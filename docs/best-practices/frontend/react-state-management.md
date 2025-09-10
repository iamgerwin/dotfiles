# React State Management Best Practices

## Overview
This guide covers various state management solutions for React applications including Redux, Zustand, MobX, and Context API, with best practices and implementation patterns for each.

## Documentation
- [Redux Documentation](https://redux.js.org)
- [Redux Toolkit](https://redux-toolkit.js.org)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [MobX Documentation](https://mobx.js.org)
- [React Context API](https://react.dev/reference/react/useContext)

## Redux & Redux Toolkit

### Overview
Redux is a predictable state container for JavaScript apps, commonly used with React. Redux Toolkit (RTK) is the official, opinionated, batteries-included toolset for efficient Redux development.

### Installation
```bash
npm install @reduxjs/toolkit react-redux
```

### Store Configuration with Redux Toolkit

```typescript
// store/store.ts
import { configureStore } from '@reduxjs/toolkit';
import { setupListeners } from '@reduxjs/toolkit/query';
import authReducer from './features/auth/authSlice';
import usersReducer from './features/users/usersSlice';
import { apiSlice } from './features/api/apiSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    users: usersReducer,
    [apiSlice.reducerPath]: apiSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['auth/setCredentials'],
      },
    }).concat(apiSlice.middleware),
  devTools: process.env.NODE_ENV !== 'production',
});

setupListeners(store.dispatch);

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### Creating Slices with Redux Toolkit

```typescript
// store/features/auth/authSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { authAPI } from '../../../api/auth';

interface User {
  id: string;
  email: string;
  name: string;
  roles: string[];
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  token: localStorage.getItem('token'),
  isLoading: false,
  error: null,
};

// Async thunk for login
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: { email: string; password: string }, { rejectWithValue }) => {
    try {
      const response = await authAPI.login(credentials);
      localStorage.setItem('token', response.token);
      return response;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Login failed');
    }
  }
);

// Async thunk for fetching user profile
export const fetchUserProfile = createAsyncThunk(
  'auth/fetchProfile',
  async (_, { getState, rejectWithValue }) => {
    const state = getState() as { auth: AuthState };
    const token = state.auth.token;
    
    if (!token) {
      return rejectWithValue('No token available');
    }
    
    try {
      const user = await authAPI.getProfile(token);
      return user;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Failed to fetch profile');
    }
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      localStorage.setItem('token', action.payload.token);
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.error = null;
      localStorage.removeItem('token');
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Login cases
      .addCase(login.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload.user;
        state.token = action.payload.token;
      })
      .addCase(login.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      })
      // Fetch profile cases
      .addCase(fetchUserProfile.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(fetchUserProfile.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload;
      })
      .addCase(fetchUserProfile.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { setCredentials, logout, clearError } = authSlice.actions;
export default authSlice.reducer;

// Selectors
export const selectCurrentUser = (state: { auth: AuthState }) => state.auth.user;
export const selectIsAuthenticated = (state: { auth: AuthState }) => !!state.auth.token;
export const selectAuthLoading = (state: { auth: AuthState }) => state.auth.isLoading;
export const selectAuthError = (state: { auth: AuthState }) => state.auth.error;
```

### RTK Query for API Integration

```typescript
// store/features/api/apiSlice.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import type { RootState } from '../../store';

export const apiSlice = createApi({
  reducerPath: 'api',
  baseQuery: fetchBaseQuery({
    baseUrl: process.env.REACT_APP_API_URL || '/api',
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) {
        headers.set('authorization', `Bearer ${token}`);
      }
      return headers;
    },
  }),
  tagTypes: ['User', 'Post', 'Comment'],
  endpoints: (builder) => ({
    // Users endpoints
    getUsers: builder.query<User[], void>({
      query: () => '/users',
      providesTags: ['User'],
    }),
    getUser: builder.query<User, string>({
      query: (id) => `/users/${id}`,
      providesTags: (result, error, id) => [{ type: 'User', id }],
    }),
    updateUser: builder.mutation<User, Partial<User> & { id: string }>({
      query: ({ id, ...patch }) => ({
        url: `/users/${id}`,
        method: 'PATCH',
        body: patch,
      }),
      invalidatesTags: (result, error, { id }) => [{ type: 'User', id }],
    }),
    
    // Posts endpoints with pagination
    getPosts: builder.query<
      { posts: Post[]; total: number },
      { page: number; limit: number; search?: string }
    >({
      query: ({ page, limit, search }) => ({
        url: '/posts',
        params: { page, limit, search },
      }),
      providesTags: (result) =>
        result
          ? [
              ...result.posts.map(({ id }) => ({ type: 'Post' as const, id })),
              { type: 'Post', id: 'LIST' },
            ]
          : [{ type: 'Post', id: 'LIST' }],
    }),
    createPost: builder.mutation<Post, Omit<Post, 'id'>>({
      query: (post) => ({
        url: '/posts',
        method: 'POST',
        body: post,
      }),
      invalidatesTags: [{ type: 'Post', id: 'LIST' }],
    }),
    
    // Optimistic update example
    likePost: builder.mutation<void, string>({
      query: (id) => ({
        url: `/posts/${id}/like`,
        method: 'POST',
      }),
      async onQueryStarted(id, { dispatch, queryFulfilled }) {
        const patchResult = dispatch(
          apiSlice.util.updateQueryData('getPost', id, (draft) => {
            draft.likes += 1;
            draft.isLiked = true;
          })
        );
        try {
          await queryFulfilled;
        } catch {
          patchResult.undo();
        }
      },
    }),
  }),
});

