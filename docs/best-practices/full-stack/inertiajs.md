# Inertia.js Best Practices

## Overview

Inertia.js is a modern full-stack framework that allows you to build single-page applications (SPAs) using classic server-side routing and controllers. It acts as a bridge between server-side frameworks and client-side frameworks, enabling you to create dynamic applications without the complexity of building a separate API. Inertia.js eliminates the need for separate frontend and backend applications by allowing server-side rendered pages to behave like SPAs.

## Pros & Cons

### Pros
- **Familiar Development Model**: Uses traditional server-side routing and controllers
- **No API Required**: Eliminates the need to build and maintain a separate API
- **SPA Experience**: Provides smooth page transitions without full page reloads
- **Framework Agnostic**: Works with multiple backend frameworks (Laravel, Rails, Django)
- **SEO Friendly**: Server-side rendering with SPA benefits
- **Simplified Authentication**: Uses traditional session-based authentication
- **Reduced Complexity**: Single codebase with unified routing and data flow
- **Progressive Enhancement**: Can be added incrementally to existing applications

### Cons
- **Learning Curve**: Requires understanding of both server and client concepts
- **Framework Lock-in**: Tightly coupled to supported backend frameworks
- **Limited Real-time Features**: Not ideal for applications requiring WebSockets
- **Mobile App Limitations**: Not suitable for native mobile applications
- **Caching Complexity**: Browser caching strategies require careful consideration
- **Debugging Challenges**: Debugging across server-client boundary can be complex
- **Limited Community**: Smaller ecosystem compared to traditional SPAs

## When to Use

Inertia.js is ideal for:
- Traditional web applications that need SPA-like behavior
- Teams with strong backend framework expertise
- Applications where API complexity is not justified
- Projects requiring SEO optimization with dynamic content
- Rapid application development with familiar patterns
- Applications with moderate interactivity requirements
- Teams wanting to avoid API versioning and maintenance overhead

Avoid Inertia.js for:
- Mobile-first applications requiring native functionality
- Applications with complex real-time requirements
- Projects with multiple client applications (web, mobile, desktop)
- Teams primarily focused on frontend technologies
- Applications requiring extensive offline functionality
- Microservices architectures with independent services

## Core Concepts

### Request Lifecycle

```javascript
// Client-side request initiation
import { router } from '@inertiajs/vue3'

// Standard navigation
router.visit('/users')

// Form submission
router.post('/users', {
  name: 'John Doe',
  email: 'john@example.com'
})

// Advanced options
router.visit('/dashboard', {
  method: 'get',
  data: { filter: 'active' },
  headers: { 'X-Custom-Header': 'value' },
  preserveScroll: true,
  preserveState: true,
  onSuccess: (page) => {
    console.log('Navigation successful', page)
  }
})
```

### Server-Side Controllers

```php
// Laravel Controller Example
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User;

class UserController extends Controller
{
    public function index(Request $request)
    {
        return Inertia::render('Users/Index', [
            'users' => User::query()
                ->when($request->search, function ($query, $search) {
                    $query->where('name', 'like', "%{$search}%");
                })
                ->paginate(10)
                ->withQueryString(),
            'filters' => $request->only(['search']),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
        ]);

        User::create($validated);

        return redirect()->route('users.index')
            ->with('success', 'User created successfully.');
    }

    public function show(User $user)
    {
        return Inertia::render('Users/Show', [
            'user' => $user->load('posts', 'profile'),
        ]);
    }

    public function update(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
        ]);

        $user->update($validated);

        return back()->with('success', 'User updated successfully.');
    }
}
```

### Vue.js Frontend Components

```vue
<!-- Users/Index.vue -->
<template>
  <AppLayout title="Users">
    <div class="py-12">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <!-- Search and Filters -->
        <div class="mb-6">
          <input
            v-model="form.search"
            type="text"
            placeholder="Search users..."
            class="form-input"
            @input="search"
          />
        </div>

        <!-- Users Table -->
        <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="user in users.data" :key="user.id">
                <td class="px-6 py-4 whitespace-nowrap">
                  <Link :href="route('users.show', user)" class="text-blue-600 hover:text-blue-900">
                    {{ user.name }}
                  </Link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {{ user.email }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <Link
                    :href="route('users.edit', user)"
                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                  >
                    Edit
                  </Link>
                  <button
                    @click="deleteUser(user)"
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>

          <!-- Pagination -->
          <Pagination :links="users.links" />
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { router, Link } from '@inertiajs/vue3'
import { debounce } from 'lodash'
import AppLayout from '@/Layouts/AppLayout.vue'
import Pagination from '@/Components/Pagination.vue'

// Props from server
const props = defineProps({
  users: Object,
  filters: Object,
})

// Reactive form data
const form = reactive({
  search: props.filters.search || '',
})

// Debounced search function
const search = debounce(() => {
  router.get(route('users.index'), form, {
    preserveState: true,
    preserveScroll: true,
  })
}, 300)

// Delete user with confirmation
const deleteUser = (user) => {
  if (confirm(`Are you sure you want to delete ${user.name}?`)) {
    router.delete(route('users.destroy', user), {
      onSuccess: () => {
        // Handle success (optional, flash message will be shown automatically)
      },
      onError: (errors) => {
        console.error('Delete failed:', errors)
      }
    })
  }
}
</script>
```

### Form Handling

```vue
<!-- Users/Create.vue -->
<template>
  <AppLayout title="Create User">
    <div class="py-12">
      <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
        <div class="bg-white overflow-hidden shadow-xl sm:rounded-lg p-6">
          <form @submit.prevent="submit">
            <!-- Name Field -->
            <div class="mb-4">
              <label for="name" class="block text-sm font-medium text-gray-700">
                Name
              </label>
              <input
                id="name"
                v-model="form.name"
                type="text"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                :class="{ 'border-red-500': form.errors.name }"
                required
              />
              <div v-if="form.errors.name" class="mt-1 text-sm text-red-600">
                {{ form.errors.name }}
              </div>
            </div>

            <!-- Email Field -->
            <div class="mb-4">
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email
              </label>
              <input
                id="email"
                v-model="form.email"
                type="email"
                class="mt-1 block w-full rounded-md border-gray-300 shadow-sm"
                :class="{ 'border-red-500': form.errors.email }"
                required
              />
              <div v-if="form.errors.email" class="mt-1 text-sm text-red-600">
                {{ form.errors.email }}
              </div>
            </div>

            <!-- Submit Button -->
            <div class="flex items-center justify-end mt-6">
              <Link
                :href="route('users.index')"
                class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded mr-2"
              >
                Cancel
              </Link>
              <button
                type="submit"
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                :disabled="form.processing"
              >
                <span v-if="form.processing">Creating...</span>
                <span v-else>Create User</span>
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup>
import { useForm, Link } from '@inertiajs/vue3'
import AppLayout from '@/Layouts/AppLayout.vue'

// Create form with validation
const form = useForm({
  name: '',
  email: '',
})

// Submit form
const submit = () => {
  form.post(route('users.store'), {
    onSuccess: () => {
      // Redirect will happen automatically
      // Flash message will be shown from server
    },
    onError: (errors) => {
      // Validation errors are automatically handled by useForm
      console.log('Validation errors:', errors)
    }
  })
}
</script>
```

## Installation & Setup

