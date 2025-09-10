# TypeScript Best Practices

## Official Documentation
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [TypeScript Playground](https://www.typescriptlang.org/play)
- [TypeScript GitHub](https://github.com/microsoft/TypeScript)
- [TypeScript Community](https://github.com/typescript-community)

## Project Structure

```
src/
├── types/           # Type definitions
│   ├── api.ts      # API response types
│   ├── user.ts     # User-related types
│   └── index.ts    # Export all types
├── utils/          # Utility functions
├── services/       # API services
├── hooks/          # Custom hooks (if React)
├── components/     # Components (if frontend)
├── pages/          # Pages/routes
├── lib/            # Third-party configurations
├── constants/      # Application constants
├── assets/         # Static assets
└── tests/          # Test files
tsconfig.json       # TypeScript configuration
package.json        # Dependencies
.eslintrc.js        # ESLint configuration
.prettierrc         # Prettier configuration
```

## TypeScript Configuration

### tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/types/*": ["src/types/*"],
      "@/utils/*": ["src/utils/*"],
      "@/services/*": ["src/services/*"]
    },
    // Strict type checking
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitThis": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  },
  "include": [
    "src/**/*",
    "**/*.ts",
    "**/*.tsx"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts",
    "**/*.spec.ts"
  ]
}
```

### Strict Configuration (tsconfig.strict.json)
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "useUnknownInCatchVariables": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true
  }
}
```

## Type Definitions Best Practices

### 1. Interface vs Type Aliases
```typescript
// Use interfaces for object shapes that might be extended
interface User {
  id: string;
  name: string;
  email: string;
}

interface AdminUser extends User {
  permissions: string[];
}

// Use type aliases for unions, primitives, and computed types
type Status = 'loading' | 'success' | 'error';
type UserKeys = keyof User;
type PartialUser = Partial<User>;
```

### 2. Generic Types
```typescript
// Generic interface
interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

// Generic function
function processData<T>(data: T[]): T[] {
  return data.filter(item => item !== null);
}

// Constrained generics
interface Identifiable {
  id: string;
}

function findById<T extends Identifiable>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}

// Conditional types
type NonNullable<T> = T extends null | undefined ? never : T;
```

### 3. Utility Types
```typescript
// Built-in utility types
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Pick specific properties
type PublicUser = Pick<User, 'id' | 'name' | 'email'>;

// Omit specific properties
type UserInput = Omit<User, 'id' | 'createdAt'>;

// Make all properties optional
type PartialUser = Partial<User>;

// Make all properties required
type RequiredUser = Required<Partial<User>>;

// Create record type
type UserRole = Record<string, 'admin' | 'user' | 'guest'>;
```

### 4. Advanced Types
```typescript
// Template literal types
type EventName<T extends string> = `on${Capitalize<T>}`;
type ClickEvent = EventName<'click'>; // 'onClick'

// Mapped types
type ReadonlyUser = {
  readonly [K in keyof User]: User[K];
};

// Conditional types with infer
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

// Discriminated unions
type LoadingState = {
  status: 'loading';
};

type SuccessState = {
  status: 'success';
  data: any;
};

type ErrorState = {
  status: 'error';
  error: string;
};

type AppState = LoadingState | SuccessState | ErrorState;
```

## Function and Class Best Practices

### 1. Function Overloads
```typescript
// Function overloads
function createElement(tag: 'div'): HTMLDivElement;
function createElement(tag: 'span'): HTMLSpanElement;
function createElement(tag: 'input'): HTMLInputElement;
function createElement(tag: string): HTMLElement {
  return document.createElement(tag);
}

// Generic function with constraints
function deepClone<T extends object>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}
```

### 2. Class Design
```typescript
// Abstract base class
abstract class Animal {
  abstract makeSound(): void;
  
  protected constructor(protected name: string) {}
  
  move(): void {
    console.log(`${this.name} is moving`);
  }
}

// Implementation
class Dog extends Animal {
  constructor(name: string, private breed: string) {
    super(name);
  }
  
  makeSound(): void {
    console.log('Woof!');
  }
  
  getBreed(): string {
    return this.breed;
  }
}

// Interface implementation
interface Flyable {
  fly(): void;
}

class Bird extends Animal implements Flyable {
  makeSound(): void {
    console.log('Tweet!');
  }
  
  fly(): void {
    console.log(`${this.name} is flying`);
  }
}
```

### 3. Decorators (Experimental)
```typescript
// Method decorator
function log(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  
  descriptor.value = function (...args: any[]) {
    console.log(`Calling ${propertyKey} with args:`, args);
    return originalMethod.apply(this, args);
  };
}

class Calculator {
  @log
  add(a: number, b: number): number {
    return a + b;
  }
}
```

## Error Handling

### 1. Type-Safe Error Handling
```typescript
// Result type for error handling
type Result<T, E = Error> = 
  | { success: true; data: T }
  | { success: false; error: E };

async function fetchUser(id: string): Promise<Result<User, string>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return { success: false, error: 'User not found' };
    }
    const user = await response.json();
    return { success: true, data: user };
  } catch (error) {
    return { success: false, error: 'Network error' };
  }
}

// Usage
const result = await fetchUser('123');
if (result.success) {
  console.log(result.data.name); // TypeScript knows this is User
} else {
  console.error(result.error); // TypeScript knows this is string
}
```

### 2. Custom Error Types
```typescript
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'AppError';
  }
}

class ValidationError extends AppError {
  constructor(message: string, public field: string) {
    super(message, 'VALIDATION_ERROR', 400);
    this.name = 'ValidationError';
  }
}

// Type guard
function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}
```

## API and Data Handling

### 1. API Client with Types
```typescript
// API response types
interface ApiResponse<T> {
  data: T;
  message: string;
  status: number;
}

interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

// API client
class ApiClient {
  private baseURL: string;
  
  constructor(baseURL: string) {
    this.baseURL = baseURL;
  }
  
  private async request<T>(
    endpoint: string,
    options?: RequestInit
  ): Promise<ApiResponse<T>> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      ...options,
    });
    
    if (!response.ok) {
      throw new AppError(`API Error: ${response.statusText}`, 'API_ERROR', response.status);
    }
    
    return response.json();
  }
  
  async get<T>(endpoint: string): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint);
  }
  
  async post<T, U = any>(endpoint: string, data: U): Promise<ApiResponse<T>> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}
```

### 2. Form Validation with Types
```typescript
// Validation schema
interface UserFormData {
  name: string;
  email: string;
  age: number;
}

type ValidationRule<T> = {
  [K in keyof T]: (value: T[K]) => string | null;
};

const userValidationRules: ValidationRule<UserFormData> = {
  name: (value) => {
    if (!value || value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  },
  email: (value) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      return 'Invalid email format';
    }
    return null;
  },
  age: (value) => {
    if (value < 0 || value > 120) {
      return 'Age must be between 0 and 120';
    }
    return null;
  },
};

function validateForm<T extends Record<string, any>>(
  data: T,
  rules: ValidationRule<T>
): { isValid: boolean; errors: Partial<Record<keyof T, string>> } {
  const errors: Partial<Record<keyof T, string>> = {};
  
  for (const key in rules) {
    const error = rules[key](data[key]);
    if (error) {
      errors[key] = error;
    }
  }
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}
```

## Testing with TypeScript

### 1. Jest Configuration
```typescript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/__tests__/**',
  ],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
};
```

### 2. Type-Safe Testing
```typescript
// user.test.ts
import { User, createUser, validateUser } from '../user';

describe('User utilities', () => {
  describe('createUser', () => {
    it('should create a user with correct types', () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
      };
      
      const user = createUser(userData);
      
      // TypeScript ensures these properties exist and have correct types
      expect(user.id).toBeDefined();
      expect(typeof user.id).toBe('string');
      expect(user.name).toBe(userData.name);
      expect(user.email).toBe(userData.email);
      expect(user.createdAt).toBeInstanceOf(Date);
    });
  });
  
  describe('validateUser', () => {
    it('should validate user correctly', () => {
      const validUser: User = {
        id: '123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        createdAt: new Date(),
      };
      
      const result = validateUser(validUser);
      expect(result.isValid).toBe(true);
      expect(result.errors).toEqual({});
    });
  });
});
```

## Performance Optimization

### 1. Lazy Loading with Types
```typescript
// Dynamic imports with types
type LazyComponent<T = {}> = React.LazyExoticComponent<React.ComponentType<T>>;

const LazyDashboard: LazyComponent<{ userId: string }> = lazy(
  () => import('./Dashboard')
);

// Conditional type loading
type ModuleType = 'admin' | 'user' | 'guest';

async function loadModule(type: ModuleType) {
  switch (type) {
    case 'admin':
      return import('./modules/admin').then(m => m.AdminModule);
    case 'user':
      return import('./modules/user').then(m => m.UserModule);
    case 'guest':
      return import('./modules/guest').then(m => m.GuestModule);
  }
}
```

### 2. Memoization with Types
```typescript
// Type-safe memoization
function memoize<Args extends unknown[], Return>(
  fn: (...args: Args) => Return
): (...args: Args) => Return {
  const cache = new Map();
  
  return (...args: Args): Return => {
    const key = JSON.stringify(args);
    if (cache.has(key)) {
      return cache.get(key);
    }
    
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
}

// Usage
const expensiveCalculation = memoize((a: number, b: number): number => {
  // Complex calculation
  return a + b;
});
```

## Common Pitfalls to Avoid

1. **Using `any` type**: Always try to use specific types
2. **Ignoring strict mode**: Enable strict TypeScript checking
3. **Not using type guards**: Implement proper type narrowing
4. **Overusing union types**: Consider discriminated unions instead
5. **Not leveraging utility types**: Use built-in utility types
6. **Inconsistent naming**: Use consistent naming conventions
7. **Missing null checks**: Handle null and undefined values
8. **Not using readonly**: Use readonly for immutable data
9. **Ignoring index signatures**: Be careful with object indexing
10. **Poor generic constraints**: Use proper generic constraints

## Development Workflow

### 1. ESLint Configuration
```json
// .eslintrc.json
{
  "extends": [
    "@typescript-eslint/recommended",
    "@typescript-eslint/recommended-requiring-type-checking"
  ],
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/prefer-nullish-coalescing": "error",
    "@typescript-eslint/prefer-optional-chain": "error"
  }
}
```

### 2. VS Code Settings
```json
// .vscode/settings.json
{
  "typescript.preferences.strictness": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true
  },
  "typescript.suggest.autoImports": true,
  "typescript.updateImportsOnFileMove.enabled": "always",
  "editor.codeActionsOnSave": {
    "source.organizeImports": true,
    "source.fixAll.eslint": true
  }
}
```

## Useful Libraries

- **zod**: Runtime type validation
- **io-ts**: Runtime type checking
- **class-validator**: Decorator-based validation
- **type-fest**: Useful type utilities
- **utility-types**: Additional utility types
- **ts-pattern**: Pattern matching library
- **fp-ts**: Functional programming utilities

## Migration Strategies

### From JavaScript to TypeScript
1. Start with `allowJs: true` in tsconfig.json
2. Rename files gradually (.js to .ts)
3. Add types incrementally
4. Enable strict mode progressively
5. Use `// @ts-check` for gradual typing

### Type Definition Strategy
1. Start with basic types
2. Add interfaces for data structures
3. Implement generic types
4. Add advanced types as needed
5. Use code generation for APIs (OpenAPI, GraphQL)

This guide provides a comprehensive foundation for writing maintainable, type-safe TypeScript code with proper tooling and best practices.