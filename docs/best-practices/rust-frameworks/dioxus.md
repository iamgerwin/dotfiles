# Dioxus Best Practices

## Official Documentation
- **Dioxus**: https://dioxuslabs.com
- **Documentation**: https://dioxuslabs.com/learn/0.5/
- **GitHub**: https://github.com/DioxusLabs/dioxus
- **Examples**: https://github.com/DioxusLabs/dioxus/tree/main/examples
- **Community Discord**: https://discord.gg/XgGxMSkvUM
- **Awesome Dioxus**: https://github.com/DioxusLabs/awesome-dioxus

## Introduction

Dioxus is a cross-platform GUI library for Rust that enables building web, desktop, mobile, and terminal user interfaces from a single codebase. Inspired by React, it provides a component-based architecture with a focus on developer ergonomics, performance, and type safety.

### When to Use Dioxus

**Ideal Scenarios:**
- Cross-platform applications needing web, desktop, and mobile support
- Performance-critical UIs leveraging Rust's zero-cost abstractions
- Applications requiring compile-time guarantees and type safety
- Projects wanting React-like patterns in Rust ecosystem
- Teams with Rust expertise building full-stack applications
- Desktop apps needing native performance without Electron overhead
- Interactive dashboards and data visualization tools
- Real-time applications with complex state management

**When to Avoid:**
- Simple static websites (use SSG like Zola instead)
- Teams without Rust experience or time to learn
- Projects requiring extensive third-party UI component libraries
- Applications needing mature ecosystem like React or Vue
- Rapid prototyping where development speed is critical
- Projects heavily dependent on JavaScript ecosystem
- Content-heavy sites better suited to traditional frameworks

## Core Concepts

### Components and RSX

```rust
use dioxus::prelude::*;

// Functional component
fn App(cx: Scope) -> Element {
    render! {
        div {
            h1 { "Hello, Dioxus!" }
            Counter {}
        }
    }
}

// Component with props
#[derive(Props)]
struct CounterProps<'a> {
    initial_count: i32,
    on_change: EventHandler<'a, i32>,
}

fn Counter<'a>(cx: Scope<'a, CounterProps<'a>>) -> Element {
    let mut count = use_state(cx, || cx.props.initial_count);

    render! {
        div {
            class: "counter",
            h2 { "Count: {count}" }
            button {
                onclick: move |_| {
                    let new_count = count.get() + 1;
                    count.set(new_count);
                    cx.props.on_change.call(new_count);
                },
                "Increment"
            }
            button {
                onclick: move |_| count.set(count.get() - 1),
                "Decrement"
            }
        }
    }
}

// Mount the app
fn main() {
    dioxus_desktop::launch(App);
    // Or for web:
    // dioxus_web::launch(App);
}
```

### State Management with Hooks

```rust
use dioxus::prelude::*;

// useState - simple state
fn UseStateExample(cx: Scope) -> Element {
    let mut count = use_state(cx, || 0);

    render! {
        button {
            onclick: move |_| count += 1,
            "Clicked {count} times"
        }
    }
}

// useRef - mutable reference
fn UseRefExample(cx: Scope) -> Element {
    let input_ref = use_ref(cx, || String::new());

    render! {
        input {
            value: "{input_ref.read()}",
            oninput: move |evt| {
                *input_ref.write() = evt.value.clone();
            }
        }
        p { "You typed: {input_ref.read()}" }
    }
}

// useEffect - side effects
fn UseEffectExample(cx: Scope) -> Element {
    let count = use_state(cx, || 0);

    use_effect(cx, (count,), |(count,)| async move {
        println!("Count changed to: {}", count);
        // Perform side effect (API call, logging, etc.)
    });

    render! {
        button {
            onclick: move |_| count += 1,
            "Count: {count}"
        }
    }
}

// useMemo - derived state
fn UseMemoExample(cx: Scope) -> Element {
    let numbers = use_state(cx, || vec![1, 2, 3, 4, 5]);

    let sum = use_memo(cx, (numbers,), |(numbers,)| {
        numbers.iter().sum::<i32>()
    });

    render! {
        p { "Sum: {sum}" }
        button {
            onclick: move |_| {
                let mut nums = numbers.get().clone();
                nums.push(nums.len() as i32 + 1);
                numbers.set(nums);
            },
            "Add Number"
        }
    }
}
```

### Props and Component Communication

