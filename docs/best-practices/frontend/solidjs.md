# Solid.js Best Practices

## Overview

Solid.js is a reactive JavaScript framework for building user interfaces with fine-grained reactivity and a compiler-based approach. Unlike other frameworks, Solid compiles away to efficient vanilla JavaScript, providing React-like syntax without a virtual DOM. It offers exceptional performance through its reactive primitives and reactive compilation, making it ideal for applications where performance is critical.

Solid.js combines the developer experience of React with the performance of vanilla JavaScript. It uses a compile-time approach to generate efficient reactive code, resulting in minimal runtime overhead and excellent bundle sizes.

## Pros & Cons

### Pros
- **Exceptional Performance**: No virtual DOM overhead, true fine-grained reactivity
- **Small Bundle Size**: Minimal runtime, efficient compilation process
- **React-like Syntax**: Easy migration path for React developers
- **Fine-grained Reactivity**: Updates only what actually changed
- **TypeScript Support**: Built with TypeScript from the ground up
- **Simple Mental Model**: Predictable reactivity without gotchas
- **Server-Side Rendering**: Built-in SSR support with streaming
- **No Stale Closures**: Reactive primitives prevent common React pitfalls
- **Excellent Developer Experience**: Great tooling and debugging
- **True Reactivity**: Values are reactive by default, not re-execution based

### Cons
- **Smaller Ecosystem**: Fewer third-party libraries compared to React
- **Learning Curve**: Different mental model from React despite similar syntax
- **Less Community**: Smaller community and fewer resources
- **Debugging Complexity**: Reactive dependencies can be harder to debug
- **Compilation Dependency**: Requires build step and Solid-specific tooling
- **Limited Job Market**: Fewer opportunities compared to mainstream frameworks

## When to Use

Solid.js is ideal for:
- Performance-critical applications requiring minimal overhead
- Applications with complex state management needs
- Projects where bundle size is a primary concern
- Teams experienced with React looking for better performance
- Real-time applications with frequent updates
- Applications requiring fine-grained control over updates
- Mobile web applications where performance matters
- Projects where SEO and SSR are important

Avoid Solid.js for:
- Simple static websites with minimal interactivity
- Projects requiring large existing React ecosystem libraries
- Teams without JavaScript framework experience
- Applications with very short development timelines
- Projects where developer hiring is a primary concern
- Applications requiring IE11 support

## Core Concepts

### Reactive Primitives

```jsx
// Signals - Basic reactive primitive
import { createSignal } from 'solid-js'

function Counter() {
  const [count, setCount] = createSignal(0)

  // Functions that access signals are automatically reactive
  const doubleCount = () => count() * 2

  return (
    <div>
      <p>Count: {count()}</p>
      <p>Double: {doubleCount()}</p>
      <button onClick={() => setCount(count() + 1)}>
        Increment
      </button>
    </div>
  )
}

// Derived state with createMemo
import { createSignal, createMemo } from 'solid-js'

function ExpensiveCalculation() {
  const [number, setNumber] = createSignal(1)

  // Memoized computation - only runs when dependencies change
  const factorial = createMemo(() => {
    console.log('Computing factorial...')
    let result = 1
    for (let i = 1; i <= number(); i++) {
      result *= i
    }
    return result
  })

  return (
    <div>
      <input
        type="number"
        value={number()}
        onInput={(e) => setNumber(parseInt(e.target.value) || 1)}
      />
      <p>Factorial: {factorial()}</p>
    </div>
  )
}

// Effects for side effects
import { createSignal, createEffect } from 'solid-js'

function UserProfile() {
  const [userId, setUserId] = createSignal(1)
  const [user, setUser] = createSignal(null)
  const [loading, setLoading] = createSignal(false)

  // Effect runs when userId changes
  createEffect(async () => {
    const id = userId()
    if (!id) return

    setLoading(true)
    try {
      const response = await fetch(`/api/users/${id}`)
      const userData = await response.json()
      setUser(userData)
    } catch (error) {
      console.error('Failed to fetch user:', error)
      setUser(null)
    } finally {
      setLoading(false)
    }
  })

  return (
    <div>
      <input
        type="number"
        value={userId()}
        onInput={(e) => setUserId(parseInt(e.target.value))}
      />
      {loading() && <p>Loading...</p>}
      {user() && (
        <div>
          <h2>{user().name}</h2>
          <p>{user().email}</p>
        </div>
      )}
    </div>
  )
}
```

### Component Patterns

```jsx
// Basic component with props
function Greeting(props) {
  return <h1>Hello, {props.name}!</h1>
}

// Component with children
function Card(props) {
  return (
    <div class="card">
      <div class="card-header">
        {props.title}
      </div>
      <div class="card-body">
        {props.children}
      </div>
    </div>
  )
}

// Component with reactive props
function UserCard(props) {
  const fullName = () => `${props.user.firstName} ${props.user.lastName}`

  return (
    <div class="user-card">
      <img src={props.user.avatar} alt={fullName()} />
      <h3>{fullName()}</h3>
      <p>{props.user.email}</p>
    </div>
  )
}

// Generic component with TypeScript
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
  children: any
}

function Button(props: ButtonProps) {
  const baseClasses = 'btn'
  const variantClass = () => `btn-${props.variant || 'primary'}`
  const sizeClass = () => `btn-${props.size || 'md'}`

  const classes = () => [
    baseClasses,
    variantClass(),
    sizeClass(),
    props.disabled && 'btn-disabled'
  ].filter(Boolean).join(' ')

  return (
    <button
      class={classes()}
      disabled={props.disabled}
      onClick={props.onClick}
    >
      {props.children}
    </button>
  )
}

// Component with local state
function TodoItem(props) {
  const [isEditing, setIsEditing] = createSignal(false)
  const [editText, setEditText] = createSignal(props.todo.text)

  const handleSave = () => {
    if (editText().trim()) {
      props.onUpdate(props.todo.id, editText().trim())
      setIsEditing(false)
    }
  }

  const handleCancel = () => {
    setEditText(props.todo.text)
    setIsEditing(false)
  }

  return (
    <div class="todo-item">
      {isEditing() ? (
        <div class="todo-edit">
          <input
            type="text"
            value={editText()}
            onInput={(e) => setEditText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleSave()
              if (e.key === 'Escape') handleCancel()
            }}
          />
          <button onClick={handleSave}>Save</button>
          <button onClick={handleCancel}>Cancel</button>
        </div>
      ) : (
        <div class="todo-display">
          <span
            class={props.todo.completed ? 'completed' : ''}
            onDblClick={() => setIsEditing(true)}
          >
            {props.todo.text}
          </span>
          <button onClick={() => props.onToggle(props.todo.id)}>
            {props.todo.completed ? 'Undo' : 'Complete'}
          </button>
          <button onClick={() => props.onDelete(props.todo.id)}>
            Delete
          </button>
        </div>
      )}
    </div>
  )
}
```

