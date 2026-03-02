import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  Box,
  Paper,
  Typography,
  Grid,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  TextField,
  InputAdornment,
  Tooltip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import { TreeView, TreeItem } from '@mui/lab';
import {
  ExpandMore,
  ChevronRight,
  Storage,
  TableChart,
  Search,
  Refresh,
  Download,
  Edit,
  Delete,
  Add,
} from '@mui/icons-material';

import { RootState, AppDispatch } from '../store';
import { fetchDatabases, fetchDatabase, selectDatabase } from '../store/schemaSlice';
import { Database, Table as TableType } from '../types';

const SchemaManager: React.FC = () => {
  const dispatch = useDispatch<AppDispatch>();
  const { databases, selectedDatabase, isLoading } = useSelector(
    (state: RootState) => state.schema
  );

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTable, setSelectedTable] = useState<TableType | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);

  useEffect(() => {
    dispatch(fetchDatabases());
  }, [dispatch]);

  const handleDatabaseSelect = async (database: Database) => {
    dispatch(selectDatabase(database));
    await dispatch(fetchDatabase(database.name));
  };

  const handleTableSelect = (table: TableType) => {
    setSelectedTable(table);
  };

  const filteredDatabases = databases.filter(db =>
    db.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <Typography variant="h4">Schema Manager</Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setCreateDialogOpen(true)}
          >
            Create Database
          </Button>
          <IconButton onClick={() => dispatch(fetchDatabases())}>
            <Refresh />
          </IconButton>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Database Tree */}
        <Grid item xs={12} md={3}>
          <Paper sx={{ p: 2, height: '70vh', overflow: 'auto' }}>
            <TextField
              fullWidth
              size="small"
              placeholder="Search databases..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search />
                  </InputAdornment>
                ),
              }}
              sx={{ mb: 2 }}
            />

            <TreeView
              defaultCollapseIcon={<ExpandMore />}
              defaultExpandIcon={<ChevronRight />}
            >
              {filteredDatabases.map((db) => (
                <TreeItem
                  key={db.name}
                  nodeId={db.name}
                  label={
                    <Box sx={{ display: 'flex', alignItems: 'center', py: 1 }}>
                      <Storage sx={{ mr: 1, fontSize: 18 }} />
                      <Typography variant="body2">{db.name}</Typography>
                      <Chip
                        label={`${db.tableCount} tables`}
                        size="small"
                        sx={{ ml: 'auto' }}
                      />
                    </Box>
                  }
                  onClick={() => handleDatabaseSelect(db)}
                >
                  {db.tables?.map((table) => (
                    <TreeItem
                      key={table.name}
                      nodeId={`${db.name}.${table.name}`}
                      label={
                        <Box sx={{ display: 'flex', alignItems: 'center', py: 0.5 }}>
                          <TableChart sx={{ mr: 1, fontSize: 16 }} />
                          <Typography variant="caption">{table.name}</Typography>
                        </Box>
                      }
                      onClick={(e) => {
                        e.stopPropagation();
                        handleTableSelect(table);
                      }}
                    />
                  ))}
                </TreeItem>
              ))}
            </TreeView>
          </Paper>
        </Grid>

        {/* Database/Table Details */}
        <Grid item xs={12} md={9}>
          {selectedTable ? (
            <Paper sx={{ p: 2 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="h6">
                  Table: {selectedTable.name}
                </Typography>
                <Box sx={{ display: 'flex', gap: 1 }}>
                  <Tooltip title="Edit table">
                    <IconButton size="small">
                      <Edit />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Export table">
                    <IconButton size="small">
                      <Download />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete table">
                    <IconButton size="small" color="error">
                      <Delete />
                    </IconButton>
                  </Tooltip>
                </Box>
              </Box>

              <Grid container spacing={2} sx={{ mb: 3 }}>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Engine
                  </Typography>
                  <Typography variant="body1">{selectedTable.engine}</Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Rows
                  </Typography>
                  <Typography variant="body1">
                    {selectedTable.rowCount.toLocaleString()}
                  </Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Size
                  </Typography>
                  <Typography variant="body1">
                    {selectedTable.sizeMb} MB
                  </Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Collation
                  </Typography>
                  <Typography variant="body1">{selectedTable.collation}</Typography>
                </Grid>
              </Grid>

              <Typography variant="h6" gutterBottom>
                Columns
              </Typography>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Name</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Null</TableCell>
                      <TableCell>Default</TableCell>
                      <TableCell>Key</TableCell>
                      <TableCell>Comment</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {selectedTable.columns.map((column) => (
                      <TableRow key={column.name}>
                        <TableCell>{column.name}</TableCell>
                        <TableCell>{column.type}</TableCell>
                        <TableCell>{column.nullable ? 'YES' : 'NO'}</TableCell>
                        <TableCell>{column.defaultValue || '-'}</TableCell>
                        <TableCell>
                          {column.isPrimary && (
                            <Chip label="PRI" size="small" color="primary" />
                          )}
                          {column.isUnique && !column.isPrimary && (
                            <Chip label="UNI" size="small" color="secondary" />
                          )}
                          {column.isIndexed && !column.isUnique && !column.isPrimary && (
                            <Chip label="IDX" size="small" />
                          )}
                        </TableCell>
                        <TableCell>{column.comment || '-'}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>

              {selectedTable.indexes.length > 0 && (
                <>
                  <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
                    Indexes
                  </Typography>
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Name</TableCell>
                          <TableCell>Columns</TableCell>
                          <TableCell>Type</TableCell>
                          <TableCell>Unique</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {selectedTable.indexes.map((index) => (
                          <TableRow key={index.name}>
                            <TableCell>{index.name}</TableCell>
                            <TableCell>{index.columns.join(', ')}</TableCell>
                            <TableCell>{index.type}</TableCell>
                            <TableCell>{index.isUnique ? 'YES' : 'NO'}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </>
              )}
            </Paper>
          ) : selectedDatabase ? (
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" gutterBottom>
                Database: {selectedDatabase.name}
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Tables
                  </Typography>
                  <Typography variant="h4">{selectedDatabase.tableCount}</Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Views
                  </Typography>
                  <Typography variant="h4">{selectedDatabase.views?.length || 0}</Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Procedures
                  </Typography>
                  <Typography variant="h4">{selectedDatabase.procedures?.length || 0}</Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="caption" color="textSecondary">
                    Size
                  </Typography>
                  <Typography variant="h4">{selectedDatabase.sizeMb} MB</Typography>
                </Grid>
              </Grid>
            </Paper>
          ) : (
            <Paper sx={{ p: 4, textAlign: 'center' }}>
              <Storage sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
              <Typography variant="h6" color="textSecondary">
                Select a database or table to view details
              </Typography>
            </Paper>
          )}
        </Grid>
      </Grid>

      {/* Create Database Dialog */}
      <Dialog open={createDialogOpen} onClose={() => setCreateDialogOpen(false)}>
        <DialogTitle>Create New Database</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="Database Name"
            fullWidth
            variant="outlined"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>Cancel</Button>
          <Button variant="contained">Create</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SchemaManager;
