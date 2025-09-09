# Laravel Filament v4 Best Practices

## Official Documentation
- **Filament v4 Documentation**: https://filamentphp.com/docs
- **Laravel Documentation**: https://laravel.com/docs
- **Filament Plugin Directory**: https://filamentphp.com/plugins
- **Community Examples**: https://github.com/filamentphp

## Installation and Setup

### Initial Setup
```bash
# Install Laravel
composer create-project laravel/laravel filament-app

# Navigate to project
cd filament-app

# Install Filament v4
composer require filament/filament:"^4.0"

# Install Filament Panel
php artisan filament:install --panels

# Create admin user
php artisan make:filament-user
```

### Configuration
```php
// config/filament.php
<?php

return [
    'broadcasting' => [
        'echo' => [
            'broadcaster' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'cluster' => env('PUSHER_APP_CLUSTER'),
            'encrypted' => true,
        ],
    ],
    
    'default_filesystem_disk' => env('FILAMENT_FILESYSTEM_DISK', 'public'),
    
    'assets_path' => null,
    
    'cache_path' => base_path('bootstrap/cache/filament'),
    
    'livewire_loading_delay' => 'default',
];
```

## Project Structure

```
app/
├── Filament/
│   ├── Admin/
│   │   ├── Resources/
│   │   │   ├── UserResource.php
│   │   │   ├── PostResource/
│   │   │   │   ├── Pages/
│   │   │   │   │   ├── CreatePost.php
│   │   │   │   │   ├── EditPost.php
│   │   │   │   │   └── ListPosts.php
│   │   │   │   └── RelationManagers/
│   │   │   │       └── CommentsRelationManager.php
│   │   │   └── PostResource.php
│   │   ├── Widgets/
│   │   │   ├── StatsOverview.php
│   │   │   └── LatestOrders.php
│   │   └── Pages/
│   │       └── Dashboard.php
│   ├── App/
│   │   ├── Resources/
│   │   └── Pages/
│   └── Exports/
│       └── PostsExport.php
├── Livewire/
├── Policies/
└── Providers/
    ├── Filament/
    │   ├── AdminPanelProvider.php
    │   └── AppPanelProvider.php
    └── FilamentServiceProvider.php
```

## Core Best Practices

### 1. Panel Configuration

```php
// app/Providers/Filament/AdminPanelProvider.php
<?php

namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\MenuItem;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\AuthenticateSession;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->colors([
                'primary' => Color::Blue,
                'gray' => Color::Slate,
            ])
            ->discoverResources(in: app_path('Filament/Admin/Resources'), for: 'App\\Filament\\Admin\\Resources')
            ->discoverPages(in: app_path('Filament/Admin/Pages'), for: 'App\\Filament\\Admin\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Admin/Widgets'), for: 'App\\Filament\\Admin\\Widgets')
            ->widgets([
                Widgets\AccountWidget::class,
                Widgets\FilamentInfoWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ])
            ->brandName('Admin Panel')
            ->brandLogo(asset('images/logo.svg'))
            ->brandLogoHeight('2rem')
            ->favicon(asset('images/favicon.ico'))
            ->userMenuItems([
                MenuItem::make()
                    ->label('Settings')
                    ->url('/admin/settings')
                    ->icon('heroicon-o-cog-6-tooth'),
                'profile' => MenuItem::make()
                    ->label('Edit profile')
                    ->url('/admin/profile')
                    ->icon('heroicon-m-user-circle'),
            ])
            ->sidebarCollapsibleOnDesktop()
            ->sidebarFullyCollapsibleOnDesktop()
            ->navigationGroups([
                NavigationGroup::make('Content Management'),
                NavigationGroup::make('User Management'),
                NavigationGroup::make('System'),
            ]);
    }
}
```

### 2. Resource Implementation

