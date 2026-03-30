# CONTRACT_SYNC.md

## Repository
- Repo: `https://github.com/jho951/Editor-page`
- Branch: `main`
- Role: `frontend-consumer`

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
- `contracts/openapi/gateway-edge.v1.yaml`
- `contracts/openapi/user-service.v1.yaml`
- `contracts/openapi/auth-service.v1.yaml`
- `contracts/openapi/block-service.v1.yaml`

## Impact Scope
- Contract Areas:
  - `routing`
  - `headers`
  - `security`
  - `errors`
  - `env`
  - `openapi`
- Affected Flows:
  - `문서 목록/상세 조회` -> `GET /v1/documents/**`
  - `문서 편집/저장/이동/복구/휴지통` -> `PATCH/POST /v1/documents/{documentId}/**`

## Frontend Notes
- Gateway 노출 경로는 `/v1/**` 기준으로만 사용한다.
- 문서 목록, 상세, 블록 조회는 `contracts/openapi/block-service.v1.yaml`과 맞춘다.
- 인증이 필요한 화면은 `Authorization: Bearer <token>` 전송을 전제로 한다.
- 휴지통, 복구, 이동, 관리자 블록 조작은 권한에 따라 UI 노출을 분기한다.
- mock data, fallback UI, feature-flag가 있으면 이 파일에 같이 기록한다.
- 계약 변경이 페이지 상호작용에 영향을 주면 같은 PR에서 갱신한다.

## Validation
- Commands:
  - `pnpm test`
  - `pnpm lint`
  - `pnpm build`
- Result:
  - `<pass/fail summary>`

## Sync Log
| Date | Contract SHA | Areas | Notes |
|---|---|---|---|
| `<YYYY-MM-DD>` | `<contract-sha>` | `<routing, headers, ...>` | `<short note>` |
