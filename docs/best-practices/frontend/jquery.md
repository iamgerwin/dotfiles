# jQuery Best Practices

## Official Documentation
- **jQuery Documentation**: https://api.jquery.com
- **jQuery Learning Center**: https://learn.jquery.com
- **jQuery UI**: https://jqueryui.com
- **jQuery Mobile**: https://jquerymobile.com

## Project Structure

```
project-root/
├── assets/
│   ├── css/
│   │   ├── main.css
│   │   └── components/
│   ├── js/
│   │   ├── vendor/
│   │   │   ├── jquery-3.7.1.min.js
│   │   │   └── jquery-ui.min.js
│   │   ├── modules/
│   │   │   ├── auth.js
│   │   │   ├── forms.js
│   │   │   └── navigation.js
│   │   ├── plugins/
│   │   │   └── custom-plugins.js
│   │   ├── utils/
│   │   │   └── helpers.js
│   │   └── main.js
│   └── images/
├── pages/
│   ├── index.html
│   └── about.html
├── api/
└── index.html
```

## Core Best Practices

### 1. DOM Ready and Module Pattern

```javascript
// Modern module pattern with jQuery
(function($, window, document) {
    'use strict';
    
    // Module definition
    const App = {
        // Configuration
        config: {
            apiUrl: 'https://api.example.com',
            debug: true,
            animations: {
                duration: 300,
                easing: 'swing'
            }
        },
        
        // Cache DOM elements
        cache: {
            $window: $(window),
            $document: $(document),
            $body: null,
            $header: null,
            $nav: null
        },
        
        // Initialize
        init: function() {
            this.cacheElements();
            this.bindEvents();
            this.initModules();
        },
        
        // Cache frequently used elements
        cacheElements: function() {
            this.cache.$body = $('body');
            this.cache.$header = $('#header');
            this.cache.$nav = $('.navigation');
        },
        
        // Bind events using namespaces
        bindEvents: function() {
            this.cache.$document
                .on('click.app', '.js-toggle', this.handleToggle.bind(this))
                .on('submit.app', '.js-form', this.handleFormSubmit.bind(this));
            
            this.cache.$window
                .on('scroll.app', this.utils.throttle(this.handleScroll.bind(this), 100))
                .on('resize.app', this.utils.debounce(this.handleResize.bind(this), 250));
        },
        
        // Initialize modules
        initModules: function() {
            this.forms.init();
            this.navigation.init();
            this.lazyLoad.init();
        },
        
        // Event handlers
        handleToggle: function(e) {
            e.preventDefault();
            const $target = $(e.currentTarget);
            const targetId = $target.data('target');
            
            if (targetId) {
                $('#' + targetId).slideToggle(this.config.animations.duration);
            }
        },
        
        handleFormSubmit: function(e) {
            e.preventDefault();
            const $form = $(e.currentTarget);
            
            if (this.forms.validate($form)) {
                this.forms.submit($form);
            }
        },
        
        handleScroll: function() {
            const scrollTop = this.cache.$window.scrollTop();
            
            // Sticky header
            this.cache.$header.toggleClass('is-sticky', scrollTop > 100);
            
            // Back to top button
            $('.back-to-top').toggleClass('is-visible', scrollTop > 500);
        },
        
        handleResize: function() {
            // Handle responsive behaviors
            const width = this.cache.$window.width();
            
            if (width < 768) {
                this.navigation.enableMobile();
            } else {
                this.navigation.disableMobile();
            }
        }
    };
    
    // DOM ready
    $(function() {
        App.init();
        
        // Expose to global scope if needed
        window.App = App;
    });
    
})(jQuery, window, document);
```

### 2. Forms Module

