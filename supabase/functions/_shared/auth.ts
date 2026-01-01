// Authentication helpers for Edge Functions
// Verifies JWT tokens and extracts user information

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export interface AuthUser {
  id: string;
  email: string;
  tier: 'free' | 'premium' | 'admin';
}

export interface AuthResult {
  user: AuthUser | null;
  error: string | null;
  supabase: SupabaseClient;
}

// Create Supabase client with user's JWT
export function createSupabaseClient(authHeader: string | null): SupabaseClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: authHeader ? { Authorization: authHeader } : {},
    },
  });
}

// Create Supabase admin client (bypasses RLS)
export function createAdminClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  return createClient(supabaseUrl, serviceRoleKey);
}

// Verify authentication and get user profile
export async function verifyAuth(req: Request): Promise<AuthResult> {
  const authHeader = req.headers.get('Authorization');

  if (!authHeader) {
    return {
      user: null,
      error: 'Missing authorization header',
      supabase: createSupabaseClient(null),
    };
  }

  const supabase = createSupabaseClient(authHeader);

  // Get the authenticated user
  const { data: { user }, error: authError } = await supabase.auth.getUser();

  if (authError || !user) {
    return {
      user: null,
      error: authError?.message || 'Invalid or expired token',
      supabase,
    };
  }

  // Get user profile with tier
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('id, email, tier')
    .eq('id', user.id)
    .single();

  if (profileError || !profile) {
    return {
      user: null,
      error: 'User profile not found',
      supabase,
    };
  }

  return {
    user: {
      id: profile.id,
      email: profile.email,
      tier: profile.tier,
    },
    error: null,
    supabase,
  };
}

// Check if user has premium access
export function isPremium(user: AuthUser): boolean {
  return user.tier === 'premium' || user.tier === 'admin';
}

// Check if user is admin
export function isAdmin(user: AuthUser): boolean {
  return user.tier === 'admin';
}

// Get user's tier limits
export function getTierLimits(tier: string): {
  fragranceLimit: number;
  dailyAiLimit: number;
  monthlySearchLimit: number;
  nlQueriesAllowed: boolean;
  weatherAllowed: boolean;
} {
  if (tier === 'premium' || tier === 'admin') {
    return {
      fragranceLimit: 999999,
      dailyAiLimit: 50,
      monthlySearchLimit: 30,
      nlQueriesAllowed: true,
      weatherAllowed: true,
    };
  }

  // Free tier
  return {
    fragranceLimit: 5,
    dailyAiLimit: 5,
    monthlySearchLimit: 3,
    nlQueriesAllowed: false,
    weatherAllowed: false,
  };
}
