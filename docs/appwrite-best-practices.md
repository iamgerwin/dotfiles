# Appwrite Best Practices

## Overview
Concise, actionable guidance for Appwrite projects.

## Project Structure
- Keep services/modules organized by domain.
- Separate infra-as-code (e.g., Terraform) from app code.

## Environment & Config
- Use `.env` with placeholders; never commit secrets.
- Prefer scoped API keys and least-privilege roles.

## Security
- Enforce auth rules at collection/bucket level.
- Rotate keys regularly; store secrets in a manager.

## Data
- Define indexes for frequent queries.
- Use validation rules on collections.

## Testing
- Mock Appwrite SDK for unit tests; integration tests hit a local stack.

## Deployment
- Automate infra; version schemas; migrate with scripts.

## Troubleshooting
- Enable structured logs; tag requests with request IDs.

## References
- https://appwrite.io/docs
