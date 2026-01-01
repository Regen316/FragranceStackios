# FragranceStack Backend Implementation Plan

## Overview

This plan outlines building a backend for the FragranceStack iOS app using:
- **Supabase** (Auth, PostgreSQL Database, Edge Functions)
- **Claude API** (AI recommendations, descriptions, NL queries)
- **Open-Meteo** (Free weather API)
- **Brave Search** (Fragrance web lookup)
- **Next.js + Vercel** (Admin Dashboard)

---

## Phase 1: Supabase Project Setup

### 1.1 Create Supabase Project
- [ ] Create account at supabase.com
- [ ] Create new project "fragrancestack"
- [ ] Note down: Project URL, Anon Key, Service Role Key

### 1.2 Configure Authentication
- [ ] Enable Email/Password auth
- [ ] Enable Apple Sign-In (for iOS)
- [ ] Configure email templates (welcome, password reset)
- [ ] Set up redirect URLs for iOS app

### 1.3 Set Environment Secrets (Edge Functions)
```
ANTHROPIC_API_KEY=sk-ant-...
BRAVE_SEARCH_API_KEY=BSA...
```

**Deliverables:**
- Supabase project live
- Auth configured
- API keys secured

---

## Phase 2: Database Schema

### 2.1 Core Tables

```sql
-- Users (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT NOT NULL,
    display_name TEXT,
    tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'admin')),
    fragrance_limit INTEGER DEFAULT 5,
    ai_queries_today INTEGER DEFAULT 0,
    ai_queries_reset_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

-- Master fragrance database
CREATE TABLE public.fragrances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    concentration TEXT CHECK (concentration IN ('EDT', 'EDP', 'Parfum', 'Cologne', 'EDC')),
    gender TEXT CHECK (gender IN ('masculine', 'feminine', 'unisex')),
    release_year INTEGER,

    -- Notes stored as JSON
    notes_top TEXT[],
    notes_heart TEXT[],
    notes_base TEXT[],

    -- Performance metrics
    longevity_hours DECIMAL(3,1),
    projection INTEGER CHECK (projection BETWEEN 1 AND 10),
    sillage INTEGER CHECK (sillage BETWEEN 1 AND 10),

    -- Seasonal suitability (1-10)
    season_spring INTEGER DEFAULT 5,
    season_summer INTEGER DEFAULT 5,
    season_fall INTEGER DEFAULT 5,
    season_winter INTEGER DEFAULT 5,

    -- Occasion suitability (1-10)
    occasion_office INTEGER DEFAULT 5,
    occasion_date INTEGER DEFAULT 5,
    occasion_casual INTEGER DEFAULT 5,
    occasion_formal INTEGER DEFAULT 5,
    occasion_club INTEGER DEFAULT 5,

    -- AI-generated content (cached)
    ai_description TEXT,
    ai_description_generated_at TIMESTAMPTZ,
    ai_description_cost_usd DECIMAL(6,4),

    -- Metadata
    image_url TEXT,
    fragrantica_url TEXT,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User's personal collection
CREATE TABLE public.user_fragrances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    fragrance_id UUID REFERENCES public.fragrances(id) ON DELETE CASCADE,

    -- Personal details
    purchase_date DATE,
    purchase_price DECIMAL(10,2),
    bottle_size_ml INTEGER,
    amount_remaining_percent INTEGER DEFAULT 100,

    -- User ratings
    personal_rating INTEGER CHECK (personal_rating BETWEEN 1 AND 5),
    is_signature BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,

    -- Usage tracking
    times_worn INTEGER DEFAULT 0,
    last_worn_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, fragrance_id)
);

-- Wear history
CREATE TABLE public.wear_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_fragrance_id UUID REFERENCES public.user_fragrances(id) ON DELETE CASCADE,
    fragrance_id UUID REFERENCES public.fragrances(id),

    date_worn DATE NOT NULL DEFAULT CURRENT_DATE,
    time_of_day TEXT CHECK (time_of_day IN ('morning', 'afternoon', 'evening', 'night')),
    occasion TEXT,

    -- Context
    weather TEXT,
    temperature_f INTEGER,
    location_city TEXT,

    -- Feedback
    satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
    compliments_received INTEGER DEFAULT 0,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- LLM request logging (for cost tracking)
CREATE TABLE public.llm_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

    request_type TEXT NOT NULL CHECK (request_type IN (
        'recommendation',
        'natural_language',
        'fragrance_description',
        'fragrance_search'
    )),

    -- Request details
    prompt TEXT,
    response TEXT,

    -- Cost tracking
    model TEXT DEFAULT 'claude-sonnet-4-20250514',
    tokens_input INTEGER,
    tokens_output INTEGER,
    cost_usd DECIMAL(8,6),

    -- Performance
    latency_ms INTEGER,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Model pricing configuration (admin-editable)
CREATE TABLE public.model_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT UNIQUE NOT NULL,
    input_price_per_million DECIMAL(10,4),
    output_price_per_million DECIMAL(10,4),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES public.profiles(id)
);

-- Insert current Claude pricing
INSERT INTO public.model_pricing (model_name, input_price_per_million, output_price_per_million)
VALUES
    ('claude-sonnet-4-20250514', 3.00, 15.00),
    ('claude-haiku-35-20241022', 0.80, 4.00);

-- Rate limiting tracking
CREATE TABLE public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    endpoint TEXT NOT NULL,
    requests_today INTEGER DEFAULT 0,
    last_request_at TIMESTAMPTZ,
    reset_at TIMESTAMPTZ,

    UNIQUE(user_id, endpoint)
);
```

