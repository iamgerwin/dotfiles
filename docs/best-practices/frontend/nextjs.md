# Next.js 15 Best Practices

## Official Documentation
- **Next.js Documentation**: https://nextjs.org/docs
- **Next.js Learn**: https://nextjs.org/learn
- **Next.js Examples**: https://github.com/vercel/next.js/tree/canary/examples
- **Vercel Documentation**: https://vercel.com/docs
- **Next.js 15 Release Notes**: https://nextjs.org/blog/next-15

## Project Structure

```
project-root/
├── app/                      # App Router (Next.js 13+)
│   ├── (auth)/
│   │   ├── login/
│   │   │   ├── page.tsx
│   │   │   └── loading.tsx
│   │   └── register/
│   │       └── page.tsx
│   ├── api/
│   │   ├── auth/
│   │   │   └── [...nextauth]/
│   │   │       └── route.ts
│   │   └── users/
│   │       ├── route.ts
│   │       └── [id]/
│   │           └── route.ts
│   ├── dashboard/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── loading.tsx
│   ├── layout.tsx
│   ├── page.tsx
│   ├── error.tsx
│   ├── loading.tsx
│   └── not-found.tsx
├── components/
│   ├── ui/
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   └── Modal.tsx
│   ├── forms/
│   │   ├── LoginForm.tsx
│   │   └── UserForm.tsx
│   └── layouts/
│       ├── Header.tsx
│       └── Footer.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useDebounce.ts
│   └── useFetch.ts
├── lib/
│   ├── api/
│   │   ├── client.ts
│   │   └── endpoints.ts
│   ├── utils/
│   │   ├── format.ts
│   │   └── validation.ts
│   └── db/
│       ├── prisma.ts
│       └── queries.ts
├── services/
│   ├── auth.service.ts
│   └── user.service.ts
├── types/
│   ├── api.ts
│   ├── user.ts
│   └── global.d.ts
├── styles/
│   └── globals.css
├── public/
│   ├── images/
│   └── fonts/
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── tests/
│   ├── unit/
│   └── e2e/
├── .env.local
├── .env.example
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Core Best Practices

## Next.js 15 New Features & Best Practices

### 1. Turbopack Build System (Beta)

```javascript
// next.config.js - Enable Turbopack for development
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable Turbopack for development (much faster builds)
  experimental: {
    turbo: {
      // Configure Turbopack loaders
      loaders: {
        '.svg': ['@svgr/webpack'],
      },
      // Configure Turbopack resolveAlias
      resolveAlias: {
        '@': './src',
        '@/components': './src/components',
      },
    },
  },
}

module.exports = nextConfig
```

```bash
# Use Turbopack for faster development builds
npm run dev --turbo
# or
yarn dev --turbo
```

### 2. Node.js Middleware (Stable)

```typescript
// middleware.ts - Enhanced middleware with Node.js APIs
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { headers } from 'next/headers'

