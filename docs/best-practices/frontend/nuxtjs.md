# Nuxt.js + Pinia Best Practices

## Official Documentation
- **Nuxt.js Documentation**: https://nuxt.com/docs
- **Nuxt Examples**: https://nuxt.com/docs/examples
- **Pinia Documentation**: https://pinia.vuejs.org
- **Vue 3 Documentation**: https://vuejs.org/guide

## Project Structure

```
project-root/
├── assets/
│   ├── css/
│   │   ├── main.css
│   │   └── components.css
│   ├── images/
│   └── fonts/
├── components/
│   ├── ui/
│   │   ├── Button.vue
│   │   ├── Card.vue
│   │   └── Modal.vue
│   ├── forms/
│   │   ├── LoginForm.vue
│   │   └── ContactForm.vue
│   └── layout/
│       ├── Header.vue
│       ├── Footer.vue
│       └── Sidebar.vue
├── composables/
│   ├── useAuth.ts
│   ├── useFetch.ts
│   └── useValidation.ts
├── layouts/
│   ├── default.vue
│   ├── auth.vue
│   └── dashboard.vue
├── middleware/
│   ├── auth.ts
│   ├── guest.ts
│   └── admin.ts
├── pages/
│   ├── index.vue
│   ├── about.vue
│   ├── login.vue
│   ├── dashboard/
│   │   ├── index.vue
│   │   └── profile.vue
│   └── blog/
│       ├── index.vue
│       └── [slug].vue
├── plugins/
│   ├── api.client.ts
│   ├── toast.client.ts
│   └── dayjs.ts
├── server/
│   └── api/
│       ├── auth/
│       │   ├── login.post.ts
│       │   └── logout.post.ts
│       └── users/
│           ├── index.get.ts
│           └── [id].get.ts
├── stores/
│   ├── auth.ts
│   ├── user.ts
│   └── products.ts
├── types/
│   ├── api.ts
│   ├── user.ts
│   └── global.d.ts
├── utils/
│   ├── helpers.ts
│   ├── validators.ts
│   └── constants.ts
├── .env
├── nuxt.config.ts
└── package.json
```

## Core Best Practices

### 1. Nuxt Configuration

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  devtools: { enabled: true },
  
  // CSS frameworks
  css: ['~/assets/css/main.css'],
  
  // Modules
  modules: [
    '@pinia/nuxt',
    '@nuxtjs/tailwindcss',
    '@vueuse/nuxt',
    '@nuxt/image',
    '@nuxtjs/color-mode',
  ],
  
  // Runtime config
  runtimeConfig: {
    // Private keys (only available on server-side)
    apiSecret: process.env.API_SECRET,
    
    // Public keys (exposed to client-side)
    public: {
      apiBase: process.env.API_BASE || 'http://localhost:3001',
      appName: 'My Nuxt App',
    }
  },
  
  // App configuration
  app: {
    head: {
      title: 'My Nuxt App',
      titleTemplate: '%s - My Nuxt App',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'My amazing Nuxt application' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
      ]
    }
  },
  
  // Build optimization
  build: {
    transpile: ['@headlessui/vue']
  },
  
  // Vite configuration
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: '@use "~/assets/scss/_vars.scss" as *;'
        }
      }
    }
  }
})
```

### 2. Pinia Store Pattern

```typescript
// stores/auth.ts
import { defineStore } from 'pinia'

interface User {
  id: string
  name: string
  email: string
  role: string
}

