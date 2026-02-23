import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Backup, BackupType } from '../types';

interface BackupState {
  backups: Backup[];
  currentBackup: Backup | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: BackupState = {
  backups: [],
  currentBackup: null,
  isLoading: false,
  error: null,
};

export const fetchBackups = createAsyncThunk(
  'backup/fetchAll',
  async () => {
    const response = await apiService.get<Backup[]>('/backups');
    return response;
  }
);

export const createBackup = createAsyncThunk(
  'backup/create',
  async (data: {
    database: string;
    type: BackupType;
    description?: string;
    compression?: boolean;
  }) => {
    const response = await apiService.post<Backup>('/backups/create', data);
    return response;
  }
);

export const restoreBackup = createAsyncThunk(
  'backup/restore',
  async (data: {
    backupId: string;
    targetDatabase: string;
    validateChecksum?: boolean;
  }) => {
    const response = await apiService.post<any>('/backups/restore', data);
    return response;
  }
);

export const deleteBackup = createAsyncThunk(
  'backup/delete',
  async (id: string) => {
    await apiService.delete(`/backups/${id}`);
    return id;
  }
);

const backupSlice = createSlice({
  name: 'backup',
  initialState,
  reducers: {
    setCurrentBackup: (state, action) => {
      state.currentBackup = action.payload;
    },
    updateBackupStatus: (state, action) => {
      const { id, status } = action.payload;
      const backup = state.backups.find(b => b.id === id);
      if (backup) {
        backup.status = status;
      }
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchBackups.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchBackups.fulfilled, (state, action) => {
        state.isLoading = false;
        state.backups = action.payload;
      })
      .addCase(fetchBackups.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch backups';
      })
      .addCase(createBackup.fulfilled, (state, action) => {
        state.backups.unshift(action.payload);
      })
      .addCase(deleteBackup.fulfilled, (state, action) => {
        state.backups = state.backups.filter(b => b.id !== action.payload);
      });
  },
});

export const { setCurrentBackup, updateBackupStatus } = backupSlice.actions;
export default backupSlice.reducer;