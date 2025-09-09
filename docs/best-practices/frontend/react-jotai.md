# React + Jotai Best Practices

## Official Documentation
- **React Documentation**: https://react.dev
- **Jotai Documentation**: https://jotai.org
- **Jotai Examples**: https://github.com/pmndrs/jotai/tree/main/examples
- **React TypeScript**: https://react-typescript-cheatsheet.netlify.app

## Project Structure

```
react-jotai-app/
├── src/
│   ├── atoms/
│   │   ├── auth.ts
│   │   ├── posts.ts
│   │   ├── ui.ts
│   │   └── index.ts
│   ├── components/
│   │   ├── ui/
│   │   │   ├── Button.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── LoadingSpinner.tsx
│   │   ├── forms/
│   │   │   ├── LoginForm.tsx
│   │   │   └── PostForm.tsx
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Layout.tsx
│   │   └── features/
│   │       ├── auth/
│   │       ├── posts/
│   │       └── dashboard/
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   └── usePosts.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── auth.service.ts
│   │   └── storage.service.ts
│   ├── types/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   └── post.ts
│   ├── utils/
│   │   ├── helpers.ts
│   │   └── constants.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── package.json
└── tsconfig.json
```

## Core Best Practices

### 1. Atom Organization and Structure

```typescript
// atoms/index.ts - Central atom registry
export * from './auth'
export * from './posts'
export * from './ui'

// atoms/auth.ts
import { atom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'user'
  avatar?: string
}

export interface AuthState {
  user: User | null
  isAuthenticated: boolean
  loading: boolean
  error: string | null
}

// Base auth atom with storage persistence
const authStorageAtom = atomWithStorage<AuthState>('auth', {
  user: null,
  isAuthenticated: false,
  loading: false,
  error: null,
})

// Derived atoms for specific auth properties
export const userAtom = atom(
  (get) => get(authStorageAtom).user,
  (get, set, user: User | null) => {
    const currentAuth = get(authStorageAtom)
    set(authStorageAtom, {
      ...currentAuth,
      user,
      isAuthenticated: !!user,
    })
  }
)

export const isAuthenticatedAtom = atom(
  (get) => get(authStorageAtom).isAuthenticated
)

export const authLoadingAtom = atom(
  (get) => get(authStorageAtom).loading,
  (get, set, loading: boolean) => {
    const currentAuth = get(authStorageAtom)
    set(authStorageAtom, {
      ...currentAuth,
      loading,
    })
  }
)

export const authErrorAtom = atom(
  (get) => get(authStorageAtom).error,
  (get, set, error: string | null) => {
    const currentAuth = get(authStorageAtom)
    set(authStorageAtom, {
      ...currentAuth,
      error,
    })
  }
)

// Action atoms for auth operations
export const loginAtom = atom(
  null,
  async (get, set, credentials: { email: string; password: string }) => {
    set(authLoadingAtom, true)
    set(authErrorAtom, null)
    
    try {
      const response = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials),
      })

      if (!response.ok) {
        throw new Error('Login failed')
      }

      const { user, token } = await response.json()
      
      // Store token in localStorage
      localStorage.setItem('token', token)
      
      // Update user atom
      set(userAtom, user)
    } catch (error) {
      set(authErrorAtom, error instanceof Error ? error.message : 'Login failed')
    } finally {
      set(authLoadingAtom, false)
    }
  }
)

export const logoutAtom = atom(null, async (get, set) => {
  set(authLoadingAtom, true)
  
  try {
    await fetch('/api/logout', { method: 'POST' })
    
    // Clear storage
    localStorage.removeItem('token')
    
    // Reset auth state
    set(userAtom, null)
  } catch (error) {
    console.error('Logout error:', error)
  } finally {
    set(authLoadingAtom, false)
  }
})

// atoms/posts.ts
import { atom } from 'jotai'
import { atomWithReset, loadable } from 'jotai/utils'

export interface Post {
  id: string
  title: string
  content: string
  excerpt: string
  authorId: string
  status: 'draft' | 'published'
  createdAt: string
  updatedAt: string
}

// Posts state atoms
export const postsAtom = atom<Post[]>([])
export const postsLoadingAtom = atom(false)
export const postsErrorAtom = atomWithReset<string | null>(null)

// Filter and search atoms
export const postSearchAtom = atom('')
export const postStatusFilterAtom = atom<'all' | 'published' | 'draft'>('all')

// Derived atoms
export const filteredPostsAtom = atom((get) => {
  const posts = get(postsAtom)
  const search = get(postSearchAtom).toLowerCase()
  const statusFilter = get(postStatusFilterAtom)
  
  return posts.filter(post => {
    const matchesSearch = search === '' || 
      post.title.toLowerCase().includes(search) ||
      post.content.toLowerCase().includes(search)
    
    const matchesStatus = statusFilter === 'all' || post.status === statusFilter
    
    return matchesSearch && matchesStatus
  })
})

export const postCountsAtom = atom((get) => {
  const posts = get(postsAtom)
  
  return {
    total: posts.length,
    published: posts.filter(p => p.status === 'published').length,
    draft: posts.filter(p => p.status === 'draft').length,
  }
})

// Async atoms for data fetching
export const fetchPostsAtom = atom(
  null,
  async (get, set) => {
    set(postsLoadingAtom, true)
    set(postsErrorAtom, null)
    
    try {
      const response = await fetch('/api/posts', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
      })

      if (!response.ok) {
        throw new Error('Failed to fetch posts')
      }

      const posts = await response.json()
      set(postsAtom, posts)
    } catch (error) {
      set(postsErrorAtom, error instanceof Error ? error.message : 'Failed to fetch posts')
    } finally {
      set(postsLoadingAtom, false)
    }
  }
)

export const createPostAtom = atom(
  null,
  async (get, set, newPost: Omit<Post, 'id' | 'createdAt' | 'updatedAt'>) => {
    set(postsLoadingAtom, true)
    
    try {
      const response = await fetch('/api/posts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
        },
        body: JSON.stringify(newPost),
      })

      if (!response.ok) {
        throw new Error('Failed to create post')
      }

      const createdPost = await response.json()
      const currentPosts = get(postsAtom)
      set(postsAtom, [createdPost, ...currentPosts])
      
      return createdPost
    } catch (error) {
      set(postsErrorAtom, error instanceof Error ? error.message : 'Failed to create post')
      throw error
    } finally {
      set(postsLoadingAtom, false)
    }
  }
)

// Loadable atom for automatic loading states
export const postsLoadableAtom = loadable(
  atom(async (get) => {
    const response = await fetch('/api/posts')
    if (!response.ok) throw new Error('Failed to fetch posts')
    return response.json()
  })
)

// atoms/ui.ts
import { atom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

export interface ToastMessage {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  duration?: number
}

export interface ModalState {
  isOpen: boolean
  title?: string
  content?: React.ReactNode
}

// UI state atoms
export const sidebarOpenAtom = atomWithStorage('sidebar-open', true)
export const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light')
export const toastsAtom = atom<ToastMessage[]>([])
export const modalAtom = atom<ModalState>({ isOpen: false })

// Toast actions
export const addToastAtom = atom(
  null,
  (get, set, toast: Omit<ToastMessage, 'id'>) => {
    const id = Date.now().toString()
    const newToast: ToastMessage = { ...toast, id }
    const currentToasts = get(toastsAtom)
    
    set(toastsAtom, [...currentToasts, newToast])
    
    // Auto-remove toast after duration
    setTimeout(() => {
      set(removeToastAtom, id)
    }, toast.duration || 5000)
  }
)

export const removeToastAtom = atom(
  null,
  (get, set, id: string) => {
    const currentToasts = get(toastsAtom)
    set(toastsAtom, currentToasts.filter(toast => toast.id !== id))
  }
)

// Modal actions
export const openModalAtom = atom(
  null,
  (get, set, modal: Omit<ModalState, 'isOpen'>) => {
    set(modalAtom, { ...modal, isOpen: true })
  }
)

export const closeModalAtom = atom(
  null,
  (get, set) => {
    set(modalAtom, { isOpen: false })
  }
)
```

