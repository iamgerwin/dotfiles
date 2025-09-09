# Clerk Authentication Best Practices

## Official Documentation
- **Clerk Documentation**: https://clerk.com/docs
- **Clerk Next.js Guide**: https://clerk.com/docs/quickstarts/nextjs
- **Clerk React Guide**: https://clerk.com/docs/quickstarts/react
- **Clerk API Reference**: https://clerk.com/docs/reference

## Overview

Clerk is a complete authentication and user management platform that provides drop-in UI components, flexible APIs, and admin dashboards for React applications.

## Installation & Setup

```bash
# Install Clerk for Next.js
npm install @clerk/nextjs

# Install Clerk for React
npm install @clerk/clerk-react
```

### Environment Variables

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_WEBHOOK_SECRET=whsec_...

# Optional: Custom domains
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
```

## Next.js Implementation

### 1. Root Layout Setup

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'
import { dark } from '@clerk/themes'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <ClerkProvider
      publishableKey={process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY!}
      appearance={{
        baseTheme: dark,
        variables: {
          colorPrimary: '#3b82f6',
          colorBackground: '#1f2937',
          colorInputBackground: '#374151',
          colorInputText: '#f9fafb',
        },
        elements: {
          formButtonPrimary: 'bg-blue-600 hover:bg-blue-700 transition-colors',
          card: 'bg-gray-800 border border-gray-700 shadow-xl',
          headerTitle: 'text-gray-100',
          headerSubtitle: 'text-gray-300',
        }
      }}
    >
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

### 2. Middleware Configuration

```typescript
// middleware.ts
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'

const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/admin(.*)',
  '/api/protected(.*)',
  '/profile(.*)',
  '/settings(.*)'
])

const isPublicRoute = createRouteMatcher([
  '/',
  '/about',
  '/contact',
  '/api/public(.*)',
  '/sign-in(.*)',
  '/sign-up(.*)'
])

export default clerkMiddleware((auth, req) => {
  // Allow public routes
  if (isPublicRoute(req)) {
    return
  }

  // Protect all other routes
  if (isProtectedRoute(req)) {
    auth().protect()
  }

  // Redirect unauthenticated users to sign-in
  if (!auth().userId && !isPublicRoute(req)) {
    return auth().redirectToSignIn()
  }
})

export const config = {
  matcher: [
    '/((?!.*\\..*|_next).*)',
    '/',
    '/(api|trpc)(.*)'
  ],
}
```

### 3. Authentication Pages

```typescript
// app/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from '@clerk/nextjs'

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <SignIn 
        appearance={{
          elements: {
            rootBox: "mx-auto",
            card: "shadow-2xl"
          }
        }}
        routing="path"
        path="/sign-in"
        afterSignInUrl="/dashboard"
        signUpUrl="/sign-up"
      />
    </div>
  )
}

// app/sign-up/[[...sign-up]]/page.tsx
import { SignUp } from '@clerk/nextjs'

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <SignUp 
        appearance={{
          elements: {
            rootBox: "mx-auto",
            card: "shadow-2xl"
          }
        }}
        routing="path"
        path="/sign-up"
        afterSignUpUrl="/onboarding"
        signInUrl="/sign-in"
      />
    </div>
  )
}
```

### 4. User Components

```typescript
// components/auth/UserProfile.tsx
'use client'

import { useUser, UserButton, SignInButton, SignUpButton } from '@clerk/nextjs'

