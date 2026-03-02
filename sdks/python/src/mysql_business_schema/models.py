"""Data models for MySQL Business-to-Schema SDK."""

from datetime import datetime
from enum import Enum
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, EmailStr


# ============================================
# Enums
# ============================================


class UserRole(str, Enum):
    """Represent UserRole."""

    ADMIN = "admin"
    DEVELOPER = "developer"
    ANALYST = "analyst"
    VIEWER = "viewer"


class MigrationStatus(str, Enum):
    """Represent MigrationStatus."""

    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class BackupType(str, Enum):
    """Represent BackupType."""

    FULL = "full"
    INCREMENTAL = "incremental"
    DIFFERENTIAL = "differential"


class BackupStatus(str, Enum):
    """Represent BackupStatus."""

    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class AlertCondition(str, Enum):
    """Represent AlertCondition."""

    GREATER_THAN = "greater_than"
    LESS_THAN = "less_than"
    EQUALS = "equals"
    NOT_EQUALS = "not_equals"


# ============================================
# Schema Models
# ============================================


class Column(BaseModel):
    """Database column definition."""

    name: str
    type: str
    nullable: bool = True
    default_value: Optional[Any] = None
    is_primary: bool = False
    is_unique: bool = False
    is_indexed: bool = False
    auto_increment: bool = False
    comment: Optional[str] = None
    charset: Optional[str] = None
    collation: Optional[str] = None

    def to_sql(self) -> str:
        """Convert column to SQL definition."""
        sql = f"`{self.name}` {self.type}"
        if not self.nullable:
            sql += " NOT NULL"
        if self.default_value is not None:
            sql += f" DEFAULT {self.default_value}"
        if self.auto_increment:
            sql += " AUTO_INCREMENT"
        if self.comment:
            sql += f" COMMENT '{self.comment}'"
        return sql


class Index(BaseModel):
    """Database index definition."""

    name: str
    columns: List[str]
    is_unique: bool = False
    type: str = "BTREE"
    comment: Optional[str] = None

    def to_sql(self, table_name: str) -> str:
        """Convert index to SQL definition."""
        unique = "UNIQUE " if self.is_unique else ""
        cols = ", ".join([f"`{col}`" for col in self.columns])
        return f"CREATE {unique}INDEX `{self.name}` ON `{table_name}` ({cols}) USING {self.type}"


class ForeignKey(BaseModel):
    """Foreign key constraint definition."""

    name: str
    column: str
    referenced_table: str
    referenced_column: str
    on_delete: str = "RESTRICT"
    on_update: str = "RESTRICT"

    def to_sql(self) -> str:
        """Convert foreign key to SQL definition."""
        return (
            f"CONSTRAINT `{self.name}` FOREIGN KEY (`{self.column}`) "
            f"REFERENCES `{self.referenced_table}` (`{self.referenced_column}`) "
            f"ON DELETE {self.on_delete} ON UPDATE {self.on_update}"
        )


class Table(BaseModel):
    """Database table definition."""

    name: str
    columns: List[Column]
    indexes: List[Index] = []
    foreign_keys: List[ForeignKey] = []
    engine: str = "InnoDB"
    charset: str = "utf8mb4"
    collation: str = "utf8mb4_unicode_ci"
    row_count: Optional[int] = None
    size_mb: Optional[float] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    comment: Optional[str] = None

    def to_create_sql(self) -> str:
        """Generate CREATE TABLE SQL statement."""
        # Columns
        column_defs = [col.to_sql() for col in self.columns]

        # Primary keys
        primary_keys = [col.name for col in self.columns if col.is_primary]
        if primary_keys:
            column_defs.append(f"PRIMARY KEY (`{'`, `'.join(primary_keys)}`)")

        # Foreign keys
        for fk in self.foreign_keys:
            column_defs.append(fk.to_sql())

        # Create statement
        sql = f"CREATE TABLE `{self.name}` (\n  "
        sql += ",\n  ".join(column_defs)
        sql += f"\n) ENGINE={self.engine}"
        sql += f" DEFAULT CHARSET={self.charset}"
        sql += f" COLLATE={self.collation}"

        if self.comment:
            sql += f" COMMENT='{self.comment}'"

        return sql


