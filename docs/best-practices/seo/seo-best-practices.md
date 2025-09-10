# SEO (Search Engine Optimization) Best Practices

## Overview
SEO is the practice of optimizing websites to improve their visibility and ranking in search engine results pages (SERPs). This guide covers technical SEO, content optimization, and modern SEO tools and techniques.

## Documentation & Resources
- [Google Search Central](https://developers.google.com/search)
- [Google Search Console](https://search.google.com/search-console)
- [Bing Webmaster Tools](https://www.bing.com/webmasters)
- [Schema.org](https://schema.org)
- [Web.dev SEO Guide](https://web.dev/learn/seo)

## Technical SEO

### 1. Site Architecture

```html
<!-- Proper URL structure -->
https://example.com/category/subcategory/product-name
https://example.com/blog/2024/01/article-title

<!-- XML Sitemap -->
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/page</loc>
    <lastmod>2024-01-15</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
</urlset>

<!-- Robots.txt -->
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml

# Specific crawler rules
User-agent: Googlebot
Crawl-delay: 0

User-agent: bingbot
Crawl-delay: 1
```

### 2. HTML Optimization

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- Basic Meta Tags -->
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Title Tag (50-60 characters) -->
  <title>Primary Keyword - Secondary Keyword | Brand Name</title>
  
  <!-- Meta Description (150-160 characters) -->
  <meta name="description" content="Compelling description with primary and secondary keywords that encourages clicks.">
  
  <!-- Canonical URL -->
  <link rel="canonical" href="https://example.com/page">
  
  <!-- Open Graph Tags -->
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Page description">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:url" content="https://example.com/page">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Site Name">
  
  <!-- Twitter Card Tags -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:site" content="@username">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Page description">
  <meta name="twitter:image" content="https://example.com/image.jpg">
  
  <!-- Alternate Languages -->
  <link rel="alternate" hreflang="en" href="https://example.com/page">
  <link rel="alternate" hreflang="es" href="https://example.com/es/page">
  <link rel="alternate" hreflang="x-default" href="https://example.com/page">
  
  <!-- Pagination -->
  <link rel="prev" href="https://example.com/page/1">
  <link rel="next" href="https://example.com/page/3">
</head>
<body>
  <!-- Proper Heading Hierarchy -->
  <h1>Main Page Title (One per page)</h1>
  <h2>Section Title</h2>
  <h3>Subsection Title</h3>
  
  <!-- Image Optimization -->
  <img src="image.webp" 
       alt="Descriptive alt text with keywords"
       width="800" 
       height="600"
       loading="lazy"
       srcset="image-400.webp 400w,
               image-800.webp 800w,
               image-1200.webp 1200w"
       sizes="(max-width: 600px) 400px,
              (max-width: 1200px) 800px,
              1200px">
  
  <!-- Internal Linking -->
  <a href="/related-page" title="Descriptive title">Anchor text with keywords</a>
</body>
</html>
```

### 3. Structured Data (Schema Markup)

```html
<!-- Organization Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Company Name",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://facebook.com/company",
    "https://twitter.com/company",
    "https://linkedin.com/company/company"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-234-567-8900",
    "contactType": "customer service"
  }
}
</script>

<!-- Product Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "image": ["https://example.com/photo1.jpg"],
  "description": "Product description",
  "sku": "12345",
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/product",
    "priceCurrency": "USD",
    "price": "99.99",
    "priceValidUntil": "2024-12-31",
    "availability": "https://schema.org/InStock"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.5",
    "reviewCount": "89"
  }
}
</script>

<!-- Article Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Article Title",
  "image": "https://example.com/image.jpg",
  "datePublished": "2024-01-15",
  "dateModified": "2024-01-16",
  "author": {
    "@type": "Person",
    "name": "Author Name"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Publisher Name",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "description": "Article description"
}
</script>

<!-- FAQ Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "What is SEO?",
    "acceptedAnswer": {
      "@type": "Answer",
      "text": "SEO stands for Search Engine Optimization..."
    }
  }]
}
</script>

<!-- Breadcrumb Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [{
    "@type": "ListItem",
    "position": 1,
    "name": "Home",
    "item": "https://example.com"
  },{
    "@type": "ListItem",
    "position": 2,
    "name": "Category",
    "item": "https://example.com/category"
  },{
    "@type": "ListItem",
    "position": 3,
    "name": "Current Page",
    "item": "https://example.com/category/page"
  }]
}
</script>
```

### 4. Core Web Vitals Optimization

```javascript
// Largest Contentful Paint (LCP) Optimization
// Target: < 2.5 seconds