interface AuthState {
  user: User | null
  token: string | null
  loading: boolean
  error: string | null
}

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({
    user: null,
    token: null,
    loading: false,
    error: null,
  }),

  getters: {
    isLoggedIn: (state): boolean => !!state.token,
    isAdmin: (state): boolean => state.user?.role === 'admin',
    userName: (state): string => state.user?.name || 'Guest',
  },

  actions: {
    async login(credentials: { email: string; password: string }) {
      this.loading = true
      this.error = null

      try {
        const { data } = await $fetch<{ user: User; token: string }>('/api/auth/login', {
          method: 'POST',
          body: credentials,
        })

        this.user = data.user
        this.token = data.token

        // Store in cookie for SSR
        const tokenCookie = useCookie('auth-token', {
          httpOnly: true,
          secure: true,
          maxAge: 60 * 60 * 24 * 7, // 7 days
        })
        tokenCookie.value = data.token

        await navigateTo('/dashboard')
      } catch (error: any) {
        this.error = error.data?.message || 'Login failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async logout() {
      try {
        await $fetch('/api/auth/logout', { method: 'POST' })
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        this.user = null
        this.token = null
        
        const tokenCookie = useCookie('auth-token')
        tokenCookie.value = null
        
        await navigateTo('/login')
      }
    },

    async fetchUser() {
      if (!this.token) return

      try {
        this.user = await $fetch<User>('/api/auth/me', {
          headers: {
            Authorization: `Bearer ${this.token}`,
          },
        })
      } catch (error) {
        this.logout()
      }
    },

    // Persist state on page reload
    async initializeAuth() {
      const tokenCookie = useCookie('auth-token')
      
      if (tokenCookie.value) {
        this.token = tokenCookie.value
        await this.fetchUser()
      }
    },
  },

  // Persist state
  persist: {
    storage: persistedState.localStorage,
  },
})

// stores/products.ts
export const useProductsStore = defineStore('products', {
  state: () => ({
    products: [] as Product[],
    loading: false,
    filters: {
      category: '',
      priceRange: [0, 1000],
      search: '',
    },
  }),

  getters: {
    filteredProducts: (state) => {
      return state.products.filter(product => {
        const matchesCategory = !state.filters.category || 
          product.category === state.filters.category
        
        const matchesPrice = product.price >= state.filters.priceRange[0] &&
          product.price <= state.filters.priceRange[1]
        
        const matchesSearch = !state.filters.search ||
          product.name.toLowerCase().includes(state.filters.search.toLowerCase())

        return matchesCategory && matchesPrice && matchesSearch
      })
    },

    productsByCategory: (state) => {
      return (category: string) => 
        state.products.filter(product => product.category === category)
    },
  },

  actions: {
    async fetchProducts() {
      this.loading = true
      try {
        this.products = await $fetch<Product[]>('/api/products')
      } catch (error) {
        throw createError({
          statusCode: 500,
          statusMessage: 'Failed to fetch products',
        })
      } finally {
        this.loading = false
      }
    },

    updateFilters(newFilters: Partial<typeof this.filters>) {
      Object.assign(this.filters, newFilters)
    },

    resetFilters() {
      this.filters = {
        category: '',
        priceRange: [0, 1000],
        search: '',
      }
    },
  },
})
```

### 3. Composables Pattern

```typescript
// composables/useAuth.ts
export const useAuth = () => {
  const authStore = useAuthStore()
  
  const user = computed(() => authStore.user)
  const isLoggedIn = computed(() => authStore.isLoggedIn)
  const loading = computed(() => authStore.loading)

  const login = async (credentials: LoginCredentials) => {
    return await authStore.login(credentials)
  }

  const logout = async () => {
    return await authStore.logout()
  }

  // Auto-initialize on composable use
  onMounted(async () => {
    if (!authStore.user && process.client) {
      await authStore.initializeAuth()
    }
  })

  return {
    user: readonly(user),
    isLoggedIn: readonly(isLoggedIn),
    loading: readonly(loading),
    login,
    logout,
  }
}

// composables/useApi.ts
export const useApi = () => {
  const config = useRuntimeConfig()

  const api = $fetch.create({
    baseURL: config.public.apiBase,
    onRequest({ request, options }) {
      const authStore = useAuthStore()
      
      if (authStore.token) {
        options.headers = {
          ...options.headers,
          Authorization: `Bearer ${authStore.token}`,
        }
      }
    },
    onResponseError({ response }) {
      if (response.status === 401) {
        const authStore = useAuthStore()
        authStore.logout()
      }
    },
  })

  return { api }
}

