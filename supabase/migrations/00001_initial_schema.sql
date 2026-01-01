-- FragranceStack Database Schema
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users profile (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT,
    tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'admin')),
    fragrance_limit INTEGER DEFAULT 5,
    daily_ai_limit INTEGER DEFAULT 5,
    monthly_search_limit INTEGER DEFAULT 3,
    ai_queries_today INTEGER DEFAULT 0,
    ai_queries_reset_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '1 day'),
    searches_this_month INTEGER DEFAULT 0,
    searches_reset_at TIMESTAMPTZ DEFAULT (DATE_TRUNC('month', NOW()) + INTERVAL '1 month'),
    total_cost_usd DECIMAL(10,4) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master fragrance database (shared across all users)
CREATE TABLE IF NOT EXISTS public.fragrances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    concentration TEXT CHECK (concentration IN ('EDT', 'EDP', 'Parfum', 'Cologne', 'EDC', 'Other')),
    gender TEXT CHECK (gender IN ('masculine', 'feminine', 'unisex')),
    release_year INTEGER,
    fragrance_family TEXT,

    -- Notes stored as arrays
    notes_top TEXT[] DEFAULT '{}',
    notes_heart TEXT[] DEFAULT '{}',
    notes_base TEXT[] DEFAULT '{}',

    -- Performance metrics (1-10 scale)
    longevity_hours DECIMAL(3,1),
    projection INTEGER CHECK (projection IS NULL OR (projection BETWEEN 1 AND 10)),
    sillage INTEGER CHECK (sillage IS NULL OR (sillage BETWEEN 1 AND 10)),

    -- Seasonal suitability (1-10)
    season_spring INTEGER DEFAULT 5 CHECK (season_spring BETWEEN 1 AND 10),
    season_summer INTEGER DEFAULT 5 CHECK (season_summer BETWEEN 1 AND 10),
    season_fall INTEGER DEFAULT 5 CHECK (season_fall BETWEEN 1 AND 10),
    season_winter INTEGER DEFAULT 5 CHECK (season_winter BETWEEN 1 AND 10),

    -- Occasion suitability (1-10)
    occasion_office INTEGER DEFAULT 5 CHECK (occasion_office BETWEEN 1 AND 10),
    occasion_date INTEGER DEFAULT 5 CHECK (occasion_date BETWEEN 1 AND 10),
    occasion_casual INTEGER DEFAULT 5 CHECK (occasion_casual BETWEEN 1 AND 10),
    occasion_formal INTEGER DEFAULT 5 CHECK (occasion_formal BETWEEN 1 AND 10),
    occasion_club INTEGER DEFAULT 5 CHECK (occasion_club BETWEEN 1 AND 10),

    -- AI-generated content (cached - generated once)
    ai_description TEXT,
    ai_description_generated_at TIMESTAMPTZ,
    ai_description_cost_usd DECIMAL(8,6),

    -- External references
    image_url TEXT,
    fragrantica_url TEXT,
    parfumo_url TEXT,

    -- Metadata
    created_by UUID REFERENCES public.profiles(id),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User's personal fragrance collection
CREATE TABLE IF NOT EXISTS public.user_fragrances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    fragrance_id UUID REFERENCES public.fragrances(id) ON DELETE CASCADE NOT NULL,

    -- Purchase details
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    bottle_size_ml INTEGER,
    amount_remaining_percent INTEGER DEFAULT 100 CHECK (amount_remaining_percent BETWEEN 0 AND 100),

    -- User preferences
    personal_rating INTEGER CHECK (personal_rating IS NULL OR (personal_rating BETWEEN 1 AND 5)),
    personal_notes TEXT,
    is_signature BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,

    -- Usage tracking
    times_worn INTEGER DEFAULT 0,
    last_worn_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, fragrance_id)
);

