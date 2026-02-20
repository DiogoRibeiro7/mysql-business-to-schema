"""
Database Migration System for MySQL Business-to-Schema.

A comprehensive migration framework providing:
- Version control for database schemas
- Automatic migration generation
- Rollback capabilities
- Migration validation
- Conflict detection
- Dry-run mode
"""

__version__ = "1.0.0"

from .core import Migration, MigrationRunner
from .generator import MigrationGenerator
from .validator import MigrationValidator
from .cli import cli

__all__ = [
    "Migration",
    "MigrationRunner",
    "MigrationGenerator",
    "MigrationValidator",
    "cli"
]