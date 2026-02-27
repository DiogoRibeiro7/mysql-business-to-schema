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
from .query_manager import QueryManager
from .index_advisor import IndexAdvisor

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
query_manager = QueryManager()
index_advisor = IndexAdvisor()
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
# Query Management Endpoints (Save/Share)
# ============================================

@app.post("/api/query/save")
async def save_query(
    query_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Save or update a query."""
    try:
        result = query_manager.save_query(current_user.id, query_data)
        # Record execution if just executed
        if query_data.get('execution_time'):
            query_manager.record_execution(result['query']['id'], {
                'execution_time': query_data['execution_time'],
                'rows_returned': query_data.get('rows_returned', 0),
                'database': query_data.get('database'),
                'success': True
            })
        return result
    except Exception as e:
        logger.error(f"Error saving query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/saved")
async def get_saved_queries(
    include_shared: bool = True,
    current_user: User = Depends(get_current_user)
):
    """Get all saved queries for the current user."""
    try:
        queries = query_manager.get_user_queries(current_user.id, include_shared)
        return {"queries": queries}
    except Exception as e:
        logger.error(f"Error getting saved queries: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/saved/{query_id}")
async def get_saved_query(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific saved query."""
    try:
        query = query_manager.get_query(query_id, current_user.id)
        if not query:
            raise HTTPException(status_code=404, detail="Query not found or access denied")
        return {"query": query}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/query/saved/{query_id}")
async def delete_saved_query(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete a saved query."""
    try:
        result = query_manager.delete_query(query_id, current_user.id)
        if result['status'] == 'error':
            raise HTTPException(status_code=403, detail=result['message'])
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/collections")
async def create_collection(
    collection_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Create a new query collection."""
    try:
        result = query_manager.create_collection(current_user.id, collection_data)
        return result
    except Exception as e:
        logger.error(f"Error creating collection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/collections")
async def get_collections(
    current_user: User = Depends(get_current_user)
):
    """Get all collections for the current user."""
    try:
        collections = query_manager.get_user_collections(current_user.id)
        return {"collections": collections}
    except Exception as e:
        logger.error(f"Error getting collections: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/share/{query_id}")
async def share_query(
    query_id: str,
    share_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Share a query with other users."""
    try:
        result = query_manager.share_query(query_id, current_user.id, share_data)
        if result['status'] == 'error':
            raise HTTPException(status_code=403, detail=result['message'])
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sharing query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/duplicate/{query_id}")
async def duplicate_query(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Duplicate an existing query."""
    try:
        result = query_manager.duplicate_query(query_id, current_user.id)
        if result['status'] == 'error':
            raise HTTPException(status_code=403, detail=result['message'])
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error duplicating query: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/versions/{query_id}")
async def get_query_versions(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get version history for a query."""
    try:
        versions = query_manager.get_query_versions(query_id, current_user.id)
        return {"versions": versions}
    except Exception as e:
        logger.error(f"Error getting query versions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/versions/{query_id}/restore/{version_id}")
async def restore_query_version(
    query_id: str,
    version_id: str,
    current_user: User = Depends(get_current_user)
):
    """Restore a previous version of a query."""
    try:
        result = query_manager.restore_version(query_id, version_id, current_user.id)
        if result['status'] == 'error':
            raise HTTPException(status_code=403, detail=result['message'])
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error restoring query version: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/performance/{query_id}")
async def get_query_performance(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get performance history for a query."""
    try:
        history = query_manager.get_performance_history(query_id, current_user.id)
        return {"performance_history": history}
    except Exception as e:
        logger.error(f"Error getting performance history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/search")
async def search_queries(
    q: str,
    current_user: User = Depends(get_current_user)
):
    """Search saved queries."""
    try:
        results = query_manager.search_queries(current_user.id, q)
        return {"results": results}
    except Exception as e:
        logger.error(f"Error searching queries: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/query/favorites")
async def get_favorite_queries(
    current_user: User = Depends(get_current_user)
):
    """Get favorite queries."""
    try:
        favorites = query_manager.get_favorite_queries(current_user.id)
        return {"favorites": favorites}
    except Exception as e:
        logger.error(f"Error getting favorite queries: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/query/favorites/{query_id}")
async def toggle_favorite(
    query_id: str,
    current_user: User = Depends(get_current_user)
):
    """Toggle favorite status of a query."""
    try:
        result = query_manager.toggle_favorite(query_id, current_user.id)
        if result['status'] == 'error':
            raise HTTPException(status_code=403, detail=result['message'])
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error toggling favorite: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Index Advisor Endpoints
# ============================================

@app.post("/api/index-advisor/analyze")
async def analyze_for_indexes(
    request: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Analyze queries and suggest indexes."""
    try:
        # Get slow queries from the request or fetch from history
        slow_queries = request.get('queries', [])
        if not slow_queries:
            # Fetch recent slow queries
            slow_queries = query_analyzer.get_slow_queries(limit=100)

        # Analyze slow queries
        analysis = index_advisor.analyze_slow_queries(slow_queries)

        # Get schema information
        schema = request.get('schema', {})
        if not schema and request.get('database'):
            schema = await schema_manager.get_schema_details(request['database'])

        # Generate index suggestions
        suggestions = index_advisor.suggest_indexes(schema, slow_queries)

        # Generate comprehensive report
        report = index_advisor.generate_index_report(analysis, suggestions)

        return {
            "status": "success",
            "analysis": analysis,
            "suggestions": suggestions[:20],  # Top 20 suggestions
            "report": report
        }
    except Exception as e:
        logger.error(f"Error analyzing for indexes: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/index-advisor/suggestions/{database}")
async def get_index_suggestions(
    database: str,
    limit: int = 10,
    current_user: User = Depends(get_current_user)
):
    """Get index suggestions for a specific database."""
    try:
        suggestions = index_advisor.get_index_recommendations(database, limit)
        return {
            "database": database,
            "suggestions": suggestions,
            "total": len(suggestions)
        }
    except Exception as e:
        logger.error(f"Error getting index suggestions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/index-advisor/impact")
async def analyze_index_impact(
    request: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Analyze the impact of creating a specific index."""
    try:
        table = request.get('table')
        columns = request.get('columns', [])
        sample_queries = request.get('sample_queries', [])

        if not table or not columns:
            raise HTTPException(status_code=400, detail="Table and columns are required")

        # Analyze impact
        impact_analysis = index_advisor.analyze_index_impact(
            table, columns, sample_queries
        )

        return {
            "status": "success",
            "impact": impact_analysis
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing index impact: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/index-advisor/existing/{database}/{table}")
async def get_existing_indexes(
    database: str,
    table: str,
    current_user: User = Depends(get_current_user)
):
    """Get existing indexes for a table."""
    try:
        # This would typically query the database
        # For now, return mock data
        existing_indexes = [
            {
                "name": "PRIMARY",
                "columns": ["id"],
                "type": "PRIMARY",
                "unique": True,
                "cardinality": 10000
            }
        ]

        return {
            "database": database,
            "table": table,
            "indexes": existing_indexes
        }
    except Exception as e:
        logger.error(f"Error getting existing indexes: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/index-advisor/create")
async def create_suggested_index(
    request: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """Create a suggested index (requires admin privileges)."""
    try:
        # Check admin privileges
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin privileges required")

        create_sql = request.get('sql')
        database = request.get('database')

        if not create_sql or not database:
            raise HTTPException(status_code=400, detail="SQL and database are required")

        # In production, this would execute the CREATE INDEX statement
        # For now, simulate success
        result = {
            "status": "success",
            "message": "Index created successfully",
            "sql": create_sql,
            "database": database,
            "created_at": datetime.now().isoformat()
        }

        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating index: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/index-advisor/remove/{database}/{index_name}")
async def remove_index(
    database: str,
    index_name: str,
    current_user: User = Depends(get_current_user)
):
    """Remove an index (requires admin privileges)."""
    try:
        # Check admin privileges
        if current_user.role != "admin":
            raise HTTPException(status_code=403, detail="Admin privileges required")

        # In production, this would execute DROP INDEX
        result = {
            "status": "success",
            "message": f"Index {index_name} removed successfully",
            "database": database,
            "removed_at": datetime.now().isoformat()
        }

        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing index: {e}")
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