```rust
use dioxus::prelude::*;

// Props with lifetime
#[derive(Props)]
struct UserCardProps<'a> {
    name: &'a str,
    email: &'a str,
    #[props(default = false)]
    is_admin: bool,
    on_click: EventHandler<'a, ()>,
}

fn UserCard<'a>(cx: Scope<'a, UserCardProps<'a>>) -> Element {
    render! {
        div {
            class: "user-card",
            onclick: move |_| cx.props.on_click.call(()),
            h3 { "{cx.props.name}" }
            p { "{cx.props.email}" }
            if cx.props.is_admin {
                render! { span { class: "badge", "Admin" } }
            }
        }
    }
}

// Using the component
fn UserList(cx: Scope) -> Element {
    render! {
        UserCard {
            name: "Alice",
            email: "alice@example.com",
            is_admin: true,
            on_click: move |_| {
                println!("Alice clicked!");
            }
        }
        UserCard {
            name: "Bob",
            email: "bob@example.com",
            on_click: move |_| {
                println!("Bob clicked!");
            }
        }
    }
}
```

## Best Practices

### Component Organization

```rust
// components/mod.rs
pub mod header;
pub mod sidebar;
pub mod footer;

// components/header.rs
use dioxus::prelude::*;

#[derive(Props)]
pub struct HeaderProps<'a> {
    title: &'a str,
    #[props(optional)]
    subtitle: Option<&'a str>,
}

pub fn Header<'a>(cx: Scope<'a, HeaderProps<'a>>) -> Element {
    render! {
        header {
            class: "app-header",
            h1 { "{cx.props.title}" }
            if let Some(subtitle) = cx.props.subtitle {
                render! { p { class: "subtitle", "{subtitle}" } }
            }
        }
    }
}

// Usage in main app
use components::header::Header;

fn App(cx: Scope) -> Element {
    render! {
        Header {
            title: "My App",
            subtitle: "Built with Dioxus"
        }
    }
}
```

### Global State with Context

```rust
use dioxus::prelude::*;
use std::sync::Arc;

#[derive(Clone)]
struct AppState {
    user: Option<User>,
    theme: Theme,
}

#[derive(Clone)]
struct User {
    id: u64,
    name: String,
}

#[derive(Clone, PartialEq)]
enum Theme {
    Light,
    Dark,
}

fn App(cx: Scope) -> Element {
    // Provide global state
    use_shared_state_provider(cx, || AppState {
        user: None,
        theme: Theme::Light,
    });

    render! {
        div {
            Header {}
            MainContent {}
            ThemeToggle {}
        }
    }
}

fn Header(cx: Scope) -> Element {
    // Consume global state
    let state = use_shared_state::<AppState>(cx)?;

    render! {
        header {
            if let Some(user) = &state.read().user {
                render! { p { "Welcome, {user.name}!" } }
            } else {
                render! { p { "Please log in" } }
            }
        }
    }
}

fn ThemeToggle(cx: Scope) -> Element {
    let state = use_shared_state::<AppState>(cx)?;

    render! {
        button {
            onclick: move |_| {
                let mut s = state.write();
                s.theme = match s.theme {
                    Theme::Light => Theme::Dark,
                    Theme::Dark => Theme::Light,
                };
            },
            "Toggle Theme"
        }
    }
}
```

### Async Operations and Data Fetching

```rust
use dioxus::prelude::*;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug)]
struct Post {
    id: u64,
    title: String,
    body: String,
}

fn PostList(cx: Scope) -> Element {
    let posts = use_future(cx, (), |_| async move {
        reqwest::get("https://jsonplaceholder.typicode.com/posts")
            .await
            .unwrap()
            .json::<Vec<Post>>()
            .await
    });

    render! {
        div {
            h1 { "Posts" }
            match posts.value() {
                Some(Ok(posts)) => render! {
                    ul {
                        for post in posts {
                            li { key: "{post.id}",
                                h3 { "{post.title}" }
                                p { "{post.body}" }
                            }
                        }
                    }
                },
                Some(Err(e)) => render! {
                    p { "Error loading posts: {e}" }
                },
                None => render! {
                    p { "Loading..." }
                }
            }
        }
    }
}

// Refetchable data
fn RefetchableData(cx: Scope) -> Element {
    let posts = use_future(cx, (), |_| async move {
        fetch_posts().await
    });

    render! {
        button {
            onclick: move |_| posts.restart(),
            "Refresh"
        }
        match posts.value() {
            Some(data) => render! { DisplayPosts { posts: data.clone() } },
            None => render! { p { "Loading..." } }
        }
    }
}
```

