# Implementation Rollup 2026-04-24

이 문서는 2026-04-24 기준으로 실제 구현 레포에 반영한 변경을 한 번에 정리한다.

## 1. 운영 이미지 정책 통일

모든 운영 배포는 아래 규칙으로 통일했다.

- registry: Amazon ECR
- repository naming: `${deploy_environment}-${service_name}`
- monitoring component naming: `${deploy_environment}-monitoring-service-<component>`
- immutable deploy tag: `${GITHUB_SHA}`
- floating tag: `latest`는 `main` 또는 `master`에서만 추가 발행
- 운영 compose: `build:` 대신 `image:` 사용
- 운영 반영 방식: `docker compose pull && docker compose up -d`

## 2. Build/Run 분리

앱 서비스 `gateway-service`, `auth-service`, `user-service`, `authz-service`, `editor-service`는 Compose를 두 계층으로 분리했다.

- 실행 전용:
  - `docker/compose.yml`
  - `docker/dev/compose.yml`
  - `docker/prod/compose.yml`
- 빌드 전용:
  - `docker/compose.build.yml`

원칙:

- `dev`는 `compose.build.yml`을 추가로 겹쳐 local build를 허용한다.
- `prod`는 실행 전용 compose만 사용하고 build secret을 받지 않는다.
- private package 접근용 `GH_TOKEN`, `GITHUB_ACTOR`는 build 단계에만 사용한다.

## 3. 서비스별 구현 변경

### gateway-service

- prod compose를 `GATEWAY_IMAGE` 기반 image-only 구조로 고정
- base compose의 runtime 기본 이미지를 `gateway-service:dev`로 정리
- `docker/compose.build.yml` 추가
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 분리
- Docker 운영 문서를 ECR 기준으로 정리

### auth-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `AUTH_SERVICE_IMAGE` 기반 image-only로 유지
- `scripts/run.docker.sh`를 dev build/prod pull 구조로 정리
- Docker 문서를 ECR/image-only 기준으로 갱신

### user-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `USER_SERVICE_IMAGE` 기반 image-only로 고정
- `scripts/run.docker.sh`에서 prod build 금지
- Docker 문서를 build/run 분리 기준으로 갱신

### authz-service

- base compose를 image-first로 전환
- dev build를 `docker/compose.build.yml`로 분리
- prod compose를 `AUTHZ_SERVICE_IMAGE` 기반 image-only로 고정
- `scripts/run.docker.sh`에서 prod build 금지
- CI/구현 문서를 ECR 기준으로 갱신

### editor-service

- prod compose를 `EDITOR_SERVICE_IMAGE` 기반 image-only로 고정
- dev build를 `docker/compose.build.yml`로 분리
- `scripts/run.docker.sh`에서 prod build 금지
- README에 운영 pull 구조와 dev build 분리 원칙 반영

### redis-service

- prod compose를 `REDIS_IMAGE` 기반 image-only로 전환
- exporter 이미지를 `REDIS_EXPORTER_IMAGE`로 외부 제어 가능하게 정리
- CD workflow를 Amazon ECR push 기준으로 전환
- `contract.lock.yml`의 image registry를 ECR로 수정

### monitoring-service

- prod compose를 `PROMETHEUS_IMAGE`, `GRAFANA_IMAGE`, `LOKI_IMAGE`, `PROMTAIL_IMAGE` 기반 image-only로 전환
- CD workflow를 Amazon ECR push 기준으로 전환
- README와 운영 문서를 ECR/image-only 기준으로 갱신
- `contract.lock.yml`의 image registry를 ECR로 수정

## 4. 공통 문서/템플릿 변경

- [shared/ci-cd.md](./ci-cd.md): image stage, ECR naming, immutable tag, build/run 분리 규칙 추가
- [shared/single-ec2-deployment.md](./single-ec2-deployment.md): single EC2 운영에서도 image-only 배포 규칙 반영
- [templates/single-ec2/README.md](../templates/single-ec2/README.md): ECR image URI 주입 기준 반영
- [templates/single-ec2/env/](../templates/single-ec2/env/): 서비스별 `*_IMAGE` 변수 추가
- [templates/contract-lock-template.yml](../templates/contract-lock-template.yml): 기본 image registry를 ECR로 변경
- [templates/github-actions-contract-check.yml](../templates/github-actions-contract-check.yml): ECR login 예시로 변경
- [registry/repositories.yml](../registry/repositories.yml): 기본 CD profile의 image registry를 ECR로 정리

## 5. 남은 운영 작업

구현은 끝났고 실제 배포 전에는 아래만 채우면 된다.

- Amazon ECR repository 생성
- GitHub Actions secret/variable 등록
- 배포 대상의 ECR pull 권한 부여
- 서비스별 `.env.prod`에 실제 이미지 URI와 시크릿 값 입력
- CI/CD 실행 후 health check
