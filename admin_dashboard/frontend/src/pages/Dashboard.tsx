import React, { useEffect, useState } from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Paper,
  LinearProgress,
  Chip,
  Button,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Storage,
  Speed,
  People,
  Warning,
  CheckCircle,
  Error,
  Refresh,
  TrendingUp,
  TrendingDown,
  Timeline,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as ChartTooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

import { apiService } from '../services/api';
import { DatabaseMetrics, RealtimeMetrics, SlowQuery } from '../types';
import { wsService } from '../services/websocket';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

const Dashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<DatabaseMetrics | null>(null);
  const [realtimeMetrics, setRealtimeMetrics] = useState<RealtimeMetrics | null>(null);
  const [slowQueries, setSlowQueries] = useState<SlowQuery[]>([]);
  const [performanceData, setPerformanceData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadDashboardData();
    subscribeToRealtimeUpdates();

    return () => {
      unsubscribeFromRealtimeUpdates();
    };
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [metricsData, slowQueriesData, performanceData] = await Promise.all([
        apiService.get<DatabaseMetrics>('/monitoring/overview'),
        apiService.get<SlowQuery[]>('/monitoring/slow-queries?limit=5'),
        apiService.get<any>('/monitoring/performance?timeframe=1h'),
      ]);

      setMetrics(metricsData);
      setSlowQueries(slowQueriesData);
      setPerformanceData(performanceData.cpu_usage || []);
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  const subscribeToRealtimeUpdates = () => {
    wsService.on('metrics:update', (data: RealtimeMetrics) => {
      setRealtimeMetrics(data);
    });

    wsService.requestMetrics('realtime');
  };

  const unsubscribeFromRealtimeUpdates = () => {
    wsService.off('metrics:update');
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadDashboardData();
    setRefreshing(false);
  };

  const formatUptime = (percentage: number) => {
    if (percentage >= 99.9) {
      return { value: percentage, status: 'success', label: 'Excellent' };
    } else if (percentage >= 99) {
      return { value: percentage, status: 'warning', label: 'Good' };
    } else {
      return { value: percentage, status: 'error', label: 'Poor' };
    }
  };

  const StatCard: React.FC<{
    title: string;
    value: string | number;
    icon: React.ReactNode;
    trend?: number;
    color?: string;
  }> = ({ title, value, icon, trend, color = 'primary.main' }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 40,
              height: 40,
              borderRadius: 2,
              backgroundColor: color,
              color: 'white',
              mr: 2,
            }}
          >
            {icon}
          </Box>
          <Box sx={{ flexGrow: 1 }}>
            <Typography color="textSecondary" variant="body2">
              {title}
            </Typography>
            <Typography variant="h5" component="div">
              {value}
            </Typography>
          </Box>
          {trend !== undefined && (
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              {trend > 0 ? (
                <TrendingUp color="success" />
              ) : (
                <TrendingDown color="error" />
              )}
              <Typography
                variant="body2"
                color={trend > 0 ? 'success.main' : 'error.main'}
              >
                {Math.abs(trend)}%
              </Typography>
            </Box>
          )}
        </Box>
      </CardContent>
    </Card>
  );

  if (loading) {
    return <LinearProgress />;
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Dashboard</Typography>
        <Tooltip title="Refresh">
          <IconButton onClick={handleRefresh} disabled={refreshing}>
            <Refresh />
          </IconButton>
        </Tooltip>
      </Box>

      {/* Overview Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Databases"
            value={metrics?.databaseCount || 0}
            icon={<Storage />}
            color="primary.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Tables"
            value={metrics?.tableCount || 0}
            icon={<Storage />}
            color="secondary.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Connections"
            value={realtimeMetrics?.activeConnections || metrics?.activeConnections || 0}
            icon={<People />}
            trend={5}
            color="info.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Queries/Second"
            value={realtimeMetrics?.qps || metrics?.qps || 0}
            icon={<Speed />}
            trend={-2}
            color="warning.main"
          />
        </Grid>
      </Grid>

      {/* Performance Charts */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={8}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              System Performance
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={performanceData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="timestamp" />
                <YAxis />
                <ChartTooltip />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="value"
                  stroke="#8884d8"
                  name="CPU %"
                  strokeWidth={2}
                />
              </LineChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, height: '100%' }}>
            <Typography variant="h6" gutterBottom>
              System Health
            </Typography>
            <Box sx={{ mt: 3 }}>
              <Box sx={{ mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">CPU Usage</Typography>
                  <Typography variant="body2">
                    {realtimeMetrics?.cpu || 0}%
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={realtimeMetrics?.cpu || 0}
                  color={realtimeMetrics?.cpu > 80 ? 'error' : 'primary'}
                />
              </Box>

              <Box sx={{ mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Memory Usage</Typography>
                  <Typography variant="body2">
                    {realtimeMetrics?.memory || 0}%
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={realtimeMetrics?.memory || 0}
                  color={realtimeMetrics?.memory > 80 ? 'error' : 'primary'}
                />
              </Box>

              <Box sx={{ mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Response Time</Typography>
                  <Typography variant="body2">
                    {realtimeMetrics?.responseTimeMs || 0}ms
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={Math.min((realtimeMetrics?.responseTimeMs || 0) / 10, 100)}
                  color={realtimeMetrics?.responseTimeMs > 500 ? 'error' : 'primary'}
                />
              </Box>

              <Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Uptime</Typography>
                  <Typography variant="body2">
                    {metrics?.uptimePercentage || 0}%
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={metrics?.uptimePercentage || 0}
                  color="success"
                />
              </Box>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* Slow Queries and Alerts */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Slow Queries
            </Typography>
            {slowQueries.length === 0 ? (
              <Typography color="textSecondary">
                No slow queries detected
              </Typography>
            ) : (
              <Box>
                {slowQueries.map((query, index) => (
                  <Box
                    key={query.queryId}
                    sx={{
                      p: 1,
                      mb: 1,
                      borderLeft: 3,
                      borderColor: 'warning.main',
                      backgroundColor: 'action.hover',
                    }}
                  >
                    <Typography variant="body2" noWrap>
                      {query.query}
                    </Typography>
                    <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                      <Chip
                        label={`${query.executionTime}ms`}
                        size="small"
                        color="warning"
                      />
                      <Chip
                        label={query.database}
                        size="small"
                        variant="outlined"
                      />
                    </Box>
                  </Box>
                ))}
                <Button
                  fullWidth
                  variant="text"
                  sx={{ mt: 2 }}
                  onClick={() => {/* Navigate to query analyzer */}}
                >
                  View All Slow Queries
                </Button>
              </Box>
            )}
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Recent Alerts
            </Typography>
            <Box>
              <Box
                sx={{
                  p: 1,
                  mb: 1,
                  display: 'flex',
                  alignItems: 'center',
                  borderLeft: 3,
                  borderColor: 'error.main',
                  backgroundColor: 'action.hover',
                }}
              >
                <Error color="error" sx={{ mr: 2 }} />
                <Box sx={{ flexGrow: 1 }}>
                  <Typography variant="body2">
                    High CPU usage detected (92%)
                  </Typography>
                  <Typography variant="caption" color="textSecondary">
                    2 minutes ago
                  </Typography>
                </Box>
              </Box>

              <Box
                sx={{
                  p: 1,
                  mb: 1,
                  display: 'flex',
                  alignItems: 'center',
                  borderLeft: 3,
                  borderColor: 'warning.main',
                  backgroundColor: 'action.hover',
                }}
              >
                <Warning color="warning" sx={{ mr: 2 }} />
                <Box sx={{ flexGrow: 1 }}>
                  <Typography variant="body2">
                    Slow query threshold exceeded
                  </Typography>
                  <Typography variant="caption" color="textSecondary">
                    15 minutes ago
                  </Typography>
                </Box>
              </Box>

              <Box
                sx={{
                  p: 1,
                  mb: 1,
                  display: 'flex',
                  alignItems: 'center',
                  borderLeft: 3,
                  borderColor: 'success.main',
                  backgroundColor: 'action.hover',
                }}
              >
                <CheckCircle color="success" sx={{ mr: 2 }} />
                <Box sx={{ flexGrow: 1 }}>
                  <Typography variant="body2">
                    Backup completed successfully
                  </Typography>
                  <Typography variant="caption" color="textSecondary">
                    1 hour ago
                  </Typography>
                </Box>
              </Box>

              <Button
                fullWidth
                variant="text"
                sx={{ mt: 2 }}
                onClick={() => {/* Navigate to alerts */}}
              >
                View All Alerts
              </Button>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;