export const {
  useGetUsersQuery,
  useGetUserQuery,
  useUpdateUserMutation,
  useGetPostsQuery,
  useCreatePostMutation,
  useLikePostMutation,
} = apiSlice;
```

### Custom Hooks for Redux

```typescript
// hooks/redux.ts
import { useDispatch, useSelector, TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from '../store/store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;

// Custom auth hooks
export const useAuth = () => {
  const user = useAppSelector(selectCurrentUser);
  const isAuthenticated = useAppSelector(selectIsAuthenticated);
  const isLoading = useAppSelector(selectAuthLoading);
  const error = useAppSelector(selectAuthError);
  
  return { user, isAuthenticated, isLoading, error };
};

// Custom permission hook
export const usePermission = (permission: string) => {
  const user = useAppSelector(selectCurrentUser);
  return user?.roles?.includes(permission) ?? false;
};
```

### Redux Usage in Components

```tsx
// components/LoginForm.tsx
import React, { useState, useEffect } from 'react';
import { useAppDispatch, useAuth } from '../hooks/redux';
import { login, clearError } from '../store/features/auth/authSlice';
import { useNavigate } from 'react-router-dom';

export const LoginForm: React.FC = () => {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { isLoading, error, isAuthenticated } = useAuth();
  
  const [credentials, setCredentials] = useState({
    email: '',
    password: '',
  });
  
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/dashboard');
    }
  }, [isAuthenticated, navigate]);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await dispatch(login(credentials));
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {error && (
        <div className="error">
          {error}
          <button onClick={() => dispatch(clearError())}>✕</button>
        </div>
      )}
      
      <input
        type="email"
        value={credentials.email}
        onChange={(e) => setCredentials({ ...credentials, email: e.target.value })}
        placeholder="Email"
        required
      />
      
      <input
        type="password"
        value={credentials.password}
        onChange={(e) => setCredentials({ ...credentials, password: e.target.value })}
        placeholder="Password"
        required
      />
      
      <button type="submit" disabled={isLoading}>
        {isLoading ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
};
```

## Zustand

### Overview
Zustand is a small, fast, and scalable state management solution with a simple API based on hooks.

### Installation
```bash
npm install zustand
```

### Basic Store

```typescript
// stores/useAppStore.ts
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface Todo {
  id: string;
  text: string;
  completed: boolean;
}

interface AppState {
  // State
  todos: Todo[];
  filter: 'all' | 'active' | 'completed';
  isLoading: boolean;
  
  // Actions
  addTodo: (text: string) => void;
  toggleTodo: (id: string) => void;
  removeTodo: (id: string) => void;
  setFilter: (filter: AppState['filter']) => void;
  clearCompleted: () => void;
  