### 2. Custom Hooks with Jotai

```typescript
// hooks/useAuth.ts
import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import { userAtom, loginAtom, logoutAtom, authLoadingAtom, authErrorAtom } from '@/atoms/auth'

export const useAuth = () => {
  const user = useAtomValue(userAtom)
  const loading = useAtomValue(authLoadingAtom)
  const error = useAtomValue(authErrorAtom)
  
  const login = useSetAtom(loginAtom)
  const logout = useSetAtom(logoutAtom)

  return {
    user,
    loading,
    error,
    login,
    logout,
    isAuthenticated: !!user,
  }
}

// hooks/usePosts.ts
import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import {
  postsAtom,
  filteredPostsAtom,
  postSearchAtom,
  postStatusFilterAtom,
  postsLoadingAtom,
  postsErrorAtom,
  fetchPostsAtom,
  createPostAtom,
  postCountsAtom,
} from '@/atoms/posts'

export const usePosts = () => {
  const posts = useAtomValue(filteredPostsAtom)
  const allPosts = useAtomValue(postsAtom)
  const loading = useAtomValue(postsLoadingAtom)
  const error = useAtomValue(postsErrorAtom)
  const counts = useAtomValue(postCountsAtom)
  
  const [search, setSearch] = useAtom(postSearchAtom)
  const [statusFilter, setStatusFilter] = useAtom(postStatusFilterAtom)
  
  const fetchPosts = useSetAtom(fetchPostsAtom)
  const createPost = useSetAtom(createPostAtom)

  const updatePost = useSetAtom(
    atom(null, async (get, set, { id, updates }: { id: string; updates: Partial<Post> }) => {
      set(postsLoadingAtom, true)
      
      try {
        const response = await fetch(`/api/posts/${id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
          body: JSON.stringify(updates),
        })

        if (!response.ok) throw new Error('Failed to update post')

        const updatedPost = await response.json()
        const currentPosts = get(postsAtom)
        const updatedPosts = currentPosts.map(post => 
          post.id === id ? updatedPost : post
        )
        
        set(postsAtom, updatedPosts)
        return updatedPost
      } catch (error) {
        set(postsErrorAtom, error instanceof Error ? error.message : 'Failed to update post')
        throw error
      } finally {
        set(postsLoadingAtom, false)
      }
    })
  )

  const deletePost = useSetAtom(
    atom(null, async (get, set, id: string) => {
      set(postsLoadingAtom, true)
      
      try {
        const response = await fetch(`/api/posts/${id}`, {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
          },
        })

        if (!response.ok) throw new Error('Failed to delete post')

        const currentPosts = get(postsAtom)
        set(postsAtom, currentPosts.filter(post => post.id !== id))
      } catch (error) {
        set(postsErrorAtom, error instanceof Error ? error.message : 'Failed to delete post')
        throw error
      } finally {
        set(postsLoadingAtom, false)
      }
    })
  )

  return {
    posts,
    allPosts,
    loading,
    error,
    counts,
    search,
    setSearch,
    statusFilter,
    setStatusFilter,
    fetchPosts,
    createPost,
    updatePost,
    deletePost,
  }
}

