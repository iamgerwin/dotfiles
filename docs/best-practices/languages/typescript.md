# TypeScript Best Practices

## Overview

TypeScript is a statically typed superset of JavaScript that compiles to plain JavaScript. Developed by Microsoft, it adds optional static typing, classes, interfaces, and other features to JavaScript, enabling better tooling, error detection at compile time, and improved code maintainability for large-scale applications.

## Pros & Cons

### Pros
- **Static Type Checking**: Catches errors at compile-time rather than runtime
- **Enhanced IDE Support**: Superior autocomplete, refactoring, and navigation
- **Better Documentation**: Types serve as inline documentation
- **Easier Refactoring**: Type system helps identify all affected code
- **Modern JavaScript Features**: Supports latest ECMAScript features
- **Gradual Adoption**: Can be incrementally added to existing JavaScript projects
- **Large Ecosystem**: Extensive type definitions for popular libraries

### Cons
- **Learning Curve**: Requires understanding of type systems and TypeScript-specific features
- **Build Step Required**: Needs compilation process to convert to JavaScript
- **Verbosity**: Can require more code than plain JavaScript
- **Configuration Complexity**: tsconfig.json can become complex for large projects
- **Type Definition Maintenance**: Third-party type definitions may lag behind library updates
- **Compilation Time**: Adds overhead to build process

## When to Use

TypeScript is ideal for:
- Large-scale applications with multiple developers
- Projects requiring long-term maintenance
- Applications where runtime errors are costly
- Teams transitioning from strongly-typed languages
- Projects with complex data structures and business logic
- Libraries and frameworks intended for public use
- Applications requiring robust refactoring capabilities

## Core Concepts

### Type System Fundamentals

```typescript
// Basic Types
let isDone: boolean = false;
let decimal: number = 6;
let color: string = "blue";
let list: number[] = [1, 2, 3];
let tuple: [string, number] = ["hello", 10];

// Enums
enum Color {
  Red = 1,
  Green,
  Blue
}
let c: Color = Color.Green;

// Any and Unknown
let notSure: any = 4;
let value: unknown = 4;

// Void, Null, and Undefined
function warnUser(): void {
  console.log("Warning!");
}
let u: undefined = undefined;
let n: null = null;

// Never
function error(message: string): never {
  throw new Error(message);
}

// Object Types
interface Person {
  firstName: string;
  lastName: string;
  age?: number; // Optional property
  readonly id: number; // Readonly property
}

// Union and Intersection Types
type StringOrNumber = string | number;
type Employee = Person & { employeeId: number };
```

### Advanced Type Features

```typescript
// Generics
function identity<T>(arg: T): T {
  return arg;
}

class GenericClass<T> {
  zeroValue: T;
  add: (x: T, y: T) => T;
}

// Conditional Types
type IsString<T> = T extends string ? true : false;

// Mapped Types
type Readonly<T> = {
  readonly [P in keyof T]: T[P];
};

// Template Literal Types
type EmailLocaleIDs = "welcome_email" | "email_heading";
type FooterLocaleIDs = "footer_title" | "footer_sendoff";
type AllLocaleIDs = `${EmailLocaleIDs | FooterLocaleIDs}_id`;

// Utility Types
type Partial<T> = { [P in keyof T]?: T[P] };
type Required<T> = { [P in keyof T]-?: T[P] };
type Pick<T, K extends keyof T> = { [P in K]: T[P] };
type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
```

## Installation & Setup

### Project Initialization

```bash
# Initialize npm project
npm init -y

# Install TypeScript
npm install --save-dev typescript

# Install type definitions for Node.js
npm install --save-dev @types/node

# Initialize TypeScript configuration
npx tsc --init
```

### Essential tsconfig.json Configuration

```json
{
  "compilerOptions": {
    // Language and Environment
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "commonjs",
    "moduleResolution": "node",

    // Type Checking
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,

    // Emit
    "outDir": "./dist",
    "rootDir": "./src",
    "sourceMap": true,
    "declaration": true,
    "declarationMap": true,
    "removeComments": true,

    // Interop Constraints
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,

    // Skip Lib Check
    "skipLibCheck": true,

    // Advanced
    "resolveJsonModule": true,
    "allowJs": true,
    "checkJs": false,
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.spec.ts"]
}
```

## Project Structure

```
project-root/
├── src/
│   ├── index.ts           # Application entry point
│   ├── types/             # Type definitions
│   │   ├── global.d.ts    # Global type declarations
│   │   └── models.ts      # Domain model types
│   ├── interfaces/        # Interface definitions
│   ├── utils/            # Utility functions
│   ├── services/         # Business logic
│   └── config/           # Configuration files
├── tests/
│   ├── unit/            # Unit tests
│   └── integration/     # Integration tests
├── dist/                # Compiled JavaScript output
├── node_modules/
├── package.json
├── tsconfig.json        # TypeScript configuration
├── tsconfig.build.json  # Production build config
├── .eslintrc.json      # ESLint configuration
└── .prettierrc         # Prettier configuration
```

