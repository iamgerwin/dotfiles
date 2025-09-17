# Livewire Best Practices

## Overview

Livewire is a full-stack framework for Laravel that makes building dynamic interfaces simple, without leaving the comfort of PHP. It allows you to write your component logic in PHP while automatically handling the JavaScript layer, providing reactive and dynamic interfaces similar to Vue or React but entirely server-driven.

## Pros & Cons

### Pros
- **No JavaScript Required**: Build dynamic UIs entirely in PHP
- **Laravel Integration**: Seamless integration with Laravel's ecosystem
- **Simple Learning Curve**: Familiar PHP syntax and Laravel patterns
- **Automatic DOM Diffing**: Efficient updates without full page refreshes
- **Real-time Validation**: Server-side validation with instant feedback
- **File Uploads**: Built-in support for direct file uploads
- **Testing Support**: Easy to test with Laravel's testing tools
- **SEO Friendly**: Server-rendered content works well with search engines

### Cons
- **Network Latency**: Every interaction requires a server round-trip
- **Limited Offline Support**: Requires constant server connection
- **Performance Overhead**: Not suitable for high-frequency updates
- **Laravel Dependency**: Only works with Laravel applications
- **JavaScript Limitations**: Complex client-side logic can be challenging
- **Bundle Size**: Adds overhead to page load with Livewire JavaScript

## When to Use

Livewire is ideal for:
- Laravel applications requiring dynamic interfaces
- Admin panels and dashboards
- Forms with complex validation logic
- Real-time search and filtering interfaces
- Applications where SEO is important
- Teams with strong PHP skills but limited JavaScript expertise
- Rapid prototyping of interactive features
- CRUD applications with moderate interactivity

## Core Concepts

### Component Structure

```php
// app/Http/Livewire/SearchUsers.php
namespace App\Http\Livewire;

use Livewire\Component;
use App\Models\User;

class SearchUsers extends Component
{
    public $search = '';
    public $users = [];

    protected $queryString = ['search'];

    public function mount()
    {
        $this->users = User::latest()->take(10)->get();
    }

    public function updatedSearch()
    {
        $this->users = User::where('name', 'like', '%'.$this->search.'%')
            ->orWhere('email', 'like', '%'.$this->search.'%')
            ->limit(10)
            ->get();
    }

    public function render()
    {
        return view('livewire.search-users');
    }
}
```

### Blade Template

```blade
{{-- resources/views/livewire/search-users.blade.php --}}
<div>
    <input wire:model="search" type="search" placeholder="Search users...">

    <div class="mt-4">
        @foreach($users as $user)
            <div wire:key="user-{{ $user->id }}" class="p-4 border-b">
                <h3>{{ $user->name }}</h3>
                <p>{{ $user->email }}</p>
            </div>
        @endforeach
    </div>

    @if(count($users) === 0)
        <p>No users found.</p>
    @endif
</div>
```

## Installation & Setup

### Laravel Installation

```bash
# Install Laravel
composer create-project laravel/laravel my-app
cd my-app

# Install Livewire
composer require livewire/livewire

# Publish config (optional)
php artisan vendor:publish --tag=livewire:config

# Publish assets (optional)
php artisan vendor:publish --tag=livewire:assets
```

### Layout Setup

```blade
{{-- resources/views/layouts/app.blade.php --}}
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>My App</title>

    <!-- Styles -->
    @livewireStyles
</head>
<body>
    {{ $slot }}

    <!-- Scripts -->
    @livewireScripts
</body>
</html>
```

## Project Structure

```
app/
├── Http/
│   └── Livewire/
│       ├── Admin/
│       │   ├── Dashboard.php
│       │   └── UserManager.php
│       ├── Forms/
│       │   ├── ContactForm.php
│       │   └── UserProfileForm.php
│       └── Tables/
│           ├── UsersTable.php
│           └── OrdersTable.php
├── View/
│   └── Components/
│       └── Layouts/
│           └── App.php
resources/
├── views/
│   ├── livewire/
│   │   ├── admin/
│   │   │   ├── dashboard.blade.php
│   │   │   └── user-manager.blade.php
│   │   ├── forms/
│   │   │   ├── contact-form.blade.php
│   │   │   └── user-profile-form.blade.php
│   │   └── tables/
│   │       ├── users-table.blade.php
│   │       └── orders-table.blade.php
│   └── layouts/
│       └── app.blade.php
```