// composables/useValidation.ts
export const useValidation = () => {
  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  const validatePassword = (password: string): {
    isValid: boolean
    errors: string[]
  } => {
    const errors: string[] = []
    
    if (password.length < 8) {
      errors.push('Password must be at least 8 characters long')
    }
    
    if (!/(?=.*[a-z])/.test(password)) {
      errors.push('Password must contain at least one lowercase letter')
    }
    
    if (!/(?=.*[A-Z])/.test(password)) {
      errors.push('Password must contain at least one uppercase letter')
    }
    
    if (!/(?=.*\d)/.test(password)) {
      errors.push('Password must contain at least one number')
    }

    return {
      isValid: errors.length === 0,
      errors,
    }
  }

  const validateRequired = (value: any, fieldName: string): string | null => {
    if (!value || (typeof value === 'string' && !value.trim())) {
      return `${fieldName} is required`
    }
    return null
  }

  return {
    validateEmail,
    validatePassword,
    validateRequired,
  }
}
```

### 4. Page and Layout Components

```vue
<!-- layouts/default.vue -->
<template>
  <div class="min-h-screen bg-gray-50">
    <AppHeader />
    
    <main class="container mx-auto px-4 py-8">
      <slot />
    </main>
    
    <AppFooter />
    
    <!-- Global notifications -->
    <AppNotifications />
  </div>
</template>

<script setup lang="ts">
// Auto-import navigation guards
definePageMeta({
  layout: 'default',
})

// SEO and meta
useSeoMeta({
  ogImage: '/og-image.jpg',
  twitterCard: 'summary_large_image',
})
</script>

<!-- pages/index.vue -->
<template>
  <div>
    <Hero />
    
    <section class="py-16">
      <div class="container mx-auto">
        <h2 class="text-3xl font-bold text-center mb-12">
          Featured Products
        </h2>
        
        <ProductGrid 
          :products="featuredProducts" 
          :loading="loading" 
        />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const { data: featuredProducts, pending: loading } = await useFetch<Product[]>('/api/products/featured', {
  key: 'featured-products',
  server: true,
  default: () => [],
})

// SEO
useSeoMeta({
  title: 'Home',
  description: 'Welcome to our amazing store with the best products',
})

// Structured data
useSchemaOrg([
  defineWebSite({
    name: 'My Store',
    url: 'https://mystore.com',
  }),
])
</script>

<!-- pages/products/[slug].vue -->
<template>
  <div v-if="pending" class="flex justify-center py-16">
    <LoadingSpinner />
  </div>
  
  <div v-else-if="error" class="text-center py-16">
    <h1 class="text-2xl font-bold text-red-600 mb-4">
      Product Not Found
    </h1>
    <NuxtLink to="/products" class="btn btn-primary">
      Back to Products
    </NuxtLink>
  </div>
  
  <article v-else class="max-w-6xl mx-auto">
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-12">
      <div>
        <NuxtImg 
          :src="product.image" 
          :alt="product.name"
          class="w-full h-96 object-cover rounded-lg"
          loading="eager"
          preload
        />
      </div>
      
      <div>
        <h1 class="text-4xl font-bold mb-4">{{ product.name }}</h1>
        <p class="text-2xl font-semibold text-green-600 mb-6">
          ${{ product.price }}
        </p>
        
        <div class="prose mb-8" v-html="product.description" />
        
        <AddToCartButton :product="product" />
      </div>
    </div>
  </article>
</template>

<script setup lang="ts">
const route = useRoute()

const { data: product, pending, error } = await useFetch<Product>(`/api/products/${route.params.slug}`, {
  key: `product-${route.params.slug}`,
})

// Handle 404
if (error.value) {
  throw createError({
    statusCode: 404,
    statusMessage: 'Product not found',
  })
}

