import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardContent,
  Chip,
  Alert
} from '@mui/material';
import {
  Speed as SpeedIcon,
  Storage as StorageIcon,
  TrendingUp as TrendingUpIcon,
  Assessment as AssessmentIcon
} from '@mui/icons-material';
import IndexAdvisor from '../components/IndexAdvisor';

const IndexOptimization: React.FC = () => {
  const [selectedDatabase, setSelectedDatabase] = useState('example_01_clinic');

  // Available databases
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
    'example_10_fintech',
    'example_11_social_media',
    'example_12_real_estate',
    'example_13_event_ticketing',
    'example_14_logistics',
    'example_15_education'
  ];

  return (
    <Box>
      {/* Page Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Index Optimization Center
        </Typography>
        <Typography variant="body1" color="textSecondary">
          Analyze query patterns and optimize database performance with intelligent index recommendations
        </Typography>
      </Box>

      {/* Quick Stats */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <SpeedIcon color="primary" fontSize="large" />
                <Box>
                  <Typography variant="h5">
                    Performance
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Query optimization
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <StorageIcon color="warning" fontSize="large" />
                <Box>
                  <Typography variant="h5">
                    Storage
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Index management
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <TrendingUpIcon color="success" fontSize="large" />
                <Box>
                  <Typography variant="h5">
                    Impact
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Performance gains
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <AssessmentIcon color="info" fontSize="large" />
                <Box>
                  <Typography variant="h5">
                    Analysis
                  </Typography>
                  <Typography variant="body2" color="textSecondary">
                    Query patterns
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Database Selection */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
          <FormControl sx={{ minWidth: 300 }}>
            <InputLabel>Select Database</InputLabel>
            <Select
              value={selectedDatabase}
              onChange={(e) => setSelectedDatabase(e.target.value)}
              label="Select Database"
            >
              {databases.map((db) => (
                <MenuItem key={db} value={db}>
                  {db.replace(/_/g, ' ').replace(/example \d+ /, '')}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Box sx={{ display: 'flex', gap: 1 }}>
            <Chip
              label="AI-Powered"
              color="primary"
              size="small"
            />
            <Chip
              label="Real-time Analysis"
              color="success"
              size="small"
            />
            <Chip
              label="Impact Preview"
              color="info"
              size="small"
            />
          </Box>
        </Box>
      </Paper>

      {/* Index Advisor Component */}
      <IndexAdvisor
        database={selectedDatabase}
        onIndexCreated={() => {
          console.log('Index created successfully');
        }}
      />

      {/* Best Practices Alert */}
      <Alert severity="info" sx={{ mt: 3 }}>
        <Typography variant="subtitle2" gutterBottom>
          Index Optimization Best Practices:
        </Typography>
        <ul style={{ marginBottom: 0, paddingLeft: 20 }}>
          <li>Review and implement critical suggestions first</li>
          <li>Monitor write performance after creating new indexes</li>
          <li>Consider removing unused indexes to reduce overhead</li>
          <li>Test index changes in development before production</li>
          <li>Schedule index creation during low-traffic periods</li>
        </ul>
      </Alert>
    </Box>
  );
};

export default IndexOptimization;