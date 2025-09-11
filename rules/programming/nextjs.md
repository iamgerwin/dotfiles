# Next.js Best Practices and Bad Code Avoidance

## Project Structure and Organization
- Use the file-based routing system effectively; organize pages clearly within the `/pages` or `/app` directory.
- Separate UI components (in `/components`) from pages and business logic.
- Use the built-in API routes (`/api`) for backend functionality, keeping it minimal and stateless.
- Collocate styles with components using CSS Modules, styled-jsx, or other CSS-in-JS solutions.

## Data Fetching
- Prefer the latest Next.js data fetching methods (`getStaticProps`, `getServerSideProps`, `getStaticPaths`, or React Server Components) depending on use case.
- Avoid mixing client-side and server-side fetching blindly; be purposeful about hydration and performance.
- Cache API data at proper levels (ISR, SWR, React Query) for optimal performance and UX.

## Performance Optimization
- Use Image Optimization with Next.js `<Image>` component for responsive and lazy-loaded images.
- Enable Automatic Static Optimization where possible to reduce server load.
- Minimize client bundle size by importing only necessary parts of libraries.
- Use dynamic imports (`next/dynamic`) to lazy load components that are not critical on initial load.

## Accessibility (a11y)
- Ensure keyboard navigability and screen reader support.
- Use semantic HTML and ARIA roles where needed.
- Test accessibility regularly with tools like Lighthouse or axe.

## Styling and Theming
- Use CSS Modules, Tailwind CSS, or styled-components for scoped and maintainable styles.
- Avoid inline styles that cannot be cached or reused.
- Implement theme support (dark mode, etc.) without causing layout shifts.

## Code Quality and Maintainability
- Use TypeScript for type safety and better developer experience.
- Keep components small and focused on a single responsibility.
- Use React hooks properly: avoid exhaustive dependencies warnings, and use custom hooks for reusable logic.
- Avoid deep prop drilling using context or state management libraries (e.g., Redux, Zustand, Recoil).
- Isolate side effects within `useEffect` and clean them up properly.

## Security
- Sanitize and validate user input on both client and API routes.
- Avoid exposing sensitive environment variables to the client side (`NEXT_PUBLIC_*` prefix for allowed variables only).
- Use HTTPS and secure cookies for authentication tokens.

## Testing
- Write end-to-end tests using frameworks like Cypress or Playwright.
- Use Jest and React Testing Library for unit and integration tests focusing on components and hooks.
- Test SSR and API routes separately.

## State Management
- Use React context or dedicated state management libraries only when needed.
- Avoid overcomplicating state logic; prefer simple state solutions.
- Keep server state and client state clearly separated.

## Internationalization (i18n)
- Use Next.js built-in i18n routing support.
- Make sure localized content is properly SSR’d or statically generated.
- Load translations efficiently and avoid duplication.

## Deployment and Environment
- Leverage static generation where possible for faster deployments.
- Use environment variables set up carefully for each environment.
- Take advantage of Next.js configuration options (`next.config.js`) to tailor builds.

## Common Anti-Patterns to Avoid
- Monolithic pages with complex and mixed responsibilities.
- Unnecessary client-side rendering when static or server-side rendering works better.
- Large JavaScript bundles without code splitting.
- Inconsistent or manual routing outside Next.js conventions.
- Ignoring accessibility and SEO best practices.
- Committing `.env` files with secrets to repos.
- Leaving hardcoded values like URLs or API keys in the client bundle.

---

Following these Next.js best practices helps write scalable, maintainable, and performant applications while leveraging the framework’s powerful features effectively.
