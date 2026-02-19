/**
 * Apollo Server Setup Template
 *
 * Complete Apollo Server configuration with:
 * - DataLoader integration
 * - Authentication & Authorization
 * - Subscription support
 * - Error handling
 * - Performance monitoring
 * - Caching strategies
 */

import express from 'express';
import { createServer } from 'http';
import { ApolloServer } from 'apollo-server-express';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { SubscriptionServer } from 'subscriptions-transport-ws';
import { execute, subscribe } from 'graphql';
import { PubSub } from 'graphql-subscriptions';
import { RedisPubSub } from 'graphql-redis-subscriptions';
import Redis from 'ioredis';
import DataLoader from 'dataloader';
import depthLimit from 'graphql-depth-limit';
import costAnalysis from 'graphql-cost-analysis';
import { GraphQLError } from 'graphql';
import compression from 'compression';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { createComplexityLimitRule } from 'graphql-validation-complexity';

// Import generated schema and resolvers
import { typeDefs } from './generated/schema';
import { resolvers } from './generated/resolvers';
import { createLoaders } from './generated/dataloaders';

// Database and utilities
import { createDatabaseConnection, DatabaseConnection } from './database';
import { authenticateUser, getUserFromToken } from './auth';
import { logger } from './utils/logger';
import { cache } from './utils/cache';
import { metrics } from './utils/metrics';

// Environment configuration
const {
  PORT = 4000,
  NODE_ENV = 'development',
  REDIS_URL = 'redis://localhost:6379',
  DATABASE_URL,
  JWT_SECRET,
  MAX_QUERY_DEPTH = 10,
  MAX_QUERY_COMPLEXITY = 1000,
  RATE_LIMIT_WINDOW = 15 * 60 * 1000, // 15 minutes
  RATE_LIMIT_MAX = 100,
  ENABLE_PLAYGROUND = NODE_ENV === 'development',
  ENABLE_INTROSPECTION = NODE_ENV === 'development',
  ENABLE_TRACING = NODE_ENV === 'development',
  SUBSCRIPTION_ENDPOINT = '/subscriptions',
} = process.env;

// Redis clients for pub/sub and caching
const redisClient = new Redis(REDIS_URL);
const redisSubscriber = new Redis(REDIS_URL);

// PubSub for subscriptions (use Redis in production)
const pubsub = NODE_ENV === 'production'
  ? new RedisPubSub({
      publisher: redisClient,
      subscriber: redisSubscriber,
    })
  : new PubSub();

// Context interface
export interface Context {
  db: DatabaseConnection;
  loaders: ReturnType<typeof createLoaders>;
  user: any | null;
  pubsub: typeof pubsub;
  cache: typeof cache;
  req: express.Request;
  res: express.Response;
}

// Create executable schema
const schema = makeExecutableSchema({
  typeDefs,
  resolvers,
});

// Apollo Server plugins
const plugins = [
  // Request lifecycle logging
  {
    requestDidStart() {
      return {
        willSendResponse(requestContext: any) {
          // Log query performance
          const { query, variables, operationName } = requestContext.request;
          const { errors, data } = requestContext.response;

          metrics.recordQuery({
            operationName,
            duration: Date.now() - requestContext.startTime,
            errors: errors?.length || 0,
          });

          if (errors) {
            logger.error('GraphQL errors:', { errors, query, variables });
          }
        },
      };
    },
  },

  // Caching plugin
  {
    requestDidStart() {
      return {
        async willSendResponse(requestContext: any) {
          const { response, request } = requestContext;

          // Cache GET queries
          if (request.http?.method === 'GET' && !response.errors) {
            const cacheKey = `gql:${request.query}:${JSON.stringify(request.variables)}`;
            await cache.set(cacheKey, response.data, 300); // 5 minute cache
          }
        },
      };
    },
  },

  // Performance monitoring
  NODE_ENV === 'production' && require('apollo-server-plugin-base').ApolloServerPluginUsageReporting({
    sendVariableValues: { all: true },
    sendHeaders: { all: true },
  }),
].filter(Boolean);