// Preload critical resources
<link rel="preload" href="font.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="hero-image.webp" as="image">
<link rel="preload" href="critical.css" as="style">

// Use responsive images
const img = document.createElement('img');
img.srcset = `
  small.jpg 400w,
  medium.jpg 800w,
  large.jpg 1200w
`;
img.sizes = '(max-width: 400px) 400px, (max-width: 800px) 800px, 1200px';
img.loading = 'eager'; // For above-the-fold images

// First Input Delay (FID) Optimization
// Target: < 100 milliseconds

// Break up long tasks
function processLargeArray(array) {
  const chunkSize = 100;
  let index = 0;
  
  function processChunk() {
    const chunk = array.slice(index, index + chunkSize);
    chunk.forEach(item => processItem(item));
    index += chunkSize;
    
    if (index < array.length) {
      requestIdleCallback(processChunk);
    }
  }
  
  requestIdleCallback(processChunk);
}

// Use web workers for heavy computations
const worker = new Worker('processor.js');
worker.postMessage({ cmd: 'process', data: largeData });

// Cumulative Layout Shift (CLS) Optimization
// Target: < 0.1

// Reserve space for dynamic content
.image-container {
  aspect-ratio: 16 / 9;
  width: 100%;
  background: #f0f0f0;
}

// Avoid injecting content above existing content
const ad = document.createElement('div');
ad.style.minHeight = '250px'; // Reserve space
document.getElementById('ad-container').appendChild(ad);

// Use CSS transforms instead of layout properties
.animate {
  transform: translateX(100px); /* Good */
  /* left: 100px; */ /* Avoid */
}
```

### 5. JavaScript SEO

```javascript
// Server-Side Rendering (SSR) with Next.js
export async function getServerSideProps(context) {
  const data = await fetch('https://api.example.com/data');
  return {
    props: {
      data: await data.json()
    }
  };
}

// Static Site Generation (SSG)
export async function getStaticProps() {
  const posts = await fetchPosts();
  return {
    props: { posts },
    revalidate: 3600 // ISR: Revalidate every hour
  };
}

// Dynamic Rendering Detection
const userAgent = navigator.userAgent;
const isBot = /googlebot|bingbot|slurp|duckduckbot/i.test(userAgent);

if (isBot) {
  // Serve pre-rendered content
  window.location.href = '/static' + window.location.pathname;
}

// Lazy Loading with Intersection Observer
const imageObserver = new IntersectionObserver((entries, observer) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target;
      img.src = img.dataset.src;
      img.classList.add('loaded');
      observer.unobserve(img);
    }
  });
});

document.querySelectorAll('img[data-src]').forEach(img => {
  imageObserver.observe(img);
});
```

## Content Optimization

### 1. Keyword Research & Implementation

```javascript
// Keyword density checker
function calculateKeywordDensity(text, keyword) {
  const words = text.toLowerCase().split(/\s+/);
  const keywordCount = words.filter(word => 
    word.includes(keyword.toLowerCase())
  ).length;
  
  return (keywordCount / words.length) * 100;
}

// Optimal density: 1-2% for primary keywords
const density = calculateKeywordDensity(content, 'primary keyword');
if (density < 1) {
  console.warn('Keyword density too low');
} else if (density > 2) {
  console.warn('Potential keyword stuffing');
}
```

### 2. Content Structure

```html
<!-- Optimal content structure -->
<article>
  <h1>Primary Keyword in Title</h1>
  
  <!-- Introduction (50-100 words) -->
  <p>Introduction with primary keyword in first 100 words...</p>
  
  <!-- Table of Contents for long content -->
  <nav id="toc">
    <h2>Table of Contents</h2>
    <ol>
      <li><a href="#section1">Section 1</a></li>
      <li><a href="#section2">Section 2</a></li>
    </ol>
  </nav>
  
  <!-- Main Content Sections -->
  <section id="section1">
    <h2>Section with Secondary Keyword</h2>
    <p>Content with natural keyword placement...</p>
    
    <!-- Use lists for better readability -->
    <ul>
      <li>Point 1 with related keyword</li>
      <li>Point 2 with LSI keyword</li>
    </ul>
  </section>
  
  <!-- Rich Media -->
  <figure>
    <img src="relevant-image.jpg" alt="Descriptive alt with keyword">
    <figcaption>Image caption with context</figcaption>
  </figure>
  
  <!-- Internal/External Links -->
  <p>Learn more about <a href="/related-topic">related topic</a> or 
     visit <a href="https://authority-site.com" rel="noopener" target="_blank">
     authoritative source</a>.</p>
  
  <!-- Call to Action -->
  <section class="cta">
    <h2>Next Steps</h2>
    <p>Ready to get started? <a href="/contact">Contact us today</a>.</p>
  </section>
