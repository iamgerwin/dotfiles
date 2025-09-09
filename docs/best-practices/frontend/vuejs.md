# Vue.js Best Practices

## Official Documentation
- **Vue 3 Documentation**: https://vuejs.org
- **Vue Router**: https://router.vuejs.org
- **Pinia (State Management)**: https://pinia.vuejs.org
- **Vite**: https://vitejs.dev
- **Vue DevTools**: https://devtools.vuejs.org

## Project Structure

```
project-root/
├── src/
│   ├── assets/
│   │   ├── images/
│   │   ├── styles/
│   │   │   ├── main.scss
│   │   │   ├── variables.scss
│   │   │   └── mixins.scss
│   │   └── fonts/
│   ├── components/
│   │   ├── common/
│   │   │   ├── BaseButton.vue
│   │   │   ├── BaseInput.vue
│   │   │   └── BaseModal.vue
│   │   ├── layout/
│   │   │   ├── TheHeader.vue
│   │   │   ├── TheSidebar.vue
│   │   │   └── TheFooter.vue
│   │   └── features/
│   │       ├── UserCard.vue
│   │       └── ProductList.vue
│   ├── composables/
│   │   ├── useAuth.js
│   │   ├── useFetch.js
│   │   └── useDebounce.js
│   ├── directives/
│   │   ├── v-click-outside.js
│   │   └── v-lazy-load.js
│   ├── layouts/
│   │   ├── DefaultLayout.vue
│   │   └── AuthLayout.vue
│   ├── pages/
│   │   ├── HomePage.vue
│   │   ├── UserProfile.vue
│   │   └── NotFound.vue
│   ├── router/
│   │   ├── index.js
│   │   └── guards.js
│   ├── stores/
│   │   ├── auth.js
│   │   ├── user.js
│   │   └── cart.js
│   ├── services/
│   │   ├── api.js
│   │   └── auth.service.js
│   ├── utils/
│   │   ├── validators.js
│   │   ├── formatters.js
│   │   └── constants.js
│   ├── App.vue
│   └── main.js
├── public/
├── tests/
│   ├── unit/
│   └── e2e/
├── .env
├── .env.example
├── vite.config.js
├── package.json
└── tsconfig.json
```

## Core Best Practices

### 1. Composition API with TypeScript

```vue
<!-- UserProfile.vue -->
<template>
  <div class="user-profile">
    <div v-if="loading" class="loading">
      <LoadingSpinner />
    </div>
    
    <div v-else-if="error" class="error">
      <ErrorMessage :message="error.message" @retry="fetchUser" />
    </div>
    
    <div v-else-if="user" class="profile-content">
      <UserAvatar 
        :src="user.avatar" 
        :alt="user.name"
        size="large"
      />
      
      <h1>{{ user.name }}</h1>
      <p>{{ user.email }}</p>
      
      <div class="profile-stats">
        <StatCard 
          v-for="stat in userStats" 
          :key="stat.label"
          :label="stat.label"
          :value="stat.value"
          :icon="stat.icon"
        />
      </div>
      
      <BaseButton 
        @click="editProfile"
        variant="primary"
        :disabled="isEditing"
      >
        Edit Profile
      </BaseButton>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { storeToRefs } from 'pinia'
import { useUserStore } from '@/stores/user'
import { useAuth } from '@/composables/useAuth'
import type { User } from '@/types'

// Components
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import ErrorMessage from '@/components/common/ErrorMessage.vue'
import UserAvatar from '@/components/UserAvatar.vue'
import StatCard from '@/components/StatCard.vue'
import BaseButton from '@/components/common/BaseButton.vue'

// Props
interface Props {
  userId?: string
}

const props = withDefaults(defineProps<Props>(), {
  userId: ''
})

// Emits
const emit = defineEmits<{
  'profile-updated': [user: User]
  'error': [error: Error]
}>()

// Composables
const route = useRoute()
const router = useRouter()
const { isAuthenticated, currentUser } = useAuth()
const userStore = useUserStore()
const { user, loading, error } = storeToRefs(userStore)

// State
const isEditing = ref(false)

// Computed
const userId = computed(() => props.userId || route.params.id as string)

const userStats = computed(() => [
  { label: 'Posts', value: user.value?.postsCount || 0, icon: 'mdi-post' },
  { label: 'Followers', value: user.value?.followersCount || 0, icon: 'mdi-account-group' },
  { label: 'Following', value: user.value?.followingCount || 0, icon: 'mdi-account-plus' }
])

const canEdit = computed(() => {
  return isAuthenticated.value && currentUser.value?.id === user.value?.id
})

// Methods
async function fetchUser() {
  try {
    await userStore.fetchUser(userId.value)
  } catch (err) {
    emit('error', err as Error)
  }
}

function editProfile() {
  if (!canEdit.value) return
  
  isEditing.value = true
  router.push({
    name: 'EditProfile',
    params: { id: userId.value }
  })
}

// Watchers
watch(userId, (newId) => {
  if (newId) {
    fetchUser()
  }
})

// Lifecycle
onMounted(() => {
  if (userId.value) {
    fetchUser()
  }
})
</script>

<style scoped lang="scss">
.user-profile {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
  
  .loading,
  .error {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;
  }
  
  .profile-content {
    text-align: center;
    
    h1 {
      margin: 1rem 0;
      font-size: 2rem;
      color: var(--text-primary);
    }
    
    p {
      color: var(--text-secondary);
      margin-bottom: 2rem;
    }
  }
  
  .profile-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 1rem;
    margin: 2rem 0;
  }
}
</style>
```

