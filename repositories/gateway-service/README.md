# Gateway Contract

Gateway는 외부 public API의 진입점이다. Public route versioning, 인증 채널 판정, trusted header 재주입, upstream routing을 소유한다.

## Source
| 항목 | 값 |
| --- | --- |
| Repo | https://github.com/jho951/gateway-service |
| Branch | `main` |
| Contract Lock | `contract.lock.yml` |

## 책임 경계
| 영역 | Gateway 책임 |
| --- | --- |
| Public route | `/v1/**`, `/v2/**` 같은 외부 경로 소유 |
| Auth proxy | Cookie/Bearer 인증 채널 판정과 Auth-service 검증 연동 |
| Header normalization | 외부 trusted header 제거 후 내부 header 재주입 |
| Admin guard | 관리자 경로에서 Authz 검증 호출 |
| Upstream routing | public route를 service upstream route로 변환 |
| Edge response | CORS, preflight, timeout, upstream error normalization |

## Current Platform Runtime
- `gateway-service` 현재 구현은 `platform-runtime-bom 3.0.1`, `platform-governance-bom 3.0.1`, `platform-security-bom 3.0.1`을 함께 사용한다.
- 런타임 모듈은 `platform-governance-starter`, `platform-security-starter`, `platform-security-hybrid-web-adapter`, `platform-security-governance-bridge`다.
- `GatewayApplication`은 `PlatformSecurityHybridWebAdapterAutoConfiguration`만 exclude 한다. platform starter 전체를 끄지 않는다.
- `GatewayPlatformSecurityConfiguration`은 `PlatformSecurityHybridWebAdapterMarker`, additive `SecurityPolicy`, `HybridSecurityRuntime`, `AuditSink`를 등록한다.
- 실제 edge 판정 흐름은 `GatewayPlatformSecurityWebFilter`가 auth-service 검증, platform policy 평가, deny 응답, downstream identity projection을 수행하는 현재 구조다.

## 읽는 순서
1. [responsibility.md](responsibility.md): Gateway 책임과 경계
2. [auth-proxy.md](auth-proxy.md): public auth route와 Auth-service upstream mapping
3. [auth.md](auth.md): 인증 채널과 token/session 처리
4. [../../shared/headers.md](../../shared/headers.md): 공통 trusted/trace header
5. [security.md](security.md): Gateway 보안 경계
6. [cache.md](cache.md): session/admin decision cache
7. [response.md](response.md): edge response policy
8. [env.md](env.md): 환경변수
9. [errors.md](errors.md): Gateway error
10. [execution.md](execution.md): 실행/운영

## 핵심 계약
| Public route | Upstream owner |
| --- | --- |
| `/v1/auth/**` | Auth-service |
| `/v1/users/**` | User-service |
| `/v1/permissions/**` | Authz-service |
| `/v1/documents/**` | Editor/Block domain |
| `/v1/admin/**` | Gateway + Authz |

## 관련 문서
- [Common Routing](../../shared/routing.md)
- [Common Headers](../../shared/headers.md)
- [Common Security](../../shared/security.md)
- [Common Audit](../../shared/audit.md)
- [Gateway Public OpenAPI](../../artifacts/openapi/gateway-service.public.v1.yaml)