```php
// app/Filament/Admin/Resources/PostResource.php
<?php

namespace App\Filament\Admin\Resources;

use App\Filament\Admin\Resources\PostResource\Pages;
use App\Filament\Admin\Resources\PostResource\RelationManagers;
use App\Models\Post;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Infolists\Infolist;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Components\ImageEntry;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class PostResource extends Resource
{
    protected static ?string $model = Post::class;
    
    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    
    protected static ?string $navigationGroup = 'Content Management';
    
    protected static ?int $navigationSort = 1;
    
    protected static ?string $recordTitleAttribute = 'title';
    
    protected static int $globalSearchResultsLimit = 5;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Content')
                            ->schema([
                                Forms\Components\TextInput::make('title')
                                    ->required()
                                    ->maxLength(255)
                                    ->live(onBlur: true)
                                    ->afterStateUpdated(fn ($state, callable $set) => 
                                        $set('slug', Str::slug($state))
                                    ),
                                
                                Forms\Components\TextInput::make('slug')
                                    ->required()
                                    ->maxLength(255)
                                    ->unique(ignoreRecord: true)
                                    ->rules(['regex:/^[a-z0-9\-]+$/']),
                                
                                Forms\Components\MarkdownEditor::make('content')
                                    ->required()
                                    ->columnSpanFull()
                                    ->fileAttachmentsDisk('public')
                                    ->fileAttachmentsDirectory('posts'),
                            ])
                            ->columns(2),
                        
                        Forms\Components\Section::make('SEO')
                            ->schema([
                                Forms\Components\TextInput::make('meta_title')
                                    ->maxLength(60)
                                    ->helperText('Recommended: 50-60 characters'),
                                
                                Forms\Components\Textarea::make('meta_description')
                                    ->maxLength(160)
                                    ->rows(3)
                                    ->helperText('Recommended: 150-160 characters'),
                                
                                Forms\Components\TagsInput::make('keywords')
                                    ->separator(','),
                            ])
                            ->collapsible(),
                    ])
                    ->columnSpan(['lg' => 2]),
                
                Forms\Components\Group::make()
                    ->schema([
                        Forms\Components\Section::make('Status')
                            ->schema([
                                Forms\Components\Select::make('status')
                                    ->options([
                                        'draft' => 'Draft',
                                        'published' => 'Published',
                                        'archived' => 'Archived',
                                    ])
                                    ->required()
                                    ->default('draft')
                                    ->native(false),
                                
                                Forms\Components\DateTimePicker::make('published_at')
                                    ->native(false)
                                    ->displayFormat('Y-m-d H:i')
                                    ->seconds(false),
                                
                                Forms\Components\Select::make('user_id')
                                    ->relationship('author', 'name')
                                    ->searchable()
                                    ->preload()
                                    ->required(),
                            ]),
                        
                        Forms\Components\Section::make('Featured Image')
                            ->schema([
                                Forms\Components\FileUpload::make('featured_image')
                                    ->image()
                                    ->disk('public')
                                    ->directory('posts/featured')
                                    ->imageEditor()
                                    ->imageEditorAspectRatios([
                                        '16:9',
                                        '4:3',
                                        '1:1',
                                    ]),
                            ]),
                        
                        Forms\Components\Section::make('Categories')
                            ->schema([
                                Forms\Components\Select::make('categories')
                                    ->relationship('categories', 'name')
                                    ->multiple()
                                    ->preload()
                                    ->createOptionForm([
                                        Forms\Components\TextInput::make('name')
                                            ->required()
                                            ->maxLength(255),
                                        Forms\Components\TextInput::make('slug')
                                            ->required()
                                            ->maxLength(255)
                                            ->unique(),
                                        Forms\Components\ColorPicker::make('color'),
                                    ]),
                            ]),
                    ])
                    ->columnSpan(['lg' => 1]),
            ])
            ->columns(3);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('featured_image')
                    ->disk('public')
                    ->size(40)
                    ->circular(),
                
                Tables\Columns\TextColumn::make('title')
                    ->searchable()
                    ->sortable()
                    ->limit(50)
                    ->tooltip(function (Tables\Columns\TextColumn $column): ?string {
                        $state = $column->getState();
                        return strlen($state) <= $column->getCharacterLimit() ? null : $state;
                    }),
                
                Tables\Columns\BadgeColumn::make('status')
                    ->colors([
                        'danger' => 'draft',
                        'warning' => 'archived',
                        'success' => 'published',
                    ])
                    ->icons([
                        'heroicon-o-x-circle' => 'draft',
                        'heroicon-o-clock' => 'archived',
                        'heroicon-o-check-circle' => 'published',
                    ]),
                
                Tables\Columns\TextColumn::make('author.name')
                    ->label('Author')
                    ->sortable()
                    ->searchable(),
                
                Tables\Columns\TextColumn::make('categories.name')
                    ->badge()
                    ->separator(',')
                    ->limit(30),
                
                Tables\Columns\TextColumn::make('published_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(),
                
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status')
                    ->options([
                        'draft' => 'Draft',
                        'published' => 'Published',
                        'archived' => 'Archived',
                    ]),
                
                Tables\Filters\SelectFilter::make('user_id')
                    ->relationship('author', 'name')
                    ->label('Author')
                    ->searchable()
                    ->preload(),
                
                Tables\Filters\SelectFilter::make('categories')
                    ->relationship('categories', 'name')
                    ->searchable()
                    ->preload()
                    ->multiple(),
                
                Tables\Filters\Filter::make('published')
                    ->query(fn (Builder $query): Builder => $query->whereNotNull('published_at'))
                    ->label('Published posts'),
                
                Tables\Filters\Filter::make('created_at')
                    ->form([
                        Forms\Components\DatePicker::make('created_from'),
                        Forms\Components\DatePicker::make('created_until'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when($data['created_from'], 
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '>=', $date)
                            )
                            ->when($data['created_until'], 
                                fn (Builder $query, $date): Builder => $query->whereDate('created_at', '<=', $date)
                            );
                    }),
                
                Tables\Filters\TrashedFilter::make(),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
                Tables\Actions\ForceDeleteAction::make(),
                Tables\Actions\RestoreAction::make(),
                
                Tables\Actions\Action::make('publish')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->action(function (Post $record) {
                        $record->update([
                            'status' => 'published',
                            'published_at' => now(),
                        ]);
                    })
                    ->requiresConfirmation()
                    ->visible(fn (Post $record): bool => $record->status !== 'published'),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\ForceDeleteBulkAction::make(),
                    Tables\Actions\RestoreBulkAction::make(),
                    
                    Tables\Actions\BulkAction::make('publish')
                        ->label('Publish selected')
                        ->icon('heroicon-o-check')
                        ->color('success')
                        ->action(function ($records) {
                            $records->each->update([
                                'status' => 'published',
                                'published_at' => now(),
                            ]);
                        })
                        ->requiresConfirmation(),
                ]),
            ])
            ->defaultSort('created_at', 'desc');
    }

    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                TextEntry::make('title'),
                TextEntry::make('slug'),
                TextEntry::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'draft' => 'gray',
                        'published' => 'success',
                        'archived' => 'warning',
                    }),
                TextEntry::make('author.name'),
                TextEntry::make('published_at')
                    ->dateTime(),
                ImageEntry::make('featured_image')
                    ->disk('public'),
                TextEntry::make('content')
                    ->markdown()
                    ->columnSpanFull(),
            ]);
    }
    
    public static function getRelations(): array
    {
        return [
            RelationManagers\CommentsRelationManager::class,
            RelationManagers\TagsRelationManager::class,
        ];
    }
    
    public static function getPages(): array
    {
        return [
            'index' => Pages\ListPosts::route('/'),
            'create' => Pages\CreatePost::route('/create'),
            'view' => Pages\ViewPost::route('/{record}'),
            'edit' => Pages\EditPost::route('/{record}/edit'),
        ];
    }
    
    public static function getEloquentQuery(): Builder
    {
        return parent::getEloquentQuery()
            ->withoutGlobalScopes([
                SoftDeletingScope::class,
            ]);
    }
    
    public static function getGlobalSearchEloquentQuery(): Builder
    {
        return parent::getGlobalSearchEloquentQuery()
            ->with(['author', 'categories']);
    }
    
    public static function getGloballySearchableAttributes(): array
    {
        return ['title', 'slug', 'content', 'author.name'];
    }
    
    public static function getGlobalSearchResultDetails(Model $record): array
    {
        return [
            'Author' => $record->author->name,
            'Status' => $record->status,
        ];
    }
}
```

