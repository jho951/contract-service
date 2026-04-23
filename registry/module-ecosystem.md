# Module Ecosystem

이 문서는 현재 프론트엔드/서버에서 사용 중인 외부 모듈과, 추후 계약/구현 확장 시 붙을 모듈들을 정리한다.

## 현재 프론트엔드 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `Ui-components-module` | `https://github.com/jho951/Ui-components-module` | 프론트엔드 공통 UI 컴포넌트 npm 모듈 |

### 적용 의도
- 프론트엔드 명세가 완전히 고정되기 전에도 UI 토큰과 컴포넌트 일관성을 유지한다.
- Editor-page, Explain-page 같은 소비자 레포는 이 모듈을 통해 공통 UI를 재사용할 수 있다.
- UI 구현의 세부 사항은 프론트엔드 레포가 소유하고, contract 레포는 “어떤 화면 흐름이 어떤 계약을 소비하는지”만 관리한다.

## 현재 서버 2계층 Platform

3계층 서비스는 1계층 OSS를 직접 조립하지 않고 2계층 platform starter/BOM과 sanctioned add-on, public SPI를 소비한다.

기준은 local `BE/platform` 구현과 각 서비스 main 브랜치 build 파일이다.

| Platform | Current Service Baseline | Absorbs | Purpose |
| --- | --- | --- | --- |
| `platform-security` | `3.0.1` 기본선. `editor-service`는 아직 `3.0.0`을 pin | `auth`, `ip-guard`, `rate-limiter` | 인증/인가 기본 조립, boundary, gateway header, IP guard, rate limit |
| `platform-governance` | `3.0.1` 기본선. `editor-service`는 아직 `3.0.0`을 pin | `audit-log`, `policy-config`, plugin-policy-engine config compatibility | 감사, 운영 정책, policy config, governance decision chain |
| `platform-resource` | `3.0.0` | `file-storage`, `notification` | resource lifecycle, metadata/catalog, storage/notification orchestration |
| `platform-integrations` | `3.0.1` runtime BOM 기준. `editor-service` bridge는 아직 `2.0.0` | platform bridge | security/resource event를 governance audit으로 연결하는 optional bridge |

### 서비스별 적용 매트릭스
| Service | Current Modules | Notes |
| --- | --- | --- |
| `gateway-service` | `platform-runtime-bom 3.0.1`, `platform-governance-starter`, `platform-security-starter`, `platform-security-hybrid-web-adapter`, `platform-security-governance-bridge` | Gateway 고유 `GatewayPlatformSecurityWebFilter`와 `HybridSecurityRuntime`이 edge flow를 소유한다. |
| `auth-service` | `platform-runtime-bom 3.0.1`, `platform-governance-starter`, `platform-security-starter`, `platform-security-auth-bridge-starter`, `platform-security-ratelimit-bridge-starter`, `platform-security-governance-bridge` | cookie/session bridge와 issuer adapter를 서비스가 제공하고, platform starter가 이를 소비한다. |
| `user-service` | `platform-runtime-bom 3.0.1`, `platform-governance-starter`, `platform-security-starter`, `platform-security-ratelimit-bridge-starter`, `platform-security-governance-bridge` | `AuditSink`, `JwtDecoder`, prod Redis `RateLimiter`를 서비스가 제공한다. |
| `authz-service` | `platform-runtime-bom 3.0.1`, `platform-governance-starter`, `platform-security-starter`, `platform-security-legacy-compat`, `platform-security-web-api`, `platform-security-governance-bridge` | internal auth 기본 모드는 `HYBRID`이고 legacy secret compat를 아직 유지한다. |
| `editor-service` | `platform-runtime-bom 3.0.1`, `platform-governance/security/resource BOM 3.0.0`, `platform-governance-starter`, `platform-security-starter`, `platform-security-web-api`, `platform-resource-starter`, `platform-resource-jdbc`, `platform-security-governance-bridge 2.0.0`, `platform-resource-governance-bridge 2.0.0`, runtime `platform-resource-support-local` | local resource backing은 support-local이 맡고, 운영 storage 위치만 서비스가 정한다. |
| `monitoring-service` | only if it becomes a custom Spring Boot/admin API service | observability wrapper는 현재 2계층 platform 소비 대상이 아니다. |
| `redis-service` | not applied | real Redis infra는 현재 2계층 platform 소비 대상이 아니다. |

### 적용 기준
- 3계층 서비스는 기본적으로 `platform-*-starter`, release-train BOM, sanctioned add-on, public SPI만 안다.
- 서비스 차이는 platform 내부 모듈이 아니라 `platform.security.service-role-preset` 같은 preset과 service-owned collaborator bean으로 표현한다.
- bridge artifact는 기본 탑재가 아니라 두 platform의 event/audit 연결이 필요할 때만 추가한다.
- 서비스는 보안/감사 framework를 만들지 않고 도메인 rule과 use case만 구현한다.
- platform-governance의 공식 운영 sink SPI는 `AuditSink`다.
- 서비스 도메인 audit 구현은 `AuditLogRecorder`보다 `AuditLogger` 또는 `AuditSink`를 우선 사용한다.
- `AuditLogRecorder`는 `platform-governance-adapter-auditlog`에 있는 bridge/test/compat용 adapter로 보고, mainline starter surface로 설명하지 않는다.
- `redis-service`가 실제 Redis 인프라라면 2계층 platform 적용 대상이 아니다.
- `monitoring-service`가 Prometheus/Grafana wrapper라면 2계층 platform 적용 대상이 아니다.

