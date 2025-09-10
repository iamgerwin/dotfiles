# Laravel Eloquent ORM Best Practices

## Overview
Eloquent is Laravel's ActiveRecord ORM implementation that provides a beautiful, simple way to work with your database. Each database table has a corresponding "Model" that interacts with that table.

## Documentation
- [Official Eloquent Documentation](https://laravel.com/docs/eloquent)
- [Eloquent Relationships](https://laravel.com/docs/eloquent-relationships)
- [Eloquent Collections](https://laravel.com/docs/eloquent-collections)
- [Query Builder](https://laravel.com/docs/queries)

## Model Definition

### Basic Model Setup

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Carbon\Carbon;

class Post extends Model
{
    use HasFactory, SoftDeletes;
    
    /**
     * The table associated with the model.
     */
    protected $table = 'posts';
    
    /**
     * The primary key associated with the table.
     */
    protected $primaryKey = 'id';
    
    /**
     * Indicates if the model's ID is auto-incrementing.
     */
    public $incrementing = true;
    
    /**
     * The data type of the primary key ID.
     */
    protected $keyType = 'int';
    
    /**
     * Indicates if the model should be timestamped.
     */
    public $timestamps = true;
    
    /**
     * The storage format of the model's date columns.
     */
    protected $dateFormat = 'Y-m-d H:i:s';
    
    /**
     * The connection name for the model.
     */
    protected $connection = 'mysql';
    
    /**
     * The attributes that are mass assignable.
     */
    protected $fillable = [
        'title',
        'slug',
        'content',
        'excerpt',
        'user_id',
        'category_id',
        'published_at',
        'meta_data',
        'status',
    ];
    
    /**
     * The attributes that should be hidden for serialization.
     */
    protected $hidden = [
        'deleted_at',
    ];
    
    /**
     * The attributes that should be cast.
     */
    protected $casts = [
        'published_at' => 'datetime',
        'meta_data' => 'array',
        'is_featured' => 'boolean',
        'view_count' => 'integer',
        'settings' => 'collection',
        'tags' => 'array',
    ];
    
    /**
     * The model's default values for attributes.
     */
    protected $attributes = [
        'status' => 'draft',
        'view_count' => 0,
        'is_featured' => false,
    ];
    
    /**
     * The accessors to append to the model's array form.
     */
    protected $appends = ['reading_time', 'is_published'];
    
    /**
     * The relationships that should always be loaded.
     */
    protected $with = ['category'];
    
    /**
     * The number of models to return for pagination.
     */
    protected $perPage = 15;
}
```

### Accessors and Mutators

```php
class Post extends Model
{
    // Accessor - get attribute
    protected function title(): Attribute
    {
        return Attribute::make(
            get: fn (string $value) => ucfirst($value),
            set: fn (string $value) => strtolower($value),
        );
    }
    
    // Computed attribute accessor
    protected function readingTime(): Attribute
    {
        return Attribute::make(
            get: function () {
                $words = str_word_count(strip_tags($this->content));
                $minutes = ceil($words / 200); // Average reading speed
                return $minutes . ' min read';
            }
        );
    }
    
    // Boolean accessor
    protected function isPublished(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->published_at && $this->published_at->isPast()
        );
    }
    
    // Date accessor with formatting
    protected function publishedDate(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->published_at?->format('M d, Y')
        );
    }
    
    // JSON accessor
    protected function metaData(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => json_decode($value, true) ?? [],
            set: fn ($value) => json_encode($value)
        );
    }
    
    // Encrypted attribute
    protected function apiKey(): Attribute
    {
        return Attribute::make(
            get: fn ($value) => decrypt($value),
            set: fn ($value) => encrypt($value)
        );
    }
}
```

## Relationships

### One-to-One

```php
class User extends Model
{
    public function profile()
    {
        return $this->hasOne(Profile::class);
    }
    
    public function latestProfile()
    {
        return $this->hasOne(Profile::class)->latestOfMany();
    }
    
    public function oldestProfile()
    {
        return $this->hasOne(Profile::class)->oldestOfMany();
    }
}

class Profile extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
```

### One-to-Many

```php
class Post extends Model
{
    public function comments()
    {
        return $this->hasMany(Comment::class);
    }
    
    public function approvedComments()
    {
        return $this->hasMany(Comment::class)->where('approved', true);
    }
    
    public function latestComment()
    {
        return $this->hasOne(Comment::class)->latestOfMany();
    }
}

class Comment extends Model
{
    public function post()
    {
        return $this->belongsTo(Post::class);
    }
}
```

### Many-to-Many

```php
class User extends Model
{
    public function roles()
    {
        return $this->belongsToMany(Role::class)
            ->using(RoleUser::class) // Custom pivot model
            ->withPivot('assigned_at', 'assigned_by')
            ->withTimestamps()
            ->as('membership');
    }
    
    public function activeRoles()
    {
        return $this->belongsToMany(Role::class)
            ->wherePivot('active', true)
            ->wherePivotBetween('assigned_at', ['2024-01-01', '2024-12-31']);
    }
}

class Role extends Model
{
    public function users()
    {
        return $this->belongsToMany(User::class);
    }
    
    public function permissions()
    {
        return $this->belongsToMany(Permission::class);
    }
}

// Custom Pivot Model
use Illuminate\Database\Eloquent\Relations\Pivot;

class RoleUser extends Pivot
{
    protected $table = 'role_user';
    
    protected $casts = [
        'assigned_at' => 'datetime',
    ];
    
    public function assignedBy()
    {
        return $this->belongsTo(User::class, 'assigned_by');
    }
}
```

### Has-One-Through & Has-Many-Through

```php
class Country extends Model
{
    public function posts()
    {
        return $this->hasManyThrough(Post::class, User::class);
    }
    
    public function latestPost()
    {
        return $this->hasOneThrough(Post::class, User::class)
            ->latestOfMany();
    }
}

class Mechanic extends Model
{
    public function carOwner()
    {
        return $this->hasOneThrough(
            Owner::class,
            Car::class,
            'mechanic_id', // Foreign key on cars table
            'car_id',      // Foreign key on owners table
            'id',          // Local key on mechanics table
            'id'           // Local key on cars table
        );
    }
}
```

### Polymorphic Relationships

```php
// One-to-One Polymorphic
class Image extends Model
{
    public function imageable()
    {
        return $this->morphTo();
    }
}

class Post extends Model
{
    public function image()
    {
        return $this->morphOne(Image::class, 'imageable');
    }
}

class User extends Model
{
    public function image()
    {
        return $this->morphOne(Image::class, 'imageable');
    }
}

// One-to-Many Polymorphic
class Comment extends Model
{
    public function commentable()
    {
        return $this->morphTo();
    }
}

class Post extends Model
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}

