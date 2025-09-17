# GitHub Pages Best Practices

## Overview

GitHub Pages is a static site hosting service that takes HTML, CSS, and JavaScript files straight from a repository on GitHub, optionally runs the files through a build process, and publishes a website. It's designed to host your personal, organization, or project pages directly from a GitHub repository.

## When to Use GitHub Pages

GitHub Pages is ideal for:
- **Documentation Sites**: Host project documentation with auto-updates
- **Portfolio Websites**: Showcase your work and projects
- **Landing Pages**: Create product or project landing pages
- **Blogs**: Jekyll-powered blogs with markdown support
- **Demo Sites**: Host live demos of web projects
- **Organization Sites**: Company or team websites
- **Static Web Applications**: SPAs with client-side routing

### When NOT to Use GitHub Pages
- Server-side processing required
- Database-driven applications
- E-commerce with payment processing
- Sites requiring authentication/authorization
- Large media files (>100MB files, >1GB repos)
- High-traffic commercial applications

## Core Concepts

### Repository Types

1. **User/Organization Pages**
   - Repository: `username.github.io` or `orgname.github.io`
   - URL: `https://username.github.io`
   - Source: Main branch root or `/docs` folder

2. **Project Pages**
   - Repository: Any repository name
   - URL: `https://username.github.io/repository-name`
   - Source: Any branch, typically `gh-pages`

### Publishing Sources

- **Root of main branch**: `/`
- **docs folder**: `/docs` on main branch
- **gh-pages branch**: Dedicated branch for Pages
- **GitHub Actions**: Custom workflow deployment

## Project Structure

### Basic Static Site
```
/
├── index.html          # Homepage
├── 404.html           # Custom 404 page
├── CNAME              # Custom domain configuration
├── _config.yml        # Jekyll configuration (optional)
├── .nojekyll          # Disable Jekyll processing
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
├── pages/
│   ├── about.html
│   └── contact.html
└── robots.txt         # SEO crawler instructions
```

### Jekyll Site Structure
```
/
├── _config.yml        # Jekyll configuration
├── _layouts/          # Page templates
│   ├── default.html
│   └── post.html
├── _includes/         # Reusable components
│   ├── header.html
│   └── footer.html
├── _posts/            # Blog posts
│   └── 2024-01-01-welcome.md
├── _data/             # Data files (YAML, JSON, CSV)
├── _sass/             # Sass partials
├── assets/            # Static files
├── _site/             # Generated site (gitignored)
├── index.md           # Homepage
├── about.md           # About page
├── Gemfile            # Ruby dependencies
└── Gemfile.lock
```

## Basic Setup

### 1. Enable GitHub Pages

#### Via Repository Settings
```bash
# Navigate to Settings > Pages
# Select source branch and folder
# Save
```

#### Via GitHub Actions
```yaml
# .github/workflows/pages.yml
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Build site
        run: |
          # Your build commands here
          npm ci
          npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### 2. Custom Domain Setup

#### DNS Configuration
```
# A Records (Apex domain)
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153

# CNAME Record (Subdomain)
www.example.com -> username.github.io
```

#### CNAME File
```
# Create CNAME file in repository root
echo "www.example.com" > CNAME
```

#### Enforce HTTPS
- Enable in Settings > Pages > Enforce HTTPS
- Wait for SSL certificate provisioning (up to 24 hours)

## Jekyll Configuration

### _config.yml
```yaml
# Site Settings
title: My Awesome Site
description: A description of my site
url: "https://username.github.io"
baseurl: "/repository-name"  # For project pages
author:
  name: Your Name
  email: your-email@example.com

# Build Settings
theme: minima  # Or remote_theme for GitHub Pages themes
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-paginate
  - jemoji

# Pagination
paginate: 10
paginate_path: "/blog/page:num/"

# Markdown
markdown: kramdown
kramdown:
  input: GFM
  syntax_highlighter: rouge

# Permalinks
permalink: /:year/:month/:day/:title/

# Collections
collections:
  projects:
    output: true
    permalink: /projects/:name/

# Defaults
defaults:
  - scope:
      path: ""
      type: "posts"
    values:
      layout: "post"
      author: "Your Name"

# Exclude from build
exclude:
  - Gemfile
  - Gemfile.lock
  - node_modules/
  - vendor/
  - .sass-cache/
  - README.md
  - package.json
  - package-lock.json

# Include in build
include:
  - .htaccess
  - _pages

# Sass
sass:
  sass_dir: _sass
  style: compressed
