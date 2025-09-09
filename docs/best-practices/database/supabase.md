# Supabase Best Practices

## Official Documentation
- **Supabase Documentation**: https://supabase.com/docs
- **Supabase JavaScript Client**: https://supabase.com/docs/reference/javascript
- **Database Guide**: https://supabase.com/docs/guides/database
- **Auth Guide**: https://supabase.com/docs/guides/auth
- **Storage Guide**: https://supabase.com/docs/guides/storage

## Project Structure

```
supabase-project/
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_create_profiles_table.sql
│   │   └── 003_setup_storage.sql
│   ├── functions/
│   │   ├── hello-world/
│   │   │   └── index.ts
│   │   └── stripe-webhook/
│   │       └── index.ts
│   └── seed.sql
├── lib/
│   ├── supabase/
│   │   ├── client.ts
│   │   ├── server.ts
│   │   └── middleware.ts
│   ├── database.types.ts
│   └── hooks/
│       ├── useAuth.ts
│       ├── useProfiles.ts
│       └── useRealtime.ts
├── components/
│   ├── auth/
│   └── ui/
├── pages/
│   ├── auth/
│   ├── dashboard/
│   └── profile/
└── types/
    └── database.ts
```

## Core Best Practices

### 1. Database Schema Design

```sql
-- supabase/migrations/001_initial_schema.sql

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Custom types
CREATE TYPE user_role AS ENUM ('admin', 'user', 'moderator');
CREATE TYPE post_status AS ENUM ('draft', 'published', 'archived');

-- Users table (extends auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  role user_role DEFAULT 'user',
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts table
CREATE TABLE public.posts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  content TEXT,
  excerpt TEXT,
  featured_image TEXT,
  status post_status DEFAULT 'draft',
  author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  published_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments table
CREATE TABLE public.comments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_approved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX posts_author_id_idx ON public.posts(author_id);
CREATE INDEX posts_status_published_idx ON public.posts(status, published_at DESC) 
  WHERE status = 'published';
CREATE INDEX comments_post_id_idx ON public.comments(post_id);
CREATE INDEX comments_author_id_idx ON public.comments(author_id);
CREATE INDEX profiles_username_idx ON public.profiles(username);

-- Full text search
ALTER TABLE public.posts ADD COLUMN search_vector tsvector;
CREATE INDEX posts_search_idx ON public.posts USING gin(search_vector);

-- Update search vector function
CREATE OR REPLACE FUNCTION update_search_vector()
RETURNS trigger AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', 
    COALESCE(NEW.title, '') || ' ' || COALESCE(NEW.content, '') || ' ' || COALESCE(NEW.excerpt, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for search vector
CREATE TRIGGER posts_search_update 
  BEFORE INSERT OR UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION update_search_vector();
```

### 2. Row Level Security (RLS)

```sql
-- supabase/migrations/002_setup_rls.sql

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" 
  ON public.profiles FOR SELECT 
  USING (true);

CREATE POLICY "Users can update own profile" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
  ON public.profiles FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Posts policies
CREATE POLICY "Published posts are viewable by everyone" 
  ON public.posts FOR SELECT 
  USING (status = 'published' OR auth.uid() = author_id);

CREATE POLICY "Users can insert their own posts" 
  ON public.posts FOR INSERT 
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update their own posts" 
  ON public.posts FOR UPDATE 
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own posts" 
  ON public.posts FOR DELETE 
  USING (auth.uid() = author_id);

-- Admin override policy
CREATE POLICY "Admins can do everything on posts" 
  ON public.posts FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Comments policies
CREATE POLICY "Comments are viewable by everyone" 
  ON public.comments FOR SELECT 
  USING (true);

CREATE POLICY "Authenticated users can insert comments" 
  ON public.comments FOR INSERT 
  WITH CHECK (auth.uid() = author_id AND auth.role() = 'authenticated');

CREATE POLICY "Users can update their own comments" 
  ON public.comments FOR UPDATE 
  USING (auth.uid() = author_id);

-- Function to check user role
CREATE OR REPLACE FUNCTION public.is_admin(user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = user_id AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3. Client Setup and Configuration

```typescript
// lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../database.types'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