  // Computed
  get filteredTodos(): Todo[];
  get activeCount(): number;
  get completedCount(): number;
}

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      immer((set, get) => ({
        // Initial state
        todos: [],
        filter: 'all',
        isLoading: false,
        
        // Actions
        addTodo: (text) =>
          set((state) => {
            state.todos.push({
              id: crypto.randomUUID(),
              text,
              completed: false,
            });
          }),
          
        toggleTodo: (id) =>
          set((state) => {
            const todo = state.todos.find((t) => t.id === id);
            if (todo) {
              todo.completed = !todo.completed;
            }
          }),
          
        removeTodo: (id) =>
          set((state) => {
            state.todos = state.todos.filter((t) => t.id !== id);
          }),
          
        setFilter: (filter) =>
          set((state) => {
            state.filter = filter;
          }),
          
        clearCompleted: () =>
          set((state) => {
            state.todos = state.todos.filter((t) => !t.completed);
          }),
          
        // Computed properties
        get filteredTodos() {
          const { todos, filter } = get();
          switch (filter) {
            case 'active':
              return todos.filter((t) => !t.completed);
            case 'completed':
              return todos.filter((t) => t.completed);
            default:
              return todos;
          }
        },
        
        get activeCount() {
          return get().todos.filter((t) => !t.completed).length;
        },
        
        get completedCount() {
          return get().todos.filter((t) => t.completed).length;
        },
      })),
      {
        name: 'app-storage',
        partialize: (state) => ({ todos: state.todos }), // Only persist todos
      }
    )
  )
);
```

### Advanced Zustand Patterns

```typescript
// stores/useAuthStore.ts
import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
import { shallow } from 'zustand/shallow';
import axios from 'axios';

interface User {
  id: string;
  email: string;
  name: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  error: string | null;
  
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  refreshToken: () => Promise<void>;
  updateProfile: (data: Partial<User>) => Promise<void>;
}

export const useAuthStore = create<AuthState>()(
  subscribeWithSelector((set, get) => ({
    user: null,
    token: localStorage.getItem('token'),
    isLoading: false,
    error: null,
    
    login: async (email, password) => {
      set({ isLoading: true, error: null });
      
      try {
        const { data } = await axios.post('/api/auth/login', { email, password });
        
        set({
          user: data.user,
          token: data.token,
          isLoading: false,
        });
        
        localStorage.setItem('token', data.token);
        axios.defaults.headers.common['Authorization'] = `Bearer ${data.token}`;
      } catch (error: any) {
        set({
          error: error.response?.data?.message || 'Login failed',
          isLoading: false,
        });
        throw error;
      }
    },
    
    logout: () => {
      set({ user: null, token: null });
      localStorage.removeItem('token');
      delete axios.defaults.headers.common['Authorization'];
    },
    
    refreshToken: async () => {
      const currentToken = get().token;
      
      if (!currentToken) return;
      
      try {
        const { data } = await axios.post('/api/auth/refresh', { token: currentToken });
        
        set({ token: data.token });
        localStorage.setItem('token', data.token);
        axios.defaults.headers.common['Authorization'] = `Bearer ${data.token}`;
      } catch (error) {
        get().logout();
      }
    },
    
    updateProfile: async (updates) => {
      set({ isLoading: true });
      
      try {
        const { data } = await axios.patch('/api/users/profile', updates);
        
        set((state) => ({
          user: { ...state.user!, ...data },
          isLoading: false,
        }));
      } catch (error: any) {
        set({
          error: error.response?.data?.message || 'Update failed',
          isLoading: false,
        });
        throw error;
      }
    },
  }))
);

// Selectors
export const useUser = () => useAuthStore((state) => state.user);
export const useIsAuthenticated = () => useAuthStore((state) => !!state.token);
export const useAuthActions = () =>
  useAuthStore(
    (state) => ({
      login: state.login,
      logout: state.logout,
      refreshToken: state.refreshToken,
    }),
    shallow
  );

// Subscribe to auth changes
useAuthStore.subscribe(
  (state) => state.token,
  (token) => {
    if (token) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    } else {
      delete axios.defaults.headers.common['Authorization'];
    }
  }
);
```

### Zustand Slices Pattern

```typescript
// stores/slices/createUserSlice.ts
import { StateCreator } from 'zustand';

export interface UserSlice {
  users: User[];
  fetchUsers: () => Promise<void>;
  addUser: (user: User) => void;
  updateUser: (id: string, updates: Partial<User>) => void;
  deleteUser: (id: string) => void;
}