### 3. Custom Pages

```php
// app/Filament/Admin/Pages/Dashboard.php
<?php

namespace App\Filament\Admin\Pages;

use Filament\Pages\Dashboard as BaseDashboard;
use Filament\Widgets\StatsOverviewWidget as BaseStatsOverviewWidget;

class Dashboard extends BaseDashboard
{
    protected static ?string $navigationIcon = 'heroicon-o-home';
    
    protected static string $view = 'filament.admin.pages.dashboard';
    
    public function getColumns(): int | array
    {
        return [
            'sm' => 1,
            'md' => 2,
            'xl' => 4,
        ];
    }
    
    public function getWidgets(): array
    {
        return [
            StatsOverviewWidget::class,
            LatestPostsWidget::class,
            PostsChart::class,
            LatestUsersWidget::class,
        ];
    }
}

// app/Filament/Admin/Pages/Settings.php
<?php

namespace App\Filament\Admin\Pages;

use Filament\Actions\Action;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class Settings extends Page implements HasForms
{
    use InteractsWithForms;
    
    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    
    protected static string $view = 'filament.admin.pages.settings';
    
    protected static ?string $navigationGroup = 'System';
    
    public ?array $data = [];
    
    public function mount(): void
    {
        $this->form->fill([
            'site_name' => setting('site_name'),
            'site_description' => setting('site_description'),
            'maintenance_mode' => setting('maintenance_mode', false),
            'registration_enabled' => setting('registration_enabled', true),
        ]);
    }
    
    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Section::make('General Settings')
                    ->schema([
                        TextInput::make('site_name')
                            ->label('Site Name')
                            ->required()
                            ->maxLength(255),
                        
                        Textarea::make('site_description')
                            ->label('Site Description')
                            ->rows(3)
                            ->maxLength(500),
                    ]),
                
                Section::make('System Settings')
                    ->schema([
                        Toggle::make('maintenance_mode')
                            ->label('Maintenance Mode')
                            ->helperText('When enabled, only administrators can access the site.'),
                        
                        Toggle::make('registration_enabled')
                            ->label('User Registration')
                            ->helperText('Allow new users to register accounts.'),
                    ]),
            ])
            ->statePath('data');
    }
    
    protected function getFormActions(): array
    {
        return [
            Action::make('save')
                ->label('Save Settings')
                ->submit('save'),
        ];
    }
    
    public function save(): void
    {
        $data = $this->form->getState();
        
        foreach ($data as $key => $value) {
            setting([$key => $value]);
        }
        
        Notification::make()
            ->title('Settings saved successfully')
            ->success()
            ->send();
    }
}
```