class Video extends Model
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}

// Many-to-Many Polymorphic
class Tag extends Model
{
    public function posts()
    {
        return $this->morphedByMany(Post::class, 'taggable');
    }
    
    public function videos()
    {
        return $this->morphedByMany(Video::class, 'taggable');
    }
}

class Post extends Model
{
    public function tags()
    {
        return $this->morphToMany(Tag::class, 'taggable')
            ->withTimestamps();
    }
}
```

## Query Scopes

### Local Scopes

```php
class Post extends Model
{
    /**
     * Scope a query to only include published posts.
     */
    public function scopePublished($query)
    {
        return $query->where('published_at', '<=', now())
                     ->where('status', 'published');
    }
    
    /**
     * Scope a query to only include posts of a given type.
     */
    public function scopeOfType($query, $type)
    {
        return $query->where('type', $type);
    }
    
    /**
     * Scope for popular posts
     */
    public function scopePopular($query, $minViews = 1000)
    {
        return $query->where('view_count', '>=', $minViews)
                     ->orderBy('view_count', 'desc');
    }
    
    /**
     * Dynamic scope with multiple parameters
     */
    public function scopeFilter($query, array $filters)
    {
        return $query->when($filters['search'] ?? null, function ($query, $search) {
            $query->where(function ($query) use ($search) {
                $query->where('title', 'like', "%{$search}%")
                      ->orWhere('content', 'like', "%{$search}%");
            });
        })->when($filters['category'] ?? null, function ($query, $category) {
            $query->whereHas('category', function ($query) use ($category) {
                $query->where('slug', $category);
            });
        })->when($filters['author'] ?? null, function ($query, $author) {
            $query->whereHas('author', function ($query) use ($author) {
                $query->where('username', $author);
            });
        });
    }
}

