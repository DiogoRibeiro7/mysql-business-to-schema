# GraphQL Schema Generation System

## 🚀 Overview

The GraphQL Schema Generation System automatically generates complete GraphQL APIs from MySQL database schemas. It includes type-safe schemas, resolver templates, DataLoader integration, and full Apollo Server setup.

## ✨ Features

### Schema Generation
- 🔄 **Automatic Type Mapping**: Converts MySQL types to GraphQL types
- 📊 **Relationship Detection**: Automatically detects and generates relationships
- 🎯 **Type Safety**: Generates TypeScript types for complete type safety
- 🔍 **Smart Filtering**: Generates filter and sorting types for all tables
- 📄 **Pagination Support**: Connection-based pagination following Relay spec

### Resolver Generation
- ⚡ **DataLoader Integration**: Prevents N+1 queries automatically
- 🔐 **Authentication Hooks**: Built-in authentication/authorization
- 💾 **Caching Strategies**: Redis caching with smart invalidation
- 📊 **Performance Monitoring**: Query complexity and depth analysis
- 🔄 **Subscription Support**: Real-time updates with Redis PubSub

### Apollo Server Setup
- 🚀 **Production Ready**: Complete Apollo Server configuration
- 🛡️ **Security Features**: Rate limiting, depth limiting, query complexity
- 📈 **Monitoring**: Prometheus metrics and health checks
- 🔧 **Development Tools**: GraphQL Playground, query tracing
- 🐳 **Docker Support**: Dockerfile and docker-compose configuration

## 🎯 Quick Start

### Generate GraphQL for All Examples

```bash
# Generate GraphQL schemas for all database examples
python generate_graphql_all.py
```

This will:
1. Analyze each MySQL database schema
2. Generate GraphQL type definitions
3. Create resolver templates with DataLoader
4. Setup Apollo Server project structure
5. Generate package.json and configuration files

### Generate for Specific Database

```bash
python graphql/graphql_generator_advanced.py \
  --host localhost \
  --port 3308 \
  --user root \
  --password clinic_root \
  --database clinic_db \
  --output schema.graphql
```

## 📁 Generated Project Structure

Each example gets a complete GraphQL server setup:

```
example_XX_name/
└── graphql/
    ├── schema.graphql           # GraphQL schema definition
    ├── resolvers.ts            # Resolver implementations
    ├── schema_info.json        # Schema metadata
    ├── src/
    │   ├── server.ts          # Apollo Server setup
    │   ├── index.ts           # Entry point
    │   ├── resolvers/         # Resolver modules
    │   ├── dataloaders/       # DataLoader implementations
    │   ├── utils/             # Utility functions
    │   └── middleware/        # Express middleware
    ├── package.json           # Dependencies
    ├── tsconfig.json          # TypeScript config
    ├── .env.example           # Environment template
    ├── Dockerfile             # Docker configuration
    ├── docker-compose.graphql.yml # Docker Compose
    └── README.md              # Documentation
```

## 🔧 Generated Schema Features

### Types

```graphql
# Object Types with relationships
type Patient implements Node {
  id: ID!
  firstName: String!
  lastName: String!
  dateOfBirth: Date!
  appointments(first: Int, filter: AppointmentFilter): AppointmentConnection!
  createdAt: DateTime!
  updatedAt: DateTime!
}

# Connection types for pagination
type PatientConnection {
  edges: [PatientEdge!]!
  pageInfo: PageInfo!
}

type PatientEdge {
  node: Patient!
  cursor: String!
}
```

### Filtering

```graphql
input PatientFilter {
  firstName: String
  firstName_contains: String
  firstName_starts_with: String
  dateOfBirth_gte: Date
  dateOfBirth_lte: Date
  AND: [PatientFilter!]
  OR: [PatientFilter!]
  NOT: PatientFilter
}
```

### Queries

```graphql
type Query {
  # Single item
  patient(id: ID!): Patient

  # List with pagination and filtering
  patients(
    first: Int
    after: String
    filter: PatientFilter
    sort: [PatientSort!]
  ): PatientConnection!

  # Full-text search
  searchPatient(query: String!): [Patient!]!
}
```

### Mutations

```graphql
type Mutation {
  createPatient(input: CreatePatientInput!): Patient!
  updatePatient(id: ID!, input: UpdatePatientInput!): Patient!
  deletePatient(id: ID!): OperationResult!
  batchCreatePatient(inputs: [CreatePatientInput!]!): [Patient!]!
  batchDeletePatient(ids: [ID!]!): OperationResult!
}
```

### Subscriptions

```graphql
type Subscription {
  patientCreated: Patient!
  patientUpdated(id: ID!): Patient!
  patientDeleted: ID!
}
```

## 🚀 Running Generated Servers

### Development Mode

```bash
cd example_01_clinic/graphql
npm install
npm run dev
```

Server runs at: http://localhost:4000/graphql

### Production Mode

```bash
npm run build
npm start
```

### Docker

