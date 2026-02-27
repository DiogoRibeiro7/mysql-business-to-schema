"""
Pydantic models for API requests and responses
"""

from pydantic import BaseModel, Field, EmailStr
from typing import List, Dict, Optional, Any, Union
from datetime import datetime
from enum import Enum

# ============================================
# Enums
# ============================================


class UserRole(str, Enum):
    ADMIN = "admin"
    DEVELOPER = "developer"
    ANALYST = "analyst"
    VIEWER = "viewer"


class MigrationStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class AlertCondition(str, Enum):
    GREATER_THAN = "greater_than"
    LESS_THAN = "less_than"
    EQUALS = "equals"
    NOT_EQUALS = "not_equals"


class BackupType(str, Enum):
    FULL = "full"
    INCREMENTAL = "incremental"
    DIFFERENTIAL = "differential"


# ============================================
# Authentication Models
# ============================================


class User(BaseModel):
    username: str
    email: EmailStr
    role: UserRole
    permissions: List[str]
    created_at: Optional[datetime] = None
    last_login: Optional[datetime] = None


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = 3600


# ============================================
# Schema Models
# ============================================


class ColumnInfo(BaseModel):
    name: str
    type: str
    nullable: bool
    default_value: Optional[Any] = None
    is_primary: bool = False
    is_unique: bool = False
    is_indexed: bool = False
    comment: Optional[str] = None


class IndexInfo(BaseModel):
    name: str
    columns: List[str]
    is_unique: bool
    type: str  # BTREE, HASH, etc.


class ForeignKeyInfo(BaseModel):
    name: str
    column: str
    referenced_table: str
    referenced_column: str
    on_delete: str
    on_update: str


class TableInfo(BaseModel):
    name: str
    columns: List[ColumnInfo]
    indexes: List[IndexInfo]
    foreign_keys: List[ForeignKeyInfo]
    engine: str
    collation: str
    row_count: int
    size_mb: float
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SchemaInfo(BaseModel):
    name: str
    tables: List[TableInfo]
    views: List[str]
    procedures: List[str]
    functions: List[str]
    triggers: List[str]
    size_mb: float
    table_count: int


# ============================================
# Migration Models
# ============================================


class Migration(BaseModel):
    version: str
    description: str
    type: str  # sql, python
    status: MigrationStatus
    checksum: str
    up_script: Optional[str] = None
    down_script: Optional[str] = None
    executed_at: Optional[datetime] = None
    execution_time: Optional[float] = None
    applied_by: Optional[str] = None


class CreateMigrationRequest(BaseModel):
    description: str
    sql_up: str
    sql_down: Optional[str] = None
    auto_rollback: bool = False


class ApplyMigrationRequest(BaseModel):
    target_version: Optional[str] = None
    dry_run: bool = False


class RollbackMigrationRequest(BaseModel):
    target_version: Optional[str] = None
    steps: Optional[int] = 1


# ============================================
# Query Models
# ============================================


class ExecuteQueryRequest(BaseModel):
    query: str
    database: str
    limit: Optional[int] = 1000


class ExplainQueryRequest(BaseModel):
    query: str
    database: str


class OptimizeQueryRequest(BaseModel):
    query: str
    database: str


class QueryResult(BaseModel):
    columns: List[str]
    rows: List[List[Any]]
    row_count: int
    execution_time: float
    query_id: str


class QueryHistoryItem(BaseModel):
    query_id: str
    query: str
    database: str
    user: str
    execution_time: float
    row_count: int
    timestamp: datetime
    status: str


# ============================================
# Metrics Models
# ============================================


class MetricPoint(BaseModel):
    timestamp: datetime
    value: float


class PerformanceMetrics(BaseModel):
    cpu_usage: List[MetricPoint]
    memory_usage: List[MetricPoint]
    disk_io: List[MetricPoint]
    network_io: List[MetricPoint]
    query_latency: List[MetricPoint]


class DatabaseMetrics(BaseModel):
    database_count: int
    table_count: int
    total_size_mb: float
    active_connections: int
    queries_per_second: float
    uptime_percentage: float
    slow_queries_count: int
    error_rate: float


class SlowQuery(BaseModel):
    query_id: str
    query: str
    execution_time: float
    rows_examined: int
    rows_sent: int
    timestamp: datetime
    user: str
    database: str


# ============================================
# Backup Models
# ============================================


class Backup(BaseModel):
    backup_id: str
    database: str
    type: BackupType
    size_mb: float
    created_at: datetime
    created_by: str
    description: Optional[str] = None
    location: str
    status: str
    checksum: Optional[str] = None


class CreateBackupRequest(BaseModel):
    database: str
    type: BackupType = BackupType.FULL
    description: Optional[str] = None
    compression: bool = True


class RestoreBackupRequest(BaseModel):
    backup_id: str
    target_database: str
    validate_checksum: bool = True


# ============================================
# User Management Models
# ============================================


class CreateUserRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: UserRole = UserRole.VIEWER
    permissions: Optional[List[str]] = []


class UpdateUserRequest(BaseModel):
    email: Optional[EmailStr] = None
    role: Optional[UserRole] = None
    permissions: Optional[List[str]] = None
    is_active: Optional[bool] = None


class DatabaseUser(BaseModel):
    username: str
    host: str
    privileges: List[str]
    max_connections: int
    max_queries_per_hour: int
    created_at: Optional[datetime] = None


# ============================================
# Alert Models
# ============================================


class Alert(BaseModel):
    alert_id: str
    name: str
    metric: str
    threshold: float
    condition: AlertCondition
    is_enabled: bool
    notification_channels: List[str]
    created_at: datetime
    created_by: str
    last_triggered: Optional[datetime] = None


class CreateAlertRequest(BaseModel):
    name: str
    metric: str
    threshold: float
    condition: AlertCondition
    notification_channels: List[str]
    description: Optional[str] = None


class AlertHistory(BaseModel):
    alert_id: str
    alert_name: str
    triggered_at: datetime
    metric_value: float
    threshold: float
    condition: AlertCondition
    notification_sent: bool
    resolved_at: Optional[datetime] = None


# ============================================
# System Models
# ============================================


class SystemStatus(BaseModel):
    database: Dict[str, Any]
    migrations: Dict[str, int]
    connections: Dict[str, int]
    uptime: str
    last_backup: Optional[datetime] = None
    version: str
    environment: str


class ConnectionInfo(BaseModel):
    connection_id: int
    user: str
    host: str
    database: Optional[str]
    command: str
    time: int
    state: str
    info: Optional[str] = None


class ProcessList(BaseModel):
    connections: List[ConnectionInfo]
    total_connections: int
    active_connections: int
    idle_connections: int


# ============================================
# WebSocket Models
# ============================================


class WebSocketMessage(BaseModel):
    type: str
    data: Any
    timestamp: datetime
    user: Optional[str] = None


class RealtimeMetrics(BaseModel):
    cpu: float
    memory: float
    qps: float
    active_connections: int
    response_time_ms: float
    timestamp: datetime


# ============================================
# Response Models
# ============================================


class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Any] = None


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    details: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    page: int
    page_size: int
    total_pages: int
