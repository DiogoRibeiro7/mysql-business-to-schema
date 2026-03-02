#!/usr/bin/env python3
"""Generate GraphQL Schemas and Apollo Server Setup for All Examples.

This script:
1. Generates GraphQL schemas from MySQL for all examples
2. Creates resolver templates
3. Sets up Apollo Server projects
4. Generates package.json and configuration files
"""

import json
from pathlib import Path
from typing import Dict, List, Optional

from graphql.graphql_generator_advanced import AdvancedGraphQLGenerator
from graphql.resolver_generator import ResolverGenerator


class GraphQLProjectGenerator:
    """Generate complete GraphQL projects for examples."""

    def __init__(self, project_root: Path):
        """Initialize the instance."""
        self.project_root = project_root
        self.examples = self._get_examples()
        self.results = []

    def _get_examples(self) -> List[Path]:
        """Get all example directories."""
        return sorted([d for d in self.project_root.glob("example_*") if d.is_dir()])

    def generate_all(self):
        """Generate GraphQL for all examples."""
        print("\n" + "=" * 70)
        print("GraphQL Schema Generation for MySQL Business-to-Schema")
        print("=" * 70 + "\n")

        success_count = 0
        failed = []

        for i, example_dir in enumerate(self.examples, 1):
            example_name = example_dir.name
            print(f"[{i}/{len(self.examples)}] Processing {example_name}...")

            try:
                if self._generate_example(example_dir):
                    success_count += 1
                    print(f"  ✓ Successfully generated GraphQL for {example_name}")
                else:
                    failed.append(example_name)
                    print(f"  ✗ Failed to generate GraphQL for {example_name}")
            except Exception as e:
                failed.append(example_name)
                print(f"  ✗ Error: {e}")

        # Print summary
        print("\n" + "=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print(f"Total Examples: {len(self.examples)}")
        print(f"Successful: {success_count}")
        print(f"Failed: {len(failed)}")

        if failed:
            print(f"\nFailed examples: {', '.join(failed)}")

        print("\n✅ GraphQL generation complete!")

    def _generate_example(self, example_dir: Path) -> bool:
        """Generate GraphQL for a single example."""
        example_name = example_dir.name.replace("example_", "").replace("_", "-")

        # Get database connection parameters
        connection_params = self._get_connection_params(example_dir)
        if not connection_params:
            print("    Warning: Could not determine connection parameters")
            return False

        # Create GraphQL directory
        graphql_dir = example_dir / "graphql"
        graphql_dir.mkdir(exist_ok=True)

        # Generate schema
        if not self._generate_schema(connection_params, graphql_dir):
            return False

        # Generate resolvers
        if not self._generate_resolvers(connection_params, graphql_dir):
            return False

        # Generate Apollo Server project
        if not self._generate_apollo_project(example_name, graphql_dir):
            return False

        # Generate package.json
        self._generate_package_json(example_name, graphql_dir)

        # Generate configuration files
        self._generate_config_files(example_name, graphql_dir)

        # Generate README
        self._generate_readme(example_name, graphql_dir)

        return True

    def _get_connection_params(self, example_dir: Path) -> Optional[Dict]:
        """Extract connection parameters from docker-compose.yml."""
        docker_compose = example_dir / "docker-compose.yml"

        if not docker_compose.exists():
            return None

        try:
            import yaml

            with open(docker_compose, "r") as f:
                compose = yaml.safe_load(f)

            mysql_service = compose.get("services", {}).get("mysql", {})
            env = mysql_service.get("environment", {})
            ports = mysql_service.get("ports", [])

            # Extract port
            port = 3306
            if ports:
                port_mapping = ports[0].split(":")
                if len(port_mapping) == 2:
                    port = int(port_mapping[0])

            return {
                "host": "localhost",
                "port": port,
                "user": "root",
                "password": env.get("MYSQL_ROOT_PASSWORD", ""),
                "database": env.get("MYSQL_DATABASE", ""),
            }
        except Exception as e:
            print(f"    Error parsing docker-compose.yml: {e}")
            return None

    def _generate_schema(self, connection_params: Dict, output_dir: Path) -> bool:
        """Generate GraphQL schema from MySQL."""
        try:
            generator = AdvancedGraphQLGenerator(connection_params)

            if not generator.connect():
                return False

            try:
                generator.analyze_database()
                schema = generator.generate_schema()

                # Save schema
                schema_file = output_dir / "schema.graphql"
                with open(schema_file, "w", encoding="utf-8") as f:
                    f.write(schema)

                # Save schema info for resolver generation
                schema_info = {
                    "tables": {
                        name: {
                            "fields": [vars(f) for f in info.fields],
                            "primary_keys": info.primary_keys,
                            "foreign_keys": info.foreign_keys,
                            "indexes": info.indexes,
                        }
                        for name, info in generator.tables.items()
                    }
                }

                info_file = output_dir / "schema_info.json"
                with open(info_file, "w") as f:
                    json.dump(schema_info, f, indent=2)

                return True
            finally:
                generator.disconnect()

        except Exception as e:
            print(f"    Error generating schema: {e}")
            return False

    def _generate_resolvers(self, connection_params: Dict, output_dir: Path) -> bool:
        """Generate resolver templates."""
        try:
            # Load schema info
            info_file = output_dir / "schema_info.json"
            with open(info_file, "r") as f:
                schema_info = json.load(f)

            generator = ResolverGenerator(schema_info)

            # Generate TypeScript resolvers
            resolvers = generator.generate_resolvers_ts()

            # Save resolvers
            resolvers_file = output_dir / "resolvers.ts"
            with open(resolvers_file, "w", encoding="utf-8") as f:
                f.write(resolvers)

            return True

        except Exception as e:
            print(f"    Error generating resolvers: {e}")
            return False

    def _generate_apollo_project(self, example_name: str, output_dir: Path) -> bool:
        """Generate Apollo Server project structure."""
        try:
            # Create src directory structure
            src_dir = output_dir / "src"
            src_dir.mkdir(exist_ok=True)

            # Create subdirectories
            (src_dir / "resolvers").mkdir(exist_ok=True)
            (src_dir / "dataloaders").mkdir(exist_ok=True)
            (src_dir / "utils").mkdir(exist_ok=True)
            (src_dir / "middleware").mkdir(exist_ok=True)

            # Copy Apollo Server template
            apollo_template = (
                self.project_root / "graphql" / "apollo_server_template.ts"
            )
            if apollo_template.exists():
                import shutil

                shutil.copy(apollo_template, src_dir / "server.ts")

            # Generate index file
            index_content = f"""/**
 * GraphQL Server for {example_name}
 * Auto-generated by MySQL Business-to-Schema
 */

import './server';

console.log('Starting GraphQL server for {example_name}...');
"""
            with open(src_dir / "index.ts", "w") as f:
                f.write(index_content)

            return True

        except Exception as e:
            print(f"    Error generating Apollo project: {e}")
            return False

    def _generate_package_json(self, example_name: str, output_dir: Path):
        """Generate package.json for the GraphQL server."""
        package = {
            "name": f"{example_name}-graphql-server",
            "version": "1.0.0",
            "description": f"GraphQL server for {example_name} example",
            "main": "dist/index.js",
            "scripts": {
                "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
                "build": "tsc",
                "start": "node dist/index.js",
                "test": "jest",
                "codegen": "graphql-codegen",
                "lint": "eslint src --ext .ts",
                "format": 'prettier --write "src/**/*.ts"',
            },
            "dependencies": {
                "apollo-server-express": "^3.12.0",
                "express": "^4.18.2",
                "graphql": "^16.6.0",
                "graphql-subscriptions": "^2.0.0",
                "subscriptions-transport-ws": "^0.11.0",
                "dataloader": "^2.2.2",
                "mysql2": "^3.6.0",
                "knex": "^2.5.1",
                "ioredis": "^5.3.2",
                "graphql-redis-subscriptions": "^2.6.0",
                "jsonwebtoken": "^9.0.0",
                "bcryptjs": "^2.4.3",
                "dotenv": "^16.3.1",
                "winston": "^3.10.0",
                "compression": "^1.7.4",
                "cors": "^2.8.5",
                "helmet": "^7.0.0",
                "express-rate-limit": "^6.10.0",
                "rate-limit-redis": "^3.1.0",
                "graphql-depth-limit": "^1.1.0",
                "graphql-validation-complexity": "^0.4.2",
                "graphql-cost-analysis": "^1.1.0",
            },
            "devDependencies": {
                "@types/node": "^20.5.0",
                "@types/express": "^4.17.17",
                "@graphql-codegen/cli": "^5.0.0",
                "@graphql-codegen/typescript": "^4.0.1",
                "@graphql-codegen/typescript-resolvers": "^4.0.1",
                "typescript": "^5.1.6",
                "ts-node": "^10.9.1",
                "ts-node-dev": "^2.0.0",
                "jest": "^29.6.2",
                "@types/jest": "^29.5.3",
                "eslint": "^8.46.0",
                "@typescript-eslint/parser": "^6.2.0",
                "@typescript-eslint/eslint-plugin": "^6.2.0",
                "prettier": "^3.0.0",
            },
            "engines": {"node": ">=16.0.0"},
        }

        package_file = output_dir / "package.json"
        with open(package_file, "w") as f:
            json.dump(package, f, indent=2)

    def _generate_config_files(self, example_name: str, output_dir: Path):
        """Generate configuration files."""
        # TypeScript configuration
        tsconfig = {
            "compilerOptions": {
                "target": "ES2020",
                "module": "commonjs",
                "lib": ["ES2020"],
                "outDir": "./dist",
                "rootDir": "./src",
                "strict": True,
                "esModuleInterop": True,
                "skipLibCheck": True,
                "forceConsistentCasingInFileNames": True,
                "resolveJsonModule": True,
                "declaration": True,
                "declarationMap": True,
                "sourceMap": True,
                "experimentalDecorators": True,
                "emitDecoratorMetadata": True,
            },
            "include": ["src/**/*"],
            "exclude": ["node_modules", "dist", "**/*.test.ts"],
        }

        with open(output_dir / "tsconfig.json", "w") as f:
            json.dump(tsconfig, f, indent=2)

        # Environment variables template
        env_template = f"""# GraphQL Server Environment Variables

# Server
NODE_ENV=development
PORT=4000

# Database
DATABASE_URL=mysql://root:password@localhost:3306/{example_name}

# Redis
REDIS_URL=redis://localhost:6379

# Authentication
JWT_SECRET=your-secret-key-here
JWT_EXPIRATION=7d

# Security
MAX_QUERY_DEPTH=10
MAX_QUERY_COMPLEXITY=1000
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100

# Features
ENABLE_PLAYGROUND=true
ENABLE_INTROSPECTION=true
ENABLE_TRACING=true
SOFT_DELETE=false

# CORS
CORS_ORIGIN=*
"""

        with open(output_dir / ".env.example", "w") as f:
            f.write(env_template)

        # Docker configuration
        dockerfile = """FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 4000

# Start server
CMD ["node", "dist/index.js"]
"""

        with open(output_dir / "Dockerfile", "w") as f:
            f.write(dockerfile)

        # Docker Compose for GraphQL server
        docker_compose = f"""version: '3.8'

services:
  graphql:
    build: .
    container_name: {example_name}_graphql
    restart: unless-stopped
    ports:
      - "4000:4000"
    environment:
      NODE_ENV: production
      DATABASE_URL: mysql://root:$$MYSQL_ROOT_PASSWORD@mysql:3306/$$MYSQL_DATABASE
      REDIS_URL: redis://redis:6379
      JWT_SECRET: $$JWT_SECRET
    depends_on:
      - mysql
      - redis
    networks:
      - {example_name}_network

  redis:
    image: redis:7-alpine
    container_name: {example_name}_redis_graphql
    restart: unless-stopped
    ports:
      - "6379:6379"
    networks:
      - {example_name}_network

networks:
  {example_name}_network:
    external: true
"""

        with open(output_dir / "docker-compose.graphql.yml", "w") as f:
            f.write(docker_compose)

    def _generate_readme(self, example_name: str, output_dir: Path):
        """Generate README for GraphQL server."""
        readme = f"""# GraphQL Server for {example_name}

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- MySQL database running
- Redis (optional, for subscriptions)

### Installation

```bash
npm install
```

### Configuration

1. Copy environment template:
```bash
cp .env.example .env
```

2. Update `.env` with your database credentials

### Development

```bash
# Start development server with hot reload
npm run dev
```

Server will be available at: http://localhost:4000/graphql

### Production

```bash
# Build TypeScript
npm run build

# Start production server
npm start
```

### Docker

```bash
# Build and run with Docker Compose
docker-compose -f docker-compose.graphql.yml up
```

## 📊 Features

- ✅ **Type-safe GraphQL schema** generated from MySQL
- ✅ **DataLoader integration** for N+1 query prevention
- ✅ **Subscription support** with Redis PubSub
- ✅ **Authentication & Authorization** with JWT
- ✅ **Query complexity analysis** and depth limiting
- ✅ **Rate limiting** to prevent abuse
- ✅ **Caching** with Redis
- ✅ **Error handling** with proper logging
- ✅ **Performance monitoring** and metrics

## 🔍 GraphQL Playground

When running in development, GraphQL Playground is available at:
http://localhost:4000/graphql

### Example Queries

```graphql
# Get a single item
query GetItem {{
  item(id: "1") {{
    id
    name
    createdAt
  }}
}}

# List with pagination
query ListItems {{
  items(first: 10, filter: {{ status: "active" }}) {{
    edges {{
      node {{
        id
        name
      }}
      cursor
    }}
    pageInfo {{
      hasNextPage
      total
    }}
  }}
}}

# Create mutation
mutation CreateItem {{
  createItem(input: {{ name: "New Item" }}) {{
    id
    name
  }}
}}

# Subscribe to updates
subscription ItemUpdates {{
  itemUpdated(id: "1") {{
    id
    name
    updatedAt
  }}
}}
```

## 📁 Project Structure

```
graphql/
├── src/
│   ├── server.ts         # Apollo Server setup
│   ├── resolvers/        # GraphQL resolvers
│   ├── dataloaders/      # DataLoader implementations
│   ├── utils/            # Utility functions
│   └── middleware/       # Express middleware
├── schema.graphql        # GraphQL schema
├── resolvers.ts          # Generated resolvers
├── package.json          # Dependencies
└── tsconfig.json         # TypeScript config
```

## 🔐 Authentication

Include JWT token in headers:

```json
{{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}}
```

## 📈 Performance

The server includes several performance optimizations:

1. **DataLoader**: Batch and cache database queries
2. **Query Complexity**: Prevent expensive queries
3. **Depth Limiting**: Prevent deeply nested queries
4. **Rate Limiting**: Prevent API abuse
5. **Caching**: Redis caching for common queries

## 🧪 Testing

```bash
# Run tests
npm test

# Run with coverage
npm run test:coverage
```

## 🚢 Deployment

### Environment Variables

Required environment variables for production:

- `NODE_ENV=production`
- `DATABASE_URL`: MySQL connection string
- `REDIS_URL`: Redis connection string
- `JWT_SECRET`: Secret for JWT signing

### Health Check

Health check endpoint available at:
```
GET /health
```

### Metrics

Prometheus metrics available at:
```
GET /metrics
```

## 📖 Documentation

- [GraphQL Schema](./schema.graphql)
- [Apollo Server](https://www.apollographql.com/docs/apollo-server/)
- [DataLoader](https://github.com/graphql/dataloader)

---

*Generated by MySQL Business-to-Schema GraphQL Generator*
"""

        with open(output_dir / "README.md", "w") as f:
            f.write(readme)


def main():
    """Run entry point."""
    project_root = Path(__file__).parent

    generator = GraphQLProjectGenerator(project_root)
    generator.generate_all()


if __name__ == "__main__":
    main()
