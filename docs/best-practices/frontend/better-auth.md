# Better Auth Best Practices

## Official Documentation
- **Better Auth Documentation**: https://better-auth.com
- **Better Auth GitHub**: https://github.com/better-auth/better-auth
- **Examples**: https://github.com/better-auth/better-auth/tree/main/examples

## Overview

Better Auth is a comprehensive authentication library for TypeScript applications that focuses on simplicity, security, and developer experience. It provides a complete authentication solution with built-in support for various providers, databases, and frameworks.

## Installation & Setup

```bash
# Core package
npm install better-auth

# Database adapters (choose one)
npm install better-auth-adapter-prisma
npm install better-auth-adapter-drizzle
npm install better-auth-adapter-kysely

# Framework-specific packages
npm install @better-auth/react        # For React
npm install @better-auth/next-js      # For Next.js
npm install @better-auth/vue          # For Vue
npm install @better-auth/svelte       # For Svelte
```

## Core Configuration

### 1. Server Setup

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth"
import { prismaAdapter } from "better-auth/adapters/prisma"
import { db } from "./db"

export const auth = betterAuth({
  database: prismaAdapter(db, {
    provider: "postgresql" // or "mysql", "sqlite"
  }),
  
  // Basic configuration
  baseURL: process.env.BETTER_AUTH_BASE_URL || "http://localhost:3000",
  basePath: "/api/auth",
  
  // Email and password authentication
  emailAndPassword: {
    enabled: true,
    requireEmailVerification: true,
    minPasswordLength: 8,
    maxPasswordLength: 128,
    passwordStrength: {
      requireLowercase: true,
      requireUppercase: true,
      requireNumbers: true,
      requireSpecialCharacters: true,
    },
  },

  // Social providers
  socialProviders: {
    github: {
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    },
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    },
    discord: {
      clientId: process.env.DISCORD_CLIENT_ID!,
      clientSecret: process.env.DISCORD_CLIENT_SECRET!,
    },
  },

  // Session configuration
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24, // 1 day (update if session is older than this)
    cookieCache: {
      enabled: true,
      maxAge: 60 * 5, // 5 minutes
    },
  },

  // Security settings
  advanced: {
    crossSubDomainCookies: {
      enabled: false, // Set to true for multi-subdomain apps
      domain: undefined,
    },
    useSecureCookies: process.env.NODE_ENV === "production",
    generateId: () => crypto.randomUUID(), // Custom ID generation
  },

  // Rate limiting
  rateLimit: {
    enabled: true,
    window: 60, // 1 minute
    max: 10, // 10 requests per window
    storage: "memory", // or "redis" for production
  },

  // Email configuration
  emailVerification: {
    sendOnSignUp: true,
    autoSignInAfterVerification: true,
    expiresIn: 60 * 60 * 24, // 24 hours
  },

  // Password reset
  resetPassword: {
    enabled: true,
    expiresIn: 60 * 60, // 1 hour
  },

  // Account linking
  accountLinking: {
    enabled: true,
    trustedProviders: ["github", "google"],
  },

  // Two-factor authentication
  twoFactor: {
    enabled: true,
    issuer: "Your App Name",
  },

  // Plugins
  plugins: [
    // Custom plugin example
    {
      id: "custom-logger",
      init: (options) => {
        return {
          hooks: {
            before: [
              {
                matcher: (context) => true,
                handler: async (request) => {
                  console.log(`Auth request: ${request.method} ${request.url}`)
                },
              },
            ],
            after: [
              {
                matcher: (context) => context.path === "/sign-in",
                handler: async (request, context) => {
                  if (context.returned?.user) {
                    console.log(`User signed in: ${context.returned.user.email}`)
                  }
                },
              },
            ],
          },
        }
      },
    },
  ],

  // Custom callbacks
  callbacks: {
    signUp: {
      before: async (user) => {
        // Custom validation or processing before sign up
        if (user.email.endsWith('@blocked-domain.com')) {
          throw new Error('Email domain not allowed')
        }
        return user
      },
      after: async (user, request) => {
        // Actions after successful sign up
        await sendWelcomeEmail(user.email)
        await createUserProfile(user.id)
      },
    },
    signIn: {
      before: async (user) => {
        // Check if user is banned
        const userRecord = await db.user.findUnique({
          where: { id: user.id }
        })
        if (userRecord?.status === 'banned') {
          throw new Error('Account suspended')
        }
        return user
      },
      after: async (user, request) => {
        // Log sign in activity
        await db.userActivity.create({
          data: {
            userId: user.id,
            action: 'SIGN_IN',
            ip: request.headers.get('x-forwarded-for') || 'unknown',
            userAgent: request.headers.get('user-agent') || 'unknown',
            timestamp: new Date(),
          }
        })
      },
    },
  },
})
```

### 2. Next.js Integration

```typescript
// app/api/auth/[...auth]/route.ts
import { auth } from "@/lib/auth"