class Database(BaseModel):
    """Database schema definition."""

    name: str
    tables: List[Table] = []
    views: List[str] = []
    procedures: List[str] = []
    functions: List[str] = []
    triggers: List[str] = []
    charset: str = "utf8mb4"
    collation: str = "utf8mb4_unicode_ci"
    size_mb: Optional[float] = None
    table_count: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    def to_create_sql(self) -> str:
        """Generate CREATE DATABASE SQL statement."""
        return (
            f"CREATE DATABASE IF NOT EXISTS `{self.name}` "
            f"CHARACTER SET {self.charset} "
            f"COLLATE {self.collation}"
        )


class SchemaInfo(BaseModel):
    """Complete schema information."""

    databases: List[Database]
    total_size_mb: float
    total_tables: int
    total_views: int
    total_procedures: int
    version: str


# ============================================
# Migration Models
# ============================================


class Migration(BaseModel):
    """Database migration definition."""

    id: Optional[str] = None
    version: str
    description: str
    type: str = "sql"
    status: MigrationStatus = MigrationStatus.PENDING
    checksum: Optional[str] = None
    up_script: Optional[str] = None
    down_script: Optional[str] = None
    executed_at: Optional[datetime] = None
    execution_time: Optional[float] = None
    applied_by: Optional[str] = None
    error_message: Optional[str] = None


# ============================================
# Query Models
# ============================================


class Query(BaseModel):
    """SQL query definition."""

    id: Optional[str] = None
    text: str
    database: str
    user: Optional[str] = None
    execution_time: Optional[float] = None
    row_count: Optional[int] = None
    status: str = "pending"
    error: Optional[str] = None
    timestamp: Optional[datetime] = None


class QueryResult(BaseModel):
    """Query execution result."""

    query_id: str
    columns: List[str]
    rows: List[List[Any]]
    row_count: int
    execution_time: float
    affected_rows: Optional[int] = None
    warnings: List[str] = []


class QueryPlan(BaseModel):
    """Query execution plan."""

    query: str
    plan: List[Dict[str, Any]]
    estimated_cost: float
    estimated_rows: int
    optimization_suggestions: List[str] = []


# ============================================
# User Models
# ============================================


class User(BaseModel):
    """User account definition."""

    id: Optional[str] = None
    username: str
    email: EmailStr
    role: UserRole
    permissions: List[str] = []
    is_active: bool = True
    created_at: Optional[datetime] = None
    last_login: Optional[datetime] = None
    database_access: List[str] = []


# ============================================
# Backup Models
# ============================================


class Backup(BaseModel):
    """Database backup definition."""

    id: str
    database: str
    type: BackupType
    size_mb: float
    location: str
    status: BackupStatus
    checksum: Optional[str] = None
    compression: bool = False
    encryption: bool = False
    created_at: datetime
    created_by: str
    completed_at: Optional[datetime] = None
    description: Optional[str] = None
    metadata: Dict[str, Any] = {}


# ============================================
# Monitoring Models
# ============================================


class MetricPoint(BaseModel):
    """Metric data point."""

    timestamp: datetime
    value: float
    label: Optional[str] = None


class DatabaseMetrics(BaseModel):
    """Database performance metrics."""

    database_count: int
    table_count: int
    total_size_mb: float
    active_connections: int
    queries_per_second: float
    uptime_percentage: float
    slow_queries_count: int
    error_rate: float
    cache_hit_rate: float
    lock_wait_time: float


class SystemStatus(BaseModel):
    """System status information."""

    database: Dict[str, Any]
    migrations: Dict[str, int]
    connections: Dict[str, int]
    uptime: str
    last_backup: Optional[datetime] = None
    version: str
    environment: str
    cpu_usage: float
    memory_usage: float
    disk_usage: float


class Alert(BaseModel):
    """Alert configuration."""

    id: str
    name: str
    metric: str
    threshold: float
    condition: AlertCondition
    is_enabled: bool = True
    notification_channels: List[str] = []
    created_at: datetime
    created_by: str
    last_triggered: Optional[datetime] = None
    description: Optional[str] = None


class AlertHistory(BaseModel):
    """Alert trigger history."""

    alert_id: str
    alert_name: str
    triggered_at: datetime
    metric_value: float
    threshold: float
    condition: AlertCondition
    notification_sent: bool
    resolved_at: Optional[datetime] = None


# ============================================
# Connection Models
# ============================================


class ConnectionInfo(BaseModel):
    """Database connection information."""

    connection_id: int
    user: str
    host: str
    database: Optional[str] = None
    command: str
    time: int
    state: str
    info: Optional[str] = None
    bytes_sent: int = 0
    bytes_received: int = 0
