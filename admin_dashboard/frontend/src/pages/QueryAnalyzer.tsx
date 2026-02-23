import React from 'react';
import { Box, Typography, Paper } from '@mui/material';

const QueryAnalyzer: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Query Analyzer
      </Typography>
      <Paper sx={{ p: 3 }}>
        <Typography>Query analyzer interface coming soon...</Typography>
      </Paper>
    </Box>
  );
};

export default QueryAnalyzer;