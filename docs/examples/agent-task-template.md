# Agent Task Template

## Goal
- 무엇을 계약 기준으로 맞추는지 1~2줄로 명시

## Contract Source
- Repo: `https://github.com/jho951/contract`
- Commit SHA: `<contract-sha>`
- Referenced Docs:
  - `contracts/routing.md`
  - `contracts/headers.md`
  - `contracts/security.md`
  - `contracts/env.md`
  - `contracts/openapi/<service>.v1.yaml`

## Impacted Services
- `Api-gateway-server (main)`:
- `Auth-server (main)`:
- `User-server (main)`:
- `Redis-server (main)`:
- `Block-server (dev)`:
- `Editor-page (main)`:
- `Explain-page (main)`:

## Change Plan
1. contract 문서/OpenAPI 갱신
2. 서비스 구현 반영
3. `CONTRACT_SYNC.md` 업데이트
4. 검증/증빙

## Validation
- 실행 명령:
  - `<test-or-smoke-command-1>`
  - `<test-or-smoke-command-2>`
- 결과 요약:
  - `<pass/fail + 핵심 로그>`

## PR Body Snippet
```md
Contract SHA: <contract-sha>
Contract Areas: routing, headers, security, env, openapi
Validation: <commands/results>
```
