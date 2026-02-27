import React, { useMemo } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Chip,
  Alert,
  Tab,
  Tabs,
  Paper
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
  Tooltip,
  Legend,
  ChartOptions
} from 'chart.js';
import { Line, Bar, Pie, Doughnut, Scatter } from 'react-chartjs-2';
import { QueryResult } from '../types';

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
);

interface QueryVisualizerProps {
  queryResult: QueryResult;
  showQueryPlan?: boolean;
  showCostAnalysis?: boolean;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

const TabPanel: React.FC<TabPanelProps> = ({ children, value, index, ...other }) => {
  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`query-tabpanel-${index}`}
      aria-labelledby={`query-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
};

const QueryVisualizer: React.FC<QueryVisualizerProps> = ({
  queryResult,
  showQueryPlan = true,
  showCostAnalysis = true
}) => {
  const [tabValue, setTabValue] = React.useState(0);

  // Prepare data for different chart types based on result structure
  const chartData = useMemo(() => {
    if (!queryResult?.data || queryResult.data.length === 0) {
      return null;
    }

    const data = queryResult.data;
    const columns = queryResult.columns || Object.keys(data[0]);

    // Find numeric columns for visualization
    const numericColumns = columns.filter(col => {
      const firstValue = data[0][col];
      return typeof firstValue === 'number' || !isNaN(parseFloat(firstValue));
    });

    // Prepare data for bar chart (first numeric column)
    const barChartData = numericColumns.length > 0 ? {
      labels: data.slice(0, 20).map((_, idx) => `Row ${idx + 1}`),
      datasets: numericColumns.slice(0, 3).map((col, idx) => ({
        label: col,
        data: data.slice(0, 20).map(row => parseFloat(row[col]) || 0),
        backgroundColor: [
          'rgba(255, 99, 132, 0.5)',
          'rgba(54, 162, 235, 0.5)',
          'rgba(255, 206, 86, 0.5)'
        ][idx],
        borderColor: [
          'rgba(255, 99, 132, 1)',
          'rgba(54, 162, 235, 1)',
          'rgba(255, 206, 86, 1)'
        ][idx],
        borderWidth: 1
      }))
    } : null;

    // Prepare data for line chart (trends over time)
    const lineChartData = numericColumns.length > 0 ? {
      labels: data.slice(0, 30).map((_, idx) => `${idx + 1}`),
      datasets: numericColumns.slice(0, 2).map((col, idx) => ({
        label: col,
        data: data.slice(0, 30).map(row => parseFloat(row[col]) || 0),
        borderColor: idx === 0 ? 'rgb(255, 99, 132)' : 'rgb(53, 162, 235)',
        backgroundColor: idx === 0 ? 'rgba(255, 99, 132, 0.5)' : 'rgba(53, 162, 235, 0.5)',
        tension: 0.1
      }))
    } : null;

    // Prepare data for pie chart (distribution)
    const pieChartData = numericColumns.length > 0 ? {
      labels: data.slice(0, 8).map((row, idx) =>
        columns[0] in row ? String(row[columns[0]]) : `Item ${idx + 1}`
      ),
      datasets: [{
        label: 'Distribution',
        data: data.slice(0, 8).map(row =>
          numericColumns[0] ? parseFloat(row[numericColumns[0]]) || 0 : 0
        ),
        backgroundColor: [
          'rgba(255, 99, 132, 0.6)',
          'rgba(54, 162, 235, 0.6)',
          'rgba(255, 206, 86, 0.6)',
          'rgba(75, 192, 192, 0.6)',
          'rgba(153, 102, 255, 0.6)',
          'rgba(255, 159, 64, 0.6)',
          'rgba(199, 199, 199, 0.6)',
          'rgba(83, 102, 255, 0.6)'
        ]
      }]
    } : null;

    return {
      barChartData,
      lineChartData,
      pieChartData,
      hasNumericData: numericColumns.length > 0,
      numericColumns,
      totalRows: data.length,
      columns
    };
  }, [queryResult]);

  const chartOptions: ChartOptions<any> = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Query Result Visualization'
      }
    },
    maintainAspectRatio: false
  };

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  // Query execution plan visualization
  const renderQueryPlan = () => {
    if (!queryResult?.executionPlan) {
      return (
        <Alert severity="info">
          No execution plan available. Run EXPLAIN on your query to see the plan.
        </Alert>
      );
    }

    return (
      <Grid container spacing={2}>
        {queryResult.executionPlan.map((step, index) => (
          <Grid item xs={12} key={index}>
            <Card variant="outlined">
              <CardContent>
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={2}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Step {index + 1}
                    </Typography>
                    <Chip
                      label={step.type || 'SCAN'}
                      size="small"
                      color="primary"
                      sx={{ mt: 1 }}
                    />
                  </Grid>
                  <Grid item xs={12} sm={4}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Table
                    </Typography>
                    <Typography variant="body1">
                      {step.table || 'N/A'}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={3}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Rows Examined
                    </Typography>
                    <Typography variant="body1">
                      {step.rows || '0'}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={3}>
                    <Typography variant="subtitle2" color="textSecondary">
                      Key Used
                    </Typography>
                    <Typography variant="body1">
                      {step.key || 'None'}
                    </Typography>
                  </Grid>
                </Grid>
                {step.extra && (
                  <Box mt={2}>
                    <Typography variant="caption" color="textSecondary">
                      Additional Info: {step.extra}
                    </Typography>
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    );
  };

  // Cost analysis visualization
  const renderCostAnalysis = () => {
    const costData = {
      labels: ['Read Cost', 'Sort Cost', 'Join Cost', 'Filter Cost', 'Total Cost'],
      datasets: [{
        label: 'Query Cost Breakdown',
        data: [
          queryResult?.cost?.read || 10,
          queryResult?.cost?.sort || 5,
          queryResult?.cost?.join || 15,
          queryResult?.cost?.filter || 8,
          queryResult?.cost?.total || 38
        ],
        backgroundColor: [
          'rgba(255, 99, 132, 0.6)',
          'rgba(54, 162, 235, 0.6)',
          'rgba(255, 206, 86, 0.6)',
          'rgba(75, 192, 192, 0.6)',
          'rgba(153, 102, 255, 0.6)'
        ]
      }]
    };

    return (
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Cost Distribution
              </Typography>
              <Box sx={{ height: 300 }}>
                <Doughnut data={costData} options={chartOptions} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Performance Metrics
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="textSecondary">
                    Execution Time
                  </Typography>
                  <Typography variant="h4">
                    {queryResult?.executionTime || '0'}ms
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="textSecondary">
                    Rows Returned
                  </Typography>
                  <Typography variant="h4">
                    {chartData?.totalRows || 0}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="textSecondary">
                    Buffer Pool Hit
                  </Typography>
                  <Typography variant="h4">
                    {queryResult?.bufferHit || '95'}%
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2" color="textSecondary">
                    Index Usage
                  </Typography>
                  <Typography variant="h4">
                    {queryResult?.indexUsage || 'Yes'}
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  };

  if (!queryResult) {
    return (
      <Alert severity="info">
        No query results to visualize. Execute a query to see visualizations.
      </Alert>
    );
  }

  return (
    <Box sx={{ width: '100%' }}>
      <Paper sx={{ mb: 2 }}>
        <Tabs value={tabValue} onChange={handleTabChange} aria-label="query visualization tabs">
          <Tab label="Data Visualization" />
          {showQueryPlan && <Tab label="Execution Plan" />}
          {showCostAnalysis && <Tab label="Cost Analysis" />}
        </Tabs>
      </Paper>

      <TabPanel value={tabValue} index={0}>
        {chartData?.hasNumericData ? (
          <Grid container spacing={3}>
            <Grid item xs={12} lg={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Bar Chart
                  </Typography>
                  <Box sx={{ height: 300 }}>
                    {chartData.barChartData && (
                      <Bar data={chartData.barChartData} options={chartOptions} />
                    )}
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} lg={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Line Chart
                  </Typography>
                  <Box sx={{ height: 300 }}>
                    {chartData.lineChartData && (
                      <Line data={chartData.lineChartData} options={chartOptions} />
                    )}
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} lg={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Distribution
                  </Typography>
                  <Box sx={{ height: 300 }}>
                    {chartData.pieChartData && (
                      <Pie data={chartData.pieChartData} options={chartOptions} />
                    )}
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} lg={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Data Summary
                  </Typography>
                  <Grid container spacing={2}>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2" color="textSecondary">
                        Total Rows
                      </Typography>
                      <Typography variant="h5">
                        {chartData.totalRows}
                      </Typography>
                    </Grid>
                    <Grid item xs={6}>
                      <Typography variant="subtitle2" color="textSecondary">
                        Columns
                      </Typography>
                      <Typography variant="h5">
                        {chartData.columns.length}
                      </Typography>
                    </Grid>
                    <Grid item xs={12}>
                      <Typography variant="subtitle2" color="textSecondary">
                        Numeric Columns
                      </Typography>
                      <Box sx={{ mt: 1 }}>
                        {chartData.numericColumns.map((col, idx) => (
                          <Chip
                            key={idx}
                            label={col}
                            size="small"
                            sx={{ mr: 1, mb: 1 }}
                          />
                        ))}
                      </Box>
                    </Grid>
                  </Grid>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        ) : (
          <Alert severity="warning">
            No numeric data found in query results for visualization.
          </Alert>
        )}
      </TabPanel>

      <TabPanel value={tabValue} index={1}>
        {renderQueryPlan()}
      </TabPanel>

      <TabPanel value={tabValue} index={2}>
        {renderCostAnalysis()}
      </TabPanel>
    </Box>
  );
};

export default QueryVisualizer;