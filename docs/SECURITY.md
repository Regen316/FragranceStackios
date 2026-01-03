# FragranceStack Security Documentation

This document outlines the security measures implemented in FragranceStack based on mobile app security best practices.

## Security Principles Implemented

### 1. Rate Limiting

**Purpose:** Prevent abuse, protect against brute force attacks, and control API costs.

| Limit Type | Free Tier | Premium Tier | Implementation |
|------------|-----------|--------------|----------------|
| AI Recommendations | 5/day | 50/day | `rate_limits` table |
| Natural Language Queries | Not allowed | 20/day | `rate_limits` table |
| Fragrance Searches | 3/month | 30/month | `rate_limits` table |
| Daily Spending Cap | $0.50 | $5.00 | `llm_requests` tracking |
| Collection Size | 5 fragrances | Unlimited | `user_fragrances` count |
| Password Attempts | 5 per 15 min | 5 per 15 min | `login_attempts` table |
| IP Rate Limit | 100/min | 100/min | `ip_rate_limits` table |

**How to adjust limits:**
```sql
-- Update tier limits in the check functions
-- See supabase/migrations/00003_security_enhancements.sql
```

### 2. Input Validation

All user inputs are validated before processing:

- **String validation:** Length limits, pattern matching, injection prevention
- **Numeric validation:** Range checks, integer validation, non-negative enforcement
- **Email validation:** Format verification, lowercase normalization
- **Enum validation:** Whitelist-only values for fields like occasion, time_of_day

**Blocked patterns:**
- `<script` tags (XSS)
- `javascript:` URIs
- `on*=` event handlers
- `{{` and `${` template injection
- Null bytes and hex escapes

**Usage in Edge Functions:**
```typescript
import { validateString, validateNumber, validateEmail } from '../_shared/security.ts';

const nameResult = validateString(body.name, {
  required: true,
  minLength: 2,
  maxLength: 200,
  fieldName: 'Fragrance name'
});

if (!nameResult.valid) {
  return errorResponse(nameResult.error!, 400);
}
```

### 3. API Key Storage

**Secure storage:**
- All sensitive API keys stored in Supabase Edge Function secrets
- Never exposed in frontend code
- Never logged or included in error messages

| Key | Location | Notes |
|-----|----------|-------|
| `CLAUDE_API_KEY` | Edge Function secrets | AI features |
| `BRAVE_SEARCH_API_KEY` | Edge Function secrets | Web search |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function secrets | Admin operations |
| `SUPABASE_ANON_KEY` | iOS app (safe) | Public by design, RLS protects data |

**Setting secrets:**
```bash
supabase secrets set CLAUDE_API_KEY=sk-ant-...
supabase secrets set BRAVE_SEARCH_API_KEY=BSA...
```

### 4. Encryption

**Password handling:**
- Passwords hashed using bcrypt (via Supabase Auth)
- Never stored in plain text
- Salt automatically generated per password

**Data protection:**
- All data at rest encrypted by Supabase
- All API calls use HTTPS (TLS 1.3)
- JWT tokens signed with HS256

### 5. Session Management

**JWT-based authentication:**
- Tokens expire after 1 hour
- Automatic refresh mechanism
- Secure token storage on iOS (Keychain)

**Session security features:**
- Maximum 5 concurrent sessions per user
- Old sessions automatically revoked when limit reached
- All sessions revoked on password change (when implemented via trigger)
- Session tracking in `user_sessions` table

**Usage:**
```typescript
// Check current sessions
const { data: sessions } = await supabase
  .from('user_sessions')
  .select('*')
  .eq('user_id', userId)
  .eq('is_revoked', false);

// Revoke a specific session
await supabase
  .from('user_sessions')
  .update({ is_revoked: true })
  .eq('id', sessionId);
```

### 6. Safe Error Messages

**Principles:**
- Never expose internal error details to clients
- Never include file paths, stack traces, or database structure
- Log detailed errors server-side only
- Use generic error codes for client responses

**Error codes:**
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `BAD_REQUEST` | 400 | Invalid request format |
| `UNAUTHORIZED` | 401 | Missing or invalid auth |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `RATE_LIMITED` | 429 | Too many requests |
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `SERVER_ERROR` | 500 | Internal error (details logged) |

**Usage:**
```typescript
import { safeErrorResponse, ErrorCode } from '../_shared/security.ts';

try {
  // ... operation
} catch (error) {
  // Log detailed error server-side
  console.error('Operation failed:', error);

  // Return safe error to client
  return safeErrorResponse(ErrorCode.SERVER_ERROR, 500, error);
}
```

## Security Headers

All API responses include these headers:

```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(self), microphone=()
Cache-Control: no-store, no-cache, must-revalidate
```

## Audit Logging

Security events are logged in the `security_audit_log` table:

| Action | When Logged |
|--------|-------------|
| `login_success` | Successful authentication |
| `login_failed` | Failed authentication attempt |
| `logout` | User sign out |
| `password_change` | Password updated |
| `profile_update` | Profile modified |
| `fragrance_added` | New fragrance added |
| `fragrance_deleted` | Fragrance removed |
| `rate_limit_exceeded` | User hit rate limit |
| `suspicious_activity` | Potential attack detected |

**Viewing audit logs (admin only):**
```sql
SELECT * FROM security_audit_log
WHERE user_id = 'uuid-here'
ORDER BY created_at DESC
LIMIT 100;
```

## Row Level Security (RLS)

All tables have RLS enabled with policies:

| Table | Policy |
|-------|--------|
| `profiles` | Users can only read/update their own profile |
| `user_fragrances` | Users can only access their own collection |
| `wear_logs` | Users can only access their own logs |
| `fragrances` | Readable by all authenticated users |
| `login_attempts` | No direct access (function only) |
| `security_audit_log` | Admins only |

## Deployment Checklist

Before deploying to production:

- [ ] All API keys stored as Edge Function secrets
- [ ] RLS enabled on all tables
- [ ] Rate limiting configured appropriately
- [ ] Error messages don't expose internal details
- [ ] Security headers present on all responses
- [ ] Audit logging enabled
- [ ] Session management configured
- [ ] Input validation on all endpoints
- [ ] HTTPS enforced (automatic with Supabase)

## Reporting Security Issues

If you discover a security vulnerability, please report it responsibly by contacting the development team directly rather than creating a public issue.