// Client-side Supabase client
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
  realtime: {
    params: {
      eventsPerSecond: 10,
    },
  },
})

// Server-side Supabase client (for API routes)
// lib/supabase/server.ts
import { createClient } from '@supabase/supabase-js'
import type { Database } from '../database.types'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

export const supabaseAdmin = createClient<Database>(
  supabaseUrl,
  supabaseServiceKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
)

// Middleware for server-side auth
// lib/supabase/middleware.ts
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })

  const {
    data: { session },
  } = await supabase.auth.getSession()

  // Redirect to login if not authenticated
  if (!session && req.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/auth/login', req.url))
  }

  // Redirect authenticated users away from auth pages
  if (session && req.nextUrl.pathname.startsWith('/auth')) {
    return NextResponse.redirect(new URL('/dashboard', req.url))
  }

  return res
}

export const config = {
  matcher: ['/dashboard/:path*', '/auth/:path*'],
}
```

### 4. Authentication Patterns

```typescript
// hooks/useAuth.ts
import { useEffect, useState } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '@/lib/supabase/client'
import type { User, Session } from '@supabase/supabase-js'

export interface AuthState {
  user: User | null
  session: Session | null
  loading: boolean
}

export const useAuth = () => {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    session: null,
    loading: true,
  })
  const router = useRouter()

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setAuthState({
        user: session?.user ?? null,
        session,
        loading: false,
      })
    })

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      setAuthState({
        user: session?.user ?? null,
        session,
        loading: false,
      })

      // Handle auth events
      if (event === 'SIGNED_IN') {
        router.push('/dashboard')
      } else if (event === 'SIGNED_OUT') {
        router.push('/auth/login')
      }
    })

    return () => subscription.unsubscribe()
  }, [router])

  const signUp = async (email: string, password: string, metadata?: any) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata,
      },
    })
    
    if (error) throw error
    return data
  }

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    
    if (error) throw error
    return data
  }

  const signInWithProvider = async (provider: 'google' | 'github') => {
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    })
    
    if (error) throw error
    return data
  }

  const signOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
  }

  const resetPassword = async (email: string) => {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/reset-password`,
    })
    
    if (error) throw error
    return data
  }

  const updatePassword = async (password: string) => {
    const { data, error } = await supabase.auth.updateUser({ password })
    if (error) throw error
    return data
  }

  return {
    ...authState,
    signUp,
    signIn,
    signInWithProvider,
    signOut,
    resetPassword,
    updatePassword,
  }
}

// Auth callback page
// pages/auth/callback.tsx
import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { supabase } from '@/lib/supabase/client'

export default function AuthCallback() {
  const router = useRouter()

  useEffect(() => {
    const { data: authListener } = supabase.auth.onAuthStateChange(
      (event, session) => {
        if (event === 'SIGNED_IN') {
          router.push('/dashboard')
        }
      }
    )

    return () => {
      authListener.subscription.unsubscribe()
    }
  }, [router])

  return <div>Loading...</div>
}
```

### 5. Database Operations and Hooks

```typescript
// hooks/useProfiles.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import type { Database } from '@/lib/database.types'

type Profile = Database['public']['Tables']['profiles']['Row']
type ProfileInsert = Database['public']['Tables']['profiles']['Insert']
type ProfileUpdate = Database['public']['Tables']['profiles']['Update']

export const useProfiles = () => {
  const [profiles, setProfiles] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchProfiles = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setProfiles(data || [])
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const getProfile = async (id: string) => {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  }

  const createProfile = async (profile: ProfileInsert) => {
    const { data, error } = await supabase
      .from('profiles')
      .insert(profile)
      .select()
      .single()

    if (error) throw error
    
    // Update local state
    setProfiles(prev => [data, ...prev])
    return data
  }

  const updateProfile = async (id: string, updates: ProfileUpdate) => {
    const { data, error } = await supabase
      .from('profiles')
      .update({
        ...updates,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single()

    if (error) throw error

    // Update local state
    setProfiles(prev =>
      prev.map(profile => profile.id === id ? data : profile)
    )
    return data
  }

  const deleteProfile = async (id: string) => {
    const { error } = await supabase
      .from('profiles')
      .delete()
      .eq('id', id)

    if (error) throw error

    // Update local state
    setProfiles(prev => prev.filter(profile => profile.id !== id))
  }

  useEffect(() => {
    fetchProfiles()
  }, [])

  return {
    profiles,
    loading,
    error,
    getProfile,
    createProfile,
    updateProfile,
    deleteProfile,
    refetch: fetchProfiles,
  }
}

// hooks/usePosts.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import type { Database } from '@/lib/database.types'

type Post = Database['public']['Tables']['posts']['Row']
type PostWithAuthor = Post & {
  profiles: Pick<Database['public']['Tables']['profiles']['Row'], 'username' | 'full_name' | 'avatar_url'>
}

interface PostsParams {
  limit?: number
  offset?: number
  authorId?: string
  status?: string
  search?: string
}

export const usePosts = (params: PostsParams = {}) => {
  const [posts, setPosts] = useState<PostWithAuthor[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [hasMore, setHasMore] = useState(true)

  const fetchPosts = async (reset = false) => {
    try {
      setLoading(true)
      let query = supabase
        .from('posts')
        .select(`
          *,
          profiles:author_id (
            username,
            full_name,
            avatar_url
          )
        `)
        .order('published_at', { ascending: false, nullsFirst: false })

      // Apply filters
      if (params.status) {
        query = query.eq('status', params.status)
      }

      if (params.authorId) {
        query = query.eq('author_id', params.authorId)
      }

      if (params.search) {
        query = query.textSearch('search_vector', params.search)
      }

      // Apply pagination
      const limit = params.limit || 20
      const offset = reset ? 0 : params.offset || 0
      
      query = query.range(offset, offset + limit - 1)

      const { data, error } = await query

      if (error) throw error

      const newPosts = data as PostWithAuthor[] || []
      
      if (reset) {
        setPosts(newPosts)
      } else {
        setPosts(prev => [...prev, ...newPosts])
      }

      setHasMore(newPosts.length === limit)
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const searchPosts = async (searchTerm: string) => {
    const { data, error } = await supabase
      .from('posts')
      .select(`
        *,
        profiles:author_id (
          username,
          full_name,
          avatar_url
        )
      `)
      .textSearch('search_vector', searchTerm)
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .limit(20)

    if (error) throw error
    return data as PostWithAuthor[]
  }

  useEffect(() => {
    fetchPosts(true)
  }, [params.status, params.authorId, params.search])

  return {
    posts,
    loading,
    error,
    hasMore,
    searchPosts,
    loadMore: () => fetchPosts(false),
    refetch: () => fetchPosts(true),
  }
}
```

### 6. Realtime Subscriptions

```typescript
// hooks/useRealtime.ts
import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase/client'
import { RealtimeChannel } from '@supabase/supabase-js'

export const useRealtimeSubscription = <T>(
  table: string,
  filters?: { column: string; value: any }[]
) => {
  const [data, setData] = useState<T[]>([])
  const [channel, setChannel] = useState<RealtimeChannel | null>(null)

  useEffect(() => {
    let subscription = supabase
      .channel(`public:${table}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: table,
        },
        (payload) => {
          const { eventType, new: newRecord, old: oldRecord } = payload

          switch (eventType) {
            case 'INSERT':
              setData((current) => [...current, newRecord as T])
              break
            case 'UPDATE':
              setData((current) =>
                current.map((item: any) =>
                  item.id === newRecord.id ? newRecord : item
                )
              )
              break
            case 'DELETE':
              setData((current) =>
                current.filter((item: any) => item.id !== oldRecord.id)
              )
              break
          }
        }
      )
      .subscribe()

    setChannel(subscription)

    return () => {
      supabase.removeChannel(subscription)
    }
  }, [table])

  const insert = (record: Omit<T, 'id' | 'created_at' | 'updated_at'>) => {
    return supabase.from(table).insert(record)
  }

  const update = (id: string, updates: Partial<T>) => {
    return supabase.from(table).update(updates).eq('id', id)
  }

  const remove = (id: string) => {
    return supabase.from(table).delete().eq('id', id)
  }

  return {
    data,
    channel,
    insert,
    update,
    remove,
  }
}

