# Deployment Topologies

이 문서는 2026-04에 실제로 적용했던 배포 방식과, 무중단 배포 요구 때문에 최종적으로 채택한 방식을 함께 남긴다.

대상 서비스:

- 앱 서비스: `gateway-service`, `auth-service`, `user-service`, `authz-service`, `editor-service`
- 인프라 서비스: `redis-service`, `monitoring-service`

## 0. 현재 계정 기준 운영 모드: 논리적 MSA, 물리적 단일 EC2 통합

현재 AWS Free Tier 제약에서는 아래 방식을 현행 운영 기준으로 둔다.

핵심 원칙:

- 서비스 경계와 코드베이스는 MSA로 유지한다.
- 배포는 단일 EC2 한 대에 통합한다.
- 실행은 `docker compose` 기반으로 묶는다.
- 외부 공개는 gateway만 담당한다.
- 나머지 서비스는 같은 host 내부 Docker network alias로만 통신한다.

현재 기본 배치:

```text
Internet / Client
  -> EC2 public IP or reverse proxy
  -> gateway-service
  -> auth-service
  -> user-service
  -> authz-service
  -> editor-service
  -> redis-service

monitoring-service
  -> 같은 EC2에 최소 구성으로 올리거나
  -> 비용/리소스 압박 시 비활성화
```

이 방식을 현재 기본값으로 두는 이유:

- NAT Gateway, ALB, Route53 private hosted zone, Fargate를 모두 켜면 Free Tier 범위를 쉽게 넘는다.
- 단일 EC2는 비용 예측이 가장 쉽고, 초기 검증 속도가 빠르다.
- 서비스별 repo, contract, env, monitoring 기준은 그대로 유지할 수 있다.

현재 운영 규칙:

1. gateway만 host port를 외부에 노출한다.
2. auth, user, authz, editor, redis는 가능하면 host 외부에 직접 노출하지 않는다.
3. 서비스 간 호출 주소는 `auth-service:8081`, `user-service:8082`, `authz-service:8084`, `editor-service:8083`, `redis:6379` 같은 compose alias를 기본으로 둔다.
4. monitoring은 리소스가 허용되면 같은 host에 함께 올리고, 그렇지 않으면 앱 서비스 우선으로 둔다.
5. 이 방식은 고가용성/무중단 기본값이 아니라 비용 최적화 개발/초기 운영 모드다.

실행 체크리스트와 서비스별 env/포트 정책은 [single-ec2-deployment.md](single-ec2-deployment.md)를 기준으로 본다.

즉, 현재 계정에서의 실제 선택은 다음 한 줄로 요약한다.

```text
MSA를 논리적으로 유지하되, 배포는 물리적으로 1대 EC2에 통합한다.
```

## 1. 먼저 적용했던 방식: EC2 + Docker Compose bootstrap

첫 번째 구현은 "서비스별 단일 EC2에 Docker Compose를 직접 올리는 방식"이었다.

의도:

- 서비스별 배포 단위를 빠르게 독립시킨다.
- `redis-service`, `monitoring-service`처럼 host 운영이 자연스러운 구성과 기준을 맞춘다.
- Terraform이 EC2, Security Group, IAM, bootstrap secret, `user_data`까지 책임지게 한다.

구현 구조:

1. Terraform이 EC2 인스턴스와 bootstrap secret을 만든다.
2. `user_data.sh.tftpl`이 서버에서 Docker, Compose, Git clone, env 파일 생성, `docker compose up -d`를 실행한다.
3. 앱 서비스는 `docker/prod/compose.yml`에서 host port publish를 사용해 cross-EC2 호출을 허용한다.
4. `monitoring-service`는 Prometheus/Grafana/Loki/Promtail 구성을 같은 방식으로 EC2에 올린다.

대표 구현 포인트:

```hcl
resource "aws_secretsmanager_secret" "bootstrap" {
  name = "${local.resource_prefix}-bootstrap"
}

resource "aws_instance" "service" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  user_data              = templatefile("${path.module}/user_data.sh.tftpl", { ... })
  vpc_security_group_ids = [aws_security_group.service.id]
}
```