// hooks/useToast.ts
import { useSetAtom } from 'jotai'
import { addToastAtom, removeToastAtom } from '@/atoms/ui'

export const useToast = () => {
  const addToast = useSetAtom(addToastAtom)
  const removeToast = useSetAtom(removeToastAtom)

  const toast = {
    success: (message: string, duration?: number) =>
      addToast({ type: 'success', message, duration }),
    
    error: (message: string, duration?: number) =>
      addToast({ type: 'error', message, duration }),
    
    warning: (message: string, duration?: number) =>
      addToast({ type: 'warning', message, duration }),
    
    info: (message: string, duration?: number) =>
      addToast({ type: 'info', message, duration }),
  }

  return { toast, removeToast }
}
```

### 3. Component Examples

```tsx
// components/auth/LoginForm.tsx
import { useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { useToast } from '@/hooks/useToast'

export const LoginForm = () => {
  const [formData, setFormData] = useState({ email: '', password: '' })
  const { login, loading, error } = useAuth()
  const { toast } = useToast()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    try {
      await login(formData)
      toast.success('Logged in successfully!')
    } catch (error) {
      toast.error('Login failed. Please try again.')
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value,
    }))
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 max-w-md mx-auto">
      <div>
        <label htmlFor="email" className="block text-sm font-medium mb-1">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          value={formData.email}
          onChange={handleChange}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium mb-1">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          required
          value={formData.password}
          onChange={handleChange}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>

      {error && (
        <p className="text-red-600 text-sm">{error}</p>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? 'Signing In...' : 'Sign In'}
      </button>
    </form>
  )
}

// components/posts/PostList.tsx
import { useEffect } from 'react'
import { usePosts } from '@/hooks/usePosts'
import { PostCard } from './PostCard'
import { PostFilters } from './PostFilters'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export const PostList = () => {
  const { posts, loading, error, fetchPosts } = usePosts()

  useEffect(() => {
    fetchPosts()
  }, [fetchPosts])

  if (loading && posts.length === 0) {
    return (
      <div className="flex justify-center py-8">
        <LoadingSpinner />
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-red-600 mb-4">Error: {error}</p>
        <button
          onClick={() => fetchPosts()}
          className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PostFilters />
      
      {posts.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-gray-500">No posts found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {posts.map(post => (
            <PostCard key={post.id} post={post} />
          ))}
        </div>
      )}
    </div>
  )
}

// components/posts/PostFilters.tsx
import { usePosts } from '@/hooks/usePosts'