### Form Handling

```rust
use dioxus::prelude::*;

#[derive(Default, Clone)]
struct LoginForm {
    email: String,
    password: String,
    remember_me: bool,
}

fn LoginPage(cx: Scope) -> Element {
    let mut form_data = use_state(cx, LoginForm::default);
    let mut error = use_state(cx, || None::<String>);
    let mut loading = use_state(cx, || false);

    let submit = move |evt: Event<FormData>| {
        cx.spawn({
            let form_data = form_data.clone();
            let error = error.clone();
            let loading = loading.clone();

            async move {
                loading.set(true);
                error.set(None);

                match login_user(&form_data.email, &form_data.password).await {
                    Ok(_) => {
                        // Navigate to dashboard
                        println!("Login successful!");
                    }
                    Err(e) => {
                        error.set(Some(e.to_string()));
                    }
                }

                loading.set(false);
            }
        });
    };

    render! {
        form {
            onsubmit: submit,
            prevent_default: "onsubmit",

            div {
                label { "Email" }
                input {
                    r#type: "email",
                    value: "{form_data.email}",
                    oninput: move |evt| {
                        form_data.modify(|f| f.email = evt.value.clone());
                    },
                    required: true
                }
            }

            div {
                label { "Password" }
                input {
                    r#type: "password",
                    value: "{form_data.password}",
                    oninput: move |evt| {
                        form_data.modify(|f| f.password = evt.value.clone());
                    },
                    required: true
                }
            }

            div {
                label {
                    input {
                        r#type: "checkbox",
                        checked: "{form_data.remember_me}",
                        onchange: move |evt| {
                            form_data.modify(|f| f.remember_me = evt.value.parse().unwrap_or(false));
                        }
                    }
                    "Remember me"
                }
            }

            if let Some(err) = error.get() {
                render! { p { class: "error", "{err}" } }
            }

            button {
                r#type: "submit",
                disabled: "{loading}",
                if **loading { "Logging in..." } else { "Login" }
            }
        }
    }
}

async fn login_user(email: &str, password: &str) -> Result<(), Box<dyn std::error::Error>> {
    // API call
    Ok(())
}
```

### Routing

```rust
use dioxus::prelude::*;
use dioxus_router::prelude::*;

#[derive(Routable, Clone)]
enum Route {
    #[route("/")]
    Home {},
    #[route("/about")]
    About {},
    #[route("/users/:id")]
    UserProfile { id: u64 },
    #[route("/blog")]
    Blog {},
    #[route("/blog/:slug")]
    BlogPost { slug: String },
    #[route("/:..route")]
    NotFound { route: Vec<String> },
}

fn App(cx: Scope) -> Element {
    render! {
        Router::<Route> {}
    }
}

#[component]
fn Home(cx: Scope) -> Element {
    render! {
        div {
            h1 { "Home Page" }
            Link { to: Route::About {}, "Go to About" }
        }
    }
}

#[component]
fn About(cx: Scope) -> Element {
    render! {
        div {
            h1 { "About Page" }
            Link { to: Route::Home {}, "Back to Home" }
        }
    }
}

#[component]
fn UserProfile(cx: Scope, id: u64) -> Element {
    let user = use_future(cx, (id,), |(id,)| async move {
        fetch_user(id).await
    });

    render! {
        match user.value() {
            Some(Ok(user)) => render! {
                h1 { "User: {user.name}" }
                p { "Email: {user.email}" }
            },
            Some(Err(_)) => render! { p { "Error loading user" } },
            None => render! { p { "Loading..." } }
        }
    }
}

#[component]
fn NotFound(cx: Scope, route: Vec<String>) -> Element {
    render! {
        h1 { "404 - Page Not Found" }
        p { "Could not find: /{route:?}" }
        Link { to: Route::Home {}, "Go Home" }
    }
}
```

## Project Structure

```plaintext
dioxus-app/
├── src/
│   ├── main.rs                    # Entry point
│   ├── lib.rs                     # Library exports
│   ├── app.rs                     # Root App component
│   ├── routes/
│   │   ├── mod.rs
│   │   ├── home.rs
│   │   ├── about.rs
│   │   └── profile.rs
│   ├── components/
│   │   ├── mod.rs
│   │   ├── header.rs
│   │   ├── sidebar.rs
│   │   ├── button.rs
│   │   └── card.rs
│   ├── hooks/
│   │   ├── mod.rs
│   │   ├── use_auth.rs
│   │   └── use_api.rs
│   ├── state/
│   │   ├── mod.rs
│   │   └── app_state.rs
│   ├── services/
│   │   ├── mod.rs
│   │   ├── api.rs
│   │   └── auth.rs
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── post.rs
│   └── utils/
│       ├── mod.rs
│       └── helpers.rs
├── assets/
│   ├── styles/
│   │   └── main.css
│   └── images/
├── public/
│   └── favicon.ico
├── Cargo.toml
├── Dioxus.toml                    # Dioxus configuration
└── README.md
```