// Create Apollo Server
async function createApolloServer(): Promise<ApolloServer> {
  const db = await createDatabaseConnection(DATABASE_URL);

  const server = new ApolloServer({
    schema,
    plugins,

    // Context function - runs for every request
    context: async ({ req, res, connection }: any): Promise<Context> => {
      // For subscriptions
      if (connection) {
        return {
          ...connection.context,
          db,
          pubsub,
          cache,
        };
      }

      // For queries and mutations
      const token = req.headers.authorization?.replace('Bearer ', '');
      const user = token ? await getUserFromToken(token) : null;

      // Create fresh DataLoaders for each request
      const loaders = createLoaders(db);

      return {
        db,
        loaders,
        user,
        pubsub,
        cache,
        req,
        res,
      };
    },

    // Validation rules
    validationRules: [
      depthLimit(MAX_QUERY_DEPTH),
      createComplexityLimitRule(MAX_QUERY_COMPLEXITY, {
        onCost: (cost: number) => {
          logger.warn(`Query complexity: ${cost}`);
        },
      }),
      costAnalysis({
        maximumCost: MAX_QUERY_COMPLEXITY,
        defaultCost: 1,
        onComplete: (cost: number) => {
          metrics.recordQueryComplexity(cost);
        },
      }),
    ],

    // Error formatting
    formatError: (error: GraphQLError) => {
      // Remove stack traces in production
      if (NODE_ENV === 'production') {
        delete error.extensions?.exception?.stacktrace;
      }

      // Log errors
      logger.error('GraphQL error:', error);

      // Add error tracking
      metrics.recordError(error);

      return error;
    },

    // Development tools
    playground: ENABLE_PLAYGROUND ? {
      settings: {
        'request.credentials': 'include',
        'schema.polling.enable': false,
      },
    } : false,

    introspection: ENABLE_INTROSPECTION,
    tracing: ENABLE_TRACING,
    debug: NODE_ENV === 'development',

    // File upload support
    uploads: {
      maxFileSize: 10 * 1024 * 1024, // 10 MB
      maxFiles: 5,
    },

    // Cache control
    cacheControl: {
      defaultMaxAge: 5,
      calculateHttpHeaders: true,
    },

    // Performance optimizations
    persistedQueries: {
      cache: redisClient,
      ttl: 900, // 15 minutes
    },
  });

  return server;
}

// Express app setup
async function startServer() {
  const app = express();

  // Security middleware
  app.use(helmet({
    contentSecurityPolicy: NODE_ENV === 'production' ? undefined : false,
  }));

  // Compression
  app.use(compression());

  // CORS
  app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  }));

  // Rate limiting
  const limiter = rateLimit({
    store: new RedisStore({
      client: redisClient,
      prefix: 'rate_limit:',
    }),
    windowMs: RATE_LIMIT_WINDOW,
    max: RATE_LIMIT_MAX,
    message: 'Too many requests, please try again later.',
  });

  app.use('/graphql', limiter);

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    });
  });

  // Metrics endpoint
  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', metrics.register.contentType);
    res.end(await metrics.register.metrics());
  });

  // Create and start Apollo Server
  const apollo = await createApolloServer();
  await apollo.start();

  // Apply Apollo middleware
  apollo.applyMiddleware({
    app,
    path: '/graphql',
    cors: false, // We're handling CORS separately
  });

  // Create HTTP server
  const httpServer = createServer(app);

  // Setup subscription server
  const subscriptionServer = SubscriptionServer.create(
    {
      schema,
      execute,
      subscribe,

      // On connect lifecycle hook
      async onConnect(connectionParams: any) {
        logger.info('Subscription client connected');

        // Authenticate subscription
        if (connectionParams.authorization) {
          const user = await getUserFromToken(connectionParams.authorization);
          return { user };
        }

        throw new Error('Missing authentication');
      },

      // On disconnect lifecycle hook
      onDisconnect() {
        logger.info('Subscription client disconnected');
      },
    },
    {
      server: httpServer,
      path: SUBSCRIPTION_ENDPOINT,
    }
  );

  // Graceful shutdown
  const shutdown = async () => {
    logger.info('Shutting down server...');

    // Close subscription server
    subscriptionServer.close();

    // Close Apollo Server
    await apollo.stop();

    // Close database connections
    await db.destroy();

    // Close Redis connections
    redisClient.disconnect();
    redisSubscriber.disconnect();

    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

  // Start server
  httpServer.listen(PORT, () => {
    logger.info(`🚀 Server ready at http://localhost:${PORT}${apollo.graphqlPath}`);
    logger.info(`🔌 Subscriptions ready at ws://localhost:${PORT}${SUBSCRIPTION_ENDPOINT}`);

    if (ENABLE_PLAYGROUND) {
      logger.info(`🎮 GraphQL Playground available at http://localhost:${PORT}${apollo.graphqlPath}`);
    }
  });
}

// Error handling
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Start the server
startServer().catch((error) => {
  logger.error('Failed to start server:', error);
  process.exit(1);
});