export async function middleware(request: NextRequest) {
  // Access Node.js APIs directly in middleware
  const requestHeaders = new Headers(request.headers)
  requestHeaders.set('x-pathname', request.nextUrl.pathname)
  
  // Enhanced geolocation and user agent detection
  const country = request.geo?.country || 'US'
  const city = request.geo?.city || 'Unknown'
  
  // Rate limiting with enhanced request info
  const ip = request.ip || request.headers.get('x-forwarded-for') || '127.0.0.1'
  
  // Advanced routing logic
  if (request.nextUrl.pathname.startsWith('/api/')) {
    // API-specific middleware logic
    requestHeaders.set('x-api-route', 'true')
    requestHeaders.set('x-user-country', country)
  }
  
  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  })
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}
```

### 3. Enhanced TypeScript Support

```typescript
// Enhanced TypeScript configuration for Next.js 15
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "es6", "ES2022"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/types/*": ["./src/types/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": [
    "node_modules"
  ]
}

// Enhanced type definitions
// types/next.d.ts
import type { NextRequest } from 'next/server'

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      DATABASE_URL: string
      NEXTAUTH_SECRET: string
      NEXTAUTH_URL: string
      NEXT_PUBLIC_API_URL: string
    }
  }
}

// Enhanced request types
interface CustomNextRequest extends NextRequest {
  user?: {
    id: string
    email: string
    role: string
  }
}
```

### 4. App Router Best Practices (Next.js 15)

```typescript
// app/layout.tsx - Root Layout
import { Inter } from 'next/font/google'
import { Metadata } from 'next'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: {
    template: '%s | My App',
    default: 'My App',
  },
  description: 'My application description',
  metadataBase: new URL('https://myapp.com'),
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}

// app/dashboard/page.tsx - Server Component by default
import { Suspense } from 'react'
import { DashboardSkeleton } from '@/components/skeletons'

async function getDashboardData() {
  const res = await fetch('https://api.example.com/dashboard', {
    next: { revalidate: 3600 }, // Revalidate every hour
  })
  return res.json()
}

export default async function DashboardPage() {
  const data = await getDashboardData()
  
  return (
    <Suspense fallback={<DashboardSkeleton />}>
      <Dashboard data={data} />
    </Suspense>
  )
}
```

### 2. Data Fetching Patterns

```typescript
// Server Components - Fetch on the server
async function ProductPage({ params }: { params: { id: string } }) {
  // Parallel data fetching
  const [product, reviews] = await Promise.all([
    fetch(`/api/products/${params.id}`).then(res => res.json()),
    fetch(`/api/products/${params.id}/reviews`).then(res => res.json()),
  ])
  
  return <ProductDetails product={product} reviews={reviews} />
}

// Client Components - Use SWR or React Query
'use client'

import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then(res => res.json())

export function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading } = useSWR(
    `/api/users/${userId}`,
    fetcher,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: false,
    }
  )
  
  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Failed to load</div>
  
  return <div>{data.name}</div>
}

// Server Actions (Next.js 14+)
async function updateUser(formData: FormData) {
  'use server'
  
  const name = formData.get('name')
  const email = formData.get('email')
  
  await db.user.update({
    where: { email },
    data: { name },
  })
  
  revalidatePath('/users')
  redirect('/users')
}
```

### 3. API Routes Best Practices

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { prisma } from '@/lib/prisma'

const userSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
})

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    
    const users = await prisma.user.findMany({
      skip: (page - 1) * limit,
      take: limit,
      select: {
        id: true,
        name: true,
        email: true,
        createdAt: true,
      },
    })
    
    return NextResponse.json({ users, page, limit })
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = userSchema.parse(body)
    
    const user = await prisma.user.create({
      data: validated,
    })
    
    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: error.errors },
        { status: 400 }
      )
    }
    
    return NextResponse.json(
      { error: 'Internal Server Error' },
      { status: 500 }
    )
  }
}
```

### 4. Component Patterns

```typescript
// Server Component with Client Component composition
// app/products/ProductList.tsx
import { ProductCard } from './ProductCard'
import { AddToCartButton } from './AddToCartButton'

export async function ProductList() {
  const products = await getProducts()
  
  return (
    <div className="grid grid-cols-3 gap-4">
      {products.map(product => (
        <ProductCard key={product.id} product={product}>
          <AddToCartButton productId={product.id} />
        </ProductCard>
      ))}
    </div>
  )
}

// Client Component
// app/products/AddToCartButton.tsx
'use client'

import { useState } from 'react'
import { useCart } from '@/hooks/useCart'

export function AddToCartButton({ productId }: { productId: string }) {
  const [isLoading, setIsLoading] = useState(false)
  const { addItem } = useCart()
  
  const handleClick = async () => {
    setIsLoading(true)
    await addItem(productId)
    setIsLoading(false)
  }
  
  return (
    <button 
      onClick={handleClick} 
      disabled={isLoading}
      className="btn btn-primary"
    >
      {isLoading ? 'Adding...' : 'Add to Cart'}
    </button>
  )
}
```

### 5. Authentication Pattern

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { getToken } from 'next-auth/jwt'

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request })
  const isAuthPage = request.nextUrl.pathname.startsWith('/login')
  
  if (!token && !isAuthPage) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  
  if (token && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*', '/login'],
}

// lib/auth.ts
import { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { prisma } from '@/lib/prisma'
import bcrypt from 'bcryptjs'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }
        
        const user = await prisma.user.findUnique({
          where: { email: credentials.email },
        })
        
        if (!user || !await bcrypt.compare(credentials.password, user.password)) {
          return null
        }
        
        return {
          id: user.id,
          email: user.email,
          name: user.name,
        }
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
      }
      return token
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string
      }
      return session
    },
  },
}
```

### 6. Performance Optimization

```typescript
// Image Optimization
import Image from 'next/image'

export function ProductImage({ src, alt }: { src: string; alt: string }) {
  return (
    <Image
      src={src}
      alt={alt}
      width={500}
      height={500}
      placeholder="blur"
      blurDataURL="data:image/jpeg;base64,..."
      priority={false}
      loading="lazy"
      sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
    />
  )
}

// Dynamic Imports for Code Splitting
import dynamic from 'next/dynamic'

const DynamicChart = dynamic(() => import('@/components/Chart'), {
  loading: () => <p>Loading chart...</p>,
  ssr: false,
})

// Metadata for SEO
export async function generateMetadata({ params }: { params: { id: string } }) {
  const product = await getProduct(params.id)
  
  return {
    title: product.name,
    description: product.description,
    openGraph: {
      title: product.name,
      description: product.description,
      images: [product.image],
    },
  }
}
```

### 7. Error Handling

```typescript
// app/error.tsx
'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])
  
  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      <h2 className="text-2xl font-bold mb-4">Something went wrong!</h2>
      <button
        onClick={reset}
        className="px-4 py-2 bg-blue-500 text-white rounded"
      >
        Try again
      </button>
    </div>
  )
}

// app/not-found.tsx
import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen">
      <h2 className="text-2xl font-bold mb-4">404 - Page Not Found</h2>
      <Link href="/" className="text-blue-500 hover:underline">
        Return Home
      </Link>
    </div>
  )
}
```

### 8. Environment Variables

```bash
# .env.local
DATABASE_URL="postgresql://..."
NEXTAUTH_SECRET="your-secret"
NEXTAUTH_URL="http://localhost:3000"

# Public variables (accessible in browser)
NEXT_PUBLIC_API_URL="https://api.example.com"
NEXT_PUBLIC_STRIPE_KEY="pk_test_..."
```

```typescript
// Type-safe environment variables
// env.mjs
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(1),
  NEXTAUTH_URL: z.string().url(),
  NEXT_PUBLIC_API_URL: z.string().url(),
})

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET,
  NEXTAUTH_URL: process.env.NEXTAUTH_URL,
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
})
```

### 9. Testing

```typescript
// Unit Testing with Jest
// __tests__/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from '@/components/ui/Button'

describe('Button', () => {
  it('renders correctly', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })
  
  it('handles click events', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    
    fireEvent.click(screen.getByText('Click me'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })
})

// E2E Testing with Playwright
// e2e/app.spec.ts
import { test, expect } from '@playwright/test'

test('homepage has title', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveTitle(/My App/)
})

test('navigation works', async ({ page }) => {
  await page.goto('/')
  await page.click('text=About')
  await expect(page).toHaveURL('/about')
})
```

### 10. Styling Best Practices

```typescript
// Tailwind CSS with CSS Modules
// components/Card.module.css
.card {
  @apply bg-white rounded-lg shadow-md p-6;
}

.card:hover {
  @apply shadow-lg transform -translate-y-1;
}

// Component
import styles from './Card.module.css'

export function Card({ children }: { children: React.ReactNode }) {
  return <div className={styles.card}>{children}</div>
}

// CSS-in-JS with styled-components
import styled from 'styled-components'

const StyledButton = styled.button`
  background: ${props => props.primary ? '#0070f3' : 'white'};
  color: ${props => props.primary ? 'white' : '#0070f3'};
  padding: 0.5rem 1rem;
  border: 2px solid #0070f3;
  border-radius: 0.25rem;
  cursor: pointer;
  
  &:hover {
    opacity: 0.8;
  }
`
```

### 11. Next.js 15 Configuration & Deployment

```javascript
// next.config.js - Next.js 15 optimized configuration
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable React Strict Mode for better development experience
  reactStrictMode: true,
  
  // Use SWC for minification (faster than Terser)
  swcMinify: true,
  
  // Enable Turbopack for development (Next.js 15)
  experimental: {
    turbo: {
      loaders: {
        '.svg': ['@svgr/webpack'],
      },
      resolveAlias: {
        '@': './src',
      },
    },
    // Server Actions are now stable
    serverActions: {
      allowedOrigins: ['localhost:3000', 'yourdomain.com'],
      bodySizeLimit: '2mb',
    },
  },
  
  // Enhanced image optimization
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'images.example.com',
        port: '',
        pathname: '/uploads/**',
      },
    ],
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 31536000, // 1 year
  },
  
  // Security headers
  headers: async () => [
    {
      source: '/(.*)',
      headers: [
        {
          key: 'X-Content-Type-Options',
          value: 'nosniff',
        },
        {
          key: 'X-Frame-Options',
          value: 'DENY',
        },
        {
          key: 'X-XSS-Protection',
          value: '1; mode=block',
        },
        {
          key: 'Strict-Transport-Security',
          value: 'max-age=31536000; includeSubDomains',
        },
        {
          key: 'Content-Security-Policy',
          value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';",
        },
      ],
    },
  ],
  
  // Optimized bundling
  webpack: (config, { isServer }) => {
    // Optimize bundle splitting
    if (!isServer) {
      config.optimization.splitChunks.cacheGroups = {
        ...config.optimization.splitChunks.cacheGroups,
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          priority: 10,
          chunks: 'all',
        },
      }
    }
    return config
  },
  
  // Output settings for static export if needed
  // output: 'export', // Uncomment for static export
  
  // Environment variable validation
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
}

module.exports = nextConfig
```

## Vercel Deployment Best Practices

### 1. Project Configuration

```json
// vercel.json - Comprehensive Vercel configuration
{
  "version": 2,
  "framework": "nextjs",
  "buildCommand": "next build",
  "outputDirectory": ".next",
  "installCommand": "npm install",
  "regions": ["iad1"],
  "functions": {
    "app/api/**/*.ts": {
      "runtime": "nodejs18.x",
      "maxDuration": 30
    }
  },
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-cache, no-store, must-revalidate"
        }
      ]
    }
  ],
  "redirects": [
    {
      "source": "/old-page",
      "destination": "/new-page",
      "permanent": true
    }
  ],
  "rewrites": [
    {
      "source": "/api/proxy/:path*",
      "destination": "https://external-api.com/:path*"
    }
  ],
  "crons": [
    {
      "path": "/api/cleanup",
      "schedule": "0 2 * * *"
    }
  ]
}
```

### 2. Environment Variables Management

```bash
# .env.example - Document all required environment variables
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/database