### 2. Composables for Reusable Logic

```javascript
// composables/useFetch.js
import { ref, unref, watchEffect } from 'vue'

export function useFetch(url, options = {}) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)
  const abortController = ref(null)
  
  async function execute() {
    loading.value = true
    error.value = null
    
    // Cancel previous request
    if (abortController.value) {
      abortController.value.abort()
    }
    
    // Create new abort controller
    abortController.value = new AbortController()
    
    try {
      const response = await fetch(unref(url), {
        ...options,
        signal: abortController.value.signal
      })
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      
      data.value = await response.json()
    } catch (err) {
      if (err.name !== 'AbortError') {
        error.value = err
      }
    } finally {
      loading.value = false
    }
  }
  
  // Auto-fetch when URL changes
  if (options.immediate !== false) {
    watchEffect(() => {
      execute()
    })
  }
  
  // Cleanup on unmount
  onUnmounted(() => {
    if (abortController.value) {
      abortController.value.abort()
    }
  })
  
  return {
    data: readonly(data),
    error: readonly(error),
    loading: readonly(loading),
    execute,
    abort: () => abortController.value?.abort()
  }
}

// composables/useDebounce.js
import { ref, watch } from 'vue'

export function useDebounce(value, delay = 300) {
  const debouncedValue = ref(value.value)
  let timeout
  
  watch(value, (newValue) => {
    clearTimeout(timeout)
    timeout = setTimeout(() => {
      debouncedValue.value = newValue
    }, delay)
  })
  
  onUnmounted(() => {
    clearTimeout(timeout)
  })
  
  return debouncedValue
}

// composables/useInfiniteScroll.js
import { ref, onMounted, onUnmounted } from 'vue'

export function useInfiniteScroll(callback, options = {}) {
  const {
    threshold = 100,
    root = null,
    rootMargin = '0px'
  } = options
  
  const target = ref(null)
  const isIntersecting = ref(false)
  let observer = null
  
  onMounted(() => {
    observer = new IntersectionObserver(
      ([entry]) => {
        isIntersecting.value = entry.isIntersecting
        
        if (entry.isIntersecting) {
          callback()
        }
      },
      {
        root,
        rootMargin,
        threshold: threshold / 100
      }
    )
    
    if (target.value) {
      observer.observe(target.value)
    }
  })
  
  onUnmounted(() => {
    if (observer && target.value) {
      observer.unobserve(target.value)
      observer.disconnect()
    }
  })
  
  return {
    target,
    isIntersecting
  }
}

// composables/useLocalStorage.js
import { ref, watch, Ref } from 'vue'

export function useLocalStorage<T>(
  key: string,
  defaultValue: T,
  options = {}
): [Ref<T>, (value: T) => void] {
  const { serializer = JSON } = options
  
  const data = ref<T>(defaultValue)
  
  // Load initial value
  try {
    const item = window.localStorage.getItem(key)
    if (item !== null) {
      data.value = serializer.parse(item)
    }
  } catch (error) {
    console.error(`Error loading localStorage key "${key}":`, error)
  }
  
  // Save to localStorage when data changes
  watch(data, (newValue) => {
    try {
      window.localStorage.setItem(key, serializer.stringify(newValue))
    } catch (error) {
      console.error(`Error saving localStorage key "${key}":`, error)
    }
  }, { deep: true })
  
  // Manual setter
  function setData(value: T) {
    data.value = value
  }
  
  return [data, setData]
}
```

