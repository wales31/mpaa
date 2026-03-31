# MPAA Web App Backend Transition Paper
## From Firebase to PHP + Apache (XAMPP)

**Prepared for:** Project stakeholders and technical review panel  
**Project:** MPAA Web Application  
**Date:** March 31, 2026

---

## 1) Executive Summary

The current MPAA web application is a React + Vite frontend with Firebase Authentication and Firestore as its backend services. This paper presents a complete, presentation-ready transition plan to move backend responsibilities to a **PHP + Apache stack running on XAMPP** while preserving existing product behavior.

The migration objective is to:
- Keep the current frontend UX and business flows intact.
- Replace Firebase-dependent backend capabilities with a self-hosted, API-first PHP backend.
- Use Apache (XAMPP) for HTTP serving and MySQL/MariaDB for persistent storage.
- Introduce secure authentication/session handling compatible with role-based access (`admin`, `user`).

This document is intentionally implementation-focused and can be used as a blueprint for engineering execution, QA validation, and deployment planning.

---

## 2) Current-State Assessment

### 2.1 Frontend and Runtime
- The app is a React TypeScript SPA built with Vite.
- Core business modules in UI include:
  - Farmers management
  - Milk collections
  - Payments lifecycle and status updates
  - Dashboard analytics and export flows

### 2.2 Current Backend Dependency Profile
The current backend contracts are Firebase-centric and include:
- **Firebase Auth** with Google popup sign-in.
- **Firestore** collections for `users`, `farmers`, `collections`, and `payments`.
- List, create, update, delete, and status transition workflows reflected in the UI.

### 2.3 Current Data Contracts (as implemented)
Current documented contracts define:
- `users/{uid}` with fields `uid`, `email`, `name`, `role`
- `farmers/{id}` with identity/contact/location/join metadata
- `collections/{id}` with milk amount/quality/timestamp/operator
- `payments/{id}` with amount/period/status/timestamp

These contracts provide a clear baseline for backend migration without changing user-facing features.

---

## 3) Problem Statement and Business Rationale

### 3.1 Why transition from Firebase to PHP + Apache (XAMPP)?
Potential strategic drivers:
- Preference for on-premise or self-managed infrastructure.
- Cost predictability compared to consumption-based cloud billing.
- Team familiarity with PHP/MySQL operations.
- Greater control over data governance and backup topology.

### 3.2 Constraints
- No functional regressions in core modules.
- Maintain role-based authorization behavior.
- Keep migration low-risk and incremental.
- Minimize frontend disruption through API contract compatibility.

---

## 4) Target Architecture (Future State)

### 4.1 High-Level Architecture

**Client Layer**
- Existing React SPA (Vite build artifacts).

**Web Server Layer**
- Apache (from XAMPP) serving:
  - Static frontend assets (production build), and/or
  - API endpoints routed to PHP app.

**Application Layer**
- PHP 8.x REST API (modular controllers/services/repositories).
- Authentication and authorization middleware.
- Input validation and standardized error handling.

**Data Layer**
- MySQL/MariaDB (via XAMPP).
- Relational schema aligned to current Firestore contracts.

### 4.2 Recommended Backend Project Structure

```text
backend/
  public/
    index.php
    .htaccess
  src/
    Controllers/
    Services/
    Repositories/
    Middleware/
    DTO/
    Support/
  config/
    app.php
    database.php
    cors.php
    auth.php
  storage/
    logs/
  database/
    migrations/
    seeds/
  tests/
```

### 4.3 API Style
- RESTful JSON API.
- Versioned base path (recommended): `/api/v1`.
- Uniform envelope for responses and errors.

Example success response:
```json
{
  "success": true,
  "data": { "id": 123 },
  "meta": null
}
```