# Authentication
NEXTAUTH_SECRET=your-secret-key-here
NEXTAUTH_URL=http://localhost:3000

# External APIs
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLIC_KEY=pk_test_...

# Analytics
GOOGLE_ANALYTICS_ID=GA-XXXXXXXXX

# Feature flags
FEATURE_NEW_DASHBOARD=false

# Vercel-specific
VERCEL_URL=your-app.vercel.app
VERCEL_ENV=development
```

```typescript
// lib/env.ts - Type-safe environment validation
import { z } from 'zod'

const envSchema = z.object({
  // Database
  DATABASE_URL: z.string().url(),
  
  // Auth
  NEXTAUTH_SECRET: z.string().min(32),
  NEXTAUTH_URL: z.string().url(),
  
  // External services
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  
  // Public variables
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: z.string().startsWith('pk_'),
  NEXT_PUBLIC_APP_URL: z.string().url(),
  
  // Vercel
  VERCEL_URL: z.string().optional(),
  VERCEL_ENV: z.enum(['development', 'preview', 'production']).optional(),
})

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET,
  NEXTAUTH_URL: process.env.NEXTAUTH_URL,
  STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  VERCEL_URL: process.env.VERCEL_URL,
  VERCEL_ENV: process.env.VERCEL_ENV,
})
```

### 3. Build Optimization & Cost Control

```javascript
// vercel-build.js - Custom build script with optimization
const { execSync } = require('child_process')