### 3. Pinia Store Management

```javascript
// stores/auth.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authService } from '@/services/auth.service'
import router from '@/router'

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null)
  const token = ref(localStorage.getItem('token'))
  const refreshToken = ref(localStorage.getItem('refreshToken'))
  const isLoading = ref(false)
  const error = ref(null)
  
  // Getters
  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const userRole = computed(() => user.value?.role || 'guest')
  const hasRole = computed(() => (role) => userRole.value === role)
  const hasPermission = computed(() => (permission) => {
    return user.value?.permissions?.includes(permission) || false
  })
  
  // Actions
  async function login(credentials) {
    isLoading.value = true
    error.value = null
    
    try {
      const response = await authService.login(credentials)
      
      // Store tokens
      token.value = response.data.token
      refreshToken.value = response.data.refreshToken
      user.value = response.data.user
      
      // Save to localStorage
      localStorage.setItem('token', token.value)
      localStorage.setItem('refreshToken', refreshToken.value)
      
      // Redirect to dashboard
      router.push('/dashboard')
      
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }
  
  async function logout() {
    try {
      await authService.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      // Clear state
      user.value = null
      token.value = null
      refreshToken.value = null
      
      // Clear localStorage
      localStorage.removeItem('token')
      localStorage.removeItem('refreshToken')
      
      // Redirect to login
      router.push('/login')
    }
  }
  
  async function fetchCurrentUser() {
    if (!token.value) return
    
    try {
      const response = await authService.getCurrentUser()
      user.value = response.data
    } catch (error) {
      if (error.response?.status === 401) {
        await logout()
      }
      throw error
    }
  }
  
  async function refreshAccessToken() {
    if (!refreshToken.value) {
      throw new Error('No refresh token available')
    }
    
    try {
      const response = await authService.refreshToken(refreshToken.value)
      
      token.value = response.data.token
      localStorage.setItem('token', token.value)
      
      return token.value
    } catch (error) {
      await logout()
      throw error
    }
  }
  
  // Reset store
  function $reset() {
    user.value = null
    token.value = null
    refreshToken.value = null
    isLoading.value = false
    error.value = null
  }
  
  return {
    // State
    user,
    token,
    isLoading,
    error,
    
    // Getters
    isAuthenticated,
    userRole,
    hasRole,
    hasPermission,
    
    // Actions
    login,
    logout,
    fetchCurrentUser,
    refreshAccessToken,
    $reset
  }
})

// stores/user.js
import { defineStore } from 'pinia'
import { userService } from '@/services/user.service'

export const useUserStore = defineStore('user', {
  state: () => ({
    users: [],
    currentUser: null,
    loading: false,
    error: null,
    filters: {
      search: '',
      role: null,
      status: 'active'
    },
    pagination: {
      page: 1,
      limit: 20,
      total: 0
    }
  }),
  
  getters: {
    filteredUsers: (state) => {
      let filtered = [...state.users]
      
      if (state.filters.search) {
        const search = state.filters.search.toLowerCase()
        filtered = filtered.filter(user => 
          user.name.toLowerCase().includes(search) ||
          user.email.toLowerCase().includes(search)
        )
      }
      
      if (state.filters.role) {
        filtered = filtered.filter(user => user.role === state.filters.role)
      }
      
      if (state.filters.status) {
        filtered = filtered.filter(user => user.status === state.filters.status)
      }
      
      return filtered
    },
    
    totalPages: (state) => Math.ceil(state.pagination.total / state.pagination.limit),
    
    getUserById: (state) => (id) => {
      return state.users.find(user => user.id === id)
    }
  },
  
  actions: {
    async fetchUsers(params = {}) {
      this.loading = true
      this.error = null
      
      try {
        const response = await userService.getUsers({
          ...this.filters,
          page: this.pagination.page,
          limit: this.pagination.limit,
          ...params
        })
        
        this.users = response.data.users
        this.pagination.total = response.data.total
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
    
    async fetchUser(id) {
      this.loading = true
      this.error = null
      
      try {
        const response = await userService.getUser(id)
        this.currentUser = response.data
        
        // Update in list if exists
        const index = this.users.findIndex(u => u.id === id)
        if (index !== -1) {
          this.users[index] = response.data
        }
        
        return response.data
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
    
    async createUser(userData) {
      this.loading = true
      this.error = null
      
      try {
        const response = await userService.createUser(userData)
        this.users.unshift(response.data)
        return response.data
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
    
    async updateUser(id, updates) {
      this.loading = true
      this.error = null
      
      try {
        const response = await userService.updateUser(id, updates)
        
        const index = this.users.findIndex(u => u.id === id)
        if (index !== -1) {
          this.users[index] = response.data
        }
        
        if (this.currentUser?.id === id) {
          this.currentUser = response.data
        }
        
        return response.data
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
    
    async deleteUser(id) {
      this.loading = true
      this.error = null
      
      try {
        await userService.deleteUser(id)
        this.users = this.users.filter(u => u.id !== id)
        
        if (this.currentUser?.id === id) {
          this.currentUser = null
        }
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.loading = false
      }
    },
    
    setFilter(key, value) {
      this.filters[key] = value
      this.pagination.page = 1 // Reset to first page
      this.fetchUsers()
    },
    
    setPage(page) {
      this.pagination.page = page
      this.fetchUsers()
    }
  }
})
```