export const createUserSlice: StateCreator<UserSlice> = (set) => ({
  users: [],
  
  fetchUsers: async () => {
    const response = await fetch('/api/users');
    const users = await response.json();
    set({ users });
  },
  
  addUser: (user) =>
    set((state) => ({
      users: [...state.users, user],
    })),
    
  updateUser: (id, updates) =>
    set((state) => ({
      users: state.users.map((user) =>
        user.id === id ? { ...user, ...updates } : user
      ),
    })),
    
  deleteUser: (id) =>
    set((state) => ({
      users: state.users.filter((user) => user.id !== id),
    })),
});

// Combine slices
import { create } from 'zustand';
import { createUserSlice, UserSlice } from './slices/createUserSlice';
import { createPostSlice, PostSlice } from './slices/createPostSlice';

type StoreState = UserSlice & PostSlice;

export const useStore = create<StoreState>()((...a) => ({
  ...createUserSlice(...a),
  ...createPostSlice(...a),
}));
```

## MobX

### Overview
MobX is a battle-tested library that makes state management simple and scalable through reactive programming.

### Installation
```bash
npm install mobx mobx-react-lite
```

### MobX Store

```typescript
// stores/TodoStore.ts
import { makeAutoObservable, runInAction } from 'mobx';
import { makePersistable } from 'mobx-persist-store';

export interface Todo {
  id: string;
  text: string;
  completed: boolean;
  createdAt: Date;
}

class TodoStore {
  todos: Todo[] = [];
  filter: 'all' | 'active' | 'completed' = 'all';
  isLoading = false;
  error: string | null = null;
  
  constructor() {
    makeAutoObservable(this);
    
    // Enable persistence
    makePersistable(this, {
      name: 'TodoStore',
      properties: ['todos', 'filter'],
      storage: window.localStorage,
    });
  }
  
  // Computed values
  get filteredTodos() {
    switch (this.filter) {
      case 'active':
        return this.todos.filter((todo) => !todo.completed);
      case 'completed':
        return this.todos.filter((todo) => todo.completed);
      default:
        return this.todos;
    }
  }
  
  get activeTodoCount() {
    return this.todos.filter((todo) => !todo.completed).length;
  }
  
  get completedTodoCount() {
    return this.todos.filter((todo) => todo.completed).length;
  }
  
  get progress() {
    const total = this.todos.length;
    if (total === 0) return 0;
    return (this.completedTodoCount / total) * 100;
  }
  
  // Actions
  addTodo(text: string) {
    const todo: Todo = {
      id: crypto.randomUUID(),
      text,
      completed: false,
      createdAt: new Date(),
    };
    this.todos.push(todo);
  }
  
  toggleTodo(id: string) {
    const todo = this.todos.find((t) => t.id === id);
    if (todo) {
      todo.completed = !todo.completed;
    }
  }
  
  removeTodo(id: string) {
    this.todos = this.todos.filter((t) => t.id !== id);
  }
  
  setFilter(filter: TodoStore['filter']) {
    this.filter = filter;
  }
  
  clearCompleted() {
    this.todos = this.todos.filter((t) => !t.completed);
  }
  
  // Async actions
  async fetchTodos() {
    this.isLoading = true;
    this.error = null;
    
    try {
      const response = await fetch('/api/todos');
      const todos = await response.json();
      
      runInAction(() => {
        this.todos = todos;
        this.isLoading = false;
      });
    } catch (error) {
      runInAction(() => {
        this.error = 'Failed to fetch todos';
        this.isLoading = false;
      });
    }
  }
  
  async saveTodo(text: string) {
    const tempId = crypto.randomUUID();
    const tempTodo: Todo = {
      id: tempId,
      text,
      completed: false,
      createdAt: new Date(),
    };
    
    // Optimistic update
    this.todos.push(tempTodo);
    
    try {
      const response = await fetch('/api/todos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text }),
      });
      
      const savedTodo = await response.json();
      
      runInAction(() => {
        const index = this.todos.findIndex((t) => t.id === tempId);
        if (index !== -1) {
          this.todos[index] = savedTodo;
        }
      });
    } catch (error) {
      runInAction(() => {
        this.todos = this.todos.filter((t) => t.id !== tempId);
        this.error = 'Failed to save todo';
      });
    }
  }
}

export const todoStore = new TodoStore();
```

### MobX with React

```tsx
// App.tsx
import React from 'react';
import { observer } from 'mobx-react-lite';
import { todoStore } from './stores/TodoStore';

