import React, { useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';

import Layout from './components/Layout';
import PrivateRoute from './components/PrivateRoute';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import SchemaManager from './pages/SchemaManager';
import MigrationManager from './pages/MigrationManager';
import QueryAnalyzer from './pages/QueryAnalyzer';
import UserManagement from './pages/UserManagement';
import Monitoring from './pages/Monitoring';
import Alerts from './pages/Alerts';
import Backups from './pages/Backups';
import Settings from './pages/Settings';

import { RootState, AppDispatch } from './store';
import { checkAuthStatus } from './store/authSlice';
import { initializeWebSocket } from './services/websocket';

const App: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { isAuthenticated, isLoading } = useSelector(
    (state: RootState) => state.auth
  );

  useEffect(() => {
    // Check authentication status on mount
    dispatch(checkAuthStatus());
  }, [dispatch]);

  useEffect(() => {
    // Initialize WebSocket connection when authenticated
    if (isAuthenticated) {
      const cleanup = initializeWebSocket();
      return cleanup;
    }
  }, [isAuthenticated]);

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <PrivateRoute>
            <Layout />
          </PrivateRoute>
        }
      >
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="schemas" element={<SchemaManager />} />
        <Route path="migrations" element={<MigrationManager />} />
        <Route path="query" element={<QueryAnalyzer />} />
        <Route path="users" element={<UserManagement />} />
        <Route path="monitoring" element={<Monitoring />} />
        <Route path="alerts" element={<Alerts />} />
        <Route path="backups" element={<Backups />} />
        <Route path="settings" element={<Settings />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

export default App;