### Backend Setup (Laravel)

```bash
# Install Inertia.js server-side adapter
composer require inertiajs/inertia-laravel

# Publish Inertia middleware
php artisan inertia:middleware

# Add middleware to app/Http/Kernel.php
```

```php
// app/Http/Kernel.php
protected $middlewareGroups = [
    'web' => [
        // ... existing middleware
        \App\Http\Middleware\HandleInertiaRequests::class,
    ],
];

// app/Http/Middleware/HandleInertiaRequests.php
<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): string|null
    {
        return parent::version($request);
    }

    public function share(Request $request): array
    {
        return array_merge(parent::share($request), [
            'auth' => [
                'user' => $request->user() ? [
                    'id' => $request->user()->id,
                    'name' => $request->user()->name,
                    'email' => $request->user()->email,
                ] : null,
            ],
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'errors' => function () use ($request) {
                return $request->session()->get('errors')
                    ? $request->session()->get('errors')->getBag('default')->getMessages()
                    : (object) [];
            },
        ]);
    }
}
```

### Frontend Setup (Vue.js)

```bash
# Install frontend dependencies
npm install @inertiajs/vue3 @vitejs/plugin-vue vue@next

# Install additional utilities
npm install axios lodash
```

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import laravel from 'laravel-vite-plugin'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    laravel({
      input: ['resources/css/app.css', 'resources/js/app.js'],
      refresh: true,
    }),
    vue({
      template: {
        transformAssetUrls: {
          base: null,
          includeAbsolute: false,
        },
      },
    }),
  ],
  resolve: {
    alias: {
      '@': '/resources/js',
    },
  },
})
```

```javascript
// resources/js/app.js
import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'
import { ZiggyVue } from '../../vendor/tightenco/ziggy/dist/vue.m'

const appName = window.document.getElementsByTagName('title')[0]?.innerText || 'Laravel'

createInertiaApp({
  title: (title) => `${title} - ${appName}`,
  resolve: (name) => resolvePageComponent(`./Pages/${name}.vue`, import.meta.glob('./Pages/**/*.vue')),
  setup({ el, App, props, plugin }) {
    return createApp({ render: () => h(App, props) })
      .use(plugin)
      .use(ZiggyVue, Ziggy)
      .mount(el)
  },
  progress: {
    color: '#4B5563',
  },
})
```

### Root Template

```html
<!-- resources/views/app.blade.php -->
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="csrf-token" content="{{ csrf_token() }}">

  <title inertia>{{ config('app.name', 'Laravel') }}</title>

  <!-- Scripts -->
  @routes
  @vite(['resources/css/app.css', 'resources/js/app.js'])
  @inertiaHead
</head>
<body class="font-sans antialiased">
  @inertia
</body>
</html>
```

## Project Structure

### Recommended Directory Structure

```
resources/
├── js/
│   ├── Components/
│   │   ├── Common/
│   │   │   ├── Button.vue
│   │   │   ├── Modal.vue
│   │   │   └── Pagination.vue
│   │   ├── Forms/
│   │   │   ├── Input.vue
│   │   │   ├── Select.vue
│   │   │   └── TextArea.vue
│   │   └── Navigation/
│   │       ├── NavBar.vue
│   │       └── SideBar.vue
│   ├── Layouts/
│   │   ├── AppLayout.vue
│   │   ├── AuthLayout.vue
│   │   └── GuestLayout.vue
│   ├── Pages/
│   │   ├── Auth/
│   │   │   ├── Login.vue
│   │   │   └── Register.vue
│   │   ├── Dashboard/
│   │   │   └── Index.vue
│   │   ├── Users/
│   │   │   ├── Index.vue
│   │   │   ├── Show.vue
│   │   │   ├── Create.vue
│   │   │   └── Edit.vue
│   │   └── Welcome.vue
│   ├── Stores/
│   │   ├── auth.js
│   │   └── notifications.js
│   ├── Utils/
│   │   ├── api.js
│   │   ├── helpers.js
│   │   └── validation.js
│   └── app.js
└── views/
    └── app.blade.php
```

### Component Organization

```vue
<!-- Components/Common/Modal.vue -->
<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div v-if="show" class="fixed inset-0 z-50 overflow-y-auto">
        <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
          <!-- Background overlay -->
          <div
            class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75"
            @click="close"
          ></div>

          <!-- Modal content -->
          <div
            class="inline-block w-full max-w-md p-6 my-8 overflow-hidden text-left align-middle transition-all transform bg-white shadow-xl rounded-lg"
          >
            <!-- Header -->
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900">
                {{ title }}
              </h3>
              <button
                @click="close"
                class="text-gray-400 hover:text-gray-600"
              >
                <span class="sr-only">Close</span>
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <!-- Content -->
            <div class="mb-4">
              <slot></slot>
            </div>

            <!-- Footer -->
            <div class="flex justify-end space-x-2">
              <slot name="footer">
                <button
                  @click="close"
                  class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300"
                >
                  Cancel
                </button>
              </slot>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { watch } from 'vue'

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: '',
  },
  closeable: {
    type: Boolean,
    default: true,
  },
})

const emit = defineEmits(['close'])

const close = () => {
  if (props.closeable) {
    emit('close')
  }
}

// Handle escape key
watch(() => props.show, (show) => {
  if (show) {
    document.addEventListener('keydown', handleEscape)
  } else {
    document.removeEventListener('keydown', handleEscape)
  }
})

const handleEscape = (e) => {
  if (e.key === 'Escape') {
    close()
  }
}
</script>
```

### Layout Components

```vue
<!-- Layouts/AppLayout.vue -->
<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Navigation -->
    <nav class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <!-- Logo -->
            <div class="flex-shrink-0 flex items-center">
              <Link :href="route('dashboard')" class="text-xl font-bold text-gray-800">
                {{ $page.props.app.name }}
              </Link>
            </div>

            <!-- Navigation Links -->
            <div class="hidden space-x-8 sm:-my-px sm:ml-10 sm:flex">
              <NavLink :href="route('dashboard')" :active="route().current('dashboard')">
                Dashboard
              </NavLink>
              <NavLink :href="route('users.index')" :active="route().current('users.*')">
                Users
              </NavLink>
            </div>
          </div>

          <!-- User Menu -->
          <div class="hidden sm:flex sm:items-center sm:ml-6">
            <Dropdown align="right" width="48">
              <template #trigger>
                <button class="flex items-center text-sm font-medium text-gray-500 hover:text-gray-700">
                  <div>{{ $page.props.auth.user.name }}</div>
                  <svg class="ml-1 -mr-0.5 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
                  </svg>
                </button>
              </template>

              <template #content>
                <DropdownLink :href="route('profile.show')">
                  Profile
                </DropdownLink>
                <DropdownLink :href="route('logout')" method="post" as="button">
                  Log Out
                </DropdownLink>
              </template>
            </Dropdown>
          </div>
        </div>
      </div>
    </nav>

    <!-- Page Header -->
    <header v-if="$slots.header" class="bg-white shadow">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <slot name="header" />
      </div>
    </header>

    <!-- Flash Messages -->
    <FlashMessages />

    <!-- Page Content -->
    <main>
      <slot />
    </main>
  </div>
</template>

