import { apiService } from './api';
import { User, LoginCredentials } from '../types';

interface LoginResponse {
  token: string;
  user: User;
  expiresIn: number;
}

class AuthService {
  async login(credentials: LoginCredentials): Promise<LoginResponse> {
    const response = await apiService.post<any>('/auth/login', credentials);
    return {
      token: response.access_token,
      user: response.user,
      expiresIn: response.expires_in,
    };
  }

  async logout(): Promise<void> {
    try {
      await apiService.post('/auth/logout');
    } catch (error) {
      console.error('Logout error:', error);
    }
  }

  async getCurrentUser(): Promise<User> {
    return await apiService.get<User>('/auth/me');
  }

  async updateProfile(data: Partial<User>): Promise<User> {
    return await apiService.put<User>('/auth/profile', data);
  }

  async changePassword(oldPassword: string, newPassword: string): Promise<void> {
    await apiService.post('/auth/change-password', {
      old_password: oldPassword,
      new_password: newPassword,
    });
  }

  async requestPasswordReset(email: string): Promise<void> {
    await apiService.post('/auth/reset-password-request', { email });
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    await apiService.post('/auth/reset-password', {
      token,
      new_password: newPassword,
    });
  }

  async refreshToken(): Promise<string> {
    const response = await apiService.post<{ access_token: string }>(
      '/auth/refresh'
    );
    return response.access_token;
  }

  async validateToken(token: string): Promise<boolean> {
    try {
      await apiService.post('/auth/validate', { token });
      return true;
    } catch {
      return false;
    }
  }

  getStoredToken(): string | null {
    return localStorage.getItem('token');
  }

  setStoredToken(token: string): void {
    localStorage.setItem('token', token);
  }

  clearStoredToken(): void {
    localStorage.removeItem('token');
  }

  isAuthenticated(): boolean {
    return !!this.getStoredToken();
  }
}

export const authService = new AuthService();