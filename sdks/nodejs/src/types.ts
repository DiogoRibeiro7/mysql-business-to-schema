/**
 * Type definitions for MySQL Business-to-Schema SDK
 */

// ============================================
// Enums
// ============================================

export enum UserRole {
  ADMIN = 'admin',
  DEVELOPER = 'developer',
  ANALYST = 'analyst',
  VIEWER = 'viewer'
}

export enum MigrationStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  ROLLED_BACK = 'rolled_back'
}

export enum BackupType {
  FULL = 'full',
  INCREMENTAL = 'incremental',
  DIFFERENTIAL = 'differential'
}

export enum BackupStatus {
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed'
}

export enum AlertCondition {
  GREATER_THAN = 'greater_than',
  LESS_THAN = 'less_than',
  EQUALS = 'equals',
  NOT_EQUALS = 'not_equals'
}

// ============================================
// Schema Interfaces
// ============================================

export interface Column {
  name: string;
  type: string;
  nullable?: boolean;
  defaultValue?: any;
  isPrimary?: boolean;
  isUnique?: boolean;
  isIndexed?: boolean;
  autoIncrement?: boolean;
  comment?: string;
  charset?: string;
  collation?: string;
}

export interface Index {
  name: string;
  columns: string[];
  isUnique?: boolean;
  type?: string;
  comment?: string;
}

export interface ForeignKey {
  name: string;
  column: string;
  referencedTable: string;
  referencedColumn: string;
  onDelete?: string;
  onUpdate?: string;
}

export interface Table {
  name: string;
  columns: Column[];
  indexes?: Index[];
  foreignKeys?: ForeignKey[];
  engine?: string;
  charset?: string;
  collation?: string;
  rowCount?: number;
  sizeMb?: number;
  createdAt?: Date;
  updatedAt?: Date;
  comment?: string;
}

export interface Database {
  name: string;
  tables?: Table[];
  views?: string[];
  procedures?: string[];
  functions?: string[];
  triggers?: string[];
  charset?: string;
  collation?: string;
  sizeMb?: number;
  tableCount?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

// ============================================
// Migration Interfaces
// ============================================

export interface Migration {
  id?: string;
  version: string;
  description: string;
  type?: string;
  status: MigrationStatus;
  checksum?: string;
  upScript?: string;
  downScript?: string;
  executedAt?: Date;
  executionTime?: number;
  appliedBy?: string;
  errorMessage?: string;
}

export interface MigrationResult {
  migration: Migration;
  success: boolean;
  message?: string;
}

// ============================================
// Query Interfaces
// ============================================

export interface Query {
  id?: string;
  text: string;
  database: string;
  user?: string;
  executionTime?: number;
  rowCount?: number;
  status?: string;
  error?: string;
  timestamp?: Date;
}

export interface QueryResult {
  queryId: string;
  columns: string[];
  rows: any[][];
  rowCount: number;
  executionTime: number;
  affectedRows?: number;
  warnings?: string[];
}

export interface QueryPlan {
  query: string;
  plan: any[];
  estimatedCost: number;
  estimatedRows: number;
  optimizationSuggestions?: string[];
}

// ============================================
// User Interfaces
// ============================================

export interface User {
  id?: string;
  username: string;
  email: string;
  role: UserRole;
  permissions?: string[];
  isActive?: boolean;
  createdAt?: Date;
  lastLogin?: Date;
  databaseAccess?: string[];
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface AuthToken {
  token: string;
  expiresIn: number;
  user: User;
}

// ============================================
// Backup Interfaces
// ============================================

export interface Backup {
  id: string;
  database: string;
  type: BackupType;
  sizeMb: number;
  location: string;
  status: BackupStatus;
  checksum?: string;
  compression?: boolean;
  encryption?: boolean;
  createdAt: Date;
  createdBy: string;
  completedAt?: Date;
  description?: string;
  metadata?: Record<string, any>;
}

export interface BackupOptions {
  database: string;
  type?: BackupType;
  description?: string;
  compression?: boolean;
  encryption?: boolean;
}

export interface RestoreOptions {
  backupId: string;
  targetDatabase: string;
  validateChecksum?: boolean;
}

// ============================================
// Monitoring Interfaces
// ============================================

export interface MetricPoint {
  timestamp: Date;
  value: number;
  label?: string;
}

export interface DatabaseMetrics {
  databaseCount: number;
  tableCount: number;
  totalSizeMb: number;
  activeConnections: number;
  queriesPerSecond: number;
  uptimePercentage: number;
  slowQueriesCount: number;
  errorRate: number;
  cacheHitRate?: number;
  lockWaitTime?: number;
}

export interface SystemStatus {
  database: Record<string, any>;
  migrations: Record<string, number>;
  connections: Record<string, number>;
  uptime: string;
  lastBackup?: Date;
  version: string;
  environment: string;
  cpuUsage?: number;
  memoryUsage?: number;
  diskUsage?: number;
}

export interface Alert {
  id: string;
  name: string;
  metric: string;
  threshold: number;
  condition: AlertCondition;
  isEnabled?: boolean;
  notificationChannels?: string[];
  createdAt: Date;
  createdBy: string;
  lastTriggered?: Date;
  description?: string;
}

// ============================================
// WebSocket Interfaces
// ============================================

export interface WebSocketMessage {
  event: string;
  data: any;
  timestamp?: Date;
}

export interface WebSocketOptions {
  autoReconnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

// ============================================
// Client Options
// ============================================

export interface ClientOptions {
  host?: string;
  port?: number;
  apiKey?: string;
  username?: string;
  password?: string;
  timeout?: number;
  maxRetries?: number;
  ssl?: boolean;
}

// ============================================
// Generator Interfaces
// ============================================

export interface DataGeneratorOptions {
  schema: string;
  rows: number;
  format?: 'sql' | 'csv' | 'json';
  seed?: number;
}

export interface SchemaGeneratorOptions {
  template: string;
  databaseName: string;
  options?: Record<string, any>;
}

// ============================================
// API Response Interfaces
// ============================================

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T = any> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}