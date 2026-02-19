/**
 * Analytics API Routes
 * Provides endpoints for performance analysis and optimization
 */

import express, { Request, Response } from 'express';
import mysql from 'mysql2/promise';
import { IndexAdvisor } from '../analytics/indexAdvisor';

const router = express.Router();

/**
 * Get index recommendations for a database
 */
router.post('/index-recommendations', async (req: Request, res: Response) => {
  try {
    const { database, threshold = 1000 } = req.body;

    if (!database) {
      return res.status(400).json({
        error: 'Database name is required'
      });
    }

    // Get connection from request context
    const connection = (req as any).dbConnection;
    if (!connection) {
      return res.status(500).json({
        error: 'Database connection not available'
      });
    }

    const advisor = new IndexAdvisor(connection);
    const recommendations = await advisor.analyzeSlowQueries(database, threshold);

    res.json({
      database,
      threshold,
      recommendationCount: recommendations.length,
      recommendations
    });
  } catch (error) {
    console.error('Error getting index recommendations:', error);
    res.status(500).json({
      error: 'Failed to generate index recommendations'
    });
  }
});

/**
 * Analyze query performance
 */
router.post('/analyze-query', async (req: Request, res: Response) => {
  try {
    const { query, database } = req.body;

    if (!query || !database) {
      return res.status(400).json({
        error: 'Query and database are required'
      });
    }

    const connection = (req as any).dbConnection;
    if (!connection) {
      return res.status(500).json({
        error: 'Database connection not available'
      });
    }

    // Use database
    await connection.query(`USE ${database}`);

    // Get query execution plan
    const [explainRows] = await connection.query(`EXPLAIN ${query}`);

    // Get query profile if available
    await connection.query('SET profiling = 1');
    await connection.query(query);
    const [profileRows] = await connection.query('SHOW PROFILE');
    await connection.query('SET profiling = 0');

    // Analyze the results
    const analysis = analyzeQueryPlan(explainRows as any[], profileRows as any[]);

    res.json({
      query,
      database,
      executionPlan: explainRows,
      profile: profileRows,
      analysis
    });
  } catch (error) {
    console.error('Error analyzing query:', error);
    res.status(500).json({
      error: 'Failed to analyze query'
    });
  }
});

/**
 * Get slow query log
 */
router.get('/slow-queries/:database', async (req: Request, res: Response) => {
  try {
    const { database } = req.params;
    const { limit = 50, minTime = 1 } = req.query;

    const connection = (req as any).dbConnection;
    if (!connection) {
      return res.status(500).json({
        error: 'Database connection not available'
      });
    }

    const query = `
      SELECT
        DIGEST_TEXT as queryText,
        COUNT_STAR as executionCount,
        ROUND(AVG_TIMER_WAIT / 1000000000, 3) as avgTimeMs,
        ROUND(MAX_TIMER_WAIT / 1000000000, 3) as maxTimeMs,
        SUM_ROWS_EXAMINED as totalRowsExamined,
        SUM_ROWS_SENT as totalRowsSent,
        ROUND(SUM_ROWS_SENT / NULLIF(SUM_ROWS_EXAMINED, 0) * 100, 2) as efficiency,
        FIRST_SEEN as firstSeen,
        LAST_SEEN as lastSeen
      FROM performance_schema.events_statements_summary_by_digest
      WHERE SCHEMA_NAME = ?
        AND AVG_TIMER_WAIT > ?
        AND DIGEST_TEXT NOT LIKE '%information_schema%'
      ORDER BY AVG_TIMER_WAIT DESC
      LIMIT ?
    `;

    const [rows] = await connection.execute(query, [
      database,
      Number(minTime) * 1000000000, // Convert ms to nanoseconds
      Number(limit)
    ]);

    res.json({
      database,
      count: (rows as any[]).length,
      queries: rows
    });
  } catch (error) {
    console.error('Error fetching slow queries:', error);
    res.status(500).json({
      error: 'Failed to fetch slow queries'
    });
  }
});

/**
 * Get index usage statistics
 */
router.get('/index-usage/:database/:table', async (req: Request, res: Response) => {
  try {
    const { database, table } = req.params;

    const connection = (req as any).dbConnection;
    if (!connection) {
      return res.status(500).json({
        error: 'Database connection not available'
      });
    }

    // Get index statistics
    const indexQuery = `
      SELECT
        s.INDEX_NAME as indexName,
        GROUP_CONCAT(s.COLUMN_NAME ORDER BY s.SEQ_IN_INDEX) as columns,
        s.CARDINALITY as cardinality,
        ROUND((s.CARDINALITY / t.TABLE_ROWS) * 100, 2) as selectivity,
        s.NULLABLE as nullable,
        s.INDEX_TYPE as indexType
      FROM information_schema.STATISTICS s
      JOIN information_schema.TABLES t
        ON s.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND s.TABLE_NAME = t.TABLE_NAME
      WHERE s.TABLE_SCHEMA = ?
        AND s.TABLE_NAME = ?
      GROUP BY s.INDEX_NAME, s.CARDINALITY, s.NULLABLE, s.INDEX_TYPE, t.TABLE_ROWS
      ORDER BY s.INDEX_NAME
    `;

    const [indexStats] = await connection.execute(indexQuery, [database, table]);

    // Get unused indexes (simplified check)
    const unusedQuery = `
      SELECT DISTINCT
        object_name as tableName,
        index_name as indexName
      FROM performance_schema.table_io_waits_summary_by_index_usage
      WHERE object_schema = ?
        AND object_name = ?
        AND index_name IS NOT NULL
        AND count_star = 0
    `;

    const [unusedIndexes] = await connection.execute(unusedQuery, [database, table]);

    res.json({
      database,
      table,
      indexes: indexStats,
      unusedIndexes
    });
  } catch (error) {
    console.error('Error fetching index usage:', error);
    res.status(500).json({
      error: 'Failed to fetch index usage statistics'
    });
  }
});

