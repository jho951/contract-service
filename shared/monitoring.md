# Shared Monitoring Contract

`shared/monitoring.md`는 `monitoring-service`와 각 서비스가 맞춰야 하는 공통 관측 기준을 정의한다.

## Required Signals
| Signal | Baseline | Notes |
| --- | --- | --- |
| liveness | service-owned health endpoint | 컨테이너와 애플리케이션 자체 생존 여부를 본다. |
| readiness | critical dependency ready endpoint | DB, Redis, 필수 downstream 같은 실제 의존성 준비 상태를 반영한다. |
| metrics | Spring은 `/actuator/prometheus`, exporter는 `/metrics` | public route가 아니라 operator/private network에서만 노출한다. |
| logs | request/correlation id가 포함된 구조화 로그 | token, cookie, authorization header, raw password는 남기지 않는다. |
| traces | `X-Request-Id`, `X-Correlation-Id` 전파 | Gateway 재주입과 내부 호출 전달 규칙은 [headers.md](headers.md)를 따른다. |

## Metric Baseline
| Area | Minimum Coverage |
| --- | --- |
| Runtime | JVM/process/thread pool, CPU, memory, restart 여부 |
| Request | request count, latency, status code, error rate |
| Dependency | DB pool, Redis client, 외부 HTTP call, queue/executor |
| Domain | 서비스가 직접 소유하는 핵심 흐름 counter/timer |

## Service Rules
- health와 readiness는 같은 의미로 쓰지 않는다. liveness는 process 살아 있음, readiness는 요청 처리 준비 완료를 뜻한다.
- metrics path는 service contract와 `monitoring-service` target contract에 함께 반영한다.
- `uri`, `path`, `route` label은 raw user id나 document id가 아니라 템플릿 경로를 사용한다.
- metric label과 log field에 email, token, session id, authorization header 같은 민감값을 직접 남기지 않는다.
- DB/Redis 장애가 있어도 fail-open 전략을 택한 API와 readiness 판정은 동일한 것으로 취급하지 않는다. 서비스 contract에서 기준을 분리해서 명시한다.
- custom business metric은 service-owned prefix를 사용하고, dashboard에서 공통 JVM/HTTP metric과 함께 읽히도록 이름을 안정적으로 유지한다.

## Dashboard Baseline
| Section | 내용 |
| --- | --- |
| overview | `up`, request rate, p95 latency, 5xx rate |
| dependency | DB/Redis readiness, pool saturation, timeout/failure |
| domain | login/signup/permission/document flow처럼 서비스별 핵심 업무 지표 |
| logs | error burst와 request id 기반 drill-down |

## Adoption Rule
- 새 서비스가 adopted 상태가 되려면 health, readiness, metrics path와 기본 dashboard focus를 계약에 포함해야 한다.
- `monitoring-service` target에 추가되기 전까지는 observability adopted로 보지 않는다.
- Redis 같은 shared infra는 exporter 지표와 소비 서비스의 dependency 지표를 같이 본다.
