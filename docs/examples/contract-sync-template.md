# CONTRACT_SYNC.md Template

> Copy this file into each service or frontend repo as `CONTRACT_SYNC.md` and fill in the placeholders.

## Repository
- Repo: `<repo-url>`
- Branch: `<branch>`
- Role: `<backend-service|frontend-consumer>`

## Contract Source
- Contract Repo: `https://github.com/jho951/contract`
- Contract Commit SHA: `<contract-sha>`
- Latest Sync Date: `<YYYY-MM-DD>`

## Referenced Contract Docs
- `contracts/routing.md`
- `contracts/headers.md`
- `contracts/security.md`
- `contracts/errors.md`
- `contracts/env.md`
- `contracts/openapi/*.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `errors`
  - `env`
  - `openapi`
- Affected Endpoints or Flows:
  - `<endpoint-or-ui-flow-1>`
  - `<endpoint-or-ui-flow-2>`

## Service/Frontend Notes
### Backend Service Repos
- `main` or `dev` branch must match the adoption-matrix branch.
- Keep implementation aligned with contract before merging service changes.

### Frontend Consumer Repos
- Keep API request/response shapes aligned with the contract and OpenAPI.
- Record the UI flow or page that depends on each contract change.
- If the frontend uses mock data or fallback behavior, document it here.

## Validation
- Commands:
  - `<smoke-or-test-command-1>`
  - `<smoke-or-test-command-2>`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
