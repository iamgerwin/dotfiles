# TanStack Ecosystem Best Practices

Comprehensive guide for building modern web applications using TanStack's powerful ecosystem: TanStack Start, Query, Router, and more.

## 📚 Official Documentation
- [TanStack Start](https://tanstack.com/start)
- [TanStack Query](https://tanstack.com/query)
- [TanStack Router](https://tanstack.com/router)
- [TanStack Table](https://tanstack.com/table)
- [TanStack Form](https://tanstack.com/form)

## 🏗️ Project Setup

### TanStack Start Full-Stack Setup
```bash
# Create new TanStack Start project
npm create @tanstack/start@latest my-app
cd my-app
npm install

# Additional TanStack libraries
npm install @tanstack/react-query @tanstack/react-router
npm install @tanstack/react-table @tanstack/react-form
```

### Project Structure
```
app/
├── routes/                     # File-based routing
│   ├── __root.tsx             # Root layout
│   ├── index.tsx              # Home page
│   ├── posts/                 # Nested routes
│   │   ├── index.tsx
│   │   └── $postId.tsx
│   └── users/
│       ├── index.tsx
│       └── $userId/
│           └── profile.tsx
├── components/                 # Reusable components
│   ├── ui/
│   ├── forms/
│   └── tables/
├── hooks/                      # Custom hooks
│   ├── queries/               # TanStack Query hooks
│   └── mutations/
├── lib/                        # Utilities
│   ├── api.ts                 # API client
│   ├── validation.ts          # Zod schemas
│   └── utils.ts
├── server/                     # Server-side code
│   ├── api/                   # API routes
│   └── db/                    # Database utilities
└── styles/
    └── globals.css
```

## 🎯 TanStack Start Best Practices

### 1. App Configuration & Setup

```tsx
// app/main.tsx
import { StartClient } from '@tanstack/start'
import { createRouter } from './router'

const router = createRouter()

export default function App() {
  return <StartClient router={router} />
}
```

```tsx
// app/router.tsx
import { createRouter as createTanStackRouter } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      cacheTime: 10 * 60 * 1000, // 10 minutes
      retry: (failureCount, error) => {
        if (error?.status === 404) return false
        return failureCount < 3
      },
    },
  },
})

export function createRouter() {
  return createTanStackRouter({
    routeTree,
    context: { queryClient },
    defaultPreload: 'intent',
    defaultPreloadStaleTime: 0,
  })
}

declare module '@tanstack/react-router' {
  interface Register {
    router: ReturnType<typeof createRouter>
  }
}
```

### 2. Route Definitions with Data Loading

```tsx
// app/routes/__root.tsx
import { Outlet, createRootRouteWithContext } from '@tanstack/react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'

interface RouterContext {
  queryClient: QueryClient
}

export const Route = createRootRouteWithContext<RouterContext>()({
  component: RootComponent,
})

function RootComponent() {
  return (
    <QueryClientProvider client={Route.useRouteContext().queryClient}>
      <div className="min-h-screen bg-gray-50">
        <nav className="bg-white shadow">
          <div className="max-w-7xl mx-auto px-4">
            <div className="flex justify-between h-16">
              <div className="flex items-center space-x-4">
                <Link to="/" className="text-xl font-bold">
                  My App
                </Link>
                <Link to="/posts" className="hover:text-blue-600">
                  Posts
                </Link>
                <Link to="/users" className="hover:text-blue-600">
                  Users
                </Link>
              </div>
            </div>
          </div>
        </nav>
        <main className="max-w-7xl mx-auto py-6 px-4">
          <Outlet />
        </main>
      </div>
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

```tsx
// app/routes/posts/index.tsx
import { createFileRoute } from '@tanstack/react-router'
import { useQuery } from '@tanstack/react-query'
import { postsQueryOptions } from '../../hooks/queries/posts'

export const Route = createFileRoute('/posts/')({
  loader: ({ context }) => {
    context.queryClient.ensureQueryData(postsQueryOptions())
  },
  component: PostsPage,
})

function PostsPage() {
  const { data: posts, isLoading, error } = useQuery(postsQueryOptions())

  if (isLoading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-red-600">Error loading posts: {error.message}</p>
      </div>
    )
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Posts</h1>
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {posts?.map((post) => (
          <div key={post.id} className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-2">
              <Link
                to="/posts/$postId"
                params={{ postId: post.id.toString() }}
                className="hover:text-blue-600"
              >
                {post.title}
              </Link>
            </h2>
            <p className="text-gray-600">{post.excerpt}</p>
          </div>
        ))}
      </div>
    </div>
  )
}
```

## 🎯 TanStack Query Best Practices

### 1. Query Organization & Custom Hooks

```typescript
// hooks/queries/posts.ts
import { queryOptions, useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../../lib/api'

export const postsQueryOptions = () =>
  queryOptions({
    queryKey: ['posts'],
    queryFn: () => api.posts.getAll(),
  })

export const postQueryOptions = (id: string) =>
  queryOptions({
    queryKey: ['posts', id],
    queryFn: () => api.posts.getById(id),
    enabled: !!id,
  })

export const usePostsQuery = () => {
  return useQuery(postsQueryOptions())
}

export const usePostQuery = (id: string) => {
  return useQuery(postQueryOptions(id))
}

export const useCreatePostMutation = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: api.posts.create,
    onSuccess: (newPost) => {
      // Invalidate and refetch posts list
      queryClient.invalidateQueries({ queryKey: ['posts'] })
      
      // Optimistically add to cache
      queryClient.setQueryData(['posts', newPost.id.toString()], newPost)
      
      // Update posts list cache
      queryClient.setQueryData(['posts'], (old: any) => 
        old ? [...old, newPost] : [newPost]
      )
    },
    onError: (error) => {
      console.error('Failed to create post:', error)
    },
  })
}

export const useUpdatePostMutation = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Post> }) =>
      api.posts.update(id, data),
    onMutate: async ({ id, data }) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['posts', id] })
      
      // Snapshot previous value
      const previousPost = queryClient.getQueryData(['posts', id])
      
      // Optimistically update
      queryClient.setQueryData(['posts', id], (old: any) => ({
        ...old,
        ...data,
      }))
      
      return { previousPost }
    },
    onError: (err, variables, context) => {
      // Rollback on error
      if (context?.previousPost) {
        queryClient.setQueryData(['posts', variables.id], context.previousPost)
      }
    },
    onSettled: (data, error, variables) => {
      // Always refetch after error or success
      queryClient.invalidateQueries({ queryKey: ['posts', variables.id] })
    },
  })
}
```

### 2. Advanced Query Patterns

```typescript
// hooks/queries/infinite-posts.ts
import { useInfiniteQuery } from '@tanstack/react-query'
import { api } from '../../lib/api'