export function UserProfile() {
  const { isSignedIn, user, isLoaded } = useUser()

  if (!isLoaded) {
    return <div className="animate-pulse w-8 h-8 bg-gray-300 rounded-full" />
  }

  if (!isSignedIn) {
    return (
      <div className="flex items-center gap-2">
        <SignInButton mode="modal">
          <button className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900">
            Sign in
          </button>
        </SignInButton>
        <SignUpButton mode="modal">
          <button className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700">
            Sign up
          </button>
        </SignUpButton>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-3">
      <div className="hidden sm:block">
        <p className="text-sm font-medium text-gray-900">
          Welcome back, {user.firstName}!
        </p>
        <p className="text-xs text-gray-500">
          {user.primaryEmailAddress?.emailAddress}
        </p>
      </div>
      <UserButton
        afterSignOutUrl="/"
        appearance={{
          elements: {
            avatarBox: "w-8 h-8",
            userButtonPopover: "shadow-lg border border-gray-200"
          }
        }}
      />
    </div>
  )
}

// components/auth/ProtectedRoute.tsx
'use client'

import { useAuth } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

interface ProtectedRouteProps {
  children: React.ReactNode
  fallback?: React.ReactNode
}

export function ProtectedRoute({ children, fallback }: ProtectedRouteProps) {
  const { isLoaded, userId } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (isLoaded && !userId) {
      router.push('/sign-in')
    }
  }, [isLoaded, userId, router])

  if (!isLoaded) {
    return (
      fallback || (
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      )
    )
  }

  if (!userId) {
    return null
  }

  return <>{children}</>
}
```

### 5. Server-Side Utilities

```typescript
// lib/clerk-utils.ts
import { auth, currentUser, clerkClient } from '@clerk/nextjs/server'
import { redirect } from 'next/navigation'

export async function getAuthenticatedUser() {
  const user = await currentUser()
  
  if (!user) {
    redirect('/sign-in')
  }
  
  return user
}

export async function requireAuth() {
  const { userId } = auth()
  
  if (!userId) {
    redirect('/sign-in')
  }
  
  return userId
}

export async function requireRole(role: string) {
  const user = await getAuthenticatedUser()
  
  const userRole = user.publicMetadata.role as string
  
  if (userRole !== role) {
    redirect('/unauthorized')
  }
  
  return user
}

export async function updateUserMetadata(userId: string, metadata: Record<string, any>) {
  return await clerkClient.users.updateUserMetadata(userId, {
    publicMetadata: metadata
  })
}

export async function getUsersByRole(role: string) {
  const users = await clerkClient.users.getUserList({
    limit: 100,
  })
  
  return users.filter(user => user.publicMetadata.role === role)
}
```

### 6. Database Sync with Webhooks

```typescript
// app/api/webhooks/clerk/route.ts
import { headers } from 'next/headers'
import { NextResponse } from 'next/server'
import { Webhook } from 'svix'
import { WebhookEvent } from '@clerk/nextjs/server'
import { db } from '@/lib/db'

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET

  if (!WEBHOOK_SECRET) {
    throw new Error('Please add CLERK_WEBHOOK_SECRET from Clerk Dashboard to .env.local')
  }

  // Get the headers
  const headerPayload = headers()
  const svix_id = headerPayload.get('svix-id')
  const svix_timestamp = headerPayload.get('svix-timestamp')
  const svix_signature = headerPayload.get('svix-signature')

  // If there are no headers, error out
  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response('Error occured -- no svix headers', {
      status: 400
    })
  }

  // Get the body
  const payload = await req.json()
  const body = JSON.stringify(payload)

  // Create a new Svix instance with your secret.
  const wh = new Webhook(WEBHOOK_SECRET)

  let evt: WebhookEvent

  // Verify the payload with the headers
  try {
    evt = wh.verify(body, {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature,
    }) as WebhookEvent
  } catch (err) {
    console.error('Error verifying webhook:', err)
    return new Response('Error occured', {
      status: 400
    })
  }

  // Handle the webhook
  const { id } = evt.data
  const eventType = evt.type

  try {
    switch (eventType) {
      case 'user.created':
        await db.user.create({
          data: {
            clerkId: id,
            email: evt.data.email_addresses[0]?.email_address || '',
            firstName: evt.data.first_name || '',
            lastName: evt.data.last_name || '',
            imageUrl: evt.data.image_url || '',
            role: evt.data.public_metadata?.role as string || 'user',
          },
        })
        break

      case 'user.updated':
        await db.user.update({
          where: { clerkId: id },
          data: {
            email: evt.data.email_addresses[0]?.email_address || '',
            firstName: evt.data.first_name || '',
            lastName: evt.data.last_name || '',
            imageUrl: evt.data.image_url || '',
            role: evt.data.public_metadata?.role as string || 'user',
          },
        })
        break

      case 'user.deleted':
        await db.user.delete({
          where: { clerkId: id },
        })
        break

      case 'session.created':
        console.log('User signed in:', evt.data.user_id)
        break

      case 'session.ended':
        console.log('User signed out:', evt.data.user_id)
        break

      default:
        console.log(`Unhandled webhook event type: ${eventType}`)
    }
  } catch (error) {
    console.error('Error handling webhook:', error)
    return new Response('Error processing webhook', { status: 500 })
  }

  return NextResponse.json({ success: true })
}
```

### 7. Custom Role Management

```typescript
// components/admin/UserManagement.tsx
'use client'

