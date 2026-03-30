# Contract Automation

계약 변경 누락을 줄이기 위해 서비스 PR에서 자동 점검을 수행합니다.

## 제공 스크립트
- `scripts/contract-impact-check.sh`

이 스크립트는 서비스 코드 변경 파일을 보고 계약 영향 영역(`routing/headers/security/errors/env`)을 감지합니다.
영향이 있으면 PR 내에서 `CONTRACT_SYNC.md` 갱신이 있었는지 검사합니다.
현재 스크립트는 `gateway`, `auth`, `user`, `redis`, `block` 서비스만 지원합니다.
`Editor-page`와 `Explain-page` 같은 프론트엔드 소비자 레포는 동일한 `CONTRACT_SYNC.md` 형식을 유지하되,
별도 CI나 수동 검토로 계약 동기화를 관리합니다.

## 사용법 (서비스 레포에서 실행)
```bash
# base ref 기준으로 현재 브랜치 diff 검사
bash <(curl -fsSL https://raw.githubusercontent.com/jho951/contract/main/scripts/contract-impact-check.sh) auth origin/main
```

또는 스크립트를 레포에 vendor 하여:
```bash
./scripts/contract-impact-check.sh auth origin/main
```

## 서비스 이름 인자
- gateway
- auth
- user
- redis
- block

## 실패 시 의미
- 계약 영향 변경이 있는데 `CONTRACT_SYNC.md`가 갱신되지 않았음을 의미합니다.
- 조치:
  1. `contract` 레포 문서/OpenAPI 먼저 갱신
  2. 서비스 레포 `CONTRACT_SYNC.md`에 contract SHA 반영

## 권장 CI 적용
- 서비스 PR CI 단계에 스크립트를 추가해 merge gate로 사용
- 예시 워크플로: `docs/examples/github-actions-contract-check.yml`
