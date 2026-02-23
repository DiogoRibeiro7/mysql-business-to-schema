import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import { apiService } from '../services/api';
import { User, UserRole } from '../types';

interface UserState {
  users: User[];
  selectedUser: User | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: UserState = {
  users: [],
  selectedUser: null,
  isLoading: false,
  error: null,
};

export const fetchUsers = createAsyncThunk(
  'user/fetchAll',
  async () => {
    const response = await apiService.get<User[]>('/users');
    return response;
  }
);

export const createUser = createAsyncThunk(
  'user/create',
  async (data: {
    username: string;
    email: string;
    password: string;
    role: UserRole;
    permissions?: string[];
  }) => {
    const response = await apiService.post<User>('/users', data);
    return response;
  }
);

export const updateUser = createAsyncThunk(
  'user/update',
  async ({ id, ...data }: Partial<User> & { id: string }) => {
    const response = await apiService.put<User>(`/users/${id}`, data);
    return response;
  }
);

export const deleteUser = createAsyncThunk(
  'user/delete',
  async (id: string) => {
    await apiService.delete(`/users/${id}`);
    return id;
  }
);

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    selectUser: (state, action) => {
      state.selectedUser = action.payload;
    },
    clearSelectedUser: (state) => {
      state.selectedUser = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.isLoading = false;
        state.users = action.payload;
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Failed to fetch users';
      })
      .addCase(createUser.fulfilled, (state, action) => {
        state.users.push(action.payload);
      })
      .addCase(updateUser.fulfilled, (state, action) => {
        const index = state.users.findIndex(u => u.id === action.payload.id);
        if (index !== -1) {
          state.users[index] = action.payload;
        }
      })
      .addCase(deleteUser.fulfilled, (state, action) => {
        state.users = state.users.filter(u => u.id !== action.payload);
      });
  },
});

export const { selectUser, clearSelectedUser } = userSlice.actions;
export default userSlice.reducer;