// Usage
$posts = Post::published()->popular()->get();
$posts = Post::ofType('tutorial')->filter($request->all())->paginate();
```

### Global Scopes

```php
namespace App\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class PublishedScope implements Scope
{
    public function apply(Builder $builder, Model $model)
    {
        $builder->where('status', 'published');
    }
}

// In Model
class Post extends Model
{
    protected static function booted()
    {
        static::addGlobalScope(new PublishedScope);
        
        // Anonymous global scope
        static::addGlobalScope('ancient', function (Builder $builder) {
            $builder->where('created_at', '<', now()->subYears(2));
        });
    }
}

// Remove global scope
Post::withoutGlobalScope(PublishedScope::class)->get();
Post::withoutGlobalScope('ancient')->get();
Post::withoutGlobalScopes()->get();
Post::withoutGlobalScopes([PublishedScope::class, 'ancient'])->get();
```

## Advanced Queries

### Eager Loading

```php
// Basic eager loading
$posts = Post::with('comments')->get();

// Multiple relationships
$posts = Post::with(['comments', 'author', 'tags'])->get();

// Nested eager loading
$posts = Post::with('comments.author')->get();

// Eager loading with constraints
$posts = Post::with(['comments' => function ($query) {
    $query->where('approved', true)
          ->orderBy('created_at', 'desc');
}])->get();

// Eager load counts
$posts = Post::withCount('comments')->get();
$posts = Post::withCount([
    'comments',
    'comments as approved_comments_count' => function ($query) {
        $query->where('approved', true);
    }
])->get();

// Eager load with aggregates
$posts = Post::withSum('comments', 'votes')->get();
$posts = Post::withAvg('ratings', 'score')->get();
$posts = Post::withMax('bids', 'amount')->get();
$posts = Post::withMin('products', 'price')->get();

// Conditional eager loading
$posts = Post::when($request->include_comments, function ($query) {
    return $query->with('comments');
})->get();

// Lazy eager loading
$posts = Post::all();
$posts->load('comments'); // Load after retrieval
$posts->loadCount('comments');
$posts->loadMissing('author'); // Only load if not already loaded
```

### Subqueries

```php
use App\Models\Destination;
use App\Models\Flight;

// Select subquery
$destinations = Destination::addSelect(['last_flight' => Flight::select('name')
    ->whereColumn('destination_id', 'destinations.id')
    ->orderBy('arrived_at', 'desc')
    ->limit(1)
])->get();

// OrderBy subquery
$users = User::orderByDesc(
    Post::select('created_at')
        ->whereColumn('user_id', 'users.id')
        ->latest()
        ->limit(1)
)->get();

// Subquery in where clause
$users = User::whereExists(function ($query) {
    $query->select(DB::raw(1))
          ->from('posts')
          ->whereColumn('posts.user_id', 'users.id');
})->get();
```

### Advanced Where Clauses

```php
// Where with closure
$users = User::where(function ($query) {
    $query->where('votes', '>', 100)
          ->orWhere('name', 'John');
})->get();

// WhereHas with count
$posts = Post::whereHas('comments', function ($query) {
    $query->where('approved', true);
}, '>=', 10)->get();

// WhereDoesntHave
$posts = Post::whereDoesntHave('comments', function ($query) {
    $query->where('spam', true);
})->get();

// WhereRelation
$posts = Post::whereRelation('comments', 'approved', true)->get();
$posts = Post::whereRelation('author', 'verified_at', '!=', null)->get();

// JSON Where clauses
$users = User::where('preferences->dining->meal', 'salad')->get();
$users = User::whereJsonContains('options->languages', 'en')->get();
$users = User::whereJsonLength('options->languages', '>', 1)->get();

