# Bootstrap Best Practices

Comprehensive guide for building responsive, mobile-first web applications using Bootstrap 5's utility-first CSS framework and component system.

## 📚 Official Documentation
- [Bootstrap Documentation](https://getbootstrap.com/docs/5.3/getting-started/introduction/)
- [Bootstrap Components](https://getbootstrap.com/docs/5.3/components/accordion/)
- [Bootstrap Utilities](https://getbootstrap.com/docs/5.3/utilities/api/)
- [Bootstrap Icons](https://icons.getbootstrap.com/)

## 🏗️ Project Setup

### Installation Methods
```bash
# Via NPM
npm install bootstrap

# Via CDN (for quick prototyping)
# Add to HTML head:
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

# With Sass customization
npm install bootstrap sass
```

### Project Structure
```
src/
├── scss/
│   ├── custom.scss             # Custom Bootstrap variables
│   ├── components/
│   │   ├── _navbar.scss        # Component-specific styles
│   │   ├── _cards.scss
│   │   └── _buttons.scss
│   └── main.scss               # Main stylesheet
├── js/
│   ├── components/
│   │   ├── navbar.js           # Component interactions
│   │   ├── modal.js
│   │   └── forms.js
│   └── main.js                 # Main JavaScript file
├── pages/
│   ├── index.html
│   ├── about.html
│   └── contact.html
└── assets/
    ├── images/
    └── icons/
```

## 🎯 Core Best Practices

### 1. Custom Bootstrap Setup

```scss
// scss/custom.scss
// Custom variables before Bootstrap import
$primary: #007bff;
$secondary: #6c757d;
$success: #28a745;
$info: #17a2b8;
$warning: #ffc107;
$danger: #dc3545;
$light: #f8f9fa;
$dark: #343a40;

// Custom spacing
$spacer: 1rem;
$spacers: (
  0: 0,
  1: $spacer * .25,
  2: $spacer * .5,
  3: $spacer,
  4: $spacer * 1.5,
  5: $spacer * 3,
  6: $spacer * 4,
  7: $spacer * 5
);

// Custom breakpoints
$grid-breakpoints: (
  xs: 0,
  sm: 576px,
  md: 768px,
  lg: 992px,
  xl: 1200px,
  xxl: 1400px
);

// Import Bootstrap
@import "~bootstrap/scss/bootstrap";

// Custom component styles
.btn-custom {
  @include button-variant($primary, $primary);
  border-radius: 0.5rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.card-hover {
  transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  }
}
```

### 2. Responsive Layout Patterns

```html
<!-- Responsive Grid Layout -->
<div class="container-fluid">
  <div class="row">
    <!-- Sidebar -->
    <nav class="col-lg-3 col-md-4 d-md-block bg-light sidebar collapse" id="sidebarMenu">
      <div class="position-sticky pt-3">
        <ul class="nav flex-column">
          <li class="nav-item">
            <a class="nav-link active" href="#dashboard">
              <i class="bi bi-house-door"></i>
              Dashboard
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="#orders">
              <i class="bi bi-file-earmark"></i>
              Orders
            </a>
          </li>
        </ul>
      </div>
    </nav>

    <!-- Main content -->
    <main class="col-lg-9 ms-sm-auto col-md-8 px-md-4">
      <div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
        <h1 class="h2">Dashboard</h1>
        <div class="btn-toolbar mb-2 mb-md-0">
          <div class="btn-group me-2">
            <button type="button" class="btn btn-sm btn-outline-secondary">Share</button>
            <button type="button" class="btn btn-sm btn-outline-secondary">Export</button>
          </div>
        </div>
      </div>

      <!-- Dashboard content -->
      <div class="row g-3">
        <div class="col-xl-3 col-md-6">
          <div class="card card-hover h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between">
                <div>
                  <p class="card-text text-muted">Total Sales</p>
                  <h3 class="card-title">$12,426</h3>
                </div>
                <div class="align-self-center">
                  <i class="bi bi-currency-dollar fs-1 text-primary"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="col-xl-3 col-md-6">
          <div class="card card-hover h-100">
            <div class="card-body">
              <div class="d-flex justify-content-between">
                <div>
                  <p class="card-text text-muted">Orders</p>
                  <h3 class="card-title">1,245</h3>
                </div>
                <div class="align-self-center">
                  <i class="bi bi-bag-check fs-1 text-success"></i>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</div>
```

### 3. Advanced Component Patterns

```html
<!-- Advanced Modal with Form -->
<div class="modal fade" id="userModal" tabindex="-1" aria-labelledby="userModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header bg-primary text-white">
        <h5 class="modal-title" id="userModalLabel">
          <i class="bi bi-person-plus me-2"></i>
          Add New User
        </h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      
      <form id="userForm" class="needs-validation" novalidate>
        <div class="modal-body">
          <div class="row g-3">
            <div class="col-md-6">
              <label for="firstName" class="form-label">First Name</label>
              <input type="text" class="form-control" id="firstName" required>
              <div class="invalid-feedback">
                Please provide a valid first name.
              </div>
            </div>
            
            <div class="col-md-6">
              <label for="lastName" class="form-label">Last Name</label>
              <input type="text" class="form-control" id="lastName" required>
              <div class="invalid-feedback">
                Please provide a valid last name.
              </div>
            </div>
            
            <div class="col-12">
              <label for="email" class="form-label">Email</label>
              <div class="input-group has-validation">
                <span class="input-group-text">@</span>
                <input type="email" class="form-control" id="email" required>
                <div class="invalid-feedback">
                  Please provide a valid email address.
                </div>
              </div>
            </div>
            
            <div class="col-md-6">
              <label for="role" class="form-label">Role</label>
              <select class="form-select" id="role" required>
                <option selected disabled value="">Choose...</option>
                <option value="admin">Administrator</option>
                <option value="user">User</option>
                <option value="moderator">Moderator</option>
              </select>
              <div class="invalid-feedback">
                Please select a valid role.
              </div>
            </div>
            
            <div class="col-md-6">
              <label for="department" class="form-label">Department</label>
              <input type="text" class="form-control" id="department" required>
              <div class="invalid-feedback">
                Please provide a department.
              </div>
            </div>
            
            <div class="col-12">
              <div class="form-check">
                <input class="form-check-input" type="checkbox" value="" id="sendWelcomeEmail">
                <label class="form-check-label" for="sendWelcomeEmail">
                  Send welcome email to user
                </label>
              </div>
            </div>
          </div>
        </div>
        
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
            <i class="bi bi-x-circle me-1"></i>
            Cancel
          </button>
          <button type="submit" class="btn btn-primary">
            <i class="bi bi-check-circle me-1"></i>
            Save User
          </button>
        </div>
      </form>
    </div>
  </div>
</div>
```

### 4. Interactive JavaScript Components

```javascript
// js/components/forms.js
class BootstrapFormValidator {
  constructor() {
    this.initValidation();
    this.initTooltips();
  }

  initValidation() {
    // Bootstrap form validation
    const forms = document.querySelectorAll('.needs-validation');
    
    Array.from(forms).forEach(form => {
      form.addEventListener('submit', event => {
        if (!form.checkValidity()) {
          event.preventDefault();
          event.stopPropagation();
        } else {
          event.preventDefault();
          this.handleFormSubmit(form);
        }
        form.classList.add('was-validated');
      });
    });
  }

  initTooltips() {
    // Initialize Bootstrap tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(tooltipTriggerEl => {
      return new bootstrap.Tooltip(tooltipTriggerEl);
    });
  }

  async handleFormSubmit(form) {
    const formData = new FormData(form);
    const data = Object.fromEntries(formData.entries());
    
    try {
      this.showSpinner(form);
      
      const response = await fetch(form.action || '/api/submit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        throw new Error('Network response was not ok');
      }

      const result = await response.json();
      this.showAlert('success', 'Form submitted successfully!');
      form.reset();
      form.classList.remove('was-validated');
      
      // Close modal if form is in modal
      const modal = form.closest('.modal');
      if (modal) {
        bootstrap.Modal.getInstance(modal).hide();
      }
      
    } catch (error) {
      console.error('Error:', error);
      this.showAlert('danger', 'Error submitting form. Please try again.');
    } finally {
      this.hideSpinner(form);
    }
  }

  showSpinner(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.innerHTML = `
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
        Processing...
      `;
    }
  }

  hideSpinner(form) {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = submitBtn.getAttribute('data-original-text') || 'Submit';
    }
  }

  showAlert(type, message) {
    const alertContainer = document.getElementById('alert-container') || document.body;
    const alertId = 'alert-' + Date.now();
    
    const alert = document.createElement('div');
    alert.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 end-0 m-3`;
    alert.style.zIndex = '9999';
    alert.id = alertId;
    alert.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    alertContainer.appendChild(alert);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      const alertElement = document.getElementById(alertId);
      if (alertElement) {
        bootstrap.Alert.getInstance(alertElement).close();
      }
    }, 5000);
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  new BootstrapFormValidator();
});
```

## 🛠️ Useful Utility Classes & Components

### Custom Utility Classes
```scss
// scss/components/_utilities.scss
.shadow-hover {
  transition: box-shadow 0.15s ease-in-out;
  
  &:hover {
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
  }
}