### Control Flow

```jsx
import { For, Show, Switch, Match, Index } from 'solid-js'

// Conditional rendering with Show
function ConditionalContent() {
  const [user, setUser] = createSignal(null)
  const [loading, setLoading] = createSignal(false)

  return (
    <div>
      <Show when={loading()}>
        <div class="spinner">Loading...</div>
      </Show>

      <Show when={user()} fallback={<p>Please log in</p>}>
        <div>
          <h2>Welcome, {user()?.name}!</h2>
          <p>Email: {user()?.email}</p>
        </div>
      </Show>
    </div>
  )
}

// List rendering with For
function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: 1, text: 'Learn Solid.js', completed: false },
    { id: 2, text: 'Build an app', completed: false },
    { id: 3, text: 'Deploy to production', completed: false }
  ])

  const addTodo = (text) => {
    const newTodo = {
      id: Date.now(),
      text,
      completed: false
    }
    setTodos([...todos(), newTodo])
  }

  const toggleTodo = (id) => {
    setTodos(todos().map(todo =>
      todo.id === id ? { ...todo, completed: !todo.completed } : todo
    ))
  }

  return (
    <div>
      <h2>Todo List</h2>
      <For each={todos()}>
        {(todo) => (
          <div class="todo-item">
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => toggleTodo(todo.id)}
            />
            <span class={todo.completed ? 'completed' : ''}>
              {todo.text}
            </span>
          </div>
        )}
      </For>
    </div>
  )
}

// Index-based iteration for better performance
function OptimizedList() {
  const [items, setItems] = createSignal(['apple', 'banana', 'cherry'])

  return (
    <div>
      <Index each={items()}>
        {(item, index) => (
          <div>
            {index}: {item()}
          </div>
        )}
      </Index>
    </div>
  )
}

// Switch for multiple conditions
function StatusIndicator(props) {
  return (
    <Switch>
      <Match when={props.status === 'loading'}>
        <div class="status loading">Loading...</div>
      </Match>
      <Match when={props.status === 'success'}>
        <div class="status success">Success!</div>
      </Match>
      <Match when={props.status === 'error'}>
        <div class="status error">Error occurred</div>
      </Match>
      <Match when={true}>
        <div class="status idle">Ready</div>
      </Match>
    </Switch>
  )
}
```

## Installation & Setup

### Project Initialization

```bash
# Create new Solid.js project using degit
npx degit solidjs/templates/js my-solid-app
cd my-solid-app
npm install

# Or with TypeScript
npx degit solidjs/templates/ts my-solid-app
cd my-solid-app
npm install

# Alternative: using Vite directly
npm create solid@latest my-solid-app
cd my-solid-app
npm install

# Start development server
npm run dev
```

### Manual Setup with Vite

```bash
# Create new Vite project
npm create vite@latest my-solid-app -- --template vanilla
cd my-solid-app
npm install

# Install Solid.js dependencies
npm install solid-js
npm install --save-dev vite-plugin-solid @babel/preset-typescript

# Install additional tooling
npm install --save-dev @types/node
```

### Vite Configuration

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import solid from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solid()],
  build: {
    target: 'esnext',
  },
  resolve: {
    alias: {
      '@': '/src',
    },
  },
  server: {
    port: 3000,
    open: true,
  },
})
```

### TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ESNext",
    "lib": ["DOM", "DOM.Iterable", "ES6"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": false,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "jsxImportSource": "solid-js",
    "types": ["vite/client"],
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

### Basic Project Structure

```
my-solid-app/
├── public/
│   ├── favicon.ico
│   └── index.html
├── src/
│   ├── components/
│   │   ├── common/
│   │   │   ├── Button.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── Loading.tsx
│   │   └── layout/
│   │       ├── Header.tsx
│   │       ├── Footer.tsx
│   │       └── Sidebar.tsx
│   ├── pages/
│   │   ├── Home.tsx
│   │   ├── About.tsx
│   │   └── Contact.tsx
│   ├── stores/
│   │   ├── userStore.ts
│   │   └── appStore.ts
│   ├── utils/
│   │   ├── api.ts
│   │   └── helpers.ts
│   ├── styles/
│   │   ├── index.css
│   │   └── components.css
│   ├── App.tsx
│   └── index.tsx
├── package.json
├── vite.config.js
└── tsconfig.json
```

## Project Structure

### Component Organization

```typescript
// src/components/common/Button.tsx
import { Component, JSX } from 'solid-js'
import { splitProps } from 'solid-js'

interface ButtonProps extends JSX.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  children: JSX.Element
}

export const Button: Component<ButtonProps> = (props) => {
  const [local, others] = splitProps(props, ['variant', 'size', 'loading', 'children', 'class'])

  const classes = () => {
    const base = 'btn'
    const variant = `btn-${local.variant || 'primary'}`
    const size = `btn-${local.size || 'md'}`
    const loading = local.loading ? 'btn-loading' : ''
    const custom = local.class || ''

    return [base, variant, size, loading, custom].filter(Boolean).join(' ')
  }

  return (
    <button
      class={classes()}
      disabled={local.loading || others.disabled}
      {...others}
    >
      {local.loading ? (
        <span class="btn-spinner">Loading...</span>
      ) : (
        local.children
      )}
    </button>
  )
}

// src/components/common/Modal.tsx
import { Component, JSX, Show } from 'solid-js'
import { Portal } from 'solid-js/web'

interface ModalProps {
  open: boolean
  onClose: () => void
  title?: string
  children: JSX.Element
}

export const Modal: Component<ModalProps> = (props) => {
  const handleBackdropClick = (e: MouseEvent) => {
    if (e.target === e.currentTarget) {
      props.onClose()
    }
  }

  return (
    <Show when={props.open}>
      <Portal>
        <div class="modal-backdrop" onClick={handleBackdropClick}>
          <div class="modal-content">
            <div class="modal-header">
              <h2>{props.title}</h2>
              <button class="modal-close" onClick={props.onClose}>
                ×
              </button>
            </div>
            <div class="modal-body">
              {props.children}
            </div>
          </div>
        </div>
      </Portal>
    </Show>
  )
}

// src/components/layout/Header.tsx
import { Component } from 'solid-js'
import { Button } from '../common/Button'

interface HeaderProps {
  user?: { name: string; avatar: string } | null
  onLogin: () => void
  onLogout: () => void
}

