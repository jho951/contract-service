# Contributing

## PR 규칙
1. 변경 목적을 명시 (`bugfix`, `contract-update`, `breaking-change`)
2. 영향 서비스 체크
   - gateway
   - auth
   - user
   - redis
   - block(dev)
   - editor-page
   - explain-page
3. 변경 유형
   - Non-breaking
   - Breaking
4. 테스트 증빙
   - 계약 테스트 결과 또는 샘플 요청/응답

## 머지 조건
- 문서 + OpenAPI + 예시가 함께 갱신되어야 함
- Breaking change는 릴리즈 노트와 마이그레이션 절차 포함 필수

## AI Agent 작업 규칙
- 에이전트는 `docs/ai-agent-playbook.md` 절차를 따라 계약부터 수정해야 함
- 구현 레포 PR 본문에 아래 3가지를 반드시 포함
  - 참조한 contract 커밋 SHA
  - 적용한 계약 항목(routing/headers/security/env/openapi)
  - 검증 결과(최소 smoke test 또는 계약 테스트)