-- Wear history log
CREATE TABLE IF NOT EXISTS public.wear_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    user_fragrance_id UUID REFERENCES public.user_fragrances(id) ON DELETE CASCADE,
    fragrance_id UUID REFERENCES public.fragrances(id) NOT NULL,

    date_worn DATE NOT NULL DEFAULT CURRENT_DATE,
    time_of_day TEXT CHECK (time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
    occasion TEXT,

    -- Weather context (captured at time of logging)
    weather_condition TEXT,
    temperature_f INTEGER,
    humidity_percent INTEGER,
    location_city TEXT,
    location_country TEXT,

    -- Feedback
    satisfaction_rating INTEGER CHECK (satisfaction_rating IS NULL OR (satisfaction_rating BETWEEN 1 AND 5)),
    compliments_received INTEGER DEFAULT 0,
    notes TEXT,

    -- For fragrance layering
    layered_with UUID REFERENCES public.fragrances(id),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- LLM request logging (for cost tracking and analytics)
CREATE TABLE IF NOT EXISTS public.llm_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

    request_type TEXT NOT NULL CHECK (request_type IN (
        'recommendation',
        'natural_language',
        'fragrance_description',
        'fragrance_search'
    )),

    -- Request/Response (truncated for storage)
    prompt_summary TEXT,
    response_summary TEXT,

    -- Full context for debugging (optional, can be null to save space)
    full_prompt TEXT,
    full_response TEXT,

    -- Cost tracking
    model TEXT DEFAULT 'claude-sonnet-4-20250514',
    tokens_input INTEGER NOT NULL,
    tokens_output INTEGER NOT NULL,
    cost_usd DECIMAL(10,6) NOT NULL,

    -- Performance metrics
    latency_ms INTEGER,
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT,

    -- Context
    weather_used BOOLEAN DEFAULT FALSE,
    location_used BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Model pricing configuration (admin-editable via dashboard)
CREATE TABLE IF NOT EXISTS public.model_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT UNIQUE NOT NULL,
    display_name TEXT,
    input_price_per_million DECIMAL(10,4) NOT NULL,
    output_price_per_million DECIMAL(10,4) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES public.profiles(id)
);

-- Rate limiting tracking
CREATE TABLE IF NOT EXISTS public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    endpoint TEXT NOT NULL,
    requests_count INTEGER DEFAULT 0,
    period_start TIMESTAMPTZ DEFAULT NOW(),
    period_type TEXT DEFAULT 'daily' CHECK (period_type IN ('daily', 'monthly')),
    last_request_at TIMESTAMPTZ,

    UNIQUE(user_id, endpoint, period_type)
);

