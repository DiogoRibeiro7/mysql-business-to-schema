/**
 * Index Advisor Integration for Web Demo
 * Provides index recommendations for database queries
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import mysql from 'mysql2/promise';
import path from 'path';
import fs from 'fs/promises';

const execAsync = promisify(exec);

interface IndexRecommendation {
  table: string;
  columns: string[];
  reason: string;
  impactScore: number;
  estimatedImprovement: string;
  createStatement: string;
  estimatedSize: string;
  maintenanceCost: 'LOW' | 'MEDIUM' | 'HIGH';
}

interface QueryPattern {
  query: string;
  executionCount: number;
  avgExecutionTime: number;
  rowsExamined: number;
  rowsSent: number;
  efficiency: number;
}

export class IndexAdvisor {
  private connection: mysql.Connection;
  private pythonScript: string;

  constructor(connection: mysql.Connection) {
    this.connection = connection;
    this.pythonScript = path.join(
      __dirname,
      '../../../../analytics/index-advisor/index_advisor.py'
    );
  }

  /**
   * Analyze slow queries and recommend indexes
   */
  async analyzeSlowQueries(
    database: string,
    threshold: number = 1000 // ms
  ): Promise<IndexRecommendation[]> {
    try {
      // Get slow query patterns from performance schema
      const patterns = await this.getSlowQueryPatterns(database, threshold);

      // Analyze each pattern for index opportunities
      const recommendations: IndexRecommendation[] = [];

      for (const pattern of patterns) {
        const recs = await this.analyzeQueryPattern(pattern, database);
        recommendations.push(...recs);
      }

      // Deduplicate and prioritize recommendations
      return this.prioritizeRecommendations(recommendations);
    } catch (error) {
      console.error('Error analyzing slow queries:', error);
      return [];
    }
  }

  /**
   * Get slow query patterns from performance schema
   */
  private async getSlowQueryPatterns(
    database: string,
    thresholdMs: number
  ): Promise<QueryPattern[]> {
    const query = `
      SELECT
        DIGEST_TEXT as query,
        COUNT_STAR as executionCount,
        AVG_TIMER_WAIT / 1000000000 as avgExecutionTime,
        SUM_ROWS_EXAMINED as rowsExamined,
        SUM_ROWS_SENT as rowsSent,
        ROUND(SUM_ROWS_SENT / NULLIF(SUM_ROWS_EXAMINED, 0) * 100, 2) as efficiency
      FROM performance_schema.events_statements_summary_by_digest
      WHERE SCHEMA_NAME = ?
        AND AVG_TIMER_WAIT > ?
        AND DIGEST_TEXT NOT LIKE '%information_schema%'
      ORDER BY AVG_TIMER_WAIT DESC
      LIMIT 50
    `;

    const [rows] = await this.connection.execute(query, [
      database,
      thresholdMs * 1000000 // Convert to nanoseconds
    ]);

    return rows as QueryPattern[];
  }

  /**
   * Analyze a single query pattern for index opportunities
   */
  private async analyzeQueryPattern(
    pattern: QueryPattern,
    database: string
  ): Promise<IndexRecommendation[]> {
    const recommendations: IndexRecommendation[] = [];

    // Parse the query to identify tables and conditions
    const queryAnalysis = this.parseQuery(pattern.query);

    if (!queryAnalysis) return recommendations;

    // Check existing indexes
    const existingIndexes = await this.getExistingIndexes(
      database,
      queryAnalysis.table
    );

    // Analyze WHERE clause conditions
    if (queryAnalysis.whereColumns.length > 0) {
      const whereIndex = this.suggestWhereIndex(
        queryAnalysis,
        existingIndexes,
        pattern
      );
      if (whereIndex) recommendations.push(whereIndex);
    }

    // Analyze JOIN conditions
    if (queryAnalysis.joinColumns.length > 0) {
      const joinIndex = this.suggestJoinIndex(
        queryAnalysis,
        existingIndexes,
        pattern
      );
      if (joinIndex) recommendations.push(joinIndex);
    }

    // Analyze ORDER BY clause
    if (queryAnalysis.orderByColumns.length > 0) {
      const orderIndex = this.suggestOrderByIndex(
        queryAnalysis,
        existingIndexes,
        pattern
      );
      if (orderIndex) recommendations.push(orderIndex);
    }

    return recommendations;
  }

  /**
   * Parse query to extract tables and columns
   */
  private parseQuery(query: string): any {
    // Simplified query parsing
    // In production, use a proper SQL parser
    const queryUpper = query.toUpperCase();

    // Extract main table
    const fromMatch = query.match(/FROM\s+`?(\w+)`?/i);
    if (!fromMatch) return null;

    const table = fromMatch[1];

    // Extract WHERE columns
    const whereColumns: string[] = [];
    const whereMatches = query.matchAll(/WHERE\s+.*?`?(\w+)`?\s*=/gi);
    for (const match of whereMatches) {
      whereColumns.push(match[1]);
    }

    // Extract JOIN columns
    const joinColumns: string[] = [];
    const joinMatches = query.matchAll(/JOIN.*?ON\s+.*?`?(\w+)`?\s*=/gi);
    for (const match of joinMatches) {
      joinColumns.push(match[1]);
    }

    // Extract ORDER BY columns
    const orderByColumns: string[] = [];
    const orderMatch = query.match(/ORDER\s+BY\s+([^;]+)/i);
    if (orderMatch) {
      const cols = orderMatch[1].split(',').map(c =>
        c.trim().split(/\s+/)[0].replace(/`/g, '')
      );
      orderByColumns.push(...cols);
    }

    return {
      table,
      whereColumns,
      joinColumns,
      orderByColumns
    };
  }

  /**
   * Get existing indexes for a table
   */
  private async getExistingIndexes(
    database: string,
    table: string
  ): Promise<string[][]> {
    const query = `
      SELECT COLUMN_NAME
      FROM information_schema.STATISTICS
      WHERE TABLE_SCHEMA = ?
        AND TABLE_NAME = ?
        AND INDEX_NAME != 'PRIMARY'
      ORDER BY INDEX_NAME, SEQ_IN_INDEX
    `;

    const [rows] = await this.connection.execute(query, [database, table]);

    // Group columns by index
    const indexes: string[][] = [];
    let currentIndex: string[] = [];
    let lastIndexName = '';

    for (const row of rows as any[]) {
      if (row.INDEX_NAME !== lastIndexName && currentIndex.length > 0) {
        indexes.push(currentIndex);
        currentIndex = [];
      }
      currentIndex.push(row.COLUMN_NAME);
      lastIndexName = row.INDEX_NAME;
    }

    if (currentIndex.length > 0) {
      indexes.push(currentIndex);
    }

    return indexes;
  }

  /**
   * Suggest index for WHERE clause
   */
  private suggestWhereIndex(
    queryAnalysis: any,
    existingIndexes: string[][],
    pattern: QueryPattern
  ): IndexRecommendation | null {
    const columns = queryAnalysis.whereColumns;

    // Check if index already exists
    if (this.indexExists(columns, existingIndexes)) {
      return null;
    }

    const improvement = this.calculateImprovement(pattern.efficiency);

    return {
      table: queryAnalysis.table,
      columns,
      reason: 'Optimize WHERE clause filtering',
      impactScore: this.calculateImpactScore(pattern),
      estimatedImprovement: improvement,
      createStatement: this.generateCreateIndexStatement(
        queryAnalysis.table,
        columns,
        'WHERE'
      ),
      estimatedSize: this.estimateIndexSize(columns.length),
      maintenanceCost: this.calculateMaintenanceCost(columns.length)
    };
  }

  /**
   * Suggest index for JOIN conditions
   */
  private suggestJoinIndex(
    queryAnalysis: any,
    existingIndexes: string[][],
    pattern: QueryPattern
  ): IndexRecommendation | null {
    const columns = queryAnalysis.joinColumns;

    if (this.indexExists(columns, existingIndexes)) {
      return null;
    }

    const improvement = this.calculateImprovement(pattern.efficiency);

    return {
      table: queryAnalysis.table,
      columns,
      reason: 'Optimize JOIN performance',
      impactScore: this.calculateImpactScore(pattern),
      estimatedImprovement: improvement,
      createStatement: this.generateCreateIndexStatement(
        queryAnalysis.table,
        columns,
        'JOIN'
      ),
      estimatedSize: this.estimateIndexSize(columns.length),
      maintenanceCost: this.calculateMaintenanceCost(columns.length)
    };
  }

  /**
   * Suggest index for ORDER BY clause
   */
  private suggestOrderByIndex(
    queryAnalysis: any,
    existingIndexes: string[][],
    pattern: QueryPattern
  ): IndexRecommendation | null {
    const columns = queryAnalysis.orderByColumns;

    if (this.indexExists(columns, existingIndexes)) {
      return null;
    }

    const improvement = this.calculateImprovement(pattern.efficiency);

    return {
      table: queryAnalysis.table,
      columns,
      reason: 'Eliminate filesort for ORDER BY',
      impactScore: this.calculateImpactScore(pattern),
      estimatedImprovement: improvement,
      createStatement: this.generateCreateIndexStatement(
        queryAnalysis.table,
        columns,
        'SORT'
      ),
      estimatedSize: this.estimateIndexSize(columns.length),
      maintenanceCost: this.calculateMaintenanceCost(columns.length)
    };
  }

  /**
   * Check if an index already exists for given columns
   */
  private indexExists(
    columns: string[],
    existingIndexes: string[][]
  ): boolean {
    return existingIndexes.some(index =>
      index.length >= columns.length &&
      columns.every((col, i) => index[i] === col)
    );
  }

  /**
   * Calculate impact score based on query pattern
   */
  private calculateImpactScore(pattern: QueryPattern): number {
    const timeScore = Math.min(pattern.avgExecutionTime / 100, 10);
    const frequencyScore = Math.min(pattern.executionCount / 100, 10);
    const efficiencyScore = (100 - (pattern.efficiency || 0)) / 10;

    return Math.round(
      (timeScore * 0.4 + frequencyScore * 0.3 + efficiencyScore * 0.3) * 10
    );
  }

  /**
   * Calculate estimated improvement
   */
  private calculateImprovement(efficiency: number): string {
    if (efficiency < 10) return '90%+ reduction in execution time';
    if (efficiency < 30) return '70-90% reduction in execution time';
    if (efficiency < 50) return '50-70% reduction in execution time';
    if (efficiency < 70) return '30-50% reduction in execution time';
    return '10-30% reduction in execution time';
  }

  /**
   * Generate CREATE INDEX statement
   */
  private generateCreateIndexStatement(
    table: string,
    columns: string[],
    type: string
  ): string {
    const indexName = `idx_${table}_${type.toLowerCase()}_${columns.join('_')}`.substring(0, 64);
    const columnList = columns.map(c => `\`${c}\``).join(', ');
    return `CREATE INDEX \`${indexName}\` ON \`${table}\` (${columnList});`;
  }

  /**
   * Estimate index size
   */
  private estimateIndexSize(columnCount: number): string {
    const avgBytesPerColumn = 8; // Rough estimate
    const avgRowCount = 10000; // Assume average table size
    const bytes = columnCount * avgBytesPerColumn * avgRowCount;

    if (bytes < 1024 * 1024) {
      return `~${Math.round(bytes / 1024)}KB`;
    }
    return `~${Math.round(bytes / (1024 * 1024))}MB`;
  }

  /**
   * Calculate maintenance cost
   */
  private calculateMaintenanceCost(columnCount: number): 'LOW' | 'MEDIUM' | 'HIGH' {
    if (columnCount <= 1) return 'LOW';
    if (columnCount <= 3) return 'MEDIUM';
    return 'HIGH';
  }

  /**
   * Deduplicate and prioritize recommendations
   */
  private prioritizeRecommendations(
    recommendations: IndexRecommendation[]
  ): IndexRecommendation[] {
    // Remove duplicates
    const unique = new Map<string, IndexRecommendation>();

    for (const rec of recommendations) {
      const key = `${rec.table}_${rec.columns.join('_')}`;
      const existing = unique.get(key);

      if (!existing || rec.impactScore > existing.impactScore) {
        unique.set(key, rec);
      }
    }

    // Sort by impact score
    return Array.from(unique.values())
      .sort((a, b) => b.impactScore - a.impactScore)
      .slice(0, 10); // Top 10 recommendations
  }

  /**
   * Run Python index advisor for advanced analysis
   */
  async runPythonAnalysis(
    host: string,
    port: number,
    database: string,
    username: string,
    password: string
  ): Promise<any> {
    try {
      const command = `python "${this.pythonScript}" --host ${host} --port ${port} --database ${database} --user ${username} --password ${password} --format json`;

      const { stdout, stderr } = await execAsync(command);

      if (stderr) {
        console.error('Python script stderr:', stderr);
      }

      return JSON.parse(stdout);
    } catch (error) {
      console.error('Error running Python analysis:', error);
      return null;
    }
  }

  /**
   * Validate index recommendation
   */
  async validateRecommendation(
    database: string,
    recommendation: IndexRecommendation
  ): Promise<boolean> {
    try {
      // Check if the index would actually be used
      const explainQuery = `
        EXPLAIN SELECT * FROM ${recommendation.table}
        WHERE ${recommendation.columns.map(c => `${c} = ?`).join(' AND ')}
      `;

      const [rows] = await this.connection.execute(
        explainQuery,
        recommendation.columns.map(() => 1)
      );

      // Check if full table scan would be avoided
      const explain = rows as any[];
      return explain.some(row =>
        row.type !== 'ALL' &&
        row.possible_keys &&
        row.rows < 1000
      );
    } catch (error) {
      console.error('Error validating recommendation:', error);
      return false;
    }
  }
}