.text-gradient {
  background: linear-gradient(45deg, var(--bs-primary), var(--bs-info));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.bg-glass {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.btn-gradient {
  background: linear-gradient(45deg, var(--bs-primary), var(--bs-info));
  border: none;
  color: white;
  
  &:hover {
    background: linear-gradient(45deg, darken($primary, 10%), darken($info, 10%));
    color: white;
  }
}

// Animation utilities
.animate-fade-in {
  animation: fadeIn 0.5s ease-in;
}

.animate-slide-up {
  animation: slideUp 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { 
    transform: translateY(20px);
    opacity: 0;
  }
  to { 
    transform: translateY(0);
    opacity: 1;
  }
}
```

### Advanced Data Table Component
```html
<div class="card">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="card-title mb-0">Users Management</h5>
    <div class="d-flex gap-2">
      <input type="search" class="form-control form-control-sm" placeholder="Search users..." id="searchInput">
      <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#userModal">
        <i class="bi bi-plus-circle me-1"></i>
        Add User
      </button>
    </div>
  </div>
  
  <div class="card-body p-0">
    <div class="table-responsive">
      <table class="table table-hover mb-0" id="usersTable">
        <thead class="table-dark">
          <tr>
            <th>
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="selectAll">
              </div>
            </th>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Department</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <div class="form-check">
                <input class="form-check-input row-checkbox" type="checkbox" value="1">
              </div>
            </td>
            <td>
              <div class="d-flex align-items-center">
                <img src="https://via.placeholder.com/32" class="rounded-circle me-2" alt="Avatar">
                <div>
                  <div class="fw-semibold">John Doe</div>
                  <small class="text-muted">ID: #001</small>
                </div>
              </div>
            </td>
            <td>john.doe@example.com</td>
            <td><span class="badge bg-primary">Administrator</span></td>
            <td>IT Department</td>
            <td><span class="badge bg-success">Active</span></td>
            <td>
              <div class="btn-group" role="group">
                <button type="button" class="btn btn-outline-primary btn-sm" title="Edit">
                  <i class="bi bi-pencil"></i>
                </button>
                <button type="button" class="btn btn-outline-danger btn-sm" title="Delete">
                  <i class="bi bi-trash"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
  
  <div class="card-footer d-flex justify-content-between align-items-center">
    <small class="text-muted">Showing 1 to 10 of 50 entries</small>
    <nav>
      <ul class="pagination pagination-sm mb-0">
        <li class="page-item disabled">
          <a class="page-link" href="#" tabindex="-1">Previous</a>
        </li>
        <li class="page-item active"><a class="page-link" href="#">1</a></li>
        <li class="page-item"><a class="page-link" href="#">2</a></li>
        <li class="page-item"><a class="page-link" href="#">3</a></li>
        <li class="page-item">
          <a class="page-link" href="#">Next</a>
        </li>
      </ul>
    </nav>
  </div>
</div>
```

## ⚠️ Common Pitfalls to Avoid

### 1. Over-relying on !important
```scss
// ❌ Bad - Overusing !important
.my-custom-class {
  color: red !important;
  background: blue !important;
}

// ✅ Good - Use CSS specificity properly
.card .my-custom-class {
  color: red;
  background: blue;
}
```

### 2. Not Using Semantic HTML
```html
<!-- ❌ Bad - Non-semantic markup -->
<div class="btn btn-primary" onclick="submitForm()">Submit</div>

<!-- ✅ Good - Semantic button element -->
<button type="submit" class="btn btn-primary">Submit</button>
```

### 3. Ignoring Mobile-First Design
```scss
// ❌ Bad - Desktop-first approach
.my-component {
  width: 100%;
  
  @media (max-width: 768px) {
    width: 50%;
  }
}

// ✅ Good - Mobile-first approach
.my-component {
  width: 50%;
  
  @include media-breakpoint-up(md) {
    width: 100%;
  }
}
```

## 📊 Performance Optimization

### 1. Selective Bootstrap Import
```scss
// Import only needed Bootstrap components
@import "~bootstrap/scss/functions";
@import "~bootstrap/scss/variables";
@import "~bootstrap/scss/mixins";

// Layout & grid
@import "~bootstrap/scss/containers";
@import "~bootstrap/scss/grid";

// Components
@import "~bootstrap/scss/buttons";
@import "~bootstrap/scss/forms";
@import "~bootstrap/scss/card";
@import "~bootstrap/scss/navbar";

// Utilities (selective)
@import "~bootstrap/scss/utilities/api";
```

### 2. Optimize JavaScript Bundle
```javascript
// Import only needed Bootstrap JS components
import { Modal } from 'bootstrap/js/dist/modal';
import { Tooltip } from 'bootstrap/js/dist/tooltip';
import { Collapse } from 'bootstrap/js/dist/collapse';

// Initialize only what you need
document.addEventListener('DOMContentLoaded', () => {
  // Initialize tooltips
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltips.forEach(tooltip => new Tooltip(tooltip));
  
  // Initialize modals
  const modals = document.querySelectorAll('.modal');
  modals.forEach(modal => new Modal(modal));
});
```

## 🧪 Testing Strategies

### Accessibility Testing
```javascript
// Test for Bootstrap accessibility features
describe('Bootstrap Accessibility', () => {
  test('buttons have proper ARIA attributes', () => {
    const button = document.querySelector('.btn[data-bs-toggle="modal"]');
    expect(button).toHaveAttribute('aria-expanded');
    expect(button).toHaveAttribute('aria-controls');
  });
  
  test('form inputs have associated labels', () => {
    const inputs = document.querySelectorAll('input[type="text"], input[type="email"]');
    inputs.forEach(input => {
      const label = document.querySelector(`label[for="${input.id}"]`);
      expect(label).toBeTruthy();
    });
  });
});
```

## 🚀 Production Best Practices

### 1. CSS Optimization
```javascript
// webpack.config.js
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');

module.exports = {
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'postcss-loader',
          'sass-loader'
        ]
      }
    ]
  },
  optimization: {
    minimizer: [
      new CssMinimizerPlugin()
    ]
  }
};
```

### 2. RTL Support
```scss
// RTL support for Bootstrap
[dir="rtl"] {
  .me-2 { margin-left: 0.5rem !important; margin-right: 0 !important; }
  .ms-2 { margin-right: 0.5rem !important; margin-left: 0 !important; }
  .pe-3 { padding-left: 1rem !important; padding-right: 0 !important; }
  .ps-3 { padding-right: 1rem !important; padding-left: 0 !important; }
}
```

## 📈 Advanced Bootstrap Patterns

### Theme Switching
```javascript
class ThemeManager {
  constructor() {
    this.currentTheme = localStorage.getItem('theme') || 'light';
    this.init();
  }

