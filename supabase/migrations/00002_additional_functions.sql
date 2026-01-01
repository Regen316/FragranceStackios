-- Additional database functions
-- Run after 00001_initial_schema.sql

-- Increment user's total cost (called from Edge Functions)
CREATE OR REPLACE FUNCTION public.increment_user_cost(
    p_user_id UUID,
    p_amount DECIMAL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.profiles
    SET total_cost_usd = total_cost_usd + p_amount
    WHERE id = p_user_id;
END;
$$;

-- Get user's daily spending
CREATE OR REPLACE FUNCTION public.get_daily_spending(p_user_id UUID)
RETURNS DECIMAL
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total DECIMAL;
BEGIN
    SELECT COALESCE(SUM(cost_usd), 0)
    INTO v_total
    FROM public.llm_requests
    WHERE user_id = p_user_id
      AND created_at >= DATE_TRUNC('day', NOW())
      AND created_at < DATE_TRUNC('day', NOW()) + INTERVAL '1 day';

    RETURN v_total;
END;
$$;

-- Check if fragrance exists by name and brand
CREATE OR REPLACE FUNCTION public.find_fragrance(
    p_name TEXT,
    p_brand TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id UUID;
BEGIN
    SELECT id INTO v_id
    FROM public.fragrances
    WHERE LOWER(name) = LOWER(p_name)
      AND LOWER(brand) = LOWER(p_brand)
    LIMIT 1;

    RETURN v_id;
END;
$$;

-- Search fragrances by text
CREATE OR REPLACE FUNCTION public.search_fragrances(p_query TEXT)
RETURNS SETOF public.fragrances
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.fragrances
    WHERE
        to_tsvector('english', name || ' ' || brand) @@ plainto_tsquery('english', p_query)
        OR name ILIKE '%' || p_query || '%'
        OR brand ILIKE '%' || p_query || '%'
    ORDER BY
        CASE WHEN LOWER(name) = LOWER(p_query) THEN 0
             WHEN LOWER(name) LIKE LOWER(p_query) || '%' THEN 1
             ELSE 2
        END,
        name
    LIMIT 20;
END;
$$;

-- Get user's collection with fragrance details
CREATE OR REPLACE FUNCTION public.get_user_collection(p_user_id UUID)
RETURNS TABLE (
    user_fragrance_id UUID,
    fragrance_id UUID,
    name TEXT,
    brand TEXT,
    concentration TEXT,
    personal_rating INTEGER,
    times_worn INTEGER,
    is_signature BOOLEAN,
    is_favorite BOOLEAN,
    ai_description TEXT,
    notes_top TEXT[],
    notes_heart TEXT[],
    notes_base TEXT[],
    longevity_hours DECIMAL,
    projection INTEGER,
    sillage INTEGER,
    season_spring INTEGER,
    season_summer INTEGER,
    season_fall INTEGER,
    season_winter INTEGER,
    occasion_office INTEGER,
    occasion_date INTEGER,
    occasion_casual INTEGER,
    occasion_formal INTEGER,
    occasion_club INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        uf.id as user_fragrance_id,
        f.id as fragrance_id,
        f.name,
        f.brand,
        f.concentration,
        uf.personal_rating,
        uf.times_worn,
        uf.is_signature,
        uf.is_favorite,
        f.ai_description,
        f.notes_top,
        f.notes_heart,
        f.notes_base,
        f.longevity_hours,
        f.projection,
        f.sillage,
        f.season_spring,
        f.season_summer,
        f.season_fall,
        f.season_winter,
        f.occasion_office,
        f.occasion_date,
        f.occasion_casual,
        f.occasion_formal,
        f.occasion_club
    FROM public.user_fragrances uf
    JOIN public.fragrances f ON uf.fragrance_id = f.id
    WHERE uf.user_id = p_user_id
    ORDER BY uf.is_signature DESC, uf.is_favorite DESC, uf.times_worn DESC;
END;
$$;

-- Admin: Get cost summary by user
CREATE OR REPLACE FUNCTION public.admin_get_user_costs(
    p_start_date TIMESTAMPTZ DEFAULT (NOW() - INTERVAL '30 days'),
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    tier TEXT,
    request_count BIGINT,
    total_input_tokens BIGINT,
    total_output_tokens BIGINT,
    total_cost_usd DECIMAL,
    avg_cost_per_request DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id as user_id,
        p.email,
        p.tier,
        COUNT(lr.id) as request_count,
        COALESCE(SUM(lr.tokens_input), 0) as total_input_tokens,
        COALESCE(SUM(lr.tokens_output), 0) as total_output_tokens,
        COALESCE(SUM(lr.cost_usd), 0) as total_cost_usd,
        CASE WHEN COUNT(lr.id) > 0
            THEN ROUND(SUM(lr.cost_usd) / COUNT(lr.id), 6)
            ELSE 0
        END as avg_cost_per_request
    FROM public.profiles p
    LEFT JOIN public.llm_requests lr ON p.id = lr.user_id
        AND lr.created_at BETWEEN p_start_date AND p_end_date
    GROUP BY p.id, p.email, p.tier
    ORDER BY total_cost_usd DESC;
END;
$$;

-- Admin: Get daily cost breakdown
CREATE OR REPLACE FUNCTION public.admin_get_daily_costs(
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    date DATE,
    request_count BIGINT,
    unique_users BIGINT,
    total_cost_usd DECIMAL,
    recommendation_cost DECIMAL,
    nl_query_cost DECIMAL,
    search_cost DECIMAL,
    description_cost DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE(lr.created_at) as date,
        COUNT(*) as request_count,
        COUNT(DISTINCT lr.user_id) as unique_users,
        SUM(lr.cost_usd) as total_cost_usd,
        SUM(CASE WHEN lr.request_type = 'recommendation' THEN lr.cost_usd ELSE 0 END) as recommendation_cost,
        SUM(CASE WHEN lr.request_type = 'natural_language' THEN lr.cost_usd ELSE 0 END) as nl_query_cost,
        SUM(CASE WHEN lr.request_type = 'fragrance_search' THEN lr.cost_usd ELSE 0 END) as search_cost,
        SUM(CASE WHEN lr.request_type = 'fragrance_description' THEN lr.cost_usd ELSE 0 END) as description_cost
    FROM public.llm_requests lr
    WHERE lr.created_at >= NOW() - (p_days || ' days')::INTERVAL
    GROUP BY DATE(lr.created_at)
    ORDER BY date DESC;
END;
$$;