export const PostFilters = () => {
  const { search, setSearch, statusFilter, setStatusFilter, counts } = usePosts()

  return (
    <div className="flex flex-col sm:flex-row gap-4 mb-6">
      <div className="flex-1">
        <input
          type="text"
          placeholder="Search posts..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      
      <div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as any)}
          className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">All Posts ({counts.total})</option>
          <option value="published">Published ({counts.published})</option>
          <option value="draft">Draft ({counts.draft})</option>
        </select>
      </div>
    </div>
  )
}

// components/ui/Toast.tsx
import { useAtomValue, useSetAtom } from 'jotai'
import { toastsAtom, removeToastAtom } from '@/atoms/ui'

export const ToastContainer = () => {
  const toasts = useAtomValue(toastsAtom)
  const removeToast = useSetAtom(removeToastAtom)

  if (toasts.length === 0) return null

  return (
    <div className="fixed top-4 right-4 space-y-2 z-50">
      {toasts.map(toast => (
        <div
          key={toast.id}
          className={`
            p-4 rounded-md shadow-lg max-w-sm
            ${toast.type === 'success' ? 'bg-green-500 text-white' : ''}
            ${toast.type === 'error' ? 'bg-red-500 text-white' : ''}
            ${toast.type === 'warning' ? 'bg-yellow-500 text-white' : ''}
            ${toast.type === 'info' ? 'bg-blue-500 text-white' : ''}
          `}
        >
          <div className="flex justify-between items-center">
            <span>{toast.message}</span>
            <button
              onClick={() => removeToast(toast.id)}
              className="ml-2 text-white hover:text-gray-200"
            >
              ×
            </button>
          </div>
        </div>
      ))}
    </div>
  )
}
```

### 4. Advanced Patterns

```typescript
// Atom families for dynamic collections
import { atomFamily } from 'jotai/utils'

export const postAtomFamily = atomFamily((id: string) =>
  atom(
    async (get) => {
      const response = await fetch(`/api/posts/${id}`)
      if (!response.ok) throw new Error('Failed to fetch post')
      return response.json()
    }
  )
)

// Using atom families in components
const PostDetail = ({ id }: { id: string }) => {
  const postAtom = useMemo(() => postAtomFamily(id), [id])
  const post = useAtomValue(postAtom)
  
  return <div>{post.title}</div>
}