async function build() {
  console.log('🚀 Starting optimized build...')
  
  // Analyze bundle before build
  if (process.env.ANALYZE === 'true') {
    execSync('npx @next/bundle-analyzer', { stdio: 'inherit' })
  }
  
  // Build with specific optimizations
  execSync('next build', { 
    stdio: 'inherit',
    env: {
      ...process.env,
      NODE_OPTIONS: '--max-old-space-size=4096',
    }
  })
  
  // Post-build optimizations
  console.log('✨ Build optimization complete!')
}

build().catch(console.error)
```

```json
// package.json - Optimized scripts
{
  "scripts": {
    "dev": "next dev --turbo",
    "build": "node vercel-build.js",
    "build:analyze": "ANALYZE=true npm run build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "test": "jest --passWithNoTests",
    "test:e2e": "playwright test",
    "postinstall": "prisma generate"
  }
}
```

### 4. Performance Monitoring & Cost Optimization

```typescript
// lib/analytics.ts - Performance monitoring
export function trackWebVitals(metric: any) {
  // Track Core Web Vitals
  const { name, value, id } = metric
  
  // Send to analytics service
  if (typeof window !== 'undefined') {
    window.gtag?.('event', name, {
      event_category: 'Web Vitals',
      event_label: id,
      value: Math.round(name === 'CLS' ? value * 1000 : value),
      non_interaction: true,
    })
  }
  
  // Log to Vercel Analytics
  if (process.env.NODE_ENV === 'production') {
    console.log(`[Web Vitals] ${name}: ${value}`)
  }
}