export const { GET, POST } = auth.handler

// middleware.ts
import { NextRequest, NextResponse } from 'next/server'
import { auth } from './lib/auth'

export async function middleware(request: NextRequest) {
  const session = await auth.api.getSession({
    headers: request.headers
  })

  const isAuthPage = request.nextUrl.pathname.startsWith('/auth/')
  const isProtectedRoute = request.nextUrl.pathname.startsWith('/dashboard')

  // Redirect authenticated users away from auth pages
  if (session && isAuthPage) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // Redirect unauthenticated users to sign in
  if (!session && isProtectedRoute) {
    const redirectUrl = new URL('/auth/sign-in', request.url)
    redirectUrl.searchParams.set('callbackUrl', request.url)
    return NextResponse.redirect(redirectUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}
```

### 3. Client-Side Setup

```typescript
// lib/auth-client.ts
import { createAuthClient } from "@better-auth/react"

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000",
  basePath: "/api/auth"
})

export const {
  signIn,
  signUp,
  signOut,
  useSession,
  getSession,
} = authClient

// components/providers/AuthProvider.tsx
"use client"

import { SessionProvider } from "@better-auth/react"
import { authClient } from "@/lib/auth-client"

export function AuthProvider({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider client={authClient}>
      {children}
    </SessionProvider>
  )
}
```

## React Components

### 1. Authentication Forms

```typescript
// components/auth/SignInForm.tsx
"use client"

import { useState } from 'react'
import { signIn } from '@/lib/auth-client'
import { useRouter, useSearchParams } from 'next/navigation'

export function SignInForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  
  const router = useRouter()
  const searchParams = useSearchParams()
  const callbackUrl = searchParams.get('callbackUrl') || '/dashboard'

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    try {
      const result = await signIn.email({
        email,
        password,
      })

      if (result.error) {
        setError(result.error.message)
      } else {
        router.push(callbackUrl)
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Email address
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium text-gray-700">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      {error && (
        <div className="rounded-md bg-red-50 p-4">
          <div className="text-sm text-red-700">{error}</div>
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isLoading ? (
          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
        ) : (
          'Sign in'
        )}
      </button>
    </form>
  )
}

// components/auth/SignUpForm.tsx
"use client"

import { useState } from 'react'
import { signUp } from '@/lib/auth-client'
import { useRouter } from 'next/navigation'

interface SignUpFormData {
  name: string
  email: string
  password: string
  confirmPassword: string
}