export const useInfinitePostsQuery = (filters?: PostFilters) => {
  return useInfiniteQuery({
    queryKey: ['posts', 'infinite', filters],
    queryFn: ({ pageParam = 1 }) =>
      api.posts.getPaginated({ page: pageParam, ...filters }),
    getNextPageParam: (lastPage, allPages) => {
      return lastPage.hasMore ? allPages.length + 1 : undefined
    },
    initialPageParam: 1,
  })
}

// hooks/queries/dependent-queries.ts
export const useUserPostsQuery = (userId: string) => {
  const { data: user } = useUserQuery(userId)
  
  return useQuery({
    queryKey: ['posts', 'user', userId],
    queryFn: () => api.posts.getByUserId(userId),
    enabled: !!user, // Only run when user data is available
  })
}

// hooks/queries/parallel-queries.ts
export const usePostWithComments = (postId: string) => {
  const postQuery = useQuery(postQueryOptions(postId))
  const commentsQuery = useQuery({
    queryKey: ['comments', 'post', postId],
    queryFn: () => api.comments.getByPostId(postId),
    enabled: !!postId,
  })

  return {
    post: postQuery.data,
    comments: commentsQuery.data,
    isLoading: postQuery.isLoading || commentsQuery.isLoading,
    error: postQuery.error || commentsQuery.error,
  }
}
```

## 🎯 TanStack Router Advanced Patterns

### 1. Route Guards & Authentication

```tsx
// routes/_authenticated.tsx
import { createFileRoute, redirect } from '@tanstack/react-router'
import { useAuth } from '../hooks/useAuth'

export const Route = createFileRoute('/_authenticated')({
  beforeLoad: async ({ context }) => {
    const { isAuthenticated } = await context.queryClient.ensureQueryData(
      authQueryOptions()
    )
    
    if (!isAuthenticated) {
      throw redirect({
        to: '/login',
        search: {
          redirect: location.href,
        },
      })
    }
  },
  component: AuthenticatedLayout,
})

