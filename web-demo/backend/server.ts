/**
 * Interactive Web Demo Backend Server
 *
 * Provides read-only access to database examples with:
 * - Schema exploration
 * - Query execution (read-only)
 * - Sample data viewing
 * - Performance metrics
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import mysql from 'mysql2/promise';
import { RateLimiterMemory } from 'rate-limiter-flexible';
import winston from 'winston';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

// Environment configuration
const PORT = process.env.PORT || 3001;
const NODE_ENV = process.env.NODE_ENV || 'development';
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'];

// Logger setup
const logger = winston.createLogger({
  level: NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple(),
    }),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

// Rate limiter - strict for production
const rateLimiter = new RateLimiterMemory({
  points: 100, // Number of requests
  duration: 900, // Per 15 minutes
});

// Database configurations for all examples
const DATABASE_CONFIGS: Record<string, any> = {
  clinic: {
    name: 'Medical Clinic Management',
    description: 'Healthcare patient and appointment management system',
    host: process.env.DB_HOST || 'localhost',
    port: 3308,
    user: 'root',
    password: process.env.CLINIC_PASSWORD || 'clinic_root',
    database: 'clinic_db',
    icon: '🏥',
    features: ['Appointments', 'Patients', 'Doctors', 'Invoicing'],
    sampleQueries: [
      {
        name: 'Recent Appointments',
        query: 'SELECT * FROM appointments ORDER BY start_time DESC LIMIT 10',
        description: 'View the 10 most recent appointments'
      },
      {
        name: 'Patient Count',
        query: 'SELECT COUNT(*) as total_patients FROM patients',
        description: 'Total number of patients in the system'
      },
      {
        name: 'Doctor Specialties',
        query: `SELECT d.first_name, d.last_name, GROUP_CONCAT(s.name) as specialties
                FROM doctors d
                JOIN doctor_specialties ds ON d.doctor_id = ds.doctor_id
                JOIN specialties s ON ds.specialty_id = s.specialty_id
                GROUP BY d.doctor_id LIMIT 10`,
        description: 'Doctors and their specialties'
      }
    ]
  },
  iot_bins: {
    name: 'IoT Waste Management',
    description: 'Smart city waste bin monitoring and collection optimization',
    host: process.env.DB_HOST || 'localhost',
    port: 3309,
    user: 'root',
    password: process.env.IOT_BINS_PASSWORD || 'iot_root',
    database: 'iot_bins',
    icon: '🗑️',
    features: ['Sensors', 'Real-time Monitoring', 'Route Optimization', 'Analytics'],
    sampleQueries: [
      {
        name: 'Bin Fill Levels',
        query: 'SELECT bin_id, location, fill_level, last_reading FROM bins WHERE fill_level > 70 LIMIT 10',
        description: 'Bins that need collection (>70% full)'
      },
      {
        name: 'Sensor Readings',
        query: 'SELECT * FROM sensor_readings ORDER BY reading_time DESC LIMIT 20',
        description: 'Latest sensor readings'
      }
    ]
  },
  ecommerce: {
    name: 'E-Commerce Platform',
    description: 'Complete online shopping platform with inventory and orders',
    host: process.env.DB_HOST || 'localhost',
    port: 3311,
    user: 'root',
    password: process.env.ECOMMERCE_PASSWORD || 'ecommerce_root',
    database: 'ecommerce_db',
    icon: '🛒',
    features: ['Products', 'Orders', 'Customers', 'Inventory', 'Reviews'],
    sampleQueries: [
      {
        name: 'Top Products',
        query: 'SELECT name, price, stock_quantity FROM products ORDER BY price DESC LIMIT 10',
        description: 'Top 10 most expensive products'
      },
      {
        name: 'Recent Orders',
        query: 'SELECT order_id, customer_id, total_amount, status, created_at FROM orders ORDER BY created_at DESC LIMIT 10',
        description: 'Most recent orders'
      }
    ]
  },
  fintech: {
    name: 'FinTech Platform',
    description: 'Financial technology platform with transactions and accounts',
    host: process.env.DB_HOST || 'localhost',
    port: 3317,
    user: 'root',
    password: process.env.FINTECH_PASSWORD || 'fintech_root',
    database: 'fintech_db',
    icon: '💳',
    features: ['Accounts', 'Transactions', 'Payments', 'Analytics'],
    sampleQueries: [
      {
        name: 'Account Balances',
        query: 'SELECT account_id, account_type, balance, currency FROM accounts LIMIT 10',
        description: 'Sample account balances'
      },
      {
        name: 'Recent Transactions',
        query: 'SELECT * FROM transactions ORDER BY transaction_date DESC LIMIT 20',
        description: 'Latest transactions'
      }
    ]
  },
  social_media: {
    name: 'Social Media Platform',
    description: 'Social networking platform with posts, comments, and interactions',
    host: process.env.DB_HOST || 'localhost',
    port: 3318,
    user: 'root',
    password: process.env.SOCIAL_PASSWORD || 'social_root',
    database: 'social_media_db',
    icon: '💬',
    features: ['Posts', 'Comments', 'Likes', 'Followers', 'Messages'],
    sampleQueries: [
      {
        name: 'Popular Posts',
        query: 'SELECT post_id, content, likes_count, comments_count FROM posts ORDER BY likes_count DESC LIMIT 10',
        description: 'Most liked posts'
      },
      {
        name: 'Active Users',
        query: 'SELECT user_id, username, followers_count FROM users ORDER BY followers_count DESC LIMIT 10',
        description: 'Users with most followers'
      }
    ]
  }
  // Add more examples as needed
};

// Express app
const app = express();

// Middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(compression());
app.use(express.json({ limit: '10mb' }));

// CORS configuration
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));

// Rate limiting middleware
app.use(async (req, res, next) => {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch {
    res.status(429).json({ error: 'Too many requests' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
  });
});

// Get available databases
app.get('/api/databases', (req, res) => {
  const databases = Object.entries(DATABASE_CONFIGS).map(([key, config]) => ({
    id: key,
    name: config.name,
    description: config.description,
    icon: config.icon,
    features: config.features,
  }));

  res.json(databases);
});

// Get database schema
app.get('/api/databases/:id/schema', async (req, res) => {
  const { id } = req.params;
  const config = DATABASE_CONFIGS[id];

  if (!config) {
    return res.status(404).json({ error: 'Database not found' });
  }

  try {
    const connection = await mysql.createConnection({
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      database: config.database,
    });

    // Get all tables
    const [tables] = await connection.execute(
      'SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.TABLES WHERE TABLE_SCHEMA = ?',
      [config.database]
    );

    // Get columns for each table
    const schema = await Promise.all(
      (tables as any[]).map(async (table) => {
        const [columns] = await connection.execute(
          `SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY, COLUMN_DEFAULT, COLUMN_COMMENT
           FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
           ORDER BY ORDINAL_POSITION`,
          [config.database, table.TABLE_NAME]
        );

        const [rowCount] = await connection.execute(
          `SELECT COUNT(*) as count FROM ${table.TABLE_NAME}`
        ) as any;

        return {
          name: table.TABLE_NAME,
          comment: table.TABLE_COMMENT,
          rowCount: rowCount[0].count,
          columns: columns,
        };
      })
    );

    await connection.end();

    res.json({
      database: config.name,
      tables: schema,
    });
  } catch (error) {
    logger.error('Schema fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch schema' });
  }
});

// Get sample queries
app.get('/api/databases/:id/sample-queries', (req, res) => {
  const { id } = req.params;
  const config = DATABASE_CONFIGS[id];

  if (!config) {
    return res.status(404).json({ error: 'Database not found' });
  }

  res.json(config.sampleQueries || []);
});

// Execute read-only query
app.post('/api/databases/:id/query', async (req, res) => {
  const { id } = req.params;
  const { query } = req.body;
  const config = DATABASE_CONFIGS[id];

  if (!config) {
    return res.status(404).json({ error: 'Database not found' });
  }

  // Security: Only allow SELECT queries
  const normalizedQuery = query.trim().toUpperCase();
  const allowedStatements = ['SELECT', 'SHOW', 'DESCRIBE', 'DESC', 'EXPLAIN'];
  const isAllowed = allowedStatements.some(stmt => normalizedQuery.startsWith(stmt));

  if (!isAllowed) {
    return res.status(403).json({
      error: 'Only read-only queries are allowed',
      allowed: allowedStatements
    });
  }

  // Additional security checks
  const dangerousKeywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER', 'CREATE', 'TRUNCATE', 'REPLACE'];
  const hasDangerousKeyword = dangerousKeywords.some(keyword =>
    normalizedQuery.includes(keyword)
  );

  if (hasDangerousKeyword) {
    return res.status(403).json({
      error: 'Query contains prohibited keywords',
      message: 'This demo only allows read-only operations'
    });
  }

  try {
    const connection = await mysql.createConnection({
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      database: config.database,
      rowsAsArray: false,
    });

    // Add query timeout
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Query timeout')), 30000); // 30 second timeout
    });

    const queryPromise = connection.execute(query);

    const [results, fields] = await Promise.race([
      queryPromise,
      timeoutPromise
    ]) as any;

    await connection.end();

    // Limit results for demo
    const limitedResults = Array.isArray(results) ? results.slice(0, 1000) : results;

    res.json({
      success: true,
      results: limitedResults,
      fields: fields?.map((f: any) => ({
        name: f.name,
        type: f.type,
      })),
      rowCount: Array.isArray(results) ? results.length : 0,
      limited: Array.isArray(results) && results.length > 1000,
    });

    // Log query for analytics
    logger.info('Query executed', {
      database: id,
      query: query.substring(0, 100),
      rowCount: Array.isArray(results) ? results.length : 0,
    });

  } catch (error: any) {
    logger.error('Query error:', error);

    res.status(400).json({
      error: 'Query execution failed',
      message: error.message,
      sqlMessage: error.sqlMessage,
    });
  }
});

// Get table data with pagination
app.get('/api/databases/:id/tables/:table', async (req, res) => {
  const { id, table } = req.params;
  const { page = 1, limit = 50 } = req.query;
  const config = DATABASE_CONFIGS[id];

  if (!config) {
    return res.status(404).json({ error: 'Database not found' });
  }

  try {
    const connection = await mysql.createConnection({
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      database: config.database,
    });

    // Validate table exists
    const [tables] = await connection.execute(
      'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?',
      [config.database, table]
    ) as any;

    if (tables.length === 0) {
      await connection.end();
      return res.status(404).json({ error: 'Table not found' });
    }

    // Get total count
    const [countResult] = await connection.execute(
      `SELECT COUNT(*) as total FROM ${table}`
    ) as any;

    const total = countResult[0].total;
    const offset = (Number(page) - 1) * Number(limit);

    // Get paginated data
    const [rows] = await connection.execute(
      `SELECT * FROM ${table} LIMIT ? OFFSET ?`,
      [String(limit), String(offset)]
    );

    await connection.end();

    res.json({
      table,
      rows,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        totalPages: Math.ceil(total / Number(limit)),
      },
    });

  } catch (error) {
    logger.error('Table data fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch table data' });
  }
});

// Serve static files in production
if (NODE_ENV === 'production') {
  app.use(express.static(path.join(__dirname, '../../frontend/build')));

  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../../frontend/build/index.html'));
  });
}

// Error handling
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 Web Demo API Server running on port ${PORT}`);
  logger.info(`Environment: ${NODE_ENV}`);
  logger.info(`Available databases: ${Object.keys(DATABASE_CONFIGS).join(', ')}`);
});