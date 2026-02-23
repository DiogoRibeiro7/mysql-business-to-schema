import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Query, QueryResult } from '../types';

interface QueryState {
  queries: Query[];
  currentQuery: string;
  queryResult: QueryResult | null;
  queryHistory: Query[];
  isExecuting: boolean;
  isLoading: boolean;
  error: string | null;
}

const initialState: QueryState = {
  queries: [],
  currentQuery: '',
  queryResult: null,
  queryHistory: [],
  isExecuting: false,
  isLoading: false,
  error: null,
};

export const executeQuery = createAsyncThunk(
  'query/execute',
  async (data: { query: string; database: string; limit?: number }) => {
    const response = await apiService.post<QueryResult>('/query/execute', data);
    return response;
  }
);

export const explainQuery = createAsyncThunk(
  'query/explain',
  async (data: { query: string; database: string }) => {
    const response = await apiService.post<QueryResult>('/query/explain', data);
    return response;
  }
);

export const optimizeQuery = createAsyncThunk(
  'query/optimize',
  async (data: { query: string; database: string }) => {
    const response = await apiService.post<any>('/query/optimize', data);
    return response;
  }
);

export const fetchQueryHistory = createAsyncThunk(
  'query/fetchHistory',
  async (limit: number = 100) => {
    const response = await apiService.get<Query[]>(`/query/history?limit=${limit}`);
    return response;
  }
);

const querySlice = createSlice({
  name: 'query',
  initialState,
  reducers: {
    setCurrentQuery: (state, action) => {
      state.currentQuery = action.payload;
    },
    clearQueryResult: (state) => {
      state.queryResult = null;
      state.error = null;
    },
    addToHistory: (state, action) => {
      state.queryHistory.unshift(action.payload);
      if (state.queryHistory.length > 100) {
        state.queryHistory.pop();
      }
    },
  },
  extraReducers: (builder) => {
    builder
      // Execute query
      .addCase(executeQuery.pending, (state) => {
        state.isExecuting = true;
        state.error = null;
        state.queryResult = null;
      })
      .addCase(executeQuery.fulfilled, (state, action) => {
        state.isExecuting = false;
        state.queryResult = action.payload;
      })
      .addCase(executeQuery.rejected, (state, action) => {
        state.isExecuting = false;
        state.error = action.error.message || 'Query execution failed';
      })
      // Explain query
      .addCase(explainQuery.fulfilled, (state, action) => {
        state.queryResult = action.payload;
      })
      // Fetch history
      .addCase(fetchQueryHistory.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(fetchQueryHistory.fulfilled, (state, action) => {
        state.isLoading = false;
        state.queryHistory = action.payload;
      })
      .addCase(fetchQueryHistory.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch query history';
      });
  },
});

export const { setCurrentQuery, clearQueryResult, addToHistory } = querySlice.actions;
export default querySlice.reducer;