// Optimistic updates pattern
const optimisticUpdateAtom = atom(
  null,
  async (get, set, { id, updates }: { id: string; updates: Partial<Post> }) => {
    const currentPosts = get(postsAtom)
    
    // Optimistically update the UI
    const optimisticPosts = currentPosts.map(post =>
      post.id === id ? { ...post, ...updates } : post
    )
    set(postsAtom, optimisticPosts)

    try {
      // Make the API call
      const response = await fetch(`/api/posts/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      })

      if (!response.ok) throw new Error('Update failed')

      const updatedPost = await response.json()
      
      // Update with the actual response
      const finalPosts = currentPosts.map(post =>
        post.id === id ? updatedPost : post
      )
      set(postsAtom, finalPosts)
      
    } catch (error) {
      // Revert optimistic update on error
      set(postsAtom, currentPosts)
      throw error
    }
  }
)

// Derived atoms with complex logic
const dashboardStatsAtom = atom((get) => {
  const posts = get(postsAtom)
  const user = get(userAtom)
  
  if (!user) return null

  const userPosts = posts.filter(post => post.authorId === user.id)
  const publishedCount = userPosts.filter(post => post.status === 'published').length
  const draftCount = userPosts.filter(post => post.status === 'draft').length
  
  const today = new Date()
  const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)
  const recentPosts = userPosts.filter(
    post => new Date(post.createdAt) > thisWeek
  )

  return {
    totalPosts: userPosts.length,
    publishedCount,
    draftCount,
    recentCount: recentPosts.length,
    publishRate: userPosts.length > 0 ? (publishedCount / userPosts.length) * 100 : 0,
  }
})

// Async atom with dependencies
const userPostsAtom = atom(async (get) => {
  const user = get(userAtom)
  if (!user) return []
  
  const response = await fetch(`/api/users/${user.id}/posts`)
  if (!response.ok) throw new Error('Failed to fetch user posts')
  
  return response.json()
})

// Atom with cleanup
const subscriptionAtom = atom<WebSocket | null>(null)

const connectWebSocketAtom = atom(
  (get) => get(subscriptionAtom),
  (get, set, url: string) => {
    const currentWs = get(subscriptionAtom)
    
    // Close existing connection
    if (currentWs) {
      currentWs.close()
    }
    
    // Create new connection
    const ws = new WebSocket(url)
    set(subscriptionAtom, ws)
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data)
      // Handle incoming messages
      if (data.type === 'POST_UPDATE') {
        const currentPosts = get(postsAtom)
        const updatedPosts = currentPosts.map(post =>
          post.id === data.post.id ? data.post : post
        )
        set(postsAtom, updatedPosts)
      }
    }
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error)
      set(subscriptionAtom, null)
    }
    
    return ws
  }
)
```

### 5. Testing with Jotai

```typescript
// __tests__/atoms/auth.test.ts
import { renderHook, act } from '@testing-library/react'
import { Provider } from 'jotai'
import { useAtom, useAtomValue } from 'jotai'
import { userAtom, loginAtom, logoutAtom } from '@/atoms/auth'

// Mock fetch
global.fetch = jest.fn()

const TestProvider = ({ children }: { children: React.ReactNode }) => (
  <Provider>{children}</Provider>
)

describe('Auth Atoms', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should login successfully', async () => {
    const mockUser = { id: '1', name: 'John Doe', email: 'john@example.com', role: 'user' as const }
    
    ;(fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ user: mockUser, token: 'mock-token' }),
    })

    const { result } = renderHook(() => {
      const user = useAtomValue(userAtom)
      const login = useAtom(loginAtom)[1]
      return { user, login }
    }, { wrapper: TestProvider })

    await act(async () => {
      await result.current.login({ email: 'john@example.com', password: 'password' })
    })

    expect(result.current.user).toEqual(mockUser)
    expect(localStorage.getItem('token')).toBe('mock-token')
  })

  it('should logout successfully', async () => {
    // Set initial user
    const { result } = renderHook(() => {
      const [user, setUser] = useAtom(userAtom)
      const logout = useAtom(logoutAtom)[1]
      return { user, setUser, logout }
    }, { wrapper: TestProvider })

    const mockUser = { id: '1', name: 'John Doe', email: 'john@example.com', role: 'user' as const }
    
    act(() => {
      result.current.setUser(mockUser)
    })

    ;(fetch as jest.Mock).mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({}),
    })

    await act(async () => {
      await result.current.logout()
    })

    expect(result.current.user).toBeNull()
    expect(localStorage.getItem('token')).toBeNull()
  })
})

// __tests__/components/LoginForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { Provider } from 'jotai'
import { LoginForm } from '@/components/auth/LoginForm'

const TestWrapper = ({ children }: { children: React.ReactNode }) => (
  <Provider>{children}</Provider>
)

describe('LoginForm', () => {
  it('should render login form', () => {
    render(<LoginForm />, { wrapper: TestWrapper })
    
    expect(screen.getByLabelText('Email')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Sign In' })).toBeInTheDocument()
  })

  it('should handle form submission', async () => {
    global.fetch = jest.fn().mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ 
        user: { id: '1', name: 'John', email: 'john@example.com', role: 'user' },
        token: 'mock-token'
      }),
    })

    render(<LoginForm />, { wrapper: TestWrapper })
    
    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'john@example.com' },
    })
    fireEvent.change(screen.getByLabelText('Password'), {
      target: { value: 'password' },
    })

    fireEvent.click(screen.getByRole('button', { name: 'Sign In' }))

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'john@example.com', password: 'password' }),
      })
    })
  })
})
```

### Common Pitfalls to Avoid

1. **Creating atoms inside components (causes re-creation)**
2. **Not using proper TypeScript types**
3. **Overusing derived atoms (performance impact)**
4. **Not cleaning up side effects in atoms**
5. **Putting too much logic in components instead of atoms**
6. **Not using atom families for dynamic data**
7. **Forgetting to handle loading and error states**
8. **Not testing atom logic properly**
9. **Mixing Jotai with other state management libraries**
10. **Not leveraging Jotai utilities (atomWithStorage, loadable, etc.)**

### Performance Tips

1. **Use atomic design principles**
2. **Leverage atom families for collections**
3. **Split atoms for better granularity**
4. **Use loadable for async operations**
5. **Implement proper memoization**
6. **Avoid unnecessary re-renders with proper atom structure**
7. **Use React.memo for expensive components**
8. **Implement virtual scrolling for large lists**
9. **Optimize bundle size with proper imports**
10. **Monitor performance with React DevTools**

### Useful Libraries

- **jotai**: Core state management
- **jotai/utils**: Additional utilities
- **jotai/immer**: Immer integration
- **jotai/optics**: Lens-based updates
- **jotai/query**: React Query integration
- **jotai/urql**: URQL GraphQL integration
- **jotai/redux**: Redux DevTools integration
- **react-hook-form**: Form handling
- **zod**: Runtime validation
- **framer-motion**: Animations