```bash
SECRET_JSON="$(aws secretsmanager get-secret-value ...)"
APP_SECRET_ENV_JSON="$(printf '%s' "$SECRET_JSON" | jq -c '.app_secret_env // {}')"

write_env_file() {
  jq -r 'to_entries[] | "\(.key)=\(.value)"' <<<"$1" >> "$DEPLOY_ENV_FILE"
}

git clone "$REPOSITORY_URL" "$APP_DIR"
write_env_file "$APP_ENV_JSON"
write_env_file "$APP_SECRET_ENV_JSON"
docker compose -f docker/prod/compose.yml up -d
```

```yaml
services:
  auth-service:
    ports:
      - "${AUTH_SERVICE_HOST_BIND}:${AUTH_SERVICE_HOST_PORT}:8081"
```

앱 서비스에서 이 방식으로 남겼던 핵심 파일:

- `infra/terraform/main.tf`
- `infra/terraform/variables.tf`
- `infra/terraform/user_data.sh.tftpl`
- `infra/terraform/terraform.tfvars.example`
- `docker/prod/compose.yml`

이 방식이 유효한 곳:

- `redis-service`: self-managed Redis + exporter
- `monitoring-service`: Prometheus, Grafana, Loki, Promtail, exporter/agent

이 방식의 한계:

- 단일 EC2에서 `docker compose pull/up` 시 컨테이너 교체가 일어나므로 엄밀한 무중단 배포가 아니다.
- 앱 서비스가 여러 EC2로 나뉘면 health gate, draining, traffic shift를 Compose가 대신해주지 않는다.
- 무중단을 만들려면 결국 서비스별 2개 이상의 EC2, ALB, blue/green 스위칭을 추가로 구현해야 한다.

## 2. 장기 권장 방식: ECS/Fargate blue/green + EC2 hybrid

무중단 배포가 요구사항이 되면서 앱 서비스의 기준을 바꿨다.

최종 선택:

- `gateway-service`, `auth-service`, `user-service`, `authz-service`, `editor-service`
  -> ECS/Fargate + ALB + CodeDeploy blue/green
- `redis-service`, `monitoring-service`
  -> EC2 유지

이유:

- 앱 서비스는 stateless에 가깝고, ALB health check와 traffic shift가 중요하다.
- `redis-service`, `monitoring-service`는 host 운영과 exporter/agent 구성이 더 자연스럽다.
- 무중단의 핵심은 "새 task set을 health check로 검증한 뒤 트래픽을 옮기는 것"인데, ECS/Fargate + CodeDeploy가 이 요구에 직접 맞는다.

현재 앱 서비스 인프라 기준:

```hcl
resource "aws_ecs_service" "service" {
  desired_count = var.desired_count
  launch_type   = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }
}

resource "aws_codedeploy_deployment_group" "service" {
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}
```

현재 CD workflow 기준:

1. Docker image build
2. Amazon ECR push
3. 현재 ECS service의 task definition 조회
4. 새 image URI로 task definition revision 등록
5. CodeDeploy ECS deployment 생성
6. deployment success까지 wait

대표 workflow 구현 포인트:

```yaml
- name: Register new task definition revision
  run: |
    aws ecs describe-task-definition ...
    jq 'del(.taskDefinitionArn, .revision, .status, .registeredAt, .registeredBy)' taskdef.json \
      | jq --arg IMAGE "$IMAGE_URI" --arg NAME "$CONTAINER_NAME" '
          .containerDefinitions |= map(if .name == $NAME then .image = $IMAGE else . end)
        ' > taskdef-rendered.json
    aws ecs register-task-definition --cli-input-json file://taskdef-rendered.json

- name: Create CodeDeploy deployment
  run: |
    jq -n '{applicationName: $app, deploymentGroupName: $group, revision: {revisionType: "AppSpecContent", appSpecContent: {content: $content}}}' ...
    aws deploy create-deployment --cli-input-json file://deployment-input.json
```

