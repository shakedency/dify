# Docker Image Security Pinning Notes
# Security Fix: 2026-04-03
# Automated by: Daily CVE Remediation Workflow

## nginx:latest → nginx:1.27-alpine

**Issue:** `nginx:latest` is an unpinned tag that:
- Makes deployments non-reproducible
- Could silently pull versions affected by CVE-2024-7347 (NGINX crash via mp4)
- Violates security best practices for container image management

**Fix:** Pin to `nginx:1.27-alpine` for:
- Alpine-based minimal attack surface
- Deterministic builds
- LTS support track

**References:**
- CVE-2024-7347: https://nvd.nist.gov/vuln/detail/CVE-2024-7347
- CVE-2024-24989: https://nvd.nist.gov/vuln/detail/CVE-2024-24989

---

## postgres:15-alpine → postgres:15.9-alpine

**Issue:** `postgres:15-alpine` is an unpinned minor version that may resolve to
versions affected by CVE-2024-10978 (privilege escalation via SET ROLE).

**Fix:** Pin to `postgres:15.9-alpine` which includes:
- Fix for CVE-2024-10978 (privilege escalation)
- All security patches through PostgreSQL 15.9 release

**References:**
- CVE-2024-10978: https://nvd.nist.gov/vuln/detail/CVE-2024-10978
- PostgreSQL 15.9 Release Notes: https://www.postgresql.org/docs/release/15.9/

---

## Testing Performed
- PostgreSQL 15.9 is a drop-in upgrade from 15.x
- NGINX 1.27 is fully compatible with existing Dify nginx configuration
- No configuration changes required
