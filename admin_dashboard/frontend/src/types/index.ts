// User and Authentication Types
export interface User {
  id: string;
  username: string;
  email: string;
  role: UserRole;
  permissions: string[];
  createdAt: string;
  lastLogin?: string;
  isActive: boolean;
}

export enum UserRole {
  ADMIN = 'admin',
  DEVELOPER = 'developer',
  ANALYST = 'analyst',
  VIEWER = 'viewer',
}

export interface LoginCredentials {
  username: string;
  password: string;
}

// Schema Types
export interface Database {
  name: string;
  tables: Table[];
  views: string[];
  procedures: string[];
  functions: string[];
  triggers: string[];
  sizeMb: number;
  tableCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface Table {
  name: string;
  columns: Column[];
  indexes: Index[];
  foreignKeys: ForeignKey[];
  engine: string;
  collation: string;
  rowCount: number;
  sizeMb: number;
  createdAt: string;
  updatedAt: string;
}

export interface Column {
  name: string;
  type: string;
  nullable: boolean;
  defaultValue?: any;
  isPrimary: boolean;
  isUnique: boolean;
  isIndexed: boolean;
  comment?: string;
}

export interface Index {
  name: string;
  columns: string[];
  isUnique: boolean;
  type: string;
}

export interface ForeignKey {
  name: string;
  column: string;
  referencedTable: string;
  referencedColumn: string;
  onDelete: string;
  onUpdate: string;
}

// Migration Types
export interface Migration {
  id: string;
  version: string;
  description: string;
  type: 'sql' | 'python';
  status: MigrationStatus;
  checksum: string;
  upScript?: string;
  downScript?: string;
  executedAt?: string;
  executionTime?: number;
  appliedBy?: string;
}

export enum MigrationStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  ROLLED_BACK = 'rolled_back',
}

// Query Types
export interface Query {
  id: string;
  query: string;  // Changed from 'text' to 'query' for consistency
  database: string;
  user: string;
  executionTime: number;
  rowCount: number;
  status: 'success' | 'error';
  error?: string;
  timestamp: string;
}

export interface QueryResult {
  columns: string[];
  data: any[];  // Array of objects for easier Chart.js integration
  rows?: any[][];  // Optional legacy format
  rowCount: number;
  executionTime: number;
  queryId?: string;
  executionPlan?: QueryPlanStep[];  // For EXPLAIN results
  cost?: QueryCost;  // Cost analysis
  bufferHit?: number;  // Buffer pool hit percentage
  indexUsage?: string;  // Index usage info
}

export interface QueryPlanStep {
  id?: number;
  type: string;
  table: string;
  rows: number;
  key?: string;
  extra?: string;
  cost?: number;
}

export interface QueryCost {
  read: number;
  sort: number;
  join: number;
  filter: number;
  total: number;
}

export interface SlowQuery {
  queryId: string;
  query: string;
  executionTime: number;
  rowsExamined: number;
  rowsSent: number;
  timestamp: string;
  database: string;
}

// Monitoring Types
export interface Metrics {
  cpu: MetricPoint[];
  memory: MetricPoint[];
  diskIo: MetricPoint[];
  networkIo: MetricPoint[];
  queryLatency: MetricPoint[];
  qps: MetricPoint[];
  timestamp: string;
}

export interface MetricPoint {
  timestamp: string;
  value: number;
}

export interface RealtimeMetrics {
  cpu: number;
  memory: number;
  qps: number;
  activeConnections: number;
  responseTimeMs: number;
  timestamp: string;
}

export interface DatabaseMetrics {
  databaseCount: number;
  tableCount: number;
  totalSizeMb: number;
  activeConnections: number;
  qps: number;
  uptimePercentage: number;
  slowQueriesCount: number;
  errorRate: number;
}

// Alert Types
export interface Alert {
  id: string;
  name: string;
  metric: string;
  threshold: number;
  condition: AlertCondition;
  isEnabled: boolean;
  notificationChannels: string[];
  createdAt: string;
  createdBy: string;
  lastTriggered?: string;
  description?: string;
}

export enum AlertCondition {
  GREATER_THAN = 'greater_than',
  LESS_THAN = 'less_than',
  EQUALS = 'equals',
  NOT_EQUALS = 'not_equals',
}

export interface AlertHistory {
  alertId: string;
  alertName: string;
  triggeredAt: string;
  metricValue: number;
  threshold: number;
  condition: AlertCondition;
  notificationSent: boolean;
  resolvedAt?: string;
}

// Backup Types
export interface Backup {
  id: string;
  database: string;
  type: BackupType;
  sizeMb: number;
  createdAt: string;
  createdBy: string;
  description?: string;
  location: string;
  status: BackupStatus;
  checksum?: string;
  completedAt?: string;
}

export enum BackupType {
  FULL = 'full',
  INCREMENTAL = 'incremental',
  DIFFERENTIAL = 'differential',
}

export enum BackupStatus {
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

// System Types
export interface SystemStatus {
  database: {
    version: string;
    uptime: string;
  };
  migrations: {
    total: number;
    completed: number;
    pending: number;
  };
  connections: {
    active: number;
    max: number;
  };
  lastBackup?: string;
  version: string;
  environment: string;
}

export interface ConnectionInfo {
  connectionId: number;
  user: string;
  host: string;
  database?: string;
  command: string;
  time: number;
  state: string;
  info?: string;
}

// Form Types
export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface TableColumn {
  id: string;
  field: string;
  headerName: string;
  width?: number;
  sortable?: boolean;
  filterable?: boolean;
  renderCell?: (params: any) => React.ReactNode;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// Settings Types
export interface Settings {
  theme: 'light' | 'dark' | 'auto';
  language: string;
  timezone: string;
  notifications: NotificationSettings;
  display: DisplaySettings;
}

export interface NotificationSettings {
  email: boolean;
  push: boolean;
  slack: boolean;
  alertThreshold: number;
}

export interface DisplaySettings {
  compactMode: boolean;
  showLineNumbers: boolean;
  fontSize: number;
  editorTheme: string;
}