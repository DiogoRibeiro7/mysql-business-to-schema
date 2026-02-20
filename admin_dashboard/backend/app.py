"""
FastAPI application for Admin Dashboard
"""

from fastapi import FastAPI, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from typing import List, Dict, Any, Optional
import asyncio
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

from .database import DatabaseManager
from .auth import AuthManager, get_current_user, User
from .models import *
from .monitoring import MetricsCollector, ConnectionManager
from .schema_manager import SchemaManager
from .migration_handler import MigrationHandler
from .query_analyzer import QueryAnalyzer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="MySQL Business-to-Schema Admin Dashboard",
    description="Comprehensive management interface for MySQL schemas",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize managers
db_manager = DatabaseManager()
auth_manager = AuthManager()
schema_manager = SchemaManager()
migration_handler = MigrationHandler()
query_analyzer = QueryAnalyzer()
metrics_collector = MetricsCollector()
ws_manager = ConnectionManager()

# ============================================
# Health & Status Endpoints
# ============================================

@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@app.get("/api/status")
async def system_status(current_user: User = Depends(get_current_user)):
    """Get system status."""
    try:
        status = await db_manager.get_system_status()
        return {
            "database": status["database"],
            "migrations": status["migrations"],
            "connections": status["connections"],
            "uptime": status["uptime"],
            "last_backup": status["last_backup"]
        }
    except Exception as e:
        logger.error(f"Error getting system status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Authentication Endpoints
# ============================================

@app.post("/api/auth/login")
async def login(credentials: LoginRequest):
    """User login."""
    token = await auth_manager.login(
        credentials.username,
        credentials.password
    )
    if not token:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": 3600
    }

@app.post("/api/auth/logout")
async def logout(current_user: User = Depends(get_current_user)):
    """User logout."""
    await auth_manager.logout(current_user.username)
    return {"message": "Logged out successfully"}

@app.get("/api/auth/me")
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information."""
    return {
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "permissions": current_user.permissions
    }

# ============================================
# Dashboard Metrics Endpoints
# ============================================

@app.get("/api/metrics/overview")
async def get_metrics_overview(current_user: User = Depends(get_current_user)):
    """Get dashboard overview metrics."""
    try:
        metrics = await metrics_collector.get_overview_metrics()
        return {
            "databases": metrics["database_count"],
            "tables": metrics["table_count"],
            "total_size": metrics["total_size_mb"],
            "connections": metrics["active_connections"],
            "queries_per_second": metrics["qps"],
            "uptime_percentage": metrics["uptime_percentage"],
            "last_updated": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Error getting metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/metrics/performance")
async def get_performance_metrics(
    timeframe: str = "1h",
    current_user: User = Depends(get_current_user)
):
    """Get performance metrics."""
    try:
        metrics = await metrics_collector.get_performance_metrics(timeframe)
        return {
            "cpu_usage": metrics["cpu_usage"],
            "memory_usage": metrics["memory_usage"],
            "disk_io": metrics["disk_io"],
            "network_io": metrics["network_io"],
            "query_latency": metrics["query_latency"],
            "timestamps": metrics["timestamps"]
        }
    except Exception as e:
        logger.error(f"Error getting performance metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/metrics/queries")
async def get_query_metrics(
    limit: int = 10,
    current_user: User = Depends(get_current_user)
):
    """Get slow query metrics."""
    try:
        queries = await metrics_collector.get_slow_queries(limit)
        return {
            "slow_queries": queries,
            "total_count": len(queries),
            "threshold_ms": 1000
        }
    except Exception as e:
        logger.error(f"Error getting query metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Schema Management Endpoints
# ============================================

@app.get("/api/schemas")
async def list_schemas(current_user: User = Depends(get_current_user)):
    """List all database schemas."""
    try:
        schemas = await schema_manager.list_schemas()
        return {"schemas": schemas}
    except Exception as e:
        logger.error(f"Error listing schemas: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/schemas/{schema_name}")
async def get_schema_details(
    schema_name: str,
    current_user: User = Depends(get_current_user)
):
    """Get detailed schema information."""
    try:
        details = await schema_manager.get_schema_details(schema_name)
        return details
    except Exception as e:
        logger.error(f"Error getting schema details: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/schemas/{schema_name}/tables")
async def list_tables(
    schema_name: str,
    current_user: User = Depends(get_current_user)
):
    """List tables in a schema."""
    try:
        tables = await schema_manager.list_tables(schema_name)
        return {"tables": tables}
    except Exception as e:
        logger.error(f"Error listing tables: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/schemas/{schema_name}/tables/{table_name}")
async def get_table_details(
    schema_name: str,
    table_name: str,
    current_user: User = Depends(get_current_user)
):
    """Get table details including columns and indexes."""
    try:
        details = await schema_manager.get_table_details(schema_name, table_name)
        return details
    except Exception as e:
        logger.error(f"Error getting table details: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/schemas/{schema_name}/diagram")
async def get_schema_diagram(
    schema_name: str,
    current_user: User = Depends(get_current_user)
):
    """Get schema ERD diagram data."""
    try:
        diagram = await schema_manager.generate_erd_diagram(schema_name)
        return diagram
    except Exception as e:
        logger.error(f"Error generating diagram: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Migration Management Endpoints
# ============================================

@app.get("/api/migrations")
async def list_migrations(current_user: User = Depends(get_current_user)):
    """List all migrations."""
    try:
        migrations = await migration_handler.list_migrations()
        return {"migrations": migrations}
    except Exception as e:
        logger.error(f"Error listing migrations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/migrations/status")
async def get_migration_status(current_user: User = Depends(get_current_user)):
    """Get migration status."""
    try:
        status = await migration_handler.get_status()
        return status
    except Exception as e:
        logger.error(f"Error getting migration status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/create")
async def create_migration(
    migration: CreateMigrationRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new migration."""
    try:
        result = await migration_handler.create_migration(
            description=migration.description,
            sql_up=migration.sql_up,
            sql_down=migration.sql_down
        )
        return {
            "version": result["version"],
            "filename": result["filename"],
            "message": "Migration created successfully"
        }
    except Exception as e:
        logger.error(f"Error creating migration: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/apply")
