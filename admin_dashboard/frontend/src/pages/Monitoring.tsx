import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const Monitoring: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        System Monitoring
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>Real-time monitoring interface coming soon...</Typography>
      </Paper>
    </Box>
  );
};

export default Monitoring;