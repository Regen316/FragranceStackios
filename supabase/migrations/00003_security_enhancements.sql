-- FragranceStack Security Enhancements
-- Based on security principles for mobile app development

-- ============================================================================
-- 1. PASSWORD ATTEMPT RATE LIMITING
-- ============================================================================

-- Track failed login attempts
CREATE TABLE IF NOT EXISTS public.login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address TEXT NOT NULL,
    email TEXT NOT NULL,
    attempt_at TIMESTAMPTZ DEFAULT NOW(),
    success BOOLEAN DEFAULT FALSE
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON public.login_attempts(ip_address, attempt_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON public.login_attempts(email, attempt_at DESC);

-- Auto-delete old records (older than 24 hours)
CREATE OR REPLACE FUNCTION cleanup_old_login_attempts()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM public.login_attempts
    WHERE attempt_at < NOW() - INTERVAL '24 hours';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_cleanup_login_attempts
    AFTER INSERT ON public.login_attempts
    FOR EACH STATEMENT
    EXECUTE FUNCTION cleanup_old_login_attempts();

-- Function to check if login is allowed (max 5 attempts per 15 minutes)
CREATE OR REPLACE FUNCTION check_login_allowed(
    p_ip_address TEXT,
    p_email TEXT
) RETURNS JSON AS $$
DECLARE
    ip_count INTEGER;
    email_count INTEGER;
    lockout_until TIMESTAMPTZ;
    max_attempts INTEGER := 5;
    lockout_minutes INTEGER := 15;
BEGIN
    -- Count recent failed attempts by IP
    SELECT COUNT(*) INTO ip_count
    FROM public.login_attempts
    WHERE ip_address = p_ip_address
      AND success = FALSE
      AND attempt_at > NOW() - (lockout_minutes || ' minutes')::INTERVAL;

    -- Count recent failed attempts by email
    SELECT COUNT(*) INTO email_count
    FROM public.login_attempts
    WHERE email = LOWER(p_email)
      AND success = FALSE
      AND attempt_at > NOW() - (lockout_minutes || ' minutes')::INTERVAL;

    -- Check if locked out
    IF ip_count >= max_attempts OR email_count >= max_attempts THEN
        SELECT MAX(attempt_at) + (lockout_minutes || ' minutes')::INTERVAL INTO lockout_until
        FROM public.login_attempts
        WHERE (ip_address = p_ip_address OR email = LOWER(p_email))
          AND success = FALSE
          AND attempt_at > NOW() - (lockout_minutes || ' minutes')::INTERVAL;

        RETURN json_build_object(
            'allowed', FALSE,
            'reason', 'Too many failed attempts. Please try again later.',
            'lockout_until', lockout_until,
            'attempts_remaining', 0
        );
    END IF;

    RETURN json_build_object(
        'allowed', TRUE,
        'attempts_remaining', max_attempts - GREATEST(ip_count, email_count)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log login attempt
CREATE OR REPLACE FUNCTION log_login_attempt(
    p_ip_address TEXT,
    p_email TEXT,
    p_success BOOLEAN
) RETURNS VOID AS $$
BEGIN
    INSERT INTO public.login_attempts (ip_address, email, success)
    VALUES (p_ip_address, LOWER(p_email), p_success);

    -- If successful, clear previous failed attempts for this email
    IF p_success THEN
        DELETE FROM public.login_attempts
        WHERE email = LOWER(p_email)
          AND success = FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 2. SESSION MANAGEMENT ENHANCEMENTS
-- ============================================================================

-- Track active sessions for concurrent session limits
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    session_token_hash TEXT NOT NULL,  -- Store hash, not actual token
    device_info TEXT,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
    is_revoked BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON public.user_sessions(user_id, is_revoked);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON public.user_sessions(expires_at) WHERE is_revoked = FALSE;

-- Function to limit concurrent sessions (max 5 per user)
CREATE OR REPLACE FUNCTION enforce_session_limit()
RETURNS TRIGGER AS $$
DECLARE
    session_count INTEGER;
    max_sessions INTEGER := 5;
BEGIN
    -- Count active sessions for this user
    SELECT COUNT(*) INTO session_count
    FROM public.user_sessions
    WHERE user_id = NEW.user_id
      AND is_revoked = FALSE
      AND expires_at > NOW();

    -- If at limit, revoke the oldest session
    IF session_count >= max_sessions THEN
        UPDATE public.user_sessions
        SET is_revoked = TRUE
        WHERE id = (
            SELECT id FROM public.user_sessions
            WHERE user_id = NEW.user_id
              AND is_revoked = FALSE
            ORDER BY last_active_at ASC
            LIMIT 1
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_enforce_session_limit
    BEFORE INSERT ON public.user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION enforce_session_limit();

-- Function to revoke all sessions on password change
CREATE OR REPLACE FUNCTION revoke_sessions_on_password_change()
RETURNS TRIGGER AS $$
BEGIN
    -- When password changes in auth.users, revoke all sessions
    UPDATE public.user_sessions
    SET is_revoked = TRUE
    WHERE user_id = NEW.id
      AND is_revoked = FALSE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: This trigger would need to be on auth.users which requires superuser
-- For now, we'll handle this in the application layer


-- ============================================================================
-- 3. AUDIT LOG FOR SENSITIVE ACTIONS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.security_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_user ON public.security_audit_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON public.security_audit_log(action, created_at DESC);

-- Function to log security events
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_action TEXT,
    p_resource_type TEXT DEFAULT NULL,
    p_resource_id TEXT DEFAULT NULL,
    p_ip_address TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_details JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO public.security_audit_log (
        user_id, action, resource_type, resource_id,
        ip_address, user_agent, details
    ) VALUES (
        p_user_id, p_action, p_resource_type, p_resource_id,
        p_ip_address, p_user_agent, p_details
    ) RETURNING id INTO log_id;

    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 4. RATE LIMIT ENHANCEMENTS
-- ============================================================================

-- Add IP-based rate limiting table
CREATE TABLE IF NOT EXISTS public.ip_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address TEXT NOT NULL,
    endpoint TEXT NOT NULL,
    requests_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ip_address, endpoint)
);

CREATE INDEX IF NOT EXISTS idx_ip_rate_limits ON public.ip_rate_limits(ip_address, endpoint);

-- Function to check IP rate limit (100 requests per minute per endpoint)
CREATE OR REPLACE FUNCTION check_ip_rate_limit(
    p_ip_address TEXT,
    p_endpoint TEXT,
    p_limit INTEGER DEFAULT 100
) RETURNS JSON AS $$
DECLARE
    current_count INTEGER;
    window_start_time TIMESTAMPTZ;
BEGIN
    -- Get or create rate limit record
    INSERT INTO public.ip_rate_limits (ip_address, endpoint, requests_count, window_start)
    VALUES (p_ip_address, p_endpoint, 1, NOW())
    ON CONFLICT (ip_address, endpoint) DO UPDATE
    SET requests_count = CASE
        WHEN ip_rate_limits.window_start < NOW() - INTERVAL '1 minute'
        THEN 1
        ELSE ip_rate_limits.requests_count + 1
    END,
    window_start = CASE
        WHEN ip_rate_limits.window_start < NOW() - INTERVAL '1 minute'
        THEN NOW()
        ELSE ip_rate_limits.window_start
    END
    RETURNING requests_count, window_start INTO current_count, window_start_time;

    IF current_count > p_limit THEN
        RETURN json_build_object(
            'allowed', FALSE,
            'remaining', 0,
            'resets_at', window_start_time + INTERVAL '1 minute'
        );
    END IF;

    RETURN json_build_object(
        'allowed', TRUE,
        'remaining', p_limit - current_count,
        'resets_at', window_start_time + INTERVAL '1 minute'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 5. INPUT VALIDATION HELPERS
-- ============================================================================

-- Function to sanitize text input
CREATE OR REPLACE FUNCTION sanitize_text_input(
    p_input TEXT
) RETURNS TEXT AS $$
BEGIN
    IF p_input IS NULL THEN
        RETURN NULL;
    END IF;

    -- Remove null bytes
    p_input := REPLACE(p_input, E'\x00', '');

    -- Basic HTML entity encoding for storage
    p_input := REPLACE(p_input, '<', '&lt;');
    p_input := REPLACE(p_input, '>', '&gt;');

    RETURN TRIM(p_input);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to validate numeric range
CREATE OR REPLACE FUNCTION validate_numeric_range(
    p_value NUMERIC,
    p_min NUMERIC,
    p_max NUMERIC
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_value IS NOT NULL
       AND p_value >= p_min
       AND p_value <= p_max;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- ============================================================================
-- 6. RLS POLICIES FOR NEW TABLES
-- ============================================================================

ALTER TABLE public.login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ip_rate_limits ENABLE ROW LEVEL SECURITY;

-- Login attempts: Only functions can access (SECURITY DEFINER)
CREATE POLICY "No direct access to login_attempts"
    ON public.login_attempts FOR ALL
    USING (FALSE);

-- User sessions: Users can only see their own sessions
CREATE POLICY "Users can view own sessions"
    ON public.user_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can revoke own sessions"
    ON public.user_sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- Audit log: Only admins can view
CREATE POLICY "Admins can view audit log"
    ON public.security_audit_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND tier = 'admin'
        )
    );

-- IP rate limits: Only functions can access
CREATE POLICY "No direct access to ip_rate_limits"
    ON public.ip_rate_limits FOR ALL
    USING (FALSE);


-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION check_login_allowed TO authenticated, anon;
GRANT EXECUTE ON FUNCTION log_login_attempt TO authenticated, anon;
GRANT EXECUTE ON FUNCTION log_security_event TO authenticated;
GRANT EXECUTE ON FUNCTION check_ip_rate_limit TO authenticated, anon;
GRANT EXECUTE ON FUNCTION sanitize_text_input TO authenticated;
GRANT EXECUTE ON FUNCTION validate_numeric_range TO authenticated;

GRANT SELECT, UPDATE ON public.user_sessions TO authenticated;
GRANT SELECT ON public.security_audit_log TO authenticated;