<script setup>
import { Link } from '@inertiajs/vue3'
import NavLink from '@/Components/NavLink.vue'
import Dropdown from '@/Components/Dropdown.vue'
import DropdownLink from '@/Components/DropdownLink.vue'
import FlashMessages from '@/Components/FlashMessages.vue'

defineProps({
  title: String,
})
</script>
```

## Development Patterns

### State Management

```javascript
// stores/auth.js
import { reactive } from 'vue'

export const authStore = reactive({
  user: null,
  permissions: [],

  setUser(user) {
    this.user = user
  },

  setPermissions(permissions) {
    this.permissions = permissions
  },

  hasPermission(permission) {
    return this.permissions.includes(permission)
  },

  can(permission) {
    return this.hasPermission(permission)
  },

  logout() {
    this.user = null
    this.permissions = []
  }
})

// Usage in components
import { authStore } from '@/stores/auth'

export default {
  setup() {
    return {
      auth: authStore
    }
  }
}
```

### Form Validation Patterns

```vue
<!-- Advanced form with custom validation -->
<template>
  <form @submit.prevent="submit">
    <FormField
      label="Email"
      :error="form.errors.email"
      required
    >
      <input
        v-model="form.email"
        type="email"
        class="form-input"
        :class="{ 'error': form.errors.email }"
        @blur="validateEmail"
      />
    </FormField>

    <FormField
      label="Password"
      :error="form.errors.password"
      required
    >
      <input
        v-model="form.password"
        type="password"
        class="form-input"
        :class="{ 'error': form.errors.password }"
        @blur="validatePassword"
      />
    </FormField>

    <FormField
      label="Confirm Password"
      :error="form.errors.password_confirmation"
      required
    >
      <input
        v-model="form.password_confirmation"
        type="password"
        class="form-input"
        :class="{ 'error': form.errors.password_confirmation }"
        @blur="validatePasswordConfirmation"
      />
    </FormField>

    <button
      type="submit"
      :disabled="form.processing || !isFormValid"
      class="btn btn-primary"
    >
      <span v-if="form.processing">Creating Account...</span>
      <span v-else>Create Account</span>
    </button>
  </form>
</template>

<script setup>
import { computed } from 'vue'
import { useForm } from '@inertiajs/vue3'
import FormField from '@/Components/FormField.vue'

const form = useForm({
  email: '',
  password: '',
  password_confirmation: '',
})

const isFormValid = computed(() => {
  return form.email &&
         form.password &&
         form.password_confirmation &&
         form.password === form.password_confirmation &&
         !Object.keys(form.errors).length
})

const validateEmail = () => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!form.email) {
    form.setError('email', 'Email is required')
  } else if (!emailRegex.test(form.email)) {
    form.setError('email', 'Please enter a valid email address')
  } else {
    form.clearErrors('email')
  }
}

const validatePassword = () => {
  if (!form.password) {
    form.setError('password', 'Password is required')
  } else if (form.password.length < 8) {
    form.setError('password', 'Password must be at least 8 characters')
  } else {
    form.clearErrors('password')
  }
}

const validatePasswordConfirmation = () => {
  if (!form.password_confirmation) {
    form.setError('password_confirmation', 'Password confirmation is required')
  } else if (form.password !== form.password_confirmation) {
    form.setError('password_confirmation', 'Passwords do not match')
  } else {
    form.clearErrors('password_confirmation')
  }
}

const submit = () => {
  // Validate all fields before submission
  validateEmail()
  validatePassword()
  validatePasswordConfirmation()

  if (isFormValid.value) {
    form.post(route('register'))
  }
}
</script>
```

### Data Fetching Patterns

```vue
<!-- Advanced data fetching with caching -->
<template>
  <div>
    <div v-if="loading" class="text-center py-4">
      <Spinner />
    </div>

    <div v-else>
      <!-- Search and Filters -->
      <div class="mb-6 flex space-x-4">
        <input
          v-model="filters.search"
          type="text"
          placeholder="Search..."
          class="form-input"
          @input="debouncedSearch"
        />

        <select v-model="filters.status" @change="fetchData" class="form-select">
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>

        <select v-model="filters.sort" @change="fetchData" class="form-select">
          <option value="name">Sort by Name</option>
          <option value="email">Sort by Email</option>
          <option value="created_at">Sort by Date</option>
        </select>
      </div>

      <!-- Results -->
      <div v-if="data.length === 0" class="text-center py-8 text-gray-500">
        No results found
      </div>

      <div v-else class="grid gap-4">
        <div
          v-for="item in data"
          :key="item.id"
          class="bg-white p-4 rounded-lg shadow"
        >
          <!-- Item content -->
        </div>
      </div>

      <!-- Pagination -->
      <Pagination v-if="pagination" :links="pagination.links" />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { router } from '@inertiajs/vue3'
import { debounce } from 'lodash'

const props = defineProps({
  initialData: Array,
  initialPagination: Object,
  initialFilters: Object,
})

const loading = ref(false)
const data = ref(props.initialData || [])
const pagination = ref(props.initialPagination || null)

const filters = reactive({
  search: props.initialFilters?.search || '',
  status: props.initialFilters?.status || '',
  sort: props.initialFilters?.sort || 'name',
})

// Cache for storing previous results
const cache = new Map()

const getCacheKey = (filters) => {
  return JSON.stringify(filters)
}

const fetchData = async () => {
  const cacheKey = getCacheKey(filters)

  // Check cache first
  if (cache.has(cacheKey)) {
    const cached = cache.get(cacheKey)
    data.value = cached.data
    pagination.value = cached.pagination
    return
  }

  loading.value = true

  try {
    await router.get(route('data.index'), filters, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: (page) => {
        data.value = page.props.data
        pagination.value = page.props.pagination

        // Cache the results
        cache.set(cacheKey, {
          data: page.props.data,
          pagination: page.props.pagination,
        })

        // Limit cache size
        if (cache.size > 10) {
          const firstKey = cache.keys().next().value
          cache.delete(firstKey)
        }
      },
      onFinish: () => {
        loading.value = false
      }
    })
  } catch (error) {
    console.error('Failed to fetch data:', error)
    loading.value = false
  }
}

const debouncedSearch = debounce(() => {
  fetchData()
}, 300)