export const TodoList = observer(() => {
  const [newTodo, setNewTodo] = React.useState('');
  
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (newTodo.trim()) {
      todoStore.addTodo(newTodo.trim());
      setNewTodo('');
    }
  };
  
  return (
    <div>
      <h1>Todos ({todoStore.activeTodoCount} active)</h1>
      
      <div className="progress">
        <div
          className="progress-bar"
          style={{ width: `${todoStore.progress}%` }}
        />
      </div>
      
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={newTodo}
          onChange={(e) => setNewTodo(e.target.value)}
          placeholder="What needs to be done?"
        />
      </form>
      
      <div className="filters">
        {(['all', 'active', 'completed'] as const).map((filter) => (
          <button
            key={filter}
            className={todoStore.filter === filter ? 'active' : ''}
            onClick={() => todoStore.setFilter(filter)}
          >
            {filter}
          </button>
        ))}
      </div>
      
      <ul>
        {todoStore.filteredTodos.map((todo) => (
          <li key={todo.id}>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => todoStore.toggleTodo(todo.id)}
            />
            <span className={todo.completed ? 'completed' : ''}>
              {todo.text}
            </span>
            <button onClick={() => todoStore.removeTodo(todo.id)}>
              ✕
            </button>
          </li>
        ))}
      </ul>
      
      {todoStore.completedTodoCount > 0 && (
        <button onClick={() => todoStore.clearCompleted()}>
          Clear completed
        </button>
      )}
    </div>
  );
});
```

### MobX Root Store Pattern

```typescript
// stores/RootStore.ts
import { makeAutoObservable } from 'mobx';
import { AuthStore } from './AuthStore';
import { UserStore } from './UserStore';
import { UIStore } from './UIStore';

export class RootStore {
  authStore: AuthStore;
  userStore: UserStore;
  uiStore: UIStore;
  
  constructor() {
    this.authStore = new AuthStore(this);
    this.userStore = new UserStore(this);
    this.uiStore = new UIStore(this);
    makeAutoObservable(this);
  }
  
  reset() {
    this.authStore.reset();
    this.userStore.reset();
    this.uiStore.reset();
  }
}

export const rootStore = new RootStore();

// React context for MobX stores
import { createContext, useContext } from 'react';

const StoreContext = createContext<RootStore>(rootStore);

export const StoreProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return <StoreContext.Provider value={rootStore}>{children}</StoreContext.Provider>;
};

export const useStores = () => {
  const context = useContext(StoreContext);
  if (!context) {
    throw new Error('useStores must be used within StoreProvider');
  }
  return context;
};

// Usage in components
export const UserProfile = observer(() => {
  const { authStore, userStore } = useStores();
  
  return (
    <div>
      <h1>Welcome, {authStore.user?.name}</h1>
      <ul>
        {userStore.users.map((user) => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  );
});
```

## Context API

### Overview
React Context API provides a way to pass data through the component tree without prop drilling.

### Basic Context

```typescript
// contexts/ThemeContext.tsx
import React, { createContext, useContext, useState, useEffect } from 'react';

type Theme = 'light' | 'dark';

interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
  setTheme: (theme: Theme) => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem('theme');
    return (saved as Theme) || 'light';
  });
  
  useEffect(() => {
    localStorage.setItem('theme', theme);
    document.documentElement.setAttribute('data-theme', theme);
  }, [theme]);
  
  const toggleTheme = () => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  };
  
  return (
    <ThemeContext.Provider value={{ theme, toggleTheme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
};
```

### Advanced Context with Reducer

```typescript
// contexts/AppContext.tsx
import React, { createContext, useContext, useReducer, useCallback, useMemo } from 'react';

interface User {
  id: string;
  name: string;
  email: string;
}

interface Notification {
  id: string;
  type: 'success' | 'error' | 'info' | 'warning';
  message: string;
}

interface AppState {
  user: User | null;
  notifications: Notification[];
  isLoading: boolean;
  sidebarOpen: boolean;
}

type AppAction =
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'ADD_NOTIFICATION'; payload: Notification }
  | { type: 'REMOVE_NOTIFICATION'; payload: string }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'TOGGLE_SIDEBAR' }
  | { type: 'RESET' };

const initialState: AppState = {
  user: null,
  notifications: [],
  isLoading: false,
  sidebarOpen: false,
};

