# Laravel Livewire Best Practices

## Overview
Laravel Livewire is a full-stack framework for Laravel that enables building dynamic interfaces without leaving PHP. These best practices ensure optimal performance, maintainability, and user experience.

## Component Architecture

### Component Organization
```php
// app/Livewire/Users/UserTable.php
namespace App\Livewire\Users;

class UserTable extends Component
{
    use WithPagination;
    
    public $perPage = 10;
    public $search = '';
    public $sortField = 'created_at';
    public $sortDirection = 'desc';
    
    protected $queryString = [
        'search' => ['except' => ''],
        'perPage',
    ];
}
```

### Single Responsibility Principle
- Keep components focused on a single feature
- Extract reusable logic into traits
- Use child components for complex UI sections

## Performance Optimization

### Wire:model Modifiers
```php
<!-- Defer updates until action -->
<input wire:model.defer="name" />

<!-- Debounce input for search -->
<input wire:model.debounce.500ms="search" />

<!-- Lazy loading for heavy operations -->
<input wire:model.lazy="description" />
```

### Computed Properties
```php
class ProductList extends Component
{
    public $category;
    
    // Cache computed property for request lifecycle
    public function getProductsProperty()
    {
        return cache()->remember(
            "products.{$this->category}",
            300,
            fn() => Product::where('category', $this->category)->get()
        );
    }
    
    public function render()
    {
        return view('livewire.product-list', [
            'products' => $this->products // Accessed as property
        ]);
    }
}
```

### Pagination Best Practices
```php
use WithPagination;

class UserTable extends Component
{
    use WithPagination;
    
    protected $paginationTheme = 'bootstrap'; // or 'tailwind'
    
    public function updatingSearch()
    {
        $this->resetPage(); // Reset to page 1 when searching
    }
}
```

## State Management

### Property Types and Validation
```php
class UserForm extends Component
{
    public User $user;
    public $photo;
    
    protected $rules = [
        'user.name' => 'required|min:3',
        'user.email' => 'required|email|unique:users,email',
        'photo' => 'nullable|image|max:1024',
    ];
    
    protected $messages = [
        'user.email.unique' => 'This email is already taken.',
    ];
    
    public function updated($propertyName)
    {
        $this->validateOnly($propertyName);
    }
}
```

### Data Binding Patterns
```php
<!-- Two-way binding -->
<input wire:model="user.name" />

<!-- One-way binding -->
<input value="{{ $user->name }}" wire:change="updateName($event.target.value)" />

<!-- Conditional classes -->
<div class="{{ $isActive ? 'active' : 'inactive' }}">
```

## Security Best Practices

### Authorization
```php
class AdminPanel extends Component
{
    public function mount()
    {
        $this->authorize('viewAdminPanel');
    }
    
    public function deleteUser($userId)
    {
        $this->authorize('delete', User::find($userId));
        // Delete logic
    }
}
```

### Protected Properties
```php
class SecureComponent extends Component
{
    public $publicData;
    protected $sensitiveData; // Not accessible from frontend
    private $internalData;
    
    // Lock properties from frontend updates
    protected $guarded = ['id', 'user_id'];
}
```

### SQL Injection Prevention
```php
// Always use Eloquent or query builder
public function search($term)
{
    $this->results = User::where('name', 'like', '%' . $term . '%')
        ->orWhere('email', 'like', '%' . $term . '%')
        ->get();
}
```

## Event Handling

### Browser Events
```php
class NotificationComponent extends Component
{
    protected $listeners = [
        'refreshComponent' => '$refresh',
        'userUpdated' => 'handleUserUpdate',
    ];
    
    public function save()
    {
        // Save logic
        $this->dispatch('notify', [
            'type' => 'success',
            'message' => 'Saved successfully!'
        ]);
    }
    
    public function handleUserUpdate($userId)
    {
        // Handle the event
    }
}
```

### JavaScript Integration
```blade
<div x-data="{ open: @entangle('showModal') }">
    <button @click="$wire.toggleModal()">Toggle</button>
    
    <div x-show="open" x-transition>
        <!-- Modal content -->
    </div>
</div>

<script>
    Livewire.on('notify', (data) => {
        toastr[data.type](data.message);
    });
</script>
```

## File Uploads

### Optimized File Handling
```php
class FileUpload extends Component
{
    use WithFileUploads;
    
    public $photo;
    public $photos = [];
    
    protected $rules = [
        'photo' => 'image|max:1024', // 1MB Max
        'photos.*' => 'image|max:1024',
    ];
    
    public function save()
    {
        $this->validate();
        
        // Single file
        $path = $this->photo->store('photos', 'public');
        
        // Multiple files
        foreach ($this->photos as $photo) {
            $photo->store('photos', 'public');
        }
        
        // Clean up
        $this->reset(['photo', 'photos']);
    }
    
    public function updatedPhoto()
    {
        $this->validate(['photo' => 'image|max:1024']);
    }
}
```

### Progress Indicators
```blade
<div wire:loading wire:target="photo">
    Uploading...
</div>

<div x-data="{ uploading: false, progress: 0 }"
     x-on:livewire-upload-start="uploading = true"
     x-on:livewire-upload-finish="uploading = false"
     x-on:livewire-upload-progress="progress = $event.detail.progress">
    
    <input type="file" wire:model="photo">
    
    <div x-show="uploading">
        <progress max="100" x-bind:value="progress"></progress>
    </div>
</div>
```

