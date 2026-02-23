import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { Alert, AlertHistory } from '../types';

interface AlertState {
  alerts: Alert[];
  alertHistory: AlertHistory[];
  unreadAlerts: number;
  isLoading: boolean;
  error: string | null;
}

const initialState: AlertState = {
  alerts: [],
  alertHistory: [],
  unreadAlerts: 0,
  isLoading: false,
  error: null,
};

export const fetchAlerts = createAsyncThunk(
  'alert/fetchAlerts',
  async () => {
    const response = await apiService.get<Alert[]>('/alerts');
    return response;
  }
);

export const fetchAlertHistory = createAsyncThunk(
  'alert/fetchHistory',
  async (limit: number = 50) => {
    const response = await apiService.get<AlertHistory[]>(
      `/alerts/history?limit=${limit}`
    );
    return response;
  }
);

export const createAlert = createAsyncThunk(
  'alert/create',
  async (alert: Omit<Alert, 'id' | 'createdAt' | 'createdBy'>) => {
    const response = await apiService.post<Alert>('/alerts', alert);
    return response;
  }
);

export const updateAlert = createAsyncThunk(
  'alert/update',
  async ({ id, ...data }: Partial<Alert> & { id: string }) => {
    const response = await apiService.put<Alert>(`/alerts/${id}`, data);
    return response;
  }
);

export const deleteAlert = createAsyncThunk(
  'alert/delete',
  async (id: string) => {
    await apiService.delete(`/alerts/${id}`);
    return id;
  }
);

const alertSlice = createSlice({
  name: 'alert',
  initialState,
  reducers: {
    addAlert: (state, action: PayloadAction<AlertHistory>) => {
      state.alertHistory.unshift(action.payload);
      state.unreadAlerts++;
    },
    markAlertsRead: (state) => {
      state.unreadAlerts = 0;
    },
    clearAlertHistory: (state) => {
      state.alertHistory = [];
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch alerts
      .addCase(fetchAlerts.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchAlerts.fulfilled, (state, action) => {
        state.isLoading = false;
        state.alerts = action.payload;
      })
      .addCase(fetchAlerts.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch alerts';
      })
      // Fetch history
      .addCase(fetchAlertHistory.fulfilled, (state, action) => {
        state.alertHistory = action.payload;
      })
      // Create alert
      .addCase(createAlert.fulfilled, (state, action) => {
        state.alerts.push(action.payload);
      })
      // Update alert
      .addCase(updateAlert.fulfilled, (state, action) => {
        const index = state.alerts.findIndex(a => a.id === action.payload.id);
        if (index !== -1) {
          state.alerts[index] = action.payload;
        }
      })
      // Delete alert
      .addCase(deleteAlert.fulfilled, (state, action) => {
        state.alerts = state.alerts.filter(a => a.id !== action.payload);
      });
  },
});

export const { addAlert, markAlertsRead, clearAlertHistory } = alertSlice.actions;
export default alertSlice.reducer;