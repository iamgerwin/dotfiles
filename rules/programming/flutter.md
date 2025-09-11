# Flutter Best Practices and Bad Code Avoidance

## Project Structure and Organization
- Use a scalable folder structure: separate `lib` into logical folders like `screens`, `widgets`, `models`, `services`, and `utils`.
- Keep widgets small and reusable.
- Separate UI code from business logic using state management patterns (Provider, Riverpod, Bloc, etc.).
- Avoid deeply nested widget trees; extract widgets to improve readability.

## State Management
- Choose a clear state management solution suited to your app’s complexity.
- Avoid putting business logic directly inside UI widgets.
- Isolate side effects and asynchronous calls in controllers, services, or view models.
- Keep state immutable where possible to avoid unexpected mutations.

## UI and Layout
- Use composition over inheritance for creating widgets.
- Prefer declarative UI with clear separation of concerns.
- Avoid rebuilding large parts of UI unnecessarily; optimize with `const` constructors and `shouldRebuild` checks.
- Use Flutter’s built-in widgets for accessibility support.

## Code Quality and Maintainability
- Use Dart’s `effective_dart` style guide and format code with `dart format`.
- Write meaningful names for variables, methods, and widgets.
- Avoid large widget classes and methods; break them down into smaller components.
- Use comments sparingly and only for complex logic.
- Write unit and widget tests to cover critical functionality.

## Performance
- Use `const` constructors wherever possible to reduce widget rebuilds.
- Avoid heavy computations or synchronous operations on the main UI thread.
- Cache images and data efficiently.
- Prefer lazy-loading lists with `ListView.builder`.
- Dispose controllers and streams to avoid memory leaks.

## Asynchronous Programming
- Use `async/await` and `Future` properly for asynchronous calls.
- Handle errors and loading states gracefully.
- Avoid blocking UI during async operations by using appropriate indicators.

## Dependency Management
- Keep `pubspec.yaml` dependencies minimal and up-to-date.
- Avoid including unnecessary or heavy packages.
- Use dependency injection tools like `get_it` for better testability and decoupling.

## Testing
- Write unit tests for business logic and utility functions.
- Write widget tests to verify UI components.
- Use integration tests for end-to-end user flow validation.
- Mock dependencies and services during testing.

## Logging and Error Handling
- Use centralized error reporting with tools like Sentry or Firebase Crashlytics.
- Handle exceptions gracefully and provide user-friendly error messages.
- Avoid printing sensitive information in logs.

## Accessibility
- Support screen readers by labeling UI elements appropriately.
- Use proper color contrast and scalable text.
- Test your app using accessibility tools regularly.

## Common Anti-Patterns to Avoid
- Mixing UI code and business logic in the same widget.
- Overusing `setState` without considering more scalable state management.
- Using global variables and singletons without control.
- Writing monolithic widgets that are hard to maintain.
- Ignoring asynchronous error handling.
- Forgetting to dispose of controllers, streams, or animations.

---

Following these Flutter best practices helps build maintainable, performant, and user-friendly mobile applications that are easy to scale and debug.
