# WordPress Theme Development Best Practices

Comprehensive guide for creating professional, monetizable WordPress themes with modern development practices, performance optimization, and commercial viability.

## 📚 Official Documentation
- [WordPress Theme Handbook](https://developer.wordpress.org/themes/)
- [Theme Review Guidelines](https://make.wordpress.org/themes/handbook/review/)
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [Theme Unit Test](https://codex.wordpress.org/Theme_Unit_Test)

## 🏗️ Theme Structure

### Professional Theme Structure
```
my-awesome-theme/
├── style.css                  # Main stylesheet with theme header
├── index.php                  # Main template file
├── functions.php              # Theme functions and features
├── screenshot.png             # Theme screenshot (1200x900px)
├── readme.txt                 # Theme documentation
├── templates/                 # Block theme templates (WP 5.9+)
│   ├── index.html
│   ├── single.html
│   └── page.html
├── parts/                     # Template parts
│   ├── header.php
│   ├── footer.php
│   ├── sidebar.php
│   └── navigation.php
├── template-parts/            # Reusable template parts
│   ├── content.php
│   ├── content-single.php
│   ├── content-page.php
│   └── content-none.php
├── page-templates/            # Custom page templates
│   ├── page-full-width.php
│   └── page-landing.php
├── inc/                       # Theme includes
│   ├── customizer.php         # Customizer settings
│   ├── template-functions.php # Template helper functions
│   ├── template-tags.php      # Template tags
│   ├── custom-header.php      # Custom header support
│   ├── jetpack.php           # Jetpack compatibility
│   └── woocommerce.php       # WooCommerce compatibility
├── assets/                    # Source assets
│   ├── scss/
│   │   ├── style.scss
│   │   ├── editor-style.scss
│   │   └── components/
│   ├── js/
│   │   ├── theme.js
│   │   └── customizer.js
│   └── images/
├── dist/                      # Compiled assets
│   ├── css/
│   └── js/
├── languages/                 # Translation files
├── layouts/                   # CSS Grid layouts
└── package.json              # Build configuration
```

## 🎯 Theme Development Best Practices

### 1. Theme Header and Setup

```php
<?php
/**
 * Theme Name: My Awesome Theme
 * Description: A modern, responsive WordPress theme perfect for businesses and portfolios.
 * Author: Your Name
 * Author URI: https://yourwebsite.com
 * Version: 1.0.0
 * License: GPL v2 or later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: my-awesome-theme
 * Domain Path: /languages
 * Tags: blog, business, portfolio, responsive, custom-colors, custom-menu, featured-images, threaded-comments, translation-ready
 * Requires at least: 5.0
 * Tested up to: 6.4
 * Requires PHP: 7.4
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Theme version
define('MY_AWESOME_THEME_VERSION', '1.0.0');

// Theme setup
if (!function_exists('my_awesome_theme_setup')) {
    function my_awesome_theme_setup() {
        // Make theme available for translation
        load_theme_textdomain('my-awesome-theme', get_template_directory() . '/languages');

        // Add default posts and comments RSS feed links to head
        add_theme_support('automatic-feed-links');

        // Let WordPress manage the document title
        add_theme_support('title-tag');

        // Enable support for Post Thumbnails
        add_theme_support('post-thumbnails');

        // Add custom image sizes
        add_image_size('hero-image', 1920, 1080, true);
        add_image_size('featured-large', 800, 600, true);
        add_image_size('featured-medium', 400, 300, true);
        add_image_size('featured-small', 200, 150, true);

        // Register navigation menus
        register_nav_menus([
            'primary' => esc_html__('Primary Menu', 'my-awesome-theme'),
            'footer' => esc_html__('Footer Menu', 'my-awesome-theme'),
            'social' => esc_html__('Social Links Menu', 'my-awesome-theme'),
        ]);

        // Switch default core markup to output valid HTML5
        add_theme_support('html5', [
            'search-form',
            'comment-form',
            'comment-list',
            'gallery',
            'caption',
            'style',
            'script',
        ]);

        // Set up the WordPress core custom background feature
        add_theme_support('custom-background', [
            'default-color' => 'ffffff',
            'default-image' => '',
        ]);

        // Add theme support for selective refresh for widgets
        add_theme_support('customize-selective-refresh-widgets');

        // Add support for core custom logo
        add_theme_support('custom-logo', [
            'height' => 60,
            'width' => 240,
            'flex-width' => true,
            'flex-height' => true,
        ]);

        // Add theme support for custom header
        add_theme_support('custom-header', [
            'default-image' => '',
            'default-text-color' => '000000',
            'width' => 1920,
            'height' => 1080,
            'flex-width' => true,
            'flex-height' => true,
        ]);

        // Add support for Block Styles
        add_theme_support('wp-block-styles');

        // Add support for full and wide align images
        add_theme_support('align-wide');

        // Add support for responsive embedded content
        add_theme_support('responsive-embeds');

        // Add support for editor color palette
        add_theme_support('editor-color-palette', [
            [
                'name' => esc_html__('Primary', 'my-awesome-theme'),
                'slug' => 'primary',
                'color' => '#007cba',
            ],
            [
                'name' => esc_html__('Secondary', 'my-awesome-theme'),
                'slug' => 'secondary',
                'color' => '#006ba1',
            ],
            [
                'name' => esc_html__('Dark Gray', 'my-awesome-theme'),
                'slug' => 'dark-gray',
                'color' => '#111111',
            ],
            [
                'name' => esc_html__('Light Gray', 'my-awesome-theme'),
                'slug' => 'light-gray',
                'color' => '#767676',
            ],
            [
                'name' => esc_html__('White', 'my-awesome-theme'),
                'slug' => 'white',
                'color' => '#ffffff',
            ],
        ]);

        // Add support for editor font sizes
        add_theme_support('editor-font-sizes', [
            [
                'name' => esc_html__('Small', 'my-awesome-theme'),
                'size' => 12,
                'slug' => 'small',
            ],
            [
                'name' => esc_html__('Regular', 'my-awesome-theme'),
                'size' => 16,
                'slug' => 'regular',
            ],
            [
                'name' => esc_html__('Large', 'my-awesome-theme'),
                'slug' => 'large',
                'size' => 36,
            ],
            [
                'name' => esc_html__('Huge', 'my-awesome-theme'),
                'slug' => 'huge',
                'size' => 48,
            ],
        ]);

        // Disable custom colors in block editor
        add_theme_support('disable-custom-colors');

        // Disable custom font sizes in block editor
        add_theme_support('disable-custom-font-sizes');

        // Add WooCommerce support
        add_theme_support('woocommerce');
        add_theme_support('wc-product-gallery-zoom');
        add_theme_support('wc-product-gallery-lightbox');
        add_theme_support('wc-product-gallery-slider');
    }
}
add_action('after_setup_theme', 'my_awesome_theme_setup');

// Set content width
if (!isset($content_width)) {
    $content_width = 1200;
}

/**
 * Enqueue scripts and styles
 */
function my_awesome_theme_scripts() {
    // Theme stylesheet
    wp_enqueue_style('my-awesome-theme-style', get_stylesheet_uri(), [], MY_AWESOME_THEME_VERSION);

    // Google Fonts
    wp_enqueue_style(
        'my-awesome-theme-fonts',
        'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap',
        [],
        null
    );

    // Main theme script
    wp_enqueue_script(
        'my-awesome-theme-script',
        get_template_directory_uri() . '/dist/js/theme.js',
        ['jquery'],
        MY_AWESOME_THEME_VERSION,
        true
    );

    // Localize script
    wp_localize_script('my-awesome-theme-script', 'myAwesomeTheme', [
        'ajaxurl' => admin_url('admin-ajax.php'),
        'nonce' => wp_create_nonce('my_awesome_theme_nonce'),
        'strings' => [
            'loading' => esc_html__('Loading...', 'my-awesome-theme'),
            'loadMore' => esc_html__('Load More', 'my-awesome-theme'),
            'noMore' => esc_html__('No More Posts', 'my-awesome-theme'),
        ],
    ]);

    // Comment reply script
    if (is_singular() && comments_open() && get_option('thread_comments')) {
        wp_enqueue_script('comment-reply');
    }

    // Block editor styles
    add_theme_support('editor-styles');
    add_editor_style('dist/css/editor-style.css');
}
add_action('wp_enqueue_scripts', 'my_awesome_theme_scripts');

/**
 * Register widget areas
 */
function my_awesome_theme_widgets_init() {
    register_sidebar([
        'name' => esc_html__('Primary Sidebar', 'my-awesome-theme'),
        'id' => 'sidebar-1',
        'description' => esc_html__('Add widgets here to appear in your primary sidebar.', 'my-awesome-theme'),
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget' => '</section>',
        'before_title' => '<h2 class="widget-title">',
        'after_title' => '</h2>',
    ]);

    register_sidebar([
        'name' => esc_html__('Footer Area 1', 'my-awesome-theme'),
        'id' => 'footer-1',
        'description' => esc_html__('Add widgets here to appear in footer area 1.', 'my-awesome-theme'),
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget' => '</section>',
        'before_title' => '<h2 class="widget-title">',
        'after_title' => '</h2>',
    ]);

    register_sidebar([
        'name' => esc_html__('Footer Area 2', 'my-awesome-theme'),
        'id' => 'footer-2',
        'description' => esc_html__('Add widgets here to appear in footer area 2.', 'my-awesome-theme'),
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget' => '</section>',
        'before_title' => '<h2 class="widget-title">',
        'after_title' => '</h2>',
    ]);

    register_sidebar([
        'name' => esc_html__('Footer Area 3', 'my-awesome-theme'),
        'id' => 'footer-3',
        'description' => esc_html__('Add widgets here to appear in footer area 3.', 'my-awesome-theme'),
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget' => '</section>',
        'before_title' => '<h2 class="widget-title">',
        'after_title' => '</h2>',
    ]);
}
add_action('widgets_init', 'my_awesome_theme_widgets_init');

/**
 * Load theme includes
 */
require get_template_directory() . '/inc/template-functions.php';
require get_template_directory() . '/inc/template-tags.php';
require get_template_directory() . '/inc/customizer.php';
require get_template_directory() . '/inc/custom-header.php';

// Load Jetpack compatibility file
if (defined('JETPACK__VERSION')) {
    require get_template_directory() . '/inc/jetpack.php';
}

// Load WooCommerce compatibility file
if (class_exists('WooCommerce')) {
    require get_template_directory() . '/inc/woocommerce.php';
}
```

### 2. Template Hierarchy Implementation

```php
<?php
// index.php - Main template file

get_header(); ?>

<div id="primary" class="content-area">
    <main id="main" class="site-main">
        
        <?php if (have_posts()) : ?>
            
            <?php if (is_home() && !is_front_page()) : ?>
                <header class="page-header">
                    <h1 class="page-title screen-reader-text"><?php single_post_title(); ?></h1>
                </header>
            <?php endif; ?>

            <div class="posts-container">
                <?php while (have_posts()) : the_post(); ?>
                    <?php get_template_part('template-parts/content', get_post_type()); ?>
                <?php endwhile; ?>
            </div>

            <?php my_awesome_theme_posts_navigation(); ?>

        <?php else : ?>
            <?php get_template_part('template-parts/content', 'none'); ?>
        <?php endif; ?>

    </main><!-- #main -->
</div><!-- #primary -->

<?php
get_sidebar();
get_footer();
```

```php
<?php
// template-parts/content.php

?>
<article id="post-<?php the_ID(); ?>" <?php post_class('post-card'); ?>>
    
    <?php if (has_post_thumbnail()) : ?>
        <div class="post-thumbnail">
            <a href="<?php the_permalink(); ?>" aria-hidden="true" tabindex="-1">
                <?php the_post_thumbnail('featured-large', [
                    'alt' => the_title_attribute(['echo' => false]),
                ]); ?>
            </a>
        </div><!-- .post-thumbnail -->
    <?php endif; ?>

    <div class="post-content">
        <header class="entry-header">
            <?php
            if (is_singular()) :
                the_title('<h1 class="entry-title">', '</h1>');
            else :
                the_title('<h2 class="entry-title"><a href="' . esc_url(get_permalink()) . '" rel="bookmark">', '</a></h2>');
            endif;
            ?>

            <?php if ('post' === get_post_type()) : ?>
                <div class="entry-meta">
                    <?php my_awesome_theme_posted_on(); ?>
                    <?php my_awesome_theme_posted_by(); ?>
                    <?php my_awesome_theme_entry_footer(); ?>
                </div><!-- .entry-meta -->
            <?php endif; ?>
        </header><!-- .entry-header -->

        <div class="entry-content">
            <?php
            if (is_singular()) :
                the_content(sprintf(
                    wp_kses(
                        /* translators: %s: Name of current post. Only visible to screen readers */
                        __('Continue reading<span class="screen-reader-text"> "%s"</span>', 'my-awesome-theme'),
                        ['span' => ['class' => []]]
                    ),
                    wp_kses_post(get_the_title())
                ));

                wp_link_pages([
                    'before' => '<div class="page-links">' . esc_html__('Pages:', 'my-awesome-theme'),
                    'after' => '</div>',
                ]);
            else :
                the_excerpt();
                ?>
                <a href="<?php the_permalink(); ?>" class="read-more-link">
                    <?php esc_html_e('Read More', 'my-awesome-theme'); ?>
                    <span class="screen-reader-text"><?php the_title(); ?></span>
                </a>
                <?php
            endif;
            ?>
        </div><!-- .entry-content -->
    </div><!-- .post-content -->

</article><!-- #post-<?php the_ID(); ?> -->
```

### 3. Customizer Integration

```php
<?php
// inc/customizer.php

/**
 * Add postMessage support for site title and description for the Theme Customizer
 */
function my_awesome_theme_customize_register($wp_customize) {
    
    // Theme Options Panel
    $wp_customize->add_panel('theme_options', [
        'title' => esc_html__('Theme Options', 'my-awesome-theme'),
        'description' => esc_html__('Customize your theme settings', 'my-awesome-theme'),
        'priority' => 30,
    ]);

    // Colors Section
    $wp_customize->add_section('colors_section', [
        'title' => esc_html__('Color Scheme', 'my-awesome-theme'),
        'panel' => 'theme_options',
        'priority' => 10,
    ]);

    // Primary Color
    $wp_customize->add_setting('primary_color', [
        'default' => '#007cba',
        'sanitize_callback' => 'sanitize_hex_color',
        'transport' => 'postMessage',
    ]);

    $wp_customize->add_control(new WP_Customize_Color_Control($wp_customize, 'primary_color', [
        'label' => esc_html__('Primary Color', 'my-awesome-theme'),
        'section' => 'colors_section',
        'settings' => 'primary_color',
    ]));

    // Secondary Color
    $wp_customize->add_setting('secondary_color', [
        'default' => '#006ba1',
        'sanitize_callback' => 'sanitize_hex_color',
        'transport' => 'postMessage',
    ]);

    $wp_customize->add_control(new WP_Customize_Color_Control($wp_customize, 'secondary_color', [
        'label' => esc_html__('Secondary Color', 'my-awesome-theme'),
        'section' => 'colors_section',
        'settings' => 'secondary_color',
    ]));

    // Typography Section
    $wp_customize->add_section('typography_section', [
        'title' => esc_html__('Typography', 'my-awesome-theme'),
        'panel' => 'theme_options',
        'priority' => 20,
    ]);

    // Font Family
    $wp_customize->add_setting('font_family', [
        'default' => 'Inter',
        'sanitize_callback' => 'sanitize_text_field',
    ]);

    $wp_customize->add_control('font_family', [
        'label' => esc_html__('Font Family', 'my-awesome-theme'),
        'section' => 'typography_section',
        'type' => 'select',
        'choices' => [
            'Inter' => 'Inter',
            'Roboto' => 'Roboto',
            'Open Sans' => 'Open Sans',
            'Lato' => 'Lato',
            'Montserrat' => 'Montserrat',
        ],
    ]);

    // Layout Section
    $wp_customize->add_section('layout_section', [
        'title' => esc_html__('Layout Options', 'my-awesome-theme'),
        'panel' => 'theme_options',
        'priority' => 30,
    ]);

    // Container Width
    $wp_customize->add_setting('container_width', [
        'default' => '1200',
        'sanitize_callback' => 'absint',
        'transport' => 'postMessage',
    ]);

    $wp_customize->add_control('container_width', [
        'label' => esc_html__('Container Width (px)', 'my-awesome-theme'),
        'section' => 'layout_section',
        'type' => 'number',
        'input_attrs' => [
            'min' => 960,
            'max' => 1920,
            'step' => 10,
        ],
    ]);

    // Sidebar Position
    $wp_customize->add_setting('sidebar_position', [
        'default' => 'right',
        'sanitize_callback' => 'my_awesome_theme_sanitize_select',
    ]);

    $wp_customize->add_control('sidebar_position', [
        'label' => esc_html__('Sidebar Position', 'my-awesome-theme'),
        'section' => 'layout_section',
        'type' => 'select',
        'choices' => [
            'left' => esc_html__('Left', 'my-awesome-theme'),
            'right' => esc_html__('Right', 'my-awesome-theme'),
            'none' => esc_html__('No Sidebar', 'my-awesome-theme'),
        ],
    ]);

    // Blog Section
    $wp_customize->add_section('blog_section', [
        'title' => esc_html__('Blog Options', 'my-awesome-theme'),
        'panel' => 'theme_options',
        'priority' => 40,
    ]);

    // Excerpt Length
    $wp_customize->add_setting('excerpt_length', [
        'default' => 25,
        'sanitize_callback' => 'absint',
    ]);

    $wp_customize->add_control('excerpt_length', [
        'label' => esc_html__('Excerpt Length (words)', 'my-awesome-theme'),
        'section' => 'blog_section',
        'type' => 'number',
        'input_attrs' => [
            'min' => 10,
            'max' => 100,
        ],
    ]);

    // Show Author Bio
    $wp_customize->add_setting('show_author_bio', [
        'default' => false,
        'sanitize_callback' => 'my_awesome_theme_sanitize_checkbox',
    ]);

    $wp_customize->add_control('show_author_bio', [
        'label' => esc_html__('Show Author Bio', 'my-awesome-theme'),
        'section' => 'blog_section',
        'type' => 'checkbox',
    ]);

    // Footer Section
    $wp_customize->add_section('footer_section', [
        'title' => esc_html__('Footer Options', 'my-awesome-theme'),
        'panel' => 'theme_options',
        'priority' => 50,
    ]);

    // Copyright Text
    $wp_customize->add_setting('copyright_text', [
        'default' => sprintf(esc_html__('© %s. All rights reserved.', 'my-awesome-theme'), date('Y')),
        'sanitize_callback' => 'sanitize_text_field',
    ]);

    $wp_customize->add_control('copyright_text', [
        'label' => esc_html__('Copyright Text', 'my-awesome-theme'),
        'section' => 'footer_section',
        'type' => 'text',
    ]);

    // Social Links
    $social_networks = [
        'facebook' => esc_html__('Facebook', 'my-awesome-theme'),
        'twitter' => esc_html__('Twitter', 'my-awesome-theme'),
        'instagram' => esc_html__('Instagram', 'my-awesome-theme'),
        'linkedin' => esc_html__('LinkedIn', 'my-awesome-theme'),
        'youtube' => esc_html__('YouTube', 'my-awesome-theme'),
    ];

    foreach ($social_networks as $network => $label) {
        $wp_customize->add_setting("social_{$network}", [
            'default' => '',
            'sanitize_callback' => 'esc_url_raw',
        ]);

        $wp_customize->add_control("social_{$network}", [
            'label' => $label . ' ' . esc_html__('URL', 'my-awesome-theme'),
            'section' => 'footer_section',
            'type' => 'url',
        ]);
    }
}
add_action('customize_register', 'my_awesome_theme_customize_register');

/**
 * Sanitization callbacks
 */
function my_awesome_theme_sanitize_checkbox($checked) {
    return ((isset($checked) && true == $checked) ? true : false);
}

function my_awesome_theme_sanitize_select($input, $setting) {
    $choices = $setting->manager->get_control($setting->id)->choices;
    return (array_key_exists($input, $choices) ? $input : $setting->default);
}

/**
 * Bind JS handlers to instantly live-preview changes
 */
function my_awesome_theme_customize_preview_js() {
    wp_enqueue_script(
        'my-awesome-theme-customizer',
        get_template_directory_uri() . '/dist/js/customizer.js',
        ['customize-preview'],
        MY_AWESOME_THEME_VERSION,
        true
    );
}
add_action('customize_preview_init', 'my_awesome_theme_customize_preview_js');
```

## 💰 Theme Monetization Strategies

### 1. Premium Theme Structure

```php
<?php
// inc/theme-updater.php

class MyAwesome_Theme_Updater {
    
    private $theme_slug;
    private $version;
    private $update_path;
    private $license_key;
    
    public function __construct($theme_slug, $version, $update_path) {
        $this->theme_slug = get_template();
        $this->version = $version;
        $this->update_path = $update_path;
        $this->license_key = get_option('my_awesome_theme_license_key');
        
        add_filter('pre_set_site_transient_update_themes', [$this, 'check_for_update']);
    }
    
    public function check_for_update($transient) {
        if (empty($transient->checked)) {
            return $transient;
        }
        
        $remote_data = $this->get_remote_data();
        
        if ($remote_data && version_compare($this->version, $remote_data['version'], '<')) {
            $transient->response[$this->theme_slug] = [
                'theme' => $this->theme_slug,
                'new_version' => $remote_data['version'],
                'url' => $remote_data['url'],
                'package' => $remote_data['package'],
            ];
        }
        
        return $transient;
    }
    
    private function get_remote_data() {
        $request = wp_remote_get($this->update_path . '?license=' . $this->license_key);
        
        if (!is_wp_error($request) && wp_remote_retrieve_response_code($request) === 200) {
            return json_decode(wp_remote_retrieve_body($request), true);
        }
        
        return false;
    }
}

// Initialize updater for premium themes
if (get_theme_mod('theme_license_status') === 'active') {
    new MyAwesome_Theme_Updater(
        get_template(),
        MY_AWESOME_THEME_VERSION,
        'https://your-update-server.com/api/theme-updates'
    );
}
```

### 2. License Management

```php
<?php
// inc/license-manager.php

class MyAwesome_Theme_License {
    
    private $license_server = 'https://your-license-server.com/api/';
    
    public function __construct() {
        add_action('customize_register', [$this, 'add_license_section']);
        add_action('wp_ajax_activate_theme_license', [$this, 'activate_license']);
        add_action('wp_ajax_deactivate_theme_license', [$this, 'deactivate_license']);
    }
    
    public function add_license_section($wp_customize) {
        $wp_customize->add_section('license_section', [
            'title' => esc_html__('Theme License', 'my-awesome-theme'),
            'priority' => 200,
        ]);
        
        $wp_customize->add_setting('license_key', [
            'default' => '',
            'sanitize_callback' => 'sanitize_text_field',
        ]);
        
        $wp_customize->add_control('license_key', [
            'label' => esc_html__('License Key', 'my-awesome-theme'),
            'section' => 'license_section',
            'type' => 'text',
            'description' => $this->get_license_status_message(),
        ]);
    }
    
    public function activate_license() {
        check_ajax_referer('theme_license_nonce');
        
        $license_key = sanitize_text_field($_POST['license_key']);
        
        $response = wp_remote_post($this->license_server . 'activate', [
            'body' => [
                'license_key' => $license_key,
                'site_url' => home_url(),
                'theme' => get_template(),
            ],
            'timeout' => 15,
        ]);
        
        if (is_wp_error($response)) {
            wp_send_json_error(['message' => $response->get_error_message()]);
        }
        
        $body = json_decode(wp_remote_retrieve_body($response), true);
        
        if ($body['success']) {
            set_theme_mod('license_key', $license_key);
            set_theme_mod('license_status', 'active');
            set_theme_mod('license_expires', $body['expires']);
            
            wp_send_json_success(['message' => esc_html__('License activated successfully!', 'my-awesome-theme')]);
        } else {
            wp_send_json_error(['message' => $body['message']]);
        }
    }
    
    public function deactivate_license() {
        check_ajax_referer('theme_license_nonce');
        
        $license_key = get_theme_mod('license_key');
        
        wp_remote_post($this->license_server . 'deactivate', [
            'body' => [
                'license_key' => $license_key,
                'site_url' => home_url(),
            ],
        ]);
        
        remove_theme_mod('license_key');
        remove_theme_mod('license_status');
        remove_theme_mod('license_expires');
        
        wp_send_json_success(['message' => esc_html__('License deactivated successfully!', 'my-awesome-theme')]);
    }
    
    private function get_license_status_message() {
        $status = get_theme_mod('license_status');
        
        if ($status === 'active') {
            $expires = get_theme_mod('license_expires');
            return sprintf(
                esc_html__('License is active. Expires: %s', 'my-awesome-theme'),
                date('F j, Y', strtotime($expires))
            );
        }
        
        return esc_html__('Enter your license key to receive theme updates and premium support.', 'my-awesome-theme');
    }
    
    public function is_license_valid() {
        return get_theme_mod('license_status') === 'active';
    }
}

new MyAwesome_Theme_License();
```

## 🛠️ Advanced Theme Features

### 1. Custom Post Type Integration

```php
<?php
// inc/post-types.php

function my_awesome_theme_register_post_types() {
    // Only register if license is active or for free themes
    $license_manager = new MyAwesome_Theme_License();
    if (!$license_manager->is_license_valid() && !MY_AWESOME_THEME_IS_FREE) {
        return;
    }
    
    // Portfolio Post Type
    register_post_type('portfolio', [
        'labels' => [
            'name' => esc_html__('Portfolio', 'my-awesome-theme'),
            'singular_name' => esc_html__('Portfolio Item', 'my-awesome-theme'),
            'add_new' => esc_html__('Add New', 'my-awesome-theme'),
            'add_new_item' => esc_html__('Add New Portfolio Item', 'my-awesome-theme'),
            'edit_item' => esc_html__('Edit Portfolio Item', 'my-awesome-theme'),
        ],
        'public' => true,
        'has_archive' => true,
        'show_in_rest' => true,
        'supports' => ['title', 'editor', 'thumbnail', 'excerpt'],
        'menu_icon' => 'dashicons-portfolio',
    ]);
    
    // Testimonials Post Type
    register_post_type('testimonial', [
        'labels' => [
            'name' => esc_html__('Testimonials', 'my-awesome-theme'),
            'singular_name' => esc_html__('Testimonial', 'my-awesome-theme'),
        ],
        'public' => true,
        'show_in_rest' => true,
        'supports' => ['title', 'editor', 'thumbnail'],
        'menu_icon' => 'dashicons-testimonial',
    ]);
    
    // Team Members Post Type
    register_post_type('team', [
        'labels' => [
            'name' => esc_html__('Team Members', 'my-awesome-theme'),
            'singular_name' => esc_html__('Team Member', 'my-awesome-theme'),
        ],
        'public' => true,
        'show_in_rest' => true,
        'supports' => ['title', 'editor', 'thumbnail'],
        'menu_icon' => 'dashicons-groups',
    ]);
}
add_action('init', 'my_awesome_theme_register_post_types');
```

### 2. Block Editor Integration

```php
<?php
// inc/block-editor.php

/**
 * Block editor customizations
 */
function my_awesome_theme_block_editor_setup() {
    // Add block styles
    wp_enqueue_style(
        'my-awesome-theme-block-editor-style',
        get_template_directory_uri() . '/dist/css/block-editor.css',
        [],
        MY_AWESOME_THEME_VERSION
    );
    
    // Add custom block styles
    register_block_style('core/quote', [
        'name' => 'fancy-quote',
        'label' => esc_html__('Fancy Quote', 'my-awesome-theme'),
    ]);
    
    register_block_style('core/button', [
        'name' => 'rounded-button',
        'label' => esc_html__('Rounded Button', 'my-awesome-theme'),
    ]);
}
add_action('enqueue_block_editor_assets', 'my_awesome_theme_block_editor_setup');

/**
 * Register custom block patterns
 */
function my_awesome_theme_register_block_patterns() {
    // Hero section pattern
    register_block_pattern('my-awesome-theme/hero-section', [
        'title' => esc_html__('Hero Section', 'my-awesome-theme'),
        'categories' => ['featured'],
        'content' => '<!-- wp:cover {"url":"' . get_template_directory_uri() . '/assets/images/hero-bg.jpg","hasParallax":true} -->
        <div class="wp-block-cover has-parallax">
            <span aria-hidden="true" class="wp-block-cover__background has-background-dim"></span>
            <div class="wp-block-cover__image-background" style="background-position:50% 50%;background-image:url(' . get_template_directory_uri() . '/assets/images/hero-bg.jpg)"></div>
            <div class="wp-block-cover__inner-container">
                <!-- wp:heading {"level":1,"textAlign":"center","textColor":"white"} -->
                <h1 class="has-text-align-center has-white-color has-text-color">' . esc_html__('Welcome to Our Amazing Site', 'my-awesome-theme') . '</h1>
                <!-- /wp:heading -->
                
                <!-- wp:paragraph {"align":"center","textColor":"white"} -->
                <p class="has-text-align-center has-white-color has-text-color">' . esc_html__('Discover something extraordinary with our amazing theme.', 'my-awesome-theme') . '</p>
                <!-- /wp:paragraph -->
                
                <!-- wp:buttons {"contentJustification":"center"} -->
                <div class="wp-block-buttons is-content-justification-center">
                    <!-- wp:button {"className":"is-style-rounded-button"} -->
                    <div class="wp-block-button is-style-rounded-button">
                        <a class="wp-block-button__link">' . esc_html__('Get Started', 'my-awesome-theme') . '</a>
                    </div>
                    <!-- /wp:button -->
                </div>
                <!-- /wp:buttons -->
            </div>
        </div>
        <!-- /wp:cover -->',
    ]);
    
    // Call to action pattern
    register_block_pattern('my-awesome-theme/call-to-action', [
        'title' => esc_html__('Call to Action', 'my-awesome-theme'),
        'categories' => ['text'],
        'content' => '<!-- wp:group {"backgroundColor":"primary","textColor":"white","className":"call-to-action-section"} -->
        <div class="wp-block-group call-to-action-section has-primary-background-color has-white-color has-text-color has-background">
            <!-- wp:heading {"textAlign":"center"} -->
            <h2 class="has-text-align-center">' . esc_html__('Ready to Get Started?', 'my-awesome-theme') . '</h2>
            <!-- /wp:heading -->
            
            <!-- wp:paragraph {"align":"center"} -->
            <p class="has-text-align-center">' . esc_html__('Join thousands of satisfied customers today.', 'my-awesome-theme') . '</p>
            <!-- /wp:paragraph -->
            
            <!-- wp:buttons {"contentJustification":"center"} -->
            <div class="wp-block-buttons is-content-justification-center">
                <!-- wp:button {"backgroundColor":"white","textColor":"primary"} -->
                <div class="wp-block-button">
                    <a class="wp-block-button__link has-primary-color has-white-background-color has-text-color has-background">' . esc_html__('Contact Us', 'my-awesome-theme') . '</a>
                </div>
                <!-- /wp:button -->
            </div>
            <!-- /wp:buttons -->
        </div>
        <!-- /wp:group -->',
    ]);
}
add_action('init', 'my_awesome_theme_register_block_patterns');
```

### 3. Performance Optimization

```php
<?php
// inc/performance.php

/**
 * Performance optimizations
 */
class MyAwesome_Theme_Performance {
    
    public function __construct() {
        add_action('wp_enqueue_scripts', [$this, 'optimize_scripts'], 100);
        add_filter('wp_resource_hints', [$this, 'add_resource_hints'], 10, 2);
        add_action('wp_head', [$this, 'add_preload_hints'], 1);
        
        // Lazy loading
        add_filter('wp_lazy_loading_enabled', '__return_true');
        
        // Remove unused scripts
        add_action('wp_enqueue_scripts', [$this, 'remove_unused_scripts'], 100);
        
        // Optimize images
        add_filter('wp_calculate_image_srcset_meta', [$this, 'optimize_image_srcset']);
    }
    
    public function optimize_scripts() {
        // Defer non-critical CSS
        if (!is_admin()) {
            wp_enqueue_style('my-awesome-theme-non-critical', get_template_directory_uri() . '/dist/css/non-critical.css', [], MY_AWESOME_THEME_VERSION, 'all');
            wp_style_add_data('my-awesome-theme-non-critical', 'media', 'print');
            wp_style_add_data('my-awesome-theme-non-critical', 'onload', "this.media='all'");
        }
    }
    
    public function add_resource_hints($urls, $relation_type) {
        if ($relation_type === 'preconnect') {
            $urls[] = 'https://fonts.googleapis.com';
            $urls[] = 'https://fonts.gstatic.com';
        }
        
        return $urls;
    }
    
    public function add_preload_hints() {
        // Preload critical CSS
        echo '<link rel="preload" href="' . get_template_directory_uri() . '/dist/css/critical.css" as="style" onload="this.onload=null;this.rel=\'stylesheet\'">' . "\n";
        
        // Preload key fonts
        echo '<link rel="preload" href="https://fonts.gstatic.com/s/inter/v12/UcCO3FwrK3iLTeHuS_fvQtMwCp50KnMw2boKoduKmMEVuLyfAZ9hiA.woff2" as="font" type="font/woff2" crossorigin>' . "\n";
    }
    
    public function remove_unused_scripts() {
        // Remove jQuery migrate on frontend for better performance
        if (!is_admin() && !is_customize_preview()) {
            wp_deregister_script('jquery-migrate');
        }
        
        // Remove block library CSS on non-block pages
        if (!has_blocks()) {
            wp_dequeue_style('wp-block-library');
            wp_dequeue_style('wp-block-library-theme');
        }
    }
    
    public function optimize_image_srcset($image_meta) {
        // Remove unnecessary image sizes from srcset
        $allowed_sizes = ['thumbnail', 'medium', 'large', 'featured-large'];
        
        foreach ($image_meta['sizes'] as $size => $data) {
            if (!in_array($size, $allowed_sizes)) {
                unset($image_meta['sizes'][$size]);
            }
        }
        
        return $image_meta;
    }
}

new MyAwesome_Theme_Performance();

/**
 * Critical CSS inline
 */
function my_awesome_theme_critical_css() {
    if (is_front_page()) {
        $critical_css = file_get_contents(get_template_directory() . '/dist/css/critical.css');
        if ($critical_css) {
            echo '<style id="critical-css">' . $critical_css . '</style>';
        }
    }
}
add_action('wp_head', 'my_awesome_theme_critical_css', 1);
```

## ⚠️ Common Pitfalls to Avoid

### 1. Theme Review Issues
```php
// ❌ Bad - Using file_get_contents() for remote URLs
$content = file_get_contents('https://api.example.com/data');

// ✅ Good - Using WordPress HTTP API
$response = wp_remote_get('https://api.example.com/data');
if (!is_wp_error($response)) {
    $content = wp_remote_retrieve_body($response);
}

// ❌ Bad - Direct database queries
global $wpdb;
$results = $wpdb->get_results("SELECT * FROM {$wpdb->posts} WHERE post_status = 'publish'");

// ✅ Good - Using WordPress functions
$posts = get_posts(['post_status' => 'publish']);
```

### 2. Security Issues
```php
// ❌ Bad - No sanitization in customizer
$wp_customize->add_control('custom_html', [
    'sanitize_callback' => 'wp_kses_post', // Still not safe for HTML
]);

// ✅ Good - Proper sanitization
$wp_customize->add_control('custom_html', [
    'sanitize_callback' => function($input) {
        return wp_kses($input, [
            'p' => [],
            'strong' => [],
            'em' => [],
            'a' => ['href' => [], 'title' => []],
        ]);
    },
]);
```

## 📊 Theme Performance Metrics

### 1. Core Web Vitals Optimization
```scss
// Critical CSS for above-the-fold content
.hero-section {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    
    // Prevent layout shift
    aspect-ratio: 16 / 9;
}

// Optimize font loading
@font-face {
    font-family: 'Inter';
    font-style: normal;
    font-weight: 400;
    font-display: swap; // Prevent invisible text during font load
    src: url('fonts/inter-v12-latin-regular.woff2') format('woff2');
}
```

### 2. Image Optimization
```php
// Add WebP support
function my_awesome_theme_webp_support($sources, $size_array, $image_src, $image_meta, $attachment_id) {
    if (!function_exists('wp_get_webp_info')) {
        return $sources;
    }
    
    foreach ($sources as $width => $source) {
        $webp_src = str_replace(['.jpg', '.jpeg', '.png'], '.webp', $source['url']);
        if (file_exists(str_replace(home_url('/'), ABSPATH, $webp_src))) {
            $sources[$width]['url'] = $webp_src;
            $sources[$width]['type'] = 'image/webp';
        }
    }
    
    return $sources;
}
add_filter('wp_calculate_image_srcset', 'my_awesome_theme_webp_support', 10, 5);
```

## 📋 Code Review Checklist

- [ ] Theme passes WordPress Theme Review requirements
- [ ] All strings are translatable with proper text domain
- [ ] Proper sanitization and escaping implemented
- [ ] Performance optimizations in place
- [ ] Accessibility standards met (WCAG 2.1 AA)
- [ ] Cross-browser compatibility tested
- [ ] Mobile responsiveness verified
- [ ] Block editor compatibility ensured
- [ ] License system implemented (if premium)
- [ ] Update mechanism configured (if premium)

Remember: Successful WordPress themes solve specific design problems while maintaining compatibility with WordPress standards and providing excellent user experience. Focus on performance, accessibility, and adherence to WordPress coding standards for both free and premium distribution.