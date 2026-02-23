import { io, Socket } from 'socket.io-client';
import { store } from '../store';
import { updateMetrics } from '../store/monitoringSlice';
import { addAlert } from '../store/alertSlice';

const WS_URL = process.env.REACT_APP_WS_URL || 'ws://localhost:8000';

class WebSocketService {
  private socket: Socket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;

  connect(token: string): void {
    if (this.socket?.connected) {
      return;
    }

    this.socket = io(WS_URL, {
      auth: { token },
      transports: ['websocket'],
      reconnection: true,
      reconnectionAttempts: this.maxReconnectAttempts,
      reconnectionDelay: this.reconnectDelay,
    });

    this.setupEventListeners();
  }

  private setupEventListeners(): void {
    if (!this.socket) return;

    this.socket.on('connect', () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
      this.subscribeToChannels();
    });

    this.socket.on('disconnect', (reason) => {
      console.log('WebSocket disconnected:', reason);
      if (reason === 'io server disconnect') {
        // Server initiated disconnect, try to reconnect
        this.reconnect();
      }
    });

    this.socket.on('error', (error) => {
      console.error('WebSocket error:', error);
    });

    // Real-time metrics
    this.socket.on('metrics:update', (data) => {
      store.dispatch(updateMetrics(data));
    });

    // Alert notifications
    this.socket.on('alert:triggered', (alert) => {
      store.dispatch(addAlert(alert));
      this.showNotification('Alert Triggered', alert.message);
    });

    // Migration updates
    this.socket.on('migration:status', (data) => {
      // Update migration status in store
      console.log('Migration status update:', data);
    });

    // Backup updates
    this.socket.on('backup:status', (data) => {
      // Update backup status in store
      console.log('Backup status update:', data);
    });

    // Query execution updates
    this.socket.on('query:result', (data) => {
      // Handle query results
      console.log('Query result:', data);
    });

    // System notifications
    this.socket.on('notification', (notification) => {
      this.showNotification(notification.title, notification.message);
    });
  }

  private subscribeToChannels(): void {
    if (!this.socket) return;

    // Subscribe to specific channels based on user preferences
    this.socket.emit('subscribe', {
      channels: ['metrics', 'alerts', 'migrations', 'backups'],
    });
  }

  private reconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnection attempts reached');
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    setTimeout(() => {
      console.log(`Reconnecting... (attempt ${this.reconnectAttempts})`);
      const token = localStorage.getItem('token');
      if (token) {
        this.connect(token);
      }
    }, delay);
  }

  private showNotification(title: string, message: string): void {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        body: message,
        icon: '/favicon.ico',
      });
    }
  }

  // Public methods for emitting events
  emit(event: string, data?: any): void {
    if (this.socket?.connected) {
      this.socket.emit(event, data);
    }
  }

  on(event: string, callback: (data: any) => void): void {
    if (this.socket) {
      this.socket.on(event, callback);
    }
  }

  off(event: string, callback?: (data: any) => void): void {
    if (this.socket) {
      this.socket.off(event, callback);
    }
  }

  disconnect(): void {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }

  isConnected(): boolean {
    return this.socket?.connected || false;
  }

  // Specific event emitters
  requestMetrics(timeframe: string): void {
    this.emit('metrics:request', { timeframe });
  }

  executeQuery(query: string, database: string): void {
    this.emit('query:execute', { query, database });
  }

  subscribeMigration(migrationId: string): void {
    this.emit('migration:subscribe', { migrationId });
  }

  unsubscribeMigration(migrationId: string): void {
    this.emit('migration:unsubscribe', { migrationId });
  }

  subscribeBackup(backupId: string): void {
    this.emit('backup:subscribe', { backupId });
  }

  unsubscribeBackup(backupId: string): void {
    this.emit('backup:unsubscribe', { backupId });
  }
}

export const wsService = new WebSocketService();

export const initializeWebSocket = (): (() => void) => {
  const token = localStorage.getItem('token');
  if (token) {
    wsService.connect(token);
  }

  // Request notification permission
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
  }

  // Return cleanup function
  return () => {
    wsService.disconnect();
  };
};

export default wsService;