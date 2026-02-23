# MySQL Business-to-Schema Admin Dashboard

A comprehensive web-based administration dashboard for managing MySQL databases, schemas, migrations, and monitoring.

## 🚀 Features

### Core Functionality
- **🔐 Authentication & Authorization**: JWT-based authentication with role-based access control
- **📊 Real-time Monitoring**: Live database metrics and performance monitoring
- **🗄️ Schema Management**: Visual database and table management interface
- **🔄 Migration System**: Version-controlled database migrations with rollback support
- **🔍 Query Analyzer**: SQL query execution, optimization, and analysis
- **👥 User Management**: Comprehensive user and permission management
- **🚨 Alert System**: Configurable alerts for database metrics
- **💾 Backup & Restore**: Automated backup management with restore capabilities

### Technical Features
- **WebSocket Support**: Real-time updates and notifications
- **RESTful API**: Complete REST API for all operations
- **Docker Ready**: Fully containerized deployment
- **Responsive Design**: Mobile-friendly interface
- **Dark Mode**: Support for light and dark themes

## 🏗️ Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Frontend  │────▶│   Backend   │────▶│   Database  │
│   (React)   │     │  (FastAPI)  │     │   (MySQL)   │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                     │
       │                   │                     │
    WebSocket          Redis Cache          Backup Storage
```

## 📋 Prerequisites

- Docker & Docker Compose (for containerized deployment)
- OR:
  - Node.js 16+ (for frontend)
  - Python 3.9+ (for backend)
  - MySQL 8.0+
  - Redis 7+

## 🛠️ Quick Start

### Using Docker (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/yourusername/mysql-business-to-schema.git
cd mysql-business-to-schema/admin_dashboard
```

2. Create environment file:
```bash
cp .env.example .env
# Edit .env with your configurations
```

3. Start the services:
```bash
docker-compose up -d
```

4. Access the dashboard:
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

### Manual Setup

#### Backend Setup

1. Navigate to backend directory:
```bash
cd admin_dashboard/backend
```

2. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Configure database:
```bash
# Edit .env file with your MySQL credentials
cp .env.example .env
```

5. Run the backend:
```bash
uvicorn app:app --reload --port 8000
```

#### Frontend Setup

1. Navigate to frontend directory:
```bash
cd admin_dashboard/frontend
```

2. Install dependencies:
```bash
npm install
```

3. Configure API endpoint:
```bash
# Edit .env file
cp .env.example .env
```

4. Start development server:
```bash
npm start
```

## 📁 Project Structure

```
admin_dashboard/
├── backend/
│   ├── app.py              # FastAPI application
│   ├── auth.py              # Authentication logic
│   ├── database.py          # Database management
│   ├── models.py            # Pydantic models
│   ├── monitoring.py        # Metrics collection
│   ├── schema_manager.py    # Schema operations
│   ├── migration_handler.py # Migration logic
│   ├── query_analyzer.py    # Query optimization
│   └── requirements.txt     # Python dependencies
├── frontend/
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API services
│   │   ├── store/          # Redux store
│   │   ├── types/          # TypeScript types
│   │   └── App.tsx         # Main app
│   ├── package.json        # Node dependencies
│   └── Dockerfile          # Frontend container
├── docker-compose.yml      # Docker orchestration
└── README.md              # Documentation
```

## 🔑 Default Credentials

| Role      | Username   | Password    | Permissions              |
|-----------|------------|-------------|--------------------------|
| Admin     | admin      | admin123    | Full access             |
| Developer | developer  | dev123      | Read, Write, Execute    |
| Analyst   | analyst    | analyst123  | Read, Execute           |
| Viewer    | viewer     | viewer123   | Read only               |

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=admin123
DB_NAME=mysql_business_schema
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key
ENVIRONMENT=development
```

#### Frontend (.env)
```env
REACT_APP_API_URL=http://localhost:8000/api
REACT_APP_WS_URL=ws://localhost:8000
```

## 📚 API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key Endpoints

| Method | Endpoint                    | Description              |
|--------|----------------------------|--------------------------|
| POST   | `/api/auth/login`          | User authentication      |
| GET    | `/api/schemas/databases`    | List all databases      |
| POST   | `/api/migrations/apply`    | Apply migrations        |
| POST   | `/api/query/execute`       | Execute SQL query       |
| GET    | `/api/monitoring/metrics`   | Get system metrics      |
| GET    | `/api/users`               | List all users          |
| POST   | `/api/backups/create`      | Create backup           |

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest tests/ -v --cov=.
```

### Frontend Tests
```bash
cd frontend
npm test
npm run test:coverage
```

## 🚀 Deployment

### Production Deployment

1. Update environment variables for production
2. Build production images:
```bash
docker-compose -f docker-compose.prod.yml build
```

3. Deploy with orchestration:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes Deployment
```bash
kubectl apply -f k8s/
```

## 📊 Monitoring

The dashboard includes built-in monitoring for:

- CPU and Memory usage
- Query performance
- Connection pool statistics
- Slow query logging
- Error rates
- Backup status

## 🔒 Security Features

- JWT token authentication
- Role-based access control (RBAC)
- SQL injection prevention
- XSS protection
- CORS configuration
- Rate limiting
- Audit logging

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🆘 Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/yourusername/mysql-business-to-schema/issues)
- Documentation: [Wiki](https://github.com/yourusername/mysql-business-to-schema/wiki)

## 🔄 Roadmap

- [ ] Multi-database support (PostgreSQL, MongoDB)
- [ ] Advanced query optimization
- [ ] Automated performance tuning
- [ ] Machine learning for anomaly detection
- [ ] Mobile application
- [ ] GraphQL API support
- [ ] Terraform/Ansible deployment scripts

## 👥 Team

- Backend Development: FastAPI, Python
- Frontend Development: React, TypeScript
- DevOps: Docker, Kubernetes
- Database: MySQL optimization

---

Built with ❤️ for the MySQL community