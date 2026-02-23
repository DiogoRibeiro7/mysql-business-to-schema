# MySQL Admin Dashboard Frontend

A modern React-based admin dashboard for MySQL database management.

## Features

- 🔐 **Authentication & Authorization** - JWT-based auth with role-based access control
- 📊 **Real-time Monitoring** - Live metrics and performance monitoring via WebSocket
- 🗄️ **Schema Management** - Browse and manage databases, tables, and schemas
- 🔄 **Migration System** - Version-controlled database migrations with rollback
- 🔍 **Query Analyzer** - Execute queries, view execution plans, and optimize
- 👥 **User Management** - Manage users, roles, and permissions
- 🚨 **Alert System** - Configure and monitor database alerts
- 💾 **Backup Management** - Create, manage, and restore database backups
- 🎨 **Modern UI** - Material-UI components with responsive design

## Tech Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Redux Toolkit** - State management
- **Material-UI** - Component library
- **React Router** - Routing
- **Socket.io** - Real-time updates
- **Recharts** - Data visualization
- **Monaco Editor** - SQL editor

## Prerequisites

- Node.js 16+
- npm or yarn
- Backend API running on http://localhost:8000

## Installation

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

## Project Structure

```
src/
├── components/       # Reusable components
│   ├── Layout.tsx   # Main layout with sidebar
│   └── PrivateRoute.tsx
├── pages/           # Page components
│   ├── Dashboard.tsx
│   ├── Login.tsx
│   ├── SchemaManager.tsx
│   ├── MigrationManager.tsx
│   ├── QueryAnalyzer.tsx
│   ├── UserManagement.tsx
│   ├── Monitoring.tsx
│   ├── Alerts.tsx
│   ├── Backups.tsx
│   └── Settings.tsx
├── services/        # API services
│   ├── api.ts
│   ├── auth.ts
│   └── websocket.ts
├── store/          # Redux store
│   ├── index.ts
│   ├── authSlice.ts
│   ├── schemaSlice.ts
│   ├── migrationSlice.ts
│   ├── monitoringSlice.ts
│   ├── userSlice.ts
│   ├── alertSlice.ts
│   ├── backupSlice.ts
│   └── querySlice.ts
├── types/          # TypeScript types
│   └── index.ts
├── App.tsx         # Main app component
├── index.tsx       # Entry point
└── theme.ts        # Material-UI theme

```

## Environment Variables

Create a `.env` file in the root:

```env
REACT_APP_API_URL=http://localhost:8000/api
REACT_APP_WS_URL=ws://localhost:8000
```

## Available Scripts

```bash
# Start development server
npm start

# Run tests
npm test

# Build production bundle
npm run build

# Run ESLint
npm run lint

# Format code with Prettier
npm run format
```

## Key Features Implementation

### Authentication Flow
- Login with username/password
- JWT token stored in localStorage
- Auto-refresh token mechanism
- Protected routes with role-based access

### Real-time Updates
- WebSocket connection for live metrics
- Auto-reconnect with exponential backoff
- Subscription-based updates for specific resources

### State Management
- Redux Toolkit for predictable state
- Async thunks for API calls
- Normalized data structure
- Optimistic updates where appropriate

### UI/UX
- Responsive design for mobile/tablet/desktop
- Dark mode support
- Keyboard shortcuts
- Accessible components (ARIA)

## Demo Credentials

- **Admin**: admin / admin123
- **Developer**: developer / dev123
- **Analyst**: analyst / analyst123
- **Viewer**: viewer / viewer123

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

## License

MIT