### 현재 적용 예외
- `gateway-service`는 `platform-security-hybrid-web-adapter`를 sanctioned add-on으로 쓰지만, gateway 고유 `GatewayPlatformSecurityWebFilter`와 `HybridSecurityRuntime`이 edge filter chain을 계속 소유한다. `GatewayApplication`은 `PlatformSecurityHybridWebAdapterAutoConfiguration`만 exclude 한다.
- `auth-service`는 `AuthPlatformIssuerAdaptersConfiguration`에서 raw `TokenService`, `SessionStore` adapter를 만들고, `PlatformSecurityRequestAttributeBridgeFilter`가 cookie/session과 internal caller proof를 request attribute로 브리지한다.
- `user-service`는 `UserPlatformRuntimeConfiguration`에서 `AuditSink`, `JwtDecoder`, prod Redis `RateLimiter`를 제공한다.
- `authz-service`는 `platform-security-legacy-compat`와 `AuthzInternalRequestAuthorizer`를 함께 사용해 `JWT`와 legacy secret 호환 경로를 `HYBRID` 모드로 유지한다. prod 전용 raw `RateLimiter` bean은 남아 있지만 bridge starter는 아직 추가하지 않았다.
- `editor-service`는 더 이상 `platform-resource-core` 구현을 직접 가져오지 않는다. local fallback은 runtime `platform-resource-support-local`이 맡고, 서비스는 `platform-security-web-api`로 custom `SecurityFailureResponseWriter`만 구현한다. 다만 prod 전용 raw `RateLimiter` bean은 남아 있고 bridge starter는 아직 추가하지 않았다.

### 감사 이벤트 대상
| Service | Representative Events |
| --- | --- |
| `auth-service` | 로그인 성공/실패, MFA, refresh, logout, session revoke |
| `authz-service` | 정책 생성/수정/삭제, role grant/revoke, delegation, authorization decision |
| `user-service` | 프로필 수정, visibility/privacy 변경, social link add/remove |
| `Gateway` | 인증 프록시 허용/거부, admin IP guard 차단, header normalization |
| `Editor` / `editor-service` | 문서/블록 수정, 공유, 삭제, 복구, 게시 |
| `redis-service` | 캐시 무효화, 운영자 수준 키 조작 |

## 추후 확장 서버 모듈
| Module | Repo | Purpose |
| --- | --- | --- |
| `ip-guard` | `https://github.com/jho951/ip-guard.git` | 관리자 접근 제한, IP allow/deny, edge 보호 정책 |
| `rate-limiter` | `https://github.com/jho951/ratelimiter.git` | 요청 제한, abuse 방지, 보호 정책 |
| `feature-flag` | `https://github.com/jho951/feature-flag.git` | 기능 노출 제어, 점진 롤아웃, 실험 플래그 |
| `policy-config` | `https://github.com/jho951/policy-config.git` | 정책 정의/배포/버전 관리 |

### 적용 방향
- `ip-guard`는 Gateway의 관리자/internal route 경계에서 접근 제한 정책으로 적용한다.
- `rate-limiter`는 Gateway 또는 Auth/Authz 경계에서 보호 정책과 함께 적용한다.
- `feature-flag`는 프론트/백엔드의 점진 배포와 실험 플로우에 사용한다.
- `policy-config`는 Authz 정책 모델, delegation, versioning과 결합해 운영한다.

## 책임 분리
| Area | Source of Truth |
| --- | --- |
| UI 컴포넌트 구현 | `Ui-components-module` 또는 각 프론트엔드 레포 |
| 인증/세션 | `auth` + `auth-service` 계약 |
| 감사 추적 | `audit-log` + 서비스 감사 계약 |
| 정책 평가 | `plugin-policy-engine` + `repositories/authz-service/*` |
| 관리자 접근 제한 | `ip-guard` + Gateway 정책 |
| 요청 제한 | `rate-limiter` + Gateway/Authz 정책 |
| 기능 노출 | `feature-flag` + 각 서비스/프론트 계약 |
| 정책 정의 | `policy-config` + `repositories/authz-service/*` |

## 계약 연결
- 프론트엔드 소비자 계약은 `contract.lock.yml`과 README contract source 섹션에서 외부 UI 모듈 사용 여부를 기록한다.
- 서버 확장 모듈은 `Authz` 정책/캐시/버전 문서와 함께 갱신한다.
- 외부 모듈이 추가되면 이 문서를 먼저 갱신하고, 그다음 서비스 레포 README와 `contract.lock.yml`을 맞춘다.