### 2.2 Row Level Security (RLS)

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fragrances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fragrances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wear_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.llm_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read/update their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Fragrances: Anyone can read, authenticated users can create
CREATE POLICY "Anyone can view fragrances" ON public.fragrances
    FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create fragrances" ON public.fragrances
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- User fragrances: Users can only access their own
CREATE POLICY "Users can manage own collection" ON public.user_fragrances
    FOR ALL USING (auth.uid() = user_id);

-- Wear logs: Users can only access their own
CREATE POLICY "Users can manage own wear logs" ON public.wear_logs
    FOR ALL USING (auth.uid() = user_id);

-- LLM requests: Users can view their own, admins can view all
CREATE POLICY "Users can view own LLM requests" ON public.llm_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Rate limits: Users can view their own
CREATE POLICY "Users can view own rate limits" ON public.rate_limits
    FOR SELECT USING (auth.uid() = user_id);

-- Admin policies (for dashboard)
CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND tier = 'admin'
        )
    );

CREATE POLICY "Admins can view all LLM requests" ON public.llm_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND tier = 'admin'
        )
    );
```

### 2.3 Database Functions

```sql
-- Function to check and enforce rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_endpoint TEXT,
    p_limit INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    v_requests INTEGER;
    v_reset_at TIMESTAMPTZ;
BEGIN
    -- Get or create rate limit record
    INSERT INTO public.rate_limits (user_id, endpoint, requests_today, reset_at)
    VALUES (p_user_id, p_endpoint, 0, NOW() + INTERVAL '1 day')
    ON CONFLICT (user_id, endpoint) DO NOTHING;

    -- Get current count
    SELECT requests_today, reset_at INTO v_requests, v_reset_at
    FROM public.rate_limits
    WHERE user_id = p_user_id AND endpoint = p_endpoint;

    -- Reset if new day
    IF v_reset_at < NOW() THEN
        UPDATE public.rate_limits
        SET requests_today = 0, reset_at = NOW() + INTERVAL '1 day'
        WHERE user_id = p_user_id AND endpoint = p_endpoint;
        v_requests := 0;
    END IF;

    -- Check limit
    IF v_requests >= p_limit THEN
        RETURN FALSE;
    END IF;

    -- Increment counter
    UPDATE public.rate_limits
    SET requests_today = requests_today + 1, last_request_at = NOW()
    WHERE user_id = p_user_id AND endpoint = p_endpoint;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate LLM cost
CREATE OR REPLACE FUNCTION calculate_llm_cost(
    p_model TEXT,
    p_input_tokens INTEGER,
    p_output_tokens INTEGER
) RETURNS DECIMAL AS $$
DECLARE
    v_input_price DECIMAL;
    v_output_price DECIMAL;
BEGIN
    SELECT input_price_per_million, output_price_per_million
    INTO v_input_price, v_output_price
    FROM public.model_pricing
    WHERE model_name = p_model;

    IF v_input_price IS NULL THEN
        -- Default to sonnet pricing if model not found
        v_input_price := 3.00;
        v_output_price := 15.00;
    END IF;

    RETURN (p_input_tokens * v_input_price / 1000000) +
           (p_output_tokens * v_output_price / 1000000);
