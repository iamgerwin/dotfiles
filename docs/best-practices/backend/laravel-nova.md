# Laravel Nova Best Practices

## Overview
Laravel Nova is a beautifully designed administration panel for Laravel applications. It provides a simple, powerful interface for managing database records.

## Documentation
- [Official Documentation](https://nova.laravel.com/docs)
- [API Reference](https://nova.laravel.com/docs/4.0/api-reference.html)
- [Nova Packages](https://novapackages.com)

## Installation

```bash
composer require laravel/nova
php artisan nova:install
php artisan migrate
```

## Project Structure

```
app/
├── Nova/
│   ├── Actions/
│   ├── Cards/
│   ├── Dashboards/
│   ├── Filters/
│   ├── Lenses/
│   ├── Metrics/
│   ├── Resources/
│   └── User.php
nova/
├── resources/
│   ├── js/
│   └── sass/
└── src/
```

## Core Best Practices

### 1. Resource Organization

```php
namespace App\Nova;

use Laravel\Nova\Fields\ID;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Fields\BelongsTo;
use Laravel\Nova\Http\Requests\NovaRequest;

class Post extends Resource
{
    public static $model = \App\Models\Post::class;
    
    public static $title = 'title';
    
    public static $search = [
        'id', 'title', 'slug'
    ];
    
    public static $globallySearchable = true;
    
    public function fields(NovaRequest $request)
    {
        return [
            ID::make()->sortable(),
            
            Text::make('Title')
                ->sortable()
                ->rules('required', 'max:255'),
                
            BelongsTo::make('Author', 'author', User::class)
                ->searchable()
                ->withSubtitles(),
        ];
    }
}
```

### 2. Custom Actions

```php
namespace App\Nova\Actions;

use Laravel\Nova\Actions\Action;
use Laravel\Nova\Fields\ActionFields;
use Laravel\Nova\Fields\Select;
use Laravel\Nova\Http\Requests\NovaRequest;

class PublishPosts extends Action
{
    public $name = 'Publish Posts';
    
    public function handle(ActionFields $fields, Collection $models)
    {
        foreach ($models as $model) {
            $model->update(['status' => 'published']);
        }
        
        return Action::message('Posts published successfully!');
    }
    
    public function fields(NovaRequest $request)
    {
        return [
            Select::make('Notification Type')->options([
                'email' => 'Email',
                'slack' => 'Slack',
            ]),
        ];
    }
}
```

### 3. Custom Metrics

```php
namespace App\Nova\Metrics;

use Laravel\Nova\Http\Requests\NovaRequest;
use Laravel\Nova\Metrics\Value;

class NewUsers extends Value
{
    public function calculate(NovaRequest $request)
    {
        return $this->count($request, User::class);
    }
    
    public function ranges()
    {
        return [
            30 => __('30 Days'),
            60 => __('60 Days'),
            365 => __('365 Days'),
            'TODAY' => __('Today'),
            'MTD' => __('Month To Date'),
            'YTD' => __('Year To Date'),
        ];
    }
    
    public function cacheFor()
    {
        return now()->addMinutes(5);
    }
}
```

### 4. Custom Filters

```php
namespace App\Nova\Filters;

use Laravel\Nova\Filters\Filter;
use Laravel\Nova\Http\Requests\NovaRequest;

class PostStatus extends Filter
{
    public function apply(NovaRequest $request, $query, $value)
    {
        return $query->where('status', $value);
    }
    
    public function options(NovaRequest $request)
    {
        return [
            'Draft' => 'draft',
            'Published' => 'published',
            'Archived' => 'archived',
        ];
    }
}
```

### 5. Field Validation

```php
public function fields(NovaRequest $request)
{
    return [
        Text::make('Email')
            ->sortable()
            ->rules('required', 'email', 'max:254')
            ->creationRules('unique:users,email')
            ->updateRules('unique:users,email,{{resourceId}}'),
            
        Password::make('Password')
            ->onlyOnForms()
            ->creationRules('required', Rules\Password::defaults())
            ->updateRules('nullable', Rules\Password::defaults()),
    ];
}
```

### 6. Authorization

```php
class Post extends Resource
{
    public static function authorizable()
    {
        return true;
    }
    
    public function authorizedToView(Request $request)
    {
        return $request->user()->can('view', $this->resource);
    }
    
    public function authorizedToUpdate(Request $request)
    {
        return $request->user()->can('update', $this->resource);
    }
    
    public function authorizedToDelete(Request $request)
    {
        return $request->user()->can('delete', $this->resource);
    }
}
```

### 7. Custom Tools

```php
namespace App\Nova\Tools;

use Laravel\Nova\Nova;
use Laravel\Nova\Tool;

class Reports extends Tool
{
    public function boot()
    {
        Nova::script('reports', __DIR__.'/../../dist/js/tool.js');
        Nova::style('reports', __DIR__.'/../../dist/css/tool.css');
    }
    
    public function renderNavigation()
    {
        return view('nova.tools.reports');
    }
}
```

### 8. Lenses

```php
namespace App\Nova\Lenses;

use Laravel\Nova\Fields\ID;
use Laravel\Nova\Fields\Text;
use Laravel\Nova\Lenses\Lens;
use Laravel\Nova\Http\Requests\LensRequest;

class MostPopularPosts extends Lens
{
    public static function query(LensRequest $request, $query)
    {
        return $request->withOrdering($request->withFilters(
            $query->select([
                'posts.id',
                'posts.title',
                DB::raw('count(views.id) as views_count')
            ])
            ->join('views', 'posts.id', '=', 'views.post_id')
            ->groupBy('posts.id', 'posts.title')
        ));
    }
    
    public function fields(NovaRequest $request)
    {
        return [
            ID::make('ID', 'id'),
            Text::make('Title'),
            Number::make('Views', 'views_count'),
        ];
    }
}
```

## Performance Optimization

### 1. Eager Loading

```php
public static $with = ['author', 'category', 'tags'];

public static function relatableQuery(NovaRequest $request, $query)
{
    return parent::relatableQuery($request, $query)
        ->with(['profile']);
}
```

### 2. Pagination

```php
public static $perPageViaRelationship = 10;
public static $perPageOptions = [25, 50, 100];
```

### 3. Caching Metrics

```php
public function cacheFor()
{
    return now()->addMinutes(5);
}

public function uriKey()
{
    return 'new-users-metric';
}
```

## Custom Fields

### 1. Creating Custom Fields

```php
namespace App\Nova\Fields;

use Laravel\Nova\Fields\Field;

class ColorPicker extends Field
{
    public $component = 'color-picker';
    
    public function presetColors($colors)
    {
        return $this->withMeta(['presetColors' => $colors]);
    }
}
```

### 2. Vue Component

```javascript
// resources/js/components/ColorPicker.vue
<template>
    <default-field :field="field" :errors="errors">
        <template slot="field">
            <input
                type="color"
                class="w-full form-control form-input form-input-bordered"
                :id="field.attribute"
                :value="value"
                @input="handleChange"
            />
        </template>
    </default-field>
</template>

<script>
import { FormField, HandlesValidationErrors } from 'laravel-nova'

export default {
    mixins: [FormField, HandlesValidationErrors],
    
    methods: {
        setInitialValue() {
            this.value = this.field.value || '#000000'
        },
        
        fill(formData) {
            formData.append(this.field.attribute, this.value || '')
        },
        
        handleChange(e) {
            this.value = e.target.value
        }
    }
}
</script>
```

## Testing

```php
use Laravel\Nova\Testing\TestsActions;

class PublishPostActionTest extends TestCase
{
    use TestsActions;
    
    public function test_can_publish_posts()
    {
        $posts = Post::factory()->count(3)->create(['status' => 'draft']);
        
        $response = $this->runAction(
            PublishPosts::class,
            Post::class,
            $posts->pluck('id')->toArray()
        );
        
        $response->assertOk();
        
        $posts->each(function ($post) {
            $this->assertEquals('published', $post->fresh()->status);
        });
    }
}
```

## Security Best Practices

1. **Policy Implementation**: Always implement policies for resources
2. **Field Authorization**: Use field-level authorization for sensitive data
3. **Action Authorization**: Restrict actions to authorized users
4. **SQL Injection**: Use parameter binding in custom queries
5. **XSS Protection**: Sanitize user input in custom fields

## Common Pitfalls

1. **N+1 Queries**: Not using eager loading
2. **Large Datasets**: Not implementing proper pagination
3. **Missing Indexes**: Forgetting to index searchable columns
4. **Uncached Metrics**: Not caching expensive metric calculations
5. **Missing Authorization**: Forgetting to implement resource policies

## Useful Packages

### UI & Layout Enhancements
- `eminiarts/nova-tabs`: Organize resource fields into tabs for better UX
- `whitecube/nova-flexible-content`: Create flexible, repeatable content blocks and layouts
- `murdercode/nova4-tinymce-editor`: Rich text editor with TinyMCE for Nova 4
- `ek0519/quilljs`: Modern WYSIWYG editor using Quill.js

### Media & File Management
- `outl1ne/nova-media-hub`: Centralized media library with image optimization and cropping
- `ebess/advanced-nova-media-library`: Media management with Spatie Media Library integration
- `intervention/image`: PHP image manipulation library for resizing, cropping, and filters
- `spatie/image`: Fluent interface for image manipulations

### Field Extensions
- `alexwenzel/nova-dependency-container`: Show/hide fields based on other field values
- `outl1ne/nova-multiselect-field`: Enhanced multiselect field with search and tagging

### Content Management
- `outl1ne/nova-page-manager`: Full page management system with templates and regions
- `outl1ne/nova-menu-builder`: Visual menu builder with drag-and-drop interface
- `outl1ne/nova-settings`: Simple key-value settings management
- `optimistdigital/nova-menu-builder`: Alternative menu management solution

### Laravel Integrations
- `laravel/sanctum`: Simple API authentication for SPAs and mobile apps
- `laravel/scout`: Full-text search for Eloquent models with driver support
- `fruitcake/laravel-cors`: Cross-Origin Resource Sharing (CORS) support

### Monitoring & Logging
- `bilfeldt/laravel-request-logger`: Log HTTP requests and responses for debugging
- `sentry/sentry-laravel`: Error tracking and performance monitoring
- `spatie/laravel-activitylog`: Log model changes and user activities
- `venturecraft/revisionable`: Track and revert model changes with history

### Data & Query Management
- `spatie/laravel-query-builder`: Build Eloquent queries from API requests
- `spatie/laravel-tags`: Add tagging functionality to any model
- `spatie/laravel-sluggable`: Generate SEO-friendly slugs for models

### Permissions & Security
- `spatie/laravel-permission`: Role and permission management system
- `spatie/nova-backup-tool`: Backup management interface for Nova
- `kabbouchi/nova-impersonate`: User impersonation for testing and support
- `vyuldashev/nova-permission`: Permission management integrated with Nova

### Image Optimization
- `spatie/laravel-image-optimizer`: Automatically optimize images on upload
- `intervention/image`: Image manipulation with resize, crop, and filter support

### API Documentation
- `darkaonline/l5-swagger`: Generate interactive API documentation with Swagger UI

### Utility Packages
- `nova-kit/nova-packages-tool`: Discover and manage Nova packages
- `laravel/nova-log-viewer`: View application logs within Nova interface

## Deployment

```bash
# Production build
npm run production

# Publishing assets
php artisan nova:publish

# Clear caches
php artisan cache:clear
php artisan view:clear
php artisan config:clear
```

## Advanced Features

### 1. Repeater Fields

```php
use Laravel\Nova\Fields\Repeater;

Repeater::make('Options')
    ->repeatables([
        \App\Nova\Repeatables\SimpleOption::make(),
        \App\Nova\Repeatables\AdvancedOption::make(),
    ])
    ->asJson()
```

### 2. Dependent Fields

```php
Select::make('Country')
    ->options($countries)
    ->searchable(),

Select::make('State')
    ->dependsOn(['country'], function ($field, $request, $formData) {
        $field->options(
            State::where('country_id', $formData->country)->pluck('name', 'id')
        );
    }),
```

### 3. Custom Cards

```php
namespace App\Nova\Cards;

use Laravel\Nova\Card;

class RevenueChart extends Card
{
    public $width = '1/2';
    
    public function component()
    {
        return 'revenue-chart';
    }
    
    public function revenue()
    {
        return $this->withMeta([
            'revenue' => Order::sum('total')
        ]);
    }
}
```