// SEO with dynamic data
useSeoMeta({
  title: () => product.value?.name,
  description: () => product.value?.shortDescription,
  ogImage: () => product.value?.image,
})

// Structured data for product
useSchemaOrg([
  defineProduct({
    name: () => product.value?.name,
    image: () => product.value?.image,
    description: () => product.value?.description,
    offers: {
      '@type': 'Offer',
      price: () => product.value?.price,
      priceCurrency: 'USD',
      availability: 'https://schema.org/InStock',
    },
  }),
])
</script>
```

### 5. Server API Routes

```typescript
// server/api/auth/login.post.ts
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'

export default defineEventHandler(async (event) => {
  const { email, password } = await readBody(event)
  
  // Validate input
  if (!email || !password) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Email and password are required',
    })
  }

  try {
    // Find user (replace with your database logic)
    const user = await findUserByEmail(email)
    
    if (!user || !await bcrypt.compare(password, user.password)) {
      throw createError({
        statusCode: 401,
        statusMessage: 'Invalid credentials',
      })
    }

    // Generate JWT token
    const config = useRuntimeConfig()
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      config.apiSecret,
      { expiresIn: '7d' }
    )

    // Set secure HTTP-only cookie
    setCookie(event, 'auth-token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7, // 7 days
      sameSite: 'lax',
    })

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
      token,
    }
  } catch (error) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Authentication failed',
    })
  }
})

// server/api/products/index.get.ts
export default defineEventHandler(async (event) => {
  const query = getQuery(event)
  const { page = 1, limit = 20, category, search } = query

  try {
    const products = await getProducts({
      page: Number(page),
      limit: Number(limit),
      category: category as string,
      search: search as string,
    })

    return {
      data: products.data,
      meta: {
        total: products.total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(products.total / Number(limit)),
      },
    }
  } catch (error) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to fetch products',
    })
  }
})

// server/api/products/[id].get.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  
  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Product ID is required',
    })
  }

  try {
    const product = await getProductById(id)
    
    if (!product) {
      throw createError({
        statusCode: 404,
        statusMessage: 'Product not found',
      })
    }

    return product
  } catch (error) {
    if (error.statusCode === 404) {
      throw error
    }
    
    throw createError({
      statusCode: 500,
      statusMessage: 'Failed to fetch product',
    })
  }
})
```

### 6. Middleware

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to) => {
  const { isLoggedIn } = useAuth()
  
  if (!isLoggedIn.value) {
    return navigateTo('/login')
  }
})

// middleware/guest.ts
export default defineNuxtRouteMiddleware(() => {
  const { isLoggedIn } = useAuth()
  
  if (isLoggedIn.value) {
    return navigateTo('/dashboard')
  }
})

// middleware/admin.ts
export default defineNuxtRouteMiddleware(() => {
  const authStore = useAuthStore()
  
  if (!authStore.isAdmin) {
    throw createError({
      statusCode: 403,
      statusMessage: 'Admin access required',
    })
  }
})
```

### 7. Component Examples