## Testing

### Component Testing
```php
use Livewire\Livewire;

class UserComponentTest extends TestCase
{
    /** @test */
    public function can_create_user()
    {
        Livewire::test(UserForm::class)
            ->set('user.name', 'John Doe')
            ->set('user.email', 'john@example.com')
            ->call('save')
            ->assertHasNoErrors()
            ->assertEmitted('userCreated')
            ->assertSee('User created successfully');
    }
    
    /** @test */
    public function validates_required_fields()
    {
        Livewire::test(UserForm::class)
            ->call('save')
            ->assertHasErrors(['user.name', 'user.email']);
    }
}
```

## Polling and Real-time Updates

### Efficient Polling
```php
<!-- Poll every 2 seconds -->
<div wire:poll.2s>
    Current time: {{ now() }}
</div>

<!-- Conditional polling -->
<div wire:poll.5s="refreshStats">
    @if($isActive)
        <!-- Content -->
    @endif
</div>

<!-- Keep alive -->
<div wire:poll.keep-alive>
    <!-- Prevents session timeout -->
</div>
```

### WebSocket Integration
```php
// Using Laravel Echo
class ChatComponent extends Component
{
    public $messages = [];
    
    public function mount()
    {
        $this->loadMessages();
    }
    
    public function getListeners()
    {
        return [
            "echo:chat.{$this->chatId},MessageSent" => 'onMessageSent',
        ];
    }
    
    public function onMessageSent($payload)
    {
        $this->messages[] = $payload['message'];
    }
}
```

## Loading States

### Targeted Loading
```blade
<button wire:click="save" wire:loading.attr="disabled">
    <span wire:loading.remove wire:target="save">Save</span>
    <span wire:loading wire:target="save">Saving...</span>
</button>

<div wire:loading.class="opacity-50" wire:target="search">
    <!-- Content that dims while searching -->
</div>

<div wire:loading.delay.longest>
    <!-- Shows only for long operations -->
</div>
```

## Deployment Considerations

### Production Optimization
```php
// config/livewire.php
return [
    'asset_url' => env('ASSET_URL', null),
    'app_url' => env('APP_URL', 'http://localhost'),
    'middleware_group' => 'web',
    'temporary_file_upload' => [
        'disk' => 's3', // Use S3 for production
        'rules' => 'file|max:12288', // 12MB
        'directory' => 'livewire-tmp',
        'middleware' => 'throttle:60,1',
        'preview_mimes' => [
            'png', 'gif', 'bmp', 'svg', 'wav', 'mp4',
            'mov', 'avi', 'wmv', 'mp3', 'm4a', 'jpg', 'jpeg',
        ],
    ],
];
```

### Caching Strategies
```php
class CachedComponent extends Component
{
    public function mount()
    {
        // Cache component data
        $this->data = Cache::remember('component.data', 3600, function () {
            return expensive_operation();
        });
    }
    
    public function refresh()
    {
        Cache::forget('component.data');
        $this->mount();
    }
}
```

## Common Patterns

### Modal Management
```php
class ModalComponent extends Component
{
    public $showModal = false;
    public $modalData = [];
    
    protected $listeners = ['openModal'];
    
    public function openModal($data = [])
    {
        $this->modalData = $data;
        $this->showModal = true;
    }
    
    public function closeModal()
    {
        $this->showModal = false;
        $this->reset('modalData');
    }
}
```

### Infinite Scroll
```php
class InfiniteScroll extends Component
{
    public $items = [];
    public $page = 1;
    public $hasMore = true;
    
    public function loadMore()
    {
        if (!$this->hasMore) return;
        
        $newItems = Item::paginate(10, ['*'], 'page', $this->page);
        
        $this->items = array_merge($this->items, $newItems->items());
        $this->hasMore = $newItems->hasMorePages();
        $this->page++;
    }
}
```

## Anti-Patterns to Avoid

1. **Avoid Large Component State**: Keep component properties minimal
2. **Don't Use Raw SQL**: Always use Eloquent or Query Builder
3. **Avoid Complex Computed Properties**: Cache expensive operations
4. **Don't Forget wire:key**: Use for dynamic lists
5. **Avoid Inline Styles**: Use CSS classes for better performance
6. **Don't Ignore N+1 Queries**: Use eager loading
7. **Avoid Public Methods for Everything**: Use protected/private when possible
8. **Don't Store Sensitive Data in Public Properties**: Use sessions or encrypted storage

## Debugging Tips

### Debug Mode
```php
// Enable debug mode in development
class DebugComponent extends Component
{
    public function mount()
    {
        if (config('app.debug')) {
            \Debugbar::info('Component mounted');
        }
    }
}
```

### Ray Integration
```php
public function troubleshoot()
{
    ray($this->all())->label('Component State');
    ray()->measure(function() {
        // Code to measure
    });
}
```

## Conclusion

Laravel Livewire enables rapid development of dynamic interfaces while staying in PHP. Following these best practices ensures your Livewire applications are performant, secure, and maintainable. Focus on component organization, optimize for performance, and always validate and secure user input.