## Development Patterns

### Type-Safe Function Patterns

```typescript
// Function Overloading
function reverse(x: string): string;
function reverse(x: number[]): number[];
function reverse(x: string | number[]): string | number[] {
  if (typeof x === 'string') {
    return x.split('').reverse().join('');
  }
  return x.slice().reverse();
}

// Type Guards
interface Bird {
  fly(): void;
  layEggs(): void;
}

interface Fish {
  swim(): void;
  layEggs(): void;
}

function isFish(pet: Fish | Bird): pet is Fish {
  return (pet as Fish).swim !== undefined;
}

// Assertion Functions
function assertIsString(val: any): asserts val is string {
  if (typeof val !== "string") {
    throw new Error("Not a string!");
  }
}

// Discriminated Unions
type Action =
  | { type: 'INCREMENT'; payload: number }
  | { type: 'DECREMENT'; payload: number }
  | { type: 'RESET' };

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'INCREMENT':
      return state + action.payload;
    case 'DECREMENT':
      return state - action.payload;
    case 'RESET':
      return 0;
  }
}
```

### Class Patterns

```typescript
// Abstract Classes
abstract class Animal {
  abstract makeSound(): void;

  move(): void {
    console.log("Moving...");
  }
}

// Class with Generics
class Container<T> {
  private value: T;

  constructor(value: T) {
    this.value = value;
  }

  getValue(): T {
    return this.value;
  }
}

// Mixins
type Constructor<T = {}> = new (...args: any[]) => T;

function Timestamped<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    timestamp = Date.now();
  };
}

function Activatable<TBase extends Constructor>(Base: TBase) {
  return class extends Base {
    isActivated = false;

    activate() {
      this.isActivated = true;
    }

    deactivate() {
      this.isActivated = false;
    }
  };
}

class User {
  name = '';
}

const TimestampedActivatableUser = Timestamped(Activatable(User));
const user = new TimestampedActivatableUser();
```

### Async Patterns

```typescript
// Promise Types
async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// Error Handling with Result Type
type Result<T, E = Error> =
  | { success: true; value: T }
  | { success: false; error: E };

async function safeFetch<T>(url: string): Promise<Result<T>> {
  try {
    const response = await fetch(url);
    if (!response.ok) {
      return { success: false, error: new Error(`HTTP ${response.status}`) };
    }
    const value = await response.json();
    return { success: true, value };
  } catch (error) {
    return { success: false, error: error as Error };
  }
}

// Async Iterators
async function* generateSequence(start: number, end: number) {
  for (let i = start; i <= end; i++) {
    await new Promise(resolve => setTimeout(resolve, 100));
    yield i;
  }
}
```

## Security Best Practices

### Input Validation

```typescript
// Use branded types for validation
type Email = string & { readonly brand: unique symbol };
type UserId = number & { readonly brand: unique symbol };

function isValidEmail(email: string): email is Email {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

function validateEmail(email: string): Email {
  if (!isValidEmail(email)) {
    throw new Error('Invalid email format');
  }
  return email;
}

// Runtime validation with type guards
interface UserInput {
  name: unknown;
  email: unknown;
  age: unknown;
}

function validateUserInput(input: UserInput): User {
  if (typeof input.name !== 'string' || input.name.length === 0) {
    throw new Error('Invalid name');
  }

  if (typeof input.email !== 'string' || !isValidEmail(input.email)) {
    throw new Error('Invalid email');
  }

  if (typeof input.age !== 'number' || input.age < 0 || input.age > 120) {
    throw new Error('Invalid age');
  }

  return {
    name: input.name,
    email: input.email,
    age: input.age
  };
}
```

### Preventing Type Confusion

```typescript
// Avoid using 'any'
// Bad
function processData(data: any) {
  return data.value; // Unsafe access
}

// Good
function processData<T extends { value: unknown }>(data: T) {
  if (typeof data.value === 'string') {
    return data.value;
  }
  throw new Error('Invalid data value');
}

// Use 'unknown' instead of 'any'
function parseJSON(text: string): unknown {
  return JSON.parse(text);
}

// Validate external data
interface APIResponse {
  data: unknown;
}

function isUserResponse(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'name' in data &&
    'email' in data &&
    typeof (data as any).name === 'string' &&
    typeof (data as any).email === 'string'
  );
}
```

### Secure Configuration

