import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardActions,
  Chip,
  Alert,
  AlertTitle,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  IconButton,
  Tooltip,
  Tab,
  Tabs,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  CircularProgress,
  Divider,
  Stack,
  Badge
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Speed as SpeedIcon,
  Storage as StorageIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Info as InfoIcon,
  Build as BuildIcon,
  Assessment as AssessmentIcon,
  Code as CodeIcon,
  ContentCopy as CopyIcon,
  PlayArrow as ExecuteIcon,
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  Timeline as TimelineIcon,
  DataUsage as DataUsageIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Add as AddIcon,
  Remove as RemoveIcon
} from '@mui/icons-material';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip as ChartTooltip,
  Legend
} from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import { apiService } from '../services/api';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  ChartTooltip,
  Legend
);

interface IndexSuggestion {
  table: string;
  columns: string[];
  index_name: string;
  type: string;
  reason: string;
  frequency: number;
  impact_score: number;
  estimated_size_mb: number;
  write_overhead: number;
  recommendation: 'critical' | 'high' | 'medium' | 'low';
  benefits: string[];
  considerations: string[];
  create_sql?: string;
}

interface AnalysisResult {
  total_queries: number;
  patterns_found: Record<string, any>;
  problem_areas: any[];
  optimization_potential: number;
  summary: {
    total_patterns: number;
    total_queries_analyzed: number;
    slow_patterns: number;
    tables_affected: number;
    recommendation: string;
  };
}

interface ImpactAnalysis {
  table: string;
  columns: string[];
  before_metrics: {
    avg_cost: number;
    total_scanned_rows: number;
  };
  after_metrics: {
    avg_cost: number;
    total_scanned_rows: number;
  };
  improvement: {
    cost_reduction: number;
    percentage: number;
    scan_reduction: number;
  };
  affected_queries: any[];
  storage_impact: Record<string, any>;
  write_impact: Record<string, any>;
}

interface IndexAdvisorProps {
  database?: string;
  onIndexCreated?: () => void;
}

