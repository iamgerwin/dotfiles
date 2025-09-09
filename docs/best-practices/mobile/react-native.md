# React Native Best Practices

## Official Documentation
- **React Native Documentation**: https://reactnative.dev/docs/getting-started
- **React Navigation**: https://reactnavigation.org/docs/getting-started
- **Expo Documentation**: https://docs.expo.dev
- **React Native Community**: https://github.com/react-native-community

## Project Structure

```
project-root/
├── src/
│   ├── api/
│   │   ├── client.ts
│   │   ├── endpoints.ts
│   │   └── interceptors.ts
│   ├── assets/
│   │   ├── images/
│   │   ├── fonts/
│   │   └── icons/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── Card.tsx
│   │   ├── forms/
│   │   │   └── LoginForm.tsx
│   │   └── layouts/
│   │       ├── Header.tsx
│   │       └── TabBar.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   └── useDebounce.ts
│   ├── navigation/
│   │   ├── AppNavigator.tsx
│   │   ├── AuthNavigator.tsx
│   │   └── TabNavigator.tsx
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── LoginScreen.tsx
│   │   │   └── RegisterScreen.tsx
│   │   ├── home/
│   │   │   └── HomeScreen.tsx
│   │   └── profile/
│   │       └── ProfileScreen.tsx
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── storage.service.ts
│   │   └── notification.service.ts
│   ├── store/
│   │   ├── slices/
│   │   │   ├── authSlice.ts
│   │   │   └── userSlice.ts
│   │   └── index.ts
│   ├── theme/
│   │   ├── colors.ts
│   │   ├── typography.ts
│   │   └── spacing.ts
│   ├── types/
│   │   ├── navigation.ts
│   │   └── models.ts
│   ├── utils/
│   │   ├── constants.ts
│   │   ├── helpers.ts
│   │   └── validators.ts
│   └── App.tsx
├── __tests__/
├── android/
├── ios/
├── .env
├── .env.example
├── app.json
├── babel.config.js
├── metro.config.js
├── package.json
└── tsconfig.json
```

## Core Best Practices

### 1. Component Architecture

```typescript
// Functional Component with TypeScript
import React, { memo, useCallback, useMemo } from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  ActivityIndicator,
  ViewStyle,
  TextStyle,
} from 'react-native';

interface ButtonProps {
  title: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
  variant?: 'primary' | 'secondary' | 'outline';
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export const Button = memo<ButtonProps>(({
  title,
  onPress,
  loading = false,
  disabled = false,
  variant = 'primary',
  style,
  textStyle,
}) => {
  const buttonStyle = useMemo(() => [
    styles.button,
    styles[variant],
    disabled && styles.disabled,
    style,
  ], [variant, disabled, style]);

  const textColor = useMemo(() => [
    styles.text,
    variant === 'outline' && styles.outlineText,
    textStyle,
  ], [variant, textStyle]);

  const handlePress = useCallback(() => {
    if (!loading && !disabled) {
      onPress();
    }
  }, [loading, disabled, onPress]);

  return (
    <TouchableOpacity
      style={buttonStyle}
      onPress={handlePress}
      disabled={loading || disabled}
      activeOpacity={0.7}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'outline' ? '#007AFF' : '#FFFFFF'} />
      ) : (
        <Text style={textColor}>{title}</Text>
      )}
    </TouchableOpacity>
  );
});

Button.displayName = 'Button';

const styles = StyleSheet.create({
  button: {
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  primary: {
    backgroundColor: '#007AFF',
  },
  secondary: {
    backgroundColor: '#5856D6',
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#007AFF',
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  outlineText: {
    color: '#007AFF',
  },
});
```

### 2. Navigation with React Navigation

