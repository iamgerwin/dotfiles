# Drupal Best Practices

Comprehensive guide for building robust, scalable Drupal applications with modern development practices, custom modules, themes, and enterprise-level security.

## 📚 Official Documentation
- [Drupal Documentation](https://www.drupal.org/docs)
- [Drupal API Reference](https://api.drupal.org/)
- [Drupal Coding Standards](https://www.drupal.org/docs/develop/standards)
- [Drupal Security](https://www.drupal.org/security)

## 🏗️ Project Structure

### Modern Drupal Project Structure
```
drupal-project/
├── composer.json              # Dependency management
├── composer.lock              # Lock file
├── web/                       # Web root (public)
│   ├── index.php
│   ├── sites/
│   │   └── default/
│   │       ├── settings.php
│   │       ├── services.yml
│   │       └── files/
│   ├── modules/
│   │   ├── contrib/           # Contributed modules
│   │   └── custom/            # Custom modules
│   │       └── my_module/
│   │           ├── my_module.info.yml
│   │           ├── my_module.module
│   │           ├── src/
│   │           └── templates/
│   ├── themes/
│   │   ├── contrib/           # Contributed themes
│   │   └── custom/            # Custom themes
│   │       └── my_theme/
│   │           ├── my_theme.info.yml
│   │           ├── my_theme.libraries.yml
│   │           ├── templates/
│   │           ├── css/
│   │           └── js/
│   ├── profiles/              # Installation profiles
│   └── libraries/             # External libraries
├── config/                    # Configuration
│   ├── sync/                  # Exported configuration
│   └── staging/               # Staging configuration
├── drush/                     # Drush commands
├── scripts/                   # Custom scripts
├── tests/                     # Automated tests
└── vendor/                    # Composer dependencies
```

## 🎯 Core Drupal Best Practices

### 1. Module Development

```php
<?php
// modules/custom/my_module/my_module.info.yml
name: 'My Custom Module'
type: module
description: 'A comprehensive custom module for business logic.'
core_version_requirement: ^9 || ^10
package: Custom
dependencies:
  - drupal:node
  - drupal:user
  - drupal:field
  - drupal:views
configure: my_module.settings
```

```php
<?php
// modules/custom/my_module/my_module.module

use Drupal\Core\Routing\RouteMatchInterface;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Entity\EntityInterface;
use Drupal\node\NodeInterface;

/**
 * Implements hook_help().
 */
function my_module_help($route_name, RouteMatchInterface $route_match) {
  switch ($route_name) {
    case 'help.page.my_module':
      return '<p>' . t('This module provides custom functionality for the site.') . '</p>';
  }
}

/**
 * Implements hook_theme().
 */
function my_module_theme($existing, $type, $theme, $path) {
  return [
    'my_custom_template' => [
      'variables' => [
        'items' => [],
        'title' => '',
        'attributes' => [],
      ],
      'template' => 'my-custom-template',
    ],
    'my_entity_display' => [
      'variables' => [
        'entity' => NULL,
        'view_mode' => 'full',
      ],
    ],
  ];
}

/**
 * Implements hook_form_alter().
 */
function my_module_form_alter(&$form, FormStateInterface $form_state, $form_id) {
  switch ($form_id) {
    case 'node_article_form':
    case 'node_article_edit_form':
      // Add custom validation
      $form['#validate'][] = 'my_module_article_form_validate';
      
      // Add custom submit handler
      $form['actions']['submit']['#submit'][] = 'my_module_article_form_submit';
      
      // Alter form elements
      $form['field_custom']['widget']['#description'] = t('Enter a custom value here.');
      break;
  }
}

/**
 * Custom validation for article forms.
 */
function my_module_article_form_validate(array &$form, FormStateInterface $form_state) {
  $title = $form_state->getValue('title')[0]['value'];
  
  if (strlen($title) < 5) {
    $form_state->setErrorByName('title', t('Title must be at least 5 characters long.'));
  }
  
  // Check for duplicate titles
  $query = \Drupal::entityQuery('node')
    ->condition('type', 'article')
    ->condition('title', $title)
    ->accessCheck(TRUE);
    
  // Exclude current node if editing
  if ($node_id = $form_state->getFormObject()->getEntity()->id()) {
    $query->condition('nid', $node_id, '<>');
  }
  
  $existing = $query->execute();
  if (!empty($existing)) {
    $form_state->setErrorByName('title', t('An article with this title already exists.'));
  }
}

/**
 * Custom submit handler for article forms.
 */
function my_module_article_form_submit(array &$form, FormStateInterface $form_state) {
  /** @var \Drupal\node\NodeInterface $node */
  $node = $form_state->getFormObject()->getEntity();
  
  // Perform custom actions after node save
  \Drupal::messenger()->addStatus(t('Article "@title" has been processed.', [
    '@title' => $node->getTitle(),
  ]));
  
  // Log the action
  \Drupal::logger('my_module')->info('Article @title was saved by user @user', [
    '@title' => $node->getTitle(),
    '@user' => \Drupal::currentUser()->getAccountName(),
  ]);
}

/**
 * Implements hook_entity_presave().
 */
function my_module_entity_presave(EntityInterface $entity) {
  if ($entity instanceof NodeInterface && $entity->bundle() === 'article') {
    // Auto-generate slug if empty
    if (empty($entity->field_slug->value)) {
      $slug = \Drupal::service('pathauto.alias_cleaner')->cleanString($entity->getTitle());
      $entity->set('field_slug', $slug);
    }
    
    // Set automatic tags based on content
    $content = $entity->body->value;
    $auto_tags = my_module_extract_tags($content);
    if (!empty($auto_tags)) {
      $entity->set('field_auto_tags', $auto_tags);
    }
  }
}

/**
 * Extract tags from content.
 */
function my_module_extract_tags($content) {
  // Simple implementation - in real world, use NLP libraries
  $keywords = ['drupal', 'php', 'web development', 'cms'];
  $found_tags = [];
  
  foreach ($keywords as $keyword) {
    if (stripos($content, $keyword) !== FALSE) {
      $found_tags[] = $keyword;
    }
  }
  
  return implode(', ', $found_tags);
}
```

### 2. Service and Controller Development

```php
<?php
// modules/custom/my_module/src/MyModuleService.php

namespace Drupal\my_module;

use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Psr\Log\LoggerInterface;

/**
 * Service for custom business logic.
 */
class MyModuleService {

  /**
   * The database connection.
   */
  protected Connection $database;

  /**
   * The entity type manager.
   */
  protected EntityTypeManagerInterface $entityTypeManager;

  /**
   * The config factory.
   */
  protected ConfigFactoryInterface $configFactory;

  /**
   * The logger.
   */
  protected LoggerInterface $logger;

  /**
   * The current user.
   */
  protected AccountProxyInterface $currentUser;

  /**
   * Constructs a MyModuleService object.
   */
  public function __construct(
    Connection $database,
    EntityTypeManagerInterface $entity_type_manager,
    ConfigFactoryInterface $config_factory,
    LoggerChannelFactoryInterface $logger_factory,
    AccountProxyInterface $current_user
  ) {
    $this->database = $database;
    $this->entityTypeManager = $entity_type_manager;
    $this->configFactory = $config_factory;
    $this->logger = $logger_factory->get('my_module');
    $this->currentUser = $current_user;
  }

  /**
   * Process user data with validation and security checks.
   */
  public function processUserData(array $data): array {
    // Validate input data
    $this->validateUserData($data);
    
    // Apply business logic
    $processed_data = $this->applyBusinessRules($data);
    
    // Save to database
    $result = $this->saveProcessedData($processed_data);
    
    // Log the operation
    $this->logger->info('User data processed for user @user', [
      '@user' => $this->currentUser->getAccountName(),
    ]);
    
    return $result;
  }

  /**
   * Validate user input data.
   */
  protected function validateUserData(array $data): void {
    $required_fields = ['name', 'email', 'type'];
    
    foreach ($required_fields as $field) {
      if (empty($data[$field])) {
        throw new \InvalidArgumentException("Field {$field} is required");
      }
    }
    
    // Email validation
    if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
      throw new \InvalidArgumentException('Invalid email format');
    }
    
    // Check permissions
    if (!$this->currentUser->hasPermission('process user data')) {
      throw new \AccessDeniedHttpException('Insufficient permissions');
    }
  }

  /**
   * Apply business rules to data.
   */
  protected function applyBusinessRules(array $data): array {
    $config = $this->configFactory->get('my_module.settings');
    
    // Apply transformations based on configuration
    if ($config->get('auto_capitalize')) {
      $data['name'] = ucwords(strtolower($data['name']));
    }
    
    // Add timestamps
    $data['created'] = \Drupal::time()->getRequestTime();
    $data['uid'] = $this->currentUser->id();
    
    return $data;
  }

  /**
   * Save processed data to database.
   */
  protected function saveProcessedData(array $data): array {
    try {
      $query = $this->database->insert('my_module_data')
        ->fields([
          'name' => $data['name'],
          'email' => $data['email'],
          'type' => $data['type'],
          'created' => $data['created'],
          'uid' => $data['uid'],
        ]);
        
      $id = $query->execute();
      
      return [
        'success' => TRUE,
        'id' => $id,
        'message' => 'Data saved successfully',
      ];
    }
    catch (\Exception $e) {
      $this->logger->error('Failed to save data: @message', [
        '@message' => $e->getMessage(),
      ]);
      
      throw new \RuntimeException('Failed to save data');
    }
  }

  /**
   * Get user statistics.
   */
  public function getUserStats(int $uid): array {
    $query = $this->database->select('my_module_data', 'm')
      ->fields('m', ['type'])
      ->condition('uid', $uid)
      ->groupBy('type')
      ->extend('Drupal\Core\Database\Query\SelectExtender')
      ->addExpression('COUNT(*)', 'count');
      
    $results = $query->execute()->fetchAllKeyed();
    
    return [
      'total' => array_sum($results),
      'by_type' => $results,
      'last_activity' => $this->getLastActivity($uid),
    ];
  }

  /**
   * Get last activity for user.
   */
  protected function getLastActivity(int $uid): ?int {
    $query = $this->database->select('my_module_data', 'm')
      ->fields('m', ['created'])
      ->condition('uid', $uid)
      ->orderBy('created', 'DESC')
      ->range(0, 1);
      
    return $query->execute()->fetchField();
  }
}
```

```php
<?php
// modules/custom/my_module/src/Controller/MyModuleController.php

namespace Drupal\my_module\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\DependencyInjection\ContainerInjectionInterface;
use Drupal\my_module\MyModuleService;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

/**
 * Controller for My Module pages.
 */
class MyModuleController extends ControllerBase implements ContainerInjectionInterface {

  /**
   * The my module service.
   */
  protected MyModuleService $myModuleService;

  /**
   * Constructs a MyModuleController object.
   */
  public function __construct(MyModuleService $my_module_service) {
    $this->myModuleService = $my_module_service;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('my_module.service')
    );
  }

  /**
   * Main dashboard page.
   */
  public function dashboard(): array {
    $current_user = $this->currentUser();
    
    // Get user statistics
    $stats = $this->myModuleService->getUserStats($current_user->id());
    
    // Build render array
    $build = [
      '#theme' => 'my_custom_template',
      '#title' => $this->t('Dashboard'),
      '#items' => $this->buildDashboardItems($stats),
      '#attached' => [
        'library' => ['my_module/dashboard'],
        'drupalSettings' => [
          'myModule' => [
            'userId' => $current_user->id(),
            'stats' => $stats,
          ],
        ],
      ],
      '#cache' => [
        'contexts' => ['user'],
        'tags' => ['my_module:dashboard:' . $current_user->id()],
        'max-age' => 300, // 5 minutes
      ],
    ];
    
    return $build;
  }

  /**
   * API endpoint for processing data.
   */
  public function processData(Request $request): JsonResponse {
    try {
      // Get JSON data from request
      $data = json_decode($request->getContent(), TRUE);
      
      if (json_last_error() !== JSON_ERROR_NONE) {
        throw new \InvalidArgumentException('Invalid JSON data');
      }
      
      // Process the data
      $result = $this->myModuleService->processUserData($data);
      
      return new JsonResponse([
        'success' => TRUE,
        'data' => $result,
      ]);
    }
    catch (\InvalidArgumentException $e) {
      return new JsonResponse([
        'success' => FALSE,
        'error' => $e->getMessage(),
      ], 400);
    }
    catch (\Exception $e) {
      $this->getLogger('my_module')->error('API error: @message', [
        '@message' => $e->getMessage(),
      ]);
      
      return new JsonResponse([
        'success' => FALSE,
        'error' => 'Internal server error',
      ], 500);
    }
  }

  /**
   * Build dashboard items array.
   */
  protected function buildDashboardItems(array $stats): array {
    $items = [];
    
    $items[] = [
      'title' => $this->t('Total Records'),
      'value' => $stats['total'],
      'icon' => 'fa-database',
      'class' => 'stat-total',
    ];
    
    foreach ($stats['by_type'] as $type => $count) {
      $items[] = [
        'title' => $this->t('@type Records', ['@type' => ucfirst($type)]),
        'value' => $count,
        'icon' => 'fa-file',
        'class' => 'stat-type',
      ];
    }
    
    if ($stats['last_activity']) {
      $items[] = [
        'title' => $this->t('Last Activity'),
        'value' => $this->dateFormatter()->format($stats['last_activity'], 'short'),
        'icon' => 'fa-clock',
        'class' => 'stat-activity',
      ];
    }
    
    return $items;
  }
}
```

### 3. Configuration Management

```yaml
# modules/custom/my_module/config/install/my_module.settings.yml
api_endpoint: 'https://api.example.com'
cache_lifetime: 3600
enable_logging: true
auto_capitalize: true
max_records_per_user: 1000

# Default field configuration
default_fields:
  - name
  - email
  - type
  - created

# Validation rules
validation_rules:
  name:
    required: true
    min_length: 2
    max_length: 100
  email:
    required: true
    format: email
  type:
    required: true
    allowed_values:
      - personal
      - business
      - other
```

```php
<?php
// modules/custom/my_module/src/Form/MyModuleSettingsForm.php

namespace Drupal\my_module\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

/**
 * Configuration form for My Module settings.
 */
class MyModuleSettingsForm extends ConfigFormBase {

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames(): array {
    return ['my_module.settings'];
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId(): string {
    return 'my_module_settings_form';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('my_module.settings');

    $form['api_settings'] = [
      '#type' => 'details',
      '#title' => $this->t('API Settings'),
      '#open' => TRUE,
    ];

    $form['api_settings']['api_endpoint'] = [
      '#type' => 'url',
      '#title' => $this->t('API Endpoint'),
      '#default_value' => $config->get('api_endpoint'),
      '#description' => $this->t('The base URL for the external API.'),
      '#required' => TRUE,
    ];

    $form['performance'] = [
      '#type' => 'details',
      '#title' => $this->t('Performance Settings'),
      '#open' => TRUE,
    ];

    $form['performance']['cache_lifetime'] = [
      '#type' => 'number',
      '#title' => $this->t('Cache Lifetime (seconds)'),
      '#default_value' => $config->get('cache_lifetime'),
      '#min' => 60,
      '#max' => 86400,
      '#description' => $this->t('How long to cache API responses.'),
    ];

    $form['features'] = [
      '#type' => 'details',
      '#title' => $this->t('Feature Settings'),
      '#open' => TRUE,
    ];

    $form['features']['enable_logging'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Enable Logging'),
      '#default_value' => $config->get('enable_logging'),
      '#description' => $this->t('Log module activities for debugging.'),
    ];

    $form['features']['auto_capitalize'] = [
      '#type' => 'checkbox',
      '#title' => $this->t('Auto Capitalize Names'),
      '#default_value' => $config->get('auto_capitalize'),
      '#description' => $this->t('Automatically capitalize user names.'),
    ];

    $form['limits'] = [
      '#type' => 'details',
      '#title' => $this->t('Limits'),
      '#open' => FALSE,
    ];

    $form['limits']['max_records_per_user'] = [
      '#type' => 'number',
      '#title' => $this->t('Max Records Per User'),
      '#default_value' => $config->get('max_records_per_user'),
      '#min' => 1,
      '#max' => 10000,
      '#description' => $this->t('Maximum number of records a user can create.'),
    ];

    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function validateForm(array &$form, FormStateInterface $form_state): void {
    $api_endpoint = $form_state->getValue('api_endpoint');
    
    // Validate API endpoint
    if (!filter_var($api_endpoint, FILTER_VALIDATE_URL)) {
      $form_state->setErrorByName('api_endpoint', $this->t('Please enter a valid URL.'));
    }

    // Test API connection if endpoint is provided
    if (!empty($api_endpoint)) {
      $response = \Drupal::httpClient()->get($api_endpoint . '/status', [
        'timeout' => 5,
        'http_errors' => FALSE,
      ]);
      
      if ($response->getStatusCode() !== 200) {
        $this->messenger()->addWarning($this->t('Could not connect to API endpoint. Please verify the URL is correct.'));
      }
    }

    parent::validateForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $config = $this->config('my_module.settings');
    
    $config
      ->set('api_endpoint', $form_state->getValue('api_endpoint'))
      ->set('cache_lifetime', $form_state->getValue('cache_lifetime'))
      ->set('enable_logging', $form_state->getValue('enable_logging'))
      ->set('auto_capitalize', $form_state->getValue('auto_capitalize'))
      ->set('max_records_per_user', $form_state->getValue('max_records_per_user'))
      ->save();

    // Clear relevant caches
    \Drupal::cache()->deleteAll();
    
    parent::submitForm($form, $form_state);
  }
}
```

## 🛠️ Theme Development

### 1. Theme Structure and Configuration

```yaml
# themes/custom/my_theme/my_theme.info.yml
name: My Custom Theme
type: theme
description: 'A modern, responsive Drupal theme.'
package: Custom
core_version_requirement: ^9 || ^10
version: '1.0.0'

base theme: false

libraries:
  - my_theme/global-styling
  - my_theme/global-scripts

regions:
  header: Header
  primary_menu: 'Primary menu'
  secondary_menu: 'Secondary menu'
  page_top: 'Page top'
  page_bottom: 'Page bottom'
  highlighted: Highlighted
  featured_top: 'Featured top'
  breadcrumb: Breadcrumb
  content: Content
  sidebar_first: 'Sidebar first'
  sidebar_second: 'Sidebar second'
  featured_bottom_first: 'Featured bottom first'
  featured_bottom_second: 'Featured bottom second'
  featured_bottom_third: 'Featured bottom third'
  footer_first: 'Footer first'
  footer_second: 'Footer second'
  footer_third: 'Footer third'
  footer_fourth: 'Footer fourth'
  footer_fifth: 'Footer fifth'
```

```yaml
# themes/custom/my_theme/my_theme.libraries.yml
global-styling:
  css:
    theme:
      css/style.css: {}
      css/components.css: {}
  dependencies:
    - core/normalize

global-scripts:
  js:
    js/theme.js: {}
  dependencies:
    - core/jquery
    - core/drupal

component-carousel:
  css:
    component:
      css/components/carousel.css: {}
  js:
    js/components/carousel.js: {}
  dependencies:
    - my_theme/global-scripts

admin-styling:
  css:
    theme:
      css/admin.css: {}
```

### 2. Template Development

```php
<?php
// themes/custom/my_theme/templates/page.html.twig

{#
/**
 * @file
 * Default theme implementation to display a single page.
 */
#}
<div class="layout-container">

  <header role="banner" class="site-header">
    {{ page.header }}
    
    {% if page.primary_menu or page.secondary_menu %}
      <nav role="navigation" class="site-navigation" aria-labelledby="system-menu-block--main">
        {{ page.primary_menu }}
        {{ page.secondary_menu }}
      </nav>
    {% endif %}
  </header>

  {{ page.primary_menu }}
  {{ page.secondary_menu }}

  {{ page.breadcrumb }}

  {{ page.highlighted }}

  {{ page.help }}

  <main role="main" class="main-content">
    <a id="main-content" tabindex="-1"></a>{# link is in html.html.twig #}

    <div class="layout-content">
      {{ page.content }}
    </div>{# /.layout-content #}

    {% if page.sidebar_first %}
      <aside class="layout-sidebar-first" role="complementary">
        {{ page.sidebar_first }}
      </aside>
    {% endif %}

    {% if page.sidebar_second %}
      <aside class="layout-sidebar-second" role="complementary">
        {{ page.sidebar_second }}
      </aside>
    {% endif %}

  </main>

  {% if page.footer_first or page.footer_second or page.footer_third or page.footer_fourth %}
    <footer role="contentinfo" class="site-footer">
      <div class="footer-content">
        {{ page.footer_first }}
        {{ page.footer_second }}
        {{ page.footer_third }}
        {{ page.footer_fourth }}
      </div>
    </footer>
  {% endif %}

</div>
```

```php
<?php
// themes/custom/my_theme/templates/node.html.twig

{#
/**
 * @file
 * Theme override to display a node.
 */
#}
{%
  set classes = [
    'node',
    'node--type-' ~ node.bundle|clean_class,
    node.isPromoted() ? 'node--promoted',
    node.isSticky() ? 'node--sticky',
    not node.isPublished() ? 'node--unpublished',
    view_mode ? 'node--view-mode-' ~ view_mode|clean_class,
  ]
%}
<article{{ attributes.addClass(classes) }}>

  {{ title_prefix }}
  {% if label and not page %}
    <h2{{ title_attributes }}>
      <a href="{{ url }}" rel="bookmark">{{ label }}</a>
    </h2>
  {% endif %}
  {{ title_suffix }}

  {% if display_submitted %}
    <footer class="node__meta">
      {{ author_picture }}
      <div{{ author_attributes.addClass('node__submitted') }}>
        {% trans %}Submitted by {{ author_name }} on {{ date }}{% endtrans %}
        {{ metadata }}
      </div>
    </footer>
  {% endif %}

  <div{{ content_attributes.addClass('node__content') }}>
    {{ content }}
  </div>

</article>
```

## ⚠️ Common Pitfalls to Avoid

### 1. Security Issues
```php
// ❌ Bad - Direct database queries without sanitization
$query = \Drupal::database()->query("SELECT * FROM users WHERE name = '{$_GET['name']}'");

// ✅ Good - Using entity queries with proper sanitization
$query = \Drupal::entityQuery('user')
  ->condition('name', \Drupal::request()->query->get('name'))
  ->accessCheck(TRUE);
$users = $query->execute();
```

### 2. Performance Issues
```php
// ❌ Bad - Loading entities in loops
foreach ($node_ids as $nid) {
  $node = \Drupal::entityTypeManager()->getStorage('node')->load($nid);
  // Process node
}

// ✅ Good - Batch loading entities
$nodes = \Drupal::entityTypeManager()->getStorage('node')->loadMultiple($node_ids);
foreach ($nodes as $node) {
  // Process node
}
```

## 📊 Performance Optimization

### 1. Caching Strategies
```php
// Cache API usage
$cache_key = 'my_module:user_stats:' . $user->id();
$cached_data = \Drupal::cache()->get($cache_key);

if ($cached_data === FALSE) {
  $data = $this->generateUserStats($user);
  \Drupal::cache()->set($cache_key, $data, time() + 3600, ['user:' . $user->id()]);
} else {
  $data = $cached_data->data;
}
```

### 2. Database Optimization
```php
// Efficient queries with proper indexing
$query = \Drupal::database()->select('my_module_data', 'm')
  ->fields('m', ['id', 'name', 'created'])
  ->condition('status', 1)
  ->condition('created', strtotime('-1 month'), '>')
  ->orderBy('created', 'DESC')
  ->range(0, 50);
  
$results = $query->execute();
```

## 🔒 Security Best Practices

### 1. Input Validation and Sanitization
```php
// Proper input validation
public function validateInput(array $input): array {
  $errors = [];
  
  // Required field validation
  if (empty($input['title'])) {
    $errors['title'] = $this->t('Title is required.');
  }
  
  // Length validation
  if (!empty($input['title']) && strlen($input['title']) > 255) {
    $errors['title'] = $this->t('Title must be less than 255 characters.');
  }
  
  // Email validation
  if (!empty($input['email']) && !filter_var($input['email'], FILTER_VALIDATE_EMAIL)) {
    $errors['email'] = $this->t('Please enter a valid email address.');
  }
  
  return $errors;
}
```

### 2. Access Control
```php
// Proper permission checking
public function accessCheck(AccountInterface $account): AccessResultInterface {
  // Check specific permission
  if ($account->hasPermission('access my module data')) {
    return AccessResult::allowed();
  }
  
  // Check role-based access
  if ($account->hasRole('administrator')) {
    return AccessResult::allowed();
  }
  
  // Check entity-specific access
  if ($this->entity->getOwnerId() === $account->id()) {
    return AccessResult::allowed();
  }
  
  return AccessResult::forbidden('Insufficient permissions');
}
```

## 📋 Code Review Checklist

- [ ] All database queries use proper sanitization
- [ ] Input validation implemented for all forms
- [ ] Proper access controls in place
- [ ] Caching strategies implemented where appropriate
- [ ] Error handling and logging in place
- [ ] Code follows Drupal coding standards
- [ ] Security best practices followed
- [ ] Performance considerations addressed
- [ ] Configuration management properly implemented
- [ ] Tests written for custom functionality

Remember: Drupal development requires attention to security, performance, and following Drupal's architectural patterns. Always use Drupal APIs appropriately and follow established conventions for maintainable, secure code.