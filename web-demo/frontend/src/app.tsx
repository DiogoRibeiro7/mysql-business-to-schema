/**
 * Interactive Database Demo Frontend
 *
 * React application for exploring MySQL database schemas
 * with interactive query execution and visualization
 */

import React, { useState, useEffect } from 'react';
import {
  Container,
  Grid,
  Typography,
  Box,
  Paper,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Button,
  TextField,
  Alert,
  CircularProgress,
  Chip,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Card,
  CardContent,
  CardActions,
  Snackbar,
  AppBar,
  Toolbar,
  Drawer,
  CssBaseline,
  ThemeProvider,
  createTheme,
} from '@mui/material';
import {
  Storage as DatabaseIcon,
  TableChart as TableIcon,
  PlayArrow as RunIcon,
  ContentCopy as CopyIcon,
  Code as CodeIcon,
  History as HistoryIcon,
  Lightbulb as TipIcon,
  Menu as MenuIcon,
  ChevronLeft as ChevronLeftIcon,
  SchemaOutlined,
} from '@mui/icons-material';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import axios from 'axios';

// Theme configuration
const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#0a0e27',
      paper: '#1e1e2e',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 700,
    },
  },
  components: {
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
      },
    },
  },
});

// API configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001';

// Types
interface Database {
  id: string;
  name: string;
  description: string;
  icon: string;
  features: string[];
}

interface TableSchema {
  name: string;
  comment: string;
  rowCount: number;
  columns: Column[];
}

interface Column {
  COLUMN_NAME: string;
  DATA_TYPE: string;
  IS_NULLABLE: string;
  COLUMN_KEY: string;
  COLUMN_DEFAULT: string | null;
  COLUMN_COMMENT: string;
}

interface SampleQuery {
  name: string;
  query: string;
  description: string;
}

interface QueryResult {
  success: boolean;
  results: any[];
  fields: { name: string; type: string }[];
  rowCount: number;
  limited: boolean;
  error?: string;
  message?: string;
}