// app/layout.tsx - Add web vitals tracking
export function reportWebVitals(metric: any) {
  trackWebVitals(metric)
}
```

```typescript
// lib/vercel-edge.ts - Edge function optimization
import { NextRequest, NextResponse } from 'next/server'

// Edge function for geolocation-based redirects
export function middleware(request: NextRequest) {
  const country = request.geo?.country
  const city = request.geo?.city
  
  // Redirect users to region-specific content
  if (country === 'GB' && !request.nextUrl.pathname.startsWith('/uk')) {
    return NextResponse.redirect(new URL('/uk', request.url))
  }
  
  // Add geolocation headers for personalization
  const response = NextResponse.next()
  response.headers.set('x-user-country', country || 'unknown')
  response.headers.set('x-user-city', city || 'unknown')
  
  return response
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
  runtime: 'edge', // Use Edge Runtime for better performance
}
```

### 5. Database & External Service Integration

```typescript
// lib/db-edge.ts - Database connection for Edge Runtime
import { PrismaClient } from '@prisma/client/edge'
import { withAccelerate } from '@prisma/extension-accelerate'

// Use Prisma Accelerate for Edge Runtime
const prisma = new PrismaClient().$extends(withAccelerate())

export { prisma }

// lib/redis-edge.ts - Redis for Edge caching
import { Redis } from '@upstash/redis'

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
})
```

### 6. Vercel-Specific Optimizations

```typescript
// app/api/edge-api/route.ts - Optimized Edge API Route
import { NextRequest, NextResponse } from 'next/server'