onMounted(() => {
  // Initialize cache with initial data
  const cacheKey = getCacheKey(filters)
  cache.set(cacheKey, {
    data: data.value,
    pagination: pagination.value,
  })
})
</script>
```

### File Upload Patterns

```vue
<!-- File upload component -->
<template>
  <div class="file-upload">
    <div
      @drop.prevent="handleDrop"
      @dragover.prevent
      @dragenter.prevent
      class="upload-area"
      :class="{ 'drag-active': isDragActive }"
    >
      <input
        ref="fileInput"
        type="file"
        :multiple="multiple"
        :accept="accept"
        @change="handleFileSelect"
        class="hidden"
      />

      <div v-if="!files.length" class="upload-placeholder">
        <svg class="w-12 h-12 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
        </svg>
        <p class="text-gray-600 mb-2">
          Drag and drop files here, or
          <button @click="$refs.fileInput.click()" class="text-blue-600 hover:text-blue-800">
            browse
          </button>
        </p>
        <p class="text-sm text-gray-500">{{ acceptText }}</p>
      </div>

      <!-- File previews -->
      <div v-else class="file-list">
        <div
          v-for="(file, index) in files"
          :key="index"
          class="file-item"
        >
          <div class="file-info">
            <div class="file-name">{{ file.name }}</div>
            <div class="file-size">{{ formatFileSize(file.size) }}</div>
          </div>

          <!-- Upload progress -->
          <div v-if="file.uploading" class="upload-progress">
            <div class="progress-bar">
              <div
                class="progress-fill"
                :style="{ width: file.progress + '%' }"
              ></div>
            </div>
            <span class="progress-text">{{ file.progress }}%</span>
          </div>

          <!-- File actions -->
          <div class="file-actions">
            <button
              v-if="!file.uploading && !file.uploaded"
              @click="uploadFile(file, index)"
              class="btn btn-sm btn-primary"
            >
              Upload
            </button>
            <button
              @click="removeFile(index)"
              class="btn btn-sm btn-danger"
            >
              Remove
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Upload all button -->
    <div v-if="files.length && !allUploaded" class="mt-4 text-center">
      <button
        @click="uploadAll"
        :disabled="uploading"
        class="btn btn-primary"
      >
        <span v-if="uploading">Uploading...</span>
        <span v-else>Upload All ({{ remainingFiles.length }})</span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { router } from '@inertiajs/vue3'

const props = defineProps({
  multiple: {
    type: Boolean,
    default: false,
  },
  accept: {
    type: String,
    default: '*/*',
  },
  maxSize: {
    type: Number,
    default: 10 * 1024 * 1024, // 10MB
  },
  uploadUrl: {
    type: String,
    required: true,
  },
})

const emit = defineEmits(['uploaded', 'error'])

const fileInput = ref(null)
const files = ref([])
const isDragActive = ref(false)
const uploading = ref(false)

const remainingFiles = computed(() => {
  return files.value.filter(file => !file.uploaded && !file.uploading)
})

const allUploaded = computed(() => {
  return files.value.length > 0 && files.value.every(file => file.uploaded)
})

const acceptText = computed(() => {
  if (props.accept === '*/*') return 'Any file type'
  return `Accepted types: ${props.accept}`
})

const handleDrop = (e) => {
  isDragActive.value = false
  const droppedFiles = Array.from(e.dataTransfer.files)
  processFiles(droppedFiles)
}

const handleFileSelect = (e) => {
  const selectedFiles = Array.from(e.target.files)
  processFiles(selectedFiles)
}

const processFiles = (newFiles) => {
  const validFiles = newFiles.filter(file => {
    if (file.size > props.maxSize) {
      alert(`File ${file.name} is too large. Maximum size is ${formatFileSize(props.maxSize)}`)
      return false
    }
    return true
  })

  const processedFiles = validFiles.map(file => ({
    file,
    name: file.name,
    size: file.size,
    progress: 0,
    uploading: false,
    uploaded: false,
    error: null,
  }))

  if (props.multiple) {
    files.value.push(...processedFiles)
  } else {
    files.value = processedFiles
  }
}

const uploadFile = async (fileData, index) => {
  fileData.uploading = true
  fileData.error = null

  const formData = new FormData()
  formData.append('file', fileData.file)

  try {
    const response = await fetch(props.uploadUrl, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
      },
    })

    if (!response.ok) {
      throw new Error(`Upload failed: ${response.statusText}`)
    }

    const result = await response.json()

    fileData.uploaded = true
    fileData.uploading = false
    fileData.progress = 100

    emit('uploaded', {
      file: fileData,
      response: result,
    })

  } catch (error) {
    fileData.uploading = false
    fileData.error = error.message

    emit('error', {
      file: fileData,
      error: error.message,
    })
  }
}

const uploadAll = async () => {
  uploading.value = true

  for (const fileData of remainingFiles.value) {
    const index = files.value.indexOf(fileData)
    await uploadFile(fileData, index)
  }

  uploading.value = false
}

const removeFile = (index) => {
  files.value.splice(index, 1)
}

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}
</script>

<style scoped>
.upload-area {
  @apply border-2 border-dashed border-gray-300 rounded-lg p-8 text-center transition-colors;
}

.upload-area.drag-active {
  @apply border-blue-500 bg-blue-50;
}

.file-list {
  @apply space-y-4;
}

.file-item {
  @apply flex items-center justify-between p-4 bg-gray-50 rounded-lg;
}

.file-info {
  @apply flex-1;
}

.file-name {
  @apply font-medium text-gray-900;
}

.file-size {
  @apply text-sm text-gray-500;
}

.upload-progress {
  @apply flex items-center space-x-2;
}

.progress-bar {
  @apply w-32 h-2 bg-gray-200 rounded-full overflow-hidden;
}

.progress-fill {
  @apply h-full bg-blue-500 transition-all duration-300;
}

.progress-text {
  @apply text-sm text-gray-600;
}

.file-actions {
  @apply flex space-x-2;
}
</style>
```

## Security Best Practices

### CSRF Protection

```php
// Automatic CSRF protection in Laravel
// app/Http/Middleware/VerifyCsrfToken.php
protected $except = [
    // API routes that don't need CSRF protection
    'api/*',
];

// Inertia automatically includes CSRF token in requests
// Manual CSRF token inclusion if needed
```

```javascript
// Client-side CSRF handling
import { router } from '@inertiajs/vue3'

// CSRF token is automatically included in Inertia requests
router.post('/users', userData, {
  headers: {
    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
  }
})

// For manual fetch requests
const csrfToken = document.querySelector('meta[name="csrf-token"]').content

fetch('/api/data', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-TOKEN': csrfToken,
  },
  body: JSON.stringify(data)
})
```

### Input Validation and Sanitization

```php
// Server-side validation (Laravel)
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateUserRequest extends FormRequest
{
    public function authorize()
    {
        return $this->user()->can('create', User::class);
    }

    public function rules()
    {
        return [
            'name' => ['required', 'string', 'max:255', 'regex:/^[a-zA-Z\s]+$/'],
            'email' => ['required', 'string', 'email:rfc,dns', 'max:255', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed', Rules\Password::defaults()],
            'avatar' => ['nullable', 'image', 'mimes:jpeg,png,jpg', 'max:2048'],
            'role' => ['required', 'string', 'in:user,admin,moderator'],
        ];
    }

    public function messages()
    {
        return [
            'name.regex' => 'Name can only contain letters and spaces.',
            'email.email' => 'Please provide a valid email address.',
            'password.min' => 'Password must be at least 8 characters long.',
        ];
    }

    protected function prepareForValidation()
    {
        $this->merge([
            'name' => strip_tags($this->name),
            'email' => strtolower(trim($this->email)),
        ]);
    }
}

// Controller usage
public function store(CreateUserRequest $request)
{
    $validated = $request->validated();

    $user = User::create([
        'name' => $validated['name'],
        'email' => $validated['email'],
        'password' => Hash::make($validated['password']),
        'role' => $validated['role'],
    ]);

    if ($request->hasFile('avatar')) {
        $path = $request->file('avatar')->store('avatars', 'public');
        $user->update(['avatar' => $path]);
    }

    return redirect()->route('users.index')
        ->with('success', 'User created successfully.');
}
```

### XSS Prevention

```vue
<!-- Safe rendering practices in Vue -->
<template>
  <div>
    <!-- Safe: Automatic escaping -->
    <p>{{ userInput }}</p>

    <!-- Dangerous: Raw HTML rendering -->
    <!-- <p v-html="userInput"></p> // NEVER do this with user input -->

    <!-- Safe: Sanitized HTML rendering -->
    <p v-html="sanitizedContent"></p>

    <!-- Safe: Attribute binding -->
    <img :src="sanitizedImageUrl" :alt="userDescription">

    <!-- Safe: Class binding -->
    <div :class="sanitizedClassName">Content</div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import DOMPurify from 'dompurify'

const props = defineProps({
  userInput: String,
  userDescription: String,
  userHtml: String,
  imageUrl: String,
  className: String,
})

// Sanitize HTML content
const sanitizedContent = computed(() => {
  return DOMPurify.sanitize(props.userHtml, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
    ALLOWED_ATTR: ['href'],
    ALLOWED_URI_REGEXP: /^https?:\/\//,
  })
})