```javascript
// forms.js - Form handling module
App.forms = (function($) {
    'use strict';
    
    const config = {
        selectors: {
            form: '.js-form',
            input: '.form-input',
            error: '.form-error',
            success: '.form-success'
        },
        classes: {
            loading: 'is-loading',
            error: 'has-error',
            success: 'has-success'
        }
    };
    
    // Initialize forms
    function init() {
        setupValidation();
        setupAjaxForms();
        setupCustomSelects();
        setupDatePickers();
    }
    
    // Setup validation
    function setupValidation() {
        // Add custom validation methods
        $.validator.addMethod('phone', function(value, element) {
            return this.optional(element) || /^[\d\s\-\+\(\)]+$/.test(value);
        }, 'Please enter a valid phone number');
        
        // Default validation settings
        $.validator.setDefaults({
            errorClass: 'form-error',
            validClass: 'form-valid',
            errorElement: 'span',
            errorPlacement: function(error, element) {
                if (element.parent('.input-group').length) {
                    error.insertAfter(element.parent());
                } else {
                    error.insertAfter(element);
                }
            },
            highlight: function(element) {
                $(element).closest('.form-group').addClass(config.classes.error);
            },
            unhighlight: function(element) {
                $(element).closest('.form-group').removeClass(config.classes.error);
            }
        });
    }
    
    // Setup AJAX form submission
    function setupAjaxForms() {
        $(config.selectors.form).each(function() {
            const $form = $(this);
            
            $form.validate({
                submitHandler: function(form) {
                    submit($(form));
                    return false;
                }
            });
        });
    }
    
    // Validate form
    function validate($form) {
        return $form.valid();
    }
    
    // Submit form via AJAX
    function submit($form) {
        const url = $form.attr('action');
        const method = $form.attr('method') || 'POST';
        const data = $form.serialize();
        
        // Show loading state
        $form.addClass(config.classes.loading);
        $form.find(':submit').prop('disabled', true);
        
        $.ajax({
            url: url,
            type: method,
            data: data,
            dataType: 'json'
        })
        .done(function(response) {
            handleSuccess($form, response);
        })
        .fail(function(xhr) {
            handleError($form, xhr);
        })
        .always(function() {
            $form.removeClass(config.classes.loading);
            $form.find(':submit').prop('disabled', false);
        });
    }
    
    // Handle successful submission
    function handleSuccess($form, response) {
        // Show success message
        const $success = $form.find(config.selectors.success);
        $success.text(response.message || 'Success!').fadeIn();
        
        // Reset form if needed
        if ($form.data('reset')) {
            $form[0].reset();
            $form.validate().resetForm();
        }
        
        // Trigger custom event
        $form.trigger('form:success', [response]);
    }
    
    // Handle submission error
    function handleError($form, xhr) {
        const response = xhr.responseJSON || {};
        const $error = $form.find(config.selectors.error);
        
        // Show error message
        $error.text(response.message || 'An error occurred').fadeIn();
        
        // Show field errors
        if (response.errors) {
            $.each(response.errors, function(field, messages) {
                const $field = $form.find('[name="' + field + '"]');
                const $group = $field.closest('.form-group');
                
                $group.addClass(config.classes.error);
                $group.find('.field-error').remove();
                $group.append('<span class="field-error">' + messages[0] + '</span>');
            });
        }
        
        // Trigger custom event
        $form.trigger('form:error', [response]);
    }
    
    // Setup custom select boxes
    function setupCustomSelects() {
        $('.js-select2').select2({
            theme: 'bootstrap4',
            placeholder: 'Select an option',
            allowClear: true
        });
    }
    
    // Setup date pickers
    function setupDatePickers() {
        $('.js-datepicker').datepicker({
            dateFormat: 'yy-mm-dd',
            changeMonth: true,
            changeYear: true,
            showButtonPanel: true
        });
    }
    
    // Public API
    return {
        init: init,
        validate: validate,
        submit: submit
    };
    
})(jQuery);
```

### 3. AJAX Best Practices

