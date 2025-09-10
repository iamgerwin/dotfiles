# Technology Stacks Best Practices

## Overview
A technology stack is a combination of programming languages, frameworks, libraries, and tools used to build and run applications. This guide covers best practices for popular, battle-tested technology stacks.

## Table of Contents
- [LAMP Stack](#lamp-stack)
- [MERN Stack](#mern-stack)
- [MEAN Stack](#mean-stack)
- [MEVN Stack](#mevn-stack)
- [JAMstack](#jamstack)
- [PERN Stack](#pern-stack)
- [Django Stack](#django-stack)
- [Ruby on Rails Stack](#ruby-on-rails-stack)
- [.NET Stack](#net-stack)
- [T3 Stack](#t3-stack)
- [TALL Stack](#tall-stack)
- [VILT Stack](#vilt-stack)

---

## LAMP Stack
**Linux + Apache + MySQL + PHP**

### Architecture
```
┌─────────────────────────┐
│     Client Browser      │
└────────────┬────────────┘
             │ HTTP/HTTPS
┌────────────▼────────────┐
│     Apache Server       │
│   ┌─────────────────┐   │
│   │   PHP Engine    │   │
│   └────────┬────────┘   │
└────────────┼────────────┘
             │
┌────────────▼────────────┐
│     MySQL Database      │
└─────────────────────────┘
```

### Setup and Configuration

#### Apache Configuration
```apache
# /etc/apache2/sites-available/app.conf
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # PHP Configuration
    <FilesMatch \.php$>
        SetHandler application/x-httpd-php
    </FilesMatch>
    
    # Security Headers
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-Content-Type-Options "nosniff"
    Header set X-XSS-Protection "1; mode=block"
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

#### PHP Configuration
```ini
; php.ini optimizations
memory_limit = 256M
max_execution_time = 300
upload_max_filesize = 64M
post_max_size = 64M

; Security settings
expose_php = Off
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log

; Performance
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
```

#### MySQL Optimization
```sql
-- my.cnf optimizations
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

query_cache_type = 1
query_cache_size = 128M
query_cache_limit = 2M

max_connections = 200
thread_cache_size = 8
table_open_cache = 4000
```

### Best Practices
- Use PHP-FPM instead of mod_php for better performance
- Implement OPcache for PHP bytecode caching
- Use prepared statements to prevent SQL injection
- Enable HTTPS with Let's Encrypt
- Implement proper logging and monitoring
- Use Composer for PHP dependency management

---

## MERN Stack
**MongoDB + Express.js + React + Node.js**

### Project Structure
```
mern-app/
├── client/                 # React frontend
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── context/
│   │   ├── utils/
│   │   └── App.jsx
│   └── package.json
├── server/                 # Express backend
│   ├── config/
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── middleware/
│   ├── utils/
│   └── server.js
├── shared/                 # Shared types/constants
└── docker-compose.yml
```

### Backend Setup (Express + MongoDB)
```javascript
// server/server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const app = express();

// Security middleware
app.use(helmet());
app.use(cors({
    origin: process.env.CLIENT_URL,
    credentials: true
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api', limiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/posts', require('./routes/posts'));

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

### Frontend Setup (React)
```javascript
// client/src/App.jsx
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './context/AuthContext';

const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            staleTime: 5 * 60 * 1000, // 5 minutes
            cacheTime: 10 * 60 * 1000, // 10 minutes
            retry: 1
        }
    }
});

function App() {
    return (
        <QueryClientProvider client={queryClient}>
            <AuthProvider>
                <Router>
                    <Routes>
                        <Route path="/" element={<Home />} />
                        <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
                        <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
                    </Routes>
                </Router>
            </AuthProvider>
        </QueryClientProvider>
    );
}
```

### API Service Layer
```javascript
// client/src/services/api.js
class ApiService {
    constructor() {
        this.baseURL = process.env.REACT_APP_API_URL;
    }
    
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };
        
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        
        const response = await fetch(url, config);
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.statusText}`);
        }
        
        return response.json();
    }
    
    get(endpoint) {
        return this.request(endpoint, { method: 'GET' });
    }
    
    post(endpoint, data) {
        return this.request(endpoint, {
            method: 'POST',
            body: JSON.stringify(data)
        });
    }
    
    put(endpoint, data) {
        return this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(data)
        });
    }
    
    delete(endpoint) {
        return this.request(endpoint, { method: 'DELETE' });
    }
}

export default new ApiService();
```

### Docker Compose Setup
```yaml
version: '3.8'

services:
  mongodb:
    image: mongo:6
    container_name: mern_mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: mernapp
    volumes:
      - mongodb_data:/data/db
    networks:
      - mern_network

  backend:
    build: ./server
    container_name: mern_backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      MONGODB_URI: mongodb://admin:${MONGO_PASSWORD}@mongodb:27017/mernapp?authSource=admin
      JWT_SECRET: ${JWT_SECRET}
      CLIENT_URL: http://localhost:3000
    ports:
      - "5000:5000"
    depends_on:
      - mongodb
    networks:
      - mern_network

  frontend:
    build: ./client
    container_name: mern_frontend
    restart: unless-stopped
    environment:
      REACT_APP_API_URL: http://localhost:5000/api
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - mern_network

volumes:
  mongodb_data:

networks:
  mern_network:
    driver: bridge
```

---

## MEAN Stack
**MongoDB + Express.js + Angular + Node.js**

### Project Structure
```
mean-app/
├── client/                 # Angular frontend
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/
│   │   │   ├── services/
│   │   │   ├── guards/
│   │   │   ├── interceptors/
│   │   │   ├── models/
│   │   │   └── modules/
│   │   └── environments/
│   └── angular.json
├── server/                 # Express backend
│   ├── src/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── middleware/
│   │   └── config/
│   └── server.ts
└── package.json
```

### Angular Service Setup
```typescript
// client/src/app/services/api.service.ts
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';

@Injectable({
    providedIn: 'root'
})
export class ApiService {
    private baseUrl = environment.apiUrl;
    
    constructor(private http: HttpClient) {}
    
    private getHeaders(): HttpHeaders {
        const token = localStorage.getItem('token');
        let headers = new HttpHeaders({
            'Content-Type': 'application/json'
        });
        
        if (token) {
            headers = headers.set('Authorization', `Bearer ${token}`);
        }
        
        return headers;
    }
    
    get<T>(endpoint: string): Observable<T> {
        return this.http.get<T>(`${this.baseUrl}${endpoint}`, {
            headers: this.getHeaders()
        });
    }
    
    post<T>(endpoint: string, data: any): Observable<T> {
        return this.http.post<T>(`${this.baseUrl}${endpoint}`, data, {
            headers: this.getHeaders()
        });
    }
    
    put<T>(endpoint: string, data: any): Observable<T> {
        return this.http.put<T>(`${this.baseUrl}${endpoint}`, data, {
            headers: this.getHeaders()
        });
    }
    
    delete<T>(endpoint: string): Observable<T> {
        return this.http.delete<T>(`${this.baseUrl}${endpoint}`, {
            headers: this.getHeaders()
        });
    }
}
```

### Angular Auth Guard
```typescript
// client/src/app/guards/auth.guard.ts
import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

@Injectable({
    providedIn: 'root'
})
export class AuthGuard implements CanActivate {
    constructor(
        private authService: AuthService,
        private router: Router
    ) {}
    
    canActivate(): boolean {
        if (this.authService.isAuthenticated()) {
            return true;
        }
        
        this.router.navigate(['/login']);
        return false;
    }
}
```

---

## JAMstack
**JavaScript + APIs + Markup**

### Architecture
```
┌─────────────────────────┐
│     Static Site Gen     │
│  (Gatsby/Next/Nuxt)     │
└────────────┬────────────┘
             │ Build Time
┌────────────▼────────────┐
│    Static HTML/CSS/JS   │
│        (CDN)            │
└────────────┬────────────┘
             │ Runtime
┌────────────▼────────────┐
│     APIs/Services       │
│  (Headless CMS, Auth,   │
│   Functions, Database)  │
└─────────────────────────┘
```

### Next.js JAMstack Setup
```javascript
// pages/index.js
export async function getStaticProps() {
    // Fetch data at build time
    const res = await fetch('https://api.example.com/posts');
    const posts = await res.json();
    
    return {
        props: {
            posts
        },
        revalidate: 60 // ISR: Regenerate page every 60 seconds
    };
}

export default function Home({ posts }) {
    return (
        <div>
            {posts.map(post => (
                <article key={post.id}>
                    <h2>{post.title}</h2>
                    <p>{post.excerpt}</p>
                </article>
            ))}
        </div>
    );
}
```

### Gatsby JAMstack Setup
```javascript
// gatsby-config.js
module.exports = {
    plugins: [
        {
            resolve: 'gatsby-source-contentful',
            options: {
                spaceId: process.env.CONTENTFUL_SPACE_ID,
                accessToken: process.env.CONTENTFUL_ACCESS_TOKEN
            }
        },
        'gatsby-plugin-image',
        'gatsby-plugin-sharp',
        'gatsby-transformer-sharp',
        {
            resolve: 'gatsby-plugin-manifest',
            options: {
                name: 'JAMstack Site',
                short_name: 'JAMstack',
                start_url: '/',
                background_color: '#ffffff',
                theme_color: '#000000',
                display: 'minimal-ui',
                icon: 'src/images/icon.png'
            }
        }
    ]
};

// src/pages/index.js
import { graphql } from 'gatsby';

export const query = graphql`
    query {
        allContentfulPost {
            nodes {
                id
                title
                slug
                excerpt
                publishedDate
            }
        }
    }
`;

export default function Home({ data }) {
    const posts = data.allContentfulPost.nodes;
    
    return (
        <div>
            {posts.map(post => (
                <article key={post.id}>
                    <h2>{post.title}</h2>
                    <p>{post.excerpt}</p>
                </article>
            ))}
        </div>
    );
}
```

### Serverless Functions
```javascript
// api/newsletter.js (Vercel)
export default async function handler(req, res) {
    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }
    
    const { email } = req.body;
    
    try {
        // Add to mailing list
        await fetch('https://api.mailchimp.com/3.0/lists/LIST_ID/members', {
            method: 'POST',
            headers: {
                'Authorization': `apikey ${process.env.MAILCHIMP_API_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email_address: email,
                status: 'subscribed'
            })
        });
        
        res.status(200).json({ message: 'Subscribed successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to subscribe' });
    }
}
```

---

## PERN Stack
**PostgreSQL + Express.js + React + Node.js**

### Database Setup with Prisma
```prisma
// prisma/schema.prisma
datasource db {
    provider = "postgresql"
    url      = env("DATABASE_URL")
}

generator client {
    provider = "prisma-client-js"
}

model User {
    id        String   @id @default(cuid())
    email     String   @unique
    password  String
    name      String?
    posts     Post[]
    createdAt DateTime @default(now())
    updatedAt DateTime @updatedAt
}

model Post {
    id        String   @id @default(cuid())
    title     String
    content   String
    published Boolean  @default(false)
    author    User     @relation(fields: [authorId], references: [id])
    authorId  String
    createdAt DateTime @default(now())
    updatedAt DateTime @updatedAt
    
    @@index([authorId])
}
```

### Express with Prisma
```javascript
// server/app.js
const express = require('express');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = new PrismaClient();
const app = express();

app.use(express.json());

// User registration
app.post('/api/register', async (req, res) => {
    const { email, password, name } = req.body;
    
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        
        const user = await prisma.user.create({
            data: {
                email,
                password: hashedPassword,
                name
            }
        });
        
        const token = jwt.sign(
            { userId: user.id },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        res.json({ token, user: { id: user.id, email: user.email, name: user.name } });
    } catch (error) {
        res.status(400).json({ error: 'Email already exists' });
    }
});

// Get posts with pagination
app.get('/api/posts', async (req, res) => {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;
    
    const [posts, total] = await Promise.all([
        prisma.post.findMany({
            where: { published: true },
            include: {
                author: {
                    select: { name: true, email: true }
                }
            },
            skip,
            take: parseInt(limit),
            orderBy: { createdAt: 'desc' }
        }),
        prisma.post.count({ where: { published: true } })
    ]);
    
    res.json({
        posts,
        pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / limit)
        }
    });
});

// Graceful shutdown
process.on('SIGINT', async () => {
    await prisma.$disconnect();
    process.exit(0);
});
```

---

## T3 Stack
**TypeScript + Next.js + tRPC + Prisma + Tailwind CSS + NextAuth.js**

### Project Setup
```bash
npm create t3-app@latest my-t3-app
cd my-t3-app
```

### tRPC Router Setup
```typescript
// src/server/api/routers/post.ts
import { z } from "zod";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "../trpc";

export const postRouter = createTRPCRouter({
    getAll: publicProcedure
        .input(z.object({
            limit: z.number().min(1).max(100).default(10),
            cursor: z.string().nullish()
        }))
        .query(async ({ ctx, input }) => {
            const { limit, cursor } = input;
            
            const posts = await ctx.prisma.post.findMany({
                take: limit + 1,
                where: { published: true },
                cursor: cursor ? { id: cursor } : undefined,
                orderBy: { createdAt: 'desc' },
                include: {
                    author: {
                        select: { name: true, image: true }
                    }
                }
            });
            
            let nextCursor: typeof cursor = undefined;
            if (posts.length > limit) {
                const nextItem = posts.pop();
                nextCursor = nextItem!.id;
            }
            
            return {
                posts,
                nextCursor
            };
        }),
    
    create: protectedProcedure
        .input(z.object({
            title: z.string().min(1).max(280),
            content: z.string().min(1)
        }))
        .mutation(async ({ ctx, input }) => {
            return ctx.prisma.post.create({
                data: {
                    ...input,
                    authorId: ctx.session.user.id
                }
            });
        })
});
```

### Frontend with tRPC
```typescript
// src/pages/posts.tsx
import { api } from "~/utils/api";
import { useSession } from "next-auth/react";

export default function Posts() {
    const { data: session } = useSession();
    
    const { data, fetchNextPage, hasNextPage } = api.post.getAll.useInfiniteQuery(
        { limit: 10 },
        { getNextPageParam: (lastPage) => lastPage.nextCursor }
    );
    
    const createPost = api.post.create.useMutation({
        onSuccess: () => {
            void ctx.post.getAll.invalidate();
        }
    });
    
    const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        const formData = new FormData(e.currentTarget);
        
        createPost.mutate({
            title: formData.get('title') as string,
            content: formData.get('content') as string
        });
    };
    
    return (
        <div className="container mx-auto p-4">
            {session && (
                <form onSubmit={handleSubmit} className="mb-8">
                    <input
                        name="title"
                        placeholder="Title"
                        className="w-full p-2 border rounded mb-2"
                        required
                    />
                    <textarea
                        name="content"
                        placeholder="Content"
                        className="w-full p-2 border rounded mb-2"
                        rows={4}
                        required
                    />
                    <button
                        type="submit"
                        className="bg-blue-500 text-white px-4 py-2 rounded"
                        disabled={createPost.isLoading}
                    >
                        {createPost.isLoading ? 'Creating...' : 'Create Post'}
                    </button>
                </form>
            )}
            
            <div className="space-y-4">
                {data?.pages.map((page) =>
                    page.posts.map((post) => (
                        <article key={post.id} className="border p-4 rounded">
                            <h2 className="text-xl font-bold">{post.title}</h2>
                            <p className="text-gray-600">{post.content}</p>
                            <div className="mt-2 text-sm text-gray-500">
                                By {post.author.name}
                            </div>
                        </article>
                    ))
                )}
            </div>
            
            {hasNextPage && (
                <button
                    onClick={() => fetchNextPage()}
                    className="mt-4 bg-gray-200 px-4 py-2 rounded"
                >
                    Load More
                </button>
            )}
        </div>
    );
}
```

---

## TALL Stack
**Tailwind CSS + Alpine.js + Laravel + Livewire**

### Laravel Livewire Component
```php
// app/Http/Livewire/PostList.php
<?php

namespace App\Http\Livewire;

use App\Models\Post;
use Livewire\Component;
use Livewire\WithPagination;

class PostList extends Component
{
    use WithPagination;
    
    public $search = '';
    public $sortBy = 'created_at';
    public $sortDirection = 'desc';
    
    protected $queryString = ['search', 'sortBy', 'sortDirection'];
    
    public function updatingSearch()
    {
        $this->resetPage();
    }
    
    public function sortBy($field)
    {
        if ($this->sortBy === $field) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            $this->sortBy = $field;
            $this->sortDirection = 'asc';
        }
    }
    
    public function render()
    {
        $posts = Post::query()
            ->when($this->search, function ($query) {
                $query->where('title', 'like', '%' . $this->search . '%')
                      ->orWhere('content', 'like', '%' . $this->search . '%');
            })
            ->orderBy($this->sortBy, $this->sortDirection)
            ->paginate(10);
        
        return view('livewire.post-list', [
            'posts' => $posts
        ]);
    }
}
```

### Blade Template with Alpine.js
```blade
{{-- resources/views/livewire/post-list.blade.php --}}
<div>
    <div class="mb-4 flex gap-4">
        <input
            type="text"
            wire:model.debounce.300ms="search"
            placeholder="Search posts..."
            class="flex-1 px-4 py-2 border rounded-lg"
        >
    </div>
    
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
            <thead>
                <tr>
                    <th>
                        <button
                            wire:click="sortBy('title')"
                            class="flex items-center gap-1"
                        >
                            Title
                            @if($sortBy === 'title')
                                <svg class="w-4 h-4" fill="currentColor">
                                    @if($sortDirection === 'asc')
                                        <path d="M7 10l5-5 5 5H7z"/>
                                    @else
                                        <path d="M7 10l5 5 5-5H7z"/>
                                    @endif
                                </svg>
                            @endif
                        </button>
                    </th>
                    <th>Author</th>
                    <th>Published</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
                @foreach($posts as $post)
                    <tr x-data="{ showDetails: false }">
                        <td class="px-6 py-4">
                            <button
                                @click="showDetails = !showDetails"
                                class="text-blue-600 hover:underline"
                            >
                                {{ $post->title }}
                            </button>
                            <div
                                x-show="showDetails"
                                x-transition
                                class="mt-2 text-sm text-gray-600"
                            >
                                {{ Str::limit($post->content, 200) }}
                            </div>
                        </td>
                        <td class="px-6 py-4">{{ $post->author->name }}</td>
                        <td class="px-6 py-4">{{ $post->published_at->format('M d, Y') }}</td>
                        <td class="px-6 py-4">
                            <button
                                wire:click="edit({{ $post->id }})"
                                class="text-blue-600 hover:underline"
                            >
                                Edit
                            </button>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    
    <div class="mt-4">
        {{ $posts->links() }}
    </div>
</div>
```

---

## Best Practices Across All Stacks

### 1. Security
- Always use HTTPS in production
- Implement proper authentication and authorization
- Sanitize and validate all inputs
- Use environment variables for sensitive data
- Keep dependencies updated
- Implement rate limiting
- Use prepared statements/parameterized queries

### 2. Performance
- Implement caching strategies (Redis, Memcached)
- Optimize database queries and indexes
- Use CDN for static assets
- Implement lazy loading
- Minimize bundle sizes
- Use compression (gzip, brotli)
- Implement proper pagination

### 3. Development Workflow
- Use version control (Git)
- Implement CI/CD pipelines
- Write automated tests
- Use linting and formatting tools
- Document APIs
- Implement logging and monitoring
- Use containerization (Docker)

### 4. Scalability
- Design stateless applications
- Implement horizontal scaling
- Use load balancers
- Implement database replication
- Use message queues for async tasks
- Implement microservices when appropriate
- Use auto-scaling in cloud environments

### 5. Monitoring and Logging
```javascript
// Example logging setup
const winston = require('winston');

const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
        ...(process.env.NODE_ENV !== 'production' ? [
            new winston.transports.Console({
                format: winston.format.simple()
            })
        ] : [])
    ]
});

// APM integration
const apm = require('elastic-apm-node').start({
    serviceName: 'my-app',
    secretToken: process.env.APM_TOKEN,
    serverUrl: process.env.APM_SERVER_URL
});
```

## Choosing the Right Stack

### Decision Factors
1. **Team Expertise**: Choose stacks your team knows well
2. **Project Requirements**: Match stack capabilities to needs
3. **Performance Needs**: Consider language/framework performance
4. **Ecosystem**: Evaluate available libraries and tools
5. **Community Support**: Active community means better support
6. **Scalability**: Consider future growth needs
7. **Time to Market**: Some stacks enable faster development
8. **Budget**: Consider licensing and hosting costs

### Stack Comparison Matrix
| Stack | Best For | Pros | Cons |
|-------|----------|------|------|
| LAMP | Traditional web apps | Mature, well-documented | Monolithic, less scalable |
| MERN | SPAs, Real-time apps | Full JavaScript, Large ecosystem | SEO challenges |
| MEAN | Enterprise apps | TypeScript support, Structured | Steeper learning curve |
| JAMstack | Static sites, Blogs | Fast, Secure, Scalable | Limited dynamic features |
| PERN | Data-heavy apps | SQL power, Type safety | More complex setup |
| T3 | Modern full-stack | Type-safe, Modern DX | Newer, smaller community |
| TALL | Rapid development | Productive, Laravel ecosystem | PHP limitations |