const IndexAdvisor: React.FC<IndexAdvisorProps> = ({ database, onIndexCreated }) => {
  const [loading, setLoading] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [suggestions, setSuggestions] = useState<IndexSuggestion[]>([]);
  const [analysis, setAnalysis] = useState<AnalysisResult | null>(null);
  const [selectedSuggestion, setSelectedSuggestion] = useState<IndexSuggestion | null>(null);
  const [impactAnalysis, setImpactAnalysis] = useState<ImpactAnalysis | null>(null);
  const [existingIndexes, setExistingIndexes] = useState<any[]>([]);
  const [selectedTab, setSelectedTab] = useState(0);
  const [filterLevel, setFilterLevel] = useState<string>('all');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showImpactDialog, setShowImpactDialog] = useState(false);

  useEffect(() => {
    if (database) {
      loadSuggestions();
    }
  }, [database]);

  const loadSuggestions = async () => {
    setLoading(true);
    try {
      const response = await apiService.get<any>(
        `/index-advisor/suggestions/${database}?limit=20`
      );
      setSuggestions(response.suggestions || []);
    } catch (error) {
      console.error('Error loading suggestions:', error);
    } finally {
      setLoading(false);
    }
  };

  const analyzeQueries = async () => {
    setAnalyzing(true);
    try {
      const response = await apiService.post<any>('/index-advisor/analyze', {
        database,
        queries: [] // Would typically pass slow queries here
      });

      setAnalysis(response.analysis);
      setSuggestions(response.suggestions);
    } catch (error) {
      console.error('Error analyzing queries:', error);
    } finally {
      setAnalyzing(false);
    }
  };

  const analyzeImpact = async (suggestion: IndexSuggestion) => {
    try {
      const response = await apiService.post<any>('/index-advisor/impact', {
        table: suggestion.table,
        columns: suggestion.columns,
        sample_queries: [] // Would pass relevant queries
      });

      setImpactAnalysis(response.impact);
      setSelectedSuggestion(suggestion);
      setShowImpactDialog(true);
    } catch (error) {
      console.error('Error analyzing impact:', error);
    }
  };

  const createIndex = async (suggestion: IndexSuggestion) => {
    try {
      await apiService.post('/index-advisor/create', {
        sql: suggestion.create_sql,
        database
      });

      if (onIndexCreated) {
        onIndexCreated();
      }

      setShowCreateDialog(false);
      loadSuggestions(); // Refresh suggestions
    } catch (error) {
      console.error('Error creating index:', error);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const getRecommendationColor = (level: string) => {
    switch (level) {
      case 'critical':
        return 'error';
      case 'high':
        return 'warning';
      case 'medium':
        return 'info';
      case 'low':
        return 'success';
      default:
        return 'default';
    }
  };

  const getRecommendationIcon = (level: string) => {
    switch (level) {
      case 'critical':
        return <ErrorIcon />;
      case 'high':
        return <WarningIcon />;
      case 'medium':
        return <InfoIcon />;
      case 'low':
        return <CheckCircleIcon />;
      default:
        return <InfoIcon />;
    }
  };

  const filteredSuggestions = filterLevel === 'all'
    ? suggestions
    : suggestions.filter(s => s.recommendation === filterLevel);

  const renderOverview = () => {
    if (!analysis) return null;

    const chartData = {
      labels: ['Slow Queries', 'Optimized', 'Remaining'],
      datasets: [{
        data: [
          analysis.total_queries,
          Math.round(analysis.total_queries * (analysis.optimization_potential / 100)),
          Math.round(analysis.total_queries * (1 - analysis.optimization_potential / 100))
        ],
        backgroundColor: ['#f44336', '#4caf50', '#ff9800'],
        borderWidth: 0
      }]
    };

    return (
      <Grid container spacing={3}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Total Queries Analyzed
              </Typography>
              <Typography variant="h3">
                {analysis.summary.total_queries_analyzed}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                {analysis.summary.slow_patterns} slow patterns
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Optimization Potential
              </Typography>
              <Typography variant="h3" color="primary">
                {analysis.optimization_potential.toFixed(1)}%
              </Typography>
              <LinearProgress
                variant="determinate"
                value={analysis.optimization_potential}
                sx={{ mt: 2 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Tables Affected
              </Typography>
              <Typography variant="h3">
                {analysis.summary.tables_affected}
              </Typography>
              <Chip
                label={analysis.summary.recommendation}
                color={
                  analysis.summary.recommendation === 'Critical' ? 'error' :
                  analysis.summary.recommendation === 'Moderate' ? 'warning' : 'success'
                }
                size="small"
                sx={{ mt: 1 }}
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom>
                Query Distribution
              </Typography>
              <Box sx={{ height: 150 }}>
                <Doughnut
                  data={chartData}
                  options={{
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        display: false
                      }
                    }
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  };

  const renderSuggestionCard = (suggestion: IndexSuggestion) => (
    <Card key={`${suggestion.table}_${suggestion.columns.join('_')}`} sx={{ mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            {getRecommendationIcon(suggestion.recommendation)}
            <Typography variant="h6">
              {suggestion.table}
            </Typography>
            <Chip
              label={suggestion.recommendation.toUpperCase()}
              color={getRecommendationColor(suggestion.recommendation) as any}
              size="small"
            />
          </Box>
          <Typography variant="h6" color="primary">
            Impact: {suggestion.impact_score.toFixed(0)}
          </Typography>
        </Box>

        <Box sx={{ mb: 2 }}>
          <Typography variant="subtitle2" color="textSecondary">
            Suggested Index
          </Typography>
          <Paper variant="outlined" sx={{ p: 1, mt: 1 }}>
            <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace' }}>
              {suggestion.index_name} ON ({suggestion.columns.join(', ')})
            </Typography>
          </Paper>
        </Box>

        <Grid container spacing={2}>
          <Grid item xs={12} md={6}>
            <Typography variant="subtitle2" color="textSecondary">
              Benefits
            </Typography>
            <List dense>
              {suggestion.benefits.map((benefit, idx) => (
                <ListItem key={idx}>
                  <ListItemIcon>
                    <CheckCircleIcon color="success" fontSize="small" />
                  </ListItemIcon>
                  <ListItemText primary={benefit} />
                </ListItem>
              ))}
            </List>
          </Grid>

          <Grid item xs={12} md={6}>
            <Typography variant="subtitle2" color="textSecondary">
              Considerations
            </Typography>
            <List dense>
              {suggestion.considerations.map((consideration, idx) => (
                <ListItem key={idx}>
                  <ListItemIcon>
                    <InfoIcon color="info" fontSize="small" />
                  </ListItemIcon>
                  <ListItemText primary={consideration} />
                </ListItem>
              ))}
            </List>
          </Grid>
        </Grid>

        <Box sx={{ mt: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
          <Chip
            icon={<SpeedIcon />}
            label={`${suggestion.frequency} queries affected`}
            size="small"
          />
          <Chip
            icon={<StorageIcon />}
            label={`~${suggestion.estimated_size_mb.toFixed(1)} MB`}
            size="small"
          />
          <Chip
            icon={<TrendingDownIcon />}
            label={`${suggestion.write_overhead.toFixed(1)}% write overhead`}
            size="small"
            color="warning"
          />
        </Box>

        {suggestion.create_sql && (
          <Accordion sx={{ mt: 2 }}>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
              <Typography>SQL Statement</Typography>
            </AccordionSummary>
            <AccordionDetails>
              <Paper variant="outlined" sx={{ p: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" color="textSecondary">
                    CREATE INDEX Statement
                  </Typography>
                  <IconButton
                    size="small"
                    onClick={() => copyToClipboard(suggestion.create_sql!)}
                  >
                    <CopyIcon fontSize="small" />
                  </IconButton>
                </Box>
                <Typography
                  variant="body2"
                  component="pre"
                  sx={{ fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}
                >
                  {suggestion.create_sql}
                </Typography>
              </Paper>
            </AccordionDetails>
          </Accordion>
        )}
      </CardContent>

      <CardActions>
        <Button
          size="small"
          startIcon={<AssessmentIcon />}
          onClick={() => analyzeImpact(suggestion)}
        >
          Analyze Impact
        </Button>
        <Button
          size="small"
          startIcon={<BuildIcon />}
          onClick={() => {
            setSelectedSuggestion(suggestion);
            setShowCreateDialog(true);
          }}
          color="primary"
          disabled={!suggestion.create_sql}
        >
          Create Index
        </Button>
        <Button
          size="small"
          startIcon={<CopyIcon />}
          onClick={() => copyToClipboard(suggestion.create_sql || '')}
          disabled={!suggestion.create_sql}
        >
          Copy SQL
        </Button>
      </CardActions>
    </Card>
  );

  const renderImpactChart = () => {
    if (!impactAnalysis) return null;

    const chartData = {
      labels: ['Before', 'After'],
      datasets: [
        {
          label: 'Average Cost',
          data: [
            impactAnalysis.before_metrics.avg_cost,
            impactAnalysis.after_metrics.avg_cost
          ],
          backgroundColor: ['rgba(255, 99, 132, 0.5)', 'rgba(75, 192, 192, 0.5)']
        },
        {
          label: 'Scanned Rows',
          data: [
            impactAnalysis.before_metrics.total_scanned_rows / 100, // Scale down for visibility
            impactAnalysis.after_metrics.total_scanned_rows / 100
          ],
          backgroundColor: ['rgba(255, 159, 64, 0.5)', 'rgba(54, 162, 235, 0.5)']
        }
      ]
    };

    return (
      <Box sx={{ height: 300 }}>
        <Bar
          data={chartData}
          options={{
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: {
                position: 'top' as const
              },
              title: {
                display: true,
                text: 'Performance Impact Analysis'
              }
            }
          }}
        />
      </Box>
    );
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h5">
            Index Advisor
          </Typography>
          <Typography variant="body2" color="textSecondary">
            AI-powered index recommendations for optimal query performance
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadSuggestions}
            disabled={loading}
          >
            Refresh
          </Button>
          <Button
            variant="contained"
            startIcon={analyzing ? <CircularProgress size={20} /> : <SearchIcon />}
            onClick={analyzeQueries}
            disabled={analyzing || !database}
          >
            Analyze Queries
          </Button>
        </Box>
      </Box>

      {/* Tabs */}
      <Paper sx={{ mb: 3 }}>
        <Tabs value={selectedTab} onChange={(e, v) => setSelectedTab(v)}>
          <Tab label="Overview" />
          <Tab label={`Suggestions (${suggestions.length})`} />
          <Tab label="Impact Analysis" />
          <Tab label="Implementation Plan" />
        </Tabs>
      </Paper>

      {/* Tab Content */}
      {selectedTab === 0 && (
        <Box>
          {analysis ? (
            renderOverview()
          ) : (
            <Alert severity="info">
              <AlertTitle>No Analysis Available</AlertTitle>
              Click "Analyze Queries" to start analyzing your database for index optimization opportunities.
            </Alert>
          )}
        </Box>
      )}

      {selectedTab === 1 && (
        <Box>
          {/* Filter Bar */}
          <Paper sx={{ p: 2, mb: 3 }}>
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
              <Typography variant="subtitle2">Filter by Priority:</Typography>
              <Chip
                label="All"
                onClick={() => setFilterLevel('all')}
                color={filterLevel === 'all' ? 'primary' : 'default'}
              />
              <Chip
                label="Critical"
                onClick={() => setFilterLevel('critical')}
                color={filterLevel === 'critical' ? 'error' : 'default'}
              />
              <Chip
                label="High"
                onClick={() => setFilterLevel('high')}
                color={filterLevel === 'high' ? 'warning' : 'default'}
              />
              <Chip
                label="Medium"
                onClick={() => setFilterLevel('medium')}
                color={filterLevel === 'medium' ? 'info' : 'default'}
              />
              <Chip
                label="Low"
                onClick={() => setFilterLevel('low')}
                color={filterLevel === 'low' ? 'success' : 'default'}
              />
              <Box sx={{ flexGrow: 1 }} />
              <Typography variant="body2" color="textSecondary">
                {filteredSuggestions.length} suggestions
              </Typography>
            </Box>
          </Paper>

          {/* Suggestions List */}
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
              <CircularProgress />
            </Box>
          ) : filteredSuggestions.length > 0 ? (
            filteredSuggestions.map(suggestion => renderSuggestionCard(suggestion))
          ) : (
            <Alert severity="info">
              No index suggestions found. Your database may already be well-optimized!
            </Alert>
          )}
        </Box>
      )}

      {selectedTab === 2 && (
        <Box>
          {impactAnalysis ? (
            <Grid container spacing={3}>
              <Grid item xs={12}>
                {renderImpactChart()}
              </Grid>
              <Grid item xs={12} md={4}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Performance Improvement
                    </Typography>
                    <Typography variant="h3" color="primary">
                      {impactAnalysis.improvement.percentage.toFixed(1)}%
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Cost reduction: {impactAnalysis.improvement.cost_reduction.toFixed(0)}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={4}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Row Scan Reduction
                    </Typography>
                    <Typography variant="h3" color="success">
                      {impactAnalysis.improvement.scan_reduction}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Fewer rows to examine
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={4}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      Storage Impact
                    </Typography>
                    <Typography variant="h3">
                      {impactAnalysis.storage_impact.index_size_mb} MB
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Additional storage required
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          ) : (
            <Alert severity="info">
              Select a suggestion and click "Analyze Impact" to see detailed performance analysis.
            </Alert>
          )}
        </Box>
      )}

      {selectedTab === 3 && (
        <Box>
          <Alert severity="info" sx={{ mb: 3 }}>
            <AlertTitle>Phased Implementation Approach</AlertTitle>
            Implement indexes in phases to minimize risk and monitor impact on write performance.
          </Alert>

          <Timeline sx={{ mt: 3 }}>
            <TimelineItem>
              <TimelineSeparator>
                <TimelineDot color="error">
                  <ErrorIcon />
                </TimelineDot>
                <TimelineConnector />
              </TimelineSeparator>
              <TimelineContent>
                <Typography variant="h6">Phase 1: Critical Indexes</Typography>
                <Typography variant="body2" color="textSecondary">
                  Implement immediately - High impact, low risk
                </Typography>
                <Box sx={{ mt: 1 }}>
                  {suggestions
                    .filter(s => s.recommendation === 'critical')
                    .slice(0, 3)
                    .map((s, idx) => (
                      <Chip
                        key={idx}
                        label={`${s.table}: ${s.columns.join(', ')}`}
                        size="small"
                        sx={{ mr: 1, mb: 1 }}
                      />
                    ))}
                </Box>
              </TimelineContent>
            </TimelineItem>
          </Timeline>
        </Box>
      )}

      {/* Create Index Dialog */}
      <Dialog open={showCreateDialog} onClose={() => setShowCreateDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create Index</DialogTitle>
        <DialogContent>
          {selectedSuggestion && (
            <Box>
              <Alert severity="warning" sx={{ mb: 2 }}>
                Creating indexes will temporarily lock the table. Consider running during low-traffic periods.
              </Alert>

              <Typography variant="subtitle2" gutterBottom>
                Index Details
              </Typography>
              <TableContainer component={Paper} variant="outlined" sx={{ mb: 2 }}>
                <Table size="small">
                  <TableBody>
                    <TableRow>
                      <TableCell>Table</TableCell>
                      <TableCell>{selectedSuggestion.table}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>Columns</TableCell>
                      <TableCell>{selectedSuggestion.columns.join(', ')}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>Index Name</TableCell>
                      <TableCell>{selectedSuggestion.index_name}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>Estimated Size</TableCell>
                      <TableCell>{selectedSuggestion.estimated_size_mb.toFixed(1)} MB</TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </TableContainer>

              <Typography variant="subtitle2" gutterBottom>
                SQL Statement
              </Typography>
              <TextField
                fullWidth
                multiline
                rows={4}
                value={selectedSuggestion.create_sql}
                InputProps={{
                  readOnly: true,
                  sx: { fontFamily: 'monospace' }
                }}
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowCreateDialog(false)}>Cancel</Button>
          <Button
            onClick={() => selectedSuggestion && createIndex(selectedSuggestion)}
            variant="contained"
            color="primary"
            startIcon={<BuildIcon />}
          >
            Create Index
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

// Missing imports for Timeline components
import {
  Timeline,
  TimelineItem,
  TimelineSeparator,
  TimelineDot,
  TimelineConnector,
  TimelineContent
} from '@mui/lab';

export default IndexAdvisor;