// Main App Component
const App: React.FC = () => {
  const [drawerOpen, setDrawerOpen] = useState(true);
  const [databases, setDatabases] = useState<Database[]>([]);
  const [selectedDatabase, setSelectedDatabase] = useState<Database | null>(null);
  const [schema, setSchema] = useState<TableSchema[]>([]);
  const [sampleQueries, setSampleQueries] = useState<SampleQuery[]>([]);
  const [selectedTable, setSelectedTable] = useState<TableSchema | null>(null);
  const [currentTab, setCurrentTab] = useState(0);
  const [query, setQuery] = useState('');
  const [queryResult, setQueryResult] = useState<QueryResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [queryHistory, setQueryHistory] = useState<string[]>([]);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);

  // Fetch available databases
  useEffect(() => {
    fetchDatabases();
  }, []);

  const fetchDatabases = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/databases`);
      setDatabases(response.data);
    } catch (err) {
      setError('Failed to fetch databases');
    }
  };

  const selectDatabase = async (database: Database) => {
    setSelectedDatabase(database);
    setLoading(true);
    setError(null);

    try {
      // Fetch schema
      const schemaResponse = await axios.get(
        `${API_BASE_URL}/api/databases/${database.id}/schema`
      );
      setSchema(schemaResponse.data.tables);

      // Fetch sample queries
      const queriesResponse = await axios.get(
        `${API_BASE_URL}/api/databases/${database.id}/sample-queries`
      );
      setSampleQueries(queriesResponse.data);

      setSuccess(`Connected to ${database.name}`);
    } catch (err) {
      setError('Failed to fetch database schema');
    } finally {
      setLoading(false);
    }
  };

  const executeQuery = async () => {
    if (!selectedDatabase || !query.trim()) return;

    setLoading(true);
    setError(null);
    setQueryResult(null);

    try {
      const response = await axios.post(
        `${API_BASE_URL}/api/databases/${selectedDatabase.id}/query`,
        { query }
      );

      setQueryResult(response.data);

      // Add to history
      setQueryHistory(prev => [query, ...prev.filter(q => q !== query)].slice(0, 10));

      if (response.data.limited) {
        setSuccess('Query executed successfully (results limited to 1000 rows)');
      } else {
        setSuccess('Query executed successfully');
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Query execution failed');
      setQueryResult(null);
    } finally {
      setLoading(false);
    }
  };

  const loadSampleQuery = (sampleQuery: SampleQuery) => {
    setQuery(sampleQuery.query);
    setCurrentTab(1); // Switch to Query tab
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setSuccess('Copied to clipboard!');
  };

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const drawerWidth = 300;

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ display: 'flex' }}>
        {/* App Bar */}
        <AppBar
          position="fixed"
          sx={{
            width: `calc(100% - ${drawerOpen ? drawerWidth : 0}px)`,
            ml: `${drawerOpen ? drawerWidth : 0}px`,
            transition: theme.transitions.create(['margin', 'width'], {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.leavingScreen,
            }),
          }}
        >
          <Toolbar>
            <IconButton
              color="inherit"
              aria-label="open drawer"
              onClick={() => setDrawerOpen(!drawerOpen)}
              edge="start"
              sx={{ mr: 2 }}
            >
              {drawerOpen ? <ChevronLeftIcon /> : <MenuIcon />}
            </IconButton>
            <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
              MySQL Business-to-Schema - Interactive Demo
            </Typography>
            {selectedDatabase && (
              <Chip
                icon={<DatabaseIcon />}
                label={selectedDatabase.name}
                color="primary"
                sx={{ ml: 2 }}
              />
            )}
          </Toolbar>
        </AppBar>

        {/* Drawer */}
        <Drawer
          sx={{
            width: drawerWidth,
            flexShrink: 0,
            '& .MuiDrawer-paper': {
              width: drawerWidth,
              boxSizing: 'border-box',
              backgroundColor: theme.palette.background.paper,
            },
          }}
          variant="persistent"
          anchor="left"
          open={drawerOpen}
        >
          <Toolbar />
          <Box sx={{ overflow: 'auto', p: 2 }}>
            <Typography variant="h6" gutterBottom>
              Available Databases
            </Typography>
            <List>
              {databases.map((db) => (
                <ListItem
                  key={db.id}
                  button
                  selected={selectedDatabase?.id === db.id}
                  onClick={() => selectDatabase(db)}
                  sx={{
                    borderRadius: 1,
                    mb: 1,
                    '&:hover': {
                      backgroundColor: 'action.hover',
                    },
                  }}
                >
                  <ListItemIcon>
                    <Typography variant="h5">{db.icon}</Typography>
                  </ListItemIcon>
                  <ListItemText
                    primary={db.name}
                    secondary={db.description}
                    primaryTypographyProps={{ fontWeight: 'medium' }}
                  />
                </ListItem>
              ))}
            </List>
          </Box>
        </Drawer>

        {/* Main Content */}
        <Box
          component="main"
          sx={{
            flexGrow: 1,
            bgcolor: 'background.default',
            p: 3,
            marginLeft: drawerOpen ? `${drawerWidth}px` : 0,
            transition: theme.transitions.create('margin', {
              easing: theme.transitions.easing.sharp,
              duration: theme.transitions.duration.leavingScreen,
            }),
          }}
        >
          <Toolbar />

          {!selectedDatabase ? (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                height: '60vh',
              }}
            >
              <DatabaseIcon sx={{ fontSize: 100, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h5" color="text.secondary">
                Select a database from the sidebar to begin exploring
              </Typography>
            </Box>
          ) : (
            <Container maxWidth={false}>
              {/* Database Features */}
              <Box sx={{ mb: 3 }}>
                <Grid container spacing={1}>
                  {selectedDatabase.features.map((feature) => (
                    <Grid item key={feature}>
                      <Chip label={feature} size="small" variant="outlined" />
                    </Grid>
                  ))}
                </Grid>
              </Box>

              {/* Tabs */}
              <Paper sx={{ mb: 3 }}>
                <Tabs
                  value={currentTab}
                  onChange={(e, v) => setCurrentTab(v)}
                  indicatorColor="primary"
                  textColor="primary"
                >
                  <Tab icon={<SchemaOutlined />} label="Schema Explorer" />
                  <Tab icon={<CodeIcon />} label="Query Editor" />
                  <Tab icon={<TipIcon />} label="Sample Queries" />
                  <Tab icon={<HistoryIcon />} label="Query History" />
                </Tabs>
              </Paper>

              {/* Tab Panels */}
              {currentTab === 0 && (
                <Grid container spacing={3}>
                  {/* Tables List */}
                  <Grid item xs={12} md={4}>
                    <Paper sx={{ p: 2, height: '70vh', overflow: 'auto' }}>
                      <Typography variant="h6" gutterBottom>
                        Tables ({schema.length})
                      </Typography>
                      <List>
                        {schema.map((table) => (
                          <ListItem
                            key={table.name}
                            button
                            selected={selectedTable?.name === table.name}
                            onClick={() => setSelectedTable(table)}
                          >
                            <ListItemIcon>
                              <TableIcon />
                            </ListItemIcon>
                            <ListItemText
                              primary={table.name}
                              secondary={`${table.rowCount.toLocaleString()} rows`}
                            />
                          </ListItem>
                        ))}
                      </List>
                    </Paper>
                  </Grid>

                  {/* Table Details */}
                  <Grid item xs={12} md={8}>
                    {selectedTable ? (
                      <Paper sx={{ p: 2, height: '70vh', overflow: 'auto' }}>
                        <Typography variant="h6" gutterBottom>
                          {selectedTable.name}
                        </Typography>
                        {selectedTable.comment && (
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            {selectedTable.comment}
                          </Typography>
                        )}
                        <TableContainer>
                          <Table size="small">
                            <TableHead>
                              <TableRow>
                                <TableCell>Column</TableCell>
                                <TableCell>Type</TableCell>
                                <TableCell>Nullable</TableCell>
                                <TableCell>Key</TableCell>
                                <TableCell>Default</TableCell>
                                <TableCell>Comment</TableCell>
                              </TableRow>
                            </TableHead>
                            <TableBody>
                              {selectedTable.columns.map((column) => (
                                <TableRow key={column.COLUMN_NAME}>
                                  <TableCell>
                                    <Typography variant="body2" fontFamily="monospace">
                                      {column.COLUMN_NAME}
                                    </Typography>
                                  </TableCell>
                                  <TableCell>
                                    <Chip
                                      label={column.DATA_TYPE}
                                      size="small"
                                      variant="outlined"
                                    />
                                  </TableCell>
                                  <TableCell>{column.IS_NULLABLE}</TableCell>
                                  <TableCell>
                                    {column.COLUMN_KEY && (
                                      <Chip
                                        label={column.COLUMN_KEY}
                                        size="small"
                                        color={column.COLUMN_KEY === 'PRI' ? 'primary' : 'default'}
                                      />
                                    )}
                                  </TableCell>
                                  <TableCell>
                                    {column.COLUMN_DEFAULT || '-'}
                                  </TableCell>
                                  <TableCell>{column.COLUMN_COMMENT}</TableCell>
                                </TableRow>
                              ))}
                            </TableBody>
                          </Table>
                        </TableContainer>
                      </Paper>
                    ) : (
                      <Paper sx={{ p: 4, height: '70vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Typography color="text.secondary">
                          Select a table to view its structure
                        </Typography>
                      </Paper>
                    )}
                  </Grid>
                </Grid>
              )}

              {currentTab === 1 && (
                <Grid container spacing={3}>
                  {/* Query Editor */}
                  <Grid item xs={12}>
                    <Paper sx={{ p: 2 }}>
                      <Box sx={{ mb: 2 }}>
                        <TextField
                          fullWidth
                          multiline
                          rows={8}
                          variant="outlined"
                          placeholder="Enter your SQL query here... (Read-only queries only)"
                          value={query}
                          onChange={(e) => setQuery(e.target.value)}
                          sx={{
                            '& .MuiInputBase-input': {
                              fontFamily: 'monospace',
                              fontSize: '14px',
                            },
                          }}
                        />
                      </Box>
                      <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                        <Button
                          variant="contained"
                          startIcon={<RunIcon />}
                          onClick={executeQuery}
                          disabled={loading || !query.trim()}
                        >
                          Execute Query
                        </Button>
                        <Button
                          variant="outlined"
                          startIcon={<CopyIcon />}
                          onClick={() => copyToClipboard(query)}
                          disabled={!query.trim()}
                        >
                          Copy
                        </Button>
                      </Box>

                      {/* Query Results */}
                      {loading && (
                        <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
                          <CircularProgress />
                        </Box>
                      )}

                      {queryResult && queryResult.success && (
                        <Box>
                          <Typography variant="h6" gutterBottom>
                            Results ({queryResult.rowCount} rows)
                            {queryResult.limited && ' - Limited to 1000'}
                          </Typography>
                          <TableContainer component={Paper} sx={{ maxHeight: 400 }}>
                            <Table stickyHeader size="small">
                              <TableHead>
                                <TableRow>
                                  {queryResult.fields.map((field) => (
                                    <TableCell key={field.name}>
                                      <Typography variant="subtitle2" fontWeight="bold">
                                        {field.name}
                                      </Typography>
                                    </TableCell>
                                  ))}
                                </TableRow>
                              </TableHead>
                              <TableBody>
                                {queryResult.results
                                  .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                                  .map((row, idx) => (
                                    <TableRow key={idx}>
                                      {queryResult.fields.map((field) => (
                                        <TableCell key={field.name}>
                                          {row[field.name]?.toString() || 'NULL'}
                                        </TableCell>
                                      ))}
                                    </TableRow>
                                  ))}
                              </TableBody>
                            </Table>
                          </TableContainer>
                          <TablePagination
                            rowsPerPageOptions={[10, 25, 50, 100]}
                            component="div"
                            count={queryResult.results.length}
                            rowsPerPage={rowsPerPage}
                            page={page}
                            onPageChange={handleChangePage}
                            onRowsPerPageChange={handleChangeRowsPerPage}
                          />
                        </Box>
                      )}
                    </Paper>
                  </Grid>
                </Grid>
              )}

              {currentTab === 2 && (
                <Grid container spacing={3}>
                  {sampleQueries.map((sq, idx) => (
                    <Grid item xs={12} md={6} key={idx}>
                      <Card>
                        <CardContent>
                          <Typography variant="h6" gutterBottom>
                            {sq.name}
                          </Typography>
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            {sq.description}
                          </Typography>
                          <Box sx={{ mt: 2 }}>
                            <SyntaxHighlighter
                              language="sql"
                              style={vscDarkPlus}
                              customStyle={{
                                borderRadius: '4px',
                                fontSize: '12px',
                              }}
                            >
                              {sq.query}
                            </SyntaxHighlighter>
                          </Box>
                        </CardContent>
                        <CardActions>
                          <Button
                            size="small"
                            startIcon={<RunIcon />}
                            onClick={() => loadSampleQuery(sq)}
                          >
                            Run Query
                          </Button>
                          <Button
                            size="small"
                            startIcon={<CopyIcon />}
                            onClick={() => copyToClipboard(sq.query)}
                          >
                            Copy
                          </Button>
                        </CardActions>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              )}

              {currentTab === 3 && (
                <Paper sx={{ p: 2 }}>
                  <Typography variant="h6" gutterBottom>
                    Query History
                  </Typography>
                  {queryHistory.length === 0 ? (
                    <Typography color="text.secondary">
                      No queries in history yet
                    </Typography>
                  ) : (
                    <List>
                      {queryHistory.map((q, idx) => (
                        <ListItem key={idx}>
                          <ListItemText
                            primary={
                              <Typography variant="body2" fontFamily="monospace">
                                {q}
                              </Typography>
                            }
                            secondary={`Query ${idx + 1}`}
                          />
                          <Button
                            size="small"
                            onClick={() => setQuery(q)}
                          >
                            Load
                          </Button>
                        </ListItem>
                      ))}
                    </List>
                  )}
                </Paper>
              )}
            </Container>
          )}
        </Box>

        {/* Notifications */}
        <Snackbar
          open={!!error}
          autoHideDuration={6000}
          onClose={() => setError(null)}
        >
          <Alert
            onClose={() => setError(null)}
            severity="error"
            sx={{ width: '100%' }}
          >
            {error}
          </Alert>
        </Snackbar>

        <Snackbar
          open={!!success}
          autoHideDuration={3000}
          onClose={() => setSuccess(null)}
        >
          <Alert
            onClose={() => setSuccess(null)}
            severity="success"
            sx={{ width: '100%' }}
          >
            {success}
          </Alert>
        </Snackbar>
      </Box>
    </ThemeProvider>
  );
};

export default App;
