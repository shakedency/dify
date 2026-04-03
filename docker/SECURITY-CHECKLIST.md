# 🔒 Dify Deployment Security Checklist

This checklist must be completed **before deploying Dify to production**.

## ⚠️ Critical Security Items

### 1. SECRET_KEY (REQUIRED)

The `docker-compose.yaml` contains a **default** `SECRET_KEY` for convenience during development.
**You MUST change this before production deployment.**

The default key (`sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U`) is:
- Publicly visible in this repository
- Used by anyone who has not set a custom value
- Can be exploited to forge JWT tokens and impersonate users

**Generate a secure key:**
```bash
openssl rand -base64 42
```

**Set it in your `.env` file:**
```env
SECRET_KEY=<your-generated-key-here>
```

### 2. Database Passwords (REQUIRED)

Change all default database passwords in your `.env` file:

```env
# PostgreSQL
DB_PASSWORD=<strong-random-password>

# Redis
REDIS_PASSWORD=<strong-random-password>

# Weaviate (if used)
WEAVIATE_API_KEY=<strong-random-key>
```

### 3. CORS Origins (REQUIRED for production)

The default CORS configuration allows all origins (`*`). Restrict this:

```env
WEB_API_CORS_ALLOW_ORIGINS=https://yourdomain.com
CONSOLE_CORS_ALLOW_ORIGINS=https://yourdomain.com
```

### 4. Sandbox API Key (REQUIRED)

```env
SANDBOX_API_KEY=<strong-random-key>
```

### 5. Plugin Daemon Key (REQUIRED)

```env
PLUGIN_DAEMON_KEY=<strong-random-key>
PLUGIN_DIFY_INNER_API_KEY=<strong-random-key>
```

## 🔐 Security Validation Script

Run this script to validate your configuration before deployment:

```bash
#!/bin/bash
# save as: docker/check-security.sh

DEFAULT_SECRET="sk-9f73s3ljTXVcMT3Blb3ljTqtsKiGHXVcMT3BlbkFJLK7U"
DEFAULT_DB_PASS="difyai123456"
DEFAULT_REDIS_PASS="difyai123456"

ERRORS=0

if [ "${SECRET_KEY}" = "${DEFAULT_SECRET}" ] || [ -z "${SECRET_KEY}" ]; then
  echo "❌ ERROR: SECRET_KEY is not set or uses default value!"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ SECRET_KEY is customized"
fi

if [ "${DB_PASSWORD}" = "${DEFAULT_DB_PASS}" ] || [ -z "${DB_PASSWORD}" ]; then
  echo "⚠️  WARNING: DB_PASSWORD uses default value"
else
  echo "✅ DB_PASSWORD is customized"
fi

if [ "${REDIS_PASSWORD}" = "${DEFAULT_REDIS_PASS}" ] || [ -z "${REDIS_PASSWORD}" ]; then
  echo "⚠️  WARNING: REDIS_PASSWORD uses default value"
else  
  echo "✅ REDIS_PASSWORD is customized"
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Security validation FAILED. Please fix the errors above before deploying."
  exit 1
else
  echo ""
  echo "✅ Security validation PASSED"
fi
```

## 📋 Complete Security Checklist

- [ ] `SECRET_KEY` changed from default
- [ ] `DB_PASSWORD` changed from default  
- [ ] `REDIS_PASSWORD` changed from default
- [ ] `SANDBOX_API_KEY` changed from default
- [ ] `PLUGIN_DAEMON_KEY` changed from default
- [ ] `PLUGIN_DIFY_INNER_API_KEY` changed from default
- [ ] CORS origins restricted (not `*`)
- [ ] HTTPS enabled (`NGINX_HTTPS_ENABLED=true`)
- [ ] SSL certificates configured
- [ ] Firewall rules configured (only expose ports 80/443)
- [ ] Log monitoring configured
- [ ] Backup strategy in place

## 🔗 References

- [Dify Self-Hosting Security Guide](https://docs.dify.ai)
- [OWASP Deployment Security Checklist](https://owasp.org/)
- CVE Remediation Date: 2026-04-03 (automated security scan)
