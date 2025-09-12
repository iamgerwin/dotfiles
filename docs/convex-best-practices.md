# Convex Best Practices

## Overview
Practical defaults for Convex apps.

## Project Structure
- Keep queries and mutations grouped by domain.

## Environment & Config
- Configure Convex env vars via dashboard or CLI; avoid hardcoding.

## Security
- Use auth helpers; validate inputs at the edge.

## Data
- Model documents with explicit indexes; avoid unbounded scans.

## Testing
- Unit test functions; e2e uses a seeded dev instance.

## Deployment
- Automate via CI; use preview deployments for branches.

## Troubleshooting
- Add structured logging; track latency of queries/mutations.

## References
- https://docs.convex.dev/