```javascript
// AJAX wrapper with proper error handling
App.api = (function($) {
    'use strict';
    
    const config = {
        baseUrl: 'https://api.example.com',
        timeout: 30000,
        headers: {
            'X-Requested-With': 'XMLHttpRequest'
        }
    };
    
    // Setup global AJAX settings
    $.ajaxSetup({
        timeout: config.timeout,
        headers: config.headers,
        beforeSend: function(xhr, settings) {
            // Add CSRF token if needed
            const token = $('meta[name="csrf-token"]').attr('content');
            if (token) {
                xhr.setRequestHeader('X-CSRF-Token', token);
            }
            
            // Add auth token if available
            const authToken = localStorage.getItem('authToken');
            if (authToken) {
                xhr.setRequestHeader('Authorization', 'Bearer ' + authToken);
            }
        }
    });
    
    // Generic request function
    function request(options) {
        const defaults = {
            url: config.baseUrl,
            dataType: 'json',
            contentType: 'application/json',
            cache: false
        };
        
        const settings = $.extend({}, defaults, options);
        
        // Convert data to JSON for POST/PUT/PATCH
        if (settings.data && typeof settings.data === 'object' && 
            ['POST', 'PUT', 'PATCH'].includes(settings.type)) {
            settings.data = JSON.stringify(settings.data);
        }
        
        return $.ajax(settings)
            .fail(function(xhr, status, error) {
                console.error('AJAX Error:', status, error);
                handleError(xhr);
            });
    }
    
    // GET request
    function get(url, params) {
        return request({
            type: 'GET',
            url: url,
            data: params
        });
    }
    
    // POST request
    function post(url, data) {
        return request({
            type: 'POST',
            url: url,
            data: data
        });
    }
    
    // PUT request
    function put(url, data) {
        return request({
            type: 'PUT',
            url: url,
            data: data
        });
    }
    
    // DELETE request
    function del(url) {
        return request({
            type: 'DELETE',
            url: url
        });
    }
    
    // Handle errors globally
    function handleError(xhr) {
        if (xhr.status === 401) {
            // Unauthorized - redirect to login
            window.location.href = '/login';
        } else if (xhr.status === 403) {
            // Forbidden
            App.notifications.error('You do not have permission to perform this action');
        } else if (xhr.status === 404) {
            // Not found
            App.notifications.error('The requested resource was not found');
        } else if (xhr.status >= 500) {
            // Server error
            App.notifications.error('A server error occurred. Please try again later');
        }
    }
    
    // Public API
    return {
        get: get,
        post: post,
        put: put,
        delete: del,
        request: request
    };
    
})(jQuery);
```

### 4. Plugin Development

```javascript
// Custom jQuery plugin template
(function($) {
    'use strict';
    
    // Plugin name and defaults
    const pluginName = 'customPlugin';
    const defaults = {
        animationSpeed: 300,
        cssClass: 'active',
        onInit: null,
        onChange: null,
        onDestroy: null
    };
    
    // Plugin constructor
    function Plugin(element, options) {
        this.element = element;
        this.$element = $(element);
        this.options = $.extend({}, defaults, options);
        this._defaults = defaults;
        this._name = pluginName;
        
        this.init();
    }
    
    // Plugin prototype
    $.extend(Plugin.prototype, {
        init: function() {
            this.buildCache();
            this.bindEvents();
            
            // Trigger init callback
            if (typeof this.options.onInit === 'function') {
                this.options.onInit.call(this.element);
            }
        },
        
        buildCache: function() {
            this.$window = $(window);
            this.$items = this.$element.find('.item');
        },
        
        bindEvents: function() {
            const self = this;
            
            this.$element.on('click.' + this._name, '.trigger', function(e) {
                e.preventDefault();
                self.toggle($(this));
            });
        },
        
        toggle: function($trigger) {
            const $target = $trigger.next('.content');
            
            $target.slideToggle(this.options.animationSpeed);
            $trigger.toggleClass(this.options.cssClass);
            
            // Trigger change callback
            if (typeof this.options.onChange === 'function') {
                this.options.onChange.call(this.element, $trigger, $target);
            }
        },
        
        destroy: function() {
            this.unbindEvents();
            this.$element.removeData('plugin_' + this._name);
            
            // Trigger destroy callback
            if (typeof this.options.onDestroy === 'function') {
                this.options.onDestroy.call(this.element);
            }
        },
        
        unbindEvents: function() {
            this.$element.off('.' + this._name);
        }
    });
    
    // Plugin wrapper
    $.fn[pluginName] = function(options) {
        return this.each(function() {
            if (!$.data(this, 'plugin_' + pluginName)) {
                $.data(this, 'plugin_' + pluginName, new Plugin(this, options));
            }
        });
    };
    
})(jQuery);

// Usage
$('.accordion').customPlugin({
    animationSpeed: 500,
    onChange: function($trigger, $target) {
        console.log('Changed:', $trigger);
    }
});
```

### 5. Performance Optimization

