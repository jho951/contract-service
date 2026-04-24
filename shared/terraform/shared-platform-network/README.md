# Shared Platform Network Terraform

이 스택은 모든 서비스가 함께 사용하는 공통 네트워크를 만든다.

생성 리소스:

- shared VPC
- public subnet 2개
- private subnet 2개
- Internet Gateway
- 단일 NAT Gateway
- public/private route table
- Route53 private hosted zone

## 기본 의도

- gateway-service는 이 VPC의 public subnet에 놓인 public ALB를 사용한다.
- auth-service, user-service, authz-service, editor-service는 이 VPC의 private subnet과 internal ALB를 사용한다.
- redis-service, monitoring-service도 같은 private subnet에 배치한다.
- 서비스 간 이름 해석은 private hosted zone으로 통일한다.

## 적용

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## 주요 출력값

- `vpc_id`
- `vpc_cidr`
- `public_subnet_ids`
- `private_subnet_ids`
- `private_hosted_zone_id`
- `private_hosted_zone_name`

## 서비스 Terraform 연결

이 출력값을 각 서비스 repo의 `infra/terraform/terraform.tfvars`에 넣는다.

gateway-service 예시:

```hcl
create_vpc = false

existing_vpc_id             = "vpc-..."
existing_public_subnet_ids  = ["subnet-public-a", "subnet-public-c"]
existing_private_subnet_ids = ["subnet-app-a", "subnet-app-c"]
existing_vpc_cidr           = "10.0.0.0/16"

alb_internal                = false
app_ingress_cidrs           = ["0.0.0.0/0"]
test_listener_ingress_cidrs = ["10.0.0.0/16"]
```

internal service 예시:

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

Redis는 ALB를 쓰지 않고 private subnet 주소와 security group으로 직접 제한한다.