export function SignUpForm() {
  const [formData, setFormData] = useState<SignUpFormData>({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  
  const router = useRouter()

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError('')

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match')
      setIsLoading(false)
      return
    }

    try {
      const result = await signUp.email({
        name: formData.name,
        email: formData.email,
        password: formData.password,
      })

      if (result.error) {
        setError(result.error.message)
      } else {
        setSuccess(true)
        // Redirect to verification page or dashboard
        setTimeout(() => router.push('/auth/verify-email'), 2000)
      }
    } catch (err) {
      setError('An unexpected error occurred')
    } finally {
      setIsLoading(false)
    }
  }

  if (success) {
    return (
      <div className="text-center">
        <div className="rounded-md bg-green-50 p-4">
          <div className="text-sm text-green-700">
            Account created successfully! Please check your email to verify your account.
          </div>
        </div>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Full Name
        </label>
        <input
          id="name"
          name="name"
          type="text"
          autoComplete="name"
          required
          value={formData.name}
          onChange={handleChange}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Email address
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          value={formData.email}
          onChange={handleChange}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium text-gray-700">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="new-password"
          required
          value={formData.password}
          onChange={handleChange}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      <div>
        <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700">
          Confirm Password
        </label>
        <input
          id="confirmPassword"
          name="confirmPassword"
          type="password"
          autoComplete="new-password"
          required
          value={formData.confirmPassword}
          onChange={handleChange}
          className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
        />
      </div>

      {error && (
        <div className="rounded-md bg-red-50 p-4">
          <div className="text-sm text-red-700">{error}</div>
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isLoading ? (
          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
        ) : (
          'Create Account'
        )}
      </button>
    </form>
  )
}
```

### 2. Social Authentication

```typescript
// components/auth/SocialButtons.tsx
"use client"

import { signIn } from '@/lib/auth-client'
import { useState } from 'react'

export function SocialButtons() {
  const [loadingProvider, setLoadingProvider] = useState<string | null>(null)

  const handleSocialSignIn = async (provider: 'github' | 'google' | 'discord') => {
    setLoadingProvider(provider)
    try {
      await signIn.social({
        provider,
        callbackURL: '/dashboard',
      })
    } catch (error) {
      console.error(`${provider} sign in failed:`, error)
    } finally {
      setLoadingProvider(null)
    }
  }

  const providers = [
    {
      id: 'github' as const,
      name: 'GitHub',
      icon: (
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fillRule="evenodd" d="M10 0C4.477 0 0 4.484 0 10.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0110 4.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.203 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.942.359.31.678.921.678 1.856 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0020 10.017C20 4.484 15.522 0 10 0z" clipRule="evenodd" />
        </svg>
      ),
    },
    {
      id: 'google' as const,
      name: 'Google',
      icon: (
        <svg className="w-5 h-5" viewBox="0 0 24 24">
          <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
          <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
          <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
          <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
        </svg>
      ),
    },
    {
      id: 'discord' as const,
      name: 'Discord',
      icon: (
        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
          <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515a.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0a12.64 12.64 0 0 0-.617-1.25a.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057a19.9 19.9 0 0 0 5.993 3.03a.078.078 0 0 0 .084-.028a14.09 14.09 0 0 0 1.226-1.994a.076.076 0 0 0-.041-.106a13.107 13.107 0 0 1-1.872-.892a.077.077 0 0 1-.008-.128a10.2 10.2 0 0 0 .372-.292a.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127a12.299 12.299 0 0 1-1.873.892a.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028a19.839 19.839 0 0 0 6.002-3.03a.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.956-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419c0-1.333.955-2.419 2.157-2.419c1.21 0 2.176 1.096 2.157 2.42c0 1.333-.946 2.418-2.157 2.418z"/>
        </svg>
      ),
    },
  ]

  return (
    <div className="space-y-3">
      {providers.map((provider) => (
        <button
          key={provider.id}
          onClick={() => handleSocialSignIn(provider.id)}
          disabled={loadingProvider === provider.id}
          className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loadingProvider === provider.id ? (
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-600"></div>
          ) : (
            <>
              {provider.icon}
              <span className="ml-2">Continue with {provider.name}</span>
            </>
          )}
        </button>
      ))}
    </div>
  )
}
```

### 3. Session Management

```typescript
// components/auth/UserMenu.tsx
"use client"

import { useSession, signOut } from '@/lib/auth-client'
import { useState } from 'react'

export function UserMenu() {
  const { data: session, isPending } = useSession()
  const [isOpen, setIsOpen] = useState(false)

  const handleSignOut = async () => {
    await signOut()
    setIsOpen(false)
  }

  if (isPending) {
    return (
      <div className="animate-pulse w-8 h-8 bg-gray-300 rounded-full"></div>
    )
  }

  if (!session) {
    return null
  }

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center space-x-2 text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        <img
          className="h-8 w-8 rounded-full"
          src={session.user.image || `https://ui-avatars.com/api/?name=${session.user.name}&background=6366f1&color=fff`}
          alt={session.user.name}
        />
        <span className="hidden md:block text-gray-700">{session.user.name}</span>
      </button>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />
          <div className="absolute right-0 z-20 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
            <div className="px-4 py-2 text-sm text-gray-700 border-b border-gray-100">
              <div className="font-medium">{session.user.name}</div>
              <div className="text-gray-500">{session.user.email}</div>
            </div>
            
            <a
              href="/profile"
              className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
              onClick={() => setIsOpen(false)}
            >
              Your Profile
            </a>
            
            <a
              href="/settings"
              className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
              onClick={() => setIsOpen(false)}
            >
              Settings
            </a>
            
            <button
              onClick={handleSignOut}
              className="block w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
            >
              Sign out
            </button>
          </div>
        </>
      )}
    </div>
  )
}