/**
 * Get query execution statistics
 */
router.get('/query-stats/:database', async (req: Request, res: Response) => {
  try {
    const { database } = req.params;
    const { period = '1h' } = req.query;

    const connection = (req as any).dbConnection;
    if (!connection) {
      return res.status(500).json({
        error: 'Database connection not available'
      });
    }

    // Get query statistics
    const statsQuery = `
      SELECT
        COUNT(DISTINCT DIGEST) as uniqueQueries,
        SUM(COUNT_STAR) as totalExecutions,
        ROUND(AVG(AVG_TIMER_WAIT) / 1000000000, 3) as avgQueryTimeMs,
        ROUND(MAX(MAX_TIMER_WAIT) / 1000000000, 3) as maxQueryTimeMs,
        SUM(SUM_ROWS_EXAMINED) as totalRowsExamined,
        SUM(SUM_ROWS_SENT) as totalRowsSent,
        SUM(SUM_ERRORS) as totalErrors,
        SUM(SUM_WARNINGS) as totalWarnings
      FROM performance_schema.events_statements_summary_by_digest
      WHERE SCHEMA_NAME = ?
    `;

    const [stats] = await connection.execute(statsQuery, [database]);

    // Get query distribution by type
    const distributionQuery = `
      SELECT
        CASE
          WHEN DIGEST_TEXT LIKE 'SELECT%' THEN 'SELECT'
          WHEN DIGEST_TEXT LIKE 'INSERT%' THEN 'INSERT'
          WHEN DIGEST_TEXT LIKE 'UPDATE%' THEN 'UPDATE'
          WHEN DIGEST_TEXT LIKE 'DELETE%' THEN 'DELETE'
          ELSE 'OTHER'
        END as queryType,
        COUNT(*) as count,
        SUM(COUNT_STAR) as executions,
        ROUND(AVG(AVG_TIMER_WAIT) / 1000000000, 3) as avgTimeMs
      FROM performance_schema.events_statements_summary_by_digest
      WHERE SCHEMA_NAME = ?
      GROUP BY queryType
    `;

    const [distribution] = await connection.execute(distributionQuery, [database]);

    res.json({
      database,
      period,
      summary: stats[0] || {},
      distribution
    });
  } catch (error) {
    console.error('Error fetching query statistics:', error);
    res.status(500).json({
      error: 'Failed to fetch query statistics'
    });
  }
});

/**
 * Analyze query execution plan
 */
function analyzeQueryPlan(explainRows: any[], profileRows: any[]): any {
  const issues = [];
  const recommendations = [];
  let estimatedCost = 0;

  // Analyze EXPLAIN output
  for (const row of explainRows) {
    // Check for full table scans
    if (row.type === 'ALL') {
      issues.push({
        severity: 'HIGH',
        message: `Full table scan on ${row.table}`,
        impact: 'High CPU and I/O usage'
      });
      recommendations.push(`Consider adding an index on ${row.table}`);
    }

    // Check for inefficient joins
    if (row.type === 'index' && row.Extra?.includes('Using temporary')) {
      issues.push({
        severity: 'MEDIUM',
        message: 'Using temporary table for sorting',
        impact: 'Memory overhead'
      });
      recommendations.push('Consider adding a covering index');
    }

    // Check for filesort
    if (row.Extra?.includes('Using filesort')) {
      issues.push({
        severity: 'MEDIUM',
        message: 'Using filesort',
        impact: 'Additional sorting overhead'
      });
      recommendations.push('Add index to support ORDER BY clause');
    }

    // Estimate cost based on rows examined
    estimatedCost += row.rows || 0;
  }

  // Analyze profile data
  let totalTime = 0;
  const timeByPhase: Record<string, number> = {};

  for (const row of profileRows) {
    totalTime += row.Duration || 0;
    const phase = row.Status || 'Unknown';
    timeByPhase[phase] = (timeByPhase[phase] || 0) + (row.Duration || 0);
  }

  // Identify bottlenecks
  const bottlenecks = Object.entries(timeByPhase)
    .filter(([phase, time]) => time / totalTime > 0.2)
    .map(([phase, time]) => ({
      phase,
      timeMs: time * 1000,
      percentage: Math.round((time / totalTime) * 100)
    }));

  return {
    issues,
    recommendations,
    estimatedCost,
    totalTimeMs: totalTime * 1000,
    timeByPhase: Object.entries(timeByPhase).map(([phase, time]) => ({
      phase,
      timeMs: time * 1000
    })),
    bottlenecks,
    performanceScore: calculatePerformanceScore(issues, estimatedCost)
  };
}

/**
 * Calculate performance score (0-100)
 */
function calculatePerformanceScore(issues: any[], estimatedCost: number): number {
  let score = 100;

  // Deduct points for issues
  for (const issue of issues) {
    if (issue.severity === 'HIGH') score -= 20;
    else if (issue.severity === 'MEDIUM') score -= 10;
    else score -= 5;
  }

  // Deduct points for high cost
  if (estimatedCost > 10000) score -= 20;
  else if (estimatedCost > 1000) score -= 10;
  else if (estimatedCost > 100) score -= 5;

  return Math.max(0, score);
}

export default router;