```

### Front Matter
```markdown
---
layout: post
title: "My First Post"
date: 2024-01-01 10:00:00 -0000
categories: [tutorial, web]
tags: [jekyll, github-pages]
author: John Doe
excerpt: "This is a custom excerpt for the post"
image: /assets/images/featured.jpg
published: true
---

Your content here...
```

## Static Site Generators

### Next.js Static Export
```json
// next.config.js
module.exports = {
  output: 'export',
  basePath: '/repository-name',
  assetPrefix: '/repository-name/',
  images: {
    unoptimized: true
  }
}
```

```yaml
# GitHub Actions deployment
- name: Build Next.js
  run: |
    npm ci
    npm run build
    touch out/.nojekyll  # Preserve _next folder

- uses: actions/upload-pages-artifact@v3
  with:
    path: ./out
```

### Vite Configuration
```javascript
// vite.config.js
export default {
  base: '/repository-name/',
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
}
```

### Hugo Deployment
```yaml
- name: Setup Hugo
  uses: peaceiris/actions-hugo@v2
  with:
    hugo-version: 'latest'
    extended: true

- name: Build
  run: hugo --minify

- uses: actions/upload-pages-artifact@v3
  with:
    path: ./public
```

## Single Page Applications (SPAs)

### 404 Fallback for Client Routing
```html
<!-- 404.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Redirecting...</title>
  <script>
    // Preserve the path and redirect to index
    sessionStorage.setItem('redirectPath', location.pathname);
    location.replace('/');
  </script>
</head>
<body>
  Redirecting...
</body>
</html>
```

```javascript
// In your main app file
const redirectPath = sessionStorage.getItem('redirectPath');
if (redirectPath) {
  sessionStorage.removeItem('redirectPath');
  window.history.replaceState(null, '', redirectPath);
}
```

### Hash Routing Alternative
```javascript
// React Router example
import { HashRouter } from 'react-router-dom';

function App() {
  return (
    <HashRouter>
      {/* Your routes */}
    </HashRouter>
  );
}
```

## Performance Optimization

### 1. Asset Optimization

```html
<!-- Preconnect to external domains -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="dns-prefetch" href="https://cdn.example.com">

<!-- Preload critical resources -->
<link rel="preload" href="/css/main.css" as="style">
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>

<!-- Lazy load images -->
<img src="placeholder.jpg" data-src="actual-image.jpg" loading="lazy" alt="Description">
```

### 2. Service Worker for Offline Support

```javascript
// sw.js
const CACHE_NAME = 'v1';
const urlsToCache = [
  '/',
  '/css/main.css',
  '/js/main.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

```html
<!-- Register service worker -->
<script>
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js');
}
</script>
```

### 3. Compression and Minification

```yaml
# Jekyll compression
# _layouts/compress.html
# Use jekyll-compress-html layout

---
layout: compress
---
<!DOCTYPE html>
<html>
...
</html>
```

### 4. CDN Usage

```html
<!-- Use CDN for common libraries -->
<script src="https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.prod.js"></script>

<!-- Fallback to local -->
<script>
window.Vue || document.write('<script src="/js/vue.min.js"><\/script>')
</script>
```

## SEO Best Practices

### 1. Meta Tags

```html
<!-- Basic SEO -->
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="Page description">
<meta name="keywords" content="keyword1, keyword2">
<meta name="author" content="Author Name">

<!-- Open Graph -->
<meta property="og:title" content="Page Title">
<meta property="og:description" content="Page description">
<meta property="og:image" content="https://example.com/image.jpg">
<meta property="og:url" content="https://example.com/page">
<meta property="og:type" content="website">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Page Title">
<meta name="twitter:description" content="Page description">
<meta name="twitter:image" content="https://example.com/image.jpg">

<!-- Canonical URL -->
<link rel="canonical" href="https://example.com/page">
```

### 2. Structured Data

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Site Name",
  "url": "https://example.com",
  "description": "Site description",
  "author": {
    "@type": "Person",
    "name": "Author Name"
  }
}
</script>
```

### 3. Sitemap Generation

```xml
<!-- sitemap.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-01</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/about</loc>
    <lastmod>2024-01-01</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>
```

### 4. robots.txt

```
# robots.txt
User-agent: *
Allow: /
Disallow: /api/
Disallow: /admin/

Sitemap: https://example.com/sitemap.xml
```

## Security Considerations

### 1. Content Security Policy

```html
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
  style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
  font-src 'self' https://fonts.gstatic.com;
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
">
```

### 2. Prevent Clickjacking

```html
<meta http-equiv="X-Frame-Options" content="SAMEORIGIN">
```

### 3. Environment Variables

```javascript
// Never expose secrets in client-side code!
// Use GitHub Actions to inject at build time

