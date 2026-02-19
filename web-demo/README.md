# Interactive Web Demo for MySQL Business-to-Schema

## 🌐 Overview

The Interactive Web Demo provides a live, browser-based interface for exploring all MySQL database examples. Users can browse schemas, execute read-only queries, and learn from sample queries in a safe, sandboxed environment.

**Live Demo**: [https://demo.mysql-business-schema.com](https://demo.mysql-business-schema.com)

## ✨ Features

### 🔍 Schema Explorer
- Browse all tables and their structure
- View column types, keys, and constraints
- See table relationships and foreign keys
- Check row counts and table statistics

### 💻 Query Playground
- Execute read-only SQL queries
- Syntax highlighting for SQL
- Query result pagination
- Export results to CSV/JSON
- Query execution time tracking

### 📚 Sample Queries
- Pre-written queries for each database
- Learn common query patterns
- One-click query execution
- Educational descriptions

### 🔒 Security
- Read-only database access
- Query validation and sanitization
- Rate limiting to prevent abuse
- Timeout protection for long queries

## 🚀 Quick Start

### Local Development

1. **Install dependencies**:
```bash
cd web-demo
npm install:all
```

2. **Start databases** (using Docker):
```bash
docker-compose up -d
```

3. **Run development servers**:
```bash
npm run dev
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:3001

### Production Deployment

```bash
# Build for production
npm run build

# Start production server
npm run start:prod
```

## 🐳 Docker Deployment

### Full Stack with Docker Compose

```bash
# Build and run everything
docker-compose up --build

# Access at http://localhost
```

### Individual Containers

```bash
# Build image
docker build -t mysql-web-demo .

# Run container
docker run -p 3001:3001 \
  -e NODE_ENV=production \
  -e DB_HOST=host.docker.internal \
  mysql-web-demo
```

## ☁️ Cloud Deployment

### Deploy to Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway up

# Set environment variables
railway variables set NODE_ENV=production
```

### Deploy to Render

1. Connect GitHub repository
2. Use `render.yaml` blueprint
3. Deploy automatically on push

### Deploy to Fly.io

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Launch app
fly launch --config deploy/fly.toml

# Deploy
fly deploy

# Scale
fly scale count 2
```

### Deploy to Vercel (Frontend)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy frontend
cd frontend
vercel

# Set backend API URL
vercel env add REACT_APP_API_URL
```

## 🗄️ Available Databases

| Database | Description | Features |
|----------|-------------|----------|
| 🏥 **Medical Clinic** | Healthcare management system | Appointments, Patients, Doctors, Billing |
| 🗑️ **IoT Waste Bins** | Smart city waste management | Sensors, Monitoring, Routes, Analytics |
| 🛒 **E-Commerce** | Online shopping platform | Products, Orders, Customers, Inventory |
| 💳 **FinTech** | Financial technology platform | Accounts, Transactions, Payments |
| 💬 **Social Media** | Social networking platform | Posts, Comments, Likes, Followers |
| 🏢 **Real Estate** | Property management | Listings, Agents, Transactions |
| 🎫 **Event Ticketing** | Event management system | Events, Tickets, Venues, Bookings |
| 📦 **Logistics** | Supply chain management | Shipments, Warehouses, Tracking |
| 🎓 **Education** | Learning management system | Courses, Students, Grades |
| 💰 **Cryptocurrency** | Crypto exchange platform | Wallets, Trades, Orders |

## 🎯 Sample Queries

Each database includes educational sample queries:

### Medical Clinic
```sql
-- Find doctors with their specialties
SELECT d.first_name, d.last_name,
       GROUP_CONCAT(s.name) as specialties
FROM doctors d
JOIN doctor_specialties ds ON d.doctor_id = ds.doctor_id
JOIN specialties s ON ds.specialty_id = s.specialty_id
GROUP BY d.doctor_id;
```

### E-Commerce
```sql
-- Top selling products
SELECT p.name, COUNT(oi.order_item_id) as sales_count,
       SUM(oi.quantity) as total_quantity
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id
ORDER BY sales_count DESC
LIMIT 10;
```

### IoT Waste Bins
```sql
-- Bins needing collection
SELECT bin_id, location, fill_level,
       last_reading, battery_level
FROM bins
WHERE fill_level > 75
ORDER BY fill_level DESC;
```

## 🔧 Configuration

### Environment Variables

```bash
# Server
NODE_ENV=production
PORT=3001

# Security
ALLOWED_ORIGINS=https://your-domain.com
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=900000

# Database connections
DB_HOST=localhost
CLINIC_PASSWORD=clinic_root
IOT_BINS_PASSWORD=iot_root
ECOMMERCE_PASSWORD=ecommerce_root

# Features
ENABLE_QUERY_HISTORY=true
MAX_QUERY_RESULTS=1000
QUERY_TIMEOUT=30000
```

### Security Configuration

The demo enforces read-only access:

- ✅ **Allowed**: SELECT, SHOW, DESCRIBE, EXPLAIN
- ❌ **Blocked**: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE

Additional security measures:
- Query timeout (30 seconds)
- Result limit (1000 rows)
- Rate limiting (100 requests/15 min)
- SQL injection prevention

## 📊 Architecture

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│   Browser   │────▶│   Nginx     │────▶│  Express API │
│  (React UI) │     │   Proxy     │     │   Backend    │
└─────────────┘     └─────────────┘     └──────┬───────┘
                                                │
                    ┌───────────────────────────┼────────┐
                    ▼                           ▼         ▼
            ┌───────────┐             ┌───────────┐  ┌───────────┐
            │  MySQL    │             │  MySQL    │  │  MySQL    │
            │  Clinic   │             │ E-Commerce│  │   IoT     │
            └───────────┘             └───────────┘  └───────────┘
```

### Technology Stack

**Frontend**:
- React 18 with TypeScript
- Material-UI for components
- React Syntax Highlighter
- Axios for API calls

**Backend**:
- Express.js with TypeScript
- MySQL2 for database connections
- Rate limiting with rate-limiter-flexible
- Winston for logging
- Helmet for security

## 🧪 Testing

### Run Tests

```bash
# All tests
npm test

# Frontend tests
npm run test:frontend

# Backend tests
npm run test:backend

# E2E tests
npm run test:e2e
```

### Load Testing

```bash
# Using k6
k6 run tests/load-test.js

# Using Artillery
artillery run tests/load-test.yml
```

## 📈 Monitoring

### Health Check

```bash
curl http://localhost:3001/health
```

### Metrics

The application exposes metrics at `/metrics`:
- Query execution count
- Average response time
- Error rates
- Active connections

### Logging

Logs are written to:
- `logs/error.log` - Error logs
- `logs/combined.log` - All logs
- Console output in development

## 🚦 Performance

### Optimizations
- Query result caching
- Connection pooling
- Gzip compression
- Static asset CDN
- Database query optimization

### Benchmarks
- Page load: < 2 seconds
- Query execution: < 500ms average
- API response: < 100ms
- Concurrent users: 100+

## 🤝 Contributing

### Adding New Database Examples

1. Add configuration to `backend/server.ts`:
```typescript
DATABASE_CONFIGS['new_example'] = {
  name: 'New Example',
  description: 'Description',
  host: 'localhost',
  port: 3330,
  // ...
};
```

2. Add sample queries
3. Update Docker Compose
4. Test locally
5. Submit PR

### Development Guidelines

- Use TypeScript for type safety
- Follow ESLint rules
- Write tests for new features
- Update documentation

## 🐛 Troubleshooting

### Common Issues

**Cannot connect to database**:
- Check if Docker containers are running
- Verify port configurations
- Check firewall settings

**Query timeout**:
- Optimize query with indexes
- Reduce result set size
- Check database performance

**CORS errors**:
- Update ALLOWED_ORIGINS
- Check proxy configuration

## 📝 License

MIT License - See [LICENSE](../LICENSE) file

## 🔗 Links

- [Main Project](https://github.com/yourusername/mysql-business-to-schema)
- [Documentation](https://docs.mysql-business-schema.com)
- [Live Demo](https://demo.mysql-business-schema.com)
- [Report Issues](https://github.com/yourusername/mysql-business-to-schema/issues)

---

*Built with ❤️ for the MySQL community*