```typescript
// Environment variable validation
interface EnvConfig {
  NODE_ENV: 'development' | 'production' | 'test';
  PORT: number;
  DATABASE_URL: string;
  JWT_SECRET: string;
}

function loadConfig(): EnvConfig {
  const config: Partial<EnvConfig> = {
    NODE_ENV: process.env.NODE_ENV as EnvConfig['NODE_ENV'],
    PORT: parseInt(process.env.PORT || '3000', 10),
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
  };

  // Validate required fields
  if (!config.DATABASE_URL) {
    throw new Error('DATABASE_URL is required');
  }

  if (!config.JWT_SECRET) {
    throw new Error('JWT_SECRET is required');
  }

  if (!['development', 'production', 'test'].includes(config.NODE_ENV || '')) {
    config.NODE_ENV = 'development';
  }

  return config as EnvConfig;
}
```

## Performance Optimization

### Compilation Performance

```typescript
// tsconfig.json optimizations
{
  "compilerOptions": {
    // Use incremental compilation
    "incremental": true,
    "tsBuildInfoFile": ".tsbuildinfo",

    // Skip type checking of declaration files
    "skipLibCheck": true,

    // Use project references for large codebases
    "composite": true
  }
}

// Use const assertions for better performance
const config = {
  api: 'https://api.example.com',
  timeout: 5000
} as const;

// Prefer interfaces over type aliases for object types
// Interfaces are cached and reused, types are expanded each time
interface User {
  id: number;
  name: string;
}

// Not
type User = {
  id: number;
  name: string;
};
```

### Runtime Performance

```typescript
// Use enums sparingly (they generate runtime code)
// Prefer const assertions or string literal types
const Colors = {
  Red: 'red',
  Green: 'green',
  Blue: 'blue'
} as const;

type Color = typeof Colors[keyof typeof Colors];

// Optimize generic constraints
// Bad - creates new type for each call
function process<T>(item: T): T {
  return item;
}

// Good - reuses constraint
interface Processable {
  id: string;
}

function process<T extends Processable>(item: T): T {
  return item;
}

// Use readonly arrays to prevent mutations
function sum(numbers: readonly number[]): number {
  return numbers.reduce((a, b) => a + b, 0);
}
```

## Testing Strategies

### Unit Testing Setup

```typescript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.interface.ts'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  }
};

// Example test with type safety
import { Calculator } from '../src/calculator';

describe('Calculator', () => {
  let calculator: Calculator;

  beforeEach(() => {
    calculator = new Calculator();
  });

  describe('add', () => {
    it('should add two numbers correctly', () => {
      const result = calculator.add(2, 3);
      expect(result).toBe(5);
    });

    it('should handle negative numbers', () => {
      const result = calculator.add(-2, 3);
      expect(result).toBe(1);
    });
  });
});
```

### Type Testing

```typescript
// Type-level tests using conditional types
type Expect<T extends true> = T;
type Equal<X, Y> = (<T>() => T extends X ? 1 : 2) extends
  (<T>() => T extends Y ? 1 : 2) ? true : false;

// Test types
type test1 = Expect<Equal<string, string>>; // passes
type test2 = Expect<Equal<string, number>>; // fails

// Testing with dtslint or tsd
import { expectType, expectError, expectAssignable } from 'tsd';

interface User {
  name: string;
  age: number;
}

expectType<User>({name: 'John', age: 30});
expectError<User>({name: 'John'}); // Missing age
expectAssignable<User>({name: 'John', age: 30, extra: true}); // Extra props OK
```

## Deployment Guide

### Build Configuration

```json
// tsconfig.build.json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "rootDir": "./src",
    "outDir": "./dist",
    "sourceMap": false,
    "declaration": true,
    "declarationMap": false,
    "removeComments": true,
    "noEmitOnError": true
  },
  "exclude": [
    "node_modules",
    "**/*.spec.ts",
    "**/*.test.ts",
    "tests"
  ]
}
```

### Package.json Scripts

```json
{
  "scripts": {
    "build": "tsc -p tsconfig.build.json",
    "build:watch": "tsc -p tsconfig.build.json --watch",
    "clean": "rm -rf dist",
    "prebuild": "npm run clean",
    "start": "node dist/index.js",
    "dev": "ts-node-dev --respawn src/index.ts",
    "lint": "eslint . --ext .ts",
    "lint:fix": "eslint . --ext .ts --fix",
    "type-check": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "prepare": "npm run build"
  }
}
```

### Docker Configuration

```dockerfile
# Multi-stage build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src

# Build TypeScript
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built application
COPY --from=builder /app/dist ./dist

# Run application
CMD ["node", "dist/index.js"]
```

## Common Pitfalls

### Type System Pitfalls