  init() {
    this.applyTheme(this.currentTheme);
    this.setupToggleButton();
  }

  applyTheme(theme) {
    document.documentElement.setAttribute('data-bs-theme', theme);
    localStorage.setItem('theme', theme);
    this.currentTheme = theme;
  }

  toggleTheme() {
    const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
    this.applyTheme(newTheme);
    this.updateToggleButton();
  }

  setupToggleButton() {
    const toggleBtn = document.getElementById('themeToggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => this.toggleTheme());
      this.updateToggleButton();
    }
  }

  updateToggleButton() {
    const toggleBtn = document.getElementById('themeToggle');
    if (toggleBtn) {
      const icon = toggleBtn.querySelector('i');
      if (this.currentTheme === 'light') {
        icon.className = 'bi bi-moon-fill';
      } else {
        icon.className = 'bi bi-sun-fill';
      }
    }
  }
}

new ThemeManager();
```

## 🔒 Security Best Practices

- Always validate form inputs on both client and server side
- Use HTTPS for all production deployments
- Implement proper CSRF protection
- Sanitize user inputs before displaying
- Use Bootstrap's built-in form validation features

## 📋 Code Review Checklist

- [ ] Responsive design works across all breakpoints
- [ ] Accessibility attributes are properly implemented
- [ ] Custom CSS follows Bootstrap conventions
- [ ] JavaScript components are properly initialized
- [ ] Forms include proper validation
- [ ] Performance optimizations applied
- [ ] Cross-browser compatibility tested
- [ ] Dark/light theme support if needed

Remember: Bootstrap provides a solid foundation for rapid development. Focus on customization through Sass variables and mixins rather than overriding with CSS. Always prioritize semantic HTML and accessibility.