// components/auth/ProtectedRoute.tsx
"use client"

import { useSession } from '@/lib/auth-client'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

interface ProtectedRouteProps {
  children: React.ReactNode
  fallback?: React.ReactNode
  redirectTo?: string
}

export function ProtectedRoute({ 
  children, 
  fallback, 
  redirectTo = '/auth/sign-in' 
}: ProtectedRouteProps) {
  const { data: session, isPending } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (!isPending && !session) {
      router.push(redirectTo)
    }
  }, [isPending, session, router, redirectTo])

  if (isPending) {
    return (
      fallback || (
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      )
    )
  }

  if (!session) {
    return null
  }

  return <>{children}</>
}
```

## Advanced Features

### 1. Two-Factor Authentication

```typescript
// components/auth/TwoFactorSetup.tsx
"use client"

import { useState } from 'react'
import { authClient } from '@/lib/auth-client'
import QRCode from 'qrcode'

export function TwoFactorSetup() {
  const [qrCode, setQrCode] = useState('')
  const [backupCodes, setBackupCodes] = useState<string[]>([])
  const [verificationCode, setVerificationCode] = useState('')
  const [isEnabled, setIsEnabled] = useState(false)

  const generateQR = async () => {
    try {
      const response = await authClient.twoFactor.setup()
      const qrDataURL = await QRCode.toDataURL(response.uri)
      setQrCode(qrDataURL)
      setBackupCodes(response.backupCodes)
    } catch (error) {
      console.error('Failed to setup 2FA:', error)
    }
  }

  const verifyAndEnable = async () => {
    try {
      await authClient.twoFactor.verify({
        code: verificationCode
      })
      setIsEnabled(true)
    } catch (error) {
      console.error('Failed to verify 2FA:', error)
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-medium text-gray-900">Two-Factor Authentication</h3>
        <p className="text-sm text-gray-600">Add an extra layer of security to your account</p>
      </div>

      {!qrCode ? (
        <button
          onClick={generateQR}
          className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
        >
          Setup Two-Factor Authentication
        </button>
      ) : (
        <div className="space-y-4">
          <div>
            <h4 className="font-medium">1. Scan QR Code</h4>
            <p className="text-sm text-gray-600 mb-4">
              Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)
            </p>
            <img src={qrCode} alt="2FA QR Code" className="border rounded" />
          </div>

          <div>
            <h4 className="font-medium">2. Backup Codes</h4>
            <p className="text-sm text-gray-600 mb-2">
              Save these backup codes in a safe place. You can use them to access your account if you lose your phone.
            </p>
            <div className="bg-gray-100 p-4 rounded font-mono text-sm">
              {backupCodes.map((code, index) => (
                <div key={index}>{code}</div>
              ))}
            </div>
          </div>

          <div>
            <h4 className="font-medium">3. Verify Setup</h4>
            <p className="text-sm text-gray-600 mb-2">
              Enter the 6-digit code from your authenticator app
            </p>
            <div className="flex space-x-2">
              <input
                type="text"
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value)}
                placeholder="123456"
                className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                maxLength={6}
              />
              <button
                onClick={verifyAndEnable}
                disabled={verificationCode.length !== 6}
                className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
              >
                Verify & Enable
              </button>
            </div>
          </div>

          {isEnabled && (
            <div className="rounded-md bg-green-50 p-4">
              <div className="text-sm text-green-700">
                Two-factor authentication has been enabled successfully!
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
```

## Best Practices

### 1. Security
- Always use HTTPS in production
- Implement rate limiting to prevent brute force attacks
- Use secure session configuration with appropriate expiration
- Validate and sanitize all user inputs
- Implement proper CSRF protection

### 2. Performance
- Use session caching to reduce database queries
- Implement proper loading states in UI components
- Cache user data appropriately
- Use server-side rendering for initial auth state

### 3. User Experience
- Provide clear error messages for authentication failures
- Implement proper loading states during auth operations
- Support multiple authentication methods
- Provide account recovery options

### 4. Development
- Use TypeScript for better type safety
- Write comprehensive tests for authentication flows
- Document custom auth logic and configurations
- Monitor authentication metrics and errors

This comprehensive guide provides everything needed to implement Better Auth in modern web applications with security, performance, and user experience best practices.