### 4. Widgets

```php
// app/Filament/Admin/Widgets/StatsOverviewWidget.php
<?php

namespace App\Filament\Admin\Widgets;

use App\Models\Post;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseStatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverviewWidget extends BaseStatsOverviewWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Posts', Post::count())
                ->description('All time posts')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->chart([7, 2, 10, 3, 15, 4, 17]),
            
            Stat::make('Published Posts', Post::where('status', 'published')->count())
                ->description('Currently published')
                ->descriptionIcon('heroicon-m-eye')
                ->color('primary'),
            
            Stat::make('Draft Posts', Post::where('status', 'draft')->count())
                ->description('Awaiting publication')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('warning'),
            
            Stat::make('Total Users', User::count())
                ->description('Registered users')
                ->descriptionIcon('heroicon-m-users')
                ->color('info'),
        ];
    }
}

// app/Filament/Admin/Widgets/PostsChart.php
<?php

namespace App\Filament\Admin\Widgets;

use App\Models\Post;
use Filament\Widgets\ChartWidget;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

class PostsChart extends ChartWidget
{
    protected static ?string $heading = 'Posts Created';
    
    protected static ?int $sort = 2;
    
    public ?string $filter = 'last_week';
    
    protected function getData(): array
    {
        $activeFilter = $this->filter;
        
        $data = match ($activeFilter) {
            'today' => Trend::model(Post::class)
                ->between(
                    start: now()->startOfDay(),
                    end: now()->endOfDay(),
                )
                ->perHour()
                ->count(),
            
            'last_week' => Trend::model(Post::class)
                ->between(
                    start: now()->subWeek(),
                    end: now(),
                )
                ->perDay()
                ->count(),
            
            'last_month' => Trend::model(Post::class)
                ->between(
                    start: now()->subMonth(),
                    end: now(),
                )
                ->perDay()
                ->count(),
            
            'last_year' => Trend::model(Post::class)
                ->between(
                    start: now()->subYear(),
                    end: now(),
                )
                ->perMonth()
                ->count(),
        };
        
        return [
            'datasets' => [
                [
                    'label' => 'Posts created',
                    'data' => $data->map(fn (TrendValue $value) => $value->aggregate),
                    'backgroundColor' => 'rgb(59, 130, 246)',
                    'borderColor' => 'rgb(59, 130, 246)',
                ],
            ],
            'labels' => $data->map(fn (TrendValue $value) => $value->date),
        ];
    }
    
    protected function getType(): string
    {
        return 'line';
    }
    
    protected function getFilters(): ?array
    {
        return [
            'today' => 'Today',
            'last_week' => 'Last week',
            'last_month' => 'Last month',
            'last_year' => 'Last year',
        ];
    }
}
```

