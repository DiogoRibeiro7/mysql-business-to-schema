import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  CircularProgress,
  IconButton,
  Tooltip,
  Divider,
  Card,
  CardContent,
  Chip,
  Stack
} from '@mui/material';
import {
  PlayArrow as RunIcon,
  Analytics as AnalyzeIcon,
  Speed as OptimizeIcon,
  History as HistoryIcon,
  Save as SaveIcon,
  Share as ShareIcon,
  Code as FormatIcon,
  Clear as ClearIcon,
  Info as InfoIcon
} from '@mui/icons-material';
import { useDispatch, useSelector } from 'react-redux';
import { RootState, AppDispatch } from '../store';
import {
  executeQuery,
  explainQuery,
  optimizeQuery,
  setCurrentQuery,
  clearQueryResult,
  fetchQueryHistory
} from '../store/querySlice';
import QueryVisualizer from '../components/QueryVisualizer';
import QueryManager from '../components/QueryManager';
import MonacoEditor from 'react-monaco-editor';

const QueryAnalyzer: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const {
    currentQuery,
    queryResult,
    queryHistory,
    isExecuting,
    isLoading,
    error
  } = useSelector((state: RootState) => state.query);

  const [selectedDatabase, setSelectedDatabase] = useState('example_01_clinic');
  const [queryLimit, setQueryLimit] = useState(100);
  const [showHistory, setShowHistory] = useState(false);
  const [showOptimization, setShowOptimization] = useState(false);
  const [showQueryManager, setShowQueryManager] = useState(false);
  const [optimizedQuery, setOptimizedQuery] = useState('');

  // Available databases (examples)
  const databases = [
    'example_01_clinic',
    'example_02_iot_bins',
    'example_03_smart_energy',
    'example_04_ecommerce',
    'example_05_industrial_iot',
    'example_06_smart_agriculture',
    'example_07_fleet_management',
    'example_08_healthcare_iot',
    'example_09_streaming_ml',
    'example_10_fintech'
  ];

  // Sample queries for quick testing
  const sampleQueries = [
    {
      label: 'Select with Join',
      query: `SELECT p.name, a.appointment_date, a.status
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
WHERE a.status = 'scheduled'
LIMIT 10;`
    },
    {
      label: 'Aggregation',
      query: `SELECT department, COUNT(*) as count, AVG(salary) as avg_salary
FROM employees
GROUP BY department
ORDER BY count DESC;`
    },
    {
      label: 'Time Series',
      query: `SELECT DATE(created_at) as date, COUNT(*) as daily_count
FROM events
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(created_at)
ORDER BY date;`
    }
  ];

  useEffect(() => {
    // Load query history on mount
    dispatch(fetchQueryHistory(50));
  }, [dispatch]);

  const handleExecuteQuery = () => {
    if (!currentQuery.trim()) {
      return;
    }
    dispatch(executeQuery({
      query: currentQuery,
      database: selectedDatabase,
      limit: queryLimit
    }));
  };

  const handleExplainQuery = () => {
    if (!currentQuery.trim()) {
      return;
    }
    dispatch(explainQuery({
      query: currentQuery,
      database: selectedDatabase
    }));
  };

  const handleOptimizeQuery = async () => {
    if (!currentQuery.trim()) {
      return;
    }
    setShowOptimization(true);
    const result = await dispatch(optimizeQuery({
      query: currentQuery,
      database: selectedDatabase
    })).unwrap();

    if (result?.optimizedQuery) {
      setOptimizedQuery(result.optimizedQuery);
    }
  };

  const handleFormatQuery = () => {
    // Simple SQL formatting
    const formatted = currentQuery
      .replace(/\s+/g, ' ')
      .replace(/,/g, ',\n  ')
      .replace(/FROM/gi, '\nFROM')
      .replace(/WHERE/gi, '\nWHERE')
      .replace(/GROUP BY/gi, '\nGROUP BY')
      .replace(/ORDER BY/gi, '\nORDER BY')
      .replace(/JOIN/gi, '\nJOIN')
      .replace(/LIMIT/gi, '\nLIMIT');

    dispatch(setCurrentQuery(formatted));
  };

  const handleClearQuery = () => {
    dispatch(setCurrentQuery(''));
    dispatch(clearQueryResult());
    setOptimizedQuery('');
    setShowOptimization(false);
  };

  const handleLoadSampleQuery = (query: string) => {
    dispatch(setCurrentQuery(query));
  };

  const handleLoadHistoryQuery = (query: string) => {
    dispatch(setCurrentQuery(query));
    setShowHistory(false);
  };

  const handleLoadSavedQuery = (savedQuery: any) => {
    dispatch(setCurrentQuery(savedQuery.sql));
    setSelectedDatabase(savedQuery.database);
    setShowQueryManager(false);
  };

  return (
    <Box>
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4">
          Query Analyzer & Visualizer
        </Typography>
        <Stack direction="row" spacing={1}>
          <Chip
            label="Chart.js Enabled"
            color="success"
            size="small"
            icon={<AnalyzeIcon />}
          />
          <Chip
            label="Visual Mode"
            color="primary"
            size="small"
          />
        </Stack>
      </Box>

      <Grid container spacing={3}>
        {/* Query Editor Section */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3 }}>
            <Box sx={{ mb: 2, display: 'flex', gap: 2, alignItems: 'center' }}>
              <FormControl size="small" sx={{ minWidth: 200 }}>
                <InputLabel>Database</InputLabel>
                <Select
                  value={selectedDatabase}
                  onChange={(e) => setSelectedDatabase(e.target.value)}
                  label="Database"
                >
                  {databases.map((db) => (
                    <MenuItem key={db} value={db}>
                      {db.replace(/_/g, ' ')}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              <TextField
                size="small"
                type="number"
                label="Limit"
                value={queryLimit}
                onChange={(e) => setQueryLimit(parseInt(e.target.value) || 100)}
                sx={{ width: 100 }}
              />

              <Box sx={{ flexGrow: 1 }} />

              <Button
                size="small"
                variant="outlined"
                onClick={() => setShowHistory(!showHistory)}
                startIcon={<HistoryIcon />}
              >
                History
              </Button>

              <Button
                size="small"
                variant="outlined"
                onClick={() => setShowQueryManager(!showQueryManager)}
                startIcon={<SaveIcon />}
              >
                Saved Queries
              </Button>
            </Box>

            {/* Sample Queries */}
            <Box sx={{ mb: 2 }}>
              <Typography variant="caption" color="textSecondary">
                Sample Queries:
              </Typography>
              <Box sx={{ mt: 1, display: 'flex', gap: 1 }}>
                {sampleQueries.map((sample, idx) => (
                  <Chip
                    key={idx}
                    label={sample.label}
                    size="small"
                    onClick={() => handleLoadSampleQuery(sample.query)}
                    clickable
                  />
                ))}
              </Box>
            </Box>

            {/* SQL Editor */}
            <Box sx={{ mb: 2, border: '1px solid #ddd', borderRadius: 1 }}>
              <MonacoEditor
                height="250"
                language="sql"
                theme="vs-light"
                value={currentQuery}
                onChange={(value) => dispatch(setCurrentQuery(value || ''))}
                options={{
                  minimap: { enabled: false },
                  fontSize: 14,
                  wordWrap: 'on',
                  lineNumbers: 'on',
                  folding: false,
                  scrollBeyondLastLine: false,
                  automaticLayout: true
                }}
              />
            </Box>

            {/* Action Buttons */}
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Button
                variant="contained"
                onClick={handleExecuteQuery}
                disabled={isExecuting || !currentQuery.trim()}
                startIcon={isExecuting ? <CircularProgress size={16} /> : <RunIcon />}
              >
                Execute
              </Button>
              <Button
                variant="outlined"
                onClick={handleExplainQuery}
                disabled={isExecuting || !currentQuery.trim()}
                startIcon={<InfoIcon />}
              >
                Explain
              </Button>
              <Button
                variant="outlined"
                onClick={handleOptimizeQuery}
                disabled={isExecuting || !currentQuery.trim()}
                startIcon={<OptimizeIcon />}
              >
                Optimize
              </Button>
              <Button
                variant="outlined"
                onClick={handleFormatQuery}
                disabled={!currentQuery.trim()}
                startIcon={<FormatIcon />}
              >
                Format
              </Button>
              <Button
                variant="outlined"
                color="error"
                onClick={handleClearQuery}
                startIcon={<ClearIcon />}
              >
                Clear
              </Button>
            </Box>

            {/* Error Display */}
            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
          </Paper>
        </Grid>

        {/* Query Optimization Suggestions */}
        {showOptimization && optimizedQuery && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Query Optimization Suggestions
                </Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} md={6}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Original Query
                    </Typography>
                    <Paper variant="outlined" sx={{ p: 2, mt: 1 }}>
                      <Typography variant="body2" component="pre">
                        {currentQuery}
                      </Typography>
                    </Paper>
                  </Grid>
                  <Grid item xs={12} md={6}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Optimized Query
                    </Typography>
                    <Paper variant="outlined" sx={{ p: 2, mt: 1 }}>
                      <Typography variant="body2" component="pre">
                        {optimizedQuery}
                      </Typography>
                    </Paper>
                  </Grid>
                </Grid>
                <Box sx={{ mt: 2 }}>
                  <Button
                    variant="contained"
                    size="small"
                    onClick={() => dispatch(setCurrentQuery(optimizedQuery))}
                  >
                    Use Optimized Query
                  </Button>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        )}

        {/* Visual Results Section */}
        {queryResult && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Visual Query Results
              </Typography>
              <Divider sx={{ mb: 2 }} />
              <QueryVisualizer
                queryResult={queryResult}
                showQueryPlan={true}
                showCostAnalysis={true}
              />
            </Paper>
          </Grid>
        )}

        {/* Query Manager */}
        {showQueryManager && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <QueryManager
                onLoadQuery={handleLoadSavedQuery}
                currentQuery={currentQuery}
                currentDatabase={selectedDatabase}
              />
            </Paper>
          </Grid>
        )}

        {/* Query History */}
        {showHistory && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Query History
              </Typography>
              <Divider sx={{ mb: 2 }} />
              {queryHistory.length > 0 ? (
                <Box>
                  {queryHistory.slice(0, 10).map((query, idx) => (
                    <Card key={idx} sx={{ mb: 1 }} variant="outlined">
                      <CardContent sx={{ py: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" sx={{ flex: 1 }}>
                            {query.query?.substring(0, 100)}...
                          </Typography>
                          <Chip
                            label={query.database || 'unknown'}
                            size="small"
                          />
                          <Button
                            size="small"
                            onClick={() => handleLoadHistoryQuery(query.query)}
                          >
                            Load
                          </Button>
                        </Box>
                      </CardContent>
                    </Card>
                  ))}
                </Box>
              ) : (
                <Typography variant="body2" color="textSecondary">
                  No query history available
                </Typography>
              )}
            </Paper>
          </Grid>
        )}
      </Grid>
    </Box>
  );
};

export default QueryAnalyzer;