-- App settings (global configuration)
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES public.profiles(id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_tier ON public.profiles(tier);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active ON public.profiles(last_active_at);

CREATE INDEX IF NOT EXISTS idx_fragrances_brand ON public.fragrances(brand);
CREATE INDEX IF NOT EXISTS idx_fragrances_name ON public.fragrances(name);
CREATE INDEX IF NOT EXISTS idx_fragrances_search ON public.fragrances USING gin(to_tsvector('english', name || ' ' || brand));

CREATE INDEX IF NOT EXISTS idx_user_fragrances_user ON public.user_fragrances(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fragrances_fragrance ON public.user_fragrances(fragrance_id);

CREATE INDEX IF NOT EXISTS idx_wear_logs_user ON public.wear_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_wear_logs_date ON public.wear_logs(date_worn);
CREATE INDEX IF NOT EXISTS idx_wear_logs_fragrance ON public.wear_logs(fragrance_id);

CREATE INDEX IF NOT EXISTS idx_llm_requests_user ON public.llm_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_llm_requests_created ON public.llm_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_llm_requests_type ON public.llm_requests(request_type);

CREATE INDEX IF NOT EXISTS idx_rate_limits_user_endpoint ON public.rate_limits(user_id, endpoint);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fragrances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fragrances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wear_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.llm_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.model_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

CREATE POLICY "Admins can update all profiles" ON public.profiles
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- Fragrances policies (anyone can read, authenticated can create)
CREATE POLICY "Anyone can view fragrances" ON public.fragrances
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create fragrances" ON public.fragrances
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Creators and admins can update fragrances" ON public.fragrances
    FOR UPDATE USING (
        auth.uid() = created_by OR
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- User fragrances policies
CREATE POLICY "Users can view own collection" ON public.user_fragrances
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own collection" ON public.user_fragrances
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all collections" ON public.user_fragrances
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- Wear logs policies
CREATE POLICY "Users can view own wear logs" ON public.wear_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own wear logs" ON public.wear_logs
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all wear logs" ON public.wear_logs
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- LLM requests policies
CREATE POLICY "Users can view own LLM requests" ON public.llm_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all LLM requests" ON public.llm_requests
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- Rate limits policies
CREATE POLICY "Users can view own rate limits" ON public.rate_limits
    FOR SELECT USING (auth.uid() = user_id);

-- Model pricing policies (admins only for write, everyone can read)
CREATE POLICY "Anyone can view pricing" ON public.model_pricing
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage pricing" ON public.model_pricing
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- App settings policies
CREATE POLICY "Anyone can view settings" ON public.app_settings
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage settings" ON public.app_settings
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND tier = 'admin')
    );

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$;

-- Trigger for auto-creating profile
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Calculate LLM cost based on model pricing table
CREATE OR REPLACE FUNCTION public.calculate_llm_cost(
    p_model TEXT,
    p_input_tokens INTEGER,
    p_output_tokens INTEGER
)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
    v_input_price DECIMAL;
    v_output_price DECIMAL;
BEGIN
    SELECT input_price_per_million, output_price_per_million
    INTO v_input_price, v_output_price
    FROM public.model_pricing
    WHERE model_name = p_model AND is_active = TRUE;

    -- Default to Claude Sonnet pricing if model not found
    IF v_input_price IS NULL THEN
        v_input_price := 3.00;
        v_output_price := 15.00;
    END IF;

    RETURN ROUND(
        (p_input_tokens::DECIMAL * v_input_price / 1000000) +
        (p_output_tokens::DECIMAL * v_output_price / 1000000),
        6
    );
END;
$$;

-- Check rate limit and increment counter
CREATE OR REPLACE FUNCTION public.check_rate_limit(
    p_user_id UUID,
    p_endpoint TEXT,
    p_limit INTEGER,
    p_period_type TEXT DEFAULT 'daily'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_record RECORD;
    v_period_start TIMESTAMPTZ;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    -- Calculate period start
    IF p_period_type = 'daily' THEN
        v_period_start := DATE_TRUNC('day', v_now);
    ELSE
        v_period_start := DATE_TRUNC('month', v_now);
    END IF;

    -- Get or create rate limit record
    SELECT * INTO v_record
    FROM public.rate_limits
    WHERE user_id = p_user_id
      AND endpoint = p_endpoint
      AND period_type = p_period_type
    FOR UPDATE;

    IF v_record IS NULL THEN
        -- Create new record
        INSERT INTO public.rate_limits (user_id, endpoint, period_type, requests_count, period_start, last_request_at)
        VALUES (p_user_id, p_endpoint, p_period_type, 1, v_period_start, v_now);

        RETURN jsonb_build_object(
            'allowed', TRUE,
            'remaining', p_limit - 1,
            'limit', p_limit,
            'resets_at', CASE WHEN p_period_type = 'daily'
                THEN v_period_start + INTERVAL '1 day'
                ELSE v_period_start + INTERVAL '1 month'
            END
        );
    END IF;

    -- Check if period has reset
    IF v_record.period_start < v_period_start THEN
        UPDATE public.rate_limits
        SET requests_count = 1, period_start = v_period_start, last_request_at = v_now
        WHERE id = v_record.id;

        RETURN jsonb_build_object(
            'allowed', TRUE,
            'remaining', p_limit - 1,
            'limit', p_limit,
            'resets_at', CASE WHEN p_period_type = 'daily'
                THEN v_period_start + INTERVAL '1 day'
                ELSE v_period_start + INTERVAL '1 month'
            END
        );
    END IF;

    -- Check if limit exceeded
    IF v_record.requests_count >= p_limit THEN
        RETURN jsonb_build_object(
            'allowed', FALSE,
            'remaining', 0,
            'limit', p_limit,
            'resets_at', CASE WHEN p_period_type = 'daily'
                THEN v_record.period_start + INTERVAL '1 day'
                ELSE v_record.period_start + INTERVAL '1 month'
            END,
            'error', 'Rate limit exceeded'
        );
    END IF;

    -- Increment counter
    UPDATE public.rate_limits
    SET requests_count = requests_count + 1, last_request_at = v_now
    WHERE id = v_record.id;

    RETURN jsonb_build_object(
        'allowed', TRUE,
        'remaining', p_limit - v_record.requests_count - 1,
        'limit', p_limit,
        'resets_at', CASE WHEN p_period_type = 'daily'
            THEN v_record.period_start + INTERVAL '1 day'
            ELSE v_record.period_start + INTERVAL '1 month'
        END
    );
END;
$$;

-- Get user's tier limits
CREATE OR REPLACE FUNCTION public.get_user_limits(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile RECORD;
BEGIN
    SELECT * INTO v_profile FROM public.profiles WHERE id = p_user_id;

    IF v_profile IS NULL THEN
        RETURN jsonb_build_object('error', 'User not found');
    END IF;

    RETURN jsonb_build_object(
        'tier', v_profile.tier,
        'fragrance_limit', CASE WHEN v_profile.tier = 'free' THEN 5 ELSE 999999 END,
        'daily_ai_limit', CASE WHEN v_profile.tier = 'free' THEN 5 ELSE 50 END,
        'monthly_search_limit', CASE WHEN v_profile.tier = 'free' THEN 3 ELSE 30 END,
        'nl_queries_allowed', v_profile.tier IN ('premium', 'admin'),
        'weather_allowed', v_profile.tier IN ('premium', 'admin')
    );
END;
$$;

-- Update user's last active timestamp
CREATE OR REPLACE FUNCTION public.update_last_active()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET last_active_at = NOW()
    WHERE id = auth.uid();
    RETURN NEW;
END;
$$;

-- Update timestamps on row update
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Triggers for updated_at
CREATE TRIGGER update_fragrances_updated_at
    BEFORE UPDATE ON public.fragrances
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_user_fragrances_updated_at
    BEFORE UPDATE ON public.user_fragrances
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Increment times_worn when wear log is added
CREATE OR REPLACE FUNCTION public.increment_times_worn()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.user_fragrance_id IS NOT NULL THEN
        UPDATE public.user_fragrances
        SET times_worn = times_worn + 1, last_worn_at = NEW.created_at
        WHERE id = NEW.user_fragrance_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_wear_log_created
    AFTER INSERT ON public.wear_logs
    FOR EACH ROW EXECUTE FUNCTION public.increment_times_worn();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert default model pricing
INSERT INTO public.model_pricing (model_name, display_name, input_price_per_million, output_price_per_million)
VALUES
    ('claude-sonnet-4-20250514', 'Claude Sonnet 4', 3.00, 15.00),
    ('claude-haiku-35-20241022', 'Claude 3.5 Haiku', 0.80, 4.00),
    ('claude-opus-4-20250514', 'Claude Opus 4', 15.00, 75.00)
ON CONFLICT (model_name) DO NOTHING;

-- Insert default app settings
INSERT INTO public.app_settings (key, value, description)
VALUES
    ('free_tier_limits', '{"fragrances": 5, "daily_ai": 5, "monthly_search": 3}', 'Limits for free tier users'),
    ('premium_tier_limits', '{"fragrances": 999999, "daily_ai": 50, "monthly_search": 30}', 'Limits for premium tier users'),
    ('daily_spending_cap_free', '{"usd": 0.50}', 'Max daily LLM spend per free user'),
    ('daily_spending_cap_premium', '{"usd": 5.00}', 'Max daily LLM spend per premium user'),
    ('global_daily_alert', '{"usd": 50.00}', 'Alert threshold for total daily spend')
ON CONFLICT (key) DO NOTHING;

-- ============================================================================
-- VIEWS (for Admin Dashboard)
-- ============================================================================

-- User statistics view
CREATE OR REPLACE VIEW public.user_stats AS
SELECT
    p.id,
    p.email,
    p.display_name,
    p.tier,
    p.created_at,
    p.last_active_at,
    p.total_cost_usd,
    COUNT(DISTINCT uf.id) as fragrance_count,
    COUNT(DISTINCT wl.id) as wear_log_count,
    COUNT(DISTINCT lr.id) as llm_request_count,
    COALESCE(SUM(lr.cost_usd), 0) as calculated_total_cost
FROM public.profiles p
LEFT JOIN public.user_fragrances uf ON p.id = uf.user_id
LEFT JOIN public.wear_logs wl ON p.id = wl.user_id
LEFT JOIN public.llm_requests lr ON p.id = lr.user_id
GROUP BY p.id;

-- Daily cost summary view
CREATE OR REPLACE VIEW public.daily_cost_summary AS
SELECT
    DATE(created_at) as date,
    request_type,
    COUNT(*) as request_count,
    SUM(tokens_input) as total_input_tokens,
    SUM(tokens_output) as total_output_tokens,
    SUM(cost_usd) as total_cost,
    AVG(cost_usd) as avg_cost_per_request,
    AVG(latency_ms) as avg_latency_ms
FROM public.llm_requests
GROUP BY DATE(created_at), request_type
ORDER BY date DESC, request_type;

-- Grant access to views
GRANT SELECT ON public.user_stats TO authenticated;
GRANT SELECT ON public.daily_cost_summary TO authenticated;