### 4. Router Configuration

```javascript
// router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Lazy load route components
const HomePage = () => import('@/pages/HomePage.vue')
const LoginPage = () => import('@/pages/LoginPage.vue')
const DashboardPage = () => import('@/pages/DashboardPage.vue')
const UserProfile = () => import('@/pages/UserProfile.vue')
const NotFound = () => import('@/pages/NotFound.vue')

const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomePage,
    meta: { 
      title: 'Home',
      requiresAuth: false 
    }
  },
  {
    path: '/login',
    name: 'Login',
    component: LoginPage,
    meta: { 
      title: 'Login',
      requiresGuest: true 
    }
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: DashboardPage,
    meta: { 
      title: 'Dashboard',
      requiresAuth: true,
      roles: ['admin', 'user']
    }
  },
  {
    path: '/user/:id',
    name: 'UserProfile',
    component: UserProfile,
    props: true,
    meta: { 
      title: 'User Profile',
      requiresAuth: true 
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: NotFound,
    meta: { 
      title: '404 Not Found' 
    }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else if (to.hash) {
      return { el: to.hash, behavior: 'smooth' }
    } else {
      return { top: 0 }
    }
  }
})

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  // Set page title
  document.title = to.meta.title 
    ? `${to.meta.title} | My App`
    : 'My App'
  
  // Check authentication
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({
      name: 'Login',
      query: { redirect: to.fullPath }
    })
    return
  }
  
  // Check guest only routes
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next({ name: 'Dashboard' })
    return
  }
  
  // Check roles
  if (to.meta.roles && !to.meta.roles.includes(authStore.userRole)) {
    next({ name: 'NotFound' })
    return
  }
  
  next()
})

export default router
```

### 5. Component Best Practices