END;
$$ LANGUAGE plpgsql;

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

**Deliverables:**
- All tables created
- RLS policies active
- Helper functions ready

---

## Phase 3: Edge Functions (Secure API Endpoints)

### 3.1 Recommendation Endpoint

**File:** `supabase/functions/recommend/index.ts`

```typescript
// POST /recommend
// Input: { occasion, time_of_day, latitude?, longitude? }
// Output: { recommendations: [...], weather?: {...} }

// Flow:
// 1. Verify auth (JWT)
// 2. Check rate limit (free: 5/day, premium: 50/day)
// 3. Fetch user's collection from DB
// 4. If location provided, fetch weather from Open-Meteo
// 5. Build prompt with context
// 6. Call Claude API
// 7. Log request + cost to llm_requests
// 8. Return recommendations
```

### 3.2 Natural Language Query Endpoint (Premium)

**File:** `supabase/functions/nl-query/index.ts`

```typescript
// POST /nl-query
// Input: { query: "What should I wear to a summer wedding?", latitude?, longitude? }
// Output: { answer: "...", recommendations: [...] }

// Flow:
// 1. Verify auth + premium tier
// 2. Check rate limit
// 3. Fetch weather if location provided
// 4. Fetch user's collection
// 5. Call Claude with full context
// 6. Log request + cost
// 7. Return response
```

### 3.3 Fragrance Search Endpoint

**File:** `supabase/functions/search-fragrance/index.ts`

```typescript
// POST /search-fragrance
// Input: { query: "Bleu de Chanel" }
// Output: { fragrance: { name, brand, notes, ... } }

// Flow:
// 1. Verify auth
// 2. Check rate limit (free: 3/month, premium: unlimited)
// 3. Check if fragrance already exists in DB
// 4. If not, call Brave Search API
// 5. Pass results to Claude to extract structured data
// 6. Generate AI description
// 7. Log costs
// 8. Return structured fragrance data (user confirms before saving)
```

### 3.4 Generate Description Endpoint

**File:** `supabase/functions/generate-description/index.ts`

```typescript
// POST /generate-description
// Input: { fragrance_id: "..." }
// Output: { description: "..." }

// Flow:
// 1. Verify auth (admin or creator)
// 2. Fetch fragrance details
// 3. Call Claude to generate evocative description
// 4. Save to fragrance record
// 5. Log cost
// 6. Return description
```

### 3.5 Shared Utilities

**File:** `supabase/functions/_shared/`

```
_shared/
├── auth.ts          # JWT verification helpers
├── rate-limit.ts    # Rate limiting logic
├── claude.ts        # Claude API wrapper with cost tracking
├── weather.ts       # Open-Meteo API wrapper
├── search.ts        # Brave Search API wrapper
└── cors.ts          # CORS headers for all endpoints
```

**Deliverables:**
- 4 Edge Functions deployed
- Rate limiting active
- Cost tracking working

---

## Phase 4: iOS App Integration

### 4.1 Add Supabase Swift SDK

```swift
// Package.swift or Xcode SPM
.package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
```

### 4.2 Create API Service Layer

**File:** `Services/SupabaseService.swift`

```swift
// Handles:
// - Authentication (sign up, sign in, sign out)
// - Profile management
// - Fragrance CRUD
// - Collection management
// - Wear log sync
// - AI feature calls
```

### 4.3 Create Auth Manager

**File:** `Services/AuthManager.swift`

```swift
// Handles:
// - Session persistence
// - Token refresh
// - Auth state observation
// - Sign in with Apple integration
```

### 4.4 Update Existing Views

- [ ] Add sign-in/sign-up flow
- [ ] Update AddFragranceView to use search API
- [ ] Update RecommendationEngine to use backend
- [ ] Add sync logic for offline-first experience
- [ ] Add premium feature gates

### 4.5 Environment Configuration

```swift
// Config.swift
enum Config {
    static let supabaseURL = "https://xxx.supabase.co"
    static let supabaseAnonKey = "eyJ..." // Safe to include - RLS protects data
}
```

**Deliverables:**
- Supabase SDK integrated
- Auth flow complete
- Data syncing working

---

## Phase 5: Admin Dashboard

### 5.1 Project Setup

```bash
npx create-next-app@latest fragrancestack-admin --typescript --tailwind --app
cd fragrancestack-admin
npm install @supabase/supabase-js recharts
```