export const runtime = 'edge'
export const dynamic = 'force-dynamic'

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url)
  const id = searchParams.get('id')
  
  // Use Vercel KV for caching
  const cached = await kv.get(`item:${id}`)
  if (cached) {
    return NextResponse.json(cached, {
      headers: {
        'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400',
      },
    })
  }
  
  // Fetch from external API with timeout
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), 5000)
  
  try {
    const response = await fetch(`https://api.example.com/items/${id}`, {
      signal: controller.signal,
    })
    const data = await response.json()
    
    // Cache the result
    await kv.set(`item:${id}`, data, { ex: 3600 })
    
    return NextResponse.json(data)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch data' },
      { status: 500 }
    )
  } finally {
    clearTimeout(timeoutId)
  }
}
```

### 7. Deployment Workflow

```yaml
# .github/workflows/vercel.yml - CI/CD with Vercel
name: Vercel Deployment

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  deploy:
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
      
      - name: Run type checking
        run: npm run type-check
      
      - name: Run linting
        run: npm run lint
      
      - name: Run tests
        run: npm run test
      
      - name: Build project
        run: npm run build
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          NEXTAUTH_SECRET: ${{ secrets.NEXTAUTH_SECRET }}
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./
```

## Vercel Cost Optimization & Pitfalls

### Common Vercel Cost Pitfalls to Avoid

1. **Excessive Function Execution Time**
   ```typescript
   // ❌ Bad: Long-running function
   export async function GET() {
     const data = await heavyComputation() // Takes 45 seconds
     return Response.json(data)
   }
   
   // ✅ Good: Optimize for function timeouts
   export async function GET() {
     const cached = await redis.get('heavy-data')
     if (cached) return Response.json(cached)
     
     const data = await Promise.race([
       heavyComputation(),
       new Promise((_, reject) => 
         setTimeout(() => reject(new Error('Timeout')), 25000)
       )
     ])
     
     await redis.setex('heavy-data', 3600, data)
     return Response.json(data)
   }
   ```

2. **Bandwidth Overuse**
   ```typescript
   // ❌ Bad: Large unoptimized responses
   export async function GET() {
     const users = await db.user.findMany({
       include: { posts: true, profile: true, settings: true }
     })
     return Response.json(users) // Potentially huge response
   }
   
   // ✅ Good: Paginated and optimized responses
   export async function GET(request: Request) {
     const { searchParams } = new URL(request.url)
     const page = parseInt(searchParams.get('page') || '1')
     const limit = Math.min(parseInt(searchParams.get('limit') || '10'), 100)
     
     const users = await db.user.findMany({
       skip: (page - 1) * limit,
       take: limit,
       select: { id: true, name: true, email: true, createdAt: true }
     })
     
     return Response.json(users, {
       headers: { 'Cache-Control': 'public, s-maxage=300' }
     })
   }
   ```

3. **Unnecessary Edge Function Usage**
   ```typescript
   // ❌ Bad: Using Edge Runtime for database operations
   export const runtime = 'edge' // Don't use for DB queries
   
   export async function GET() {
     const users = await prisma.user.findMany() // This will be slow/fail
     return Response.json(users)
   }
   
   // ✅ Good: Use Node.js runtime for database operations
   export async function GET() {
     const users = await prisma.user.findMany()
     return Response.json(users)
   }
   ```

### Cost Monitoring & Alerts

```typescript
// lib/cost-monitor.ts - Monitor Vercel usage
export async function logUsageMetrics() {
  const metrics = {
    timestamp: new Date().toISOString(),
    functionInvocations: process.env.VERCEL_FUNCTION_INVOCATIONS || 0,
    bandwidth: process.env.VERCEL_BANDWIDTH_USAGE || 0,
    buildTime: process.env.VERCEL_BUILD_TIME || 0,
  }
  
  // Log to external monitoring service
  if (process.env.NODE_ENV === 'production') {
    await fetch('https://monitoring-service.com/metrics', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(metrics)
    })
  }
}