// Full text search
$posts = Post::whereFullText('content', 'Laravel')->get();
```

## Model Events and Observers

### Model Events

```php
class Post extends Model
{
    protected static function booted()
    {
        // Creating event
        static::creating(function ($post) {
            $post->slug = Str::slug($post->title);
            $post->uuid = Str::uuid();
        });
        
        // Created event
        static::created(function ($post) {
            Cache::forget('posts.all');
            event(new PostCreated($post));
        });
        
        // Updating event
        static::updating(function ($post) {
            if ($post->isDirty('title')) {
                $post->slug = Str::slug($post->title);
            }
        });
        
        // Updated event
        static::updated(function ($post) {
            if ($post->wasChanged('status')) {
                // Status was changed
                activity()
                    ->performedOn($post)
                    ->log('Post status changed to ' . $post->status);
            }
        });
        
        // Saving event (fired for both create and update)
        static::saving(function ($post) {
            $post->excerpt = Str::limit($post->content, 200);
        });
        
        // Deleting event
        static::deleting(function ($post) {
            // Delete related records
            $post->comments()->delete();
            $post->tags()->detach();
        });
        
        // Deleted event
        static::deleted(function ($post) {
            Cache::forget("posts.{$post->id}");
        });
        
        // Restoring event (for soft deletes)
        static::restoring(function ($post) {
            Log::info("Restoring post: {$post->id}");
        });
        
        // Restored event
        static::restored(function ($post) {
            Cache::forget('posts.trashed');
        });
    }
}
```

### Observers

```php
namespace App\Observers;

use App\Models\Post;
use Illuminate\Support\Facades\Cache;

class PostObserver
{
    public function creating(Post $post)
    {
        $post->user_id = auth()->id();
        $post->slug = Str::slug($post->title);
    }
    
    public function created(Post $post)
    {
        // Send notification
        $post->author->notify(new PostPublished($post));
        
        // Clear cache
        Cache::tags(['posts'])->flush();
    }
    
    public function updating(Post $post)
    {
        // Log changes
        foreach ($post->getDirty() as $attribute => $value) {
            $original = $post->getOriginal($attribute);
            Log::info("Post {$post->id}: {$attribute} changed from {$original} to {$value}");
        }
    }
    
    public function updated(Post $post)
    {
        // Update search index
        $post->searchable();
    }
    
    public function deleting(Post $post)
    {
        // Prevent deletion if post has comments
        if ($post->comments()->count() > 0) {
            throw new \Exception('Cannot delete post with comments');
        }
    }
    
    public function deleted(Post $post)
    {
        // Remove from search index
        $post->unsearchable();
    }
    
    public function forceDeleted(Post $post)
    {
        // Clean up files
        Storage::delete($post->featured_image);
    }
}

// Register observer in AppServiceProvider
use App\Models\Post;
use App\Observers\PostObserver;

public function boot()
{
    Post::observe(PostObserver::class);
}
```

## Collections

### Collection Methods

```php
// Transform collection
$collection = Post::all();

$filtered = $collection->filter(function ($post) {
    return $post->view_count > 1000;
});

$mapped = $collection->map(function ($post) {
    return [
        'title' => $post->title,
        'url' => route('posts.show', $post),
        'author' => $post->author->name,
    ];
});

$sorted = $collection->sortBy('created_at');
$sorted = $collection->sortByDesc('view_count');

$grouped = $collection->groupBy('category_id');
$grouped = $collection->groupBy(function ($post) {
    return $post->created_at->format('Y-m');
});

$chunked = $collection->chunk(10);

$plucked = $collection->pluck('title', 'id');

// Aggregate methods
$sum = $collection->sum('view_count');
$avg = $collection->avg('rating');
$min = $collection->min('price');
$max = $collection->max('price');

// Collection operations
$collection->contains('title', 'Laravel');
$collection->contains(function ($post) {
    return $post->published;
});

$collection->unique('category_id');
$collection->diff($otherCollection);
$collection->intersect($otherCollection);
$collection->merge($otherCollection);

// Higher order messages
$collection->each->delete();
$collection->each->update(['status' => 'archived']);
$titles = $collection->map->title;
$sum = $collection->sum->view_count;
```

### Custom Collections

```php
namespace App\Collections;

use Illuminate\Database\Eloquent\Collection;

class PostCollection extends Collection
{
    public function published()
    {
        return $this->filter(function ($post) {
            return $post->is_published;
        });
    }
    
    public function byCategory($category)
    {
        return $this->filter(function ($post) use ($category) {
            return $post->category_id === $category;
        });
    }
    