import { useState, useEffect } from 'react'
import { useUser } from '@clerk/nextjs'

interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  role: string
  imageUrl: string
}

export function UserManagement() {
  const { user: currentUser } = useUser()
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)

  const isAdmin = currentUser?.publicMetadata?.role === 'admin'

  useEffect(() => {
    if (isAdmin) {
      fetchUsers()
    }
  }, [isAdmin])

  const fetchUsers = async () => {
    try {
      const response = await fetch('/api/admin/users')
      const data = await response.json()
      setUsers(data)
    } catch (error) {
      console.error('Failed to fetch users:', error)
    } finally {
      setLoading(false)
    }
  }

  const updateUserRole = async (userId: string, role: string) => {
    try {
      const response = await fetch(`/api/admin/users/${userId}/role`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role }),
      })

      if (response.ok) {
        await fetchUsers() // Refresh the list
      }
    } catch (error) {
      console.error('Failed to update user role:', error)
    }
  }

  if (!isAdmin) {
    return (
      <div className="text-center py-8">
        <h2 className="text-xl font-semibold text-gray-900">Access Denied</h2>
        <p className="text-gray-600 mt-2">Admin privileges required</p>
      </div>
    )
  }

  if (loading) {
    return <div className="animate-pulse">Loading users...</div>
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold text-gray-900">User Management</h2>
      
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                User
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <img
                      className="h-10 w-10 rounded-full"
                      src={user.imageUrl}
                      alt=""
                    />
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900">
                        {user.firstName} {user.lastName}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {user.email}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                    user.role === 'admin' 
                      ? 'bg-red-100 text-red-800'
                      : user.role === 'moderator'
                      ? 'bg-yellow-100 text-yellow-800'
                      : 'bg-green-100 text-green-800'
                  }`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <select
                    value={user.role}
                    onChange={(e) => updateUserRole(user.id, e.target.value)}
                    className="rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                  >
                    <option value="user">User</option>
                    <option value="moderator">Moderator</option>
                    <option value="admin">Admin</option>
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

## Best Practices

### Security
1. **Environment Variables**: Always use environment variables for API keys
2. **Webhook Verification**: Always verify webhook signatures
3. **Role-Based Access**: Implement proper role-based access control
4. **HTTPS Only**: Use HTTPS in production for all Clerk endpoints

### Performance
1. **Lazy Loading**: Use dynamic imports for auth components when possible
2. **Caching**: Cache user data appropriately to reduce API calls
3. **Optimistic Updates**: Implement optimistic UI updates for better UX

### User Experience
1. **Loading States**: Always show loading states during auth operations
2. **Error Handling**: Provide clear error messages for auth failures
3. **Progressive Enhancement**: Ensure basic functionality works without JavaScript

### Development
1. **TypeScript**: Use TypeScript for better type safety with Clerk
2. **Testing**: Write tests for authentication flows
3. **Documentation**: Document custom auth logic and role systems

## Common Patterns

### Organization Management

```typescript
// lib/organization-utils.ts
import { auth, clerkClient } from '@clerk/nextjs/server'

export async function getCurrentOrganization() {
  const { orgId } = auth()
  
  if (!orgId) {
    return null
  }
  
  return await clerkClient.organizations.getOrganization({
    organizationId: orgId
  })
}

export async function requireOrganizationMembership() {
  const { userId, orgId } = auth()
  
  if (!userId || !orgId) {
    redirect('/select-organization')
  }
  
  return { userId, orgId }
}
```

### Multi-Tenant Applications

```typescript
// middleware.ts - Multi-tenant support
export default clerkMiddleware((auth, req) => {
  // Extract tenant from subdomain or path
  const url = new URL(req.url)
  const tenant = url.hostname.split('.')[0] // subdomain approach
  
  // Require organization for tenant-specific routes
  if (tenant !== 'www' && tenant !== 'app') {
    auth().protect({
      organizationId: tenant
    })
  }
})
```

This comprehensive guide covers all aspects of implementing Clerk authentication in modern React and Next.js applications with production-ready patterns and security best practices.