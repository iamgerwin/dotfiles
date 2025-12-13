# Frontend Code Review Checklist

## Component Architecture

- [ ] Components are focused and single-responsibility
- [ ] Proper component composition (not too nested)
- [ ] Presentational vs container components separated
- [ ] Props are minimal and well-defined
- [ ] Component naming is clear and consistent
- [ ] No prop drilling (use context/state management)
- [ ] Reusable components extracted appropriately

## TypeScript & Type Safety

- [ ] Proper types defined (no `any` unless justified)
- [ ] Interfaces/types exported where needed
- [ ] Generic types used appropriately
- [ ] Null/undefined handled properly
- [ ] Type assertions minimized
- [ ] Enums used for fixed sets of values

## Performance & Optimization

- [ ] Unnecessary re-renders prevented (memo, useMemo, useCallback)
- [ ] Large lists virtualized
- [ ] Images optimized and lazy-loaded
- [ ] Code splitting implemented where beneficial
- [ ] Bundle size impact considered
- [ ] API calls debounced/throttled where appropriate
- [ ] No memory leaks (cleanup in useEffect)

## Accessibility (a11y)

- [ ] Semantic HTML elements used
- [ ] ARIA labels where needed
- [ ] Keyboard navigation works
- [ ] Focus management handled
- [ ] Color contrast sufficient
- [ ] Screen reader friendly
- [ ] Alt text on images

## State Management

- [ ] State placed at appropriate level
- [ ] Local state vs global state chosen correctly
- [ ] State updates are immutable
- [ ] Derived state computed, not stored
- [ ] Loading/error states handled
- [ ] Optimistic updates where appropriate

## Styling

- [ ] Consistent with design system
- [ ] Responsive design implemented
- [ ] CSS classes are semantic
- [ ] No inline styles unless justified
- [ ] Dark mode considered (if applicable)
- [ ] Animations are performant (transform/opacity)

## Testing

- [ ] Unit tests for utility functions
- [ ] Component tests for UI logic
- [ ] Integration tests for user flows
- [ ] Edge cases covered
- [ ] Mocking used appropriately
- [ ] Tests are readable and maintainable

## Error Handling

- [ ] Error boundaries implemented
- [ ] API errors handled gracefully
- [ ] User feedback on errors
- [ ] Fallback UI provided
- [ ] Console errors resolved

## Code Quality

- [ ] No console.log statements left
- [ ] ESLint warnings resolved
- [ ] Prettier formatting applied
- [ ] Unused imports removed
- [ ] Dead code removed
- [ ] Complex logic commented

## Final Checks

- [ ] PR description is clear
- [ ] Screenshots/videos for UI changes
- [ ] Mobile view tested
- [ ] Cross-browser tested (if required)
- [ ] Environment variables documented
- [ ] No secrets in code
