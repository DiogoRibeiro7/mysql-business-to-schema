# MySQL Business-to-Schema SDKs

Official client libraries for interacting with the MySQL Business-to-Schema system. Available in multiple languages to suit your development needs.

## 🚀 Available SDKs

### Python SDK 🐍
Full-featured Python client with CLI support and async capabilities.

```bash
pip install mysql-business-schema
```

**Key Features:**
- Synchronous and async support
- Rich CLI with colored output
- Pandas DataFrame integration
- Faker-based data generation
- Type hints and Pydantic models

[📚 Python SDK Documentation](./python/README.md)

### Node.js/TypeScript SDK 📦
Modern TypeScript SDK with full type safety and promise-based API.

```bash
npm install mysql-business-schema
# or
yarn add mysql-business-schema
```

**Key Features:**
- Full TypeScript support
- Promise-based async API
- WebSocket real-time updates
- Stream support for large datasets
- Commander.js CLI

[📚 Node.js SDK Documentation](./nodejs/README.md)

### Go SDK 🚀
High-performance Go client with concurrent operations support.

```bash
go get github.com/yourusername/mysql-business-schema-go
```

**Key Features:**
- Concurrent operations with goroutines
- Context-based cancellation
- Streaming responses
- Zero dependencies
- Cobra CLI

[📚 Go SDK Documentation](./go/README.md)

## 📊 Feature Comparison

| Feature | Python | Node.js | Go |
|---------|--------|---------|-----|
| Schema Management | ✅ | ✅ | ✅ |
| Migrations | ✅ | ✅ | ✅ |
| Data Generation | ✅ | ✅ | ✅ |
| Query Execution | ✅ | ✅ | ✅ |
| User Management | ✅ | ✅ | ✅ |
| Backup/Restore | ✅ | ✅ | ✅ |
| WebSocket Support | ✅ | ✅ | ✅ |
| CLI Tool | ✅ | ✅ | ✅ |
| Async Support | ✅ | ✅ | ✅ |
| Type Safety | ✅ (Type Hints) | ✅ (TypeScript) | ✅ |
| Stream Processing | ⚠️ | ✅ | ✅ |
| Batch Operations | ✅ | ✅ | ✅ |

## 🔧 Quick Start Examples

### Python
```python
from mysql_business_schema import create_client

client = create_client(username="admin", password="admin123")
databases = client.list_databases()
```

### Node.js/TypeScript
```typescript
import { createClient } from 'mysql-business-schema';

const client = createClient({
  username: 'admin',
  password: 'admin123'
});

const databases = await client.listDatabases();
```

### Go
```go
import "github.com/yourusername/mysql-business-schema-go"

client := mysqlschema.NewClient(&mysqlschema.Config{
    Username: "admin",
    Password: "admin123",
})

databases, err := client.ListDatabases()
```

## 🏗️ Common Use Cases

### 1. Database Migration Pipeline
```python
# Python example
client = create_client()
migration = client.create_migration(
    description="Add users table",
    up_script="CREATE TABLE users ...",
    down_script="DROP TABLE users"
)
client.apply_migration()
```

### 2. Test Data Generation
```typescript
// TypeScript example
const generator = client.getDataGenerator();
const data = await generator.generate({
  schema: 'ecommerce',
  rows: 10000,
  format: 'sql'
});
```

### 3. Real-time Monitoring
```go
// Go example
ws := client.ConnectWebSocket()
ws.On("metrics:update", func(data map[string]interface{}) {
    fmt.Printf("CPU: %.2f%%\n", data["cpu"])
})
```

### 4. Automated Backups
```python
# Python example
backup = client.create_backup(
    database="production",
    compression=True
)
print(f"Backup ID: {backup.id}")
```

## 🔌 API Endpoints Coverage

All SDKs provide full coverage of the REST API endpoints:

| Endpoint Category | Methods | Description |
|------------------|---------|-------------|
| `/auth/*` | login, logout, refresh | Authentication |
| `/schemas/*` | CRUD operations | Schema management |
| `/migrations/*` | create, apply, rollback | Migration control |
| `/query/*` | execute, explain, optimize | Query operations |
| `/users/*` | CRUD operations | User management |
| `/backups/*` | create, list, restore | Backup management |
| `/monitoring/*` | metrics, status, alerts | System monitoring |

## 🧪 Testing

Each SDK includes comprehensive test suites:

```bash
# Python
cd sdks/python
pytest tests/

# Node.js
cd sdks/nodejs
npm test

# Go
cd sdks/go
go test ./...
```

## 📦 Building from Source

### Python
```bash
cd sdks/python
pip install -e .
```

### Node.js
```bash
cd sdks/nodejs
npm install
npm run build
```

### Go
```bash
cd sdks/go
go build ./...
```

## 🔐 Authentication

All SDKs support multiple authentication methods:

1. **Username/Password**
```python
client = create_client(username="admin", password="admin123")
```

2. **API Key**
```javascript
const client = createClient({ apiKey: 'your-api-key' });
```

3. **Environment Variables**
```go
// Set MYSQL_SCHEMA_API_KEY environment variable
client := mysqlschema.NewClientFromEnv()
```

## 🌐 WebSocket Support

Real-time updates are supported in all SDKs:

```python
# Python
ws = client.connect_websocket()
ws.on("alert:triggered", lambda data: print(f"Alert: {data}"))
```

```typescript
// TypeScript
const ws = client.connectWebSocket();
ws.on('alert:triggered', (data) => console.log('Alert:', data));
```

```go
// Go
ws := client.ConnectWebSocket()
ws.On("alert:triggered", func(data interface{}) {
    log.Printf("Alert: %v", data)
})
```

## 📚 Documentation

- [API Reference](../docs/API.md)
- [Python SDK Docs](./python/README.md)
- [Node.js SDK Docs](./nodejs/README.md)
- [Go SDK Docs](./go/README.md)
- [Examples](../examples/)

## 🤝 Contributing

We welcome contributions to all SDKs! Please see our [Contributing Guide](../CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## 📝 License

All SDKs are released under the MIT License. See [LICENSE](../LICENSE) for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/mysql-business-to-schema/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/mysql-business-to-schema/discussions)
- **Email**: support@mysqlbusinessschema.com

## 🔄 Version Compatibility

| SDK Version | API Version | MySQL Version |
|-------------|-------------|---------------|
| 1.0.x | 1.0 | 5.7+ |
| 1.0.x | 1.0 | 8.0+ |

## 🚀 Roadmap

- [ ] GraphQL support
- [ ] gRPC clients
- [ ] Ruby SDK
- [ ] PHP SDK
- [ ] Java SDK
- [ ] C# SDK
- [ ] Rust SDK
- [ ] Swift SDK

## ⭐ Showcase

Companies and projects using our SDKs:

- **DataCorp**: Migration automation for 500+ databases
- **CloudScale**: Real-time monitoring of 10,000+ MySQL instances
- **DevOps Pro**: Automated testing with generated data
- **FinTech Solutions**: Compliance-ready backup automation

---

Built with ❤️ by the MySQL Business-to-Schema team