## Development Patterns

### Data Binding Patterns

```php
// Component class
class FormComponent extends Component
{
    // Simple property binding
    public $name = '';
    public $email = '';

    // Nested data binding
    public $user = [
        'name' => '',
        'email' => '',
        'preferences' => [
            'newsletter' => false,
            'notifications' => true,
        ]
    ];

    // Computed properties
    public function getFullNameProperty()
    {
        return $this->user['first_name'] . ' ' . $this->user['last_name'];
    }

    // Real-time validation
    public function updated($propertyName)
    {
        $this->validateOnly($propertyName, [
            'name' => 'required|min:3',
            'email' => 'required|email',
        ]);
    }
}
```

```blade
{{-- Blade template --}}
<form wire:submit.prevent="save">
    {{-- Simple binding --}}
    <input wire:model="name" type="text">

    {{-- Deferred binding (syncs on action) --}}
    <input wire:model.defer="email" type="email">

    {{-- Lazy binding (syncs on change) --}}
    <input wire:model.lazy="description" type="text">

    {{-- Debounce binding --}}
    <input wire:model.debounce.500ms="search" type="search">

    {{-- Nested binding --}}
    <input wire:model="user.preferences.newsletter" type="checkbox">

    {{-- Computed property --}}
    <span>{{ $this->fullName }}</span>
</form>
```

### Actions and Events

```php
// Component with actions
class TodoList extends Component
{
    public $todos = [];
    public $newTodo = '';

    protected $listeners = [
        'todoDeleted' => 'refreshTodos',
        'echo:todos,.todo-updated' => 'handleTodoUpdate',
    ];

    public function addTodo()
    {
        $this->validate([
            'newTodo' => 'required|min:3',
        ]);

        Todo::create(['title' => $this->newTodo]);

        $this->newTodo = '';
        $this->emit('todoAdded');
        $this->dispatchBrowserEvent('notify', [
            'message' => 'Todo added successfully!'
        ]);
    }

    public function deleteTodo($todoId)
    {
        Todo::find($todoId)->delete();
        $this->emitSelf('todoDeleted');
    }

    public function refreshTodos()
    {
        $this->todos = Todo::latest()->get();
    }
}
```

```blade
{{-- Using actions --}}
<div>
    <form wire:submit.prevent="addTodo">
        <input wire:model="newTodo" type="text">
        <button type="submit">Add Todo</button>
    </form>

    @foreach($todos as $todo)
        <div wire:key="todo-{{ $todo->id }}">
            <span>{{ $todo->title }}</span>
            <button wire:click="deleteTodo({{ $todo->id }})"
                    wire:confirm="Are you sure?">
                Delete
            </button>
        </div>
    @endforeach
</div>

<script>
    window.addEventListener('notify', event => {
        alert(event.detail.message);
    });
</script>
```

### File Uploads

```php
// Component with file upload
use Livewire\WithFileUploads;

class ProfilePhotoUpload extends Component
{
    use WithFileUploads;

    public $photo;
    public $user;

    protected $rules = [
        'photo' => 'required|image|max:1024', // 1MB Max
    ];

    public function mount(User $user)
    {
        $this->user = $user;
    }

    public function save()
    {
        $this->validate();

        $filename = $this->photo->store('photos', 'public');

        $this->user->update([
            'profile_photo_path' => $filename,
        ]);

        session()->flash('message', 'Photo uploaded successfully.');
    }

    public function deletePhoto()
    {
        Storage::disk('public')->delete($this->user->profile_photo_path);
        $this->user->update(['profile_photo_path' => null]);
    }
}
```

```blade
{{-- File upload template --}}
<form wire:submit.prevent="save">
    @if ($photo)
        <img src="{{ $photo->temporaryUrl() }}" alt="Preview">
    @endif

    <input type="file" wire:model="photo">

    @error('photo') <span class="error">{{ $message }}</span> @enderror

    <div wire:loading wire:target="photo">Uploading...</div>

    <button type="submit">Upload Photo</button>
</form>
```

### Pagination

