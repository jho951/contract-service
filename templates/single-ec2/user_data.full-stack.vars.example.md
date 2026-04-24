# Full Stack User Data Variables Example

이 문서는 [user_data.full-stack.sh.tftpl](user_data.full-stack.sh.tftpl)에 넣어야 하는 템플릿 변수 목록을 정리한다.

## 필수 기본값

```hcl
deploy_user        = "ec2-user"
base_dir           = "/opt/services"
network_name       = "service-backbone-shared"
contract_repo_url  = "https://github.com/<owner>/service-contract.git"
contract_repo_ref  = "main"
include_monitoring = "true"
```

## 서비스 repo URL / ref

```hcl
gateway_repo_url    = "https://github.com/<owner>/gateway-service.git"
gateway_repo_ref    = "main"
auth_repo_url       = "https://github.com/<owner>/auth-service.git"
auth_repo_ref       = "main"
user_repo_url       = "https://github.com/<owner>/user-service.git"
user_repo_ref       = "main"
authz_repo_url      = "https://github.com/<owner>/authz-service.git"
authz_repo_ref      = "main"
editor_repo_url     = "https://github.com/<owner>/editor-service.git"
editor_repo_ref     = "main"
redis_repo_url      = "https://github.com/<owner>/redis-service.git"
redis_repo_ref      = "main"
monitoring_repo_url = "https://github.com/<owner>/monitoring-service.git"
monitoring_repo_ref = "main"
```

## env 파일 전달 방식

각 env 파일은 base64 인코딩 문자열로 넣는다.

예:

```bash
base64 -i gateway-service.env.prod.example | tr -d '\n'
```

템플릿 변수 이름:

```hcl
gateway_env_prod_b64    = "<base64>"
auth_env_prod_b64       = "<base64>"
user_env_prod_b64       = "<base64>"
authz_env_prod_b64      = "<base64>"
editor_env_prod_b64     = "<base64>"
redis_env_prod_b64      = "<base64>"
monitoring_env_prod_b64 = "<base64>"
```

## 비고

- `include_monitoring = "false"`면 monitoring repo/env는 생략할 수 있다.
- private repository라면 clone 가능한 URL 또는 사전 인증 방식이 필요하다.
- user data에 secret이 직접 들어가므로, 실제 운영에서는 장기적으로 Secrets Manager 또는 SSM Parameter Store로 옮기는 것이 맞다.
