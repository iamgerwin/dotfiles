# Next.js Best Practices

## Official Documentation
- **Next.js Documentation**: https://nextjs.org/docs
- **Next.js Learn**: https://nextjs.org/learn
- **Next.js Examples**: https://github.com/vercel/next.js/tree/canary/examples
- **Vercel Documentation**: https://vercel.com/docs

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

### 1. App Router Best Practices (Next.js 14+)

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

### 11. Deployment Configuration

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['images.example.com'],
    formats: ['image/avif', 'image/webp'],
  },
  experimental: {
    serverActions: true,
  },
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
      ],
    },
  ],
}

module.exports = nextConfig
```

### Common Pitfalls to Avoid

1. **Not understanding Server vs Client Components**
2. **Fetching data in client components when server components would be better**
3. **Not using Image component for optimization**
4. **Importing large libraries in client components**
5. **Not implementing proper error boundaries**
6. **Forgetting to add 'use client' directive**
7. **Not optimizing bundle size**
8. **Using useEffect for data fetching instead of server components**
9. **Not implementing proper loading states**
10. **Ignoring TypeScript errors**

### Performance Tips

1. **Use Static Generation when possible**
2. **Implement Incremental Static Regeneration (ISR)**
3. **Optimize images with next/image**
4. **Use dynamic imports for code splitting**
5. **Implement proper caching strategies**
6. **Minimize client-side JavaScript**
7. **Use React Server Components effectively**
8. **Implement streaming for better perceived performance**
9. **Use Edge Runtime for faster responses**
10. **Monitor Core Web Vitals**

### Useful Libraries

- **@tanstack/react-query**: Data fetching and caching
- **swr**: Data fetching with caching
- **zod**: Schema validation
- **react-hook-form**: Form handling
- **next-auth**: Authentication
- **prisma**: Database ORM
- **tailwindcss**: Utility-first CSS
- **framer-motion**: Animations
- **react-testing-library**: Testing utilities
- **playwright**: E2E testing