// Bad
const apiKey = 'sk-1234567890';  // Never do this!

// Good - Build-time injection
const apiEndpoint = process.env.NEXT_PUBLIC_API_URL;
```

### 4. Rate Limiting

```javascript
// Implement client-side rate limiting
const rateLimiter = {
  attempts: 0,
  resetTime: null,

  canMakeRequest() {
    const now = Date.now();
    if (this.resetTime && now < this.resetTime) {
      return this.attempts < 10;
    }
    this.attempts = 0;
    this.resetTime = now + 60000; // 1 minute
    return true;
  },

  recordAttempt() {
    this.attempts++;
  }
};
```

## Custom Themes

### Creating a Jekyll Theme

```ruby
# my-theme.gemspec
Gem::Specification.new do |spec|
  spec.name          = "my-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.summary       = "A custom Jekyll theme"

  spec.files         = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r{^(assets|_layouts|_includes|_sass|LICENSE|README)}i)
  end

  spec.add_runtime_dependency "jekyll", "~> 4.0"
  spec.add_development_dependency "bundler"
end
```

### Using Remote Themes

```yaml
# _config.yml
remote_theme: username/theme-repository

# Or with specific version
remote_theme: username/theme-repository@v1.0.0
```

## Analytics Integration

### Google Analytics 4

```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

### Privacy-Focused Analytics

```html
<!-- Plausible Analytics -->
<script defer data-domain="yourdomain.com" src="https://plausible.io/js/script.js"></script>

<!-- Umami Analytics -->
<script async defer data-website-id="xxxxx" src="https://analytics.example.com/script.js"></script>
```

## Forms and Dynamic Content

### Form Submission Options

#### 1. Formspree
```html
<form action="https://formspree.io/f/yourformid" method="POST">
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  <button type="submit">Send</button>
</form>
```

#### 2. Netlify Forms (Deploy to Netlify)
```html
<form name="contact" method="POST" data-netlify="true">
  <input type="hidden" name="form-name" value="contact">
  <input type="email" name="email" required>
  <textarea name="message" required></textarea>
  <button type="submit">Send</button>
</form>
```

#### 3. GitHub Issues API
```javascript
async function createIssue(title, body) {
  const response = await fetch('https://api.github.com/repos/username/repo/issues', {
    method: 'POST',
    headers: {
      'Authorization': 'token YOUR_PAT',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ title, body })
  });
  return response.json();
}
```

### Comments System

#### 1. Utterances (GitHub Issues)
```html
<script src="https://utteranc.es/client.js"
        repo="username/repository"
        issue-term="pathname"
        theme="github-light"
        crossorigin="anonymous"
        async>
</script>
```

#### 2. Giscus (GitHub Discussions)
```html
<script src="https://giscus.app/client.js"
        data-repo="username/repository"
        data-repo-id="REPO_ID"
        data-category="General"
        data-category-id="CATEGORY_ID"
        data-mapping="pathname"
        data-theme="light"
        crossorigin="anonymous"
        async>
</script>
```

## Common Issues and Solutions

### 1. Build Failures

**Problem**: Page build failure email
```
The page build failed for the `main` branch
```

**Solutions**:
- Check Jekyll syntax errors
- Validate _config.yml
- Review Gemfile dependencies
- Check for unsupported plugins

### 2. Custom Domain Issues

**Problem**: "GitHub Pages is temporarily down"
```
404 - There isn't a GitHub Pages site here
```

**Solutions**:
- Verify DNS propagation (24-48 hours)
- Check CNAME file exists and is correct
- Ensure repository is public
- Verify GitHub Pages is enabled

### 3. HTTPS Certificate Issues

**Problem**: Certificate not provisioning
```
Your site is ready to be published at http://...
```

**Solutions**:
- DNS must point to GitHub Pages IPs
- Wait up to 24 hours for provisioning
- Remove and re-add custom domain
- Check CAA records in DNS

### 4. Jekyll Build Errors

**Problem**: Liquid syntax error
```
Liquid Exception: Liquid syntax error
```

**Solutions**:
```liquid
<!-- Escape liquid tags -->
{% raw %}
{{ this won't be processed }}
{% endraw %}

<!-- Check variable existence -->
{% if page.title %}
  {{ page.title }}
{% endif %}
```

### 5. Path Issues with Project Pages