### 5.2 Dashboard Pages

```
app/
├── page.tsx                    # Dashboard overview
├── login/page.tsx              # Admin login
├── users/
│   ├── page.tsx               # User list
│   └── [id]/page.tsx          # User detail
├── costs/
│   ├── page.tsx               # Cost overview
│   └── breakdown/page.tsx     # Detailed breakdown
├── fragrances/
│   ├── page.tsx               # Fragrance database
│   └── [id]/page.tsx          # Edit fragrance
├── settings/
│   ├── page.tsx               # General settings
│   ├── pricing/page.tsx       # Model pricing config
│   └── rate-limits/page.tsx   # Rate limit config
└── health/page.tsx             # System health
```

### 5.3 Key Features

**Dashboard Overview:**
- Active users (daily/weekly/monthly)
- Total LLM spend today/this month
- Average cost per user
- Top users by usage
- Error rate

**User Management:**
- List all users with search
- View user details (collection, usage, costs)
- Upgrade/downgrade tier
- View user's LLM request history

**Cost Tracking:**
- Real-time spend chart
- Cost per feature breakdown
- Cost per user ranking
- Projected monthly spend
- Alerts for unusual spending

**Fragrance Management:**
- View all fragrances
- Edit details
- Regenerate AI descriptions
- View which users have each fragrance

**Settings:**
- Update model pricing
- Configure rate limits per tier
- Manage admin accounts

**Deliverables:**
- Admin dashboard live on Vercel
- All features functional

---

## Phase 6: Security Hardening

### 6.1 Input Validation

```typescript
// All Edge Functions validate input with Zod
import { z } from 'zod';

const RecommendRequestSchema = z.object({
    occasion: z.enum(['office', 'date', 'casual', 'formal', 'club']),
    time_of_day: z.enum(['morning', 'afternoon', 'evening', 'night']),
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
});
```

### 6.2 Rate Limiting Tiers

| Endpoint | Free Tier | Premium |
|----------|-----------|---------|
| /recommend | 5/day | 50/day |
| /nl-query | 0 (blocked) | 20/day |
| /search-fragrance | 3/month | 30/day |
| /generate-description | N/A | N/A |

### 6.3 Cost Protection

- Daily spending cap per user: $0.50 (free), $5.00 (premium)
- Global daily cap alert: $50
- Token limit per request: 4000 input, 1000 output

### 6.4 Audit Logging

All sensitive operations logged:
- Auth events (login, logout, password changes)
- Tier changes
- Admin actions
- Rate limit violations

**Deliverables:**
- All security measures implemented
- Monitoring active

---

## Phase 7: Documentation

### 7.1 Documentation Files

```
docs/
├── 01-architecture-overview.md     # System architecture
├── 02-supabase-setup.md           # Supabase configuration guide
├── 03-database-schema.md          # Complete schema reference
├── 04-edge-functions.md           # API documentation
├── 05-ios-integration.md          # iOS SDK usage
├── 06-admin-dashboard.md          # Dashboard guide
├── 07-security.md                 # Security measures
├── 08-cost-management.md          # Cost monitoring guide
└── 09-deployment.md               # Deployment checklist
```

**Deliverables:**
- All documentation complete

---

## Implementation Order

```
Week 1-2: Foundation
├── Phase 1: Supabase Setup
├── Phase 2: Database Schema
└── Phase 3: Edge Functions (core endpoints)

Week 3: iOS Integration
├── Phase 4: iOS SDK + Auth
└── Test end-to-end flow

Week 4: Admin & Polish
├── Phase 5: Admin Dashboard
├── Phase 6: Security Hardening
└── Phase 7: Documentation
```

---

## Success Criteria

- [ ] User can sign up and log in on iOS
- [ ] User can add fragrances via search
- [ ] User can get AI recommendations
- [ ] Premium users can use natural language queries
- [ ] Admin can view all users and costs
- [ ] Admin can update pricing config
- [ ] Rate limits enforced correctly
- [ ] All API keys secured (never in iOS app)
- [ ] Cost per user tracked accurately
- [ ] Documentation complete

---

## Estimated Costs (5 Test Users)

| Service | Monthly Cost |
|---------|-------------|
| Supabase | $0 (free tier) |
| Vercel | $0 (free tier) |
| Claude API | $2-5 |
| Brave Search | $0 (free tier) |
| **Total** | **~$2-5/month** |
