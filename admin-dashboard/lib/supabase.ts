import { createClient } from '@supabase/supabase-js';
import { createBrowserClient } from '@supabase/ssr';

// Environment variables - set these in Vercel or .env.local
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Browser client for client-side operations
export const createBrowserSupabaseClient = () =>
  createBrowserClient(supabaseUrl, supabaseAnonKey);

// Server client for server-side operations
export const createServerSupabaseClient = () =>
  createClient(supabaseUrl, supabaseAnonKey);

// Admin client for admin operations (uses service role key)
export const createAdminSupabaseClient = () => {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceRoleKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set');
  }
  return createClient(supabaseUrl, serviceRoleKey);
};

// Types for database tables
export interface Profile {
  id: string;
  email: string;
  display_name: string | null;
  tier: 'free' | 'premium' | 'admin';
  fragrance_limit: number;
  daily_ai_limit: number;
  monthly_search_limit: number;
  total_cost_usd: number;
  created_at: string;
  last_active_at: string;
}

export interface LLMRequest {
  id: string;
  user_id: string;
  request_type: 'recommendation' | 'natural_language' | 'fragrance_description' | 'fragrance_search';
  prompt_summary: string | null;
  response_summary: string | null;
  model: string;
  tokens_input: number;
  tokens_output: number;
  cost_usd: number;
  latency_ms: number | null;
  success: boolean;
  error_message: string | null;
  created_at: string;
}

export interface Fragrance {
  id: string;
  name: string;
  brand: string;
  concentration: string | null;
  gender: string | null;
  notes_top: string[] | null;
  notes_heart: string[] | null;
  notes_base: string[] | null;
  ai_description: string | null;
  is_verified: boolean;
  created_at: string;
}

export interface ModelPricing {
  id: string;
  model_name: string;
  display_name: string | null;
  input_price_per_million: number;
  output_price_per_million: number;
  is_active: boolean;
  updated_at: string;
}

export interface DailyCostSummary {
  date: string;
  request_type: string;
  request_count: number;
  total_input_tokens: number;
  total_output_tokens: number;
  total_cost: number;
  avg_cost_per_request: number;
  avg_latency_ms: number;
}

export interface UserStats {
  id: string;
  email: string;
  display_name: string | null;
  tier: string;
  created_at: string;
  last_active_at: string;
  total_cost_usd: number;
  fragrance_count: number;
  wear_log_count: number;
  llm_request_count: number;
  calculated_total_cost: number;
}