**Problem**: Assets not loading on project pages

**Solution**: Use relative URLs
```liquid
<!-- Use baseurl in config -->
<link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
<script src="{{ '/assets/js/main.js' | relative_url }}"></script>
<img src="{{ '/assets/images/logo.png' | relative_url }}" alt="Logo">
```

### 6. Large Files

**Problem**: File size limits (100MB)

**Solutions**:
- Use Git LFS for large files
- Host large files on CDN
- Compress images and assets
- Use external video hosting

## Monitoring and Maintenance

### 1. GitHub Pages Health Check

```ruby
# Check site health
require 'net/http'
require 'json'

url = 'https://api.github.com/repos/username/repo/pages'
uri = URI(url)
response = Net::HTTP.get(uri)
data = JSON.parse(response)

puts "Status: #{data['status']}"
puts "CNAME: #{data['cname']}"
puts "Custom 404: #{data['custom_404']}"
```

### 2. Automated Testing

```yaml
# .github/workflows/test-site.yml
name: Test Site

on:
  schedule:
    - cron: '0 0 * * *'  # Daily

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Check site availability
        run: |
          response=$(curl -s -o /dev/null -w "%{http_code}" https://example.com)
          if [ $response -ne 200 ]; then
            echo "Site is down! Status: $response"
            exit 1
          fi

      - name: Validate HTML
        run: |
          npm install -g html-validator-cli
          html-validator https://example.com
```

### 3. Broken Link Checker

```yaml
- name: Check for broken links
  uses: gaurav-nelson/github-action-markdown-link-check@v1
  with:
    use-quiet-mode: 'yes'
    config-file: '.markdown-link-check.json'
```

## Migration Strategies

### From WordPress
1. Export content as markdown using plugins
2. Convert to Jekyll posts format
3. Migrate media files
4. Set up redirects for old URLs

### From Other Static Hosts
```yaml
# Redirect old URLs
# _redirects or netlify.toml format
/old-path  /new-path  301
/blog/*    /posts/:splat  301
```

### URL Preservation
```yaml
# _config.yml
plugins:
  - jekyll-redirect-from

# In front matter
---
redirect_from:
  - /old-url/
  - /another-old-url/
---
```

## Cost Optimization

### Free Tier Limits
- **Bandwidth**: 100GB/month
- **Builds**: 10 builds/hour
- **Sites**: Unlimited public repositories
- **Storage**: 1GB recommended (soft limit)

### Optimization Strategies
1. Use CDN for large assets
2. Compress images (WebP format)
3. Minimize JavaScript bundles
4. Use GitHub Actions for complex builds
5. Cache static assets

## Advanced Configurations

### Multiple Environments

```yaml
# Development config: _config.dev.yml
url: "http://localhost:4000"
baseurl: ""

# Build command
jekyll build --config _config.yml,_config.dev.yml
```

### A/B Testing

```javascript
// Simple A/B test implementation
const variant = Math.random() > 0.5 ? 'A' : 'B';
document.body.classList.add(`variant-${variant}`);

// Track with analytics
gtag('event', 'experiment_view', {
  experiment_id: 'hero_test',
  variant_id: variant
});
```

### Progressive Web App

```json
// manifest.json
{
  "name": "My PWA",
  "short_name": "PWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
```

```html
<link rel="manifest" href="/manifest.json">
<meta name="theme-color" content="#000000">
```

## Best Practices Summary

### Do's
- ✅ Use relative URLs for assets
- ✅ Implement proper 404 pages
- ✅ Optimize images before committing
- ✅ Test locally with Jekyll serve
- ✅ Use GitHub Actions for complex builds
- ✅ Implement caching strategies
- ✅ Monitor site performance
- ✅ Keep dependencies updated

### Don'ts
- ❌ Store sensitive data in repositories
- ❌ Use absolute URLs for internal links
- ❌ Commit large binary files
- ❌ Ignore build warnings
- ❌ Use unsupported Jekyll plugins
- ❌ Forget mobile responsiveness
- ❌ Skip HTTPS enforcement
- ❌ Neglect SEO basics

## Additional Resources

- [GitHub Pages Documentation](https://docs.github.com/pages)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Supported Themes](https://pages.github.com/themes/)
- [Jekyll Plugins Whitelist](https://pages.github.com/versions/)
- [Custom Domain Troubleshooting](https://docs.github.com/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [GitHub Pages Examples](https://github.com/collections/github-pages-examples)
- [Static Site Generators List](https://jamstack.org/generators/)