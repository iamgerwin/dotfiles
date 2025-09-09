# GSAP (GreenSock Animation Platform) Best Practices

Comprehensive guide for creating high-performance, cross-browser animations using GSAP's powerful animation library and ecosystem.

## 📚 Official Documentation
- [GSAP Documentation](https://greensock.com/docs/)
- [GSAP Learning Center](https://greensock.com/learning/)
- [ScrollTrigger Plugin](https://greensock.com/scrolltrigger/)
- [GSAP Codepen Collection](https://codepen.io/collection/DyvJkZ)

## 🏗️ Project Setup

### Installation & Licensing
```bash
# NPM installation
npm install gsap

# For premium plugins (requires GSAP membership)
# Download from GSAP member area and install locally

# CDN (for quick prototyping)
# <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>
```

### Project Structure
```
src/
├── animations/
│   ├── timeline.js           # Timeline animations
│   ├── scroll-animations.js  # ScrollTrigger animations
│   ├── page-transitions.js   # Page transition effects
│   └── micro-interactions.js # Button/UI micro-interactions
├── utils/
│   ├── gsap-config.js        # GSAP configuration
│   └── animation-helpers.js   # Animation utility functions
├── components/
│   ├── AnimatedText.jsx      # Text animation components
│   ├── ScrollReveal.jsx      # Scroll-triggered animations
│   └── LoadingSpinner.jsx    # Loading animations
└── styles/
    └── animations.css        # CSS for GSAP compatibility
```

## 🎯 Core Best Practices

### 1. Basic GSAP Setup & Configuration

```javascript
// utils/gsap-config.js
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { TextPlugin } from 'gsap/TextPlugin';

// Register plugins
gsap.registerPlugin(ScrollTrigger, TextPlugin);

// Global GSAP configuration
gsap.config({
  nullTargetWarn: false, // Disable warnings for null targets
  trialWarn: false, // Disable trial warnings if you have a license
});

// Set default ease and duration
gsap.defaults({
  duration: 0.8,
  ease: "power2.out"
});

// Refresh ScrollTrigger on window resize
let resizeTimer;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    ScrollTrigger.refresh();
  }, 250);
});

export { gsap, ScrollTrigger };
```

### 2. Performance-Optimized Animation Patterns

```javascript
// animations/micro-interactions.js
import { gsap } from '../utils/gsap-config';

export class MicroInteractions {
  constructor() {
    this.initButtonAnimations();
    this.initCardHovers();
    this.initFormElements();
  }

  initButtonAnimations() {
    // Efficient button hover animations
    const buttons = document.querySelectorAll('.btn-animated');
    
    buttons.forEach(button => {
      const tl = gsap.timeline({ paused: true });
      
      // Pre-build timeline for performance
      tl.to(button, {
        scale: 1.05,
        duration: 0.2,
        ease: "power2.out"
      })
      .to(button.querySelector('.btn-bg'), {
        scaleX: 1.1,
        duration: 0.2,
        ease: "power2.out"
      }, 0);

      button.addEventListener('mouseenter', () => tl.play());
      button.addEventListener('mouseleave', () => tl.reverse());
    });
  }

  initCardHovers() {
    // Card hover with 3D transform
    const cards = document.querySelectorAll('.card-3d');
    
    cards.forEach(card => {
      const image = card.querySelector('.card-image');
      const content = card.querySelector('.card-content');
      
      // Create hover timeline
      const hoverTL = gsap.timeline({ paused: true });
      
      hoverTL.to(card, {
        y: -10,
        rotationX: 5,
        rotationY: 5,
        transformPerspective: 1000,
        duration: 0.4,
        ease: "power2.out"
      })
      .to(image, {
        scale: 1.1,
        duration: 0.4,
        ease: "power2.out"
      }, 0)
      .to(content, {
        y: -5,
        duration: 0.4,
        ease: "power2.out"
      }, 0.1);

      card.addEventListener('mouseenter', () => hoverTL.play());
      card.addEventListener('mouseleave', () => hoverTL.reverse());
    });
  }

  initFormElements() {
    // Form input focus animations
    const inputs = document.querySelectorAll('.form-input');
    
    inputs.forEach(input => {
      const label = input.nextElementSibling;
      
      if (label && label.classList.contains('floating-label')) {
        const focusTL = gsap.timeline({ paused: true });
        
        focusTL.to(label, {
          y: -20,
          scale: 0.8,
          color: '#3b82f6',
          duration: 0.3,
          ease: "power2.out"
        });

        input.addEventListener('focus', () => focusTL.play());
        input.addEventListener('blur', () => {
          if (!input.value) focusTL.reverse();
        });
      }
    });
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  new MicroInteractions();
});
```

### 3. Advanced ScrollTrigger Animations

```javascript
// animations/scroll-animations.js
import { gsap, ScrollTrigger } from '../utils/gsap-config';

export class ScrollAnimations {
  constructor() {
    this.initHeroParallax();
    this.initSectionReveals();
    this.initTextAnimations();
    this.initProgressIndicators();
  }

  initHeroParallax() {
    // Hero section parallax effect
    const heroSection = document.querySelector('.hero-section');
    const heroImage = heroSection?.querySelector('.hero-image');
    const heroText = heroSection?.querySelector('.hero-text');
    
    if (heroSection && heroImage && heroText) {
      gsap.set(heroImage, { scale: 1.2 });
      
      ScrollTrigger.create({
        trigger: heroSection,
        start: 'top top',
        end: 'bottom top',
        scrub: 1,
        animation: gsap.timeline()
          .to(heroImage, {
            scale: 1,
            y: '50%',
            ease: 'none'
          })
          .to(heroText, {
            y: '100%',
            opacity: 0,
            ease: 'none'
          }, 0)
      });
    }
  }

  initSectionReveals() {
    // Reveal sections on scroll
    const sections = document.querySelectorAll('.reveal-section');
    
    sections.forEach((section, index) => {
      const elements = section.querySelectorAll('.reveal-element');
      
      // Set initial state
      gsap.set(elements, {
        y: 60,
        opacity: 0,
        rotationX: 45,
        transformPerspective: 1000
      });
      
      ScrollTrigger.create({
        trigger: section,
        start: 'top 80%',
        end: 'bottom 20%',
        animation: gsap.timeline()
          .to(elements, {
            y: 0,
            opacity: 1,
            rotationX: 0,
            duration: 0.8,
            stagger: 0.1,
            ease: 'power3.out'
          })
      });
    });
  }

  initTextAnimations() {
    // Advanced text reveal animations
    const textElements = document.querySelectorAll('.text-reveal');
    
    textElements.forEach(element => {
      // Split text into lines and words
      const lines = this.splitTextIntoLines(element);
      
      lines.forEach(line => {
        const words = this.splitLineIntoWords(line);
        
        // Set initial state
        gsap.set(words, {
          y: '100%',
          opacity: 0,
          rotationX: 90,
          transformOrigin: '50% 100%'
        });
        
        ScrollTrigger.create({
          trigger: line,
          start: 'top 90%',
          animation: gsap.to(words, {
            y: '0%',
            opacity: 1,
            rotationX: 0,
            duration: 0.6,
            stagger: 0.02,
            ease: 'power3.out'
          })
        });
      });
    });
  }

  initProgressIndicators() {
    // Reading progress indicator
    const progressBar = document.querySelector('.reading-progress');
    
    if (progressBar) {
      gsap.set(progressBar, { scaleX: 0, transformOrigin: 'left center' });
      
      ScrollTrigger.create({
        trigger: 'body',
        start: 'top top',
        end: 'bottom bottom',
        scrub: 0.3,
        animation: gsap.to(progressBar, {
          scaleX: 1,
          ease: 'none'
        })
      });
    }

    // Section progress indicators
    const sections = document.querySelectorAll('section[data-section]');
    const indicators = document.querySelectorAll('.nav-indicator');
    
    sections.forEach((section, index) => {
      ScrollTrigger.create({
        trigger: section,
        start: 'top center',
        end: 'bottom center',
        onToggle: self => {
          if (self.isActive && indicators[index]) {
            gsap.to(indicators, { scale: 1, opacity: 0.5, duration: 0.3 });
            gsap.to(indicators[index], { scale: 1.2, opacity: 1, duration: 0.3 });
          }
        }
      });
    });
  }

  // Utility methods
  splitTextIntoLines(element) {
    const text = element.textContent;
    const words = text.split(' ');
    element.innerHTML = '';
    
    let currentLine = document.createElement('div');
    currentLine.style.overflow = 'hidden';
    element.appendChild(currentLine);
    
    words.forEach(word => {
      const span = document.createElement('span');
      span.textContent = word + ' ';
      span.style.display = 'inline-block';
      currentLine.appendChild(span);
    });
    
    return Array.from(element.children);
  }

  splitLineIntoWords(line) {
    return Array.from(line.children);
  }
}

// Initialize scroll animations
document.addEventListener('DOMContentLoaded', () => {
  new ScrollAnimations();
});
```

### 4. Complex Timeline Animations

```javascript
// animations/timeline.js
import { gsap } from '../utils/gsap-config';

export class TimelineAnimations {
  constructor() {
    this.initPageLoadAnimation();
    this.initModalAnimations();
    this.initMenuAnimations();
  }

  initPageLoadAnimation() {
    const tl = gsap.timeline({ delay: 0.2 });
    
    // Set initial states
    gsap.set('.page-content', { opacity: 0, y: 30 });
    gsap.set('.nav-item', { opacity: 0, y: -20 });
    gsap.set('.hero-title .word', { opacity: 0, y: 40, rotationX: 90 });
    gsap.set('.hero-subtitle', { opacity: 0, y: 20 });
    gsap.set('.hero-cta', { opacity: 0, scale: 0.8 });
    
    // Page load sequence
    tl.to('.page-content', {
      opacity: 1,
      y: 0,
      duration: 0.8,
      ease: 'power3.out'
    })
    .to('.nav-item', {
      opacity: 1,
      y: 0,
      duration: 0.6,
      stagger: 0.1,
      ease: 'power2.out'
    }, 0.2)
    .to('.hero-title .word', {
      opacity: 1,
      y: 0,
      rotationX: 0,
      duration: 0.8,
      stagger: 0.05,
      ease: 'power3.out'
    }, 0.4)
    .to('.hero-subtitle', {
      opacity: 1,
      y: 0,
      duration: 0.6,
      ease: 'power2.out'
    }, 0.8)
    .to('.hero-cta', {
      opacity: 1,
      scale: 1,
      duration: 0.5,
      ease: 'back.out(1.7)'
    }, 1.0);
  }

  initModalAnimations() {
    const modals = document.querySelectorAll('.modal');
    
    modals.forEach(modal => {
      const backdrop = modal.querySelector('.modal-backdrop');
      const content = modal.querySelector('.modal-content');
      const closeBtn = modal.querySelector('.modal-close');
      
      // Create open/close timelines
      const openTL = gsap.timeline({ paused: true });
      const closeTL = gsap.timeline({ paused: true });
      
      // Set initial states
      gsap.set(modal, { display: 'none' });
      gsap.set(backdrop, { opacity: 0 });
      gsap.set(content, { 
        opacity: 0, 
        scale: 0.8, 
        y: 50,
        rotationX: 45,
        transformPerspective: 1000
      });
      
      // Open animation
      openTL.set(modal, { display: 'flex' })
        .to(backdrop, {
          opacity: 1,
          duration: 0.3,
          ease: 'power2.out'
        })
        .to(content, {
          opacity: 1,
          scale: 1,
          y: 0,
          rotationX: 0,
          duration: 0.5,
          ease: 'back.out(1.7)'
        }, 0.1);
      
      // Close animation
      closeTL.to(content, {
        opacity: 0,
        scale: 0.8,
        y: -50,
        rotationX: -45,
        duration: 0.3,
        ease: 'power2.in'
      })
      .to(backdrop, {
        opacity: 0,
        duration: 0.2,
        ease: 'power2.out'
      }, 0.1)
      .set(modal, { display: 'none' });
      
      // Event listeners
      modal.addEventListener('open', () => openTL.play());
      modal.addEventListener('close', () => closeTL.play());
      
      if (closeBtn) {
        closeBtn.addEventListener('click', () => {
          modal.dispatchEvent(new Event('close'));
        });
      }
      
      if (backdrop) {
        backdrop.addEventListener('click', (e) => {
          if (e.target === backdrop) {
            modal.dispatchEvent(new Event('close'));
          }
        });
      }
    });
  }

  initMenuAnimations() {
    const menuToggle = document.querySelector('.menu-toggle');
    const mobileMenu = document.querySelector('.mobile-menu');
    
    if (menuToggle && mobileMenu) {
      const menuItems = mobileMenu.querySelectorAll('.menu-item');
      const menuBg = mobileMenu.querySelector('.menu-bg');
      
      // Create menu timeline
      const menuTL = gsap.timeline({ paused: true });
      
      // Set initial states
      gsap.set(mobileMenu, { display: 'none' });
      gsap.set(menuBg, { scaleY: 0, transformOrigin: 'top center' });
      gsap.set(menuItems, { 
        opacity: 0, 
        x: 50, 
        rotationY: 45,
        transformPerspective: 1000
      });
      
      // Menu open sequence
      menuTL.set(mobileMenu, { display: 'block' })
        .to(menuBg, {
          scaleY: 1,
          duration: 0.4,
          ease: 'power3.out'
        })
        .to(menuItems, {
          opacity: 1,
          x: 0,
          rotationY: 0,
          duration: 0.5,
          stagger: 0.08,
          ease: 'power3.out'
        }, 0.2);
      
      let menuOpen = false;
      
      menuToggle.addEventListener('click', () => {
        if (!menuOpen) {
          menuTL.play();
          menuOpen = true;
        } else {
          menuTL.reverse();
          menuOpen = false;
        }
      });
    }
  }
}

// Initialize timeline animations
document.addEventListener('DOMContentLoaded', () => {
  new TimelineAnimations();
});
```

## 🛠️ React Integration Patterns

### React Hooks for GSAP
```jsx
// hooks/useGSAP.js
import { useEffect, useRef } from 'react';
import { gsap } from '../utils/gsap-config';

export const useGSAP = (animation, dependencies = []) => {
  const elementRef = useRef(null);
  
  useEffect(() => {
    const element = elementRef.current;
    if (!element) return;
    
    const ctx = gsap.context(() => {
      animation(element);
    }, element);
    
    return () => ctx.revert(); // Cleanup
  }, dependencies);
  
  return elementRef;
};

// components/AnimatedText.jsx
import { useGSAP } from '../hooks/useGSAP';

const AnimatedText = ({ children, delay = 0 }) => {
  const textRef = useGSAP((element) => {
    const words = element.querySelectorAll('.word');
    
    gsap.fromTo(words, 
      {
        opacity: 0,
        y: 40,
        rotationX: 90,
        transformPerspective: 1000
      },
      {
        opacity: 1,
        y: 0,
        rotationX: 0,
        duration: 0.8,
        stagger: 0.05,
        delay,
        ease: 'power3.out'
      }
    );
  }, [delay]);

  // Split text into words
  const splitText = (text) => {
    return text.split(' ').map((word, index) => (
      <span key={index} className="word inline-block">
        {word}&nbsp;
      </span>
    ));
  };

  return (
    <div ref={textRef} className="overflow-hidden">
      {typeof children === 'string' ? splitText(children) : children}
    </div>
  );
};

export default AnimatedText;
```

### Advanced React Components
```jsx
// components/ScrollReveal.jsx
import { useEffect, useRef } from 'react';
import { gsap, ScrollTrigger } from '../utils/gsap-config';

const ScrollReveal = ({ 
  children, 
  direction = 'up', 
  distance = 60, 
  duration = 0.8, 
  delay = 0,
  stagger = 0.1,
  triggerStart = 'top 80%'
}) => {
  const containerRef = useRef(null);

  useEffect(() => {
    const elements = containerRef.current.children;
    if (!elements.length) return;

    const getInitialTransform = () => {
      switch (direction) {
        case 'up': return { y: distance, opacity: 0 };
        case 'down': return { y: -distance, opacity: 0 };
        case 'left': return { x: distance, opacity: 0 };
        case 'right': return { x: -distance, opacity: 0 };
        case 'scale': return { scale: 0.8, opacity: 0 };
        default: return { y: distance, opacity: 0 };
      }
    };

    // Set initial state
    gsap.set(elements, getInitialTransform());

    // Create ScrollTrigger animation
    const ctx = gsap.context(() => {
      ScrollTrigger.create({
        trigger: containerRef.current,
        start: triggerStart,
        animation: gsap.to(elements, {
          x: 0,
          y: 0,
          scale: 1,
          opacity: 1,
          duration,
          delay,
          stagger,
          ease: 'power3.out'
        })
      });
    });

    return () => ctx.revert();
  }, [direction, distance, duration, delay, stagger, triggerStart]);

  return (
    <div ref={containerRef}>
      {children}
    </div>
  );
};

export default ScrollReveal;
```

## ⚠️ Common Pitfalls to Avoid

### 1. Not Using GSAP Context
```javascript
// ❌ Bad - No cleanup, memory leaks
useEffect(() => {
  gsap.to('.element', { x: 100 });
}, []);

// ✅ Good - Proper cleanup with context
useEffect(() => {
  const ctx = gsap.context(() => {
    gsap.to('.element', { x: 100 });
  });
  
  return () => ctx.revert();
}, []);
```

### 2. Animating Layout Properties
```javascript
// ❌ Bad - Causes layout thrashing
gsap.to('.element', { width: '100%', height: '200px' });

// ✅ Good - Use transforms and opacity
gsap.to('.element', { scaleX: 2, scaleY: 1.5, opacity: 0.8 });
```

### 3. Over-animating Elements
```javascript
// ❌ Bad - Too many simultaneous animations
gsap.to('.element', { 
  x: 100, 
  y: 50, 
  rotation: 360, 
  scale: 1.5, 
  opacity: 0.5,
  skewX: 15,
  duration: 0.3
});

// ✅ Good - Focused, purposeful animation
gsap.to('.element', { 
  y: -10, 
  scale: 1.05,
  duration: 0.3,
  ease: 'power2.out'
});
```

## 📊 Performance Optimization

### 1. Use will-change CSS Property
```css
.animated-element {
  will-change: transform, opacity;
}

/* Remove after animation */
.animation-complete {
  will-change: auto;
}
```

### 2. Optimize Timeline Creation
```javascript
// Create timeline once, reuse multiple times
class AnimationManager {
  constructor() {
    this.buttonHoverTL = this.createButtonHoverTimeline();
  }
  
  createButtonHoverTimeline() {
    return gsap.timeline({ paused: true })
      .to('.button', { scale: 1.05, duration: 0.2 })
      .to('.button-bg', { scaleX: 1.1, duration: 0.2 }, 0);
  }
  
  playButtonHover() {
    this.buttonHoverTL.restart();
  }
}
```

### 3. Use GSAP's Batch Plugin
```javascript
// Efficient handling of multiple elements
ScrollTrigger.batch('.fade-in', {
  onEnter: elements => {
    gsap.fromTo(elements, 
      { opacity: 0, y: 60 },
      { opacity: 1, y: 0, duration: 0.8, stagger: 0.1 }
    );
  },
  start: 'top 80%'
});
```

## 🧪 Testing Animations

### Animation Testing Utilities
```javascript
// utils/animation-testing.js
export const animationTestUtils = {
  // Fast-forward all animations
  fastForward: () => {
    gsap.globalTimeline.progress(1);
  },
  
  // Disable all animations for testing
  disableAnimations: () => {
    gsap.set('*', { duration: 0 });
    gsap.globalTimeline.timeScale(1000);
  },
  
  // Wait for animation completion
  waitForAnimation: (timeline) => {
    return new Promise(resolve => {
      timeline.eventCallback('onComplete', resolve);
    });
  },
  
  // Check if element is being animated
  isAnimating: (element) => {
    return gsap.isTweening(element);
  }
};

// Jest test example
describe('Button Animation', () => {
  beforeEach(() => {
    animationTestUtils.disableAnimations();
  });
  
  test('button scales on hover', async () => {
    const button = document.createElement('button');
    const timeline = gsap.timeline();
    
    timeline.to(button, { scale: 1.05 });
    
    await animationTestUtils.waitForAnimation(timeline);
    
    expect(button.style.transform).toContain('scale(1.05)');
  });
});
```

## 🚀 Production Optimizations

### 1. Code Splitting GSAP Plugins
```javascript
// Lazy load plugins
const loadScrollTrigger = async () => {
  const { ScrollTrigger } = await import('gsap/ScrollTrigger');
  gsap.registerPlugin(ScrollTrigger);
  return ScrollTrigger;
};

// Use only when needed
const initScrollAnimations = async () => {
  const ScrollTrigger = await loadScrollTrigger();
  // Initialize scroll animations
};
```

### 2. Reduce Motion Preferences
```javascript
// Respect user's motion preferences
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

if (prefersReducedMotion) {
  gsap.set('*', { duration: 0 });
} else {
  // Initialize normal animations
}
```

## 📈 Advanced GSAP Techniques

### Custom Ease Creation
```javascript
// Create custom eases
gsap.registerEase('customBounce', 'M0,0 C0.14,0 0.242,0.438 0.272,0.561 0.313,0.728 0.354,0.963 0.362,1 0.37,0.985 0.414,0.928 0.455,0.878 0.518,0.806 0.647,0.727 0.679,0.727 0.717,0.727 0.767,0.906 0.788,0.954 0.814,1.014 0.835,1.086 0.851,1.114 0.869,1.146 0.889,1.151 0.912,1.151 0.94,1.151 0.97,1 1,1');

// Use custom ease
gsap.to('.element', {
  x: 100,
  duration: 1,
  ease: 'customBounce'
});
```

### Physics-Based Animations
```javascript
// Simulate physics with GSAP
const createPhysicsAnimation = (element, force, friction = 0.8) => {
  let velocity = { x: 0, y: 0 };
  let position = { x: 0, y: 0 };
  
  const animate = () => {
    velocity.x += force.x;
    velocity.y += force.y;
    
    position.x += velocity.x;
    position.y += velocity.y;
    
    velocity.x *= friction;
    velocity.y *= friction;
    
    gsap.set(element, {
      x: position.x,
      y: position.y
    });
    
    if (Math.abs(velocity.x) > 0.1 || Math.abs(velocity.y) > 0.1) {
      requestAnimationFrame(animate);
    }
  };
  
  animate();
};
```

## 🔒 Security & Accessibility

### Accessibility Considerations
```javascript
// Respect user preferences
const respectAccessibility = () => {
  const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  
  const handleMotionPreference = (mediaQuery) => {
    if (mediaQuery.matches) {
      gsap.globalTimeline.timeScale(1000); // Speed up animations
      gsap.set('*', { duration: 0.01 }); // Nearly instant
    } else {
      gsap.globalTimeline.timeScale(1); // Normal speed
      gsap.set('*', { duration: 0.8 }); // Normal duration
    }
  };
  
  prefersReducedMotion.addListener(handleMotionPreference);
  handleMotionPreference(prefersReducedMotion);
};
```

## 📋 Code Review Checklist

- [ ] GSAP context used for proper cleanup
- [ ] Animations respect reduced motion preferences
- [ ] Performance-critical properties (transform, opacity) prioritized
- [ ] Timeline animations are properly structured
- [ ] ScrollTrigger refreshes on resize
- [ ] Memory leaks prevented with proper cleanup
- [ ] Animation timing feels natural and purposeful
- [ ] Cross-browser compatibility verified

Remember: GSAP is powerful but should be used purposefully. Focus on enhancing user experience with smooth, performant animations that support the interface rather than overwhelming it.