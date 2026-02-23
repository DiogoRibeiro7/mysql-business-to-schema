import { configureStore } from '@reduxjs/toolkit';
import authReducer from './authSlice';
import schemaReducer from './schemaSlice';
import migrationReducer from './migrationSlice';
import monitoringReducer from './monitoringSlice';
import userReducer from './userSlice';
import alertReducer from './alertSlice';
import backupReducer from './backupSlice';
import queryReducer from './querySlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    schema: schemaReducer,
    migration: migrationReducer,
    monitoring: monitoringReducer,
    user: userReducer,
    alert: alertReducer,
    backup: backupReducer,
    query: queryReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['monitoring/updateMetrics'],
        ignoredActionPaths: ['payload.timestamp'],
        ignoredPaths: ['monitoring.metrics'],
      },
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;