```javascript
// Performance utilities
App.utils = (function($) {
    'use strict';
    
    // Debounce function
    function debounce(func, wait, immediate) {
        let timeout;
        return function() {
            const context = this;
            const args = arguments;
            const later = function() {
                timeout = null;
                if (!immediate) func.apply(context, args);
            };
            const callNow = immediate && !timeout;
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
            if (callNow) func.apply(context, args);
        };
    }
    
    // Throttle function
    function throttle(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(function() {
                    inThrottle = false;
                }, limit);
            }
        };
    }
    
    // Lazy load images
    function lazyLoadImages() {
        const $images = $('img[data-src]');
        
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver(function(entries) {
                entries.forEach(function(entry) {
                    if (entry.isIntersecting) {
                        const $img = $(entry.target);
                        $img.attr('src', $img.data('src'));
                        $img.removeAttr('data-src');
                        imageObserver.unobserve(entry.target);
                    }
                });
            });
            
            $images.each(function() {
                imageObserver.observe(this);
            });
        } else {
            // Fallback for older browsers
            $images.each(function() {
                const $img = $(this);
                $img.attr('src', $img.data('src'));
                $img.removeAttr('data-src');
            });
        }
    }
    
    // Efficient event delegation
    function setupEventDelegation() {
        // Use single delegated handler instead of multiple individual handlers
        $(document)
            .on('click', '[data-action]', function(e) {
                e.preventDefault();
                const action = $(this).data('action');
                
                switch(action) {
                    case 'toggle':
                        handleToggle($(this));
                        break;
                    case 'submit':
                        handleSubmit($(this));
                        break;
                    case 'delete':
                        handleDelete($(this));
                        break;
                }
            });
    }
    
    // Cache selectors
    const selectorCache = {};
    
    function getElement(selector) {
        if (!selectorCache[selector]) {
            selectorCache[selector] = $(selector);
        }
        return selectorCache[selector];
    }
    
    // Batch DOM updates
    function batchUpdate(updates) {
        const fragment = document.createDocumentFragment();
        
        updates.forEach(function(update) {
            const element = document.createElement(update.tag);
            element.textContent = update.text;
            element.className = update.class;
            fragment.appendChild(element);
        });
        
        document.getElementById('container').appendChild(fragment);
    }
    
    return {
        debounce: debounce,
        throttle: throttle,
        lazyLoadImages: lazyLoadImages,
        setupEventDelegation: setupEventDelegation,
        getElement: getElement,
        batchUpdate: batchUpdate
    };
    
})(jQuery);
```

### 6. Common Patterns

```javascript
// Namespace pattern
var MyApp = MyApp || {};

MyApp.utils = {
    formatCurrency: function(amount) {
        return '$' + parseFloat(amount).toFixed(2);
    }
};

// Singleton pattern
MyApp.cart = (function($) {
    let instance;
    
    function init() {
        const items = [];
        
        return {
            addItem: function(item) {
                items.push(item);
                this.updateUI();
            },
            
            removeItem: function(id) {
                const index = items.findIndex(item => item.id === id);
                if (index > -1) {
                    items.splice(index, 1);
                    this.updateUI();
                }
            },
            
            getItems: function() {
                return items;
            },
            
            getTotal: function() {
                return items.reduce((total, item) => total + item.price, 0);
            },
            
            updateUI: function() {
                $('.cart-count').text(items.length);
                $('.cart-total').text(MyApp.utils.formatCurrency(this.getTotal()));
            }
        };
    }
    
    return {
        getInstance: function() {
            if (!instance) {
                instance = init();
            }
            return instance;
        }
    };
})(jQuery);

// Observer pattern
MyApp.eventBus = (function($) {
    const events = {};
    
    return {
        on: function(event, callback) {
            if (!events[event]) {
                events[event] = [];
            }
            events[event].push(callback);
        },
        
        off: function(event, callback) {
            if (events[event]) {
                events[event] = events[event].filter(cb => cb !== callback);
            }
        },
        
        trigger: function(event, data) {
            if (events[event]) {
                events[event].forEach(callback => callback(data));
            }
        }
    };
})(jQuery);
```

### Common Pitfalls to Avoid

1. **Not caching jQuery selectors**
2. **Using inefficient selectors**
3. **Binding events inside loops**
4. **Not using event delegation**
5. **Manipulating DOM in loops**
6. **Not using namespaced events**
7. **Memory leaks from event handlers**
8. **Not checking if element exists**
9. **Using deprecated methods**
10. **Not optimizing animations**

### Useful jQuery Plugins

- **jQuery Validation**: Form validation
- **Select2**: Enhanced select boxes
- **DataTables**: Advanced tables
- **Slick**: Carousel/slider
- **Fancybox**: Lightbox
- **jQuery UI**: UI components
- **Isotope**: Filtering and sorting
- **Waypoints**: Scroll triggers
- **ScrollMagic**: Scroll animations
- **Chosen**: Select boxes
- **Dropzone**: File uploads
- **FullCalendar**: Calendar widget