// Sanitize image URL
const sanitizedImageUrl = computed(() => {
  try {
    const url = new URL(props.imageUrl)
    return url.protocol === 'https:' || url.protocol === 'http:' ? url.href : '/default-avatar.png'
  } catch {
    return '/default-avatar.png'
  }
})

// Sanitize class name
const sanitizedClassName = computed(() => {
  return props.className?.replace(/[^a-zA-Z0-9-_\s]/g, '') || ''
})
</script>
```

### Authentication and Authorization

```php
// Authentication middleware
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class EnsureUserIsAuthenticated
{
    public function handle(Request $request, Closure $next)
    {
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        return $next($request);
    }
}

// Authorization policies
<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Post;

class PostPolicy
{
    public function viewAny(User $user)
    {
        return true;
    }

    public function view(User $user, Post $post)
    {
        return $post->published || $user->id === $post->user_id;
    }

    public function create(User $user)
    {
        return $user->hasRole('author');
    }

    public function update(User $user, Post $post)
    {
        return $user->id === $post->user_id || $user->hasRole('admin');
    }

    public function delete(User $user, Post $post)
    {
        return $user->id === $post->user_id || $user->hasRole('admin');
    }
}

// Controller with authorization
public function show(Post $post)
{
    $this->authorize('view', $post);

    return Inertia::render('Posts/Show', [
        'post' => $post->load('author', 'tags'),
        'canEdit' => auth()->user()->can('update', $post),
        'canDelete' => auth()->user()->can('delete', $post),
    ]);
}
```

```vue
<!-- Client-side authorization handling -->
<template>
  <div>
    <!-- Conditional rendering based on permissions -->
    <div v-if="canViewPosts">
      <h2>Posts</h2>
      <!-- Posts list -->
    </div>

    <div v-if="canCreatePost" class="mt-4">
      <Link :href="route('posts.create')" class="btn btn-primary">
        Create New Post
      </Link>
    </div>

    <!-- Action buttons with permission checks -->
    <div v-if="post" class="flex space-x-2">
      <Link
        v-if="canEdit"
        :href="route('posts.edit', post)"
        class="btn btn-secondary"
      >
        Edit
      </Link>

      <button
        v-if="canDelete"
        @click="deletePost"
        class="btn btn-danger"
      >
        Delete
      </button>
    </div>
  </div>
</template>

<script setup>
import { Link, router } from '@inertiajs/vue3'

const props = defineProps({
  post: Object,
  canEdit: Boolean,
  canDelete: Boolean,
})

// Computed permissions based on page props
const canViewPosts = computed(() => {
  return $page.props.auth.user && $page.props.auth.permissions.includes('view-posts')
})

const canCreatePost = computed(() => {
  return $page.props.auth.user && $page.props.auth.permissions.includes('create-posts')
})

const deletePost = () => {
  if (confirm('Are you sure you want to delete this post?')) {
    router.delete(route('posts.destroy', props.post), {
      onSuccess: () => {
        // Handle success
      },
      onError: (errors) => {
        console.error('Delete failed:', errors)
      }
    })
  }
}
</script>
```

## Performance Optimization

### Frontend Optimization

```javascript
// Code splitting and lazy loading
import { defineAsyncComponent } from 'vue'

// Lazy load heavy components
const HeavyChart = defineAsyncComponent(() => import('@/Components/HeavyChart.vue'))
const DataTable = defineAsyncComponent(() => import('@/Components/DataTable.vue'))

// Route-based code splitting
const routes = {
  'Dashboard': () => import('@/Pages/Dashboard/Index.vue'),
  'Users/Index': () => import('@/Pages/Users/Index.vue'),
  'Reports/Analytics': () => import('@/Pages/Reports/Analytics.vue'),
}

// Preload critical routes
router.preload('dashboard')
router.preload('users.index')
```

```vue
<!-- Virtual scrolling for large lists -->
<template>
  <div class="virtual-list" :style="{ height: containerHeight + 'px' }">
    <div
      class="virtual-list-phantom"
      :style="{ height: totalHeight + 'px' }"
    ></div>

    <div
      class="virtual-list-content"
      :style="{ transform: `translateY(${offset}px)` }"
    >
      <div
        v-for="item in visibleItems"
        :key="item.id"
        class="virtual-list-item"
        :style="{ height: itemHeight + 'px' }"
      >
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  items: Array,
  itemHeight: {
    type: Number,
    default: 50,
  },
  containerHeight: {
    type: Number,
    default: 400,
  },
})

const scrollTop = ref(0)

const totalHeight = computed(() => {
  return props.items.length * props.itemHeight
})

const visibleCount = computed(() => {
  return Math.ceil(props.containerHeight / props.itemHeight) + 2
})

const startIndex = computed(() => {
  return Math.floor(scrollTop.value / props.itemHeight)
})

const endIndex = computed(() => {
  return Math.min(startIndex.value + visibleCount.value, props.items.length)
})

const visibleItems = computed(() => {
  return props.items.slice(startIndex.value, endIndex.value)
})

const offset = computed(() => {
  return startIndex.value * props.itemHeight
})

const handleScroll = (e) => {
  scrollTop.value = e.target.scrollTop
}

onMounted(() => {
  const container = document.querySelector('.virtual-list')
  container?.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  const container = document.querySelector('.virtual-list')
  container?.removeEventListener('scroll', handleScroll)
})
</script>
```

### Backend Optimization

```php
// Database query optimization
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Inertia\Inertia;
use App\Models\User;

class UserController extends Controller
{
    public function index(Request $request)
    {
        // Efficient pagination with eager loading
        $users = User::query()
            ->with(['profile', 'roles:id,name']) // Eager load relationships
            ->select(['id', 'name', 'email', 'created_at']) // Select only needed columns
            ->when($request->search, function ($query, $search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->when($request->role, function ($query, $role) {
                $query->whereHas('roles', function ($q) use ($role) {
                    $q->where('name', $role);
                });
            })
            ->orderBy($request->sort ?? 'created_at', $request->direction ?? 'desc')
            ->paginate($request->per_page ?? 15)
            ->withQueryString();

        return Inertia::render('Users/Index', [
            'users' => $users,
            'filters' => $request->only(['search', 'role', 'sort', 'direction']),
        ]);
    }

    // Efficient resource transformation
    public function show(User $user)
    {
        // Load relationships efficiently
        $user->load([
            'profile',
            'posts' => function ($query) {
                $query->select(['id', 'title', 'slug', 'created_at', 'user_id'])
                      ->latest()
                      ->limit(10);
            },
            'roles:id,name'
        ]);

        return Inertia::render('Users/Show', [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'profile' => $user->profile,
                'recent_posts' => $user->posts,
                'roles' => $user->roles->pluck('name'),
                'created_at' => $user->created_at->format('Y-m-d'),
            ],
        ]);
    }
}

// Caching strategies
class PostController extends Controller
{
    public function index(Request $request)
    {
        $cacheKey = 'posts.' . md5($request->fullUrl());

        $posts = Cache::remember($cacheKey, 300, function () use ($request) {
            return Post::with('author:id,name')
                ->published()
                ->latest()
                ->paginate(15);
        });

        return Inertia::render('Posts/Index', compact('posts'));
    }

