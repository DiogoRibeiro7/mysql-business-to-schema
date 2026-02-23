import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Metrics, RealtimeMetrics, DatabaseMetrics } from '../types';

interface MonitoringState {
  metrics: Metrics | null;
  realtimeMetrics: RealtimeMetrics | null;
  databaseMetrics: DatabaseMetrics | null;
  isLoading: boolean;
  error: string | null;
  timeframe: string;
}

const initialState: MonitoringState = {
  metrics: null,
  realtimeMetrics: null,
  databaseMetrics: null,
  isLoading: false,
  error: null,
  timeframe: '1h',
};

export const fetchMetrics = createAsyncThunk(
  'monitoring/fetchMetrics',
  async (timeframe: string) => {
    const response = await apiService.get<Metrics>(
      `/monitoring/performance?timeframe=${timeframe}`
    );
    return response;
  }
);

export const fetchDatabaseMetrics = createAsyncThunk(
  'monitoring/fetchDatabaseMetrics',
  async () => {
    const response = await apiService.get<DatabaseMetrics>(
      '/monitoring/overview'
    );
    return response;
  }
);

const monitoringSlice = createSlice({
  name: 'monitoring',
  initialState,
  reducers: {
    updateMetrics: (state, action: PayloadAction<RealtimeMetrics>) => {
      state.realtimeMetrics = action.payload;
      // Append to historical metrics if needed
      if (state.metrics) {
        // Add new data point to metrics arrays
        const newPoint = {
          timestamp: action.payload.timestamp,
          value: action.payload.cpu,
        };
        state.metrics.cpu = [...(state.metrics.cpu || []), newPoint].slice(-100);
      }
    },
    setTimeframe: (state, action: PayloadAction<string>) => {
      state.timeframe = action.payload;
    },
    clearMetrics: (state) => {
      state.metrics = null;
      state.realtimeMetrics = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMetrics.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchMetrics.fulfilled, (state, action) => {
        state.isLoading = false;
        state.metrics = action.payload;
      })
      .addCase(fetchMetrics.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch metrics';
      })
      .addCase(fetchDatabaseMetrics.fulfilled, (state, action) => {
        state.databaseMetrics = action.payload;
      });
  },
});

export const { updateMetrics, setTimeframe, clearMetrics } = monitoringSlice.actions;
export default monitoringSlice.reducer;