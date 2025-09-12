# Strapi Best Practices

## Overview
Guidelines for Strapi projects.

## Project Structure
- Keep components re-usable; group content-types by domain.

## Environment & Config
- Use environment configs; do not commit credentials.

## Security
- Lock down admin; enable CORS as needed; sanitize uploads.

## Data
- Plan content-types; write lifecycle hooks carefully; add indexes.

## Testing
- Snapshot API responses; seed minimal data for e2e.

## Deployment
- Use migrations/content transfer; back up databases.

## Troubleshooting
- Enable verbose logs in dev only; monitor 4xx/5xx rates.

## References
- https://docs.strapi.io/