function appReducer(state: AppState, action: AppAction): AppState {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, user: action.payload };
      
    case 'ADD_NOTIFICATION':
      return {
        ...state,
        notifications: [...state.notifications, action.payload],
      };
      
    case 'REMOVE_NOTIFICATION':
      return {
        ...state,
        notifications: state.notifications.filter((n) => n.id !== action.payload),
      };
      
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
      
    case 'TOGGLE_SIDEBAR':
      return { ...state, sidebarOpen: !state.sidebarOpen };
      
    case 'RESET':
      return initialState;
      
    default:
      return state;
  }
}

interface AppContextValue {
  state: AppState;
  actions: {
    setUser: (user: User | null) => void;
    showNotification: (type: Notification['type'], message: string) => void;
    removeNotification: (id: string) => void;
    setLoading: (loading: boolean) => void;
    toggleSidebar: () => void;
    reset: () => void;
  };
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(appReducer, initialState);
  
  const setUser = useCallback((user: User | null) => {
    dispatch({ type: 'SET_USER', payload: user });
  }, []);
  
  const showNotification = useCallback((type: Notification['type'], message: string) => {
    const notification: Notification = {
      id: crypto.randomUUID(),
      type,
      message,
    };
    
    dispatch({ type: 'ADD_NOTIFICATION', payload: notification });
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      dispatch({ type: 'REMOVE_NOTIFICATION', payload: notification.id });
    }, 5000);
  }, []);
  
  const removeNotification = useCallback((id: string) => {
    dispatch({ type: 'REMOVE_NOTIFICATION', payload: id });
  }, []);
  
  const setLoading = useCallback((loading: boolean) => {
    dispatch({ type: 'SET_LOADING', payload: loading });
  }, []);
  
  const toggleSidebar = useCallback(() => {
    dispatch({ type: 'TOGGLE_SIDEBAR' });
  }, []);
  
  const reset = useCallback(() => {
    dispatch({ type: 'RESET' });
  }, []);
  
  const actions = useMemo(
    () => ({
      setUser,
      showNotification,
      removeNotification,
      setLoading,
      toggleSidebar,
      reset,
    }),
    [setUser, showNotification, removeNotification, setLoading, toggleSidebar, reset]
  );
  
  const value = useMemo(() => ({ state, actions }), [state, actions]);
  
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within AppProvider');
  }
  return context;
};

// Specific hooks for common use cases
export const useUser = () => {
  const { state } = useApp();
  return state.user;
};

export const useNotifications = () => {
  const { state, actions } = useApp();
  return {
    notifications: state.notifications,
    showNotification: actions.showNotification,
    removeNotification: actions.removeNotification,
  };
};
```

### Context Composition Pattern

```typescript
// contexts/index.tsx
import React from 'react';
import { AuthProvider } from './AuthContext';
import { ThemeProvider } from './ThemeContext';
import { AppProvider } from './AppContext';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000,
    },
  },
});

export const Providers: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ThemeProvider>
          <AppProvider>{children}</AppProvider>
        </ThemeProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
};

// App.tsx
import { Providers } from './contexts';

function App() {
  return (
    <Providers>
      <Router>
        {/* Your app components */}
      </Router>
    </Providers>
  );
}
```

## Comparison and Best Practices

### When to Use Each Solution

**Redux/RTK:**
- Large applications with complex state
- Need time-travel debugging
- Multiple developers working on the same codebase
- Server state caching with RTK Query
- Predictable state updates are critical

**Zustand:**
- Medium-sized applications
- Want simpler API than Redux
- Need good TypeScript support
- Quick prototyping
- Less boilerplate preferred

**MobX:**
- Complex reactive state requirements
- Prefer OOP style
- Fine-grained reactivity needed
- Working with observable data structures
- Coming from Angular or Vue background

**Context API:**
- Small to medium applications
- Passing data to deeply nested components
- Theme, authentication, or user preferences
- Avoiding external dependencies
- Simple global state requirements

### Performance Best Practices

1. **Use selector patterns** to prevent unnecessary re-renders
2. **Memoize expensive computations** with useMemo
3. **Split stores** by domain to reduce update scope
4. **Normalize state shape** for relational data
5. **Use React.memo** for pure components
6. **Implement code splitting** for large stores
7. **Batch updates** when making multiple state changes
8. **Use development tools** for debugging (Redux DevTools, MobX DevTools)
9. **Avoid storing derived state** - compute it instead
10. **Profile performance** with React DevTools Profiler