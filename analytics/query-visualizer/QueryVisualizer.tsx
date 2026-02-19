/**
 * Query Result Visualizer Component
 *
 * Provides intelligent visualization of SQL query results with:
 * - Automatic chart type detection
 * - Multiple visualization options
 * - Query plan visualization
 * - Cost analysis display
 */

import React, { useState, useEffect, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  ButtonGroup,
  Card,
  CardContent,
  Grid,
  Tabs,
  Tab,
  Tooltip,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  Switch,
  FormControlLabel,
  Alert,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
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
  Legend,
  RadialLinearScale,
  Filler,
} from 'chart.js';
import { Line, Bar, Pie, Doughnut, Radar, Scatter, Bubble } from 'react-chartjs-2';
import {
  BarChart,
  ShowChart,
  PieChart,
  BubbleChart,
  ScatterPlot,
  Timeline,
  TableChart,
  Download,
  Settings,
  ExpandMore,
  TrendingUp,
  Speed,
  Storage,
  Assignment,
} from '@mui/icons-material';
import { saveAs } from 'file-saver';
import * as XLSX from 'xlsx';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  ChartTooltip,
  Legend,
  RadialLinearScale,
  Filler
);

// Types
interface QueryResult {
  columns: string[];
  rows: any[][];
  executionTime: number;
  rowsAffected: number;
}

interface QueryPlan {
  id: number;
  selectType: string;
  table: string;
  type: string;
  possibleKeys: string | null;
  key: string | null;
  keyLen: string | null;
  ref: string | null;
  rows: number;
  filtered: number;
  extra: string;
  cost?: number;
}

interface VisualizationConfig {
  type: 'bar' | 'line' | 'pie' | 'doughnut' | 'radar' | 'scatter' | 'bubble' | 'table';
  xAxis: string;
  yAxis: string[];
  aggregation: 'sum' | 'avg' | 'count' | 'min' | 'max';
  groupBy?: string;
  sortBy?: 'asc' | 'desc';
  top?: number;
}

interface ChartRecommendation {
  type: string;
  confidence: number;
  reason: string;
  config: Partial<VisualizationConfig>;
}

// Utility functions
const detectDataTypes = (rows: any[][], columns: string[]) => {
  const types: Record<string, string> = {};

  columns.forEach((col, idx) => {
    const values = rows.map(row => row[idx]).filter(v => v !== null && v !== undefined);

    if (values.length === 0) {
      types[col] = 'unknown';
      return;
    }

    // Check if all values are numbers
    if (values.every(v => !isNaN(Number(v)))) {
      types[col] = 'number';
    }
    // Check if all values are dates
    else if (values.every(v => !isNaN(Date.parse(v)))) {
      types[col] = 'date';
    }
    // Otherwise string
    else {
      types[col] = 'string';
    }
  });

  return types;
};

const recommendChartTypes = (
  rows: any[][],
  columns: string[],
  dataTypes: Record<string, string>
): ChartRecommendation[] => {
  const recommendations: ChartRecommendation[] = [];

  const numericColumns = Object.entries(dataTypes)
    .filter(([_, type]) => type === 'number')
    .map(([col]) => col);

  const stringColumns = Object.entries(dataTypes)
    .filter(([_, type]) => type === 'string')
    .map(([col]) => col);

  const dateColumns = Object.entries(dataTypes)
    .filter(([_, type]) => type === 'date')
    .map(([col]) => col);

  // Bar chart - good for categories vs numbers
  if (stringColumns.length > 0 && numericColumns.length > 0) {
    recommendations.push({
      type: 'bar',
      confidence: 0.9,
      reason: 'Perfect for comparing values across categories',
      config: {
        type: 'bar',
        xAxis: stringColumns[0],
        yAxis: [numericColumns[0]],
        aggregation: 'sum'
      }
    });
  }

  // Line chart - good for time series
  if (dateColumns.length > 0 && numericColumns.length > 0) {
    recommendations.push({
      type: 'line',
      confidence: 0.95,
      reason: 'Ideal for showing trends over time',
      config: {
        type: 'line',
        xAxis: dateColumns[0],
        yAxis: numericColumns,
        aggregation: 'avg'
      }
    });
  }

  // Pie chart - good for parts of a whole
  if (stringColumns.length > 0 && numericColumns.length > 0 && rows.length < 20) {
    recommendations.push({
      type: 'pie',
      confidence: 0.8,
      reason: 'Great for showing proportions',
      config: {
        type: 'pie',
        xAxis: stringColumns[0],
        yAxis: [numericColumns[0]],
        aggregation: 'sum'
      }
    });
  }

  // Scatter plot - good for correlations
  if (numericColumns.length >= 2) {
    recommendations.push({
      type: 'scatter',
      confidence: 0.85,
      reason: 'Excellent for finding correlations between variables',
      config: {
        type: 'scatter',
        xAxis: numericColumns[0],
        yAxis: [numericColumns[1]],
        aggregation: 'sum'
      }
    });
  }

  // Always include table view
  recommendations.push({
    type: 'table',
    confidence: 1.0,
    reason: 'View raw data in tabular format',
    config: {
      type: 'table',
      xAxis: columns[0],
      yAxis: columns.slice(1),
      aggregation: 'sum'
    }
  });

  return recommendations.sort((a, b) => b.confidence - a.confidence);
};