```php
// Component with pagination
use Livewire\WithPagination;

class UsersTable extends Component
{
    use WithPagination;

    public $search = '';
    public $sortField = 'name';
    public $sortDirection = 'asc';

    protected $queryString = [
        'search' => ['except' => ''],
        'sortField' => ['except' => 'name'],
        'sortDirection' => ['except' => 'asc'],
    ];

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function sortBy($field)
    {
        if ($this->sortField === $field) {
            $this->sortDirection = $this->sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            $this->sortField = $field;
            $this->sortDirection = 'asc';
        }
    }

    public function render()
    {
        return view('livewire.users-table', [
            'users' => User::query()
                ->when($this->search, function ($query) {
                    $query->where('name', 'like', '%' . $this->search . '%')
                        ->orWhere('email', 'like', '%' . $this->search . '%');
                })
                ->orderBy($this->sortField, $this->sortDirection)
                ->paginate(10)
        ]);
    }
}
```

## Security Best Practices

### Property Protection

```php
class SecureComponent extends Component
{
    // Public properties are exposed to frontend
    public $visibleData = 'This is visible';

    // Protected/private properties are not exposed
    protected $sensitiveData = 'This is hidden';
    private $secretKey = 'Never exposed';

    // Lock properties from frontend updates
    protected $rules = [
        'visibleData' => 'required|string|max:255',
    ];

    // Authorize actions
    public function deletePost($postId)
    {
        $post = Post::findOrFail($postId);

        $this->authorize('delete', $post);

        $post->delete();
    }

    // Validate before processing
    public function save()
    {
        $validated = $this->validate([
            'title' => 'required|min:3|max:255',
            'content' => 'required|min:10',
        ]);

        Post::create($validated);
    }
}
```

### Preventing Mass Assignment

```php
class UserProfile extends Component
{
    public $user;

    // Use only() to whitelist fields
    public function updateProfile()
    {
        $this->user->update(
            $this->only(['name', 'email', 'bio'])
        );
    }

    // Protect sensitive fields
    protected $guarded = ['role', 'is_admin', 'email_verified_at'];

    // Use fill() with caution
    public function updateUser($userData)
    {
        $this->user->fill(
            Arr::only($userData, ['name', 'bio'])
        )->save();
    }
}
```

### XSS Prevention

```blade
{{-- Always escape output --}}
<div>{{ $userInput }}</div>

{{-- Be careful with unescaped output --}}
{{-- Only use for trusted HTML content --}}
<div>{!! $trustedHtml !!}</div>

{{-- Livewire automatically escapes --}}
<div wire:poll.5s>
    {{ $dynamicContent }}
</div>

{{-- Use @js directive for JavaScript --}}
<script>
    let data = @js($phpArray);
</script>
```

### CSRF Protection

```php
// Livewire automatically handles CSRF
class FormComponent extends Component
{
    public function submitForm()
    {
        // CSRF token is automatically verified
        $this->validate();
        // Process form...
    }
}

// For manual AJAX calls
public function render()
{
    return view('livewire.form', [
        'csrfToken' => csrf_token(),
    ]);
}
```

## Performance Optimization

### Lazy Loading

```php
// Component with lazy loading
class HeavyComponent extends Component
{
    public $data = [];

    public function mount()
    {
        // Don't load data on mount
    }

    public function loadData()
    {
        sleep(2); // Simulate heavy operation
        $this->data = ExpensiveModel::all();
    }

    public function placeholder()
    {
        return <<<'HTML'
            <div class="skeleton-loader">
                Loading...
            </div>
        HTML;
    }
}
```

```blade
{{-- Lazy load component --}}
<livewire:heavy-component lazy />

{{-- Load on scroll --}}
<div x-data="{ shown: false }"
     x-intersect="shown = true">
    <div x-show="shown" x-transition>
        <livewire:heavy-component />
    </div>
</div>
```

### Query Optimization

```php
class OptimizedTable extends Component
{
    use WithPagination;

    // Cache computed properties
    public function getUsersProperty()
    {
        return Cache::remember('users-page-'.$this->page, 60, function () {
            return User::with(['posts', 'comments'])
                ->withCount(['posts', 'comments'])
                ->paginate(20);
        });
    }

    // Use select to limit columns
    public function render()
    {
        $users = User::select(['id', 'name', 'email', 'created_at'])
            ->when($this->search, function ($query) {
                $query->where('name', 'like', '%' . $this->search . '%');
            })
            ->paginate(20);

        return view('livewire.optimized-table', compact('users'));
    }
}
```

### DOM Diffing Optimization