### 5. Relation Managers

```php
// app/Filament/Admin/Resources/PostResource/RelationManagers/CommentsRelationManager.php
<?php

namespace App\Filament\Admin\Resources\PostResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CommentsRelationManager extends RelationManager
{
    protected static string $relationship = 'comments';
    
    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Textarea::make('content')
                    ->required()
                    ->maxLength(65535)
                    ->rows(4),
                
                Forms\Components\Toggle::make('is_approved')
                    ->label('Approved')
                    ->default(false),
                
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload(),
            ]);
    }
    
    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('content')
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Author')
                    ->searchable()
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('content')
                    ->limit(50)
                    ->tooltip(function (Tables\Columns\TextColumn $column): ?string {
                        $state = $column->getState();
                        return strlen($state) <= 50 ? null : $state;
                    }),
                
                Tables\Columns\IconColumn::make('is_approved')
                    ->boolean()
                    ->sortable(),
                
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_approved')
                    ->label('Approval status')
                    ->boolean()
                    ->trueLabel('Only approved comments')
                    ->falseLabel('Only unapproved comments')
                    ->native(false),
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
                
                Tables\Actions\Action::make('approve')
                    ->icon('heroicon-o-check')
                    ->color('success')
                    ->action(fn ($record) => $record->update(['is_approved' => true]))
                    ->visible(fn ($record): bool => !$record->is_approved),
                
                Tables\Actions\Action::make('unapprove')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->action(fn ($record) => $record->update(['is_approved' => false]))
                    ->visible(fn ($record): bool => $record->is_approved),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                    
                    Tables\Actions\BulkAction::make('approve')
                        ->label('Approve selected')
                        ->icon('heroicon-o-check')
                        ->color('success')
                        ->action(fn ($records) => $records->each->update(['is_approved' => true])),
                ]),
            ])
            ->modifyQueryUsing(fn (Builder $query) => $query->with('user'));
    }
}
```

