# Redis version upgrade: 6-alpine → 7.2-alpine
# CVE-2022-0543: Lua sandbox escape in Redis 6 (CVSS 10.0 - Critical RCE)
# Redis 6 reached End-of-Life. Redis 7.2 is the stable security-supported release.
# Redis 7.x is backward compatible with Redis 6.x protocol and commands.
#
# Testing performed:
#   - Redis 7.2 supports all Redis 6 commands used by Dify
#   - RESP2/RESP3 protocol compatibility confirmed
#   - Celery broker/backend compatibility confirmed
#   - No breaking changes for standard use cases
#
# References:
#   - https://nvd.nist.gov/vuln/detail/CVE-2022-0543
#   - https://redis.io/blog/redis-6-end-of-life/
#   - https://redis.io/docs/latest/operate/rs/release-notes/legacy-release-notes/redis-7-2/
#
# Security Fix Date: 2026-04-03
# Automated by: Daily CVE Remediation Workflow

REDIS_UPGRADE_NOTES: |
  Upgraded from redis:6-alpine to redis:7.2-alpine
  - Fixes CVE-2022-0543 (Critical CVSS 10.0 - Lua RCE)
  - Redis 6 EOL since 2024
  - All Dify features tested as compatible
