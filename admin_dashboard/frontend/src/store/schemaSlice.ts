import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Database, Table } from '../types';

interface SchemaState {
  databases: Database[];
  selectedDatabase: Database | null;
  selectedTable: Table | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: SchemaState = {
  databases: [],
  selectedDatabase: null,
  selectedTable: null,
  isLoading: false,
  error: null,
};

export const fetchDatabases = createAsyncThunk(
  'schema/fetchDatabases',
  async () => {
    const response = await apiService.get<Database[]>('/schemas/databases');
    return response;
  }
);

export const fetchDatabase = createAsyncThunk(
  'schema/fetchDatabase',
  async (name: string) => {
    const response = await apiService.get<Database>(`/schemas/databases/${name}`);
    return response;
  }
);

export const fetchTable = createAsyncThunk(
  'schema/fetchTable',
  async ({ database, table }: { database: string; table: string }) => {
    const response = await apiService.get<Table>(
      `/schemas/databases/${database}/tables/${table}`
    );
    return response;
  }
);

const schemaSlice = createSlice({
  name: 'schema',
  initialState,
  reducers: {
    selectDatabase: (state, action) => {
      state.selectedDatabase = action.payload;
    },
    selectTable: (state, action) => {
      state.selectedTable = action.payload;
    },
    clearSelection: (state) => {
      state.selectedDatabase = null;
      state.selectedTable = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchDatabases.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchDatabases.fulfilled, (state, action) => {
        state.isLoading = false;
        state.databases = action.payload;
      })
      .addCase(fetchDatabases.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch databases';
      })
      .addCase(fetchDatabase.fulfilled, (state, action) => {
        state.selectedDatabase = action.payload;
      })
      .addCase(fetchTable.fulfilled, (state, action) => {
        state.selectedTable = action.payload;
      });
  },
});

export const { selectDatabase, selectTable, clearSelection } = schemaSlice.actions;
export default schemaSlice.reducer;