현재 코드 기준 위치:

- 앱 서비스 Terraform: 각 서비스 repo의 `infra/terraform/`
- 앱 서비스 CD: 각 서비스 repo의 `.github/workflows/cd.yml`
- Redis EC2: `redis-service/infra/terraform/`
- Monitoring EC2: `monitoring-service/infra/terraform/`
- Shared VPC root: `shared/terraform/shared-platform-network/`

## 3. 장기 권장 라우팅 토폴로지

최종 라우팅 기본값은 다음처럼 확정한다.

```text
Internet / Client
  -> Public ALB
  -> gateway-service
  -> Internal ALB + Route53 private DNS
  -> auth-service / user-service / authz-service / editor-service

redis-service
  -> private subnet endpoint only
  -> no ALB
```

서비스별 endpoint 기본값:

- `gateway-service` -> `https://api.example.com`
- `auth-service` -> `http://auth.internal.platform.local`
- `user-service` -> `http://user.internal.platform.local`
- `authz-service` -> `http://authz.internal.platform.local`
- `editor-service` -> `http://editor.internal.platform.local`
- `redis-service` -> private subnet address only, ALB 미사용

현재 Terraform 코드가 반영하는 shared VPC 포인트:

```hcl
create_vpc = false

existing_vpc_id             = "vpc-..."
existing_public_subnet_ids  = ["subnet-public-a", "subnet-public-c"]
existing_private_subnet_ids = ["subnet-app-a", "subnet-app-c"]
existing_vpc_cidr           = "10.0.0.0/16"

alb_internal                          = true
alb_ingress_source_security_group_ids = ["sg-gateway-ecs-tasks"]
private_dns_zone_id                   = "Z123456789PRIVATE"
private_dns_name                      = "auth.internal.platform.local"
```

이 값들은 현재 다음 공통 구현으로 연결된다.

```hcl
locals {
  vpc_id             = var.create_vpc ? aws_vpc.main[0].id : var.existing_vpc_id
  public_subnet_ids  = var.create_vpc ? aws_subnet.public[*].id : var.existing_public_subnet_ids
  private_subnet_ids = var.create_vpc ? aws_subnet.private[*].id : var.existing_private_subnet_ids
  alb_internal       = var.alb_internal == null ? var.service_name != "gateway-service" : var.alb_internal
}

resource "aws_route53_record" "private_service" {
  count   = var.private_dns_zone_id != "" && var.private_dns_name != "" ? 1 : 0
  zone_id = var.private_dns_zone_id
  name    = var.private_dns_name
}
```

즉, 현재 코드는 "shared VPC + gateway만 public ALB + 나머지는 internal ALB/private DNS"를 장기 목표 구조로 직접 표현할 수 있는 상태다.

## 4. 실제 운영 판단

운영 기준은 다음처럼 고정한다.

1. 현재 Free Tier 계정에서는 단일 EC2 + Docker Compose를 실제 배포 기본값으로 둔다.
2. 무중단과 확장성이 중요한 정식 운영 단계로 넘어가면 앱 서비스는 ECS/Fargate로 승격한다.
3. Redis, Prometheus, Grafana, Loki처럼 host 성격이 강하면 승격 이후에도 EC2 유지 후보로 본다.
4. `docker/prod/compose.yml`은 현재 계정에서는 실제 배포 기준이고, 비용 제약이 해제되면 fallback/reference로 되돌린다.
5. 비교와 예외 판단은 각 서비스의 `troubleshooting`에 남기고, 공통 구현 이력은 이 문서에 누적한다.

남은 환경 작업:

- 현재 Free Tier 모드에서는 단일 EC2 compose env 파일과 공개 포트 정책을 먼저 확정한다.
- 비용 제약이 해제되면 `shared/terraform/shared-platform-network/`를 apply해서 shared VPC와 private hosted zone을 만든다.
- 그 다음 각 서비스 repo의 `terraform.tfvars`에 실제 subnet ID, security group ID, private hosted zone ID를 채운다.
