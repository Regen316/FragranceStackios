# Database Schema Reference

This document describes all database tables, their columns, and relationships.

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────┐
│   profiles   │       │ user_fragrances  │       │  fragrances  │
├──────────────┤       ├──────────────────┤       ├──────────────┤
│ id (PK)      │◄──┐   │ id (PK)          │   ┌──►│ id (PK)      │
│ email        │   │   │ user_id (FK)     │───┘   │ name         │
│ tier         │   └───│ fragrance_id(FK) │───────│ brand        │
│ total_cost   │       │ personal_rating  │       │ notes_*      │
└──────────────┘       │ times_worn       │       │ ai_description│
       │               └──────────────────┘       │ created_by(FK)│
       │                       │                  └──────────────┘
       │                       │
       ▼                       ▼
┌──────────────┐       ┌──────────────────┐
│ llm_requests │       │    wear_logs     │
├──────────────┤       ├──────────────────┤
│ id (PK)      │       │ id (PK)          │
│ user_id (FK) │       │ user_id (FK)     │
│ request_type │       │ fragrance_id(FK) │
│ cost_usd     │       │ date_worn        │
│ tokens_*     │       │ satisfaction     │
└──────────────┘       └──────────────────┘
```

## Tables

### profiles
Extends Supabase `auth.users` with app-specific data.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | References `auth.users.id` |
| `email` | TEXT | User's email |
| `display_name` | TEXT | Display name |
| `tier` | TEXT | `free`, `premium`, or `admin` |
| `fragrance_limit` | INT | Max fragrances allowed |
| `daily_ai_limit` | INT | Max AI requests per day |
| `monthly_search_limit` | INT | Max searches per month |
| `total_cost_usd` | DECIMAL | Total LLM cost for this user |
| `created_at` | TIMESTAMPTZ | Account creation |
| `last_active_at` | TIMESTAMPTZ | Last activity |

**RLS Policies:**
- Users can read/update their own profile
- Admins can read/update all profiles

---

### fragrances
Master fragrance database shared across all users.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `name` | TEXT | Fragrance name |
| `brand` | TEXT | Brand name |
| `concentration` | TEXT | EDT, EDP, Parfum, etc. |
| `gender` | TEXT | masculine, feminine, unisex |
| `release_year` | INT | Year released |
| `fragrance_family` | TEXT | Woody, Fresh, Oriental, etc. |
| `notes_top` | TEXT[] | Array of top notes |
| `notes_heart` | TEXT[] | Array of heart notes |
| `notes_base` | TEXT[] | Array of base notes |
| `longevity_hours` | DECIMAL | Expected wear time |
| `projection` | INT (1-10) | How far the scent projects |
| `sillage` | INT (1-10) | Trail left behind |
| `season_spring` | INT (1-10) | Spring suitability |
| `season_summer` | INT (1-10) | Summer suitability |
| `season_fall` | INT (1-10) | Fall suitability |
| `season_winter` | INT (1-10) | Winter suitability |
| `occasion_office` | INT (1-10) | Office suitability |
| `occasion_date` | INT (1-10) | Date suitability |
| `occasion_casual` | INT (1-10) | Casual suitability |
| `occasion_formal` | INT (1-10) | Formal suitability |
| `occasion_club` | INT (1-10) | Night out suitability |
| `ai_description` | TEXT | AI-generated description (cached) |
| `ai_description_generated_at` | TIMESTAMPTZ | When description was generated |
| `ai_description_cost_usd` | DECIMAL | Cost to generate description |
| `image_url` | TEXT | URL to fragrance image |
| `fragrantica_url` | TEXT | Fragrantica page URL |
| `parfumo_url` | TEXT | Parfumo page URL |
| `created_by` | UUID (FK) | User who added this fragrance |
| `is_verified` | BOOLEAN | Admin verified accuracy |
| `created_at` | TIMESTAMPTZ | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | Last update |

**RLS Policies:**
- Anyone can read fragrances
- Authenticated users can create fragrances
- Creators and admins can update fragrances

---

### user_fragrances
Links users to their fragrance collection.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `user_id` | UUID (FK) | References `profiles.id` |
| `fragrance_id` | UUID (FK) | References `fragrances.id` |
| `purchase_date` | DATE | When purchased |
| `purchase_price` | DECIMAL | Price paid |
| `bottle_size_ml` | INT | Bottle size in mL |
| `amount_remaining_percent` | INT (0-100) | How much is left |
| `personal_rating` | INT (1-5) | User's rating |
| `personal_notes` | TEXT | User's notes |
| `is_signature` | BOOLEAN | User's signature scent |
| `is_favorite` | BOOLEAN | Marked as favorite |
| `times_worn` | INT | Wear count |
| `last_worn_at` | TIMESTAMPTZ | Last wear date |
| `created_at` | TIMESTAMPTZ | Added to collection |
| `updated_at` | TIMESTAMPTZ | Last update |

**Constraints:**
- UNIQUE(user_id, fragrance_id) - can't add same fragrance twice

**RLS Policies:**
- Users can only access their own collection

---

### wear_logs
Tracks when users wear fragrances.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `user_id` | UUID (FK) | References `profiles.id` |
| `user_fragrance_id` | UUID (FK) | References `user_fragrances.id` |
| `fragrance_id` | UUID (FK) | References `fragrances.id` |
| `date_worn` | DATE | Date worn |
| `time_of_day` | TEXT | morning, afternoon, evening, night |
| `occasion` | TEXT | Why it was worn |
| `weather_condition` | TEXT | Weather at time |
| `temperature_f` | INT | Temperature |
| `humidity_percent` | INT | Humidity |
| `location_city` | TEXT | City |
| `location_country` | TEXT | Country |
| `satisfaction_rating` | INT (1-5) | How satisfied |
| `compliments_received` | INT | Compliment count |
| `notes` | TEXT | User notes |
| `layered_with` | UUID (FK) | If layered, which fragrance |
| `created_at` | TIMESTAMPTZ | Log creation |

**RLS Policies:**
- Users can only access their own wear logs

---

### llm_requests
Logs all AI API calls for cost tracking.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `user_id` | UUID (FK) | References `profiles.id` |
| `request_type` | TEXT | recommendation, natural_language, fragrance_description, fragrance_search |
| `prompt_summary` | TEXT | First 500 chars of prompt |
| `response_summary` | TEXT | First 500 chars of response |
| `full_prompt` | TEXT | Complete prompt (optional) |
| `full_response` | TEXT | Complete response (optional) |
| `model` | TEXT | Model used (e.g., claude-sonnet-4-20250514) |
| `tokens_input` | INT | Input tokens used |
| `tokens_output` | INT | Output tokens used |
| `cost_usd` | DECIMAL | Calculated cost |
| `latency_ms` | INT | Response time |
| `success` | BOOLEAN | Request succeeded |
| `error_message` | TEXT | Error if failed |
| `weather_used` | BOOLEAN | Weather context included |
| `location_used` | BOOLEAN | Location context included |
| `created_at` | TIMESTAMPTZ | Request timestamp |

**RLS Policies:**
- Users can view their own requests
- Admins can view all requests

---

### model_pricing
Stores current Claude API pricing (admin-editable).

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `model_name` | TEXT (UNIQUE) | Model identifier |
| `display_name` | TEXT | Human-readable name |
| `input_price_per_million` | DECIMAL | $/1M input tokens |
| `output_price_per_million` | DECIMAL | $/1M output tokens |
| `is_active` | BOOLEAN | Currently in use |
| `updated_at` | TIMESTAMPTZ | Last update |
| `updated_by` | UUID (FK) | Admin who updated |

**Default Values:**
- claude-sonnet-4-20250514: $3/$15 per 1M tokens
- claude-haiku-35-20241022: $0.80/$4 per 1M tokens
- claude-opus-4-20250514: $15/$75 per 1M tokens

---

### rate_limits
Tracks rate limit usage per user per endpoint.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID (PK) | Unique identifier |
| `user_id` | UUID (FK) | References `profiles.id` |
| `endpoint` | TEXT | recommendation, natural_language, etc. |
| `period_type` | TEXT | daily or monthly |
| `requests_count` | INT | Requests in current period |
| `period_start` | TIMESTAMPTZ | Period start time |
| `last_request_at` | TIMESTAMPTZ | Last request time |

**Constraints:**
- UNIQUE(user_id, endpoint, period_type)

---

### app_settings
Global application configuration.

| Column | Type | Description |
|--------|------|-------------|
| `key` | TEXT (PK) | Setting name |
| `value` | JSONB | Setting value |
| `description` | TEXT | What this setting does |
| `updated_at` | TIMESTAMPTZ | Last update |
| `updated_by` | UUID (FK) | Admin who updated |

**Default Settings:**
- `free_tier_limits`: `{"fragrances": 5, "daily_ai": 5, "monthly_search": 3}`
- `premium_tier_limits`: `{"fragrances": 999999, "daily_ai": 50, "monthly_search": 30}`
- `daily_spending_cap_free`: `{"usd": 0.50}`
- `daily_spending_cap_premium`: `{"usd": 5.00}`
- `global_daily_alert`: `{"usd": 50.00}`

---

## Views

### user_stats
Aggregated user statistics for admin dashboard.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | User ID |
| `email` | TEXT | Email |
| `tier` | TEXT | Subscription tier |
| `fragrance_count` | BIGINT | Fragrances in collection |
| `wear_log_count` | BIGINT | Total wear logs |
| `llm_request_count` | BIGINT | Total AI requests |
| `calculated_total_cost` | DECIMAL | Sum of all LLM costs |

### daily_cost_summary
Daily cost aggregation for charts.

| Column | Type | Description |
|--------|------|-------------|
| `date` | DATE | Date |
| `request_type` | TEXT | Type of request |
| `request_count` | BIGINT | Number of requests |
| `total_cost` | DECIMAL | Total cost |
| `avg_cost_per_request` | DECIMAL | Average cost |
| `avg_latency_ms` | DECIMAL | Average response time |

---

## Functions

### check_rate_limit(user_id, endpoint, limit, period_type)
Checks and increments rate limit counter. Returns JSON with:
- `allowed`: boolean
- `remaining`: int
- `limit`: int
- `resets_at`: timestamp

### calculate_llm_cost(model, input_tokens, output_tokens)
Calculates USD cost based on `model_pricing` table.

### get_user_collection(user_id)
Returns user's fragrances with all details joined.

### search_fragrances(query)
Full-text search on fragrance name and brand.

### increment_user_cost(user_id, amount)
Adds to user's total_cost_usd.

### admin_get_user_costs(start_date, end_date)
Returns cost breakdown by user for admin dashboard.

### admin_get_daily_costs(days)
Returns daily cost breakdown for charts.
