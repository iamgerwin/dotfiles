# Rust Frameworks

Best practices for web and application frameworks built with Rust, focusing on performance, type safety, and modern development patterns.

## Contents

- **[Axum](axum.md)** - Ergonomic web framework for building high-performance REST APIs and microservices
- **[Dioxus](dioxus.md)** - Cross-platform GUI library for building web, desktop, and mobile applications

## Overview

Rust frameworks leverage the language's performance characteristics, memory safety, and zero-cost abstractions to build fast, reliable applications. These frameworks provide developer-friendly APIs while maintaining Rust's compile-time guarantees.

## When to Use Rust Frameworks

- High-performance web services and APIs
- Applications requiring memory safety and zero-cost abstractions
- Systems programming with modern web capabilities
- Cross-platform applications from a single codebase
- Services with strict resource and latency requirements
- Projects prioritizing type safety and compile-time correctness

## Related Technologies

- **Tokio** - Async runtime powering Axum and other Rust frameworks
- **Tower** - Middleware ecosystem for composable request/response processing
- **Tauri** - Alternative Rust-based desktop framework (lighter than Electron)

## Getting Started

Both frameworks require:
- Rust toolchain (install via [rustup](https://rustup.rs))
- Basic understanding of Rust ownership and async/await
- Familiarity with component-based architectures (for Dioxus)
