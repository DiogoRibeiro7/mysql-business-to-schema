/**
 * MySQL Business-to-Schema Node.js SDK
 *
 * A comprehensive Node.js client library for interacting with MySQL Business-to-Schema system.
 */

export { MySQLSchemaClient, createClient } from './client';
export { DataGenerator } from './generators/DataGenerator';
export { SchemaGenerator } from './generators/SchemaGenerator';
export { MigrationManager } from './migrations/MigrationManager';
export { WebSocketClient } from './websocket/WebSocketClient';

// Export all types
export * from './types';

// Export exceptions
export * from './exceptions';

// Version
export const VERSION = '1.0.0';

/**
 * Quick client creation helper
 */
export function createClient(options?: {
  host?: string;
  port?: number;
  apiKey?: string;
  username?: string;
  password?: string;
  timeout?: number;
}) {
  const { MySQLSchemaClient } = require('./client');
  return new MySQLSchemaClient(options || {});
}