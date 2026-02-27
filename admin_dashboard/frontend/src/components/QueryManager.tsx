import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  ListItemSecondaryAction,
  IconButton,
  Chip,
  Grid,
  Card,
  CardContent,
  CardActions,
  Tooltip,
  Tabs,
  Tab,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Divider,
  Alert,
  Collapse,
  Menu,
  Stack,
  Avatar,
  AvatarGroup,
  Badge
} from '@mui/material';
import {
  Save as SaveIcon,
  Folder as FolderIcon,
  FolderOpen as FolderOpenIcon,
  Share as ShareIcon,
  History as HistoryIcon,
  Star as StarIcon,
  StarBorder as StarBorderIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  ContentCopy as CopyIcon,
  Search as SearchIcon,
  Add as AddIcon,
  MoreVert as MoreIcon,
  Code as CodeIcon,
  Public as PublicIcon,
  Lock as LockIcon,
  Group as GroupIcon,
  TrendingUp as TrendingIcon,
  Timer as TimerIcon,
  Speed as SpeedIcon,
  Restore as RestoreIcon,
  FilterList as FilterIcon,
  Sort as SortIcon,
  Label as TagIcon,
  Collections as CollectionIcon
} from '@mui/icons-material';
import { apiService } from '../services/api';

interface SavedQuery {
  id: string;
  name: string;
  description: string;
  sql: string;
  database: string;
  tags: string[];
  collection_id?: string;
  owner: string;
  created_at: string;
  updated_at: string;
  is_public: boolean;
  shared_with: string[];
  execution_count: number;
  avg_execution_time: number;
  last_executed?: string;
  favorite: boolean;
  parameters?: QueryParameter[];
}

interface QueryParameter {
  name: string;
  type: 'string' | 'number' | 'date' | 'boolean';
  default_value?: any;
  description?: string;
}

interface QueryCollection {
  id: string;
  name: string;
  description: string;
  owner: string;
  query_ids: string[];
  query_count?: number;
  is_public: boolean;
  shared_with: string[];
  created_at: string;
  updated_at: string;
  icon: string;
  color: string;
}

interface QueryVersion {
  version_id: string;
  query_id: string;
  sql: string;
  name: string;
  description: string;
  created_at: string;
  created_by: string;
}

interface QueryManagerProps {
  onLoadQuery?: (query: SavedQuery) => void;
  currentQuery?: string;
  currentDatabase?: string;
}

