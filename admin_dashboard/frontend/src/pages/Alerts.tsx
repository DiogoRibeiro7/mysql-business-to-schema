import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Alerts: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Alerts Configuration
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>Alert management interface coming soon...</Typography>
      </Paper>
    </Box>
  );
};

export default Alerts;