async def apply_migrations(
    request: ApplyMigrationRequest,
    current_user: User = Depends(get_current_user)
):
    """Apply pending migrations."""
    try:
        # Check for admin role
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        result = await migration_handler.apply_migrations(
            target_version=request.target_version,
            dry_run=request.dry_run
        )

        # Send real-time update
        await ws_manager.broadcast({
            "type": "migration_update",
            "data": result
        })

        return result
    except Exception as e:
        logger.error(f"Error applying migrations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/migrations/rollback")
async def rollback_migrations(
    request: RollbackMigrationRequest,
    current_user: User = Depends(get_current_user)
):
    """Rollback migrations."""
    try:
        # Check for admin role
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        result = await migration_handler.rollback_migrations(
            target_version=request.target_version,
            steps=request.steps
        )

        # Send real-time update
        await ws_manager.broadcast({
            "type": "migration_rollback",
            "data": result
        })

        return result
    except Exception as e:
        logger.error(f"Error rolling back migrations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Query Analyzer Endpoints
# ============================================

@app.post("/api/query/execute")
async def execute_query(
    request: ExecuteQueryRequest,
    current_user: User = Depends(get_current_user)
):
    """Execute a SQL query."""
    try:
        # Check permissions for write queries
        if request.query.strip().upper().startswith(("INSERT", "UPDATE", "DELETE", "DROP", "ALTER")):
            if current_user.role not in ["admin", "developer"]:
                raise HTTPException(status_code=403, detail="Write access required")

        result = await query_analyzer.execute_query(
            query=request.query,
            database=request.database,
            limit=request.limit
        )

        return {
            "columns": result["columns"],
            "rows": result["rows"],
            "row_count": result["row_count"],
            "execution_time": result["execution_time"],
            "query_id": result["query_id"]
        }
    except Exception as e:
        logger.error(f"Error executing query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/explain")
async def explain_query(
    request: ExplainQueryRequest,
    current_user: User = Depends(get_current_user)
):
    """Get query execution plan."""
    try:
        plan = await query_analyzer.explain_query(
            query=request.query,
            database=request.database
        )

        return {
            "execution_plan": plan["plan"],
            "suggestions": plan["suggestions"],
            "estimated_rows": plan["estimated_rows"],
            "estimated_cost": plan["estimated_cost"]
        }
    except Exception as e:
        logger.error(f"Error explaining query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/history")
async def get_query_history(
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """Get query execution history."""
    try:
        history = await query_analyzer.get_query_history(
            user=current_user.username,
            limit=limit
        )

        return {"queries": history}
    except Exception as e:
        logger.error(f"Error getting query history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/optimize")
async def optimize_query(
    request: OptimizeQueryRequest,
    current_user: User = Depends(get_current_user)
):
    """Get query optimization suggestions."""
    try:
        suggestions = await query_analyzer.optimize_query(
            query=request.query,
            database=request.database
        )

        return {
            "original_query": request.query,
            "optimized_query": suggestions["optimized"],
            "suggestions": suggestions["suggestions"],
            "expected_improvement": suggestions["improvement_percentage"]
        }
    except Exception as e:
        logger.error(f"Error optimizing query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Backup Management Endpoints
# ============================================

@app.get("/api/backups")
async def list_backups(current_user: User = Depends(get_current_user)):
    """List database backups."""
    try:
        backups = await db_manager.list_backups()
        return {"backups": backups}
    except Exception as e:
        logger.error(f"Error listing backups: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/backups/create")
async def create_backup(
    request: CreateBackupRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a database backup."""
    try:
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        result = await db_manager.create_backup(
            database=request.database,
            description=request.description
        )

        # Send real-time update
        await ws_manager.broadcast({
            "type": "backup_created",
            "data": result
        })

        return result
    except Exception as e:
        logger.error(f"Error creating backup: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/backups/restore")
async def restore_backup(
    request: RestoreBackupRequest,
    current_user: User = Depends(get_current_user)
):
    """Restore from backup."""
    try:
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        result = await db_manager.restore_backup(
            backup_id=request.backup_id,
            target_database=request.target_database
        )

        return result
    except Exception as e:
        logger.error(f"Error restoring backup: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# User Management Endpoints
# ============================================

@app.get("/api/users")
async def list_users(current_user: User = Depends(get_current_user)):
    """List database users."""
    try:
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        users = await auth_manager.list_users()
        return {"users": users}
    except Exception as e:
        logger.error(f"Error listing users: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/users/create")
async def create_user(
    user: CreateUserRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new user."""
    try:
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin access required")

        result = await auth_manager.create_user(
            username=user.username,
            email=user.email,
            password=user.password,
            role=user.role
        )

        return result
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Alert Configuration Endpoints
# ============================================

@app.get("/api/alerts")
async def list_alerts(current_user: User = Depends(get_current_user)):
    """List configured alerts."""
    try:
        alerts = await db_manager.list_alerts()
        return {"alerts": alerts}
    except Exception as e:
        logger.error(f"Error listing alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/alerts/create")
async def create_alert(
    alert: CreateAlertRequest,
    current_user: User = Depends(get_current_user)
):
    """Create a new alert."""
    try:
        result = await db_manager.create_alert(
            name=alert.name,
            metric=alert.metric,
            threshold=alert.threshold,
            condition=alert.condition,
            notification_channels=alert.notification_channels
        )

        return result
    except Exception as e:
        logger.error(f"Error creating alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/alerts/history")
async def get_alert_history(
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """Get alert history."""
    try:
        history = await db_manager.get_alert_history(limit)
        return {"alerts": history}
    except Exception as e:
        logger.error(f"Error getting alert history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# WebSocket Endpoints
# ============================================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates."""
    await ws_manager.connect(websocket)
    try:
        while True:
            # Send periodic metrics
            metrics = await metrics_collector.get_real_time_metrics()
            await ws_manager.send_personal_message(
                json.dumps({
                    "type": "metrics_update",
                    "data": metrics,
                    "timestamp": datetime.utcnow().isoformat()
                }),
                websocket
            )
            await asyncio.sleep(5)  # Update every 5 seconds
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        ws_manager.disconnect(websocket)

# ============================================
# Static Files
# ============================================

# Serve static files from frontend build
frontend_path = Path(__file__).parent.parent / "frontend" / "build"
if frontend_path.exists():
    app.mount("/", StaticFiles(directory=str(frontend_path), html=True), name="static")

# ============================================
# Startup and Shutdown Events
# ============================================

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    logger.info("Starting Admin Dashboard Backend...")
    await db_manager.initialize()
    await metrics_collector.start_collection()
    logger.info("Admin Dashboard Backend started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("Shutting down Admin Dashboard Backend...")
    await metrics_collector.stop_collection()
    await db_manager.close()
    logger.info("Admin Dashboard Backend shut down")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)