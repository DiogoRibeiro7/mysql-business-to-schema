import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Migration, MigrationStatus } from '../types';

interface MigrationState {
  migrations: Migration[];
  currentMigration: Migration | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: MigrationState = {
  migrations: [],
  currentMigration: null,
  isLoading: false,
  error: null,
};

export const fetchMigrations = createAsyncThunk(
  'migration/fetchAll',
  async () => {
    const response = await apiService.get<Migration[]>('/migrations');
    return response;
  }
);

export const createMigration = createAsyncThunk(
  'migration/create',
  async (data: { description: string; upScript: string; downScript?: string }) => {
    const response = await apiService.post<Migration>('/migrations/create', data);
    return response;
  }
);

export const applyMigration = createAsyncThunk(
  'migration/apply',
  async (data: { targetVersion?: string; dryRun?: boolean }) => {
    const response = await apiService.post<Migration>('/migrations/apply', data);
    return response;
  }
);

export const rollbackMigration = createAsyncThunk(
  'migration/rollback',
  async (data: { targetVersion?: string; steps?: number }) => {
    const response = await apiService.post<Migration>('/migrations/rollback', data);
    return response;
  }
);

const migrationSlice = createSlice({
  name: 'migration',
  initialState,
  reducers: {
    setCurrentMigration: (state, action) => {
      state.currentMigration = action.payload;
    },
    updateMigrationStatus: (state, action) => {
      const { id, status } = action.payload;
      const migration = state.migrations.find(m => m.id === id);
      if (migration) {
        migration.status = status;
      }
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchMigrations.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchMigrations.fulfilled, (state, action) => {
        state.isLoading = false;
        state.migrations = action.payload;
      })
      .addCase(fetchMigrations.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch migrations';
      })
      .addCase(createMigration.fulfilled, (state, action) => {
        state.migrations.push(action.payload);
      })
      .addCase(applyMigration.fulfilled, (state, action) => {
        const index = state.migrations.findIndex(m => m.id === action.payload.id);
        if (index !== -1) {
          state.migrations[index] = action.payload;
        }
      });
  },
});

export const { setCurrentMigration, updateMigrationStatus } = migrationSlice.actions;
export default migrationSlice.reducer;