export const Header: Component<HeaderProps> = (props) => {
  return (
    <header class="app-header">
      <div class="header-container">
        <div class="header-logo">
          <h1>My App</h1>
        </div>

        <nav class="header-nav">
          <a href="/">Home</a>
          <a href="/about">About</a>
          <a href="/contact">Contact</a>
        </nav>

        <div class="header-actions">
          {props.user ? (
            <div class="user-menu">
              <img src={props.user.avatar} alt={props.user.name} />
              <span>{props.user.name}</span>
              <Button variant="secondary" size="sm" onClick={props.onLogout}>
                Logout
              </Button>
            </div>
          ) : (
            <Button onClick={props.onLogin}>
              Login
            </Button>
          )}
        </div>
      </div>
    </header>
  )
}
```

### Store Management

```typescript
// src/stores/userStore.ts
import { createSignal, createMemo } from 'solid-js'

interface User {
  id: string
  name: string
  email: string
  avatar: string
  role: 'admin' | 'user'
}

// Create store with signals
const [user, setUser] = createSignal<User | null>(null)
const [loading, setLoading] = createSignal(false)
const [error, setError] = createSignal<string | null>(null)

// Derived state
const isAuthenticated = createMemo(() => user() !== null)
const isAdmin = createMemo(() => user()?.role === 'admin')

// Actions
const login = async (email: string, password: string) => {
  setLoading(true)
  setError(null)

  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    })

    if (!response.ok) {
      throw new Error('Login failed')
    }

    const userData = await response.json()
    setUser(userData.user)
    localStorage.setItem('token', userData.token)
  } catch (err) {
    setError(err instanceof Error ? err.message : 'Login failed')
  } finally {
    setLoading(false)
  }
}

const logout = () => {
  setUser(null)
  localStorage.removeItem('token')
}

const updateProfile = async (updates: Partial<User>) => {
  if (!user()) return

  setLoading(true)
  try {
    const response = await fetch('/api/user/profile', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(updates)
    })

    if (!response.ok) {
      throw new Error('Update failed')
    }

    const updatedUser = await response.json()
    setUser(updatedUser)
  } catch (err) {
    setError(err instanceof Error ? err.message : 'Update failed')
  } finally {
    setLoading(false)
  }
}

// Export store
export const userStore = {
  // State
  user,
  loading,
  error,
  // Computed
  isAuthenticated,
  isAdmin,
  // Actions
  login,
  logout,
  updateProfile,
  setUser
}

// src/stores/appStore.ts
import { createSignal, createMemo } from 'solid-js'

interface AppState {
  theme: 'light' | 'dark'
  sidebarOpen: boolean
  notifications: Notification[]
}

interface Notification {
  id: string
  type: 'info' | 'success' | 'warning' | 'error'
  message: string
  timestamp: Date
}

const [theme, setTheme] = createSignal<'light' | 'dark'>('light')
const [sidebarOpen, setSidebarOpen] = createSignal(false)
const [notifications, setNotifications] = createSignal<Notification[]>([])

// Initialize theme from localStorage
const savedTheme = localStorage.getItem('theme') as 'light' | 'dark'
if (savedTheme) {
  setTheme(savedTheme)
}

// Computed values
const unreadNotifications = createMemo(() =>
  notifications().filter(n => !n.read).length
)

// Actions
const toggleTheme = () => {
  const newTheme = theme() === 'light' ? 'dark' : 'light'
  setTheme(newTheme)
  localStorage.setItem('theme', newTheme)
  document.documentElement.setAttribute('data-theme', newTheme)
}

const toggleSidebar = () => {
  setSidebarOpen(!sidebarOpen())
}

const addNotification = (
  type: Notification['type'],
  message: string,
  autoRemove = true
) => {
  const notification: Notification = {
    id: crypto.randomUUID(),
    type,
    message,
    timestamp: new Date()
  }

  setNotifications([notification, ...notifications()])

  if (autoRemove) {
    setTimeout(() => removeNotification(notification.id), 5000)
  }
}

const removeNotification = (id: string) => {
  setNotifications(notifications().filter(n => n.id !== id))
}

export const appStore = {
  // State
  theme,
  sidebarOpen,
  notifications,
  // Computed
  unreadNotifications,
  // Actions
  toggleTheme,
  toggleSidebar,
  addNotification,
  removeNotification
}
```

## Development Patterns

### Custom Hooks (Reactive Utilities)

```typescript
// src/hooks/useApi.ts
import { createSignal, createMemo } from 'solid-js'

interface ApiState<T> {
  data: T | null
  loading: boolean
  error: string | null
}

export function useApi<T>(url: string) {
  const [state, setState] = createSignal<ApiState<T>>({
    data: null,
    loading: false,
    error: null
  })

  const fetch = async () => {
    setState({ data: null, loading: true, error: null })

    try {
      const response = await window.fetch(url)
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      const data = await response.json()
      setState({ data, loading: false, error: null })
    } catch (error) {
      setState({
        data: null,
        loading: false,
        error: error instanceof Error ? error.message : 'Fetch failed'
      })
    }
  }

  const data = createMemo(() => state().data)
  const loading = createMemo(() => state().loading)
  const error = createMemo(() => state().error)

  return { data, loading, error, fetch }
}

// src/hooks/useLocalStorage.ts
import { createSignal, createEffect } from 'solid-js'

export function useLocalStorage<T>(key: string, defaultValue: T) {
  const [value, setValue] = createSignal<T>(() => {
    try {
      const item = localStorage.getItem(key)
      return item ? JSON.parse(item) : defaultValue
    } catch {
      return defaultValue
    }
  })

  createEffect(() => {
    try {
      localStorage.setItem(key, JSON.stringify(value()))
    } catch (error) {
      console.error(`Error saving to localStorage:`, error)
    }
  })

  return [value, setValue] as const
}

// src/hooks/useForm.ts
import { createSignal, createMemo } from 'solid-js'

interface FormField {
  value: any
  error?: string
  touched?: boolean
}

interface FormConfig<T> {
  initialValues: T
  validate?: (values: T) => Partial<Record<keyof T, string>>
  onSubmit: (values: T) => void | Promise<void>
}

export function useForm<T extends Record<string, any>>(config: FormConfig<T>) {
  const [fields, setFields] = createSignal<Record<keyof T, FormField>>(
    Object.keys(config.initialValues).reduce((acc, key) => {
      acc[key as keyof T] = {
        value: config.initialValues[key as keyof T],
        touched: false
      }
      return acc
    }, {} as Record<keyof T, FormField>)
  )

  const [isSubmitting, setIsSubmitting] = createSignal(false)

  const values = createMemo(() => {
    const currentFields = fields()
    return Object.keys(currentFields).reduce((acc, key) => {
      acc[key as keyof T] = currentFields[key as keyof T].value
      return acc
    }, {} as T)
  })

  const errors = createMemo(() => {
    if (!config.validate) return {}
    return config.validate(values())
  })

  const isValid = createMemo(() => {
    const currentErrors = errors()
    return Object.keys(currentErrors).length === 0
  })

  const setValue = (name: keyof T, value: any) => {
    setFields(prev => ({
      ...prev,
      [name]: {
        ...prev[name],
        value,
        touched: true,
        error: errors()[name]
      }
    }))
  }

  const setTouched = (name: keyof T, touched = true) => {
    setFields(prev => ({
      ...prev,
      [name]: {
        ...prev[name],
        touched
      }
    }))
  }

  const submit = async () => {
    if (!isValid() || isSubmitting()) return

    setIsSubmitting(true)
    try {
      await config.onSubmit(values())
    } finally {
      setIsSubmitting(false)
    }
  }

  const reset = () => {
    setFields(
      Object.keys(config.initialValues).reduce((acc, key) => {
        acc[key as keyof T] = {
          value: config.initialValues[key as keyof T],
          touched: false
        }
        return acc
      }, {} as Record<keyof T, FormField>)
    )
  }

  return {
    fields,
    values,
    errors,
    isValid,
    isSubmitting,
    setValue,
    setTouched,
    submit,
    reset
  }
}

