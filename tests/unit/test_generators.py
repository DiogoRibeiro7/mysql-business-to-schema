"""Unit tests for the shared data-generator base class.

These exercise the real, database-free surface of
``generators.base_generator.BaseGenerator``. Anything that needs a live
MySQL connection is covered with a mocked cursor/connection so the tests
stay fast and infra-free (and therefore safe to gate CI on).
"""

import hashlib
from datetime import date, datetime, timedelta
from unittest.mock import Mock

import pytest

from generators.base_generator import BaseGenerator


@pytest.mark.unit
class TestBaseGeneratorInit:
    """Construction and connection-parameter storage."""

    def test_stores_connection_parameters(self):
        generator = BaseGenerator(
            host="db.example.com",
            port=3307,
            user="app",
            password="secret",
            database="shop",
        )
        assert generator.host == "db.example.com"
        assert generator.port == 3307
        assert generator.user == "app"
        assert generator.password == "secret"
        assert generator.database == "shop"

    def test_defaults_and_lazy_connection(self):
        generator = BaseGenerator()
        assert generator.host == "localhost"
        assert generator.port == 3306
        # Construction must not open a connection eagerly.
        assert generator.connection is None
        assert generator.cursor is None


@pytest.mark.unit
class TestPasswordHashing:
    """``generate_password_hash`` behaviour."""

    def test_hash_matches_sha256_hex(self):
        generator = BaseGenerator()
        expected = hashlib.sha256("hunter2".encode()).hexdigest()
        result = generator.generate_password_hash("hunter2")
        assert result == expected
        assert len(result) == 64

    def test_hash_is_deterministic_for_same_input(self):
        generator = BaseGenerator()
        assert generator.generate_password_hash("hunter2") == generator.generate_password_hash(
            "hunter2"
        )

    def test_distinct_passwords_hash_differently(self):
        generator = BaseGenerator()
        assert generator.generate_password_hash("alice") != generator.generate_password_hash(
            "bob"
        )


@pytest.mark.unit
class TestRandomDates:
    """Random date/datetime helpers stay within their requested range."""

    def test_random_datetime_is_within_range(self):
        generator = BaseGenerator()
        start = datetime(2020, 1, 1)
        end = datetime(2020, 12, 31)
        for _ in range(100):
            result = generator.random_datetime_between(start, end)
            assert isinstance(result, datetime)
            assert result >= start
            # The helper adds up to one extra day of seconds, so the
            # effective upper bound is one day past ``end``.
            assert result <= end + timedelta(days=1)

    def test_random_date_between_parses_strings(self):
        generator = BaseGenerator()
        result = generator.random_date_between("2020-01-01", "2020-01-10")
        assert isinstance(result, date)
        assert result >= date(2020, 1, 1)
        assert result <= date(2020, 1, 11)


@pytest.mark.unit
class TestBulkInsert:
    """``bulk_insert`` query construction and batching (mocked cursor)."""

    def _generator_with_mock_db(self):
        generator = BaseGenerator()
        generator.cursor = Mock()
        generator.connection = Mock()
        return generator

    def test_empty_data_is_a_noop(self):
        generator = self._generator_with_mock_db()
        generator.bulk_insert("users", [], ["id", "name"])
        generator.cursor.executemany.assert_not_called()

    def test_builds_parameterized_query(self):
        generator = self._generator_with_mock_db()
        generator.bulk_insert("users", [(1, "alice")], ["id", "name"])
        query, _batch = generator.cursor.executemany.call_args[0]
        # Identifiers are backtick-quoted; values use %s placeholders
        # (parameterized, not string-interpolated).
        assert query == "INSERT INTO `users` (`id`, `name`) VALUES (%s, %s)"

    def test_splits_into_batches(self):
        generator = self._generator_with_mock_db()
        rows = [(1, "a"), (2, "b"), (3, "c")]
        generator.bulk_insert("users", rows, ["id", "name"], batch_size=2)
        # 3 rows with batch_size=2 -> two executemany calls.
        assert generator.cursor.executemany.call_count == 2
        first_batch = generator.cursor.executemany.call_args_list[0][0][1]
        second_batch = generator.cursor.executemany.call_args_list[1][0][1]
        assert first_batch == [(1, "a"), (2, "b")]
        assert second_batch == [(3, "c")]