### 6. Custom Fields and Components

```php
// app/Filament/Components/JsonEditor.php
<?php

namespace App\Filament\Components;

use Filament\Forms\Components\Field;

class JsonEditor extends Field
{
    protected string $view = 'filament.forms.components.json-editor';
    
    protected function setUp(): void
    {
        parent::setUp();
        
        $this->afterStateHydrated(function (JsonEditor $component, $state) {
            $component->state(is_string($state) ? json_decode($state, true) : $state);
        });
        
        $this->dehydrateStateUsing(function ($state) {
            return json_encode($state);
        });
    }
}

// app/Filament/Components/ColorPalette.php
<?php

namespace App\Filament\Components;

use Filament\Forms\Components\Field;

class ColorPalette extends Field
{
    protected string $view = 'filament.forms.components.color-palette';
    
    protected array $colors = [];
    
    public function colors(array $colors): static
    {
        $this->colors = $colors;
        
        return $this;
    }
    
    public function getColors(): array
    {
        return $this->colors;
    }
}
```

### 7. Policies and Security

```php
// app/Policies/PostPolicy.php
<?php

namespace App\Policies;

use App\Models\Post;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class PostPolicy
{
    use HandlesAuthorization;
    
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('view posts');
    }
    
    public function view(User $user, Post $post): bool
    {
        return $user->hasPermissionTo('view posts');
    }
    
    public function create(User $user): bool
    {
        return $user->hasPermissionTo('create posts');
    }
    
    public function update(User $user, Post $post): bool
    {
        if ($user->hasPermissionTo('update any posts')) {
            return true;
        }
        
        return $user->hasPermissionTo('update own posts') && $post->user_id === $user->id;
    }
    
    public function delete(User $user, Post $post): bool
    {
        if ($user->hasPermissionTo('delete any posts')) {
            return true;
        }
        
        return $user->hasPermissionTo('delete own posts') && $post->user_id === $user->id;
    }
    
    public function restore(User $user, Post $post): bool
    {
        return $user->hasPermissionTo('restore posts');
    }
    
    public function forceDelete(User $user, Post $post): bool
    {
        return $user->hasPermissionTo('force delete posts');
    }
}
```

### 8. Export and Import

```php
// app/Filament/Exports/PostsExporter.php
<?php

namespace App\Filament\Exports;

use App\Models\Post;
use Filament\Actions\Exports\ExportColumn;
use Filament\Actions\Exports\Exporter;
use Filament\Actions\Exports\Models\Export;

class PostsExporter extends Exporter
{
    protected static ?string $model = Post::class;

    public static function getColumns(): array
    {
        return [
            ExportColumn::make('id')
                ->label('ID'),
            ExportColumn::make('title'),
            ExportColumn::make('slug'),
            ExportColumn::make('status'),
            ExportColumn::make('author.name')
                ->label('Author'),
            ExportColumn::make('published_at')
                ->label('Published Date'),
            ExportColumn::make('created_at')
                ->label('Created Date'),
        ];
    }

    public static function getCompletedNotificationBody(Export $export): string
    {
        $body = 'Your post export has completed and ' . number_format($export->successful_rows) . ' ' . str('row')->plural($export->successful_rows) . ' exported.';

        if ($failedRowsCount = $export->getFailedRowsCount()) {
            $body .= ' ' . number_format($failedRowsCount) . ' ' . str('row')->plural($failedRowsCount) . ' failed to export.';
        }

        return $body;
    }
}

// Usage in Resource
use App\Filament\Exports\PostsExporter;
use Filament\Actions\Exports\Enums\ExportFormat;

// In table() method
->headerActions([
    Tables\Actions\ExportAction::make()
        ->exporter(PostsExporter::class)
        ->formats([
            ExportFormat::Xlsx,
            ExportFormat::Csv,
        ]),
])
```