</article>
```

## SEO Tools Implementation

### 1. Google Search Console Integration

```javascript
// Verify ownership
<meta name="google-site-verification" content="verification-code">

// Submit sitemap programmatically
async function submitSitemap() {
  const response = await fetch(
    'https://www.google.com/ping?sitemap=https://example.com/sitemap.xml'
  );
  
  if (response.ok) {
    console.log('Sitemap submitted successfully');
  }
}

// Monitor indexing via API
const { google } = require('googleapis');
const searchconsole = google.searchconsole('v1');

async function getIndexingStatus() {
  const response = await searchconsole.urlInspection.index.inspect({
    siteUrl: 'https://example.com',
    inspectionUrl: 'https://example.com/page',
  });
  
  return response.data;
}
```

### 2. Analytics & Tracking

```javascript
// Google Analytics 4 with enhanced ecommerce
gtag('config', 'GA_MEASUREMENT_ID', {
  page_path: window.location.pathname,
  custom_dimensions: {
    user_type: 'member',
    content_category: 'blog'
  }
});

// Track search queries
gtag('event', 'search', {
  search_term: query,
  results_count: results.length
});

// Track scroll depth
let maxScroll = 0;
window.addEventListener('scroll', () => {
  const scrollPercent = (window.scrollY / 
    (document.documentElement.scrollHeight - window.innerHeight)) * 100;
  
  if (scrollPercent > maxScroll) {
    maxScroll = scrollPercent;
    
    if (scrollPercent >= 25 && scrollPercent < 50) {
      gtag('event', 'scroll', { percent: 25 });
    } else if (scrollPercent >= 50 && scrollPercent < 75) {
      gtag('event', 'scroll', { percent: 50 });
    } else if (scrollPercent >= 75) {
      gtag('event', 'scroll', { percent: 75 });
    }
  }
});
```

### 3. Performance Monitoring

```javascript
// Web Vitals monitoring
import { getCLS, getFID, getLCP, getFCP, getTTFB } from 'web-vitals';

function sendToAnalytics({ name, value, id }) {
  gtag('event', name, {
    value: Math.round(name === 'CLS' ? value * 1000 : value),
    event_label: id,
    non_interaction: true,
  });
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getLCP(sendToAnalytics);
getFCP(sendToAnalytics);
getTTFB(sendToAnalytics);

// Custom performance monitoring
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.entryType === 'navigation') {
      console.log('DOM Interactive:', entry.domInteractive);
      console.log('DOM Complete:', entry.domComplete);
      console.log('Load Complete:', entry.loadEventEnd);
    }
  }
});

observer.observe({ entryTypes: ['navigation'] });
```

## Advanced SEO Techniques

### 1. International SEO

```html
<!-- hreflang implementation -->
<link rel="alternate" hreflang="en-US" href="https://example.com/us/">
<link rel="alternate" hreflang="en-GB" href="https://example.com/uk/">
<link rel="alternate" hreflang="de-DE" href="https://example.com/de/">
<link rel="alternate" hreflang="x-default" href="https://example.com/">

<!-- Language meta tag -->
<meta http-equiv="content-language" content="en-US">

<!-- Geo-targeting -->
<meta name="geo.region" content="US-CA">
<meta name="geo.placename" content="San Francisco">
<meta name="geo.position" content="37.7749;-122.4194">
```

### 2. E-commerce SEO

```javascript
// Dynamic meta tags for products
function generateProductMeta(product) {
  return {
    title: `${product.name} - ${product.brand} | Store Name`,
    description: `Buy ${product.name} for $${product.price}. ${product.shortDescription}`,
    canonical: `https://example.com/products/${product.slug}`,
    og: {
      title: product.name,
      description: product.description,
      image: product.images[0],
      price: {
        amount: product.price,
        currency: 'USD'
      }
    }
  };
}

// Faceted navigation SEO
// Use URL parameters wisely
const allowedParams = ['color', 'size', 'brand'];
const canonicalUrl = new URL(window.location);

