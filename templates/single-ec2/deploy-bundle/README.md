# Single EC2 Deploy Bundle

이 디렉터리는 앱 레포를 EC2에 clone하지 않고, ECR 이미지와 배포용 manifest만으로 단일 EC2를 올리기 위한 self-contained 번들이다.

구성:

- `docker-compose.backend.yml`: backend 7개와 내부 DB/Redis/monitoring 정의
- `docker-compose.frontend.yml`: `editor-page`, `explain-page` 정의
- `.env.backend.example`: backend/monitoring 변수 예시
- `.env.frontend.example`: frontend 변수 예시
- `config/`: MySQL 초기화와 설정 파일
- `scripts/deploy-stack.sh`: 전체 pull/up/down/ps/logs 스크립트
- `scripts/cleanup-old-clones.sh`: `/opt/services` 아래 예전 clone 디렉토리 제거 스크립트

## 목적

이 번들은 아래 상황을 전제로 한다.

1. CI/CD는 이미 ECR에 이미지를 push한다.
2. EC2는 이미지를 pull해서 실행만 한다.
3. EC2에는 앱 레포 전체를 둘 필요가 없다.
4. Nginx는 [../nginx.single-ec2.conf.example](../nginx.single-ec2.conf.example) 기준으로 별도 적용한다.

## 권장 배치

```text
/opt/deploy/
  docker-compose.backend.yml
  docker-compose.frontend.yml
  .env.backend
  .env.frontend
  config/
  scripts/
  nginx.single-ec2.conf.example
```

## 사용 순서

1. 이 디렉터리를 EC2의 `/opt/deploy`로 복사한다.
2. `.env.backend.example`을 `.env.backend`로 복사해 실제 값으로 채운다.
3. `.env.frontend.example`을 `.env.frontend`로 복사해 실제 값으로 채운다.
4. 기존 `/opt/services` clone 디렉터리를 정리하려면 `scripts/cleanup-old-clones.sh`를 실행한다.
5. `scripts/deploy-stack.sh up`으로 전체 스택을 실행한다.
6. Nginx 설정은 `../nginx.single-ec2.conf.example`을 적용한다.

## 예시

```bash
cd /opt/deploy
cp .env.backend.example .env.backend
cp .env.frontend.example .env.frontend
vi .env.backend
vi .env.frontend

FORCE=true ./scripts/cleanup-old-clones.sh /opt/services
./scripts/deploy-stack.sh up
```

## 주의

- 이 번들은 앱 레포 source code 없이 동작하도록 구성돼 있다.
- 실제 배포 단위는 Git이 아니라 ECR image다.
- `editor-page`, `explain-page`는 외부에서 직접 공개하지 않고 `127.0.0.1`에 bind한 뒤 Nginx로 프록시한다.
- backend 서비스는 host publish 없이 Docker network alias로만 통신한다.