```typescript
// navigation/types.ts
export type RootStackParamList = {
  Auth: undefined;
  Main: undefined;
  Profile: { userId: string };
  Settings: undefined;
};

export type AuthStackParamList = {
  Login: undefined;
  Register: undefined;
  ForgotPassword: undefined;
};

export type MainTabParamList = {
  Home: undefined;
  Search: undefined;
  Profile: undefined;
};

// navigation/AppNavigator.tsx
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { useSelector } from 'react-redux';
import Icon from 'react-native-vector-icons/Ionicons';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();
const AuthStack = createNativeStackNavigator<AuthStackParamList>();

// Auth Navigator
const AuthNavigator = () => (
  <AuthStack.Navigator
    screenOptions={{
      headerShown: false,
      animation: 'slide_from_right',
    }}
  >
    <AuthStack.Screen name="Login" component={LoginScreen} />
    <AuthStack.Screen name="Register" component={RegisterScreen} />
    <AuthStack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
  </AuthStack.Navigator>
);

// Main Tab Navigator
const MainNavigator = () => (
  <Tab.Navigator
    screenOptions={({ route }) => ({
      tabBarIcon: ({ focused, color, size }) => {
        let iconName: string;

        switch (route.name) {
          case 'Home':
            iconName = focused ? 'home' : 'home-outline';
            break;
          case 'Search':
            iconName = focused ? 'search' : 'search-outline';
            break;
          case 'Profile':
            iconName = focused ? 'person' : 'person-outline';
            break;
          default:
            iconName = 'circle';
        }

        return <Icon name={iconName} size={size} color={color} />;
      },
      tabBarActiveTintColor: '#007AFF',
      tabBarInactiveTintColor: 'gray',
      headerShown: false,
    })}
  >
    <Tab.Screen name="Home" component={HomeScreen} />
    <Tab.Screen name="Search" component={SearchScreen} />
    <Tab.Screen name="Profile" component={ProfileScreen} />
  </Tab.Navigator>
);

// Root Navigator
export const AppNavigator = () => {
  const isAuthenticated = useSelector((state: RootState) => state.auth.isAuthenticated);

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {isAuthenticated ? (
          <>
            <Stack.Screen name="Main" component={MainNavigator} />
            <Stack.Screen 
              name="Settings" 
              component={SettingsScreen}
              options={{
                presentation: 'modal',
                animation: 'slide_from_bottom',
              }}
            />
          </>
        ) : (
          <Stack.Screen name="Auth" component={AuthNavigator} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};
```

### 3. State Management with Redux Toolkit

```typescript
// store/slices/authSlice.ts
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { authAPI } from '../../api/auth';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
  loading: false,
  error: null,
};

export const login = createAsyncThunk(
  'auth/login',
  async (credentials: { email: string; password: string }) => {
    const response = await authAPI.login(credentials);
    await AsyncStorage.setItem('token', response.token);
    return response;
  }
);

export const logout = createAsyncThunk('auth/logout', async () => {
  await AsyncStorage.removeItem('token');
  await authAPI.logout();
});

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.isAuthenticated = true;
        state.user = action.payload.user;
        state.token = action.payload.token;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Login failed';
      })
      // Logout
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
      });
  },
});

export const { setUser, clearError } = authSlice.actions;
export default authSlice.reducer;

// store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import authReducer from './slices/authSlice';
import userReducer from './slices/userSlice';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    user: userReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### 4. Custom Hooks

```typescript
// hooks/useApi.ts
import { useState, useEffect, useCallback } from 'react';
import { AxiosError } from 'axios';

interface UseApiOptions<T> {
  immediate?: boolean;
  onSuccess?: (data: T) => void;
  onError?: (error: Error) => void;
}

export function useApi<T>(
  apiFunc: () => Promise<T>,
  options: UseApiOptions<T> = {}
) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const execute = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const result = await apiFunc();
      setData(result);
      options.onSuccess?.(result);
      return result;
    } catch (err) {
      const errorMessage = err instanceof AxiosError
        ? err.response?.data?.message || err.message
        : 'An unexpected error occurred';
      
      setError(errorMessage);
      options.onError?.(new Error(errorMessage));
      throw err;
    } finally {
      setLoading(false);
    }
  }, [apiFunc]);

  useEffect(() => {
    if (options.immediate) {
      execute();
    }
  }, []);

  return { data, loading, error, execute, setData };
}

// hooks/useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// hooks/useKeyboard.ts
import { useEffect, useState } from 'react';
import { Keyboard, KeyboardEvent, Platform } from 'react-native';