// Live chat component example
// components/LiveChat.tsx
import { useEffect, useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { useRealtimeSubscription } from '@/hooks/useRealtime'

interface Message {
  id: string
  content: string
  user_id: string
  room_id: string
  created_at: string
  profiles: {
    username: string
    avatar_url: string
  }
}

export const LiveChat = ({ roomId }: { roomId: string }) => {
  const { user } = useAuth()
  const [messages, setMessages] = useState<Message[]>([])
  const [newMessage, setNewMessage] = useState('')

  // Subscribe to new messages in real-time
  useEffect(() => {
    const channel = supabase
      .channel(`room-${roomId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `room_id=eq.${roomId}`,
        },
        (payload) => {
          setMessages((current) => [...current, payload.new as Message])
        }
      )
      .subscribe()

    // Fetch existing messages
    const fetchMessages = async () => {
      const { data } = await supabase
        .from('messages')
        .select(`
          *,
          profiles:user_id (
            username,
            avatar_url
          )
        `)
        .eq('room_id', roomId)
        .order('created_at', { ascending: true })

      if (data) setMessages(data as Message[])
    }

    fetchMessages()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [roomId])

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim() || !user) return

    const { error } = await supabase.from('messages').insert({
      content: newMessage,
      user_id: user.id,
      room_id: roomId,
    })

    if (!error) {
      setNewMessage('')
    }
  }

  return (
    <div className="flex flex-col h-96">
      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {messages.map((message) => (
          <div key={message.id} className="flex items-start space-x-2">
            <img
              src={message.profiles.avatar_url}
              alt={message.profiles.username}
              className="w-8 h-8 rounded-full"
            />
            <div>
              <span className="font-semibold text-sm">
                {message.profiles.username}
              </span>
              <p className="text-gray-700">{message.content}</p>
            </div>
          </div>
        ))}
      </div>
      
      <form onSubmit={sendMessage} className="p-4 border-t">
        <div className="flex space-x-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="Type a message..."
            className="flex-1 px-3 py-2 border rounded-md"
          />
          <button
            type="submit"
            disabled={!newMessage.trim()}
            className="px-4 py-2 bg-blue-500 text-white rounded-md disabled:opacity-50"
          >
            Send
          </button>
        </div>
      </form>
    </div>
  )
}
```

### 7. Storage Management

```typescript
// lib/storage.ts
import { supabase } from '@/lib/supabase/client'

export class StorageManager {
  static async uploadFile(
    bucket: string,
    path: string,
    file: File,
    options?: {
      cacheControl?: string
      upsert?: boolean
      onProgress?: (progress: number) => void
    }
  ) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(path, file, {
        cacheControl: options?.cacheControl || '3600',
        upsert: options?.upsert || false,
      })

    if (error) throw error
    return data
  }

  static async downloadFile(bucket: string, path: string) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .download(path)

    if (error) throw error
    return data
  }

  static getPublicUrl(bucket: string, path: string) {
    const { data } = supabase.storage
      .from(bucket)
      .getPublicUrl(path)

    return data.publicUrl
  }

  static async deleteFile(bucket: string, path: string) {
    const { error } = await supabase.storage
      .from(bucket)
      .remove([path])

    if (error) throw error
  }

  static async listFiles(bucket: string, folder?: string) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .list(folder, {
        limit: 100,
        offset: 0,
        sortBy: { column: 'name', order: 'asc' },
      })

    if (error) throw error
    return data
  }

  static async createSignedUrl(
    bucket: string,
    path: string,
    expiresIn: number = 3600
  ) {
    const { data, error } = await supabase.storage
      .from(bucket)
      .createSignedUrl(path, expiresIn)

    if (error) throw error
    return data.signedUrl
  }
}

// Avatar upload component
// components/AvatarUpload.tsx
import { useState } from 'react'
import { StorageManager } from '@/lib/storage'
import { useAuth } from '@/hooks/useAuth'

export const AvatarUpload = () => {
  const { user } = useAuth()
  const [uploading, setUploading] = useState(false)
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null)

  const uploadAvatar = async (event: React.ChangeEvent<HTMLInputElement>) => {
    try {
      setUploading(true)

      if (!event.target.files || event.target.files.length === 0) {
        throw new Error('You must select an image to upload.')
      }

      const file = event.target.files[0]
      const fileExt = file.name.split('.').pop()
      const fileName = `${user?.id}.${fileExt}`
      const filePath = `avatars/${fileName}`

      // Upload file
      await StorageManager.uploadFile('avatars', filePath, file, {
        upsert: true,
      })

      // Get public URL
      const publicUrl = StorageManager.getPublicUrl('avatars', filePath)
      
      // Update profile
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ avatar_url: publicUrl })
        .eq('id', user?.id)

      if (updateError) throw updateError

      setAvatarUrl(publicUrl)
    } catch (error: any) {
      alert(error.message)
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="flex flex-col items-center space-y-4">
      {avatarUrl ? (
        <img
          src={avatarUrl}
          alt="Avatar"
          className="w-32 h-32 rounded-full object-cover"
        />
      ) : (
        <div className="w-32 h-32 bg-gray-200 rounded-full flex items-center justify-center">
          <span className="text-gray-500">No avatar</span>
        </div>
      )}
      
      <label className="cursor-pointer">
        <input
          type="file"
          accept="image/*"
          onChange={uploadAvatar}
          disabled={uploading}
          className="hidden"
        />
        <div className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600">
          {uploading ? 'Uploading...' : 'Upload Avatar'}
        </div>
      </label>
    </div>
  )
}
```

### Common Pitfalls to Avoid

1. **Not enabling Row Level Security (RLS)**
2. **Exposing service role key on client-side**
3. **Not handling real-time subscription cleanup**
4. **Ignoring database performance optimization**
5. **Not implementing proper error handling**
6. **Missing proper type safety**
7. **Not using connection pooling in production**
8. **Forgetting to handle auth state changes**
9. **Not optimizing queries with proper indexes**
10. **Ignoring storage bucket policies**

### Performance Tips

1. **Use database indexes strategically**
2. **Implement proper RLS policies**
3. **Use select() to limit returned columns**
4. **Implement pagination for large datasets**
5. **Use connection pooling (pgBouncer)**
6. **Cache frequently accessed data**
7. **Optimize real-time subscriptions**
8. **Use CDN for static storage files**
9. **Monitor database performance**
10. **Implement proper error boundaries**

### Useful Libraries

- **@supabase/supabase-js**: Official JavaScript client
- **@supabase/auth-helpers-nextjs**: Next.js auth helpers
- **@supabase/auth-ui-react**: Pre-built auth components
- **@supabase/realtime-js**: Realtime subscriptions
- **swr**: Data fetching with caching
- **react-query**: Advanced data fetching
- **zod**: Runtime type validation
- **next-superjson-plugin**: JSON serialization
- **react-hook-form**: Form handling
- **react-dropzone**: File upload handling