    public function show(Post $post)
    {
        $cacheKey = "post.{$post->id}.{$post->updated_at->timestamp}";

        $postData = Cache::remember($cacheKey, 3600, function () use ($post) {
            return $post->load([
                'author:id,name,avatar',
                'tags:id,name',
                'comments' => function ($query) {
                    $query->with('author:id,name')
                          ->latest()
                          ->limit(20);
                }
            ]);
        });

        return Inertia::render('Posts/Show', [
            'post' => $postData,
        ]);
    }
}
```

### Asset Optimization

```javascript
// vite.config.js - Production optimization
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],

  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', '@inertiajs/vue3'],
          ui: ['@headlessui/vue', '@heroicons/vue'],
          utils: ['lodash', 'axios', 'date-fns'],
        },
      },
    },
    chunkSizeWarningLimit: 600,
  },

  resolve: {
    alias: {
      '@': resolve(__dirname, 'resources/js'),
    },
  },

  server: {
    hmr: {
      host: 'localhost',
    },
  },
})

// Resource preloading
const preloadCriticalRoutes = () => {
  // Preload dashboard route
  router.preload('dashboard')

  // Preload user's most visited routes
  const frequentRoutes = JSON.parse(localStorage.getItem('frequent_routes') || '[]')
  frequentRoutes.forEach(route => {
    router.preload(route)
  })
}

// Image optimization
const optimizeImages = () => {
  // Lazy load images
  const images = document.querySelectorAll('img[data-src]')
  const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target
        img.src = img.dataset.src
        img.classList.remove('lazy')
        imageObserver.unobserve(img)
      }
    })
  })

  images.forEach(img => imageObserver.observe(img))
}
```

## Testing Strategies

### Frontend Testing

```javascript
// test/components/UserForm.test.js
import { mount } from '@vue/test-utils'
import { createInertiaApp } from '@inertiajs/vue3'
import UserForm from '@/Pages/Users/Create.vue'

describe('UserForm', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(UserForm, {
      global: {
        plugins: [
          {
            install(app) {
              app.config.globalProperties.route = (name, params) => {
                const routes = {
                  'users.store': '/users',
                  'users.index': '/users',
                }
                return routes[name] || '/'
              }
            }
          }
        ],
        stubs: {
          Link: {
            template: '<a><slot /></a>'
          }
        }
      }
    })
  })

  afterEach(() => {
    wrapper.unmount()
  })

  it('renders form fields correctly', () => {
    expect(wrapper.find('input[type="text"]').exists()).toBe(true)
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('validates required fields', async () => {
    // Submit empty form
    await wrapper.find('form').trigger('submit.prevent')

    // Check for validation errors
    expect(wrapper.vm.form.errors.name).toBeTruthy()
    expect(wrapper.vm.form.errors.email).toBeTruthy()
  })

  it('submits form with valid data', async () => {
    // Fill form
    await wrapper.find('input[type="text"]').setValue('John Doe')
    await wrapper.find('input[type="email"]').setValue('john@example.com')

    // Mock form submission
    const mockPost = vi.fn()
    wrapper.vm.form.post = mockPost

    // Submit form
    await wrapper.find('form').trigger('submit.prevent')

    expect(mockPost).toHaveBeenCalledWith('/users')
  })

  it('disables submit button while processing', async () => {
    wrapper.vm.form.processing = true
    await wrapper.vm.$nextTick()

    const submitButton = wrapper.find('button[type="submit"]')
    expect(submitButton.attributes('disabled')).toBeDefined()
  })
})
```

### Integration Testing

```javascript
// test/features/user-management.test.js
import { test, expect } from '@playwright/test'

test.describe('User Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto('/login')
    await page.fill('[name="email"]', 'admin@example.com')
    await page.fill('[name="password"]', 'password')
    await page.click('button[type="submit"]')
    await page.waitForURL('/dashboard')
  })

  test('can create a new user', async ({ page }) => {
    // Navigate to user creation
    await page.goto('/users')
    await page.click('text=Create User')

    // Fill form
    await page.fill('[name="name"]', 'Test User')
    await page.fill('[name="email"]', 'test@example.com')
    await page.fill('[name="password"]', 'password123')
    await page.fill('[name="password_confirmation"]', 'password123')

    // Submit form
    await page.click('button[type="submit"]')

    // Verify redirect and success message
    await page.waitForURL('/users')
    await expect(page.locator('.flash-success')).toContainText('User created successfully')

    // Verify user appears in list
    await expect(page.locator('text=Test User')).toBeVisible()
  })

  test('validates form inputs', async ({ page }) => {
    await page.goto('/users/create')

    // Submit empty form
    await page.click('button[type="submit"]')

    // Check validation errors
    await expect(page.locator('.error')).toContainText('The name field is required')
    await expect(page.locator('.error')).toContainText('The email field is required')
  })

  test('can search and filter users', async ({ page }) => {
    await page.goto('/users')

    // Search for user
    await page.fill('[placeholder="Search users..."]', 'john')
    await page.waitForTimeout(350) // Wait for debounce

    // Verify filtered results
    const userRows = page.locator('table tbody tr')
    await expect(userRows).toHaveCount(1)
    await expect(userRows.first()).toContainText('john')

    // Clear search
    await page.fill('[placeholder="Search users..."]', '')
    await page.waitForTimeout(350)

    // Verify all users shown
    await expect(userRows).toHaveCountGreaterThan(1)
  })

  test('can delete a user', async ({ page }) => {
    await page.goto('/users')

    // Click delete button for first user
    await page.click('button:has-text("Delete"):first')

    // Confirm deletion in dialog
    page.on('dialog', dialog => dialog.accept())

    // Wait for request to complete
    await page.waitForResponse('/users/**')

    // Verify success message
    await expect(page.locator('.flash-success')).toContainText('User deleted successfully')
  })
})
```

### End-to-End Testing

```javascript
// test/e2e/complete-workflow.test.js
import { test, expect } from '@playwright/test'

