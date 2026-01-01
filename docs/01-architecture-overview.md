# FragranceStack Backend Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRAGRANCESTACK SYSTEM                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────┐         ┌─────────────────────────────────────┐  │
│   │   iOS App    │         │           SUPABASE                  │  │
│   │              │◄───────►│                                     │  │
│   │ - Auth       │  HTTPS  │  ┌─────────────┐  ┌──────────────┐ │  │
│   │ - Collection │         │  │   Auth      │  │  PostgreSQL  │ │  │
│   │ - Recommender│         │  │  (Users)    │  │  (Database)  │ │  │
│   │ - Wear Logs  │         │  └─────────────┘  └──────────────┘ │  │
│   └──────────────┘         │                                     │  │
│                            │  ┌─────────────────────────────────┐│  │
│                            │  │      Edge Functions             ││  │
│                            │  │  (Secure server-side code)      ││  │
│                            │  │  - /recommend                   ││  │
│                            │  │  - /nl-query                    ││  │
│                            │  │  - /search-fragrance            ││  │
│                            │  │  - /generate-description        ││  │
│                            │  └───────────────┬─────────────────┘│  │
│                            └──────────────────┼──────────────────┘  │
│                                               │                      │
│               ┌───────────────────────────────┼───────────────────┐ │
│               │                               │                   │ │
│               ▼                               ▼                   ▼ │
│   ┌─────────────────┐             ┌─────────────────┐  ┌─────────┐ │
│   │  Claude API     │             │  Open-Meteo     │  │  Brave  │ │
│   │  (Anthropic)    │             │  (Weather)      │  │ Search  │ │
│   └─────────────────┘             └─────────────────┘  └─────────┘ │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │              ADMIN DASHBOARD (Next.js on Vercel)             │  │
│   │  • User management    • Cost tracking    • Settings          │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. iOS App (Client)
- **Location**: `/FragranceStackios/`
- **Technology**: SwiftUI + SwiftData
- **Purpose**: User-facing mobile application
- **Key Files**:
  - `Services/AuthManager.swift` - Authentication handling
  - `Services/FragranceAPIService.swift` - API calls to Edge Functions
  - `Services/SupabaseDataService.swift` - Database operations
  - `Services/SupabaseConfig.swift` - Configuration

### 2. Supabase Backend
- **Location**: `/supabase/`
- **Components**:
  - **Auth**: User authentication (email, Apple Sign-In)
  - **Database**: PostgreSQL with Row Level Security
  - **Edge Functions**: Serverless API endpoints

### 3. Admin Dashboard
- **Location**: `/admin-dashboard/`
- **Technology**: Next.js 14 + Tailwind CSS
- **Purpose**: Admin monitoring and configuration
- **Hosted on**: Vercel (recommended)

### 4. External APIs
- **Claude API** (Anthropic): AI recommendations and descriptions
- **Open-Meteo**: Free weather data
- **Brave Search**: Fragrance information lookup

## Data Flow

### User Authentication
```
iOS App → Supabase Auth → JWT Token → iOS App stores token
                ↓
        Creates profile in database
```

### Getting Recommendations
```
iOS App (with JWT) → Edge Function /recommend
                            ↓
                    1. Verify JWT
                    2. Check rate limit
                    3. Fetch user's collection
                    4. Get weather (if location provided)
                    5. Call Claude API
                    6. Log request + cost
                    7. Return recommendations
```

### Adding a Fragrance
```
User enters name → Edge Function /search-fragrance
                            ↓
                    1. Check if exists in DB
                    2. If not, search Brave
                    3. Claude extracts data
                    4. Generate AI description
                    5. Return to user for review
                            ↓
User confirms → Save to fragrances table
             → Add to user_fragrances table
```

## Security Model

### Row Level Security (RLS)
Every table has RLS policies that:
- Users can only see their own data
- Admins can see all data
- Fragrances are publicly readable

### API Key Protection
- Claude API key: Stored in Supabase Edge Function secrets
- Brave Search API key: Stored in Supabase Edge Function secrets
- **Never exposed to iOS app**

### Rate Limiting
Enforced server-side in Edge Functions:
- Free: 5 AI requests/day, 3 searches/month
- Premium: 50 AI requests/day, 30 searches/month

## Cost Structure

| Service | Free Tier | Paid |
|---------|-----------|------|
| Supabase | 500MB DB, 50K auth users | $25/mo for Pro |
| Vercel | 100GB bandwidth | $20/mo for Pro |
| Claude API | Pay per token | ~$3-15/1M tokens |
| Open-Meteo | Unlimited | Free |
| Brave Search | 2,000 queries/mo | $5/1K queries |

**Estimated cost for 5 test users**: $2-5/month (mostly Claude API)

## File Structure

```
FragranceStackios/
├── FragranceStackios/          # iOS App
│   ├── App/
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   │   ├── AuthManager.swift
│   │   ├── FragranceAPIService.swift
│   │   ├── SupabaseDataService.swift
│   │   └── SupabaseConfig.swift
│   └── Theme/
├── supabase/                   # Backend
│   ├── migrations/
│   │   ├── 00001_initial_schema.sql
│   │   └── 00002_additional_functions.sql
│   ├── functions/
│   │   ├── _shared/
│   │   ├── recommend/
│   │   ├── nl-query/
│   │   ├── search-fragrance/
│   │   └── generate-description/
│   └── config.toml
├── admin-dashboard/            # Admin UI
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── package.json
└── docs/                       # Documentation
    ├── 01-architecture-overview.md
    ├── 02-supabase-setup.md
    └── ...
```

## Next Steps

1. **Set up Supabase** - See `02-supabase-setup.md`
2. **Deploy Edge Functions** - See `04-edge-functions.md`
3. **Configure iOS App** - See `05-ios-integration.md`
4. **Deploy Admin Dashboard** - See `06-admin-dashboard.md`
