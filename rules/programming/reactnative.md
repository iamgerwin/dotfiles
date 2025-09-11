# React Native Best Practices and Bad Code Avoidance

## Project Structure and Organization
- Organize code into logical folders: `components`, `screens`, `services`, `utils`, `assets`.
- Keep components small and focused on a single responsibility.
- Separate presentation components from container components (smart vs dumb components).
- Avoid deeply nested folders and overly complex structures.

## State Management
- Use appropriate state management libraries based on app complexity (Context API, Redux, MobX, Recoil).
- Avoid excessive use of local state when global state is better suited.
- Keep business logic out of UI components; use hooks or separate services.
- Use immutable state updates to prevent unintended side effects.

## Performance Optimization
- Use `React.memo` and `PureComponent` to prevent unnecessary re-renders.
- Use FlatList or SectionList for rendering large lists with proper keys.
- Avoid anonymous functions and inline objects in `render` methods or JSX props to reduce re-renders.
- Use native driver for animations where possible (`useNativeDriver: true`).
- Optimize images (size, format) and cache them efficiently.

## Code Quality and Maintainability
- Follow ESLint and Prettier for consistent code style.
- Write readable, self-documenting code with meaningful variable and function names.
- Extract complex logic into reusable hooks or utility functions.
- Avoid hardcoding strings; use localization libraries like `react-i18next`.
- Handle errors gracefully with proper try/catch blocks and user feedback.

## Navigation
- Use React Navigation or similar libraries for handling navigation.
- Avoid nesting navigators unnecessarily.
- Manage navigation state properly and avoid memory leaks.

## Asynchronous Programming
- Use async/await consistently for Promises.
- Handle loading, success, and error states carefully.
- Avoid blocking the UI thread with heavy synchronous work.

## Testing
- Write unit tests with Jest and React Native Testing Library.
- Write integration and end-to-end tests with Detox or Appium.
- Test critical user flows and component interactions.

## Security
- Avoid storing sensitive data in plaintext; use secure storage libraries.
- Sanitize inputs and handle permissions responsibly.
- Keep dependencies updated to avoid vulnerabilities.

## Styling
- Use StyleSheet API or styled-components for better performance and maintainability.
- Avoid inline styles for performance-sensitive components.
- Support different screen sizes and pixel densities with responsive design best practices.

## Logging and Debugging
- Use console logs sparingly; prefer dedicated logging tools like Sentry.
- Remove debug code before production builds.
- Use React Native Debugger or Flipper for efficient debugging.

## Common Anti-Patterns to Avoid
- Mixing UI and business logic.
- Overusing setState causing unnecessary component updates.
- Large components with multiple responsibilities.
- Ignoring platform differences (Android/iOS).
- Committing sensitive data or `.env` files to repositories.

---

Following these React Native best practices will help build maintainable, performant, and user-friendly mobile apps that are easier to scale and debug.