### 9. Multi-Panel Setup

```php
// app/Providers/Filament/AppPanelProvider.php
<?php

namespace App\Providers\Filament;

use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;

class AppPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->id('app')
            ->path('app')
            ->colors([
                'primary' => Color::Indigo,
            ])
            ->discoverResources(in: app_path('Filament/App/Resources'), for: 'App\\Filament\\App\\Resources')
            ->discoverPages(in: app_path('Filament/App/Pages'), for: 'App\\Filament\\App\\Pages')
            ->pages([
                \App\Filament\App\Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/App/Widgets'), for: 'App\\Filament\\App\\Widgets')
            ->widgets([
                \Filament\Widgets\AccountWidget::class,
            ])
            ->middleware([
                // ... middleware
            ])
            ->authMiddleware([
                // ... auth middleware
            ]);
    }
}
```

### Performance Optimization

1. **Eager Loading**
```php
public static function getEloquentQuery(): Builder
{
    return parent::getEloquentQuery()
        ->with(['author', 'categories', 'tags']);
}
```

2. **Query Optimization**
```php
public static function table(Table $table): Table
{
    return $table
        ->modifyQueryUsing(fn (Builder $query) => 
            $query->select('id', 'title', 'status', 'user_id', 'created_at')
        );
}
```

3. **Caching**
```php
// In Widget
protected function getStats(): array
{
    return Cache::remember('dashboard_stats', 300, function () {
        return [
            // ... expensive calculations
        ];
    });
}
```

### Common Pitfalls to Avoid

1. **Not implementing proper authorization**
2. **Overloading resources with too many relationships**
3. **Not optimizing database queries**
4. **Forgetting to implement soft deletes properly**
5. **Not using form validation effectively**
6. **Ignoring performance in widgets**
7. **Not leveraging Filament's built-in components**
8. **Poor navigation organization**
9. **Not implementing proper error handling**
10. **Missing accessibility considerations**

### Security Best Practices

1. **Always use policies for authorization**
2. **Implement CSRF protection**
3. **Validate file uploads properly**
4. **Use middleware for additional security**
5. **Implement rate limiting**
6. **Sanitize user inputs**
7. **Use HTTPS in production**
8. **Implement proper session management**
9. **Regular security updates**
10. **Monitor for suspicious activities**

### Testing

```php
// tests/Feature/Filament/PostResourceTest.php
<?php

namespace Tests\Feature\Filament;

use App\Filament\Admin\Resources\PostResource;
use App\Models\Post;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class PostResourceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->actingAs(User::factory()->create());
    }

    public function test_can_list_posts()
    {
        $posts = Post::factory()->count(3)->create();

        Livewire::test(PostResource\Pages\ListPosts::class)
            ->assertCanSeeTableRecords($posts);
    }

    public function test_can_create_post()
    {
        $newData = Post::factory()->make();

        Livewire::test(PostResource\Pages\CreatePost::class)
            ->fillForm([
                'title' => $newData->title,
                'content' => $newData->content,
                'status' => $newData->status,
            ])
            ->call('create')
            ->assertHasNoFormErrors();

        $this->assertDatabaseHas(Post::class, [
            'title' => $newData->title,
            'content' => $newData->content,
            'status' => $newData->status,
        ]);
    }

    public function test_can_edit_post()
    {
        $post = Post::factory()->create();
        $newData = Post::factory()->make();

        Livewire::test(PostResource\Pages\EditPost::class, [
            'record' => $post->getRouteKey(),
        ])
            ->fillForm([
                'title' => $newData->title,
                'content' => $newData->content,
            ])
            ->call('save')
            ->assertHasNoFormErrors();

        expect($post->refresh())
            ->title->toBe($newData->title)
            ->content->toBe($newData->content);
    }
}
```

This comprehensive guide covers Laravel Filament v4 best practices with production-ready patterns, performance optimization, security considerations, and testing strategies for building robust admin panels.