function AuthenticatedLayout() {
  return (
    <div>
      <header>Protected Header</header>
      <Outlet />
    </div>
  )
}
```

### 2. Search Params & Validation

```tsx
// routes/posts/index.tsx
import { z } from 'zod'
import { createFileRoute } from '@tanstack/react-router'

const postsSearchSchema = z.object({
  page: z.number().min(1).catch(1),
  limit: z.number().min(1).max(100).catch(20),
  search: z.string().optional(),
  category: z.string().optional(),
  sortBy: z.enum(['date', 'title', 'views']).catch('date'),
  order: z.enum(['asc', 'desc']).catch('desc'),
})

export const Route = createFileRoute('/posts/')({
  validateSearch: postsSearchSchema,
  loaderDeps: ({ search }) => search,
  loader: ({ context, deps }) => {
    context.queryClient.ensureQueryData(
      postsQueryOptions(deps)
    )
  },
  component: PostsPage,
})

function PostsPage() {
  const navigate = useNavigate({ from: '/posts' })
  const { page, limit, search, category, sortBy, order } = Route.useSearch()
  
  const { data: posts, isLoading } = useQuery(
    postsQueryOptions({ page, limit, search, category, sortBy, order })
  )

  const updateSearch = (updates: Partial<typeof postsSearchSchema._type>) => {
    navigate({
      search: (prev) => ({ ...prev, ...updates, page: 1 }), // Reset to page 1
    })
  }

  return (
    <div>
      <div className="mb-6 flex gap-4">
        <input
          type="text"
          value={search || ''}
          onChange={(e) => updateSearch({ search: e.target.value })}
          placeholder="Search posts..."
          className="px-3 py-2 border rounded"
        />
        <select
          value={category || ''}
          onChange={(e) => updateSearch({ category: e.target.value || undefined })}
          className="px-3 py-2 border rounded"
        >
          <option value="">All Categories</option>
          <option value="tech">Technology</option>
          <option value="design">Design</option>
        </select>
      </div>
      
      {/* Posts list */}
      {isLoading ? <PostsSkeleton /> : <PostsList posts={posts} />}
      
      {/* Pagination */}
      <Pagination
        currentPage={page}
        onPageChange={(newPage) => updateSearch({ page: newPage })}
      />
    </div>
  )
}
```

## 🎯 TanStack Table Integration

### 1. Advanced Data Table Component

```tsx
// components/tables/PostsTable.tsx
import {
  useReactTable,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  createColumnHelper,
  flexRender,
} from '@tanstack/react-table'
import { useMemo, useState } from 'react'

const columnHelper = createColumnHelper<Post>()