// Main Component
export const QueryVisualizer: React.FC<{
  queryResult: QueryResult;
  queryPlan?: QueryPlan[];
  onExport?: (format: 'csv' | 'excel' | 'json' | 'pdf') => void;
}> = ({ queryResult, queryPlan, onExport }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [visualizationConfig, setVisualizationConfig] = useState<VisualizationConfig>({
    type: 'table',
    xAxis: '',
    yAxis: [],
    aggregation: 'sum'
  });
  const [settingsAnchor, setSettingsAnchor] = useState<null | HTMLElement>(null);
  const [exportAnchor, setExportAnchor] = useState<null | HTMLElement>(null);
  const [darkMode, setDarkMode] = useState(true);

  const dataTypes = useMemo(
    () => detectDataTypes(queryResult.rows, queryResult.columns),
    [queryResult]
  );

  const recommendations = useMemo(
    () => recommendChartTypes(queryResult.rows, queryResult.columns, dataTypes),
    [queryResult, dataTypes]
  );

  // Auto-select best visualization on mount
  useEffect(() => {
    if (recommendations.length > 0) {
      setVisualizationConfig({
        ...visualizationConfig,
        ...recommendations[0].config
      });
    }
  }, [recommendations]);

  const prepareChartData = () => {
    const { xAxis, yAxis, aggregation, groupBy, sortBy, top } = visualizationConfig;

    if (!xAxis || yAxis.length === 0) {
      return null;
    }

    const xIndex = queryResult.columns.indexOf(xAxis);
    const yIndices = yAxis.map(y => queryResult.columns.indexOf(y));

    // Group and aggregate data
    const aggregatedData = new Map<string, number[]>();

    queryResult.rows.forEach(row => {
      const key = String(row[xIndex]);
      const values = yIndices.map(idx => parseFloat(row[idx]) || 0);

      if (!aggregatedData.has(key)) {
        aggregatedData.set(key, new Array(yIndices.length).fill(0));
      }

      const current = aggregatedData.get(key)!;
      values.forEach((val, idx) => {
        switch (aggregation) {
          case 'sum':
            current[idx] += val;
            break;
          case 'avg':
            current[idx] = (current[idx] + val) / 2;
            break;
          case 'max':
            current[idx] = Math.max(current[idx], val);
            break;
          case 'min':
            current[idx] = Math.min(current[idx], val);
            break;
          case 'count':
            current[idx]++;
            break;
        }
      });
    });

    // Sort if needed
    let entries = Array.from(aggregatedData.entries());
    if (sortBy) {
      entries.sort((a, b) => {
        const sumA = a[1].reduce((sum, val) => sum + val, 0);
        const sumB = b[1].reduce((sum, val) => sum + val, 0);
        return sortBy === 'asc' ? sumA - sumB : sumB - sumA;
      });
    }

    // Limit to top N if specified
    if (top && top > 0) {
      entries = entries.slice(0, top);
    }

    const labels = entries.map(([key]) => key);
    const datasets = yAxis.map((col, idx) => ({
      label: col,
      data: entries.map(([_, values]) => values[idx]),
      backgroundColor: `hsla(${idx * 60}, 70%, 50%, 0.6)`,
      borderColor: `hsla(${idx * 60}, 70%, 50%, 1)`,
      borderWidth: 2,
    }));

    return { labels, datasets };
  };

  const chartData = prepareChartData();

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
        labels: {
          color: darkMode ? '#fff' : '#000',
        }
      },
      title: {
        display: true,
        text: `${visualizationConfig.xAxis} vs ${visualizationConfig.yAxis.join(', ')}`,
        color: darkMode ? '#fff' : '#000',
      },
      tooltip: {
        mode: 'index' as const,
        intersect: false,
      }
    },
    scales: visualizationConfig.type !== 'pie' && visualizationConfig.type !== 'doughnut' ? {
      x: {
        grid: {
          color: darkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          color: darkMode ? '#fff' : '#000',
        }
      },
      y: {
        grid: {
          color: darkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)',
        },
        ticks: {
          color: darkMode ? '#fff' : '#000',
        }
      }
    } : undefined,
  };

  const renderChart = () => {
    if (!chartData) {
      return (
        <Alert severity="info">
          Please select axes for visualization
        </Alert>
      );
    }

    const chartHeight = '400px';

    switch (visualizationConfig.type) {
      case 'bar':
        return <Box height={chartHeight}><Bar data={chartData} options={chartOptions} /></Box>;
      case 'line':
        return <Box height={chartHeight}><Line data={chartData} options={chartOptions} /></Box>;
      case 'pie':
        return <Box height={chartHeight}><Pie data={chartData} options={chartOptions} /></Box>;
      case 'doughnut':
        return <Box height={chartHeight}><Doughnut data={chartData} options={chartOptions} /></Box>;
      case 'radar':
        return <Box height={chartHeight}><Radar data={chartData} options={chartOptions} /></Box>;
      case 'scatter':
        return <Box height={chartHeight}><Scatter data={chartData} options={chartOptions} /></Box>;
      default:
        return <Typography>Unsupported chart type</Typography>;
    }
  };

  const renderQueryPlan = () => {
    if (!queryPlan || queryPlan.length === 0) {
      return <Typography>No query plan available</Typography>;
    }

    return (
      <Box>
        <Typography variant="h6" gutterBottom>
          Query Execution Plan
        </Typography>
        {queryPlan.map((step, idx) => (
          <Accordion key={idx} defaultExpanded={idx === 0}>
            <AccordionSummary expandIcon={<ExpandMore />}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Chip
                  label={step.selectType}
                  size="small"
                  color={step.type === 'ALL' ? 'error' : 'primary'}
                />
                <Typography>{step.table}</Typography>
                <Typography variant="body2" color="text.secondary">
                  {step.rows} rows
                </Typography>
              </Box>
            </AccordionSummary>
            <AccordionDetails>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Access Type</Typography>
                  <Chip
                    label={step.type}
                    size="small"
                    color={
                      step.type === 'ALL' ? 'error' :
                      step.type === 'index' ? 'success' :
                      'default'
                    }
                  />
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Key Used</Typography>
                  <Typography>{step.key || 'None'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Possible Keys</Typography>
                  <Typography>{step.possibleKeys || 'None'}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Filtered</Typography>
                  <Typography>{step.filtered}%</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="subtitle2">Extra</Typography>
                  <Typography variant="body2">{step.extra}</Typography>
                </Grid>
                {step.cost && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2">Estimated Cost</Typography>
                    <Typography>{step.cost.toFixed(2)}</Typography>
                  </Grid>
                )}
              </Grid>
            </AccordionDetails>
          </Accordion>
        ))}
      </Box>
    );
  };

  const renderCostAnalysis = () => {
    const totalRows = queryPlan?.reduce((sum, step) => sum + step.rows, 0) || 0;
    const hasFullScan = queryPlan?.some(step => step.type === 'ALL');
    const unusedIndexes = queryPlan?.filter(
      step => step.possibleKeys && !step.key
    ).length || 0;

    return (
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1}>
                <Speed color="primary" />
                <Typography variant="h6">Execution Time</Typography>
              </Box>
              <Typography variant="h4">
                {queryResult.executionTime}ms
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {queryResult.executionTime < 100 ? 'Fast' :
                 queryResult.executionTime < 500 ? 'Moderate' : 'Slow'}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1}>
                <Storage color="primary" />
                <Typography variant="h6">Rows Examined</Typography>
              </Box>
              <Typography variant="h4">
                {totalRows.toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {queryResult.rowsAffected} returned
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1}>
                <TrendingUp color={hasFullScan ? 'error' : 'success'} />
                <Typography variant="h6">Optimization</Typography>
              </Box>
              <Typography variant="h4">
                {hasFullScan ? 'Needs Index' : 'Optimized'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {unusedIndexes > 0 && `${unusedIndexes} unused indexes`}
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Alert
            severity={hasFullScan ? 'warning' : 'success'}
            icon={<Assignment />}
          >
            <Typography variant="subtitle1">Performance Recommendations</Typography>
            <ul style={{ margin: '8px 0' }}>
              {hasFullScan && (
                <li>Consider adding an index to avoid full table scan</li>
              )}
              {unusedIndexes > 0 && (
                <li>Review possible indexes that weren't used</li>
              )}
              {queryResult.executionTime > 500 && (
                <li>Query is slow, consider optimization</li>
              )}
              {totalRows > 10000 && (
                <li>Large number of rows examined, consider filtering</li>
              )}
              {!hasFullScan && queryResult.executionTime < 100 && (
                <li>Query is well optimized!</li>
              )}
            </ul>
          </Alert>
        </Grid>
      </Grid>
    );
  };

  const handleExport = (format: string) => {
    switch (format) {
      case 'csv':
        const csv = [
          queryResult.columns.join(','),
          ...queryResult.rows.map(row => row.join(','))
        ].join('\n');
        const blob = new Blob([csv], { type: 'text/csv' });
        saveAs(blob, 'query-results.csv');
        break;

      case 'excel':
        const ws = XLSX.utils.aoa_to_sheet([queryResult.columns, ...queryResult.rows]);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Results');
        XLSX.writeFile(wb, 'query-results.xlsx');
        break;

      case 'json':
        const jsonData = queryResult.rows.map(row => {
          const obj: any = {};
          queryResult.columns.forEach((col, idx) => {
            obj[col] = row[idx];
          });
          return obj;
        });
        const jsonBlob = new Blob([JSON.stringify(jsonData, null, 2)], { type: 'application/json' });
        saveAs(jsonBlob, 'query-results.json');
        break;

      case 'pdf':
        // Implementation for PDF export would go here
        break;
    }

    setExportAnchor(null);
  };

  return (
    <Paper sx={{ p: 3 }}>
      {/* Header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5">Query Results Visualization</Typography>
        <Box display="flex" gap={1}>
          <FormControlLabel
            control={
              <Switch
                checked={darkMode}
                onChange={(e) => setDarkMode(e.target.checked)}
              />
            }
            label="Dark Mode"
          />
          <IconButton onClick={(e) => setSettingsAnchor(e.currentTarget)}>
            <Settings />
          </IconButton>
          <IconButton onClick={(e) => setExportAnchor(e.currentTarget)}>
            <Download />
          </IconButton>
        </Box>
      </Box>

      {/* Recommendations */}
      <Box mb={2}>
        <Typography variant="subtitle2" gutterBottom>
          Recommended Visualizations
        </Typography>
        <Box display="flex" gap={1} flexWrap="wrap">
          {recommendations.slice(0, 5).map((rec, idx) => (
            <Chip
              key={idx}
              label={`${rec.type} (${Math.round(rec.confidence * 100)}%)`}
              onClick={() => setVisualizationConfig({ ...visualizationConfig, ...rec.config })}
              variant={visualizationConfig.type === rec.type ? 'filled' : 'outlined'}
              size="small"
            />
          ))}
        </Box>
      </Box>

      {/* Tabs */}
      <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)}>
        <Tab icon={<BarChart />} label="Visualization" />
        <Tab icon={<TableChart />} label="Table View" />
        <Tab icon={<Timeline />} label="Query Plan" />
        <Tab icon={<Speed />} label="Cost Analysis" />
      </Tabs>

      {/* Tab Content */}
      <Box mt={3}>
        {activeTab === 0 && (
          <Box>
            {/* Visualization Type Selector */}
            <ButtonGroup variant="outlined" size="small" sx={{ mb: 2 }}>
              <Button
                variant={visualizationConfig.type === 'bar' ? 'contained' : 'outlined'}
                onClick={() => setVisualizationConfig({ ...visualizationConfig, type: 'bar' })}
                startIcon={<BarChart />}
              >
                Bar
              </Button>
              <Button
                variant={visualizationConfig.type === 'line' ? 'contained' : 'outlined'}
                onClick={() => setVisualizationConfig({ ...visualizationConfig, type: 'line' })}
                startIcon={<ShowChart />}
              >
                Line
              </Button>
              <Button
                variant={visualizationConfig.type === 'pie' ? 'contained' : 'outlined'}
                onClick={() => setVisualizationConfig({ ...visualizationConfig, type: 'pie' })}
                startIcon={<PieChart />}
              >
                Pie
              </Button>
              <Button
                variant={visualizationConfig.type === 'scatter' ? 'contained' : 'outlined'}
                onClick={() => setVisualizationConfig({ ...visualizationConfig, type: 'scatter' })}
                startIcon={<ScatterPlot />}
              >
                Scatter
              </Button>
            </ButtonGroup>

            {/* Axis Configuration */}
            <Grid container spacing={2} sx={{ mb: 3 }}>
              <Grid item xs={12} md={4}>
                <FormControl fullWidth size="small">
                  <InputLabel>X-Axis</InputLabel>
                  <Select
                    value={visualizationConfig.xAxis}
                    onChange={(e) => setVisualizationConfig({
                      ...visualizationConfig,
                      xAxis: e.target.value
                    })}
                    label="X-Axis"
                  >
                    {queryResult.columns.map(col => (
                      <MenuItem key={col} value={col}>
                        {col} ({dataTypes[col]})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={4}>
                <FormControl fullWidth size="small">
                  <InputLabel>Y-Axis</InputLabel>
                  <Select
                    multiple
                    value={visualizationConfig.yAxis}
                    onChange={(e) => setVisualizationConfig({
                      ...visualizationConfig,
                      yAxis: e.target.value as string[]
                    })}
                    label="Y-Axis"
                  >
                    {queryResult.columns
                      .filter(col => dataTypes[col] === 'number')
                      .map(col => (
                        <MenuItem key={col} value={col}>
                          {col}
                        </MenuItem>
                      ))}
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12} md={4}>
                <FormControl fullWidth size="small">
                  <InputLabel>Aggregation</InputLabel>
                  <Select
                    value={visualizationConfig.aggregation}
                    onChange={(e) => setVisualizationConfig({
                      ...visualizationConfig,
                      aggregation: e.target.value as any
                    })}
                    label="Aggregation"
                  >
                    <MenuItem value="sum">Sum</MenuItem>
                    <MenuItem value="avg">Average</MenuItem>
                    <MenuItem value="count">Count</MenuItem>
                    <MenuItem value="min">Min</MenuItem>
                    <MenuItem value="max">Max</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>

            {/* Chart */}
            {renderChart()}
          </Box>
        )}

        {activeTab === 1 && (
          <Box sx={{ maxHeight: '500px', overflow: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr>
                  {queryResult.columns.map(col => (
                    <th
                      key={col}
                      style={{
                        padding: '8px',
                        borderBottom: '2px solid #ddd',
                        textAlign: 'left',
                        position: 'sticky',
                        top: 0,
                        background: darkMode ? '#1e1e2e' : '#fff',
                      }}
                    >
                      {col}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {queryResult.rows.map((row, idx) => (
                  <tr key={idx}>
                    {row.map((cell, cellIdx) => (
                      <td
                        key={cellIdx}
                        style={{
                          padding: '8px',
                          borderBottom: '1px solid #ddd',
                        }}
                      >
                        {cell?.toString() || 'NULL'}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </Box>
        )}

        {activeTab === 2 && renderQueryPlan()}

        {activeTab === 3 && renderCostAnalysis()}
      </Box>

      {/* Settings Menu */}
      <Menu
        anchorEl={settingsAnchor}
        open={Boolean(settingsAnchor)}
        onClose={() => setSettingsAnchor(null)}
      >
        <MenuItem>
          <FormControl size="small" fullWidth>
            <InputLabel>Top N</InputLabel>
            <Select
              value={visualizationConfig.top || ''}
              onChange={(e) => setVisualizationConfig({
                ...visualizationConfig,
                top: Number(e.target.value)
              })}
            >
              <MenuItem value="">All</MenuItem>
              <MenuItem value={5}>Top 5</MenuItem>
              <MenuItem value={10}>Top 10</MenuItem>
              <MenuItem value={20}>Top 20</MenuItem>
              <MenuItem value={50}>Top 50</MenuItem>
            </Select>
          </FormControl>
        </MenuItem>
        <MenuItem>
          <FormControl size="small" fullWidth>
            <InputLabel>Sort By</InputLabel>
            <Select
              value={visualizationConfig.sortBy || ''}
              onChange={(e) => setVisualizationConfig({
                ...visualizationConfig,
                sortBy: e.target.value as any
              })}
            >
              <MenuItem value="">None</MenuItem>
              <MenuItem value="asc">Ascending</MenuItem>
              <MenuItem value="desc">Descending</MenuItem>
            </Select>
          </FormControl>
        </MenuItem>
      </Menu>

      {/* Export Menu */}
      <Menu
        anchorEl={exportAnchor}
        open={Boolean(exportAnchor)}
        onClose={() => setExportAnchor(null)}
      >
        <MenuItem onClick={() => handleExport('csv')}>Export as CSV</MenuItem>
        <MenuItem onClick={() => handleExport('excel')}>Export as Excel</MenuItem>
        <MenuItem onClick={() => handleExport('json')}>Export as JSON</MenuItem>
        <MenuItem onClick={() => handleExport('pdf')}>Export as PDF</MenuItem>
      </Menu>
    </Paper>
  );
};