# Supabase Setup Guide

This guide walks you through setting up the Supabase backend for FragranceStack.

## Prerequisites

- A Supabase account (https://supabase.com)
- Supabase CLI installed (optional, for local development)

## Step 1: Create a Supabase Project

1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Fill in:
   - **Name**: `fragrancestack`
   - **Database Password**: Generate a strong password (save this!)
   - **Region**: Choose closest to your users
4. Click "Create new project"
5. Wait for the project to be ready (~2 minutes)

## Step 2: Get Your API Keys

1. Go to **Settings** → **API**
2. Copy these values (you'll need them later):
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJ...` (safe to include in app)
   - **service_role key**: `eyJ...` (keep secret! For admin only)

## Step 3: Run the Database Migration

1. Go to **SQL Editor** in your Supabase dashboard
2. Click "New Query"
3. Copy the contents of `/supabase/migrations/00001_initial_schema.sql`
4. Paste into the SQL editor
5. Click "Run" (or press Cmd/Ctrl + Enter)
6. Repeat for `/supabase/migrations/00002_additional_functions.sql`

You should see "Success. No rows returned" - this is expected.

### Verify Tables Were Created

1. Go to **Table Editor**
2. You should see these tables:
   - `profiles`
   - `fragrances`
   - `user_fragrances`
   - `wear_logs`
   - `llm_requests`
   - `rate_limits`
   - `model_pricing`
   - `app_settings`

## Step 4: Configure Authentication

### Enable Email Auth

1. Go to **Authentication** → **Providers**
2. Email should already be enabled
3. Configure settings as needed:
   - Enable/disable email confirmations
   - Customize email templates

### Enable Apple Sign-In

1. Go to **Authentication** → **Providers**
2. Find "Apple" and toggle it on
3. You'll need:
   - **Client ID**: Your Apple Services ID
   - **Secret Key**: Your Apple private key

To get these from Apple:
1. Go to https://developer.apple.com/account
2. Create an App ID with "Sign in with Apple" capability
3. Create a Services ID
4. Create a Key for Sign in with Apple

## Step 5: Set Up Edge Function Secrets

Edge Functions need API keys to call Claude and Brave Search.

### Using Supabase Dashboard

1. Go to **Edge Functions** → **Secrets**
2. Add these secrets:
   - `ANTHROPIC_API_KEY`: Your Claude API key from https://console.anthropic.com
   - `BRAVE_SEARCH_API_KEY`: Your Brave Search API key from https://brave.com/search/api/

### Using Supabase CLI

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase secrets set BRAVE_SEARCH_API_KEY=BSA...
```

## Step 6: Deploy Edge Functions

### Option A: Using Supabase CLI (Recommended)

1. Install the CLI:
```bash
npm install -g supabase
```

2. Login:
```bash
supabase login
```

3. Link your project:
```bash
cd /path/to/FragranceStackios
supabase link --project-ref your-project-ref
```

4. Deploy all functions:
```bash
supabase functions deploy recommend
supabase functions deploy nl-query
supabase functions deploy search-fragrance
supabase functions deploy generate-description
```

### Option B: Manual Upload (Dashboard)

1. Go to **Edge Functions**
2. Click "Create a new function"
3. For each function in `/supabase/functions/`:
   - Name it (e.g., `recommend`)
   - Upload the `index.ts` file
   - Also upload the `_shared/` folder contents

## Step 7: Create Your Admin Account

1. Go to **Authentication** → **Users**
2. Click "Add user" → "Create new user"
3. Enter your email and a password
4. After creation, click on the user
5. Note the user's UUID

Now update their tier to admin:

1. Go to **SQL Editor**
2. Run:
```sql
UPDATE profiles
SET tier = 'admin'
WHERE id = 'YOUR-USER-UUID';
```

## Step 8: Test the Setup

### Test Auth

```bash
curl -X POST 'https://YOUR-PROJECT.supabase.co/auth/v1/token?grant_type=password' \
  -H 'apikey: YOUR-ANON-KEY' \
  -H 'Content-Type: application/json' \
  -d '{"email": "test@example.com", "password": "testpassword"}'
```

### Test Edge Function

```bash
curl -X POST 'https://YOUR-PROJECT.supabase.co/functions/v1/recommend' \
  -H 'Authorization: Bearer YOUR-JWT-TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"occasion": "casual", "time_of_day": "evening"}'
```

## Troubleshooting

### "Permission denied" errors
- Check that RLS policies are correctly applied
- Verify the user's JWT token is valid
- Check the user exists in the `profiles` table

### Edge Function not found
- Ensure the function is deployed
- Check the function name matches the URL
- Verify JWT verification is configured in `config.toml`

### Database connection issues
- Check your project is not paused (free tier pauses after 1 week of inactivity)
- Verify database password is correct
- Check region connectivity

## Environment Variables Reference

### For iOS App (`SupabaseConfig.swift`)
```swift
static let projectURL = "https://xxxxx.supabase.co"
static let anonKey = "eyJ..."  // anon/public key
```

### For Admin Dashboard (`.env.local`)
```
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...  # Only for server-side admin operations
```

### For Edge Functions (Supabase Secrets)
```
ANTHROPIC_API_KEY=sk-ant-...
BRAVE_SEARCH_API_KEY=BSA...
```

## Next Steps

- [03-database-schema.md](03-database-schema.md) - Understand the database structure
- [04-edge-functions.md](04-edge-functions.md) - Learn about the API endpoints
- [05-ios-integration.md](05-ios-integration.md) - Connect the iOS app