test.describe('Complete User Workflow', () => {
  test('complete user registration and profile setup', async ({ page }) => {
    // Registration
    await page.goto('/register')
    await page.fill('[name="name"]', 'New User')
    await page.fill('[name="email"]', 'newuser@example.com')
    await page.fill('[name="password"]', 'SecurePassword123!')
    await page.fill('[name="password_confirmation"]', 'SecurePassword123!')
    await page.check('[name="terms"]')
    await page.click('button[type="submit"]')

    // Verify email verification notice
    await expect(page.locator('.verification-notice')).toBeVisible()

    // Simulate email verification (in real tests, you'd handle this differently)
    await page.goto('/email/verify/1/fake-hash?signature=fake-signature')

    // Complete profile setup
    await page.fill('[name="phone"]', '+1234567890')
    await page.selectOption('[name="country"]', 'US')
    await page.fill('[name="bio"]', 'This is my bio')

    // Upload avatar
    await page.setInputFiles('[name="avatar"]', 'test/fixtures/avatar.jpg')

    await page.click('button:has-text("Complete Profile")')

    // Verify dashboard access
    await page.waitForURL('/dashboard')
    await expect(page.locator('.welcome-message')).toContainText('Welcome, New User!')

    // Verify profile data is displayed correctly
    await page.click('text=Profile')
    await expect(page.locator('[data-testid="user-name"]')).toContainText('New User')
    await expect(page.locator('[data-testid="user-email"]')).toContainText('newuser@example.com')
    await expect(page.locator('[data-testid="user-phone"]')).toContainText('+1234567890')
  })

  test('handles complex form interactions', async ({ page }) => {
    // Login
    await page.goto('/login')
    await page.fill('[name="email"]', 'user@example.com')
    await page.fill('[name="password"]', 'password')
    await page.click('button[type="submit"]')

    // Navigate to complex form
    await page.goto('/forms/complex')

    // Test dynamic form sections
    await page.selectOption('[name="form_type"]', 'business')
    await expect(page.locator('.business-fields')).toBeVisible()

    await page.fill('[name="company_name"]', 'Test Company')
    await page.fill('[name="tax_id"]', '123456789')

    // Test conditional validation
    await page.selectOption('[name="business_type"]', 'corporation')
    await expect(page.locator('[name="incorporation_state"]')).toBeVisible()

    // Test file upload
    await page.setInputFiles('[name="documents[]"]', [
      'test/fixtures/document1.pdf',
      'test/fixtures/document2.pdf'
    ])

    // Verify upload progress
    await expect(page.locator('.upload-progress')).toBeVisible()
    await page.waitForSelector('.upload-complete')

    // Submit form
    await page.click('button:has-text("Submit Application")')

    // Verify success and data persistence
    await page.waitForURL('/applications/*')
    await expect(page.locator('.application-status')).toContainText('Submitted')
    await expect(page.locator('.company-name')).toContainText('Test Company')
  })
})
```

## Deployment Guide

### Production Build

```bash
# Build assets for production
npm run build

# Optimize Laravel for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Generate application key (if needed)
php artisan key:generate

# Run database migrations
php artisan migrate --force

# Clear and warm up caches
php artisan cache:clear
php artisan config:cache
php artisan route:cache
```

### Server Configuration

```nginx
# nginx.conf
server {
    listen 80;
    server_name example.com;
    root /var/www/html/public;
    index index.php index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types
        text/css
        text/javascript
        text/xml
        text/plain
        text/x-component
        application/javascript
        application/x-javascript
        application/json
        application/xml
        application/rss+xml
        application/atom+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Handle PHP files
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;

        # Increase timeout for long-running requests
        fastcgi_read_timeout 300;
    }

    # Handle Inertia.js routes
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Security: Hide sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ /\.(?:git|env) {
        deny all;
    }
}
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM php:8.2-fpm-alpine

# Install dependencies
RUN apk add --no-cache \
    zip \
    unzip \
    curl \
    nginx \
    supervisor \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql bcmath

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install and build frontend assets
RUN npm ci && npm run build

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/php.ini /usr/local/etc/php/php.ini
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "80:80"
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - DB_HOST=db
      - DB_DATABASE=laravel
      - DB_USERNAME=laravel
      - DB_PASSWORD=secret
    volumes:
      - storage:/var/www/html/storage
    depends_on:
      - db
      - redis

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=secret
      - MYSQL_DATABASE=laravel
      - MYSQL_USER=laravel
      - MYSQL_PASSWORD=secret
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:alpine
    volumes:
      - redis_data:/data

volumes:
  storage:
  db_data:
  redis_data:
```

### Environment Configuration

```bash
# .env.production
APP_NAME="My Inertia App"
APP_ENV=production
APP_KEY=base64:GENERATED_KEY_HERE
APP_DEBUG=false
APP_URL=https://example.com

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=production_db
DB_USERNAME=production_user
DB_PASSWORD=secure_password

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=s3
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

# Asset optimization
VITE_APP_NAME="${APP_NAME}"
VITE_APP_ENV="${APP_ENV}"

# Security settings
SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS="example.com"
```

## Common Pitfalls

### Data Synchronization Issues

```php
// WRONG: Not handling race conditions
public function update(Request $request, User $user)
{
    $user->update($request->validated());
    return back();
}

// RIGHT: Handle concurrent updates
public function update(Request $request, User $user)
{
    $validated = $request->validated();

    // Check for concurrent modifications
    if ($request->has('updated_at') &&
        $user->updated_at->timestamp !== $request->updated_at) {
        return back()->withErrors([
            'concurrent_update' => 'This record has been modified by another user. Please refresh and try again.'
        ]);
    }

    $user->update($validated);
    return back()->with('success', 'User updated successfully.');
}
```

```vue
<!-- Handle stale data in frontend -->
<template>
  <form @submit.prevent="submit">
    <input type="hidden" :value="user.updated_at" name="updated_at">
    <!-- Form fields -->
    <button type="submit" :disabled="form.processing">
      Update User
    </button>

    <!-- Show warning for concurrent updates -->
    <div v-if="form.errors.concurrent_update" class="alert alert-warning">
      {{ form.errors.concurrent_update }}
      <button @click="refreshData" class="btn btn-sm btn-primary ml-2">
        Refresh Data
      </button>
    </div>
  </form>
</template>

<script setup>
import { router } from '@inertiajs/vue3'

const refreshData = () => {
  router.reload({ only: ['user'] })
}
</script>
```

### Memory Leaks and Performance Issues

```javascript
// WRONG: Not cleaning up event listeners
function badComponent() {
  onMounted(() => {
    window.addEventListener('resize', handleResize)
  })
}

// RIGHT: Proper cleanup
function goodComponent() {
  onMounted(() => {
    window.addEventListener('resize', handleResize)
  })

  onUnmounted(() => {
    window.removeEventListener('resize', handleResize)
  })
}

// WRONG: Reactive objects in loops
const badList = ref([])
watch(badList, () => {
  badList.value.forEach(item => {
    // Creates new reactive object each time
    item.computed = computed(() => expensiveCalculation(item))
  })
})

// RIGHT: Memoized computations
const goodList = ref([])
const memoizedCalculations = new Map()

const getCalculation = (item) => {
  if (!memoizedCalculations.has(item.id)) {
    memoizedCalculations.set(item.id, computed(() => expensiveCalculation(item)))
  }
  return memoizedCalculations.get(item.id)
}
```

### Form Handling Pitfalls

```vue
<!-- WRONG: Not preserving scroll on validation errors -->
<script setup>
const submit = () => {
  form.post('/users', {
    // Will lose scroll position on validation errors
  })
}
</script>

