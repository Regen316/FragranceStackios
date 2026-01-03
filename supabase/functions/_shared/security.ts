// Security utilities for Edge Functions
// Implements input validation, rate limiting, and safe error handling

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

// ============================================================================
// SECURITY HEADERS
// ============================================================================

export const securityHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(self), microphone=()',
};

// ============================================================================
// INPUT VALIDATION
// ============================================================================

export interface ValidationResult {
  valid: boolean;
  error?: string;
  sanitized?: unknown;
}

// Validate and sanitize string input
export function validateString(
  value: unknown,
  options: {
    required?: boolean;
    minLength?: number;
    maxLength?: number;
    pattern?: RegExp;
    fieldName?: string;
  } = {}
): ValidationResult {
  const {
    required = true,
    minLength = 1,
    maxLength = 1000,
    pattern,
    fieldName = 'Field',
  } = options;

  // Check if value exists
  if (value === undefined || value === null || value === '') {
    if (required) {
      return { valid: false, error: `${fieldName} is required` };
    }
    return { valid: true, sanitized: null };
  }

  // Must be a string
  if (typeof value !== 'string') {
    return { valid: false, error: `${fieldName} must be a string` };
  }

  const trimmed = value.trim();

  // Length checks
  if (trimmed.length < minLength) {
    return { valid: false, error: `${fieldName} must be at least ${minLength} characters` };
  }
  if (trimmed.length > maxLength) {
    return { valid: false, error: `${fieldName} is too long (max ${maxLength} characters)` };
  }

  // Pattern check
  if (pattern && !pattern.test(trimmed)) {
    return { valid: false, error: `${fieldName} format is invalid` };
  }

  // Injection pattern detection
  const suspiciousPatterns = [
    /<script\b/i,
    /javascript:/i,
    /on\w+\s*=/i,
    /\{\{/,
    /\$\{/,
    /\x00/, // Null byte
    /\\x[0-9a-f]{2}/i, // Hex escape
  ];

  for (const p of suspiciousPatterns) {
    if (p.test(trimmed)) {
      return { valid: false, error: `${fieldName} contains invalid characters` };
    }
  }

  // Sanitize: encode HTML entities for storage safety
  const sanitized = trimmed
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;');

  return { valid: true, sanitized };
}

// Validate numeric input
export function validateNumber(
  value: unknown,
  options: {
    required?: boolean;
    min?: number;
    max?: number;
    integer?: boolean;
    fieldName?: string;
  } = {}
): ValidationResult {
  const {
    required = true,
    min = -Infinity,
    max = Infinity,
    integer = false,
    fieldName = 'Field',
  } = options;

  // Check if value exists
  if (value === undefined || value === null || value === '') {
    if (required) {
      return { valid: false, error: `${fieldName} is required` };
    }
    return { valid: true, sanitized: null };
  }

  // Must be a number
  const num = typeof value === 'string' ? parseFloat(value) : value;
  if (typeof num !== 'number' || isNaN(num)) {
    return { valid: false, error: `${fieldName} must be a number` };
  }

  // Integer check
  if (integer && !Number.isInteger(num)) {
    return { valid: false, error: `${fieldName} must be an integer` };
  }

  // Range checks
  if (num < min) {
    return { valid: false, error: `${fieldName} must be at least ${min}` };
  }
  if (num > max) {
    return { valid: false, error: `${fieldName} must be at most ${max}` };
  }

  // Prevent negative prices, negative quantities, etc.
  if (min >= 0 && num < 0) {
    return { valid: false, error: `${fieldName} cannot be negative` };
  }

  return { valid: true, sanitized: num };
}

// Validate email
export function validateEmail(value: unknown, fieldName = 'Email'): ValidationResult {
  const stringResult = validateString(value, { required: true, maxLength: 254, fieldName });
  if (!stringResult.valid) return stringResult;

  const email = (stringResult.sanitized as string).toLowerCase();

  // Basic email pattern
  const emailPattern = /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/;
  if (!emailPattern.test(email)) {
    return { valid: false, error: 'Invalid email format' };
  }

  return { valid: true, sanitized: email };
}

// Validate enum value
export function validateEnum<T extends string>(
  value: unknown,
  allowedValues: T[],
  options: { required?: boolean; fieldName?: string } = {}
): ValidationResult {
  const { required = true, fieldName = 'Field' } = options;

  if (value === undefined || value === null || value === '') {
    if (required) {
      return { valid: false, error: `${fieldName} is required` };
    }
    return { valid: true, sanitized: null };
  }

  if (typeof value !== 'string') {
    return { valid: false, error: `${fieldName} must be a string` };
  }

  if (!allowedValues.includes(value as T)) {
    return { valid: false, error: `${fieldName} must be one of: ${allowedValues.join(', ')}` };
  }

  return { valid: true, sanitized: value };
}

// ============================================================================
// IP-BASED RATE LIMITING
// ============================================================================

export interface IpRateLimitResult {
  allowed: boolean;
  remaining: number;
  resetsAt: string;
}

// Check IP-based rate limit (uses database function)
export async function checkIpRateLimit(
  supabase: SupabaseClient,
  ipAddress: string,
  endpoint: string,
  limit = 100
): Promise<IpRateLimitResult> {
  try {
    const { data, error } = await supabase.rpc('check_ip_rate_limit', {
      p_ip_address: ipAddress,
      p_endpoint: endpoint,
      p_limit: limit,
    });

    if (error) {
      console.error('IP rate limit check failed:', error);
      // Fail open but log the error
      return { allowed: true, remaining: limit, resetsAt: new Date(Date.now() + 60000).toISOString() };
    }

    return {
      allowed: data.allowed,
      remaining: data.remaining,
      resetsAt: data.resets_at,
    };
  } catch {
    return { allowed: true, remaining: limit, resetsAt: new Date(Date.now() + 60000).toISOString() };
  }
}

// Extract client IP from request
export function getClientIp(req: Request): string {
  // Check common proxy headers
  const forwardedFor = req.headers.get('x-forwarded-for');
  if (forwardedFor) {
    // Take the first IP in the chain
    return forwardedFor.split(',')[0].trim();
  }

  const realIp = req.headers.get('x-real-ip');
  if (realIp) {
    return realIp.trim();
  }

  // Fallback - will be the proxy IP in most cases
  return 'unknown';
}

// ============================================================================
// LOGIN ATTEMPT TRACKING
// ============================================================================

export interface LoginCheckResult {
  allowed: boolean;
  reason?: string;
  lockoutUntil?: string;
  attemptsRemaining: number;
}

// Check if login is allowed (password attempt rate limiting)
export async function checkLoginAllowed(
  supabase: SupabaseClient,
  ipAddress: string,
  email: string
): Promise<LoginCheckResult> {
  try {
    const { data, error } = await supabase.rpc('check_login_allowed', {
      p_ip_address: ipAddress,
      p_email: email,
    });

    if (error) {
      console.error('Login check failed:', error);
      return { allowed: true, attemptsRemaining: 5 };
    }

    return {
      allowed: data.allowed,
      reason: data.reason,
      lockoutUntil: data.lockout_until,
      attemptsRemaining: data.attempts_remaining,
    };
  } catch {
    return { allowed: true, attemptsRemaining: 5 };
  }
}

// Log a login attempt
export async function logLoginAttempt(
  supabase: SupabaseClient,
  ipAddress: string,
  email: string,
  success: boolean
): Promise<void> {
  try {
    await supabase.rpc('log_login_attempt', {
      p_ip_address: ipAddress,
      p_email: email,
      p_success: success,
    });
  } catch (error) {
    console.error('Failed to log login attempt:', error);
  }
}

// ============================================================================
// SAFE ERROR RESPONSES
// ============================================================================

// Error codes for client (don't leak internal details)
export enum ErrorCode {
  BAD_REQUEST = 'BAD_REQUEST',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  NOT_FOUND = 'NOT_FOUND',
  RATE_LIMITED = 'RATE_LIMITED',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  SERVER_ERROR = 'SERVER_ERROR',
}

// Safe error messages by code (never expose internal details)
const ERROR_MESSAGES: Record<ErrorCode, string> = {
  [ErrorCode.BAD_REQUEST]: 'Invalid request',
  [ErrorCode.UNAUTHORIZED]: 'Authentication required',
  [ErrorCode.FORBIDDEN]: 'Access denied',
  [ErrorCode.NOT_FOUND]: 'Resource not found',
  [ErrorCode.RATE_LIMITED]: 'Too many requests. Please try again later.',
  [ErrorCode.VALIDATION_ERROR]: 'Invalid input',
  [ErrorCode.SERVER_ERROR]: 'An unexpected error occurred. Please try again.',
};

// Create a safe error response (logs details server-side, returns generic message)
export function safeErrorResponse(
  code: ErrorCode,
  status: number,
  internalError?: unknown,
  customMessage?: string
): Response {
  // Log detailed error server-side only
  if (internalError) {
    console.error(`[${code}] Internal error:`, internalError);
  }

  const message = customMessage || ERROR_MESSAGES[code];

  return new Response(
    JSON.stringify({
      error: {
        code,
        message,
      },
    }),
    {
      status,
      headers: {
        ...securityHeaders,
        'Content-Type': 'application/json',
      },
    }
  );
}

// ============================================================================
// SECURITY AUDIT LOGGING
// ============================================================================

export type AuditAction =
  | 'login_success'
  | 'login_failed'
  | 'logout'
  | 'password_change'
  | 'profile_update'
  | 'fragrance_added'
  | 'fragrance_deleted'
  | 'api_key_accessed'
  | 'rate_limit_exceeded'
  | 'suspicious_activity';

// Log a security event
export async function logSecurityEvent(
  supabase: SupabaseClient,
  userId: string | null,
  action: AuditAction,
  details: {
    resourceType?: string;
    resourceId?: string;
    ipAddress?: string;
    userAgent?: string;
    metadata?: Record<string, unknown>;
  } = {}
): Promise<void> {
  try {
    await supabase.rpc('log_security_event', {
      p_user_id: userId,
      p_action: action,
      p_resource_type: details.resourceType,
      p_resource_id: details.resourceId,
      p_ip_address: details.ipAddress,
      p_user_agent: details.userAgent,
      p_details: details.metadata,
    });
  } catch (error) {
    console.error('Failed to log security event:', error);
  }
}