// app/api/health/route.ts - Health check with usage logging
export async function GET() {
  await logUsageMetrics()
  
  return Response.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    region: process.env.VERCEL_REGION,
  })
}
```

### Common Next.js 15 Pitfalls to Avoid

1. **Not understanding Server vs Client Components**
2. **Fetching data in client components when server components would be better**
3. **Not using Image component for optimization**
4. **Importing large libraries in client components**
5. **Not implementing proper error boundaries**
6. **Forgetting to add 'use client' directive**
7. **Not optimizing bundle size with Turbopack**
8. **Using useEffect for data fetching instead of server components**
9. **Not implementing proper loading states**
10. **Ignoring TypeScript errors in Next.js 15**
11. **Overusing Edge Runtime for database operations**
12. **Not implementing proper caching strategies**
13. **Excessive function execution times on Vercel**
14. **Not monitoring Vercel usage and costs**
15. **Missing environment variable validation**

### Next.js 15 Performance Tips

1. **Use Turbopack for faster development builds**
2. **Leverage Server Components for data fetching**
3. **Implement Incremental Static Regeneration (ISR) with revalidateTag**
4. **Optimize images with next/image and AVIF format**
5. **Use dynamic imports for code splitting**
6. **Implement proper caching with Cache API**
7. **Minimize client-side JavaScript bundle size**
8. **Use Edge Runtime for geolocation and simple logic**
9. **Implement streaming with Suspense boundaries**
10. **Monitor Core Web Vitals with Vercel Analytics**
11. **Use Server Actions for form handling**
12. **Implement proper error boundaries at component level**
13. **Use React.memo() and useMemo() judiciously**
14. **Optimize font loading with next/font**
15. **Implement service worker for offline functionality**

### Essential Next.js 15 Libraries

**Core Dependencies**
- **next@15.x**: The framework itself
- **react@18.x**: React with concurrent features
- **typescript**: Type safety and developer experience

**Data Fetching & State Management**
- **@tanstack/react-query@5.x**: Server state management
- **swr@2.x**: Data fetching with caching
- **zustand**: Lightweight client state management
- **jotai**: Atomic state management

**Forms & Validation**
- **react-hook-form@7.x**: Performant form library
- **zod@3.x**: TypeScript-first schema validation
- **@hookform/resolvers**: Form validation resolvers

**Authentication & Security**
- **next-auth@5.x**: Authentication for Next.js
- **@auth/core**: Core authentication library
- **jose**: JWT utilities
- **bcryptjs**: Password hashing

**Database & ORM**
- **prisma@5.x**: Next-generation ORM
- **@prisma/client**: Database client
- **@vercel/postgres**: Vercel's PostgreSQL client
- **drizzle-orm**: Lightweight TypeScript ORM

**Styling & UI**
- **tailwindcss@3.x**: Utility-first CSS framework
- **@headlessui/react**: Unstyled UI components
- **framer-motion@11.x**: Motion library
- **lucide-react**: Icon library
- **class-variance-authority**: Variant-based styling

**Development & Testing**
- **@types/node**: Node.js type definitions
- **@types/react**: React type definitions
- **jest**: Testing framework
- **@testing-library/react**: React testing utilities
- **playwright**: E2E testing
- **eslint-config-next**: ESLint configuration
- **prettier**: Code formatting

**Performance & Monitoring**
- **@vercel/analytics**: Vercel Analytics
- **@sentry/nextjs**: Error monitoring
- **@next/bundle-analyzer**: Bundle analysis
- **sharp**: Image optimization (auto-installed)

**Utilities**
- **date-fns**: Date utility library
- **lodash**: Utility functions (use specific imports)
- **clsx**: Conditional className utility
- **nanoid**: Unique ID generation

### Next.js 15 Migration Checklist

1. **Update to Next.js 15**
   ```bash
   npm install next@15 react@18 react-dom@18
   ```

2. **Enable Turbopack (optional)**
   ```bash
   npm run dev --turbo
   ```

3. **Update TypeScript configuration**
   ```json
   {
     "compilerOptions": {
       "target": "ES2022",
       "moduleResolution": "bundler"
     }
   }
   ```

4. **Update middleware for Node.js APIs**
5. **Review and optimize bundle size**
6. **Test Edge Runtime compatibility**
7. **Update error handling patterns**
8. **Implement new caching strategies**
9. **Review Vercel deployment settings**
10. **Monitor performance metrics**