Example error response:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request payload",
    "details": {
      "amount": ["Amount must be greater than 0"]
    }
  }
}
```

---

## 5) Proposed Relational Data Model

Below is the relational model mapped from current contracts.

### 5.1 `users`
- `id` (BIGINT, PK, AI)
- `uid` (VARCHAR, unique; migration bridge from Firebase uid if needed)
- `email` (VARCHAR, unique, indexed)
- `name` (VARCHAR)
- `role` (ENUM: `admin`, `user`)
- `password_hash` (VARCHAR, nullable if external SSO retained)
- `created_at`, `updated_at`

### 5.2 `farmers`
- `id` (BIGINT, PK, AI)
- `name` (VARCHAR, indexed)
- `phone` (VARCHAR)
- `location` (VARCHAR)
- `joined_at` (DATETIME)
- `created_at`, `updated_at`

### 5.3 `collections`
- `id` (BIGINT, PK, AI)
- `farmer_id` (BIGINT, FK -> farmers.id, indexed)
- `amount` (DECIMAL(10,2))
- `quality` (DECIMAL(5,2))
- `timestamp` (DATETIME, indexed)
- `collected_by_user_id` (BIGINT, FK -> users.id)
- `created_at`, `updated_at`

### 5.4 `payments`
- `id` (BIGINT, PK, AI)
- `farmer_id` (BIGINT, FK -> farmers.id, indexed)
- `amount` (DECIMAL(12,2))
- `period` (VARCHAR, e.g., `March 2026`)
- `status` (ENUM: `pending`, `paid`, indexed)
- `timestamp` (DATETIME, indexed)
- `paid_at` (DATETIME, nullable)
- `created_at`, `updated_at`

### 5.5 Suggested Indexes
- `farmers(name)`
- `collections(farmer_id, timestamp)`
- `payments(farmer_id, period)` unique if business rule is one payment/period/farmer
- `payments(status, timestamp)` for dashboard filters

---

## 6) API Contract Specification (PHP Backend)

> Goal: mirror current frontend needs while enabling clean separation from Firebase.

### 6.1 Authentication

#### POST `/api/v1/auth/login`
- Request: email + password
- Response: session cookie or JWT + user profile

#### POST `/api/v1/auth/logout`
- Invalidates session/token.

#### GET `/api/v1/auth/me`
- Returns authenticated user context and role.

### 6.2 Users

#### GET `/api/v1/users/me`
- Returns currently authenticated profile.

### 6.3 Farmers

#### GET `/api/v1/farmers`
- List farmers.

#### POST `/api/v1/farmers`
- Create farmer.

#### PUT `/api/v1/farmers/{id}`
- Update farmer.

#### DELETE `/api/v1/farmers/{id}`
- Delete farmer.

### 6.4 Collections

#### GET `/api/v1/collections?sort=timestamp&order=desc`
- List collections in reverse chronological order.

#### POST `/api/v1/collections`
- Add milk collection entry.

### 6.5 Payments

#### GET `/api/v1/payments?sort=timestamp&order=desc`
- List payments.

#### POST `/api/v1/payments/generate`
- Generate period payments (monthly batch operation).

#### PATCH `/api/v1/payments/{id}/pay`
- Mark a pending payment as paid.

### 6.6 Authorization Matrix

| Endpoint Group | admin | user |
|---|---:|---:|
| auth/me, users/me | ✅ | ✅ |
| farmers create/update/delete | ✅ | ❌ |
| farmers read | ✅ | ✅ |
| collections create | ✅ | ✅ (if allowed by policy) |
| payments generate/pay | ✅ | ❌ |
| payments read | ✅ | ✅ (or filtered, policy-based) |

---

## 7) Security, Compliance, and Operational Controls

### 7.1 Application Security
- Enforce HTTPS in non-local deployments.
- Input validation at request boundary.
- Prepared statements/ORM to prevent SQL injection.
- Output encoding for XSS mitigation.
- CSRF protection for cookie-based auth.
- Strict CORS allowlist for frontend origins.

### 7.2 Authentication Strategy Options

**Option A: Session Cookies (recommended for same-origin web app)**
- Server-managed sessions in PHP.
- HttpOnly + Secure + SameSite cookies.
- Easier invalidation and reduced token leakage risk.

**Option B: JWT (for multi-client ecosystem)**
- Stateless auth for SPA/mobile API consumers.
- Requires token rotation and secure storage policy.

### 7.3 Audit and Logging
- API request/response metadata logging (excluding secrets).
- Track critical actions: payment generation, payment status changes, record deletions.
- Daily log rotation and retention policy.

### 7.4 Backup and Recovery
- Scheduled MySQL dumps (daily full + optional hourly incremental).
- Tested restoration runbooks.
- Backup encryption at rest.

---

## 8) Migration Strategy (No Frontend Feature Regression)

### Phase 1: Foundation
- Stand up XAMPP environment.
- Initialize PHP project skeleton.
- Implement DB schema and migrations.
- Configure CORS and environment variables.

### Phase 2: Core API Parity
- Build auth + user context endpoint.
- Build farmers/collections/payments endpoints.
- Implement validation + consistent error model.

### Phase 3: Data Migration
- Export Firestore data (users/farmers/collections/payments).
- Transform to relational format.
- Import into MySQL.
- Validate row counts and sampled record fidelity.

### Phase 4: Integration
- Switch frontend data layer from Firebase SDK calls to REST API service module.
- Keep DTOs aligned with existing UI expectations.
- Conduct full regression testing.

### Phase 5: Cutover and Stabilization
- Freeze writes briefly during final sync.
- Point production frontend to PHP API.
- Monitor logs, error rates, and payment workflows.
- Decommission Firebase write paths after acceptance window.

---

## 9) Testing and Quality Assurance Plan

### 9.1 Test Levels
- **Unit tests**: service and validation logic.
- **Integration tests**: endpoints + DB interactions.
- **Contract tests**: request/response compatibility with frontend expectations.
- **UAT**: workflow verification with business stakeholders.

### 9.2 Critical Test Scenarios
- Login/logout/session expiry behavior.
- Farmer CRUD lifecycle with role checks.
- Collection creation and dashboard visibility.
- Payment generation rules and idempotency protections.
- `pending -> paid` transitions and audit traceability.

### 9.3 Non-Functional Testing
- Performance baseline for list and dashboard endpoints.
- Security checks (auth bypass attempts, injection payloads).
- Backup/restore drill validation.

---

## 10) Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Data mismatch during migration | High | Dual validation scripts + sampled reconciliation |
| Auth behavior drift from Firebase model | Medium/High | Explicit auth contract + session policy tests |
| Role-permission misconfiguration | High | Centralized authorization middleware + matrix tests |
| API latency regressions | Medium | Index tuning + query profiling |
| Operational inexperience with XAMPP hardening | Medium | Production hardening checklist + SOPs |

---

## 11) Deployment and Environment Blueprint

### 11.1 Local/Development (XAMPP)
- Apache + PHP + MySQL via XAMPP.
- Backend host: `http://localhost/mpaa-api/public` (example).
- Frontend dev host proxied to API.

