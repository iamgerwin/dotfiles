# WordPress Core Development Best Practices

Comprehensive guide for WordPress core development, custom post types, custom fields, hooks, and professional WordPress development practices.

## 📚 Official Documentation
- [WordPress Developer Documentation](https://developer.wordpress.org/)
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [WordPress Plugin Handbook](https://developer.wordpress.org/plugins/)
- [WordPress Theme Handbook](https://developer.wordpress.org/themes/)

## 🏗️ Project Structure

### Standard WordPress Development Structure
```
wordpress-project/
├── wp-content/
│   ├── themes/
│   │   └── custom-theme/
│   │       ├── style.css
│   │       ├── index.php
│   │       ├── functions.php
│   │       ├── header.php
│   │       ├── footer.php
│   │       └── template-parts/
│   ├── plugins/
│   │   └── custom-plugin/
│   │       ├── custom-plugin.php
│   │       ├── includes/
│   │       ├── admin/
│   │       ├── public/
│   │       └── assets/
│   └── mu-plugins/             # Must-use plugins
├── wp-config.php
├── .htaccess
└── composer.json              # For dependency management
```

### Modern WordPress Development Structure
```
modern-wp-project/
├── web/                        # Web root
│   ├── app/                    # Renamed wp-content
│   │   ├── themes/
│   │   ├── plugins/
│   │   └── mu-plugins/
│   ├── wp/                     # WordPress core
│   └── wp-config.php
├── config/                     # Environment configs
│   ├── application.php
│   ├── environments/
│   │   ├── development.php
│   │   ├── staging.php
│   │   └── production.php
├── composer.json
└── package.json
```

## 🎯 Core WordPress Development Best Practices

### 1. Functions.php Best Practices

```php
<?php
// themes/custom-theme/functions.php

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Theme setup and initialization
 */
class CustomTheme {
    
    /**
     * Constructor
     */
    public function __construct() {
        add_action('after_setup_theme', [$this, 'theme_setup']);
        add_action('wp_enqueue_scripts', [$this, 'enqueue_scripts']);
        add_action('init', [$this, 'register_post_types']);
        add_action('init', [$this, 'register_taxonomies']);
        add_action('widgets_init', [$this, 'register_sidebars']);
    }
    
    /**
     * Theme setup
     */
    public function theme_setup() {
        // Add theme support
        add_theme_support('title-tag');
        add_theme_support('post-thumbnails');
        add_theme_support('html5', [
            'search-form',
            'comment-form',
            'comment-list',
            'gallery',
            'caption',
        ]);
        add_theme_support('customize-selective-refresh-widgets');
        
        // Add custom image sizes
        add_image_size('hero-image', 1920, 800, true);
        add_image_size('card-thumbnail', 400, 300, true);
        add_image_size('gallery-thumb', 300, 300, true);
        
        // Register navigation menus
        register_nav_menus([
            'primary' => esc_html__('Primary Menu', 'custom-theme'),
            'footer' => esc_html__('Footer Menu', 'custom-theme'),
            'mobile' => esc_html__('Mobile Menu', 'custom-theme'),
        ]);
    }
    
    /**
     * Enqueue scripts and styles
     */
    public function enqueue_scripts() {
        $theme_version = wp_get_theme()->get('Version');
        
        // Styles
        wp_enqueue_style(
            'custom-theme-style',
            get_stylesheet_uri(),
            [],
            $theme_version
        );
        
        wp_enqueue_style(
            'custom-theme-main',
            get_template_directory_uri() . '/assets/css/main.css',
            ['custom-theme-style'],
            $theme_version
        );
        
        // Scripts
        wp_enqueue_script(
            'custom-theme-main',
            get_template_directory_uri() . '/assets/js/main.js',
            ['jquery'],
            $theme_version,
            true
        );
        
        // Localize script for AJAX
        wp_localize_script('custom-theme-main', 'customTheme', [
            'ajaxurl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('custom_theme_nonce'),
            'strings' => [
                'loading' => esc_html__('Loading...', 'custom-theme'),
                'error' => esc_html__('An error occurred', 'custom-theme'),
            ]
        ]);
        
        // Conditional loading
        if (is_singular() && comments_open() && get_option('thread_comments')) {
            wp_enqueue_script('comment-reply');
        }
    }
    
    /**
     * Register custom post types
     */
    public function register_post_types() {
        // Portfolio post type
        register_post_type('portfolio', [
            'labels' => [
                'name' => esc_html__('Portfolio', 'custom-theme'),
                'singular_name' => esc_html__('Portfolio Item', 'custom-theme'),
                'add_new' => esc_html__('Add New', 'custom-theme'),
                'add_new_item' => esc_html__('Add New Portfolio Item', 'custom-theme'),
                'edit_item' => esc_html__('Edit Portfolio Item', 'custom-theme'),
                'new_item' => esc_html__('New Portfolio Item', 'custom-theme'),
                'view_item' => esc_html__('View Portfolio Item', 'custom-theme'),
                'search_items' => esc_html__('Search Portfolio', 'custom-theme'),
                'not_found' => esc_html__('No portfolio items found', 'custom-theme'),
                'not_found_in_trash' => esc_html__('No portfolio items found in trash', 'custom-theme'),
            ],
            'public' => true,
            'has_archive' => true,
            'show_in_rest' => true, // Enable Gutenberg
            'supports' => ['title', 'editor', 'thumbnail', 'excerpt', 'custom-fields'],
            'rewrite' => ['slug' => 'portfolio'],
            'menu_icon' => 'dashicons-portfolio',
        ]);
    }
    
    /**
     * Register taxonomies
     */
    public function register_taxonomies() {
        // Portfolio category
        register_taxonomy('portfolio_category', 'portfolio', [
            'labels' => [
                'name' => esc_html__('Portfolio Categories', 'custom-theme'),
                'singular_name' => esc_html__('Portfolio Category', 'custom-theme'),
            ],
            'public' => true,
            'hierarchical' => true,
            'show_in_rest' => true,
            'rewrite' => ['slug' => 'portfolio-category'],
        ]);
    }
    
    /**
     * Register sidebars
     */
    public function register_sidebars() {
        register_sidebar([
            'name' => esc_html__('Primary Sidebar', 'custom-theme'),
            'id' => 'sidebar-primary',
            'description' => esc_html__('Main sidebar that appears on the right.', 'custom-theme'),
            'before_widget' => '<div id="%1$s" class="widget %2$s">',
            'after_widget' => '</div>',
            'before_title' => '<h3 class="widget-title">',
            'after_title' => '</h3>',
        ]);
        
        register_sidebar([
            'name' => esc_html__('Footer Widgets', 'custom-theme'),
            'id' => 'sidebar-footer',
            'description' => esc_html__('Footer widget area.', 'custom-theme'),
            'before_widget' => '<div id="%1$s" class="footer-widget %2$s">',
            'after_widget' => '</div>',
            'before_title' => '<h4 class="widget-title">',
            'after_title' => '</h4>',
        ]);
    }
}

// Initialize theme
new CustomTheme();

/**
 * Custom functions
 */

/**
 * Get excerpt with custom length
 */
function custom_excerpt($limit = 150) {
    $excerpt = explode(' ', get_the_excerpt(), $limit);
    
    if (count($excerpt) >= $limit) {
        array_pop($excerpt);
        $excerpt = implode(" ", $excerpt) . '...';
    } else {
        $excerpt = implode(" ", $excerpt);
    }
    
    $excerpt = preg_replace('`\[[^\]]*\]`', '', $excerpt);
    return $excerpt;
}

/**
 * Custom pagination
 */
function custom_pagination() {
    global $wp_query;
    
    $total = $wp_query->max_num_pages;
    
    if ($total > 1) {
        if (!$current_page = get_query_var('paged')) {
            $current_page = 1;
        }
        
        echo '<nav class="pagination" role="navigation">';
        echo paginate_links([
            'base' => get_pagenum_link(1) . '%_%',
            'format' => 'page/%#%/',
            'current' => $current_page,
            'total' => $total,
            'mid_size' => 2,
            'type' => 'list',
            'prev_text' => esc_html__('« Previous', 'custom-theme'),
            'next_text' => esc_html__('Next »', 'custom-theme'),
        ]);
        echo '</nav>';
    }
}

/**
 * Custom breadcrumbs
 */
function custom_breadcrumbs() {
    if (is_front_page()) return;
    
    $delimiter = ' / ';
    $home = esc_html__('Home', 'custom-theme');
    $before = '<span class="current">';
    $after = '</span>';
    
    echo '<nav class="breadcrumbs" itemscope itemtype="https://schema.org/BreadcrumbList">';
    echo '<a href="' . esc_url(home_url()) . '" itemprop="url"><span itemprop="name">' . $home . '</span></a>' . $delimiter;
    
    if (is_category() || is_single()) {
        $categories = get_the_category();
        if ($categories) {
            $category = $categories[0];
            echo '<a href="' . esc_url(get_category_link($category->term_id)) . '" itemprop="url"><span itemprop="name">' . esc_html($category->name) . '</span></a>';
            if (is_single()) {
                echo $delimiter . $before . get_the_title() . $after;
            }
        }
    } elseif (is_page()) {
        if (wp_get_post_parent_id(get_the_ID())) {
            $parents = get_post_ancestors(get_the_ID());
            $parents = array_reverse($parents);
            foreach ($parents as $parent) {
                echo '<a href="' . esc_url(get_permalink($parent)) . '" itemprop="url"><span itemprop="name">' . get_the_title($parent) . '</span></a>' . $delimiter;
            }
        }
        echo $before . get_the_title() . $after;
    }
    
    echo '</nav>';
}
```

### 2. Custom Meta Boxes and Fields

```php
<?php
// includes/metaboxes.php

class CustomMetaBoxes {
    
    public function __construct() {
        add_action('add_meta_boxes', [$this, 'add_meta_boxes']);
        add_action('save_post', [$this, 'save_meta_boxes']);
    }
    
    /**
     * Add meta boxes
     */
    public function add_meta_boxes() {
        add_meta_box(
            'portfolio_details',
            esc_html__('Portfolio Details', 'custom-theme'),
            [$this, 'portfolio_details_callback'],
            'portfolio',
            'normal',
            'high'
        );
        
        add_meta_box(
            'page_settings',
            esc_html__('Page Settings', 'custom-theme'),
            [$this, 'page_settings_callback'],
            'page',
            'side',
            'default'
        );
    }
    
    /**
     * Portfolio details meta box callback
     */
    public function portfolio_details_callback($post) {
        wp_nonce_field('portfolio_details_nonce', 'portfolio_details_nonce_field');
        
        $client = get_post_meta($post->ID, '_portfolio_client', true);
        $url = get_post_meta($post->ID, '_portfolio_url', true);
        $technologies = get_post_meta($post->ID, '_portfolio_technologies', true);
        $featured = get_post_meta($post->ID, '_portfolio_featured', true);
        
        echo '<table class="form-table">';
        
        echo '<tr>';
        echo '<th><label for="portfolio_client">' . esc_html__('Client', 'custom-theme') . '</label></th>';
        echo '<td><input type="text" id="portfolio_client" name="portfolio_client" value="' . esc_attr($client) . '" class="regular-text" /></td>';
        echo '</tr>';
        
        echo '<tr>';
        echo '<th><label for="portfolio_url">' . esc_html__('Project URL', 'custom-theme') . '</label></th>';
        echo '<td><input type="url" id="portfolio_url" name="portfolio_url" value="' . esc_attr($url) . '" class="regular-text" /></td>';
        echo '</tr>';
        
        echo '<tr>';
        echo '<th><label for="portfolio_technologies">' . esc_html__('Technologies Used', 'custom-theme') . '</label></th>';
        echo '<td><textarea id="portfolio_technologies" name="portfolio_technologies" rows="3" class="large-text">' . esc_textarea($technologies) . '</textarea></td>';
        echo '</tr>';
        
        echo '<tr>';
        echo '<th><label for="portfolio_featured">' . esc_html__('Featured Project', 'custom-theme') . '</label></th>';
        echo '<td><input type="checkbox" id="portfolio_featured" name="portfolio_featured" value="1" ' . checked($featured, 1, false) . ' /> ' . esc_html__('Mark as featured', 'custom-theme') . '</td>';
        echo '</tr>';
        
        echo '</table>';
    }
    
    /**
     * Page settings meta box callback
     */
    public function page_settings_callback($post) {
        wp_nonce_field('page_settings_nonce', 'page_settings_nonce_field');
        
        $hide_title = get_post_meta($post->ID, '_page_hide_title', true);
        $custom_class = get_post_meta($post->ID, '_page_custom_class', true);
        $sidebar_position = get_post_meta($post->ID, '_page_sidebar_position', true);
        
        echo '<p>';
        echo '<input type="checkbox" id="page_hide_title" name="page_hide_title" value="1" ' . checked($hide_title, 1, false) . ' />';
        echo '<label for="page_hide_title">' . esc_html__('Hide page title', 'custom-theme') . '</label>';
        echo '</p>';
        
        echo '<p>';
        echo '<label for="page_custom_class">' . esc_html__('Custom CSS Class', 'custom-theme') . '</label>';
        echo '<input type="text" id="page_custom_class" name="page_custom_class" value="' . esc_attr($custom_class) . '" class="widefat" />';
        echo '</p>';
        
        echo '<p>';
        echo '<label for="page_sidebar_position">' . esc_html__('Sidebar Position', 'custom-theme') . '</label>';
        echo '<select id="page_sidebar_position" name="page_sidebar_position" class="widefat">';
        echo '<option value="default"' . selected($sidebar_position, 'default', false) . '>' . esc_html__('Default', 'custom-theme') . '</option>';
        echo '<option value="left"' . selected($sidebar_position, 'left', false) . '>' . esc_html__('Left', 'custom-theme') . '</option>';
        echo '<option value="right"' . selected($sidebar_position, 'right', false) . '>' . esc_html__('Right', 'custom-theme') . '</option>';
        echo '<option value="none"' . selected($sidebar_position, 'none', false) . '>' . esc_html__('No Sidebar', 'custom-theme') . '</option>';
        echo '</select>';
        echo '</p>';
    }
    
    /**
     * Save meta boxes data
     */
    public function save_meta_boxes($post_id) {
        // Check if nonce is set
        if (!isset($_POST['portfolio_details_nonce_field']) && !isset($_POST['page_settings_nonce_field'])) {
            return;
        }
        
        // Verify nonce
        if (isset($_POST['portfolio_details_nonce_field'])) {
            if (!wp_verify_nonce($_POST['portfolio_details_nonce_field'], 'portfolio_details_nonce')) {
                return;
            }
        }
        
        if (isset($_POST['page_settings_nonce_field'])) {
            if (!wp_verify_nonce($_POST['page_settings_nonce_field'], 'page_settings_nonce')) {
                return;
            }
        }
        
        // Check if user has permission
        if (isset($_POST['post_type']) && 'page' == $_POST['post_type']) {
            if (!current_user_can('edit_page', $post_id)) {
                return;
            }
        } else {
            if (!current_user_can('edit_post', $post_id)) {
                return;
            }
        }
        
        // Save portfolio details
        if (isset($_POST['portfolio_client'])) {
            update_post_meta($post_id, '_portfolio_client', sanitize_text_field($_POST['portfolio_client']));
        }
        
        if (isset($_POST['portfolio_url'])) {
            update_post_meta($post_id, '_portfolio_url', esc_url_raw($_POST['portfolio_url']));
        }
        
        if (isset($_POST['portfolio_technologies'])) {
            update_post_meta($post_id, '_portfolio_technologies', sanitize_textarea_field($_POST['portfolio_technologies']));
        }
        
        update_post_meta($post_id, '_portfolio_featured', isset($_POST['portfolio_featured']) ? 1 : 0);
        
        // Save page settings
        update_post_meta($post_id, '_page_hide_title', isset($_POST['page_hide_title']) ? 1 : 0);
        
        if (isset($_POST['page_custom_class'])) {
            update_post_meta($post_id, '_page_custom_class', sanitize_html_class($_POST['page_custom_class']));
        }
        
        if (isset($_POST['page_sidebar_position'])) {
            $allowed_values = ['default', 'left', 'right', 'none'];
            $value = in_array($_POST['page_sidebar_position'], $allowed_values) ? $_POST['page_sidebar_position'] : 'default';
            update_post_meta($post_id, '_page_sidebar_position', $value);
        }
    }
}

new CustomMetaBoxes();
```

### 3. Custom Hooks and Filters

```php
<?php
// includes/hooks.php

/**
 * Custom action hooks
 */

// Before content hook
if (!function_exists('custom_before_content')) {
    function custom_before_content() {
        do_action('custom_before_content');
    }
}

// After content hook  
if (!function_exists('custom_after_content')) {
    function custom_after_content() {
        do_action('custom_after_content');
    }
}

/**
 * Custom filter hooks
 */

// Custom excerpt length
function custom_excerpt_length($length) {
    return apply_filters('custom_excerpt_length', 55);
}
add_filter('excerpt_length', 'custom_excerpt_length');

// Custom excerpt more text
function custom_excerpt_more($more) {
    return apply_filters('custom_excerpt_more', '...');
}
add_filter('excerpt_more', 'custom_excerpt_more');

// Custom post classes
function custom_post_classes($classes, $class, $post_id) {
    if (is_singular('portfolio')) {
        $classes[] = 'portfolio-single';
        
        if (get_post_meta($post_id, '_portfolio_featured', true)) {
            $classes[] = 'featured-portfolio';
        }
    }
    
    return apply_filters('custom_post_classes', $classes, $class, $post_id);
}
add_filter('post_class', 'custom_post_classes', 10, 3);

// Custom body classes
function custom_body_classes($classes) {
    if (is_page()) {
        $sidebar_position = get_post_meta(get_the_ID(), '_page_sidebar_position', true);
        if ($sidebar_position && $sidebar_position !== 'default') {
            $classes[] = 'sidebar-' . $sidebar_position;
        }
    }
    
    return apply_filters('custom_body_classes', $classes);
}
add_filter('body_class', 'custom_body_classes');

/**
 * WordPress core modifications
 */

// Remove unnecessary head elements
remove_action('wp_head', 'wp_generator');
remove_action('wp_head', 'wlwmanifest_link');
remove_action('wp_head', 'rsd_link');

// Clean up image markup
function custom_image_markup($html, $id, $caption, $title, $align, $url, $size, $alt) {
    $src = wp_get_attachment_image_src($id, $size, false);
    
    if ($src) {
        $html = '<img src="' . esc_url($src[0]) . '" alt="' . esc_attr($alt) . '" width="' . esc_attr($src[1]) . '" height="' . esc_attr($src[2]) . '" />';
    }
    
    return apply_filters('custom_image_markup', $html, $id, $caption, $title, $align, $url, $size, $alt);
}
add_filter('image_send_to_editor', 'custom_image_markup', 10, 8);

// Custom login logo
function custom_login_logo() {
    $logo_url = get_theme_mod('login_logo', get_template_directory_uri() . '/assets/images/logo.png');
    
    if ($logo_url) {
        echo '<style type="text/css">
            #login h1 a {
                background-image: url(' . esc_url($logo_url) . ');
                background-size: contain;
                background-repeat: no-repeat;
                width: 100%;
                height: 80px;
            }
        </style>';
    }
}
add_action('login_enqueue_scripts', 'custom_login_logo');

// Custom login logo URL
function custom_login_logo_url() {
    return home_url();
}
add_filter('login_headerurl', 'custom_login_logo_url');

// Custom login logo title
function custom_login_logo_url_title() {
    return get_bloginfo('name');
}
add_filter('login_headertitle', 'custom_login_logo_url_title');
```

## 🛠️ AJAX and REST API Integration

### 1. AJAX Implementation

```php
<?php
// includes/ajax.php

class CustomAjax {
    
    public function __construct() {
        // For logged-in users
        add_action('wp_ajax_load_more_posts', [$this, 'load_more_posts']);
        // For non-logged-in users
        add_action('wp_ajax_nopriv_load_more_posts', [$this, 'load_more_posts']);
        
        add_action('wp_ajax_portfolio_filter', [$this, 'portfolio_filter']);
        add_action('wp_ajax_nopriv_portfolio_filter', [$this, 'portfolio_filter']);
    }
    
    /**
     * Load more posts via AJAX
     */
    public function load_more_posts() {
        // Verify nonce
        if (!wp_verify_nonce($_POST['nonce'], 'custom_theme_nonce')) {
            wp_die('Security check failed');
        }
        
        $page = intval($_POST['page']);
        $posts_per_page = intval($_POST['posts_per_page']);
        
        $args = [
            'post_type' => 'post',
            'post_status' => 'publish',
            'posts_per_page' => $posts_per_page,
            'paged' => $page,
        ];
        
        $query = new WP_Query($args);
        
        if ($query->have_posts()) {
            ob_start();
            
            while ($query->have_posts()) {
                $query->the_post();
                get_template_part('template-parts/content', 'post');
            }
            
            $html = ob_get_clean();
            
            wp_send_json_success([
                'html' => $html,
                'max_pages' => $query->max_num_pages,
                'current_page' => $page,
            ]);
        } else {
            wp_send_json_error(['message' => esc_html__('No more posts found.', 'custom-theme')]);
        }
        
        wp_reset_postdata();
        wp_die();
    }
    
    /**
     * Portfolio filter via AJAX
     */
    public function portfolio_filter() {
        if (!wp_verify_nonce($_POST['nonce'], 'custom_theme_nonce')) {
            wp_die('Security check failed');
        }
        
        $category = sanitize_text_field($_POST['category']);
        $page = intval($_POST['page']);
        
        $args = [
            'post_type' => 'portfolio',
            'post_status' => 'publish',
            'posts_per_page' => 12,
            'paged' => $page,
        ];
        
        if ($category && $category !== 'all') {
            $args['tax_query'] = [
                [
                    'taxonomy' => 'portfolio_category',
                    'field' => 'slug',
                    'terms' => $category,
                ],
            ];
        }
        
        $query = new WP_Query($args);
        
        if ($query->have_posts()) {
            ob_start();
            
            while ($query->have_posts()) {
                $query->the_post();
                get_template_part('template-parts/content', 'portfolio');
            }
            
            $html = ob_get_clean();
            
            wp_send_json_success([
                'html' => $html,
                'found_posts' => $query->found_posts,
                'max_pages' => $query->max_num_pages,
            ]);
        } else {
            wp_send_json_error(['message' => esc_html__('No portfolio items found.', 'custom-theme')]);
        }
        
        wp_reset_postdata();
        wp_die();
    }
}

new CustomAjax();
```

```javascript
// assets/js/ajax.js
(function($) {
    'use strict';

    const CustomThemeAjax = {
        init: function() {
            this.loadMorePosts();
            this.portfolioFilter();
        },

        loadMorePosts: function() {
            let page = 2;
            const $loadMoreBtn = $('.load-more-posts');
            const $postsContainer = $('.posts-container');

            $loadMoreBtn.on('click', function(e) {
                e.preventDefault();
                
                const $btn = $(this);
                $btn.text(customTheme.strings.loading).prop('disabled', true);

                $.ajax({
                    url: customTheme.ajaxurl,
                    type: 'POST',
                    data: {
                        action: 'load_more_posts',
                        page: page,
                        posts_per_page: 6,
                        nonce: customTheme.nonce
                    },
                    success: function(response) {
                        if (response.success) {
                            $postsContainer.append(response.data.html);
                            page++;
                            
                            if (page > response.data.max_pages) {
                                $btn.hide();
                            } else {
                                $btn.text('Load More').prop('disabled', false);
                            }
                        } else {
                            $btn.text('No More Posts').prop('disabled', true);
                        }
                    },
                    error: function() {
                        alert(customTheme.strings.error);
                        $btn.text('Load More').prop('disabled', false);
                    }
                });
            });
        },

        portfolioFilter: function() {
            const $filterBtns = $('.portfolio-filter button');
            const $portfolioContainer = $('.portfolio-container');
            let currentCategory = 'all';

            $filterBtns.on('click', function(e) {
                e.preventDefault();
                
                const $btn = $(this);
                const category = $btn.data('category');
                
                if (category === currentCategory) return;
                
                currentCategory = category;
                $filterBtns.removeClass('active');
                $btn.addClass('active');
                
                $portfolioContainer.html('<div class="loading">Loading...</div>');

                $.ajax({
                    url: customTheme.ajaxurl,
                    type: 'POST',
                    data: {
                        action: 'portfolio_filter',
                        category: category,
                        page: 1,
                        nonce: customTheme.nonce
                    },
                    success: function(response) {
                        if (response.success) {
                            $portfolioContainer.html(response.data.html);
                        } else {
                            $portfolioContainer.html('<p>' + response.data.message + '</p>');
                        }
                    },
                    error: function() {
                        $portfolioContainer.html('<p>' + customTheme.strings.error + '</p>');
                    }
                });
            });
        }
    };

    $(document).ready(function() {
        CustomThemeAjax.init();
    });

})(jQuery);
```

## ⚠️ Common Pitfalls to Avoid

### 1. Security Issues
```php
// ❌ Bad - No sanitization
$value = $_POST['user_input'];
update_option('my_option', $value);

// ✅ Good - Proper sanitization
$value = sanitize_text_field($_POST['user_input']);
update_option('my_option', $value);

// ❌ Bad - No nonce verification
function handle_form_submission() {
    if (isset($_POST['submit'])) {
        // Process form
    }
}

// ✅ Good - Nonce verification
function handle_form_submission() {
    if (isset($_POST['submit']) && wp_verify_nonce($_POST['_wpnonce'], 'form_action')) {
        // Process form
    }
}
```

### 2. Performance Issues
```php
// ❌ Bad - Query inside loop
while (have_posts()) : the_post();
    $related_posts = get_posts(['post_type' => 'related']);
    // Display related posts
endwhile;

// ✅ Good - Query outside loop
$related_posts = get_posts(['post_type' => 'related']);
while (have_posts()) : the_post();
    // Display post and related posts
endwhile;
```

## 📊 Performance Optimization

### 1. Query Optimization
```php
// Efficient meta queries
$args = [
    'post_type' => 'portfolio',
    'meta_query' => [
        'relation' => 'AND',
        [
            'key' => '_portfolio_featured',
            'value' => '1',
            'compare' => '='
        ],
        [
            'key' => '_portfolio_client',
            'value' => '',
            'compare' => '!='
        ]
    ]
];

// Use get_posts for simple queries
$featured_posts = get_posts([
    'post_type' => 'portfolio',
    'numberposts' => 3,
    'meta_key' => '_portfolio_featured',
    'meta_value' => '1'
]);
```

### 2. Caching Implementation
```php
// Object caching
function get_portfolio_items($category = '') {
    $cache_key = 'portfolio_items_' . md5($category);
    $items = wp_cache_get($cache_key, 'portfolio');
    
    if (false === $items) {
        $args = [
            'post_type' => 'portfolio',
            'posts_per_page' => -1,
        ];
        
        if ($category) {
            $args['tax_query'] = [
                [
                    'taxonomy' => 'portfolio_category',
                    'field' => 'slug',
                    'terms' => $category,
                ]
            ];
        }
        
        $items = get_posts($args);
        wp_cache_set($cache_key, $items, 'portfolio', HOUR_IN_SECONDS);
    }
    
    return $items;
}
```

## 🧪 Testing & Debugging

### 1. Debug Functions
```php
// Debug helper functions
function debug_log($data) {
    if (WP_DEBUG && WP_DEBUG_LOG) {
        error_log(print_r($data, true));
    }
}

function debug_query($query = null) {
    global $wp_query;
    $query = $query ?: $wp_query;
    
    echo '<pre>';
    echo 'SQL: ' . $query->request . "\n\n";
    echo 'Query Vars: ';
    print_r($query->query_vars);
    echo '</pre>';
}

// Usage in templates
if (current_user_can('administrator')) {
    debug_query();
}
```

## 📋 Code Review Checklist

- [ ] All user inputs are properly sanitized
- [ ] Nonce verification implemented for forms
- [ ] Database queries are optimized
- [ ] Proper escaping for output
- [ ] Translation functions used for all strings
- [ ] Hooks and filters properly implemented
- [ ] Performance considerations addressed
- [ ] Error handling in place
- [ ] Security best practices followed
- [ ] Code follows WordPress coding standards

Remember: WordPress development requires attention to security, performance, and following WordPress coding standards. Always sanitize inputs, escape outputs, and use WordPress APIs appropriately.