// Remove non-essential parameters for canonical
Array.from(canonicalUrl.searchParams.keys()).forEach(key => {
  if (!allowedParams.includes(key)) {
    canonicalUrl.searchParams.delete(key);
  }
});

document.querySelector('link[rel="canonical"]').href = canonicalUrl.toString();
```

### 3. Local SEO

```html
<!-- Local Business Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Business Name",
  "image": "https://example.com/photo.jpg",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "City",
    "addressRegion": "State",
    "postalCode": "12345",
    "addressCountry": "US"
  },
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "url": "https://example.com",
  "telephone": "+1234567890",
  "openingHoursSpecification": [{
    "@type": "OpeningHoursSpecification",
    "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
    "opens": "09:00",
    "closes": "17:00"
  }],
  "priceRange": "$$"
}
</script>
```

## SEO Automation

### 1. Automated Testing

```javascript
// Lighthouse CI for automated SEO audits
module.exports = {
  ci: {
    collect: {
      url: ['https://example.com'],
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        'categories:seo': ['error', { minScore: 0.9 }],
        'categories:performance': ['warn', { minScore: 0.8 }],
        'categories:accessibility': ['warn', { minScore: 0.9 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};

// Automated meta tag validation
function validateMetaTags() {
  const errors = [];
  
  // Check title length
  const title = document.querySelector('title');
  if (!title) {
    errors.push('Missing title tag');
  } else if (title.innerText.length > 60) {
    errors.push('Title too long (>60 chars)');
  } else if (title.innerText.length < 30) {
    errors.push('Title too short (<30 chars)');
  }
  
  // Check meta description
  const description = document.querySelector('meta[name="description"]');
  if (!description) {
    errors.push('Missing meta description');
  } else if (description.content.length > 160) {
    errors.push('Description too long (>160 chars)');
  }
  
  // Check canonical
  const canonical = document.querySelector('link[rel="canonical"]');
  if (!canonical) {
    errors.push('Missing canonical tag');
  }
  
  return errors;
}
```

### 2. Content Generation Helper

```javascript
// SEO-friendly URL generation
function generateSlug(title) {
  return title
    .toLowerCase()
    .replace(/[^\w\s-]/g, '') // Remove special characters
    .replace(/\s+/g, '-')      // Replace spaces with hyphens
    .replace(/--+/g, '-')      // Replace multiple hyphens
    .replace(/^-+|-+$/g, '');  // Trim hyphens from start/end
}

// Meta description generator
function generateMetaDescription(content, maxLength = 160) {
  // Remove HTML tags
  const text = content.replace(/<[^>]*>/g, '');
  
  // Find first paragraph with keywords
  const paragraphs = text.split('\n').filter(p => p.length > 50);
  
  if (paragraphs.length === 0) return '';
  
  let description = paragraphs[0];
  
  // Truncate to max length at word boundary
  if (description.length > maxLength) {
    description = description.substring(0, maxLength - 3);
    description = description.substring(0, description.lastIndexOf(' ')) + '...';
  }
  
  return description;
}
```

## Common SEO Issues & Solutions

1. **Duplicate Content**: Use canonical tags and 301 redirects
2. **Slow Page Speed**: Optimize images, minify code, use CDN
3. **Mobile Usability**: Responsive design, touch-friendly elements
4. **Crawl Errors**: Fix 404s, check robots.txt, submit sitemap
5. **Thin Content**: Expand content, add value, merge similar pages
6. **Missing Alt Text**: Add descriptive alt attributes to images
7. **Broken Links**: Regular audits, implement 301 redirects
8. **JavaScript Rendering**: Use SSR/SSG, test with Google's tools
9. **HTTPS Issues**: Implement SSL, fix mixed content warnings
10. **International Targeting**: Proper hreflang implementation

## SEO Checklist

- [ ] Title tags optimized (50-60 characters)
- [ ] Meta descriptions written (150-160 characters)
- [ ] Header tags properly structured (H1-H6)
- [ ] Images optimized with alt text
- [ ] Schema markup implemented
- [ ] XML sitemap created and submitted
- [ ] Robots.txt configured
- [ ] Page speed optimized (<3 seconds)
- [ ] Mobile-friendly design
- [ ] HTTPS implemented
- [ ] Canonical tags set
- [ ] Internal linking structure
- [ ] 404 pages handled
- [ ] Redirects properly configured
- [ ] Core Web Vitals passing