// Usage example
function ContactForm() {
  const form = useForm({
    initialValues: {
      name: '',
      email: '',
      message: ''
    },
    validate: (values) => {
      const errors: Partial<Record<keyof typeof values, string>> = {}

      if (!values.name.trim()) {
        errors.name = 'Name is required'
      }

      if (!values.email.trim()) {
        errors.email = 'Email is required'
      } else if (!/\S+@\S+\.\S+/.test(values.email)) {
        errors.email = 'Email is invalid'
      }

      if (!values.message.trim()) {
        errors.message = 'Message is required'
      }

      return errors
    },
    onSubmit: async (values) => {
      console.log('Submitting:', values)
      // Submit logic here
    }
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.submit() }}>
      <div>
        <input
          type="text"
          placeholder="Name"
          value={form.values().name}
          onInput={(e) => form.setValue('name', e.target.value)}
          onBlur={() => form.setTouched('name')}
        />
        {form.errors().name && <span class="error">{form.errors().name}</span>}
      </div>

      <div>
        <input
          type="email"
          placeholder="Email"
          value={form.values().email}
          onInput={(e) => form.setValue('email', e.target.value)}
          onBlur={() => form.setTouched('email')}
        />
        {form.errors().email && <span class="error">{form.errors().email}</span>}
      </div>

      <div>
        <textarea
          placeholder="Message"
          value={form.values().message}
          onInput={(e) => form.setValue('message', e.target.value)}
          onBlur={() => form.setTouched('message')}
        />
        {form.errors().message && <span class="error">{form.errors().message}</span>}
      </div>

      <button type="submit" disabled={!form.isValid() || form.isSubmitting()}>
        {form.isSubmitting() ? 'Sending...' : 'Send'}
      </button>
    </form>
  )
}
```

### Routing with Solid Router

```bash
# Install Solid Router
npm install @solidjs/router
```

```typescript
// src/App.tsx
import { Router, Route, Routes } from '@solidjs/router'
import { Component, lazy } from 'solid-js'

// Lazy load pages
const Home = lazy(() => import('./pages/Home'))
const About = lazy(() => import('./pages/About'))
const Contact = lazy(() => import('./pages/Contact'))
const UserProfile = lazy(() => import('./pages/UserProfile'))
const NotFound = lazy(() => import('./pages/NotFound'))

const App: Component = () => {
  return (
    <Router>
      <Routes>
        <Route path="/" component={Home} />
        <Route path="/about" component={About} />
        <Route path="/contact" component={Contact} />
        <Route path="/user/:id" component={UserProfile} />
        <Route path="*" component={NotFound} />
      </Routes>
    </Router>
  )
}

export default App

// src/pages/UserProfile.tsx
import { Component, createResource } from 'solid-js'
import { useParams } from '@solidjs/router'

const UserProfile: Component = () => {
  const params = useParams()

  const [user] = createResource(
    () => params.id,
    async (id) => {
      const response = await fetch(`/api/users/${id}`)
      if (!response.ok) {
        throw new Error('User not found')
      }
      return response.json()
    }
  )

  return (
    <div>
      <h1>User Profile</h1>
      {user.loading && <p>Loading user...</p>}
      {user.error && <p>Error: {user.error.message}</p>}
      {user() && (
        <div>
          <h2>{user().name}</h2>
          <p>Email: {user().email}</p>
          <p>Joined: {new Date(user().createdAt).toLocaleDateString()}</p>
        </div>
      )}
    </div>
  )
}

export default UserProfile

// Protected routes
import { Component, Show } from 'solid-js'
import { Navigate } from '@solidjs/router'
import { userStore } from '../stores/userStore'

interface ProtectedRouteProps {
  children: any
}

const ProtectedRoute: Component<ProtectedRouteProps> = (props) => {
  return (
    <Show when={userStore.isAuthenticated()} fallback={<Navigate href="/login" />}>
      {props.children}
    </Show>
  )
}

// Usage in router
<Route path="/dashboard" component={() =>
  <ProtectedRoute>
    <Dashboard />
  </ProtectedRoute>
} />
```

### Resource Management

```typescript
// src/resources/userResource.ts
import { createResource, createSignal } from 'solid-js'