export function useKeyboard() {
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const [isKeyboardVisible, setIsKeyboardVisible] = useState(false);

  useEffect(() => {
    const showEvent = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
    const hideEvent = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';

    const showSubscription = Keyboard.addListener(
      showEvent,
      (e: KeyboardEvent) => {
        setKeyboardHeight(e.endCoordinates.height);
        setIsKeyboardVisible(true);
      }
    );

    const hideSubscription = Keyboard.addListener(
      hideEvent,
      () => {
        setKeyboardHeight(0);
        setIsKeyboardVisible(false);
      }
    );

    return () => {
      showSubscription.remove();
      hideSubscription.remove();
    };
  }, []);

  return { keyboardHeight, isKeyboardVisible };
}
```

### 5. API Client Setup

```typescript
// api/client.ts
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import Config from 'react-native-config';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: Config.API_URL || 'https://api.example.com',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    this.setupInterceptors();
  }

  private setupInterceptors() {
    // Request interceptor
    this.client.interceptors.request.use(
      async (config) => {
        const token = await AsyncStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          // Token expired or invalid
          await AsyncStorage.removeItem('token');
          // Navigate to login screen
          // You might want to dispatch a Redux action here
        }
        return Promise.reject(error);
      }
    );
  }

  get<T>(url: string, config?: AxiosRequestConfig) {
    return this.client.get<T>(url, config).then(response => response.data);
  }

  post<T>(url: string, data?: any, config?: AxiosRequestConfig) {
    return this.client.post<T>(url, data, config).then(response => response.data);
  }

  put<T>(url: string, data?: any, config?: AxiosRequestConfig) {
    return this.client.put<T>(url, data, config).then(response => response.data);
  }

  delete<T>(url: string, config?: AxiosRequestConfig) {
    return this.client.delete<T>(url, config).then(response => response.data);
  }
}

export default new ApiClient();
```

### 6. Form Handling

```typescript
// screens/auth/LoginScreen.tsx
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { useDispatch } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import { Formik } from 'formik';
import * as Yup from 'yup';

const loginSchema = Yup.object().shape({
  email: Yup.string()
    .email('Invalid email address')
    .required('Email is required'),
  password: Yup.string()
    .min(8, 'Password must be at least 8 characters')
    .required('Password is required'),
});

export const LoginScreen = () => {
  const dispatch = useDispatch<AppDispatch>();
  const navigation = useNavigation();
  const [secureTextEntry, setSecureTextEntry] = useState(true);

  const handleLogin = async (values: { email: string; password: string }) => {
    try {
      await dispatch(login(values)).unwrap();
      // Navigation is handled by the navigator based on auth state
    } catch (error) {
      Alert.alert('Login Failed', error.message);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.header}>
          <Text style={styles.title}>Welcome Back</Text>
          <Text style={styles.subtitle}>Sign in to continue</Text>
        </View>

        <Formik
          initialValues={{ email: '', password: '' }}
          validationSchema={loginSchema}
          onSubmit={handleLogin}
        >
          {({
            handleChange,
            handleBlur,
            handleSubmit,
            values,
            errors,
            touched,
            isSubmitting,
          }) => (
            <View style={styles.form}>
              <View style={styles.inputContainer}>
                <TextInput
                  style={[
                    styles.input,
                    touched.email && errors.email && styles.inputError,
                  ]}
                  placeholder="Email"
                  placeholderTextColor="#999"
                  value={values.email}
                  onChangeText={handleChange('email')}
                  onBlur={handleBlur('email')}
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                />
                {touched.email && errors.email && (
                  <Text style={styles.errorText}>{errors.email}</Text>
                )}
              </View>

              <View style={styles.inputContainer}>
                <View style={styles.passwordContainer}>
                  <TextInput
                    style={[
                      styles.input,
                      styles.passwordInput,
                      touched.password && errors.password && styles.inputError,
                    ]}
                    placeholder="Password"
                    placeholderTextColor="#999"
                    value={values.password}
                    onChangeText={handleChange('password')}
                    onBlur={handleBlur('password')}
                    secureTextEntry={secureTextEntry}
                    autoCapitalize="none"
                  />
                  <TouchableOpacity
                    style={styles.eyeIcon}
                    onPress={() => setSecureTextEntry(!secureTextEntry)}
                  >
                    <Icon
                      name={secureTextEntry ? 'eye-off' : 'eye'}
                      size={20}
                      color="#999"
                    />
                  </TouchableOpacity>
                </View>
                {touched.password && errors.password && (
                  <Text style={styles.errorText}>{errors.password}</Text>
                )}
              </View>

              <Button
                title="Sign In"
                onPress={handleSubmit}
                loading={isSubmitting}
                style={styles.button}
              />

              <TouchableOpacity
                onPress={() => navigation.navigate('ForgotPassword')}
                style={styles.forgotPassword}
              >
                <Text style={styles.forgotPasswordText}>Forgot Password?</Text>
              </TouchableOpacity>
            </View>
          )}
        </Formik>

        <View style={styles.footer}>
          <Text style={styles.footerText}>Don't have an account? </Text>
          <TouchableOpacity onPress={() => navigation.navigate('Register')}>
            <Text style={styles.signUpText}>Sign Up</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  scrollContent: {
    flexGrow: 1,
    padding: 20,
  },
  header: {
    marginTop: 60,
    marginBottom: 40,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#000',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  form: {
    flex: 1,
  },
  inputContainer: {
    marginBottom: 20,
  },
  input: {
    height: 50,
    borderWidth: 1,
    borderColor: '#E0E0E0',
    borderRadius: 8,
    paddingHorizontal: 16,
    fontSize: 16,
    color: '#000',
  },
  inputError: {
    borderColor: '#FF3B30',
  },
  passwordContainer: {
    position: 'relative',
  },
  passwordInput: {
    paddingRight: 50,
  },
  eyeIcon: {
    position: 'absolute',
    right: 16,
    top: 15,
  },
  errorText: {
    color: '#FF3B30',
    fontSize: 12,
    marginTop: 4,
  },
  button: {
    marginTop: 20,
  },
  forgotPassword: {
    alignSelf: 'center',
    marginTop: 16,
  },
  forgotPasswordText: {
    color: '#007AFF',
    fontSize: 14,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 40,
  },
  footerText: {
    color: '#666',
    fontSize: 14,
  },
  signUpText: {
    color: '#007AFF',
    fontSize: 14,
    fontWeight: '600',
  },
});
```

### 7. Performance Optimization

```typescript
// Use FlatList for large lists
import { FlatList, RefreshControl } from 'react-native';