### Dioxus.toml Configuration

```toml
[application]
name = "my-app"
default_platform = "web"

[web.app]
title = "My Dioxus App"
base_path = "/"

[web.watcher]
watch_path = ["src", "assets"]
index_on_404 = true

[web.resource]
style = ["assets/styles/main.css"]
script = []

[[web.resource.dev.style]]
href = "https://cdn.jsdelivr.net/npm/tailwindcss@3/dist/tailwind.min.css"

[bundle]
identifier = "com.example.myapp"
publisher = "Example Corp"
icon = ["assets/icon.png"]
```

## Security Considerations

### Input Sanitization

```rust
use dioxus::prelude::*;

fn CommentForm(cx: Scope) -> Element {
    let mut comment = use_state(cx, String::new);
    let mut error = use_state(cx, || None::<String>);

    let submit = move |_| {
        // Validate input
        let trimmed = comment.trim();

        if trimmed.is_empty() {
            error.set(Some("Comment cannot be empty".to_string()));
            return;
        }

        if trimmed.len() > 500 {
            error.set(Some("Comment too long (max 500 characters)".to_string()));
            return;
        }

        // Sanitize HTML (Dioxus auto-escapes by default)
        let sanitized = html_escape::encode_text(trimmed);

        // Submit comment
        submit_comment(&sanitized);
        comment.set(String::new());
        error.set(None);
    };

    render! {
        div {
            textarea {
                value: "{comment}",
                oninput: move |evt| comment.set(evt.value.clone()),
                maxlength: 500,
                placeholder: "Write a comment..."
            }
            if let Some(err) = error.get() {
                render! { p { class: "error", "{err}" } }
            }
            button {
                onclick: submit,
                "Submit"
            }
        }
    }
}
```

### Authentication

```rust
use dioxus::prelude::*;

#[derive(Clone)]
struct AuthState {
    user: Option<User>,
    token: Option<String>,
}

// Custom hook for authentication
fn use_auth(cx: &ScopeState) -> &UseSharedState<AuthState> {
    use_shared_state::<AuthState>(cx).expect("AuthState not provided")
}

fn ProtectedRoute(cx: Scope) -> Element {
    let auth = use_auth(cx);

    if auth.read().user.is_none() {
        // Redirect to login
        return render! {
            Redirect { to: Route::Login {} }
        };
    }

    render! {
        div {
            h1 { "Protected Content" }
            button {
                onclick: move |_| {
                    auth.write().user = None;
                    auth.write().token = None;
                },
                "Logout"
            }
        }
    }
}
```

### XSS Prevention

```rust
// Dioxus automatically escapes strings in RSX
fn SafeComponent(cx: Scope) -> Element {
    let user_input = "<script>alert('XSS')</script>";

    render! {
        // This is safe - automatically escaped
        p { "{user_input}" }

        // For raw HTML (use with extreme caution)
        // dangerous_inner_html: user_input
    }
}
```

## Common Pitfalls

### 1. Unnecessary Re-renders

```rust
// BAD: Creates new closure every render
fn BadCounter(cx: Scope) -> Element {
    let count = use_state(cx, || 0);

    render! {
        // New closure each render causes child to re-render
        ExpensiveChild {
            on_click: |_| println!("Clicked")
        }
    }
}

// GOOD: Stable callback
fn GoodCounter(cx: Scope) -> Element {
    let count = use_state(cx, || 0);

    let on_click = use_callback(cx, (), |_, _| {
        println!("Clicked");
    });

    render! {
        ExpensiveChild {
            on_click: on_click
        }
    }
}
```

### 2. Not Handling Async Errors