export function PostsTable({ data }: { data: Post[] }) {
  const [sorting, setSorting] = useState([])
  const [columnFilters, setColumnFilters] = useState([])
  const [globalFilter, setGlobalFilter] = useState('')

  const columns = useMemo(
    () => [
      columnHelper.accessor('title', {
        header: 'Title',
        cell: (info) => (
          <Link
            to="/posts/$postId"
            params={{ postId: info.row.original.id.toString() }}
            className="text-blue-600 hover:underline"
          >
            {info.getValue()}
          </Link>
        ),
      }),
      columnHelper.accessor('author.name', {
        header: 'Author',
        cell: (info) => info.getValue(),
      }),
      columnHelper.accessor('createdAt', {
        header: 'Created',
        cell: (info) => new Date(info.getValue()).toLocaleDateString(),
      }),
      columnHelper.accessor('status', {
        header: 'Status',
        cell: (info) => {
          const status = info.getValue()
          return (
            <span
              className={`px-2 py-1 rounded-full text-xs font-medium ${
                status === 'published'
                  ? 'bg-green-100 text-green-800'
                  : status === 'draft'
                  ? 'bg-yellow-100 text-yellow-800'
                  : 'bg-gray-100 text-gray-800'
              }`}
            >
              {status}
            </span>
          )
        },
      }),
      columnHelper.display({
        id: 'actions',
        header: 'Actions',
        cell: (info) => (
          <div className="flex space-x-2">
            <button
              onClick={() => handleEdit(info.row.original)}
              className="text-blue-600 hover:text-blue-800"
            >
              Edit
            </button>
            <button
              onClick={() => handleDelete(info.row.original.id)}
              className="text-red-600 hover:text-red-800"
            >
              Delete
            </button>
          </div>
        ),
      }),
    ],
    []
  )

  const table = useReactTable({
    data,
    columns,
    state: {
      sorting,
      columnFilters,
      globalFilter,
    },
    onSortingChange: setSorting,
    onColumnFiltersChange: setColumnFilters,
    onGlobalFilterChange: setGlobalFilter,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: {
      pagination: {
        pageSize: 10,
      },
    },
  })

  return (
    <div className="space-y-4">
      {/* Global search */}
      <input
        value={globalFilter ?? ''}
        onChange={(e) => setGlobalFilter(e.target.value)}
        placeholder="Search all columns..."
        className="px-3 py-2 border rounded w-full max-w-md"
      />

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full bg-white border border-gray-200">
          <thead className="bg-gray-50">
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th
                    key={header.id}
                    className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer"
                    onClick={header.column.getToggleSortingHandler()}
                  >
                    {header.isPlaceholder
                      ? null
                      : flexRender(header.column.columnDef.header, header.getContext())}
                    {{
                      asc: ' 🔼',
                      desc: ' 🔽',
                    }[header.column.getIsSorted() as string] ?? null}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {table.getRowModel().rows.map((row) => (
              <tr key={row.id} className="hover:bg-gray-50">
                {row.getVisibleCells().map((cell) => (
                  <td
                    key={cell.id}
                    className="px-6 py-4 whitespace-nowrap text-sm text-gray-900"
                  >
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <button
            onClick={() => table.setPageIndex(0)}
            disabled={!table.getCanPreviousPage()}
            className="px-3 py-1 border rounded disabled:opacity-50"
          >
            {'<<'}
          </button>
          <button
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
            className="px-3 py-1 border rounded disabled:opacity-50"
          >
            {'<'}
          </button>
          <button
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
            className="px-3 py-1 border rounded disabled:opacity-50"
          >
            {'>'}
          </button>
          <button
            onClick={() => table.setPageIndex(table.getPageCount() - 1)}
            disabled={!table.getCanNextPage()}
            className="px-3 py-1 border rounded disabled:opacity-50"
          >
            {'>>'}
          </button>
        </div>
        
        <span className="flex items-center space-x-1">
          <div>Page</div>
          <strong>
            {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
          </strong>
        </span>

        <select
          value={table.getState().pagination.pageSize}
          onChange={(e) => table.setPageSize(Number(e.target.value))}
          className="px-3 py-1 border rounded"
        >
          {[10, 20, 30, 40, 50].map((pageSize) => (
            <option key={pageSize} value={pageSize}>
              Show {pageSize}
            </option>
          ))}
        </select>
      </div>
    </div>
  )
}
```

## 🛠️ API Integration & Error Handling

### 1. Robust API Client

```typescript
// lib/api.ts
import { z } from 'zod'

class APIClient {
  private baseURL: string
  
  constructor(baseURL: string) {
    this.baseURL = baseURL
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    schema?: z.ZodSchema<T>
  ): Promise<T> {
    const url = `${this.baseURL}${endpoint}`
    
    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    }

    try {
      const response = await fetch(url, config)
      
      if (!response.ok) {
        const error = await response.json().catch(() => ({ message: 'Network error' }))
        throw new APIError(error.message, response.status, error)
      }

      const data = await response.json()
      
      if (schema) {
        return schema.parse(data)
      }
      
      return data
    } catch (error) {
      if (error instanceof APIError) {
        throw error
      }
      
      throw new APIError('Request failed', 0, error)
    }
  }

  posts = {
    getAll: () =>
      this.request('/posts', {}, z.array(postSchema)),
    
    getById: (id: string) =>
      this.request(`/posts/${id}`, {}, postSchema),
    
    create: (data: CreatePostData) =>
      this.request('/posts', {
        method: 'POST',
        body: JSON.stringify(data),
      }, postSchema),
    
    update: (id: string, data: UpdatePostData) =>
      this.request(`/posts/${id}`, {
        method: 'PUT',
        body: JSON.stringify(data),
      }, postSchema),
    
    delete: (id: string) =>
      this.request(`/posts/${id}`, { method: 'DELETE' }),
  }
}

class APIError extends Error {
  constructor(
    message: string,
    public status: number,
    public data?: any
  ) {
    super(message)
    this.name = 'APIError'
  }
}

export const api = new APIClient(process.env.VITE_API_URL || '/api')
```

### 2. Global Error Handling

```tsx
// components/ErrorBoundary.tsx
import { ErrorBoundary as ReactErrorBoundary } from 'react-error-boundary'
import { QueryErrorResetBoundary } from '@tanstack/react-query'

function ErrorFallback({ error, resetErrorBoundary }: any) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md mx-auto text-center">
        <div className="text-red-500 text-6xl mb-4">⚠️</div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          Something went wrong
        </h1>
        <p className="text-gray-600 mb-6">
          {error.message || 'An unexpected error occurred'}
        </p>
        <button
          onClick={resetErrorBoundary}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Try again
        </button>
      </div>
    </div>
  )
}

export function AppErrorBoundary({ children }: { children: React.ReactNode }) {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ReactErrorBoundary
          FallbackComponent={ErrorFallback}
          onReset={reset}
        >
          {children}
        </ReactErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  )
}
```

## ⚠️ Common Pitfalls to Avoid

### 1. Query Key Management
```typescript
// ❌ Bad - Inconsistent query keys
useQuery({ queryKey: ['posts'], ... })
useQuery({ queryKey: ['post'], ... }) // Different key format

// ✅ Good - Consistent query key factory
const postQueries = {
  all: () => ['posts'] as const,
  lists: () => [...postQueries.all(), 'list'] as const,
  list: (filters: string) => [...postQueries.lists(), { filters }] as const,
  details: () => [...postQueries.all(), 'detail'] as const,
  detail: (id: string) => [...postQueries.details(), id] as const,
}
```

### 2. Over-fetching Data
```tsx
// ❌ Bad - Loading all data upfront
const { data: posts } = useQuery({
  queryKey: ['posts'],
  queryFn: () => api.posts.getAllWithEverything(), // Too much data
})

// ✅ Good - Selective loading
const { data: posts } = useQuery({
  queryKey: ['posts', 'list'],
  queryFn: () => api.posts.getList(), // Only what's needed
  select: (data) => data.map(post => ({
    id: post.id,
    title: post.title,
    excerpt: post.excerpt,
  })),
})
```

## 📊 Performance Optimization

### 1. Query Prefetching
```typescript
// Prefetch on hover/focus
const prefetchPost = (postId: string) => {
  queryClient.prefetchQuery(postQueryOptions(postId))
}

// In component
<Link
  to="/posts/$postId"
  params={{ postId: post.id.toString() }}
  onMouseEnter={() => prefetchPost(post.id.toString())}
  onFocus={() => prefetchPost(post.id.toString())}
>
  {post.title}
</Link>
```

### 2. Code Splitting Routes
```tsx
// routes/posts/index.lazy.tsx
import { createLazyFileRoute } from '@tanstack/react-router'

export const Route = createLazyFileRoute('/posts/')({
  component: () => {
    const PostsComponent = lazy(() => import('../../components/PostsPage'))
    return (
      <Suspense fallback={<div>Loading posts...</div>}>
        <PostsComponent />
      </Suspense>
    )
  },
})
```

## 🧪 Testing Strategies

### Testing with TanStack Query
```tsx
// test-utils.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createMemoryHistory, createRootRoute, createRouter } from '@tanstack/react-router'

export function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  })
}

export function renderWithProviders(component: React.ReactElement) {
  const queryClient = createTestQueryClient()
  const history = createMemoryHistory()
  const rootRoute = createRootRoute()
  const router = createRouter({ routeTree: rootRoute, history })

  return render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router}>
        {component}
      </RouterProvider>
    </QueryClientProvider>
  )
}
```

## 📋 Code Review Checklist

- [ ] Query keys are consistent and hierarchical
- [ ] Proper error boundaries implemented
- [ ] Loading states handled appropriately
- [ ] Optimistic updates where beneficial
- [ ] Route-level data loading implemented
- [ ] Search params validation in place
- [ ] Performance optimizations applied
- [ ] Proper TypeScript types throughout

Remember: TanStack's ecosystem is designed to work together seamlessly. Leverage the full-stack capabilities of TanStack Start with the data management power of TanStack Query for optimal developer experience and application performance.