const OptimizedList = () => {
  const [data, setData] = useState([]);
  const [refreshing, setRefreshing] = useState(false);

  const renderItem = useCallback(({ item }) => (
    <ListItem item={item} />
  ), []);

  const keyExtractor = useCallback((item) => item.id.toString(), []);

  const getItemLayout = useCallback((data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  }), []);

  return (
    <FlatList
      data={data}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      getItemLayout={getItemLayout}
      initialNumToRender={10}
      maxToRenderPerBatch={5}
      windowSize={10}
      removeClippedSubviews={true}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    />
  );
};

// Image optimization
import FastImage from 'react-native-fast-image';

const OptimizedImage = ({ uri }) => (
  <FastImage
    style={styles.image}
    source={{
      uri,
      priority: FastImage.priority.normal,
      cache: FastImage.cacheControl.immutable,
    }}
    resizeMode={FastImage.resizeMode.cover}
  />
);
```

### 8. Testing

```typescript
// __tests__/components/Button.test.tsx
import React from 'react';
import { render, fireEvent } from '@testing-library/react-native';
import { Button } from '../../src/components/Button';

describe('Button Component', () => {
  it('renders correctly', () => {
    const { getByText } = render(
      <Button title="Test Button" onPress={() => {}} />
    );
    
    expect(getByText('Test Button')).toBeTruthy();
  });

  it('calls onPress when pressed', () => {
    const onPressMock = jest.fn();
    const { getByText } = render(
      <Button title="Test Button" onPress={onPressMock} />
    );
    
    fireEvent.press(getByText('Test Button'));
    expect(onPressMock).toHaveBeenCalledTimes(1);
  });

  it('shows loading indicator when loading', () => {
    const { getByTestId } = render(
      <Button title="Test Button" onPress={() => {}} loading />
    );
    
    expect(getByTestId('loading-indicator')).toBeTruthy();
  });
});
```

### Common Pitfalls to Avoid

1. **Not handling platform differences**
2. **Ignoring performance optimization**
3. **Not properly handling keyboard behavior**
4. **Using inline styles excessively**
5. **Not testing on real devices**
6. **Forgetting to handle network errors**
7. **Not implementing proper navigation flow**
8. **Using setState incorrectly**
9. **Not optimizing images**
10. **Ignoring memory leaks**

### Useful Libraries

- **react-navigation**: Navigation
- **redux-toolkit**: State management
- **react-native-reanimated**: Animations
- **react-native-gesture-handler**: Gestures
- **react-native-vector-icons**: Icons
- **react-native-fast-image**: Image caching
- **react-native-config**: Environment variables
- **react-native-keychain**: Secure storage
- **react-hook-form**: Form handling
- **react-native-testing-library**: Testing
- **flipper**: Debugging
- **reactotron**: Development tools