### 11.2 Staging/Production Recommendations
- Prefer hardened LAMP/LEMP server over default XAMPP for internet-facing production.
- Apply:
  - TLS certificates
  - firewall rules
  - DB user least privilege
  - secret management (no plaintext in repo)
  - centralized monitoring

---

## 12) Delivery Plan and Effort Estimate

### 12.1 Work Breakdown (indicative)
1. Architecture + schema design (2–3 days)
2. API development (7–12 days)
3. Data migration tooling + dry runs (3–5 days)
4. Frontend integration updates (3–6 days)
5. QA/UAT hardening (4–7 days)

**Estimated total:** ~4–7 weeks depending on team size, test depth, and stakeholder feedback cycles.

### 12.2 Team Roles
- Backend Engineer (PHP/API)
- Frontend Engineer (integration)
- QA Engineer
- DevOps/Infra support
- Product Owner/UAT stakeholders

---

## 13) Acceptance Criteria

The migration is considered successful when:
1. All current workflows (farmers, collections, payments, role-based access) pass regression.
2. API response contracts are stable and documented.
3. Data parity is validated against exported Firestore baseline.
4. Security controls (auth, validation, SQL injection defense, CORS/CSRF policy) are verified.
5. Operational readiness includes backup, restore, logging, and runbook documentation.

---

## 14) Conclusion

Transitioning MPAA from Firebase to a PHP + Apache (XAMPP) backend is technically feasible and strategically viable with a controlled phased approach. The current data contracts are sufficiently clear to support a low-risk migration path. With API parity, robust validation, strong auth controls, and disciplined data migration/testing, the project can preserve existing user value while meeting infrastructure and governance goals.

---

## Appendix A: Current Contract Reference Snapshot

This migration paper is aligned to the currently observed app behavior and contracts:
- Authentication state and profile handling in the frontend app.
- Firestore-backed entities: users, farmers, collections, payments.
- Write operations for farmers, collections, and payment status flows.

(See repository source references listed below for implementation-level details.)

## Appendix B: Source Files Reviewed
- `README.md`
- `src/App.tsx`
- `src/firebase.ts`
- `mobile/docs/data-contracts.md`

