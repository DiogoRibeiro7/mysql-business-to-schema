"""
MySQL Business-to-Schema CLI

A unified command-line interface for database schema management,
migration control, data generation, and monitoring.
"""

from .version import __version__
from .main import cli

__all__ = ["cli", "__version__"]