```typescript
// 1. Overusing 'any'
// Bad
function process(data: any): any {
  return data.transform();
}

// Good
function process<T extends { transform(): U }, U>(data: T): U {
  return data.transform();
}

// 2. Not understanding structural typing
interface Point {
  x: number;
  y: number;
}

interface NamedPoint {
  x: number;
  y: number;
  name: string;
}

let p: Point = { x: 10, y: 20 };
let np: NamedPoint = { x: 10, y: 20, name: "origin" };
p = np; // OK - structural typing
// np = p; // Error - missing 'name'

// 3. Ignoring compiler warnings
// Always address TypeScript errors and warnings
// Use @ts-expect-error sparingly and with comments

// 4. Misusing type assertions
// Bad
const value = getUserInput() as string; // Unsafe

// Good
const value = getUserInput();
if (typeof value === 'string') {
  // value is string here
}

// 5. Not using strict mode
// Always enable strict mode in tsconfig.json
```

### Module System Pitfalls

```typescript
// 1. Mixing import styles
// Bad
import * as fs from 'fs';
const path = require('path'); // Don't mix

// Good
import * as fs from 'fs';
import * as path from 'path';

// 2. Not understanding module resolution
// Use explicit file extensions in imports for ESM
import { helper } from './helper.js'; // ESM
import { helper } from './helper'; // CommonJS

// 3. Circular dependencies
// Avoid circular imports by restructuring code
// Use dependency injection or events if needed
```

## Troubleshooting

### Common TypeScript Errors

```typescript
// 1. "Object is possibly 'undefined'"
// Solution: Use optional chaining or type guards
const value = obj?.property?.nested;

// 2. "Type 'X' is not assignable to type 'Y'"
// Solution: Check type compatibility
interface User {
  name: string;
  email: string;
}

const partialUser: Partial<User> = { name: 'John' };
// const user: User = partialUser; // Error
const user: User = { ...partialUser, email: 'john@example.com' };

// 3. "Cannot find module"
// Solution: Install type definitions
// npm install --save-dev @types/module-name

// 4. "Property does not exist on type"
// Solution: Use type assertions or extend types
interface Window {
  myCustomProperty: string;
}

window.myCustomProperty = 'value';

// 5. "Expression is not callable"
// Solution: Check function signatures
type Callback = (value: string) => void;
const cb: Callback = (value) => console.log(value);
cb('test'); // OK
```

### Build Issues

```bash
# Clear TypeScript cache
rm -rf node_modules/.cache
rm .tsbuildinfo

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check for type definition conflicts
npm ls @types/node

# Verify tsconfig.json
npx tsc --showConfig

# Debug compilation
npx tsc --listFiles
npx tsc --traceResolution
```

## Best Practices Summary

### Do's
- ✅ Enable strict mode from the start
- ✅ Use interfaces for object shapes
- ✅ Leverage type inference where possible
- ✅ Create custom type guards for runtime validation
- ✅ Use const assertions for literal types
- ✅ Organize types in dedicated files
- ✅ Document complex types with JSDoc
- ✅ Use generics for reusable code
- ✅ Validate external data at boundaries
- ✅ Keep type definitions close to usage

### Don'ts
- ❌ Don't use `any` unless absolutely necessary
- ❌ Don't ignore TypeScript errors
- ❌ Don't overuse type assertions
- ❌ Don't create overly complex type hierarchies
- ❌ Don't use `@ts-ignore` (use `@ts-expect-error` with explanation)
- ❌ Don't mix module systems (CommonJS/ESM)
- ❌ Don't forget to handle null/undefined
- ❌ Don't use enums for simple constants
- ❌ Don't skip type checking in tests
- ❌ Don't commit generated .d.ts files (unless publishing a library)

## Migration Strategy

### Migrating from JavaScript

```typescript
// 1. Rename .js files to .ts gradually
// 2. Start with loose configuration
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": false,
    "strict": false
  }
}

// 3. Add types incrementally
// Before
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// After
interface Item {
  price: number;
}

function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// 4. Enable strict checks gradually
// Start with individual flags before enabling strict: true
"noImplicitAny": true,
"strictNullChecks": true,
// ... then eventually
"strict": true
```

## Conclusion

TypeScript transforms JavaScript development by adding a robust type system that catches errors early, improves code documentation, and enables powerful refactoring capabilities. While it introduces compilation overhead and a learning curve, the benefits in code quality, maintainability, and developer productivity make it invaluable for serious JavaScript applications. Success with TypeScript comes from understanding its type system deeply, configuring it appropriately for your project's needs, and gradually adopting its strictest features as your team becomes comfortable with the language.

## Resources

- [Official TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [DefinitelyTyped Repository](https://github.com/DefinitelyTyped/DefinitelyTyped)
- [TypeScript Playground](https://www.typescriptlang.org/play)
- [TypeScript ESLint](https://typescript-eslint.io/)
- [ts-node Documentation](https://typestrong.org/ts-node/)
- [TypeScript Roadmap](https://github.com/microsoft/TypeScript/wiki/Roadmap)
- [TypeScript Performance Wiki](https://github.com/microsoft/TypeScript/wiki/Performance)
- [Type Challenges](https://github.com/type-challenges/type-challenges)