// Rate limiting utilities for Edge Functions
// Enforces usage limits based on user tier

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { AuthUser, getTierLimits } from './auth.ts';

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  limit: number;
  resetsAt: string;
  error?: string;
}

export type EndpointType = 'recommendation' | 'natural_language' | 'fragrance_search' | 'fragrance_description';

// Endpoint configurations
const ENDPOINT_CONFIG: Record<
  EndpointType,
  {
    periodType: 'daily' | 'monthly';
    freeLimit: number;
    premiumLimit: number;
    requiresPremium: boolean;
  }
> = {
  recommendation: {
    periodType: 'daily',
    freeLimit: 5,
    premiumLimit: 50,
    requiresPremium: false,
  },
  natural_language: {
    periodType: 'daily',
    freeLimit: 0, // Not allowed for free tier
    premiumLimit: 20,
    requiresPremium: true,
  },
  fragrance_search: {
    periodType: 'monthly',
    freeLimit: 3,
    premiumLimit: 30,
    requiresPremium: false,
  },
  fragrance_description: {
    periodType: 'daily',
    freeLimit: 5, // Descriptions are cached, so this is rarely hit
    premiumLimit: 50,
    requiresPremium: false,
  },
};

// Check rate limit for a specific endpoint
export async function checkRateLimit(
  supabase: SupabaseClient,
  user: AuthUser,
  endpoint: EndpointType
): Promise<RateLimitResult> {
  const config = ENDPOINT_CONFIG[endpoint];
  const isPremium = user.tier === 'premium' || user.tier === 'admin';

  // Check if endpoint requires premium
  if (config.requiresPremium && !isPremium) {
    return {
      allowed: false,
      remaining: 0,
      limit: 0,
      resetsAt: new Date().toISOString(),
      error: 'This feature requires a premium subscription',
    };
  }

  const limit = isPremium ? config.premiumLimit : config.freeLimit;

  // If limit is 0, feature is not available
  if (limit === 0) {
    return {
      allowed: false,
      remaining: 0,
      limit: 0,
      resetsAt: new Date().toISOString(),
      error: 'This feature is not available for your subscription tier',
    };
  }

  // Call the database function to check and increment rate limit
  const { data, error } = await supabase.rpc('check_rate_limit', {
    p_user_id: user.id,
    p_endpoint: endpoint,
    p_limit: limit,
    p_period_type: config.periodType,
  });

  if (error) {
    console.error('Rate limit check failed:', error);
    // Fail open - allow the request but log the error
    return {
      allowed: true,
      remaining: limit - 1,
      limit,
      resetsAt: new Date(Date.now() + 86400000).toISOString(),
      error: 'Rate limit check failed, proceeding with caution',
    };
  }

  return {
    allowed: data.allowed,
    remaining: data.remaining,
    limit: data.limit,
    resetsAt: data.resets_at,
    error: data.error,
  };
}

// Get user's current usage stats
export async function getUserUsageStats(
  supabase: SupabaseClient,
  userId: string
): Promise<{
  dailyAiUsed: number;
  dailyAiLimit: number;
  monthlySearchUsed: number;
  monthlySearchLimit: number;
  totalCostUsd: number;
}> {
  const { data: profile } = await supabase
    .from('profiles')
    .select('tier, total_cost_usd')
    .eq('id', userId)
    .single();

  const tier = profile?.tier || 'free';
  const limits = getTierLimits(tier);

  // Get daily AI usage
  const { data: dailyRateLimit } = await supabase
    .from('rate_limits')
    .select('requests_count')
    .eq('user_id', userId)
    .eq('endpoint', 'recommendation')
    .eq('period_type', 'daily')
    .single();

  // Get monthly search usage
  const { data: monthlyRateLimit } = await supabase
    .from('rate_limits')
    .select('requests_count')
    .eq('user_id', userId)
    .eq('endpoint', 'fragrance_search')
    .eq('period_type', 'monthly')
    .single();

  return {
    dailyAiUsed: dailyRateLimit?.requests_count || 0,
    dailyAiLimit: limits.dailyAiLimit,
    monthlySearchUsed: monthlyRateLimit?.requests_count || 0,
    monthlySearchLimit: limits.monthlySearchLimit,
    totalCostUsd: profile?.total_cost_usd || 0,
  };
}

// Check if user has exceeded their daily spending cap
export async function checkSpendingCap(
  supabase: SupabaseClient,
  userId: string,
  tier: string
): Promise<{ allowed: boolean; dailySpent: number; cap: number }> {
  const cap = tier === 'free' ? 0.5 : 5.0; // $0.50 for free, $5 for premium

  // Get today's spending
  const today = new Date().toISOString().split('T')[0];

  const { data } = await supabase
    .from('llm_requests')
    .select('cost_usd')
    .eq('user_id', userId)
    .gte('created_at', `${today}T00:00:00Z`)
    .lt('created_at', `${today}T23:59:59Z`);

  const dailySpent = (data || []).reduce((sum, req) => sum + (req.cost_usd || 0), 0);

  return {
    allowed: dailySpent < cap,
    dailySpent,
    cap,
  };
}

// Check collection limit for free tier users
export async function checkCollectionLimit(
  supabase: SupabaseClient,
  userId: string,
  tier: string
): Promise<{ allowed: boolean; current: number; limit: number }> {
  const limit = tier === 'free' ? 5 : 999999;

  const { count } = await supabase
    .from('user_fragrances')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);

  const current = count || 0;

  return {
    allowed: current < limit,
    current,
    limit,
  };
}

// Format rate limit info for response headers
export function getRateLimitHeaders(result: RateLimitResult): Record<string, string> {
  return {
    'X-RateLimit-Limit': result.limit.toString(),
    'X-RateLimit-Remaining': result.remaining.toString(),
    'X-RateLimit-Reset': result.resetsAt,
  };
}
