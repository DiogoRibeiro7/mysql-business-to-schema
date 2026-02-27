"""
Admin Dashboard Backend API
FastAPI-based backend for MySQL Business-to-Schema Admin Dashboard
"""

__version__ = "1.0.0"

from .app import app
from .database import get_db
from .auth import get_current_user

__all__ = ["app", "get_db", "get_current_user"]