```rust
// BAD: Unwrap can panic
fn BadAsync(cx: Scope) -> Element {
    let data = use_future(cx, (), |_| async {
        reqwest::get("https://api.example.com/data")
            .await
            .unwrap()  // Can panic!
            .json()
            .await
            .unwrap()  // Can panic!
    });

    render! { /* ... */ }
}

// GOOD: Proper error handling
fn GoodAsync(cx: Scope) -> Element {
    let data = use_future(cx, (), |_| async {
        let response = reqwest::get("https://api.example.com/data")
            .await?;

        let data: Vec<Item> = response.json().await?;

        Ok::<_, Box<dyn std::error::Error>>(data)
    });

    render! {
        match data.value() {
            Some(Ok(items)) => render! { /* display items */ },
            Some(Err(e)) => render! { p { "Error: {e}" } },
            None => render! { p { "Loading..." } }
        }
    }
}
```

### 3. Overusing Global State

```rust
// BAD: Everything in global state
#[derive(Clone)]
struct AppState {
    counter: i32,
    form_input: String,
    hover_state: bool,
    // ... many more
}

// GOOD: Local state where appropriate
fn Component(cx: Scope) -> Element {
    // Local state for UI interactions
    let hover = use_state(cx, || false);

    // Global state only when needed
    let app_state = use_shared_state::<AppState>(cx);

    render! { /* ... */ }
}
```

## Testing Strategies

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use dioxus::prelude::*;

    #[test]
    fn test_counter_increment() {
        let mut vdom = VirtualDom::new(Counter);

        // Initial render
        let _ = vdom.rebuild();

        // Simulate button click
        // vdom.handle_event("click", ...);

        // Assert state changed
        // assert_eq!(count, 1);
    }

    #[test]
    fn test_component_props() {
        // Test component with different props
    }
}
```

## Pros and Cons

### Pros
✓ **Cross-platform** from single codebase (web, desktop, mobile, TUI)
✓ **Type safety** with compile-time guarantees from Rust
✓ **Performance** with zero-cost abstractions and minimal runtime
✓ **React-like API** familiar to web developers
✓ **Memory safe** leveraging Rust's ownership system
✓ **Fast compilation** compared to other Rust GUI frameworks
✓ **Concurrent rendering** with async/await support
✓ **Hot reload** for rapid development iteration
✓ **Native desktop** without Electron overhead

### Cons
✗ **Rust learning curve** steep for newcomers
✗ **Smaller ecosystem** compared to React or Vue
✗ **Limited third-party components** available
✗ **Compile times** can be significant for large projects
✗ **Less mature** than established frontend frameworks
✗ **Fewer examples** and learning resources
✗ **Mobile support** still experimental
✗ **CSS tooling** less integrated than JavaScript frameworks

## Summary

**Key Takeaways:**
- Use functional components with RSX macro for declarative UIs
- Leverage hooks (useState, useEffect, useMemo) for state management
- Implement global state with use_shared_state for app-wide data
- Handle async operations with use_future and proper error handling
- Organize components in separate modules for maintainability
- Use routing for multi-page applications
- Validate and sanitize user inputs
- Avoid unnecessary re-renders with use_callback
- Test components in isolation
- Configure Dioxus.toml for platform-specific builds

**Quick Reference Checklist:**
- [ ] Components are small and focused
- [ ] Props use appropriate lifetime annotations
- [ ] State management strategy chosen (local vs global)
- [ ] Async operations handle errors gracefully
- [ ] User inputs validated and sanitized
- [ ] Routing configured for navigation
- [ ] Event handlers use proper closure patterns
- [ ] Expensive computations use useMemo
- [ ] Side effects use useEffect
- [ ] Project structure follows conventions

## Conclusion

Dioxus brings React-inspired patterns to Rust, enabling developers to build performant, type-safe UIs across multiple platforms. Its cross-platform capabilities and compile-time guarantees make it an excellent choice for teams investing in Rust while wanting familiar component-based architecture. However, the framework's youth and smaller ecosystem require evaluation against project timelines and team expertise.

Choose Dioxus when you need cross-platform UIs with Rust's performance and safety guarantees. For mature ecosystems or rapid prototyping, consider established JavaScript frameworks.

## Resources

- **Official Documentation**: https://dioxuslabs.com/learn/0.5/
- **GitHub Repository**: https://github.com/DioxusLabs/dioxus
- **Examples**: https://github.com/DioxusLabs/dioxus/tree/main/examples
- **Awesome Dioxus**: https://github.com/DioxusLabs/awesome-dioxus
- **Community Discord**: https://discord.gg/XgGxMSkvUM
- **Dioxus Blog**: https://dioxuslabs.com/blog
- **YouTube Tutorials**: Search "Dioxus Rust Tutorial"
- **Rust Book**: https://doc.rust-lang.org/book/