```vue
<!-- BaseButton.vue - Reusable component -->
<template>
  <component
    :is="componentType"
    :to="to"
    :href="href"
    :type="type"
    :disabled="disabled || loading"
    :class="buttonClasses"
    @click="handleClick"
  >
    <span v-if="loading" class="button-loader">
      <LoadingIcon />
    </span>
    <span v-if="icon && iconPosition === 'left'" class="button-icon">
      <component :is="icon" />
    </span>
    <span class="button-content">
      <slot>{{ label }}</slot>
    </span>
    <span v-if="icon && iconPosition === 'right'" class="button-icon">
      <component :is="icon" />
    </span>
  </component>
</template>

<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

const props = defineProps({
  label: String,
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'secondary', 'danger', 'ghost'].includes(value)
  },
  size: {
    type: String,
    default: 'medium',
    validator: (value) => ['small', 'medium', 'large'].includes(value)
  },
  type: {
    type: String,
    default: 'button'
  },
  to: [String, Object],
  href: String,
  disabled: Boolean,
  loading: Boolean,
  fullWidth: Boolean,
  icon: Object,
  iconPosition: {
    type: String,
    default: 'left'
  }
})

const emit = defineEmits(['click'])

const componentType = computed(() => {
  if (props.to) return RouterLink
  if (props.href) return 'a'
  return 'button'
})

const buttonClasses = computed(() => [
  'base-button',
  `button--${props.variant}`,
  `button--${props.size}`,
  {
    'button--disabled': props.disabled,
    'button--loading': props.loading,
    'button--full-width': props.fullWidth
  }
])

function handleClick(event) {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}
</script>

<style scoped lang="scss">
.base-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.375rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  text-decoration: none;
  
  &:focus {
    outline: none;
    ring: 2px;
    ring-offset: 2px;
  }
  
  // Variants
  &--primary {
    background-color: var(--color-primary);
    color: white;
    
    &:hover:not(.button--disabled) {
      background-color: var(--color-primary-dark);
    }
  }
  
  &--secondary {
    background-color: var(--color-secondary);
    color: white;
    
    &:hover:not(.button--disabled) {
      background-color: var(--color-secondary-dark);
    }
  }
  
  &--danger {
    background-color: var(--color-danger);
    color: white;
    
    &:hover:not(.button--disabled) {
      background-color: var(--color-danger-dark);
    }
  }
  
  &--ghost {
    background-color: transparent;
    color: var(--color-primary);
    border: 1px solid currentColor;
    
    &:hover:not(.button--disabled) {
      background-color: var(--color-primary-light);
    }
  }
  
  // Sizes
  &--small {
    padding: 0.5rem 1rem;
    font-size: 0.875rem;
  }
  
  &--large {
    padding: 1rem 2rem;
    font-size: 1.125rem;
  }
  
  // States
  &--disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  &--loading {
    cursor: wait;
  }
  
  &--full-width {
    width: 100%;
  }
}

.button-loader {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
</style>
```

### 6. Testing

```javascript
// tests/unit/components/BaseButton.spec.js
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import BaseButton from '@/components/common/BaseButton.vue'

describe('BaseButton', () => {
  it('renders properly', () => {
    const wrapper = mount(BaseButton, {
      props: {
        label: 'Click me'
      }
    })
    
    expect(wrapper.text()).toContain('Click me')
    expect(wrapper.classes()).toContain('button--primary')
  })
  
  it('emits click event when clicked', async () => {
    const wrapper = mount(BaseButton)
    
    await wrapper.trigger('click')
    
    expect(wrapper.emitted()).toHaveProperty('click')
    expect(wrapper.emitted('click')).toHaveLength(1)
  })
  
  it('does not emit click when disabled', async () => {
    const wrapper = mount(BaseButton, {
      props: {
        disabled: true
      }
    })
    
    await wrapper.trigger('click')
    
    expect(wrapper.emitted('click')).toBeUndefined()
  })
  
  it('shows loading state', () => {
    const wrapper = mount(BaseButton, {
      props: {
        loading: true
      }
    })
    
    expect(wrapper.find('.button-loader').exists()).toBe(true)
    expect(wrapper.classes()).toContain('button--loading')
  })
})

// tests/unit/stores/auth.spec.js
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'
import { vi } from 'vitest'

describe('Auth Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })
  
  it('logs in user successfully', async () => {
    const authStore = useAuthStore()
    const mockUser = { id: 1, name: 'John Doe', email: 'john@example.com' }
    
    // Mock API call
    vi.spyOn(authService, 'login').mockResolvedValue({
      data: {
        user: mockUser,
        token: 'fake-token',
        refreshToken: 'fake-refresh-token'
      }
    })
    
    await authStore.login({ email: 'john@example.com', password: 'password' })
    
    expect(authStore.user).toEqual(mockUser)
    expect(authStore.token).toBe('fake-token')
    expect(authStore.isAuthenticated).toBe(true)
  })
})
```

### Common Pitfalls to Avoid

1. **Not using key with v-for**
2. **Mutating props directly**
3. **Using index as key in dynamic lists**
4. **Not cleaning up watchers and event listeners**
5. **Overusing watchers instead of computed**
6. **Not using component lazy loading**
7. **Inline styles and classes instead of computed**
8. **Not handling async errors properly**
9. **Memory leaks from event listeners**
10. **Not using TypeScript for large projects**

### Useful Libraries

- **Vite**: Build tool
- **Pinia**: State management
- **Vue Router**: Routing
- **VueUse**: Composition utilities
- **Vee-Validate**: Form validation
- **Vue I18n**: Internationalization
- **Vitest**: Unit testing
- **@vue/test-utils**: Component testing
- **Vuetify/Quasar**: UI frameworks
- **TanStack Query**: Data fetching
- **Axios**: HTTP client
- **date-fns**: Date manipulation