```blade
{{-- Use wire:key for lists --}}
@foreach($items as $item)
    <div wire:key="item-{{ $item->id }}">
        {{ $item->name }}
    </div>
@endforeach

{{-- Ignore elements from diffing --}}
<div wire:ignore>
    <select class="select2">
        <!-- Third-party plugin content -->
    </select>
</div>

{{-- Ignore self only --}}
<div wire:ignore.self>
    <!-- Content that won't be updated but children might -->
</div>
```

## Testing Strategies

### Component Testing

```php
// tests/Feature/Livewire/SearchUsersTest.php
use Livewire\Livewire;
use App\Http\Livewire\SearchUsers;
use App\Models\User;

class SearchUsersTest extends TestCase
{
    /** @test */
    public function can_search_users()
    {
        $user1 = User::factory()->create(['name' => 'John Doe']);
        $user2 = User::factory()->create(['name' => 'Jane Smith']);

        Livewire::test(SearchUsers::class)
            ->set('search', 'John')
            ->assertSee('John Doe')
            ->assertDontSee('Jane Smith');
    }

    /** @test */
    public function validates_search_input()
    {
        Livewire::test(SearchUsers::class)
            ->set('search', 'a')
            ->assertHasErrors(['search' => 'min']);
    }

    /** @test */
    public function can_delete_user()
    {
        $user = User::factory()->create();

        Livewire::actingAs(User::factory()->admin()->create())
            ->test(SearchUsers::class)
            ->call('deleteUser', $user->id)
            ->assertEmitted('userDeleted')
            ->assertDontSee($user->name);

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }
}
```

### Testing File Uploads

```php
/** @test */
public function can_upload_profile_photo()
{
    Storage::fake('public');
    $user = User::factory()->create();

    $file = UploadedFile::fake()->image('photo.jpg', 100, 100);

    Livewire::actingAs($user)
        ->test(ProfilePhotoUpload::class, ['user' => $user])
        ->set('photo', $file)
        ->call('save')
        ->assertHasNoErrors()
        ->assertSessionHas('message', 'Photo uploaded successfully.');

    Storage::disk('public')->assertExists('photos/' . $file->hashName());
    $this->assertNotNull($user->fresh()->profile_photo_path);
}
```

## Deployment Guide

### Production Configuration

```php
// config/livewire.php
return [
    'asset_url' => env('ASSET_URL', null),
    'app_url' => env('APP_URL', 'http://localhost'),
    'middleware_group' => 'web',
    'temporary_file_upload' => [
        'disk' => 's3',
        'rules' => 'required|file|max:12288', // 12MB
        'directory' => 'tmp',
        'middleware' => 'throttle:60,1',
        'preview_mimes' => [
            'png', 'gif', 'bmp', 'svg', 'jpg', 'jpeg', 'mp4',
            'mov', 'avi', 'wmv', 'mp3', 'wav', 'm4a', 'pdf',
        ],
        'max_upload_time' => 5, // Minutes
    ],
    'render_on_redirect' => false,
    'legacy_model_binding' => false,
    'inject_assets' => true,
    'inject_morph_markers' => true,
    'navigate' => [
        'show_progress_bar' => true,
    ],
];
```

### Asset Optimization

```bash
# Publish and compile assets
php artisan vendor:publish --tag=livewire:assets
npm run production

# Cache views and config
php artisan view:cache
php artisan config:cache
php artisan route:cache

# Optimize autoloader
composer install --optimize-autoloader --no-dev
```

### CDN Setup

```blade
{{-- Use CDN for Livewire assets --}}
@livewireStyles
<script src="https://cdn.jsdelivr.net/gh/livewire/livewire@v2.x.x/dist/livewire.js"></script>

{{-- Or use local assets with versioning --}}
<link rel="stylesheet" href="{{ asset('css/app.css') }}?v={{ config('app.version') }}">
<script src="{{ asset('js/app.js') }}?v={{ config('app.version') }}"></script>
```

## Common Pitfalls

### State Management Issues

```php
// Wrong: Modifying arrays/objects directly
public function addItem()
{
    $this->items[] = 'New Item'; // Won't trigger re-render
}

// Correct: Reassign the entire array
public function addItem()
{
    $this->items = array_merge($this->items, ['New Item']);
}

// Or use collection
public function addItem()
{
    $this->items = collect($this->items)->push('New Item')->toArray();
}
```

### Memory Leaks