<!-- RIGHT: Preserve user experience -->
<script setup>
const submit = () => {
  form.post('/users', {
    preserveScroll: true,
    onError: (errors) => {
      // Focus first error field
      const firstErrorField = Object.keys(errors)[0]
      const element = document.querySelector(`[name="${firstErrorField}"]`)
      element?.focus()
    }
  })
}
</script>
```

## Troubleshooting

### Common Issues and Solutions

#### Inertia Requests Not Working

```javascript
// Problem: Standard HTTP requests instead of Inertia requests
// Solution: Ensure proper setup

// Check if Inertia is properly initialized
if (!window.Inertia) {
  console.error('Inertia.js not initialized')
}

// Verify middleware is registered
// In Laravel: app/Http/Kernel.php
'web' => [
    \App\Http\Middleware\HandleInertiaRequests::class,
],

// Check X-Inertia header in requests
const observer = new PerformanceObserver((list) => {
  list.getEntries().forEach((entry) => {
    if (entry.name.includes('/users')) {
      console.log('Request type:', entry.transferSize === 0 ? 'Inertia' : 'Standard')
    }
  })
})
observer.observe({ entryTypes: ['navigation', 'resource'] })
```

#### Page Props Not Updating

```php
// Problem: Shared data not reactive
// Solution: Use closures for dynamic data

// WRONG
public function share(Request $request): array
{
    return [
        'auth' => [
            'user' => $request->user(),
        ],
    ];
}

// RIGHT
public function share(Request $request): array
{
    return [
        'auth' => [
            'user' => fn () => $request->user() ? [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'email' => $request->user()->email,
            ] : null,
        ],
    ];
}
```

#### Form Validation Issues

```vue
<!-- Problem: Validation errors not clearing -->
<template>
  <form @submit.prevent="submit">
    <input v-model="form.email" @input="clearError('email')">
    <div v-if="form.errors.email">{{ form.errors.email }}</div>
  </form>
</template>

<script setup>
const clearError = (field) => {
  if (form.errors[field]) {
    form.clearErrors(field)
  }
}
</script>
```

#### Route Helper Issues

```javascript
// Problem: Route helper not available
// Solution: Ensure Ziggy is properly configured

// Install and configure Ziggy
npm install ziggy-js

// In app.js
import { ZiggyVue } from '../../vendor/tightenco/ziggy/dist/vue.m'

app.use(ZiggyVue, Ziggy)

// Alternative: Create route helper
const route = (name, params = {}) => {
  const routes = {
    'users.index': '/users',
    'users.show': (id) => `/users/${id}`,
    'users.edit': (id) => `/users/${id}/edit`,
  }

  const routeFunction = routes[name]
  return typeof routeFunction === 'function' ? routeFunction(params) : routeFunction
}
```

### Debugging Tools

```javascript
// Inertia debugging utility
window.debugInertia = {
  // Log all Inertia requests
  logRequests() {
    const originalVisit = router.visit
    router.visit = function(...args) {
      console.log('Inertia visit:', args)
      return originalVisit.apply(this, args)
    }
  },

  // Log page props
  logProps() {
    console.log('Current page props:', usePage().props)
  },

  // Log component tree
  logComponents() {
    const components = document.querySelectorAll('[data-page]')
    components.forEach(component => {
      console.log('Component:', component.dataset.page)
    })
  },

  // Monitor performance
  monitorPerformance() {
    const observer = new PerformanceObserver((list) => {
      list.getEntries().forEach((entry) => {
        if (entry.name.includes('inertia')) {
          console.log('Inertia performance:', entry)
        }
      })
    })
    observer.observe({ entryTypes: ['navigation', 'resource'] })
  }
}

// Enable debugging in development
if (import.meta.env.DEV) {
  window.debugInertia.logRequests()
  window.debugInertia.monitorPerformance()
}
```

## Best Practices Summary

### Development Guidelines

1. **Architecture**
   - Use server-side validation as the source of truth
   - Keep client-side logic minimal and focused on UX
   - Leverage Inertia's automatic CSRF protection
   - Use shared data for global application state

2. **Performance**
   - Implement proper caching strategies on the backend
   - Use eager loading to avoid N+1 queries
   - Leverage code splitting for large applications
   - Implement virtual scrolling for large datasets

3. **Security**
   - Always validate and sanitize user input on the server
   - Use Laravel's built-in authorization policies
   - Implement proper CSRF protection
   - Follow secure coding practices for XSS prevention

4. **Testing**
   - Write comprehensive integration tests for user workflows
   - Test form validation and error handling
   - Use page object models for maintainable tests
   - Test both success and failure scenarios

5. **Maintenance**
   - Keep dependencies up to date
   - Monitor application performance
   - Implement proper error logging and monitoring
   - Document complex business logic and integrations

## Conclusion

Inertia.js provides an elegant solution for building modern web applications while maintaining the simplicity of traditional server-side development. It successfully bridges the gap between classic web development and single-page applications, offering the best of both worlds.

The framework's strength lies in its ability to provide SPA-like user experiences without the complexity of building and maintaining separate frontend and backend applications. This makes it particularly valuable for teams with strong backend expertise who want to create dynamic, interactive applications without diving deep into API design and state management complexities.

However, Inertia.js is not a universal solution. It works best for traditional web applications that benefit from SPA behavior, but may not be suitable for complex real-time applications, mobile-first development, or architectures requiring multiple client applications.

Success with Inertia.js comes from understanding its philosophy and leveraging its strengths: server-side routing, traditional authentication patterns, and seamless integration between frontend and backend. When used appropriately, it can significantly reduce development complexity while delivering excellent user experiences.

The framework continues to evolve with strong community support and regular updates. Its integration with popular backend frameworks like Laravel, Rails, and Django makes it an attractive choice for teams looking to modernize their web applications without abandoning their existing technology investments.

## Resources

### Official Documentation
- [Inertia.js Official Website](https://inertiajs.com/)
- [Inertia.js GitHub Repository](https://github.com/inertiajs/inertia)
- [Laravel Adapter Documentation](https://inertiajs.com/server-side-setup)
- [Vue.js Integration Guide](https://inertiajs.com/client-side-setup)

### Learning Resources
- [Inertia.js Tutorial Series](https://laracasts.com/series/build-modern-laravel-apps-using-inertia-js)
- [Building SPAs with Inertia.js](https://codecourse.com/courses/inertia-js)
- [Inertia.js Best Practices](https://tighten.co/blog/inertia-js-best-practices)

### Tools and Packages
- [Ziggy - Laravel Route Helper](https://github.com/tightenco/ziggy)
- [Laravel Breeze with Inertia](https://laravel.com/docs/starter-kits#breeze-and-inertia)
- [Laravel Jetstream](https://jetstream.laravel.com/)
- [Inertia.js DevTools](https://github.com/inertiajs/inertia-devtools)

### Community
- [Inertia.js Discord](https://discord.gg/gwgxN8Y)
- [Laravel Community](https://laravel.io/)
- [Vue.js Community](https://vue-community.org/)

### Testing Tools
- [Laravel Dusk](https://laravel.com/docs/dusk)
- [Playwright](https://playwright.dev/)
- [Vue Testing Library](https://testing-library.com/docs/vue-testing-library/intro/)

### Performance Monitoring
- [Laravel Telescope](https://laravel.com/docs/telescope)
- [Laravel Horizon](https://laravel.com/docs/horizon)
- [Sentry](https://sentry.io/)
- [New Relic](https://newrelic.com/)