```vue
<!-- components/ui/Button.vue -->
<template>
  <button 
    :class="buttonClasses"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <LoadingSpinner v-if="loading" class="w-4 h-4 mr-2" />
    <slot />
  </button>
</template>

<script setup lang="ts">
interface Props {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
  loading: false,
})

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()

const buttonClasses = computed(() => {
  const baseClasses = 'inline-flex items-center justify-center font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2'
  
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
  }
  
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  }
  
  const disabledClasses = props.disabled || props.loading ? 'opacity-50 cursor-not-allowed' : ''
  
  return [
    baseClasses,
    variantClasses[props.variant],
    sizeClasses[props.size],
    disabledClasses,
  ].join(' ')
})

const handleClick = (event: MouseEvent) => {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}
</script>

<!-- components/forms/ContactForm.vue -->
<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <div>
      <label for="name" class="block text-sm font-medium text-gray-700">
        Name
      </label>
      <input
        id="name"
        v-model="form.name"
        type="text"
        required
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        :class="{ 'border-red-500': errors.name }"
      >
      <p v-if="errors.name" class="mt-1 text-sm text-red-600">
        {{ errors.name }}
      </p>
    </div>

    <div>
      <label for="email" class="block text-sm font-medium text-gray-700">
        Email
      </label>
      <input
        id="email"
        v-model="form.email"
        type="email"
        required
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        :class="{ 'border-red-500': errors.email }"
      >
      <p v-if="errors.email" class="mt-1 text-sm text-red-600">
        {{ errors.email }}
      </p>
    </div>

    <div>
      <label for="message" class="block text-sm font-medium text-gray-700">
        Message
      </label>
      <textarea
        id="message"
        v-model="form.message"
        rows="4"
        required
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
        :class="{ 'border-red-500': errors.message }"
      />
      <p v-if="errors.message" class="mt-1 text-sm text-red-600">
        {{ errors.message }}
      </p>
    </div>

    <Button 
      type="submit" 
      :loading="pending"
      class="w-full"
    >
      Send Message
    </Button>
  </form>
</template>

<script setup lang="ts">
const form = reactive({
  name: '',
  email: '',
  message: '',
})

const errors = reactive({
  name: '',
  email: '',
  message: '',
})

const { pending, execute } = await useLazyFetch('/api/contact', {
  method: 'POST',
  body: form,
  immediate: false,
})

const { validateRequired, validateEmail } = useValidation()

const validateForm = (): boolean => {
  let isValid = true
  
  // Reset errors
  Object.keys(errors).forEach(key => {
    errors[key as keyof typeof errors] = ''
  })
  
  // Validate name
  const nameError = validateRequired(form.name, 'Name')
  if (nameError) {
    errors.name = nameError
    isValid = false
  }
  
  // Validate email
  const emailError = validateRequired(form.email, 'Email')
  if (emailError) {
    errors.email = emailError
    isValid = false
  } else if (!validateEmail(form.email)) {
    errors.email = 'Please enter a valid email address'
    isValid = false
  }
  
  // Validate message
  const messageError = validateRequired(form.message, 'Message')
  if (messageError) {
    errors.message = messageError
    isValid = false
  }
  
  return isValid
}

const handleSubmit = async () => {
  if (!validateForm()) return
  
  try {
    await execute()
    
    // Show success message
    useNuxtApp().$toast.success('Message sent successfully!')
    
    // Reset form
    Object.assign(form, {
      name: '',
      email: '',
      message: '',
    })
  } catch (error) {
    useNuxtApp().$toast.error('Failed to send message. Please try again.')
  }
}
</script>
```

### Common Pitfalls to Avoid

1. **Not using server-side rendering when beneficial**
2. **Forgetting to handle loading and error states**
3. **Not implementing proper SEO meta tags**
4. **Overusing client-side data fetching**
5. **Not leveraging Nuxt's auto-imports**
6. **Ignoring performance optimization**
7. **Not using TypeScript effectively**
8. **Poor store organization**
9. **Not implementing proper error handling**
10. **Mixing server and client logic incorrectly**

### Performance Tips

1. **Use server-side rendering for initial page loads**
2. **Implement lazy loading for components**
3. **Optimize images with Nuxt Image**
4. **Use proper caching strategies**
5. **Implement code splitting**
6. **Minimize bundle size**
7. **Use prefetching for critical routes**
8. **Optimize database queries**
9. **Implement proper loading states**
10. **Monitor Core Web Vitals**

### Useful Libraries

- **@pinia/nuxt**: State management
- **@vueuse/nuxt**: Composition utilities
- **@nuxtjs/tailwindcss**: Utility-first CSS
- **@nuxt/image**: Image optimization
- **@nuxtjs/color-mode**: Dark/light mode
- **@nuxtjs/i18n**: Internationalization
- **@nuxtjs/google-fonts**: Font optimization
- **@nuxt/content**: Content management
- **nuxt-security**: Security headers
- **@nuxtjs/robots**: SEO robots.txt