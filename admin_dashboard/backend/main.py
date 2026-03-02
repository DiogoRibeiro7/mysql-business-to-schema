#!/usr/bin/env python3
"""Run entry point for the Admin Dashboard FastAPI application."""

import uvicorn
import logging
from pathlib import Path
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Run the FastAPI application."""
    logger.info("Starting Admin Dashboard Backend Server...")

    # Add parent directory to path for imports
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))

    # Import the FastAPI app from app.py
    from admin_dashboard.backend.app import app

    # Configuration for uvicorn
    config = {
        "host": "0.0.0.0",
        "port": 8000,
        "reload": True,  # Enable auto-reload in development
        "log_level": "info",
        "access_log": True,
    }

    # Check if running in production mode
    import os

    if os.getenv("ENVIRONMENT") == "production":
        config["reload"] = False
        config["workers"] = 4
        logger.info("Running in production mode")
    else:
        logger.info("Running in development mode")

    try:
        # Start the server
        uvicorn.run(
            "admin_dashboard.backend.app:app" if config["reload"] else app, **config
        )
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        raise


if __name__ == "__main__":
    main()