    public function trending($limit = 5)
    {
        return $this->sortByDesc('view_count')->take($limit);
    }
    
    public function toSitemap()
    {
        return $this->map(function ($post) {
            return [
                'loc' => route('posts.show', $post),
                'lastmod' => $post->updated_at->toW3cString(),
                'changefreq' => 'weekly',
                'priority' => 0.8,
            ];
        });
    }
}

// In Post model
public function newCollection(array $models = [])
{
    return new PostCollection($models);
}

// Usage
$posts = Post::all();
$trending = $posts->trending(10);
$published = $posts->published();
```

## Performance Optimization

### Query Optimization

```php
// Use select to limit columns
$users = User::select('id', 'name', 'email')->get();

// Use chunk for large datasets
User::chunk(200, function ($users) {
    foreach ($users as $user) {
        // Process user
    }
});

// Use cursor for memory efficiency
foreach (User::cursor() as $user) {
    // Process user
}

// Use lazy collections
User::lazy()->each(function ($user) {
    // Process user
});

// Avoid N+1 queries
// Bad
$posts = Post::all();
foreach ($posts as $post) {
    echo $post->author->name; // N+1 query
}

// Good
$posts = Post::with('author')->get();
foreach ($posts as $post) {
    echo $post->author->name; // No additional queries
}

// Index optimization hints
$users = User::where('email', $email)
    ->useIndex('email_index')
    ->first();

// Raw queries for complex operations
$results = DB::select(DB::raw('
    SELECT 
        users.name,
        COUNT(posts.id) as post_count,
        AVG(posts.view_count) as avg_views
    FROM users
    LEFT JOIN posts ON users.id = posts.user_id
    GROUP BY users.id
    HAVING post_count > 10
'));

// Cache queries
$posts = Cache::remember('popular.posts', 3600, function () {
    return Post::popular()->with('author')->take(10)->get();
});
```

### Database Indexing

```php
// Migration with indexes
Schema::create('posts', function (Blueprint $table) {
    $table->id();
    $table->string('title');
    $table->string('slug')->unique();
    $table->text('content');
    $table->foreignId('user_id')->constrained();
    $table->foreignId('category_id')->nullable()->constrained();
    $table->datetime('published_at')->nullable();
    $table->integer('view_count')->default(0);
    $table->timestamps();
    
    // Indexes
    $table->index('user_id');
    $table->index('category_id');
    $table->index('published_at');
    $table->index(['status', 'published_at']); // Composite index
    $table->fullText('content'); // Full text index
});
```

## Testing

```php
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class PostTest extends TestCase
{
    use RefreshDatabase, WithFaker;
    
    public function test_post_has_author_relationship()
    {
        $post = Post::factory()->create();
        
        $this->assertInstanceOf(User::class, $post->author);
    }
    
    public function test_scope_published()
    {
        Post::factory()->count(3)->create(['published_at' => now()->subDay()]);
        Post::factory()->count(2)->create(['published_at' => now()->addDay()]);
        
        $published = Post::published()->get();
        
        $this->assertCount(3, $published);
    }
    
    public function test_post_creation_generates_slug()
    {
        $post = Post::create([
            'title' => 'My First Post',
            'content' => 'Content here',
            'user_id' => User::factory()->create()->id,
        ]);
        
        $this->assertEquals('my-first-post', $post->slug);
    }
    
    public function test_soft_delete()
    {
        $post = Post::factory()->create();
        $postId = $post->id;
        
        $post->delete();
        
        $this->assertSoftDeleted('posts', ['id' => $postId]);
        $this->assertNotNull(Post::withTrashed()->find($postId));
        $this->assertNull(Post::find($postId));
    }
}
```

## Best Practices

1. **Use eager loading** to prevent N+1 queries
2. **Select only needed columns** to reduce memory usage
3. **Use database indexes** on frequently queried columns
4. **Implement caching** for expensive queries
5. **Use chunk() or cursor()** for large datasets
6. **Avoid model events** for bulk operations
7. **Use transactions** for data integrity
8. **Implement query scopes** for reusable queries
9. **Use accessors/mutators** for data transformation
10. **Write tests** for complex relationships and scopes