```php
// Wrong: Storing Eloquent models in properties
public $users; // Can cause serialization issues

public function mount()
{
    $this->users = User::all(); // Bad
}

// Correct: Use computed properties or render method
public function getUsersProperty()
{
    return User::all();
}

// Or pass to view
public function render()
{
    return view('livewire.component', [
        'users' => User::all(),
    ]);
}
```

### JavaScript Integration

```blade
{{-- Wrong: Initializing JS on every render --}}
<div>
    <script>
        initializePlugin(); // Will run on every Livewire update
    </script>
</div>

{{-- Correct: Use wire:ignore and lifecycle hooks --}}
<div wire:ignore>
    <div id="chart"></div>
</div>

<script>
document.addEventListener('livewire:load', () => {
    initializeChart();
});

document.addEventListener('livewire:update', () => {
    updateChart();
});
</script>
```

## Troubleshooting

### Common Issues and Solutions

```php
// 1. Component not found
// Solution: Check namespace and class name
php artisan livewire:make ComponentName

// 2. Hydration failed
// Solution: Ensure data types are serializable
public $user; // Bad: Eloquent model
public $userId; // Good: Primitive type

// 3. File upload not working
// Solution: Check temporary file upload configuration
// Ensure storage permissions are correct
chmod -R 775 storage
chmod -R 775 bootstrap/cache

// 4. Alpine.js conflicts
// Solution: Use wire:ignore or @entangle
<div x-data="{ open: @entangle('isOpen') }">
    <!-- Alpine and Livewire working together -->
</div>

// 5. Performance issues
// Solution: Use pagination, lazy loading, and caching
public function render()
{
    return view('livewire.component', [
        'data' => Cache::remember('key', 3600, fn() => Model::all())
    ]);
}
```

## Best Practices Summary

### Do's
- ✅ Use computed properties for derived data
- ✅ Implement real-time validation for better UX
- ✅ Use wire:key for list items
- ✅ Cache expensive queries
- ✅ Use lazy loading for heavy components
- ✅ Validate all user input
- ✅ Use authorization for actions
- ✅ Test components thoroughly
- ✅ Use wire:loading for loading states
- ✅ Optimize queries with eager loading

### Don'ts
- ❌ Don't store Eloquent models in public properties
- ❌ Don't expose sensitive data in public properties
- ❌ Don't forget CSRF protection for custom forms
- ❌ Don't use Livewire for high-frequency updates
- ❌ Don't ignore performance implications
- ❌ Don't mix too much JavaScript with Livewire
- ❌ Don't forget to use wire:key in loops
- ❌ Don't trust user input without validation
- ❌ Don't use {!! !!} with user input
- ❌ Don't forget to clean up event listeners

## Integration with Alpine.js

```blade
{{-- Seamless Alpine.js integration --}}
<div x-data="{
    open: @entangle('showModal'),
    search: @entangle('searchTerm').defer,
    count: 0
}">
    <button @click="open = true">Open Modal</button>

    <input x-model="search" @keydown.enter="$wire.performSearch()">

    <button @click="count++; $wire.increment()">
        Count: <span x-text="count"></span>
    </button>

    <div x-show="open" x-transition>
        <!-- Modal content -->
    </div>
</div>
```

## Conclusion

Livewire revolutionizes Laravel development by enabling dynamic, reactive interfaces without writing JavaScript. Its seamless integration with Laravel's ecosystem, combined with familiar PHP syntax, makes it an excellent choice for teams looking to build modern web applications efficiently. While it has limitations for high-frequency updates and offline functionality, Livewire excels at creating interactive admin panels, forms, and data-driven interfaces with minimal complexity.

## Resources

- [Official Livewire Documentation](https://laravel-livewire.com/docs)
- [Livewire Screencasts](https://laravel-livewire.com/screencasts)
- [Laravel Documentation](https://laravel.com/docs)
- [Livewire GitHub Repository](https://github.com/livewire/livewire)
- [Caleb Porzio's Twitter](https://twitter.com/calebporzio)
- [Livewire Forum](https://forum.laravel-livewire.com)
- [Alpine.js Documentation](https://alpinejs.dev)
- [Laravel Daily Livewire Tutorials](https://laraveldaily.com/tag/livewire)
- [Livewire Directory](https://livewire-directory.com)
- [Awesome Livewire](https://github.com/imliam/awesome-livewire)