const QueryManager: React.FC<QueryManagerProps> = ({
  onLoadQuery,
  currentQuery,
  currentDatabase
}) => {
  const [queries, setQueries] = useState<SavedQuery[]>([]);
  const [collections, setCollections] = useState<QueryCollection[]>([]);
  const [selectedTab, setSelectedTab] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCollection, setSelectedCollection] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'name' | 'date' | 'usage'>('date');
  const [filterMenuAnchor, setFilterMenuAnchor] = useState<null | HTMLElement>(null);

  // Dialogs
  const [saveDialogOpen, setSaveDialogOpen] = useState(false);
  const [collectionDialogOpen, setCollectionDialogOpen] = useState(false);
  const [shareDialogOpen, setShareDialogOpen] = useState(false);
  const [versionDialogOpen, setVersionDialogOpen] = useState(false);

  // Form states
  const [queryToSave, setQueryToSave] = useState<Partial<SavedQuery>>({
    name: '',
    description: '',
    sql: currentQuery || '',
    database: currentDatabase || '',
    tags: [],
    is_public: false
  });
  const [newCollection, setNewCollection] = useState({
    name: '',
    description: '',
    icon: 'folder',
    color: '#1976d2'
  });
  const [selectedQuery, setSelectedQuery] = useState<SavedQuery | null>(null);
  const [queryVersions, setQueryVersions] = useState<QueryVersion[]>([]);
  const [shareSettings, setShareSettings] = useState({
    is_public: false,
    shared_with: [] as string[]
  });

  // Load data on mount
  useEffect(() => {
    loadQueries();
    loadCollections();
  }, []);

  const loadQueries = async () => {
    try {
      const response = await apiService.get<{ queries: SavedQuery[] }>('/query/saved');
      setQueries(response.queries);
    } catch (error) {
      console.error('Error loading queries:', error);
    }
  };

  const loadCollections = async () => {
    try {
      const response = await apiService.get<{ collections: QueryCollection[] }>('/query/collections');
      setCollections(response.collections);
    } catch (error) {
      console.error('Error loading collections:', error);
    }
  };

  const handleSaveQuery = async () => {
    try {
      await apiService.post('/query/save', queryToSave);
      setSaveDialogOpen(false);
      loadQueries();
      setQueryToSave({
        name: '',
        description: '',
        sql: '',
        database: '',
        tags: [],
        is_public: false
      });
    } catch (error) {
      console.error('Error saving query:', error);
    }
  };

  const handleDeleteQuery = async (queryId: string) => {
    if (window.confirm('Are you sure you want to delete this query?')) {
      try {
        await apiService.delete(`/query/saved/${queryId}`);
        loadQueries();
      } catch (error) {
        console.error('Error deleting query:', error);
      }
    }
  };

  const handleDuplicateQuery = async (queryId: string) => {
    try {
      await apiService.post(`/query/duplicate/${queryId}`);
      loadQueries();
    } catch (error) {
      console.error('Error duplicating query:', error);
    }
  };

  const handleToggleFavorite = async (queryId: string) => {
    try {
      await apiService.post(`/query/favorites/${queryId}`);
      loadQueries();
    } catch (error) {
      console.error('Error toggling favorite:', error);
    }
  };

  const handleShareQuery = async () => {
    if (!selectedQuery) return;

    try {
      await apiService.post(`/query/share/${selectedQuery.id}`, shareSettings);
      setShareDialogOpen(false);
      loadQueries();
    } catch (error) {
      console.error('Error sharing query:', error);
    }
  };

  const handleCreateCollection = async () => {
    try {
      await apiService.post('/query/collections', newCollection);
      setCollectionDialogOpen(false);
      loadCollections();
      setNewCollection({
        name: '',
        description: '',
        icon: 'folder',
        color: '#1976d2'
      });
    } catch (error) {
      console.error('Error creating collection:', error);
    }
  };

  const loadVersionHistory = async (queryId: string) => {
    try {
      const response = await apiService.get<{ versions: QueryVersion[] }>(`/query/versions/${queryId}`);
      setQueryVersions(response.versions);
    } catch (error) {
      console.error('Error loading version history:', error);
    }
  };

  const handleRestoreVersion = async (queryId: string, versionId: string) => {
    try {
      await apiService.post(`/query/versions/${queryId}/restore/${versionId}`);
      setVersionDialogOpen(false);
      loadQueries();
    } catch (error) {
      console.error('Error restoring version:', error);
    }
  };

  const handleSearch = async () => {
    if (!searchTerm) {
      loadQueries();
      return;
    }

    try {
      const response = await apiService.get<{ results: SavedQuery[] }>(`/query/search?q=${searchTerm}`);
      setQueries(response.results);
    } catch (error) {
      console.error('Error searching queries:', error);
    }
  };

  // Filter queries based on selection
  const filteredQueries = queries.filter(query => {
    if (selectedCollection === 'favorites') {
      return query.favorite;
    }
    if (selectedCollection === 'shared') {
      return query.is_public || query.shared_with.length > 0;
    }
    if (selectedCollection === 'recent') {
      return query.last_executed;
    }
    if (selectedCollection !== 'all') {
      return query.collection_id === selectedCollection;
    }
    return true;
  });

  // Sort queries
  const sortedQueries = [...filteredQueries].sort((a, b) => {
    switch (sortBy) {
      case 'name':
        return a.name.localeCompare(b.name);
      case 'date':
        return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime();
      case 'usage':
        return b.execution_count - a.execution_count;
      default:
        return 0;
    }
  });

  const renderQueryCard = (query: SavedQuery) => (
    <Card key={query.id} sx={{ mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="h6">
              {query.name}
            </Typography>
            {query.favorite && <StarIcon color="warning" fontSize="small" />}
            {query.is_public && <PublicIcon color="primary" fontSize="small" />}
            {query.shared_with.length > 0 && (
              <Badge badgeContent={query.shared_with.length} color="primary">
                <GroupIcon fontSize="small" />
              </Badge>
            )}
          </Box>
          <IconButton
            size="small"
            onClick={() => handleToggleFavorite(query.id)}
          >
            {query.favorite ? <StarIcon color="warning" /> : <StarBorderIcon />}
          </IconButton>
        </Box>

        <Typography variant="body2" color="textSecondary" sx={{ mb: 1 }}>
          {query.description || 'No description'}
        </Typography>

        <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
          <Chip
            label={query.database}
            size="small"
            variant="outlined"
          />
          {query.tags.map((tag, idx) => (
            <Chip
              key={idx}
              label={tag}
              size="small"
              icon={<TagIcon />}
            />
          ))}
        </Box>

        <Paper variant="outlined" sx={{ p: 1, mb: 2, maxHeight: 100, overflow: 'auto' }}>
          <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace', fontSize: '0.85rem' }}>
            {query.sql}
          </Typography>
        </Paper>

        <Grid container spacing={1} sx={{ mb: 1 }}>
          <Grid item xs={4}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <TrendingIcon fontSize="small" color="action" />
              <Typography variant="caption">
                {query.execution_count} runs
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={4}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <TimerIcon fontSize="small" color="action" />
              <Typography variant="caption">
                {query.avg_execution_time.toFixed(0)}ms avg
              </Typography>
            </Box>
          </Grid>
          <Grid item xs={4}>
            <Typography variant="caption" color="textSecondary">
              Updated {new Date(query.updated_at).toLocaleDateString()}
            </Typography>
          </Grid>
        </Grid>
      </CardContent>

      <CardActions>
        <Button
          size="small"
          startIcon={<CodeIcon />}
          onClick={() => onLoadQuery && onLoadQuery(query)}
        >
          Load
        </Button>
        <Button
          size="small"
          startIcon={<ShareIcon />}
          onClick={() => {
            setSelectedQuery(query);
            setShareSettings({
              is_public: query.is_public,
              shared_with: query.shared_with
            });
            setShareDialogOpen(true);
          }}
        >
          Share
        </Button>
        <Button
          size="small"
          startIcon={<HistoryIcon />}
          onClick={() => {
            setSelectedQuery(query);
            loadVersionHistory(query.id);
            setVersionDialogOpen(true);
          }}
        >
          History
        </Button>
        <Button
          size="small"
          startIcon={<CopyIcon />}
          onClick={() => handleDuplicateQuery(query.id)}
        >
          Duplicate
        </Button>
        <IconButton
          size="small"
          color="error"
          onClick={() => handleDeleteQuery(query.id)}
        >
          <DeleteIcon />
        </IconButton>
      </CardActions>
    </Card>
  );

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h5">
          Query Manager
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            startIcon={<SaveIcon />}
            onClick={() => {
              setQueryToSave({
                name: '',
                description: '',
                sql: currentQuery || '',
                database: currentDatabase || '',
                tags: [],
                is_public: false
              });
              setSaveDialogOpen(true);
            }}
          >
            Save Current Query
          </Button>
          <Button
            variant="outlined"
            startIcon={<AddIcon />}
            onClick={() => setCollectionDialogOpen(true)}
          >
            New Collection
          </Button>
        </Box>
      </Box>

      <Paper sx={{ p: 2 }}>
        {/* Search and Filters */}
        <Box sx={{ mb: 3, display: 'flex', gap: 2 }}>
          <TextField
            fullWidth
            placeholder="Search queries..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              )
            }}
            size="small"
          />
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <Select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
            >
              <MenuItem value="date">Recent</MenuItem>
              <MenuItem value="name">Name</MenuItem>
              <MenuItem value="usage">Most Used</MenuItem>
            </Select>
          </FormControl>
          <IconButton onClick={(e) => setFilterMenuAnchor(e.currentTarget)}>
            <FilterIcon />
          </IconButton>
        </Box>

        {/* Collection Tabs */}
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
          <Tabs
            value={selectedCollection}
            onChange={(e, val) => setSelectedCollection(val)}
            variant="scrollable"
            scrollButtons="auto"
          >
            <Tab label="All Queries" value="all" />
            <Tab
              label="Favorites"
              value="favorites"
              icon={<StarIcon fontSize="small" />}
              iconPosition="start"
            />
            <Tab
              label="Shared"
              value="shared"
              icon={<ShareIcon fontSize="small" />}
              iconPosition="start"
            />
            <Tab
              label="Recent"
              value="recent"
              icon={<HistoryIcon fontSize="small" />}
              iconPosition="start"
            />
            {collections.map(col => (
              <Tab
                key={col.id}
                label={`${col.name} (${col.query_count || 0})`}
                value={col.id}
              />
            ))}
          </Tabs>
        </Box>

        {/* Query List */}
        <Box>
          {sortedQueries.length > 0 ? (
            sortedQueries.map(query => renderQueryCard(query))
          ) : (
            <Alert severity="info">
              No queries found. Save a query to get started!
            </Alert>
          )}
        </Box>
      </Paper>

      {/* Save Query Dialog */}
      <Dialog open={saveDialogOpen} onClose={() => setSaveDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Save Query</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Query Name"
                value={queryToSave.name}
                onChange={(e) => setQueryToSave({ ...queryToSave, name: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                value={queryToSave.description}
                onChange={(e) => setQueryToSave({ ...queryToSave, description: e.target.value })}
                multiline
                rows={2}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="SQL Query"
                value={queryToSave.sql}
                onChange={(e) => setQueryToSave({ ...queryToSave, sql: e.target.value })}
                multiline
                rows={6}
                sx={{ fontFamily: 'monospace' }}
              />
            </Grid>
            <Grid item xs={6}>
              <TextField
                fullWidth
                label="Database"
                value={queryToSave.database}
                onChange={(e) => setQueryToSave({ ...queryToSave, database: e.target.value })}
              />
            </Grid>
            <Grid item xs={6}>
              <FormControl fullWidth>
                <InputLabel>Collection</InputLabel>
                <Select
                  value={queryToSave.collection_id || ''}
                  onChange={(e) => setQueryToSave({ ...queryToSave, collection_id: e.target.value })}
                >
                  <MenuItem value="">None</MenuItem>
                  {collections.map(col => (
                    <MenuItem key={col.id} value={col.id}>
                      {col.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Tags (comma separated)"
                value={queryToSave.tags?.join(', ')}
                onChange={(e) => setQueryToSave({
                  ...queryToSave,
                  tags: e.target.value.split(',').map(t => t.trim()).filter(Boolean)
                })}
                helperText="Add tags to organize your queries"
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={queryToSave.is_public}
                    onChange={(e) => setQueryToSave({ ...queryToSave, is_public: e.target.checked })}
                  />
                }
                label="Make this query public"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSaveDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSaveQuery} variant="contained">Save Query</Button>
        </DialogActions>
      </Dialog>

      {/* Create Collection Dialog */}
      <Dialog open={collectionDialogOpen} onClose={() => setCollectionDialogOpen(false)}>
        <DialogTitle>Create Collection</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Collection Name"
                value={newCollection.name}
                onChange={(e) => setNewCollection({ ...newCollection, name: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                value={newCollection.description}
                onChange={(e) => setNewCollection({ ...newCollection, description: e.target.value })}
                multiline
                rows={2}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCollectionDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreateCollection} variant="contained">Create</Button>
        </DialogActions>
      </Dialog>

      {/* Share Dialog */}
      <Dialog open={shareDialogOpen} onClose={() => setShareDialogOpen(false)}>
        <DialogTitle>Share Query</DialogTitle>
        <DialogContent>
          <FormControlLabel
            control={
              <Switch
                checked={shareSettings.is_public}
                onChange={(e) => setShareSettings({ ...shareSettings, is_public: e.target.checked })}
              />
            }
            label="Make Public"
          />
          <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
            Public queries can be viewed by all users
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShareDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleShareQuery} variant="contained">Update Sharing</Button>
        </DialogActions>
      </Dialog>

      {/* Version History Dialog */}
      <Dialog open={versionDialogOpen} onClose={() => setVersionDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Version History</DialogTitle>
        <DialogContent>
          <List>
            {queryVersions.map((version, idx) => (
              <ListItem key={version.version_id}>
                <ListItemText
                  primary={`Version from ${new Date(version.created_at).toLocaleString()}`}
                  secondary={
                    <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}>
                      {version.sql.substring(0, 200)}...
                    </Typography>
                  }
                />
                <ListItemSecondaryAction>
                  <Button
                    size="small"
                    startIcon={<RestoreIcon />}
                    onClick={() => selectedQuery && handleRestoreVersion(selectedQuery.id, version.version_id)}
                  >
                    Restore
                  </Button>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setVersionDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default QueryManager;