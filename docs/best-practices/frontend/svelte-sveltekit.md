# Svelte 5 & SvelteKit Best Practices

## Overview
Svelte is a compile-time framework that builds efficient vanilla JavaScript. Svelte 5 introduces Runes for fine-grained reactivity. SvelteKit is the full-stack framework for building Svelte applications.

## Documentation
- [Svelte 5 Documentation](https://svelte.dev/docs)
- [Svelte 5 Runes](https://svelte.dev/docs/svelte/runes)
- [SvelteKit Documentation](https://kit.svelte.dev)
- [Svelte Tutorial](https://learn.svelte.dev)

## Svelte 5 with Runes

### Runes Overview
Runes are Svelte 5's new reactivity primitives that provide explicit, fine-grained reactivity.

```javascript
// Core Runes
$state    // Reactive state
$derived  // Computed values
$effect   // Side effects
$props    // Component props
$bindable // Two-way bindable props
$inspect  // Debugging
```

### State Management with Runes

```svelte
<!-- Counter.svelte -->
<script>
  // Reactive state with $state
  let count = $state(0);
  let name = $state('World');
  
  // Objects and arrays are deeply reactive
  let user = $state({
    name: 'John',
    age: 30,
    address: {
      city: 'New York',
      country: 'USA'
    }
  });
  
  let todos = $state([
    { id: 1, text: 'Learn Svelte 5', done: false },
    { id: 2, text: 'Build an app', done: false }
  ]);
  
  // Derived state with $derived
  let doubled = $derived(count * 2);
  let greeting = $derived(`Hello, ${name}!`);
  let completedTodos = $derived(todos.filter(t => t.done));
  let todoStats = $derived({
    total: todos.length,
    completed: completedTodos.length,
    remaining: todos.length - completedTodos.length
  });
  
  // Class fields with runes
  class Counter {
    value = $state(0);
    doubled = $derived(this.value * 2);
    
    increment() {
      this.value++;
    }
    
    reset() {
      this.value = 0;
    }
  }
  
  let counter = new Counter();
  
  // Functions
  function increment() {
    count++;
  }
  
  function addTodo(text) {
    todos.push({
      id: Date.now(),
      text,
      done: false
    });
  }
  
  function toggleTodo(id) {
    const todo = todos.find(t => t.id === id);
    if (todo) todo.done = !todo.done;
  }
</script>

<div>
  <h1>{greeting}</h1>
  <p>Count: {count}</p>
  <p>Doubled: {doubled}</p>
  <button onclick={increment}>Increment</button>
  
  <div>
    <h2>User Info</h2>
    <input bind:value={user.name} />
    <input type="number" bind:value={user.age} />
    <p>City: {user.address.city}</p>
  </div>
  
  <div>
    <h2>Todos ({todoStats.remaining} remaining)</h2>
    {#each todos as todo}
      <label>
        <input 
          type="checkbox" 
          checked={todo.done}
          onchange={() => toggleTodo(todo.id)}
        />
        <span class:done={todo.done}>{todo.text}</span>
      </label>
    {/each}
  </div>
  
  <div>
    <h2>Class-based Counter</h2>
    <p>Value: {counter.value}</p>
    <p>Doubled: {counter.doubled}</p>
    <button onclick={() => counter.increment()}>Increment</button>
    <button onclick={() => counter.reset()}>Reset</button>
  </div>
</div>

<style>
  .done {
    text-decoration: line-through;
    opacity: 0.5;
  }
</style>
```

### Effects and Lifecycle

```svelte
<script>
  import { untrack } from 'svelte';
  
  let searchTerm = $state('');
  let results = $state([]);
  let isLoading = $state(false);
  let logs = $state([]);
  
  // Basic effect - runs when dependencies change
  $effect(() => {
    console.log('Search term changed:', searchTerm);
  });
  
  // Effect with cleanup
  $effect(() => {
    const timer = setTimeout(() => {
      console.log('Debounced search:', searchTerm);
    }, 500);
    
    // Cleanup function
    return () => clearTimeout(timer);
  });
  
  // Async effect with AbortController
  $effect(() => {
    const controller = new AbortController();
    
    async function search() {
      if (!searchTerm) {
        results = [];
        return;
      }
      
      isLoading = true;
      
      try {
        const response = await fetch(
          `/api/search?q=${encodeURIComponent(searchTerm)}`,
          { signal: controller.signal }
        );
        
        if (response.ok) {
          results = await response.json();
        }
      } catch (error) {
        if (error.name !== 'AbortError') {
          console.error('Search failed:', error);
        }
      } finally {
        isLoading = false;
      }
    }
    
    search();
    
    return () => controller.abort();
  });
  
  // Pre-effect for synchronous DOM updates
  $effect.pre(() => {
    // Runs before DOM updates
    document.title = `Search: ${searchTerm || 'Home'}`;
  });
  
  // Untracking dependencies
  $effect(() => {
    // This effect only runs when searchTerm changes
    logs.push({
      term: searchTerm,
      // untrack prevents results.length from being a dependency
      resultCount: untrack(() => results.length),
      timestamp: new Date()
    });
  });
  
  // Root effect for managing subscriptions
  $effect.root(() => {
    // Create effects that outlive the component
    const unsubscribe = someStore.subscribe((value) => {
      console.log('Store value:', value);
    });
    
    return () => {
      unsubscribe();
    };
  });
</script>

<div>
  <input 
    bind:value={searchTerm} 
    placeholder="Search..."
  />
  
  {#if isLoading}
    <p>Loading...</p>
  {:else if results.length > 0}
    <ul>
      {#each results as result}
        <li>{result.title}</li>
      {/each}
    </ul>
  {:else if searchTerm}
    <p>No results found</p>
  {/if}
  
  <div>
    <h3>Search History</h3>
    {#each logs as log}
      <p>{log.term} - {log.resultCount} results</p>
    {/each}
  </div>
</div>
```

### Component Props with Runes

```svelte
<!-- Button.svelte -->
<script>
  // Define props with $props rune
  let { 
    variant = 'primary',
    size = 'medium',
    disabled = false,
    onclick,
    children,
    ...restProps
  } = $props();
  
  // Derived classes based on props
  let classes = $derived(
    `btn btn-${variant} btn-${size} ${disabled ? 'btn-disabled' : ''}`
  );
</script>

<button 
  class={classes}
  {disabled}
  {onclick}
  {...restProps}
>
  {@render children?.()}
</button>

<!-- Parent component -->
<script>
  import Button from './Button.svelte';
  
  let count = $state(0);
</script>

<Button 
  variant="success" 
  size="large"
  onclick={() => count++}
>
  {#snippet children()}
    Click me! ({count})
  {/snippet}
</Button>
```

### Bindable Props

```svelte
<!-- Input.svelte -->
<script>
  let { 
    value = $bindable(''),
    type = 'text',
    placeholder = '',
    label,
    error = '',
    required = false,
    onchange
  } = $props();
  
  let touched = $state(false);
  let showError = $derived(touched && error);
  
  function handleBlur() {
    touched = true;
  }
  
  function handleInput(e) {
    value = e.target.value;
    onchange?.(e);
  }
</script>

<div class="form-field">
  {#if label}
    <label>
      {label}
      {#if required}<span class="required">*</span>{/if}
    </label>
  {/if}
  
  <input
    {type}
    {placeholder}
    value={value}
    oninput={handleInput}
    onblur={handleBlur}
    class:error={showError}
    aria-invalid={showError}
    aria-describedby={showError ? 'error-message' : undefined}
  />
  
  {#if showError}
    <span id="error-message" class="error-message">{error}</span>
  {/if}
</div>

<!-- Usage -->
<script>
  let email = $state('');
  let password = $state('');
  
  let emailError = $derived(
    !email.includes('@') ? 'Invalid email' : ''
  );
  
  let passwordError = $derived(
    password.length < 8 ? 'Password must be at least 8 characters' : ''
  );
</script>

<form>
  <Input
    bind:value={email}
    type="email"
    label="Email"
    placeholder="user@example.com"
    error={emailError}
    required
  />
  
  <Input
    bind:value={password}
    type="password"
    label="Password"
    error={passwordError}
    required
  />
</form>
```

### Advanced State Patterns

```svelte
<!-- stores/todo.svelte.js -->
<script context="module">
  let todos = $state([]);
  let filter = $state('all');
  
  // Derived state
  let filteredTodos = $derived(() => {
    switch (filter) {
      case 'active':
        return todos.filter(t => !t.completed);
      case 'completed':
        return todos.filter(t => t.completed);
      default:
        return todos;
    }
  });
  
  let stats = $derived({
    total: todos.length,
    active: todos.filter(t => !t.completed).length,
    completed: todos.filter(t => t.completed).length
  });
  
  // Store-like API
  export function useTodos() {
    return {
      get todos() { return todos; },
      get filteredTodos() { return filteredTodos; },
      get stats() { return stats; },
      get filter() { return filter; },
      
      addTodo(text) {
        todos.push({
          id: crypto.randomUUID(),
          text,
          completed: false,
          createdAt: new Date()
        });
      },
      
      toggleTodo(id) {
        const todo = todos.find(t => t.id === id);
        if (todo) todo.completed = !todo.completed;
      },
      
      deleteTodo(id) {
        todos = todos.filter(t => t.id !== id);
      },
      
      setFilter(newFilter) {
        filter = newFilter;
      },
      
      clearCompleted() {
        todos = todos.filter(t => !t.completed);
      }
    };
  }
</script>

<!-- TodoApp.svelte -->
<script>
  import { useTodos } from './stores/todo.svelte.js';
  
  const todoStore = useTodos();
  let newTodo = $state('');
  
  function handleSubmit(e) {
    e.preventDefault();
    if (newTodo.trim()) {
      todoStore.addTodo(newTodo.trim());
      newTodo = '';
    }
  }
</script>

<div>
  <h1>Todos ({todoStore.stats.active} active)</h1>
  
  <form onsubmit={handleSubmit}>
    <input bind:value={newTodo} placeholder="What needs to be done?" />
  </form>
  
  <div class="filters">
    {#each ['all', 'active', 'completed'] as filterOption}
      <button
        class:active={todoStore.filter === filterOption}
        onclick={() => todoStore.setFilter(filterOption)}
      >
        {filterOption}
      </button>
    {/each}
  </div>
  
  <ul>
    {#each todoStore.filteredTodos as todo (todo.id)}
      <li>
        <input
          type="checkbox"
          checked={todo.completed}
          onchange={() => todoStore.toggleTodo(todo.id)}
        />
        <span class:completed={todo.completed}>{todo.text}</span>
        <button onclick={() => todoStore.deleteTodo(todo.id)}>×</button>
      </li>
    {/each}
  </ul>
  
  {#if todoStore.stats.completed > 0}
    <button onclick={() => todoStore.clearCompleted()}>
      Clear completed
    </button>
  {/if}
</div>
```

## SvelteKit

### Project Structure

```
my-app/
├── src/
│   ├── routes/
│   │   ├── +layout.svelte
│   │   ├── +layout.server.ts
│   │   ├── +page.svelte
│   │   ├── +page.server.ts
│   │   ├── +error.svelte
│   │   ├── api/
│   │   │   └── posts/
│   │   │       └── +server.ts
│   │   └── blog/
│   │       ├── +page.svelte
│   │       ├── +page.ts
│   │       └── [slug]/
│   │           ├── +page.svelte
│   │           └── +page.server.ts
│   ├── lib/
│   │   ├── components/
│   │   ├── stores/
│   │   ├── utils/
│   │   └── server/
│   │       └── database.ts
│   ├── params/
│   ├── hooks.client.ts
│   ├── hooks.server.ts
│   └── app.html
├── static/
├── tests/
├── package.json
├── svelte.config.js
├── vite.config.js
└── tsconfig.json
```

### Routing and Pages

```typescript
// src/routes/+page.server.ts
import type { PageServerLoad, Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { db } from '$lib/server/database';

export const load: PageServerLoad = async ({ cookies, url }) => {
  const session = cookies.get('session');
  
  if (!session) {
    redirect(303, '/login');
  }
  
  const page = Number(url.searchParams.get('page') ?? '1');
  const limit = 10;
  
  const posts = await db.post.findMany({
    skip: (page - 1) * limit,
    take: limit,
    orderBy: { createdAt: 'desc' },
    include: {
      author: true,
      _count: {
        select: { comments: true }
      }
    }
  });
  
  const totalPosts = await db.post.count();
  
  return {
    posts,
    pagination: {
      page,
      limit,
      total: totalPosts,
      pages: Math.ceil(totalPosts / limit)
    }
  };
};

export const actions: Actions = {
  create: async ({ request, cookies }) => {
    const session = cookies.get('session');
    if (!session) {
      return fail(401, { message: 'Unauthorized' });
    }
    
    const data = await request.formData();
    const title = data.get('title')?.toString();
    const content = data.get('content')?.toString();
    
    if (!title || !content) {
      return fail(400, {
        message: 'Title and content are required',
        values: { title, content }
      });
    }
    
    try {
      const post = await db.post.create({
        data: {
          title,
          content,
          authorId: session.userId
        }
      });
      
      redirect(303, `/blog/${post.slug}`);
    } catch (error) {
      return fail(500, {
        message: 'Failed to create post',
        values: { title, content }
      });
    }
  },
  
  delete: async ({ request, cookies }) => {
    const session = cookies.get('session');
    if (!session) {
      return fail(401, { message: 'Unauthorized' });
    }
    
    const data = await request.formData();
    const id = data.get('id')?.toString();
    
    if (!id) {
      return fail(400, { message: 'Post ID is required' });
    }
    
    try {
      await db.post.delete({
        where: { id, authorId: session.userId }
      });
      
      return { success: true };
    } catch (error) {
      return fail(500, { message: 'Failed to delete post' });
    }
  }
};
```

```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  import type { PageData, ActionData } from './$types';
  import { enhance } from '$app/forms';
  import { invalidateAll } from '$app/navigation';
  
  export let data: PageData;
  export let form: ActionData;
  
  let isCreating = $state(false);
  let title = $state('');
  let content = $state('');
  
  // Restore form values on error
  $effect(() => {
    if (form?.values) {
      title = form.values.title || '';
      content = form.values.content || '';
    }
  });
</script>

<h1>Blog Posts</h1>

{#if form?.message}
  <div class="alert {form.success ? 'success' : 'error'}">
    {form.message}
  </div>
{/if}

<button onclick={() => isCreating = !isCreating}>
  {isCreating ? 'Cancel' : 'New Post'}
</button>

{#if isCreating}
  <form method="POST" action="?/create" use:enhance>
    <input
      name="title"
      bind:value={title}
      placeholder="Post title"
      required
    />
    
    <textarea
      name="content"
      bind:value={content}
      placeholder="Post content"
      required
    />
    
    <button type="submit">Create Post</button>
  </form>
{/if}

<div class="posts">
  {#each data.posts as post (post.id)}
    <article>
      <h2><a href="/blog/{post.slug}">{post.title}</a></h2>
      <p>By {post.author.name} • {post._count.comments} comments</p>
      <p>{post.excerpt}</p>
      
      <form method="POST" action="?/delete" use:enhance={() => {
        return async ({ result }) => {
          if (result.type === 'success') {
            await invalidateAll();
          }
        };
      }}>
        <input type="hidden" name="id" value={post.id} />
        <button type="submit">Delete</button>
      </form>
    </article>
  {/each}
</div>

<!-- Pagination -->
<div class="pagination">
  {#if data.pagination.page > 1}
    <a href="?page={data.pagination.page - 1}">Previous</a>
  {/if}
  
  <span>
    Page {data.pagination.page} of {data.pagination.pages}
  </span>
  
  {#if data.pagination.page < data.pagination.pages}
    <a href="?page={data.pagination.page + 1}">Next</a>
  {/if}
</div>
```

### API Routes

```typescript
// src/routes/api/posts/+server.ts
import type { RequestHandler } from './$types';
import { json, error } from '@sveltejs/kit';
import { db } from '$lib/server/database';
import { z } from 'zod';

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  tags: z.array(z.string()).optional()
});

export const GET: RequestHandler = async ({ url, locals }) => {
  const page = Number(url.searchParams.get('page') ?? '1');
  const limit = Number(url.searchParams.get('limit') ?? '10');
  const search = url.searchParams.get('search');
  
  const where = search
    ? {
        OR: [
          { title: { contains: search } },
          { content: { contains: search } }
        ]
      }
    : {};
  
  const posts = await db.post.findMany({
    where,
    skip: (page - 1) * limit,
    take: limit,
    orderBy: { createdAt: 'desc' }
  });
  
  return json({
    posts,
    page,
    limit
  });
};

export const POST: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) {
    error(401, 'Unauthorized');
  }
  
  const body = await request.json();
  
  // Validate input
  const result = createPostSchema.safeParse(body);
  if (!result.success) {
    error(400, {
      message: 'Invalid input',
      errors: result.error.flatten()
    });
  }
  
  try {
    const post = await db.post.create({
      data: {
        ...result.data,
        authorId: locals.user.id
      }
    });
    
    return json(post, { status: 201 });
  } catch (err) {
    console.error('Failed to create post:', err);
    error(500, 'Failed to create post');
  }
};

export const PUT: RequestHandler = async ({ request, params, locals }) => {
  if (!locals.user) {
    error(401, 'Unauthorized');
  }
  
  const { id } = params;
  const body = await request.json();
  
  const post = await db.post.findUnique({
    where: { id }
  });
  
  if (!post) {
    error(404, 'Post not found');
  }
  
  if (post.authorId !== locals.user.id) {
    error(403, 'Forbidden');
  }
  
  const updated = await db.post.update({
    where: { id },
    data: body
  });
  
  return json(updated);
};

export const DELETE: RequestHandler = async ({ params, locals }) => {
  if (!locals.user) {
    error(401, 'Unauthorized');
  }
  
  const { id } = params;
  
  const post = await db.post.findUnique({
    where: { id }
  });
  
  if (!post) {
    error(404, 'Post not found');
  }
  
  if (post.authorId !== locals.user.id) {
    error(403, 'Forbidden');
  }
  
  await db.post.delete({
    where: { id }
  });
  
  return new Response(null, { status: 204 });
};
```

### Hooks and Middleware

```typescript
// src/hooks.server.ts
import type { Handle, HandleFetch } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { db } from '$lib/server/database';
import jwt from 'jsonwebtoken';

const auth: Handle = async ({ event, resolve }) => {
  const token = event.cookies.get('session');
  
  if (token) {
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as any;
      const user = await db.user.findUnique({
        where: { id: payload.userId }
      });
      
      if (user) {
        event.locals.user = user;
      }
    } catch (err) {
      // Invalid token
      event.cookies.delete('session', { path: '/' });
    }
  }
  
  return resolve(event);
};

const logger: Handle = async ({ event, resolve }) => {
  const start = Date.now();
  
  const response = await resolve(event);
  
  const duration = Date.now() - start;
  
  console.log(`${event.request.method} ${event.url.pathname} - ${response.status} (${duration}ms)`);
  
  return response;
};

const security: Handle = async ({ event, resolve }) => {
  const response = await resolve(event);
  
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  return response;
};

export const handle = sequence(auth, logger, security);

export const handleFetch: HandleFetch = async ({ request, fetch }) => {
  // Add authorization header for internal API calls
  if (request.url.startsWith(process.env.API_URL!)) {
    request.headers.set('Authorization', `Bearer ${process.env.API_KEY}`);
  }
  
  return fetch(request);
};

// src/hooks.client.ts
import type { HandleClientError } from '@sveltejs/kit';
import * as Sentry from '@sentry/sveltekit';

Sentry.init({
  dsn: process.env.PUBLIC_SENTRY_DSN,
  environment: process.env.PUBLIC_ENV
});

export const handleError: HandleClientError = async ({ error, event }) => {
  const errorId = crypto.randomUUID();
  
  Sentry.captureException(error, {
    extra: {
      event,
      errorId
    }
  });
  
  return {
    message: 'An unexpected error occurred',
    errorId
  };
};
```

### Form Actions with Progressive Enhancement

```svelte
<!-- src/routes/contact/+page.svelte -->
<script lang="ts">
  import { enhance } from '$app/forms';
  import type { ActionData } from './$types';
  
  export let form: ActionData;
  
  let isSubmitting = $state(false);
</script>

<form
  method="POST"
  use:enhance={() => {
    isSubmitting = true;
    
    return async ({ result, update }) => {
      isSubmitting = false;
      
      if (result.type === 'success') {
        // Custom success handling
        alert('Message sent successfully!');
      }
      
      await update();
    };
  }}
>
  {#if form?.error}
    <div class="error">{form.error}</div>
  {/if}
  
  {#if form?.success}
    <div class="success">Thank you for your message!</div>
  {/if}
  
  <label>
    Name
    <input
      name="name"
      value={form?.values?.name ?? ''}
      required
      disabled={isSubmitting}
    />
    {#if form?.errors?.name}
      <span class="field-error">{form.errors.name}</span>
    {/if}
  </label>
  
  <label>
    Email
    <input
      type="email"
      name="email"
      value={form?.values?.email ?? ''}
      required
      disabled={isSubmitting}
    />
    {#if form?.errors?.email}
      <span class="field-error">{form.errors.email}</span>
    {/if}
  </label>
  
  <label>
    Message
    <textarea
      name="message"
      value={form?.values?.message ?? ''}
      required
      disabled={isSubmitting}
    />
    {#if form?.errors?.message}
      <span class="field-error">{form.errors.message}</span>
    {/if}
  </label>
  
  <button type="submit" disabled={isSubmitting}>
    {isSubmitting ? 'Sending...' : 'Send Message'}
  </button>
</form>
```

### Advanced Data Loading

```typescript
// src/routes/shop/+layout.server.ts
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals }) => {
  // Load data that's needed for all shop pages
  const categories = await db.category.findMany({
    orderBy: { name: 'asc' }
  });
  
  const cart = locals.user
    ? await db.cart.findUnique({
        where: { userId: locals.user.id },
        include: { items: true }
      })
    : null;
  
  return {
    categories,
    cart
  };
};

// src/routes/shop/products/[id]/+page.ts
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params, fetch, parent }) => {
  // Access parent layout data
  const { categories } = await parent();
  
  // Fetch product data
  const productRes = await fetch(`/api/products/${params.id}`);
  if (!productRes.ok) {
    error(404, 'Product not found');
  }
  
  const product = await productRes.json();
  
  // Fetch related products
  const relatedRes = await fetch(`/api/products/${params.id}/related`);
  const related = await relatedRes.json();
  
  return {
    product,
    related,
    category: categories.find(c => c.id === product.categoryId)
  };
};

// Streaming with promises
// src/routes/dashboard/+page.server.ts
export const load: PageServerLoad = async ({ locals }) => {
  return {
    // Immediate data
    user: locals.user,
    
    // Streamed data
    streamed: {
      posts: db.post.findMany({ where: { authorId: locals.user.id } }),
      comments: db.comment.findMany({ where: { userId: locals.user.id } }),
      analytics: fetch('/api/analytics').then(r => r.json())
    }
  };
};
```

## Configuration

### svelte.config.js

```javascript
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  
  kit: {
    adapter: adapter(),
    
    alias: {
      $components: 'src/lib/components',
      $utils: 'src/lib/utils',
      $stores: 'src/lib/stores',
      $types: 'src/types'
    },
    
    csp: {
      directives: {
        'script-src': ['self']
      }
    },
    
    env: {
      publicPrefix: 'PUBLIC_',
      privatePrefix: ''
    },
    
    serviceWorker: {
      register: false
    },
    
    version: {
      name: process.env.npm_package_version
    }
  },
  
  compilerOptions: {
    runes: true
  }
};

export default config;
```

### vite.config.js

```javascript
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [sveltekit()],
  
  server: {
    port: 3000,
    strictPort: false
  },
  
  preview: {
    port: 4173,
    strictPort: false
  },
  
  optimizeDeps: {
    include: ['lodash-es', 'dayjs']
  },
  
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['lodash-es', 'dayjs']
        }
      }
    }
  },
  
  test: {
    include: ['src/**/*.{test,spec}.{js,ts}']
  }
});
```

## Testing

```typescript
// src/routes/login/login.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { render, fireEvent, waitFor } from '@testing-library/svelte';
import Login from './+page.svelte';

describe('Login Page', () => {
  it('should render login form', () => {
    const { getByLabelText, getByRole } = render(Login);
    
    expect(getByLabelText(/email/i)).toBeInTheDocument();
    expect(getByLabelText(/password/i)).toBeInTheDocument();
    expect(getByRole('button', { name: /log in/i })).toBeInTheDocument();
  });
  
  it('should show validation errors', async () => {
    const { getByRole, getByText } = render(Login);
    
    const submitButton = getByRole('button', { name: /log in/i });
    await fireEvent.click(submitButton);
    
    await waitFor(() => {
      expect(getByText(/email is required/i)).toBeInTheDocument();
      expect(getByText(/password is required/i)).toBeInTheDocument();
    });
  });
});

// E2E test with Playwright
// tests/auth.test.ts
import { expect, test } from '@playwright/test';

test.describe('Authentication', () => {
  test('user can log in', async ({ page }) => {
    await page.goto('/login');
    
    await page.fill('input[name="email"]', 'user@example.com');
    await page.fill('input[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('h1')).toContainText('Dashboard');
  });
});
```

## Best Practices

1. **Use Runes for reactivity** - Explicit and performant
2. **Leverage server-side rendering** - Better SEO and performance
3. **Progressive enhancement** - Works without JavaScript
4. **Type everything** - Use TypeScript throughout
5. **Optimize bundle size** - Code split and lazy load
6. **Cache aggressively** - Use HTTP caching headers
7. **Handle errors gracefully** - Implement error boundaries
8. **Secure your app** - CSP, CSRF protection, input validation
9. **Test thoroughly** - Unit, integration, and E2E tests
10. **Monitor performance** - Use Web Vitals and analytics