export function createUserResource() {
  const [userId, setUserId] = createSignal<string>()

  const [user, { mutate, refetch }] = createResource(
    userId,
    async (id: string) => {
      const response = await fetch(`/api/users/${id}`)
      if (!response.ok) {
        throw new Error(`Failed to fetch user: ${response.statusText}`)
      }
      return response.json()
    }
  )

  const updateUser = async (id: string, updates: any) => {
    // Optimistic update
    mutate(prev => prev ? { ...prev, ...updates } : null)

    try {
      const response = await fetch(`/api/users/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates)
      })

      if (!response.ok) {
        throw new Error('Update failed')
      }

      const updatedUser = await response.json()
      mutate(updatedUser)
      return updatedUser
    } catch (error) {
      // Revert optimistic update on error
      refetch()
      throw error
    }
  }

  return {
    user,
    setUserId,
    updateUser,
    refetch
  }
}

// Global resource management
import { createRoot, createSignal, createResource } from 'solid-js'

function createGlobalState() {
  const [users, setUsers] = createSignal<any[]>([])

  const [usersResource] = createResource(
    async () => {
      const response = await fetch('/api/users')
      return response.json()
    }
  )

  return {
    users,
    setUsers,
    usersResource
  }
}

export const globalState = createRoot(createGlobalState)
```

## Security Best Practices

### Input Sanitization and XSS Prevention

```typescript
// src/utils/sanitize.ts
export function sanitizeHtml(html: string): string {
  const div = document.createElement('div')
  div.textContent = html
  return div.innerHTML
}

export function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

// Safe component for rendering user content
import { Component } from 'solid-js'

interface SafeHtmlProps {
  content: string
}

const SafeHtml: Component<SafeHtmlProps> = (props) => {
  const sanitized = () => sanitizeHtml(props.content)

  return <div innerHTML={sanitized()} />
}

// Input validation
export function validateEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

export function validatePassword(password: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters long')
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }

  if (!/\d/.test(password)) {
    errors.push('Password must contain at least one number')
  }

  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push('Password must contain at least one special character')
  }

  return {
    isValid: errors.length === 0,
    errors
  }
}

// Secure form component
import { Component } from 'solid-js'
import { useForm } from '../hooks/useForm'

const SecureLoginForm: Component = () => {
  const form = useForm({
    initialValues: {
      email: '',
      password: ''
    },
    validate: (values) => {
      const errors: any = {}

      if (!validateEmail(values.email)) {
        errors.email = 'Please enter a valid email address'
      }

      if (!values.password) {
        errors.password = 'Password is required'
      }

      return errors
    },
    onSubmit: async (values) => {
      try {
        const response = await fetch('/api/auth/login', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          },
          credentials: 'same-origin',
          body: JSON.stringify(values)
        })

        if (!response.ok) {
          throw new Error('Login failed')
        }

        const data = await response.json()
        // Handle successful login
      } catch (error) {
        console.error('Login error:', error)
      }
    }
  })

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.submit() }}>
      <div>
        <input
          type="email"
          placeholder="Email"
          value={form.values().email}
          onInput={(e) => form.setValue('email', e.target.value)}
          autocomplete="email"
          required
        />
        {form.errors().email && <span class="error">{form.errors().email}</span>}
      </div>

      <div>
        <input
          type="password"
          placeholder="Password"
          value={form.values().password}
          onInput={(e) => form.setValue('password', e.target.value)}
          autocomplete="current-password"
          required
        />
        {form.errors().password && <span class="error">{form.errors().password}</span>}
      </div>

      <button type="submit" disabled={!form.isValid() || form.isSubmitting()}>
        {form.isSubmitting() ? 'Signing in...' : 'Sign In'}
      </button>
    </form>
  )
}
```

### Content Security Policy

```typescript
// src/utils/csp.ts
export function setupCSP() {
  const meta = document.createElement('meta')
  meta.httpEquiv = 'Content-Security-Policy'
  meta.content = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "connect-src 'self'",
    "font-src 'self'",
    "frame-src 'none'",
    "object-src 'none'",
    "base-uri 'self'"
  ].join('; ')

  document.head.appendChild(meta)
}

// Call during app initialization
setupCSP()
```

### Authentication Patterns

```typescript
// src/auth/authContext.tsx
import { Component, createContext, useContext, ParentComponent } from 'solid-js'
import { userStore } from '../stores/userStore'

const AuthContext = createContext()

export const AuthProvider: ParentComponent = (props) => {
  const auth = {
    ...userStore,

    refreshToken: async () => {
      try {
        const response = await fetch('/api/auth/refresh', {
          method: 'POST',
          credentials: 'include'
        })

        if (response.ok) {
          const data = await response.json()
          userStore.setUser(data.user)
          return true
        }

        return false
      } catch {
        return false
      }
    },

    initializeAuth: async () => {
      const token = localStorage.getItem('token')
      if (!token) return

      try {
        const response = await fetch('/api/auth/me', {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        })

        if (response.ok) {
          const data = await response.json()
          userStore.setUser(data.user)
        } else {
          localStorage.removeItem('token')
        }
      } catch {
        localStorage.removeItem('token')
      }
    }
  }

  return (
    <AuthContext.Provider value={auth}>
      {props.children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}
```

## Performance Optimization

### Bundle Optimization

```typescript
// Lazy loading components
import { lazy, Component, Suspense } from 'solid-js'

const HeavyComponent = lazy(() => import('./HeavyComponent'))

const App: Component = () => {
  return (
    <div>
      <Suspense fallback={<div>Loading...</div>}>
        <HeavyComponent />
      </Suspense>
    </div>
  )
}

// Code splitting with dynamic imports
const loadModule = async () => {
  const module = await import('./heavyModule')
  return module.default
}

// Preloading critical routes
import('./pages/Dashboard')
import('./pages/Profile')
```

### Memory Management

```typescript
// Proper cleanup in effects
import { createSignal, createEffect, onCleanup } from 'solid-js'

function useWebSocket(url: string) {
  const [connected, setConnected] = createSignal(false)
  const [message, setMessage] = createSignal('')

  createEffect(() => {
    const ws = new WebSocket(url)

    ws.onopen = () => setConnected(true)
    ws.onclose = () => setConnected(false)
    ws.onmessage = (event) => setMessage(event.data)

    // Cleanup when effect reruns or component unmounts
    onCleanup(() => {
      ws.close()
    })
  })

  return { connected, message }
}

// Avoiding memory leaks with event listeners
function useEventListener(target: EventTarget, event: string, handler: EventListener) {
  createEffect(() => {
    target.addEventListener(event, handler)

    onCleanup(() => {
      target.removeEventListener(event, handler)
    })
  })
}
```

### Rendering Optimization

```typescript
// Using Index for better performance with lists
import { Index, For } from 'solid-js'

// Better for lists where order matters and items change frequently
function OptimizedList(props) {
  return (
    <Index each={props.items}>
      {(item, index) => (
        <div data-index={index()}>
          {item().name}: {item().value}
        </div>
      )}
    </Index>
  )
}

// Use For when items have stable keys
function StableList(props) {
  return (
    <For each={props.items}>
      {(item) => (
        <div key={item.id}>
          {item.name}: {item.value}
        </div>
      )}
    </For>
  )
}

// Memoization for expensive computations
import { createMemo } from 'solid-js'

function ExpensiveComponent(props) {
  const expensiveValue = createMemo(() => {
    console.log('Computing expensive value...')
    return props.data.reduce((sum, item) => sum + item.value * item.multiplier, 0)
  })

  return <div>Result: {expensiveValue()}</div>
}

// Batching updates
import { batch } from 'solid-js'

function batchUpdates() {
  batch(() => {
    setName('John')
    setAge(30)
    setEmail('john@example.com')
  })
}
```

## Testing Strategies

### Unit Testing Setup

```bash
# Install testing dependencies
npm install --save-dev vitest @solidjs/testing-library jsdom
npm install --save-dev @testing-library/jest-dom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import solid from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solid()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
  },
  resolve: {
    conditions: ['development', 'browser'],
  },
})

// src/test/setup.ts
import '@testing-library/jest-dom'

// Mock global objects
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})
```

### Component Testing

```typescript
// src/components/__tests__/Button.test.tsx
import { render, screen, fireEvent } from '@solidjs/testing-library'
import { describe, it, expect, vi } from 'vitest'
import { Button } from '../common/Button'

describe('Button', () => {
  it('renders with correct text', () => {
    render(() => <Button>Click me</Button>)
    expect(screen.getByRole('button')).toHaveTextContent('Click me')
  })

  it('applies correct classes based on props', () => {
    render(() => (
      <Button variant="danger" size="lg">
        Delete
      </Button>
    ))

    const button = screen.getByRole('button')
    expect(button).toHaveClass('btn', 'btn-danger', 'btn-lg')
  })

  it('handles click events', () => {
    const handleClick = vi.fn()
    render(() => <Button onClick={handleClick}>Click me</Button>)

    fireEvent.click(screen.getByRole('button'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('shows loading state', () => {
    render(() => <Button loading>Submit</Button>)

    const button = screen.getByRole('button')
    expect(button).toBeDisabled()
    expect(button).toHaveTextContent('Loading...')
  })

  it('is disabled when loading prop is true', () => {
    render(() => <Button loading>Submit</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})

// src/stores/__tests__/userStore.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { userStore } from '../userStore'

// Mock fetch
global.fetch = vi.fn()

describe('userStore', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    userStore.setUser(null)
  })

  it('initializes with null user', () => {
    expect(userStore.user()).toBeNull()
    expect(userStore.isAuthenticated()).toBe(false)
  })

  it('logs in successfully', async () => {
    const mockUser = { id: '1', name: 'John', email: 'john@example.com', role: 'user' }
    const mockResponse = {
      ok: true,
      json: async () => ({ user: mockUser, token: 'fake-token' })
    }

    fetch.mockResolvedValueOnce(mockResponse)

    await userStore.login('john@example.com', 'password')

    expect(userStore.user()).toEqual(mockUser)
    expect(userStore.isAuthenticated()).toBe(true)
    expect(localStorage.getItem('token')).toBe('fake-token')
  })

  it('handles login failure', async () => {
    const mockResponse = {
      ok: false,
      status: 401
    }

    fetch.mockResolvedValueOnce(mockResponse)

    await userStore.login('wrong@example.com', 'wrong-password')

    expect(userStore.user()).toBeNull()
    expect(userStore.error()).toBeTruthy()
    expect(userStore.isAuthenticated()).toBe(false)
  })

  it('logs out successfully', () => {
    const mockUser = { id: '1', name: 'John', email: 'john@example.com', role: 'user' }
    userStore.setUser(mockUser)
    localStorage.setItem('token', 'fake-token')

    userStore.logout()

    expect(userStore.user()).toBeNull()
    expect(userStore.isAuthenticated()).toBe(false)
    expect(localStorage.getItem('token')).toBeNull()
  })
})
```

### Integration Testing

```typescript
// src/__tests__/App.test.tsx
import { render, screen, fireEvent, waitFor } from '@solidjs/testing-library'
import { Router } from '@solidjs/router'
import { describe, it, expect, vi } from 'vitest'
import App from '../App'

const renderWithRouter = (component) => {
  return render(() => (
    <Router>
      {component}
    </Router>
  ))
}

describe('App Integration', () => {
  it('navigates between pages', async () => {
    renderWithRouter(<App />)

    // Check initial page
    expect(screen.getByText('Home')).toBeInTheDocument()

    // Navigate to about page
    fireEvent.click(screen.getByText('About'))
    await waitFor(() => {
      expect(screen.getByText('About Us')).toBeInTheDocument()
    })
  })

  it('handles user authentication flow', async () => {
    const mockUser = { id: '1', name: 'John', email: 'john@example.com' }

    global.fetch = vi.fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ user: mockUser, token: 'fake-token' })
      })

    renderWithRouter(<App />)

    // Click login button
    fireEvent.click(screen.getByText('Login'))

    // Fill login form
    fireEvent.input(screen.getByLabelText('Email'), { target: { value: 'john@example.com' } })
    fireEvent.input(screen.getByLabelText('Password'), { target: { value: 'password' } })
    fireEvent.click(screen.getByText('Sign In'))

    // Wait for successful login
    await waitFor(() => {
      expect(screen.getByText('Welcome, John!')).toBeInTheDocument()
    })
  })
})
```

### End-to-End Testing

```typescript
// e2e/auth.test.ts
import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test('user can log in successfully', async ({ page }) => {
    await page.goto('/')

    // Click login button
    await page.click('text=Login')

    // Fill login form
    await page.fill('[placeholder="Email"]', 'user@example.com')
    await page.fill('[placeholder="Password"]', 'password123')
    await page.click('button[type="submit"]')

    // Wait for successful login
    await expect(page.locator('text=Welcome')).toBeVisible()
    await expect(page.locator('text=Logout')).toBeVisible()
  })

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/')

    await page.click('text=Login')
    await page.fill('[placeholder="Email"]', 'wrong@example.com')
    await page.fill('[placeholder="Password"]', 'wrongpassword')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=Invalid credentials')).toBeVisible()
  })

  test('user can log out', async ({ page }) => {
    // Assume user is already logged in
    await page.goto('/')
    await page.click('text=Logout')

    await expect(page.locator('text=Login')).toBeVisible()
    await expect(page.locator('text=Welcome')).not.toBeVisible()
  })
})

test.describe('Todo Application', () => {
  test('can add and complete todos', async ({ page }) => {
    await page.goto('/todos')

    // Add new todo
    await page.fill('[placeholder="Add new todo"]', 'Buy groceries')
    await page.press('[placeholder="Add new todo"]', 'Enter')

    // Verify todo was added
    await expect(page.locator('text=Buy groceries')).toBeVisible()

    // Complete todo
    await page.click('input[type="checkbox"]')

    // Verify todo is marked as completed
    await expect(page.locator('.todo-item.completed')).toBeVisible()
  })

  test('can edit todos', async ({ page }) => {
    await page.goto('/todos')

    // Add todo
    await page.fill('[placeholder="Add new todo"]', 'Original task')
    await page.press('[placeholder="Add new todo"]', 'Enter')

    // Double-click to edit
    await page.dblclick('text=Original task')

    // Edit todo
    await page.fill('.todo-edit input', 'Updated task')
    await page.press('.todo-edit input', 'Enter')

    // Verify todo was updated
    await expect(page.locator('text=Updated task')).toBeVisible()
    await expect(page.locator('text=Original task')).not.toBeVisible()
  })
})
```

## Deployment Guide

### Build Configuration

```typescript
// vite.config.ts - Production optimization
import { defineConfig } from 'vite'
import solid from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solid()],
  build: {
    target: 'esnext',
    minify: 'terser',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['solid-js'],
          router: ['@solidjs/router'],
        },
      },
    },
  },
  define: {
    __DEV__: false,
  },
})

// package.json scripts
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "lint": "eslint src --ext .ts,.tsx",
    "lint:fix": "eslint src --ext .ts,.tsx --fix",
    "type-check": "tsc --noEmit"
  }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --only=production

# Build the app
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# Production image
FROM nginx:alpine AS runner
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy static assets from builder stage
COPY --from=builder /app/dist .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/css
        text/javascript
        text/plain
        text/xml
        application/javascript
        application/xml+rss
        application/json;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle client-side routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run type check
        run: npm run type-check

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm run test

      - name: Run coverage
        run: npm run test:coverage

  build:
    needs: test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: dist
          path: dist/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: dist
          path: dist/

      - name: Deploy to production
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

### Performance Monitoring

```typescript
// src/utils/performance.ts
export function measurePerformance() {
  // Core Web Vitals
  function getCLS(onPerfEntry) {
    import('web-vitals').then(({ getCLS }) => {
      getCLS(onPerfEntry)
    })
  }

  function getFID(onPerfEntry) {
    import('web-vitals').then(({ getFID }) => {
      getFID(onPerfEntry)
    })
  }

  function getFCP(onPerfEntry) {
    import('web-vitals').then(({ getFCP }) => {
      getFCP(onPerfEntry)
    })
  }

  function getLCP(onPerfEntry) {
    import('web-vitals').then(({ getLCP }) => {
      getLCP(onPerfEntry)
    })
  }

  function getTTFB(onPerfEntry) {
    import('web-vitals').then(({ getTTFB }) => {
      getTTFB(onPerfEntry)
    })
  }

  const logMetric = (metric) => {
    console.log(metric)

    // Send to analytics
    if (typeof gtag !== 'undefined') {
      gtag('event', metric.name, {
        event_category: 'Web Vitals',
        value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
        event_label: metric.id,
        non_interaction: true,
      })
    }
  }

  getCLS(logMetric)
  getFID(logMetric)
  getFCP(logMetric)
  getLCP(logMetric)
  getTTFB(logMetric)
}

// Initialize performance monitoring
if (typeof window !== 'undefined') {
  measurePerformance()
}
```

## Common Pitfalls

### Reactivity Pitfalls

```typescript
// WRONG: Destructuring reactive values
function BadComponent(props) {
  const { name, email } = props.user // Loses reactivity!

  return (
    <div>
      <p>{name}</p> {/* Won't update when props.user changes */}
      <p>{email}</p>
    </div>
  )
}

// RIGHT: Keep reactive references
function GoodComponent(props) {
  return (
    <div>
      <p>{props.user.name}</p> {/* Reactive */}
      <p>{props.user.email}</p>
    </div>
  )
}

// WRONG: Using signals incorrectly
function BadCounter() {
  const [count, setCount] = createSignal(0)

  // Wrong: reading signal value in closure
  const increment = () => {
    setTimeout(() => {
      setCount(count() + 1) // May use stale value
    }, 1000)
  }

  return <button onClick={increment}>Count: {count()}</button>
}

// RIGHT: Using functional updates
function GoodCounter() {
  const [count, setCount] = createSignal(0)

  const increment = () => {
    setTimeout(() => {
      setCount(prev => prev + 1) // Always uses current value
    }, 1000)
  }

  return <button onClick={increment}>Count: {count()}</button>
}
```

### Memory Leaks

```typescript
// WRONG: Not cleaning up subscriptions
function BadWebSocketComponent() {
  const [messages, setMessages] = createSignal([])

  createEffect(() => {
    const ws = new WebSocket('ws://localhost:8080')
    ws.onmessage = (event) => {
      setMessages(prev => [...prev, event.data])
    }
    // Missing cleanup!
  })

  return <div>{/* render messages */}</div>
}

// RIGHT: Proper cleanup
function GoodWebSocketComponent() {
  const [messages, setMessages] = createSignal([])

  createEffect(() => {
    const ws = new WebSocket('ws://localhost:8080')
    ws.onmessage = (event) => {
      setMessages(prev => [...prev, event.data])
    }

    onCleanup(() => {
      ws.close()
    })
  })

  return <div>{/* render messages */}</div>
}

// WRONG: Creating new objects in render
function BadList(props) {
  return (
    <For each={props.items}>
      {(item) => (
        <div
          onClick={() => props.onSelect({ id: item.id, name: item.name })} // New object each render!
        >
          {item.name}
        </div>
      )}
    </For>
  )
}

// RIGHT: Stable references
function GoodList(props) {
  const handleSelect = (item) => () => {
    props.onSelect(item)
  }

  return (
    <For each={props.items}>
      {(item) => (
        <div onClick={handleSelect(item)}>
          {item.name}
        </div>
      )}
    </For>
  )
}
```

### Performance Anti-patterns

```typescript
// WRONG: Expensive operations in render
function BadComponent(props) {
  const processedData = props.data.map(item => ({
    ...item,
    processed: heavyComputation(item) // Runs on every render!
  }))

  return <div>{/* render processed data */}</div>
}

// RIGHT: Memoize expensive operations
function GoodComponent(props) {
  const processedData = createMemo(() =>
    props.data.map(item => ({
      ...item,
      processed: heavyComputation(item)
    }))
  )

  return <div>{/* render processed data */}</div>
}

// WRONG: Accessing signals multiple times
function BadCounter() {
  const [count, setCount] = createSignal(0)

  return (
    <div>
      <p>Count: {count()}</p>
      <p>Double: {count() * 2}</p> {/* count() called again */}
      <p>Triple: {count() * 3}</p> {/* count() called again */}
    </div>
  )
}

// RIGHT: Access signal once with memos
function GoodCounter() {
  const [count, setCount] = createSignal(0)
  const double = createMemo(() => count() * 2)
  const triple = createMemo(() => count() * 3)

  return (
    <div>
      <p>Count: {count()}</p>
      <p>Double: {double()}</p>
      <p>Triple: {triple()}</p>
    </div>
  )
}
```

## Troubleshooting

### Common Issues and Solutions

```typescript
// Issue: Hydration mismatches in SSR
// Solution: Use isServer check
import { isServer } from 'solid-js/web'

function ClientOnlyComponent() {
  return (
    <div>
      {!isServer && (
        <div>This only renders on the client</div>
      )}
    </div>
  )
}

// Issue: Effects not running as expected
// Solution: Check dependencies
function DebugEffect(props) {
  createEffect(() => {
    console.log('Effect running with:', props.value)
    // Make sure you're accessing the reactive value
  })
}

// Issue: Components not updating
// Solution: Verify reactivity chain
function ReactiveDebug(props) {
  // Create a memo to track what's reactive
  const debugValue = createMemo(() => {
    console.log('Memo recalculating with:', props.data)
    return props.data
  })

  return <div>{debugValue()}</div>
}

// Development debugging utilities
export function debugReactivity() {
  if (import.meta.env.DEV) {
    // Track all signal reads and writes
    const originalCreateSignal = createSignal

    window.createSignal = function(value, options) {
      const [getter, setter] = originalCreateSignal(value, options)

      return [
        () => {
          console.log('Reading signal:', value)
          return getter()
        },
        (newValue) => {
          console.log('Writing signal:', value, '->', newValue)
          return setter(newValue)
        }
      ]
    }
  }
}
```

### Error Boundaries

```typescript
// src/components/ErrorBoundary.tsx
import { Component, JSX, ErrorBoundary as SolidErrorBoundary } from 'solid-js'

interface ErrorBoundaryProps {
  fallback?: (error: Error, reset: () => void) => JSX.Element
  children: JSX.Element
}

export const ErrorBoundary: Component<ErrorBoundaryProps> = (props) => {
  const defaultFallback = (error: Error, reset: () => void) => (
    <div class="error-boundary">
      <h2>Something went wrong!</h2>
      <details style="white-space: pre-wrap">
        <summary>Error details</summary>
        {error.message}
        {import.meta.env.DEV && (
          <pre>{error.stack}</pre>
        )}
      </details>
      <button onClick={reset}>Try again</button>
    </div>
  )

  return (
    <SolidErrorBoundary fallback={props.fallback || defaultFallback}>
      {props.children}
    </SolidErrorBoundary>
  )
}

// Usage
function App() {
  return (
    <ErrorBoundary>
      <Router>
        <Routes>
          <Route path="/" component={Home} />
          <Route path="/about" component={About} />
        </Routes>
      </Router>
    </ErrorBoundary>
  )
}
```

## Best Practices Summary

### Development Guidelines

1. **Embrace Fine-grained Reactivity**
   - Use signals for state that changes
   - Use memos for derived state
   - Use effects for side effects only
   - Keep reactive chains simple and predictable

2. **Component Design**
   - Keep components small and focused
   - Use TypeScript for better type safety
   - Leverage props destructuring carefully
   - Implement proper error boundaries

3. **Performance**
   - Use Index instead of For when appropriate
   - Memoize expensive computations
   - Implement lazy loading for routes
   - Optimize bundle size with tree shaking

4. **State Management**
   - Use signals for local state
   - Create stores for global state
   - Implement proper cleanup in effects
   - Avoid unnecessary state lifting

5. **Testing**
   - Write unit tests for components and utilities
   - Use integration tests for user workflows
   - Implement proper mocking strategies
   - Test accessibility and keyboard navigation

### Code Quality Standards

```typescript
// Example of well-structured Solid component
interface TodoItemProps {
  todo: Todo
  onToggle: (id: string) => void
  onDelete: (id: string) => void
  onUpdate: (id: string, text: string) => void
}

const TodoItem: Component<TodoItemProps> = (props) => {
  const [isEditing, setIsEditing] = createSignal(false)
  const [editText, setEditText] = createSignal('')

  // Derived state
  const isCompleted = createMemo(() => props.todo.completed)

  // Event handlers
  const handleEdit = () => {
    setEditText(props.todo.text)
    setIsEditing(true)
  }

  const handleSave = () => {
    const text = editText().trim()
    if (text && text !== props.todo.text) {
      props.onUpdate(props.todo.id, text)
    }
    setIsEditing(false)
  }

  const handleCancel = () => {
    setEditText('')
    setIsEditing(false)
  }

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Enter') handleSave()
    if (e.key === 'Escape') handleCancel()
  }

  return (
    <div class={`todo-item ${isCompleted() ? 'completed' : ''}`}>
      <Show
        when={isEditing()}
        fallback={
          <TodoDisplay
            todo={props.todo}
            onToggle={() => props.onToggle(props.todo.id)}
            onDelete={() => props.onDelete(props.todo.id)}
            onEdit={handleEdit}
          />
        }
      >
        <TodoEdit
          text={editText()}
          onTextChange={setEditText}
          onSave={handleSave}
          onCancel={handleCancel}
          onKeyDown={handleKeyDown}
        />
      </Show>
    </div>
  )
}
```

## Conclusion

Solid.js represents a significant advancement in reactive frontend frameworks, offering the performance benefits of fine-grained reactivity while maintaining a familiar developer experience. Its compiler-based approach eliminates the virtual DOM overhead while providing true reactivity that updates only what actually changes.

The framework's strength lies in its simplicity and performance. By compiling away to efficient vanilla JavaScript, Solid.js provides exceptional runtime performance with minimal bundle sizes. The reactive primitives (signals, memos, and effects) offer a powerful and predictable way to manage application state and side effects.

However, Solid.js requires developers to understand its reactive model, which differs from React's re-rendering approach. The smaller ecosystem means fewer third-party libraries and resources, though the framework's React-like syntax provides a relatively smooth migration path for React developers.

Solid.js is particularly well-suited for performance-critical applications, mobile web apps, and projects where bundle size matters. Its fine-grained reactivity makes it excellent for real-time applications and complex state management scenarios.

The framework continues to evolve with strong community growth and increasing adoption. Its focus on performance, developer experience, and modern JavaScript practices positions it well for the future of web development, especially as performance becomes increasingly important for user experience and SEO.

Success with Solid.js comes from embracing its reactive model, understanding the differences from traditional frameworks, and leveraging its compilation benefits for optimal performance.

## Resources

### Official Documentation
- [Solid.js Official Website](https://www.solidjs.com/)
- [Solid.js Documentation](https://docs.solidjs.com/)
- [Solid.js GitHub Repository](https://github.com/solidjs/solid)
- [Solid.js Tutorial](https://www.solidjs.com/tutorial)

### Learning Resources
- [Solid.js Playground](https://playground.solidjs.com/)
- [Solid.js Examples](https://github.com/solidjs/solid/tree/main/packages/solid/examples)
- [Solid.js Video Tutorials](https://www.youtube.com/c/RyanCarniato)
- [Solid.js Blog](https://dev.to/t/solidjs)

### Tools and Ecosystem
- [Solid Router](https://github.com/solidjs/solid-router)
- [Solid Meta](https://github.com/solidjs/solid-meta)
- [Solid Testing Library](https://github.com/solidjs/solid-testing-library)
- [Vite Plugin Solid](https://github.com/solidjs/vite-plugin-solid)
- [Solid DevTools](https://github.com/thetarnav/solid-devtools)

### Community
- [Solid.js Discord](https://discord.com/invite/solidjs)
- [Solid.js Reddit](https://www.reddit.com/r/solidjs/)
- [Solid.js Twitter](https://twitter.com/solid_js)
- [Solid.js Stack Overflow](https://stackoverflow.com/questions/tagged/solid.js)

### Deployment and Hosting
- [Netlify](https://www.netlify.com/)
- [Vercel](https://vercel.com/)
- [Cloudflare Pages](https://pages.cloudflare.com/)
- [GitHub Pages](https://pages.github.com/)

### Performance Tools
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [Web Vitals](https://web.dev/vitals/)
- [Bundle Analyzer](https://www.npmjs.com/package/webpack-bundle-analyzer)
- [Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools)