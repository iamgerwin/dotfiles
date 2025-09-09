# WordPress Plugin Development Best Practices

Comprehensive guide for creating professional, monetizable WordPress plugins with modern development practices, security, and scalability.

## 📚 Official Documentation
- [WordPress Plugin Handbook](https://developer.wordpress.org/plugins/)
- [WordPress Plugin API](https://developer.wordpress.org/reference/)
- [WordPress Security Guidelines](https://developer.wordpress.org/plugins/security/)
- [WordPress.org Plugin Guidelines](https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/)

## 🏗️ Plugin Structure

### Professional Plugin Structure
```
my-awesome-plugin/
├── my-awesome-plugin.php       # Main plugin file
├── readme.txt                  # WordPress.org readme
├── LICENSE                     # License file
├── README.md                   # Development readme
├── composer.json               # Dependencies
├── package.json               # Build tools
├── webpack.config.js          # Asset compilation
├── includes/                  # Core functionality
│   ├── class-plugin.php       # Main plugin class
│   ├── class-activator.php    # Activation hooks
│   ├── class-deactivator.php  # Deactivation hooks
│   ├── class-loader.php       # Hook loader
│   └── class-i18n.php         # Internationalization
├── admin/                     # Admin functionality
│   ├── class-admin.php        # Admin core
│   ├── class-meta-boxes.php   # Meta boxes
│   ├── class-settings.php     # Settings API
│   ├── partials/              # Admin templates
│   ├── css/                   # Admin styles
│   └── js/                    # Admin scripts
├── public/                    # Frontend functionality
│   ├── class-public.php       # Public core
│   ├── class-shortcodes.php   # Shortcodes
│   ├── partials/              # Frontend templates
│   ├── css/                   # Frontend styles
│   └── js/                    # Frontend scripts
├── languages/                 # Translation files
├── assets/                    # Source assets
│   ├── src/
│   │   ├── scss/
│   │   └── js/
│   └── dist/                  # Compiled assets
└── tests/                     # Unit tests
    ├── phpunit.xml
    ├── bootstrap.php
    └── test-*.php
```

## 🎯 Plugin Development Best Practices

### 1. Main Plugin File

```php
<?php
/**
 * Plugin Name:       My Awesome Plugin
 * Plugin URI:        https://example.com/my-awesome-plugin
 * Description:       A comprehensive plugin that does awesome things for your WordPress site.
 * Version:           1.0.0
 * Author:            Your Name
 * Author URI:        https://yourwebsite.com
 * License:           GPL v2 or later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       my-awesome-plugin
 * Domain Path:       /languages
 * Requires at least: 5.0
 * Tested up to:      6.4
 * Requires PHP:      7.4
 * Network:           false
 *
 * @package MyAwesomePlugin
 */

// If this file is called directly, abort.
if (!defined('WPINC')) {
    die;
}

/**
 * Plugin constants
 */
define('MY_AWESOME_PLUGIN_VERSION', '1.0.0');
define('MY_AWESOME_PLUGIN_PLUGIN_URL', plugin_dir_url(__FILE__));
define('MY_AWESOME_PLUGIN_PLUGIN_PATH', plugin_dir_path(__FILE__));
define('MY_AWESOME_PLUGIN_PLUGIN_BASENAME', plugin_basename(__FILE__));

/**
 * The code that runs during plugin activation.
 */
function activate_my_awesome_plugin() {
    require_once plugin_dir_path(__FILE__) . 'includes/class-activator.php';
    MyAwesomePlugin_Activator::activate();
}

/**
 * The code that runs during plugin deactivation.
 */
function deactivate_my_awesome_plugin() {
    require_once plugin_dir_path(__FILE__) . 'includes/class-deactivator.php';
    MyAwesomePlugin_Deactivator::deactivate();
}

register_activation_hook(__FILE__, 'activate_my_awesome_plugin');
register_deactivation_hook(__FILE__, 'deactivate_my_awesome_plugin');

/**
 * The core plugin class
 */
require plugin_dir_path(__FILE__) . 'includes/class-plugin.php';

/**
 * Begins execution of the plugin.
 */
function run_my_awesome_plugin() {
    $plugin = new MyAwesomePlugin();
    $plugin->run();
}

run_my_awesome_plugin();
```

### 2. Main Plugin Class

```php
<?php
// includes/class-plugin.php

/**
 * The file that defines the core plugin class
 */
class MyAwesomePlugin {

    /**
     * The loader that's responsible for maintaining and registering all hooks
     */
    protected $loader;

    /**
     * The unique identifier of this plugin
     */
    protected $plugin_name;

    /**
     * The current version of the plugin
     */
    protected $version;

    /**
     * Define the core functionality of the plugin
     */
    public function __construct() {
        if (defined('MY_AWESOME_PLUGIN_VERSION')) {
            $this->version = MY_AWESOME_PLUGIN_VERSION;
        } else {
            $this->version = '1.0.0';
        }
        
        $this->plugin_name = 'my-awesome-plugin';

        $this->load_dependencies();
        $this->set_locale();
        $this->define_admin_hooks();
        $this->define_public_hooks();
    }

    /**
     * Load the required dependencies for this plugin
     */
    private function load_dependencies() {
        require_once plugin_dir_path(dirname(__FILE__)) . 'includes/class-loader.php';
        require_once plugin_dir_path(dirname(__FILE__)) . 'includes/class-i18n.php';
        require_once plugin_dir_path(dirname(__FILE__)) . 'admin/class-admin.php';
        require_once plugin_dir_path(dirname(__FILE__)) . 'public/class-public.php';

        $this->loader = new MyAwesomePlugin_Loader();
    }

    /**
     * Define the locale for this plugin for internationalization
     */
    private function set_locale() {
        $plugin_i18n = new MyAwesomePlugin_i18n();
        $this->loader->add_action('plugins_loaded', $plugin_i18n, 'load_plugin_textdomain');
    }

    /**
     * Register all of the hooks related to the admin area functionality
     */
    private function define_admin_hooks() {
        $plugin_admin = new MyAwesomePlugin_Admin($this->get_plugin_name(), $this->get_version());

        $this->loader->add_action('admin_enqueue_scripts', $plugin_admin, 'enqueue_styles');
        $this->loader->add_action('admin_enqueue_scripts', $plugin_admin, 'enqueue_scripts');
        $this->loader->add_action('admin_menu', $plugin_admin, 'add_plugin_admin_menu');
        $this->loader->add_action('admin_init', $plugin_admin, 'options_init');
        
        // AJAX hooks
        $this->loader->add_action('wp_ajax_my_awesome_action', $plugin_admin, 'handle_ajax_request');
        $this->loader->add_action('wp_ajax_nopriv_my_awesome_action', $plugin_admin, 'handle_ajax_request');
    }

    /**
     * Register all of the hooks related to the public-facing functionality
     */
    private function define_public_hooks() {
        $plugin_public = new MyAwesomePlugin_Public($this->get_plugin_name(), $this->get_version());

        $this->loader->add_action('wp_enqueue_scripts', $plugin_public, 'enqueue_styles');
        $this->loader->add_action('wp_enqueue_scripts', $plugin_public, 'enqueue_scripts');
        $this->loader->add_action('init', $plugin_public, 'init');
        
        // Shortcodes
        $this->loader->add_action('init', $plugin_public, 'register_shortcodes');
        
        // Custom post types and taxonomies
        $this->loader->add_action('init', $plugin_public, 'register_post_types');
        $this->loader->add_action('init', $plugin_public, 'register_taxonomies');
    }

    /**
     * Run the loader to execute all of the hooks with WordPress
     */
    public function run() {
        $this->loader->run();
    }

    /**
     * The name of the plugin used to uniquely identify it
     */
    public function get_plugin_name() {
        return $this->plugin_name;
    }

    /**
     * The reference to the class that orchestrates the hooks
     */
    public function get_loader() {
        return $this->loader;
    }

    /**
     * Retrieve the version number of the plugin
     */
    public function get_version() {
        return $this->version;
    }
}
```

### 3. Admin Class with Settings API

```php
<?php
// admin/class-admin.php

class MyAwesomePlugin_Admin {

    private $plugin_name;
    private $version;

    public function __construct($plugin_name, $version) {
        $this->plugin_name = $plugin_name;
        $this->version = $version;
    }

    /**
     * Register the stylesheets for the admin area
     */
    public function enqueue_styles() {
        wp_enqueue_style(
            $this->plugin_name,
            plugin_dir_url(__FILE__) . 'css/admin.css',
            [],
            $this->version,
            'all'
        );
    }

    /**
     * Register the JavaScript for the admin area
     */
    public function enqueue_scripts() {
        wp_enqueue_script(
            $this->plugin_name,
            plugin_dir_url(__FILE__) . 'js/admin.js',
            ['jquery'],
            $this->version,
            false
        );

        wp_localize_script($this->plugin_name, 'ajax_object', [
            'ajax_url' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('my_awesome_nonce'),
        ]);
    }

    /**
     * Add an options page under the Settings submenu
     */
    public function add_plugin_admin_menu() {
        add_options_page(
            __('My Awesome Plugin Settings', 'my-awesome-plugin'),
            __('My Awesome Plugin', 'my-awesome-plugin'),
            'manage_options',
            $this->plugin_name,
            [$this, 'display_plugin_setup_page']
        );
    }

    /**
     * Render the settings page for this plugin
     */
    public function display_plugin_setup_page() {
        include_once 'partials/admin-display.php';
    }

    /**
     * Initialize plugin settings
     */
    public function options_init() {
        // Register settings
        register_setting(
            'my_awesome_plugin_options',
            'my_awesome_plugin_options',
            [$this, 'validate_options']
        );

        // Add settings section
        add_settings_section(
            'my_awesome_plugin_main',
            __('Main Settings', 'my-awesome-plugin'),
            [$this, 'main_section_callback'],
            'my_awesome_plugin'
        );

        // Add settings fields
        add_settings_field(
            'api_key',
            __('API Key', 'my-awesome-plugin'),
            [$this, 'api_key_callback'],
            'my_awesome_plugin',
            'my_awesome_plugin_main'
        );

        add_settings_field(
            'enable_feature',
            __('Enable Feature', 'my-awesome-plugin'),
            [$this, 'enable_feature_callback'],
            'my_awesome_plugin',
            'my_awesome_plugin_main'
        );

        add_settings_field(
            'color_scheme',
            __('Color Scheme', 'my-awesome-plugin'),
            [$this, 'color_scheme_callback'],
            'my_awesome_plugin',
            'my_awesome_plugin_main'
        );
    }

    /**
     * Main section callback
     */
    public function main_section_callback() {
        echo '<p>' . esc_html__('Configure the main settings for the plugin.', 'my-awesome-plugin') . '</p>';
    }

    /**
     * API Key field callback
     */
    public function api_key_callback() {
        $options = get_option('my_awesome_plugin_options');
        $api_key = isset($options['api_key']) ? $options['api_key'] : '';
        
        echo '<input type="password" id="api_key" name="my_awesome_plugin_options[api_key]" value="' . esc_attr($api_key) . '" class="regular-text" />';
        echo '<p class="description">' . esc_html__('Enter your API key here.', 'my-awesome-plugin') . '</p>';
    }

    /**
     * Enable feature field callback
     */
    public function enable_feature_callback() {
        $options = get_option('my_awesome_plugin_options');
        $enabled = isset($options['enable_feature']) ? $options['enable_feature'] : 0;
        
        echo '<input type="checkbox" id="enable_feature" name="my_awesome_plugin_options[enable_feature]" value="1" ' . checked(1, $enabled, false) . ' />';
        echo '<label for="enable_feature">' . esc_html__('Enable this awesome feature', 'my-awesome-plugin') . '</label>';
    }

    /**
     * Color scheme field callback
     */
    public function color_scheme_callback() {
        $options = get_option('my_awesome_plugin_options');
        $color_scheme = isset($options['color_scheme']) ? $options['color_scheme'] : 'default';
        
        $schemes = [
            'default' => __('Default', 'my-awesome-plugin'),
            'dark' => __('Dark', 'my-awesome-plugin'),
            'light' => __('Light', 'my-awesome-plugin'),
            'colorful' => __('Colorful', 'my-awesome-plugin'),
        ];
        
        echo '<select id="color_scheme" name="my_awesome_plugin_options[color_scheme]">';
        foreach ($schemes as $value => $label) {
            echo '<option value="' . esc_attr($value) . '" ' . selected($color_scheme, $value, false) . '>' . esc_html($label) . '</option>';
        }
        echo '</select>';
    }

    /**
     * Validate options
     */
    public function validate_options($input) {
        $validated = [];

        // Validate API key
        if (isset($input['api_key'])) {
            $api_key = sanitize_text_field($input['api_key']);
            if (strlen($api_key) >= 20) {
                $validated['api_key'] = $api_key;
            } else {
                add_settings_error(
                    'my_awesome_plugin_options',
                    'api_key_error',
                    __('API Key must be at least 20 characters long.', 'my-awesome-plugin'),
                    'error'
                );
            }
        }

        // Validate checkbox
        $validated['enable_feature'] = isset($input['enable_feature']) ? 1 : 0;

        // Validate color scheme
        $allowed_schemes = ['default', 'dark', 'light', 'colorful'];
        if (isset($input['color_scheme']) && in_array($input['color_scheme'], $allowed_schemes)) {
            $validated['color_scheme'] = $input['color_scheme'];
        } else {
            $validated['color_scheme'] = 'default';
        }

        return $validated;
    }

    /**
     * Handle AJAX requests
     */
    public function handle_ajax_request() {
        // Verify nonce
        if (!wp_verify_nonce($_POST['nonce'], 'my_awesome_nonce')) {
            wp_die(__('Security check failed', 'my-awesome-plugin'));
        }

        // Check user permissions
        if (!current_user_can('manage_options')) {
            wp_die(__('Insufficient permissions', 'my-awesome-plugin'));
        }

        $action = sanitize_text_field($_POST['custom_action']);

        switch ($action) {
            case 'test_api':
                $this->test_api_connection();
                break;
            case 'reset_settings':
                $this->reset_plugin_settings();
                break;
            default:
                wp_send_json_error(['message' => __('Invalid action', 'my-awesome-plugin')]);
                break;
        }
    }

    /**
     * Test API connection
     */
    private function test_api_connection() {
        $options = get_option('my_awesome_plugin_options');
        $api_key = isset($options['api_key']) ? $options['api_key'] : '';

        if (empty($api_key)) {
            wp_send_json_error(['message' => __('API key is required', 'my-awesome-plugin')]);
        }

        // Simulate API test (replace with actual API call)
        $response = wp_remote_get('https://api.example.com/test', [
            'headers' => [
                'Authorization' => 'Bearer ' . $api_key,
            ],
            'timeout' => 15,
        ]);

        if (is_wp_error($response)) {
            wp_send_json_error(['message' => $response->get_error_message()]);
        }

        $status_code = wp_remote_retrieve_response_code($response);
        if ($status_code === 200) {
            wp_send_json_success(['message' => __('API connection successful!', 'my-awesome-plugin')]);
        } else {
            wp_send_json_error(['message' => __('API connection failed', 'my-awesome-plugin')]);
        }
    }

    /**
     * Reset plugin settings
     */
    private function reset_plugin_settings() {
        delete_option('my_awesome_plugin_options');
        wp_send_json_success(['message' => __('Settings reset successfully!', 'my-awesome-plugin')]);
    }
}
```

### 4. Frontend/Public Class

```php
<?php
// public/class-public.php

class MyAwesomePlugin_Public {

    private $plugin_name;
    private $version;

    public function __construct($plugin_name, $version) {
        $this->plugin_name = $plugin_name;
        $this->version = $version;
    }

    /**
     * Register the stylesheets for the public-facing side
     */
    public function enqueue_styles() {
        wp_enqueue_style(
            $this->plugin_name,
            plugin_dir_url(__FILE__) . 'css/public.css',
            [],
            $this->version,
            'all'
        );
    }

    /**
     * Register the JavaScript for the public-facing side
     */
    public function enqueue_scripts() {
        wp_enqueue_script(
            $this->plugin_name,
            plugin_dir_url(__FILE__) . 'js/public.js',
            ['jquery'],
            $this->version,
            false
        );

        wp_localize_script($this->plugin_name, 'my_awesome_public', [
            'ajax_url' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('my_awesome_public_nonce'),
        ]);
    }

    /**
     * Initialize plugin functionality
     */
    public function init() {
        // Add any initialization code here
        $this->register_custom_endpoints();
    }

    /**
     * Register shortcodes
     */
    public function register_shortcodes() {
        add_shortcode('my_awesome_widget', [$this, 'widget_shortcode']);
        add_shortcode('my_awesome_form', [$this, 'form_shortcode']);
    }

    /**
     * Widget shortcode
     */
    public function widget_shortcode($atts) {
        $atts = shortcode_atts([
            'title' => __('Awesome Widget', 'my-awesome-plugin'),
            'type' => 'default',
            'count' => 5,
            'show_images' => 'yes',
        ], $atts, 'my_awesome_widget');

        ob_start();
        include plugin_dir_path(__FILE__) . 'partials/widget-display.php';
        return ob_get_clean();
    }

    /**
     * Form shortcode
     */
    public function form_shortcode($atts) {
        $atts = shortcode_atts([
            'id' => '',
            'class' => 'my-awesome-form',
            'action' => 'submit_form',
        ], $atts, 'my_awesome_form');

        ob_start();
        include plugin_dir_path(__FILE__) . 'partials/form-display.php';
        return ob_get_clean();
    }

    /**
     * Register custom post types
     */
    public function register_post_types() {
        $labels = [
            'name' => _x('Awesome Items', 'Post Type General Name', 'my-awesome-plugin'),
            'singular_name' => _x('Awesome Item', 'Post Type Singular Name', 'my-awesome-plugin'),
            'menu_name' => __('Awesome Items', 'my-awesome-plugin'),
            'name_admin_bar' => __('Awesome Item', 'my-awesome-plugin'),
            'add_new' => __('Add New', 'my-awesome-plugin'),
            'add_new_item' => __('Add New Awesome Item', 'my-awesome-plugin'),
            'new_item' => __('New Awesome Item', 'my-awesome-plugin'),
            'edit_item' => __('Edit Awesome Item', 'my-awesome-plugin'),
            'update_item' => __('Update Awesome Item', 'my-awesome-plugin'),
            'view_item' => __('View Awesome Item', 'my-awesome-plugin'),
            'view_items' => __('View Awesome Items', 'my-awesome-plugin'),
            'search_items' => __('Search Awesome Items', 'my-awesome-plugin'),
            'not_found' => __('Not found', 'my-awesome-plugin'),
            'not_found_in_trash' => __('Not found in Trash', 'my-awesome-plugin'),
        ];

        $args = [
            'label' => __('Awesome Item', 'my-awesome-plugin'),
            'description' => __('Custom post type for awesome items', 'my-awesome-plugin'),
            'labels' => $labels,
            'supports' => ['title', 'editor', 'thumbnail', 'excerpt', 'custom-fields'],
            'taxonomies' => ['awesome_category'],
            'hierarchical' => false,
            'public' => true,
            'show_ui' => true,
            'show_in_menu' => true,
            'menu_position' => 20,
            'menu_icon' => 'dashicons-star-filled',
            'show_in_admin_bar' => true,
            'show_in_nav_menus' => true,
            'can_export' => true,
            'has_archive' => true,
            'exclude_from_search' => false,
            'publicly_queryable' => true,
            'capability_type' => 'post',
            'show_in_rest' => true,
        ];

        register_post_type('awesome_item', $args);
    }

    /**
     * Register custom taxonomies
     */
    public function register_taxonomies() {
        $labels = [
            'name' => _x('Awesome Categories', 'Taxonomy General Name', 'my-awesome-plugin'),
            'singular_name' => _x('Awesome Category', 'Taxonomy Singular Name', 'my-awesome-plugin'),
            'menu_name' => __('Categories', 'my-awesome-plugin'),
            'all_items' => __('All Categories', 'my-awesome-plugin'),
            'parent_item' => __('Parent Category', 'my-awesome-plugin'),
            'parent_item_colon' => __('Parent Category:', 'my-awesome-plugin'),
            'new_item_name' => __('New Category Name', 'my-awesome-plugin'),
            'add_new_item' => __('Add New Category', 'my-awesome-plugin'),
            'edit_item' => __('Edit Category', 'my-awesome-plugin'),
            'update_item' => __('Update Category', 'my-awesome-plugin'),
            'view_item' => __('View Category', 'my-awesome-plugin'),
            'separate_items_with_commas' => __('Separate categories with commas', 'my-awesome-plugin'),
            'add_or_remove_items' => __('Add or remove categories', 'my-awesome-plugin'),
            'choose_from_most_used' => __('Choose from the most used', 'my-awesome-plugin'),
            'popular_items' => __('Popular Categories', 'my-awesome-plugin'),
            'search_items' => __('Search Categories', 'my-awesome-plugin'),
            'not_found' => __('Not Found', 'my-awesome-plugin'),
            'no_terms' => __('No categories', 'my-awesome-plugin'),
        ];

        $args = [
            'labels' => $labels,
            'hierarchical' => true,
            'public' => true,
            'show_ui' => true,
            'show_admin_column' => true,
            'show_in_nav_menus' => true,
            'show_tagcloud' => true,
            'show_in_rest' => true,
        ];

        register_taxonomy('awesome_category', ['awesome_item'], $args);
    }

    /**
     * Register custom REST API endpoints
     */
    public function register_custom_endpoints() {
        add_action('rest_api_init', function () {
            register_rest_route('my-awesome/v1', '/items', [
                'methods' => 'GET',
                'callback' => [$this, 'get_awesome_items'],
                'permission_callback' => '__return_true',
            ]);

            register_rest_route('my-awesome/v1', '/items/(?P<id>\d+)', [
                'methods' => 'GET',
                'callback' => [$this, 'get_awesome_item'],
                'permission_callback' => '__return_true',
            ]);
        });
    }

    /**
     * REST API callback for getting items
     */
    public function get_awesome_items($request) {
        $posts = get_posts([
            'post_type' => 'awesome_item',
            'numberposts' => $request->get_param('per_page') ?: 10,
            'post_status' => 'publish',
        ]);

        $data = [];
        foreach ($posts as $post) {
            $data[] = [
                'id' => $post->ID,
                'title' => get_the_title($post->ID),
                'content' => get_the_content(null, false, $post->ID),
                'featured_image' => get_the_post_thumbnail_url($post->ID, 'full'),
                'categories' => wp_get_post_terms($post->ID, 'awesome_category', ['fields' => 'names']),
            ];
        }

        return rest_ensure_response($data);
    }

    /**
     * REST API callback for getting single item
     */
    public function get_awesome_item($request) {
        $id = $request->get_param('id');
        $post = get_post($id);

        if (!$post || $post->post_type !== 'awesome_item') {
            return new WP_Error('not_found', __('Item not found', 'my-awesome-plugin'), ['status' => 404]);
        }

        $data = [
            'id' => $post->ID,
            'title' => get_the_title($post->ID),
            'content' => get_the_content(null, false, $post->ID),
            'featured_image' => get_the_post_thumbnail_url($post->ID, 'full'),
            'categories' => wp_get_post_terms($post->ID, 'awesome_category', ['fields' => 'names']),
            'meta' => get_post_meta($post->ID),
        ];

        return rest_ensure_response($data);
    }
}
```

## 💰 Monetization Strategies

### 1. Freemium Model Structure

```php
<?php
// includes/class-license-manager.php

class MyAwesomePlugin_License_Manager {
    
    private $license_server_url = 'https://your-license-server.com/api/';
    
    public function __construct() {
        add_action('admin_init', [$this, 'check_license_status']);
        add_action('admin_notices', [$this, 'show_license_notices']);
    }
    
    /**
     * Check if plugin has valid license
     */
    public function has_valid_license() {
        $license_key = get_option('my_awesome_plugin_license_key');
        $license_status = get_option('my_awesome_plugin_license_status');
        
        return !empty($license_key) && $license_status === 'valid';
    }
    
    /**
     * Check if feature is available in current plan
     */
    public function is_feature_available($feature) {
        if (!$this->has_valid_license()) {
            return false;
        }
        
        $license_plan = get_option('my_awesome_plugin_license_plan', 'free');
        
        $feature_matrix = [
            'free' => ['basic_widget', 'simple_form'],
            'pro' => ['basic_widget', 'simple_form', 'advanced_widget', 'custom_styling'],
            'premium' => ['basic_widget', 'simple_form', 'advanced_widget', 'custom_styling', 'api_integration', 'white_label'],
        ];
        
        return in_array($feature, $feature_matrix[$license_plan] ?? []);
    }
    
    /**
     * Validate license key
     */
    public function validate_license($license_key) {
        $response = wp_remote_post($this->license_server_url . 'validate', [
            'body' => [
                'license_key' => $license_key,
                'site_url' => home_url(),
                'plugin_version' => MY_AWESOME_PLUGIN_VERSION,
            ],
            'timeout' => 15,
        ]);
        
        if (is_wp_error($response)) {
            return [
                'valid' => false,
                'error' => $response->get_error_message(),
            ];
        }
        
        $body = json_decode(wp_remote_retrieve_body($response), true);
        
        if ($body['valid']) {
            update_option('my_awesome_plugin_license_key', $license_key);
            update_option('my_awesome_plugin_license_status', 'valid');
            update_option('my_awesome_plugin_license_plan', $body['plan']);
            update_option('my_awesome_plugin_license_expires', $body['expires']);
        }
        
        return $body;
    }
    
    /**
     * Deactivate license
     */
    public function deactivate_license($license_key) {
        wp_remote_post($this->license_server_url . 'deactivate', [
            'body' => [
                'license_key' => $license_key,
                'site_url' => home_url(),
            ],
        ]);
        
        delete_option('my_awesome_plugin_license_key');
        delete_option('my_awesome_plugin_license_status');
        delete_option('my_awesome_plugin_license_plan');
        delete_option('my_awesome_plugin_license_expires');
    }
}

// Feature gating example
function my_awesome_plugin_pro_feature() {
    $license_manager = new MyAwesomePlugin_License_Manager();
    
    if (!$license_manager->is_feature_available('advanced_widget')) {
        echo '<div class="notice notice-info">';
        echo '<p>' . sprintf(
            __('This feature requires a Pro license. <a href="%s" target="_blank">Upgrade now!</a>', 'my-awesome-plugin'),
            'https://your-website.com/pricing'
        ) . '</p>';
        echo '</div>';
        return;
    }
    
    // Show pro feature
    include 'partials/pro-feature.php';
}
```

### 2. Update System for Premium Plugins

```php
<?php
// includes/class-updater.php

class MyAwesomePlugin_Updater {
    
    private $plugin_file;
    private $version;
    private $slug;
    private $update_server;
    
    public function __construct($plugin_file, $version, $slug, $update_server) {
        $this->plugin_file = $plugin_file;
        $this->version = $version;
        $this->slug = $slug;
        $this->update_server = $update_server;
        
        add_filter('pre_set_site_transient_update_plugins', [$this, 'check_for_updates']);
        add_filter('plugins_api', [$this, 'plugin_info'], 10, 3);
    }
    
    /**
     * Check for plugin updates
     */
    public function check_for_updates($transient) {
        if (empty($transient->checked)) {
            return $transient;
        }
        
        $remote_version = $this->get_remote_version();
        
        if (version_compare($this->version, $remote_version, '<')) {
            $transient->response[$this->plugin_file] = (object) [
                'slug' => $this->slug,
                'new_version' => $remote_version,
                'url' => 'https://your-plugin-website.com',
                'package' => $this->get_download_url(),
            ];
        }
        
        return $transient;
    }
    
    /**
     * Get remote version
     */
    private function get_remote_version() {
        $license_key = get_option('my_awesome_plugin_license_key');
        
        $response = wp_remote_get($this->update_server . '?action=version&license=' . $license_key);
        
        if (!is_wp_error($response)) {
            $body = wp_remote_retrieve_body($response);
            $data = json_decode($body, true);
            return $data['version'] ?? $this->version;
        }
        
        return $this->version;
    }
    
    /**
     * Get download URL for licensed users
     */
    private function get_download_url() {
        $license_key = get_option('my_awesome_plugin_license_key');
        return $this->update_server . '?action=download&license=' . $license_key;
    }
    
    /**
     * Plugin information for updates
     */
    public function plugin_info($response, $action, $args) {
        if ($action !== 'plugin_information' || $args->slug !== $this->slug) {
            return $response;
        }
        
        $remote_data = $this->get_remote_info();
        
        return (object) $remote_data;
    }
    
    /**
     * Get remote plugin information
     */
    private function get_remote_info() {
        $license_key = get_option('my_awesome_plugin_license_key');
        
        $response = wp_remote_get($this->update_server . '?action=info&license=' . $license_key);
        
        if (!is_wp_error($response)) {
            $body = wp_remote_retrieve_body($response);
            return json_decode($body, true);
        }
        
        return [];
    }
}
```

## 🛠️ Advanced Features

### 1. Custom Database Tables

```php
<?php
// includes/class-database.php

class MyAwesomePlugin_Database {
    
    private $table_name;
    
    public function __construct() {
        global $wpdb;
        $this->table_name = $wpdb->prefix . 'awesome_plugin_data';
    }
    
    /**
     * Create custom table
     */
    public function create_table() {
        global $wpdb;
        
        $charset_collate = $wpdb->get_charset_collate();
        
        $sql = "CREATE TABLE {$this->table_name} (
            id bigint(20) NOT NULL AUTO_INCREMENT,
            user_id bigint(20) NOT NULL,
            item_data longtext NOT NULL,
            item_type varchar(50) NOT NULL,
            status varchar(20) DEFAULT 'active',
            created_at datetime DEFAULT CURRENT_TIMESTAMP,
            updated_at datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            KEY user_id (user_id),
            KEY item_type (item_type),
            KEY status (status)
        ) $charset_collate;";
        
        require_once(ABSPATH . 'wp-admin/includes/upgrade.php');
        dbDelta($sql);
    }
    
    /**
     * Insert data
     */
    public function insert($data) {
        global $wpdb;
        
        $result = $wpdb->insert(
            $this->table_name,
            [
                'user_id' => $data['user_id'],
                'item_data' => json_encode($data['item_data']),
                'item_type' => $data['item_type'],
                'status' => $data['status'] ?? 'active',
            ],
            ['%d', '%s', '%s', '%s']
        );
        
        return $result !== false ? $wpdb->insert_id : false;
    }
    
    /**
     * Get data by ID
     */
    public function get($id) {
        global $wpdb;
        
        $result = $wpdb->get_row(
            $wpdb->prepare("SELECT * FROM {$this->table_name} WHERE id = %d", $id),
            ARRAY_A
        );
        
        if ($result) {
            $result['item_data'] = json_decode($result['item_data'], true);
        }
        
        return $result;
    }
    
    /**
     * Update data
     */
    public function update($id, $data) {
        global $wpdb;
        
        return $wpdb->update(
            $this->table_name,
            [
                'item_data' => json_encode($data['item_data']),
                'item_type' => $data['item_type'],
                'status' => $data['status'],
            ],
            ['id' => $id],
            ['%s', '%s', '%s'],
            ['%d']
        );
    }
    
    /**
     * Delete data
     */
    public function delete($id) {
        global $wpdb;
        
        return $wpdb->delete(
            $this->table_name,
            ['id' => $id],
            ['%d']
        );
    }
    
    /**
     * Get data with pagination
     */
    public function get_paginated($page = 1, $per_page = 20, $filters = []) {
        global $wpdb;
        
        $offset = ($page - 1) * $per_page;
        $where_clause = "WHERE 1=1";
        $where_values = [];
        
        if (!empty($filters['user_id'])) {
            $where_clause .= " AND user_id = %d";
            $where_values[] = $filters['user_id'];
        }
        
        if (!empty($filters['item_type'])) {
            $where_clause .= " AND item_type = %s";
            $where_values[] = $filters['item_type'];
        }
        
        if (!empty($filters['status'])) {
            $where_clause .= " AND status = %s";
            $where_values[] = $filters['status'];
        }
        
        // Get total count
        $count_sql = "SELECT COUNT(*) FROM {$this->table_name} {$where_clause}";
        $total_items = $wpdb->get_var($wpdb->prepare($count_sql, $where_values));
        
        // Get paginated results
        $sql = "SELECT * FROM {$this->table_name} {$where_clause} ORDER BY created_at DESC LIMIT %d OFFSET %d";
        $where_values[] = $per_page;
        $where_values[] = $offset;
        
        $results = $wpdb->get_results($wpdb->prepare($sql, $where_values), ARRAY_A);
        
        // Decode JSON data
        foreach ($results as &$result) {
            $result['item_data'] = json_decode($result['item_data'], true);
        }
        
        return [
            'items' => $results,
            'total_items' => $total_items,
            'total_pages' => ceil($total_items / $per_page),
            'current_page' => $page,
            'per_page' => $per_page,
        ];
    }
}
```

## ⚠️ Common Pitfalls to Avoid

### 1. Security Issues
```php
// ❌ Bad - No input validation
function handle_form_data() {
    $user_data = $_POST['user_data'];
    update_option('my_plugin_data', $user_data);
}

// ✅ Good - Proper validation and sanitization
function handle_form_data() {
    if (!current_user_can('manage_options')) {
        wp_die(__('Insufficient permissions'));
    }
    
    if (!wp_verify_nonce($_POST['nonce'], 'my_plugin_nonce')) {
        wp_die(__('Security check failed'));
    }
    
    $user_data = sanitize_textarea_field($_POST['user_data']);
    update_option('my_plugin_data', $user_data);
}
```

### 2. Plugin Conflicts
```php
// ❌ Bad - Generic function names
function init() {
    // Plugin initialization
}

// ✅ Good - Prefixed function names
function my_awesome_plugin_init() {
    // Plugin initialization
}

// Even better - Use classes
class MyAwesomePlugin_Core {
    public function init() {
        // Plugin initialization
    }
}
```

## 📊 Performance & Optimization

### 1. Efficient Database Queries
```php
// Cache expensive queries
function get_plugin_stats() {
    $cache_key = 'my_awesome_plugin_stats';
    $stats = wp_cache_get($cache_key);
    
    if (false === $stats) {
        global $wpdb;
        $stats = $wpdb->get_results("SELECT status, COUNT(*) as count FROM {$wpdb->prefix}awesome_plugin_data GROUP BY status");
        wp_cache_set($cache_key, $stats, '', HOUR_IN_SECONDS);
    }
    
    return $stats;
}
```

### 2. Asset Optimization
```php
// Conditional loading
public function enqueue_scripts() {
    if (is_admin() && get_current_screen()->id === 'settings_page_my-awesome-plugin') {
        wp_enqueue_script('my-plugin-admin');
    }
    
    if (!is_admin() && (is_single() || is_page())) {
        wp_enqueue_script('my-plugin-public');
    }
}
```

## 📋 Code Review Checklist

- [ ] All user inputs are sanitized and validated
- [ ] Nonce verification implemented for forms
- [ ] Proper capability checks for admin functions
- [ ] Translation functions used for all strings
- [ ] Database queries are optimized
- [ ] Assets are conditionally loaded
- [ ] License validation system implemented (if premium)
- [ ] Update system configured (if premium)
- [ ] Error handling in place throughout
- [ ] Code follows WordPress coding standards

Remember: Successful WordPress plugins focus on solving specific problems, provide excellent user experience, and maintain high security standards. Consider the monetization strategy from the beginning and build features that provide clear value to justify premium pricing.