```bash
docker-compose -f docker-compose.graphql.yml up
```

## 🔐 Authentication & Authorization

Generated resolvers include authentication hooks:

```typescript
// Resolver with authentication
patient: async (_, { id }, { user, loaders }) => {
  // Require authentication
  requireAuth(user);

  // Check permissions
  await checkPermission(user, 'read', 'patients');

  // Use DataLoader to fetch
  return await loaders.patient.load(id);
}
```

Include JWT token in requests:

```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

## ⚡ Performance Optimizations

### DataLoader Integration

Prevents N+1 queries automatically:

```typescript
// Without DataLoader: N+1 queries
patients {
  doctor {  // Separate query for each patient
    name
  }
}

// With DataLoader: 2 queries total
const doctorLoader = new DataLoader(async (ids) => {
  const doctors = await db.query('SELECT * FROM doctors WHERE id IN (?)', [ids]);
  return ids.map(id => doctors.find(d => d.id === id));
});
```

### Query Complexity Analysis

Prevents expensive queries:

```graphql
# This query would be rejected if too complex
query ExpensiveQuery {
  patients(first: 1000) {
    appointments(first: 1000) {
      invoices(first: 1000) {
        items {
          ...
        }
      }
    }
  }
}
```

### Caching

Redis caching with smart invalidation:

```typescript
// Automatic caching for queries
const cached = await cache.get(`patient:${id}`);
if (cached) return cached;

const patient = await db.query(...);
await cache.set(`patient:${id}`, patient, 300); // 5 min TTL
```

## 📊 Monitoring

### Health Check

```bash
curl http://localhost:4000/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-02-19T10:00:00Z",
  "uptime": 3600
}
```

### Prometheus Metrics

```bash
curl http://localhost:4000/metrics
```

Metrics include:
- Query execution time
- Query complexity
- Error rates
- Cache hit/miss rates
- DataLoader statistics

## 🛠️ Customization

### Extending Schemas

Add custom fields to generated types:

```graphql
extend type Patient {
  fullName: String!  # Computed field
  age: Int!          # Calculated from dateOfBirth
}
```

### Custom Resolvers

Add resolver implementation:

```typescript
const Patient = {
  fullName: (parent) => `${parent.firstName} ${parent.lastName}`,
  age: (parent) => calculateAge(parent.dateOfBirth),
};
```

### Custom Scalars

Add custom scalar types:

```graphql
scalar EmailAddress
scalar PhoneNumber
scalar PostalCode
```

## 🧪 Testing

### Testing Queries

```typescript
import { createTestClient } from 'apollo-server-testing';

const { query } = createTestClient(server);

const GET_PATIENT = gql`
  query GetPatient($id: ID!) {
    patient(id: $id) {
      id
      firstName
      lastName
    }
  }
`;

const res = await query({ query: GET_PATIENT, variables: { id: '1' } });
expect(res.data.patient).toBeDefined();
```

### Testing Subscriptions

```typescript
const subscription = gql`
  subscription {
    patientCreated {
      id
      firstName
    }
  }
`;

const iterator = await subscribe({ schema, document: subscription });
const result = await iterator.next();
expect(result.value.data.patientCreated).toBeDefined();
```

## 🔧 Configuration Options

### Environment Variables

```bash
# Server
NODE_ENV=production
PORT=4000

# Database
DATABASE_URL=mysql://user:pass@localhost:3306/db

# Redis
REDIS_URL=redis://localhost:6379

# Security
JWT_SECRET=your-secret
MAX_QUERY_DEPTH=10
MAX_QUERY_COMPLEXITY=1000
RATE_LIMIT_MAX=100

# Features
ENABLE_PLAYGROUND=false
ENABLE_INTROSPECTION=false
SOFT_DELETE=true
```

## 📚 Best Practices

### 1. Use DataLoaders

Always use DataLoaders for relationships to prevent N+1 queries.

### 2. Implement Pagination

Use cursor-based pagination for large datasets:

```graphql
query {
  patients(first: 20, after: "cursor") {
    edges {
      node { ... }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### 3. Add Field-Level Authorization

Implement fine-grained permissions:

```typescript
email: async (parent, _, { user }) => {
  if (user.id === parent.id || user.role === 'admin') {
    return parent.email;
  }
  throw new ForbiddenError('Not authorized');
}
```

### 4. Use Subscriptions Wisely

Only subscribe to relevant events:

```typescript
patientUpdated: {
  subscribe: withFilter(
    () => pubsub.asyncIterator('PATIENT_UPDATED'),
    (payload, variables) => payload.patientUpdated.id === variables.id
  )
}
```

## 🤝 Contributing

To add new features to the GraphQL generator:

1. Update schema generation in `graphql_generator_advanced.py`
2. Update resolver templates in `resolver_generator.py`
3. Test with a sample database
4. Add documentation

## 📝 License

This GraphQL generation system is part of the MySQL Business-to-Schema project.

---

*For more information, see the [main project README](../README.md)*