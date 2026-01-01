// Generate Fragrance Description Endpoint
// POST /generate-description
// Generates an AI description for a fragrance (one-time, cached)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { verifyAuth, isAdmin } from '../_shared/auth.ts';
import { checkRateLimit, checkSpendingCap, getRateLimitHeaders } from '../_shared/rate-limit.ts';
import { callClaude, isClaudeError, SYSTEM_PROMPTS } from '../_shared/claude.ts';

// Request validation
interface GenerateDescriptionRequest {
  fragrance_id: string;
  force_regenerate?: boolean;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  // Only accept POST
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405);
  }

  try {
    // Verify authentication
    const { user, error: authError, supabase } = await verifyAuth(req);

    if (authError || !user) {
      return errorResponse(authError || 'Unauthorized', 401);
    }

    // Parse request body
    const body = await req.json().catch(() => ({}));
    const request = body as GenerateDescriptionRequest;

    // Validate fragrance_id
    if (!request.fragrance_id || typeof request.fragrance_id !== 'string') {
      return errorResponse('fragrance_id is required', 400);
    }

    // UUID validation
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(request.fragrance_id)) {
      return errorResponse('Invalid fragrance_id format', 400);
    }

    // Get the fragrance
    const { data: fragrance, error: fragranceError } = await supabase
      .from('fragrances')
      .select('*')
      .eq('id', request.fragrance_id)
      .single();

    if (fragranceError || !fragrance) {
      return errorResponse('Fragrance not found', 404);
    }

    // Check if description already exists (unless force regenerate)
    if (fragrance.ai_description && !request.force_regenerate) {
      return jsonResponse({
        fragrance_id: fragrance.id,
        description: fragrance.ai_description,
        generated_at: fragrance.ai_description_generated_at,
        cached: true,
        message: 'Description already exists. Use force_regenerate=true to regenerate.',
      });
    }

    // Only admin or creator can force regenerate
    if (request.force_regenerate && !isAdmin(user) && fragrance.created_by !== user.id) {
      return errorResponse('Only the creator or admin can regenerate descriptions', 403);
    }

    // Check rate limit
    const rateLimit = await checkRateLimit(supabase, user, 'fragrance_description');
    if (!rateLimit.allowed) {
      return new Response(
        JSON.stringify({ error: rateLimit.error || 'Rate limit exceeded' }),
        {
          status: 429,
          headers: {
            ...corsHeaders,
            ...getRateLimitHeaders(rateLimit),
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Check spending cap
    const spendingCheck = await checkSpendingCap(supabase, user.id, user.tier);
    if (!spendingCheck.allowed) {
      return errorResponse('Daily spending limit reached. Please try again tomorrow.', 429);
    }

    // Build the prompt
    const prompt = `Create an evocative description for this fragrance:

Name: ${fragrance.name}
Brand: ${fragrance.brand}
Concentration: ${fragrance.concentration || 'Unknown'}
Gender: ${fragrance.gender || 'Unisex'}
Release Year: ${fragrance.release_year || 'Unknown'}
Fragrance Family: ${fragrance.fragrance_family || 'Unknown'}

Notes:
- Top: ${(fragrance.notes_top || []).join(', ') || 'Unknown'}
- Heart: ${(fragrance.notes_heart || []).join(', ') || 'Unknown'}
- Base: ${(fragrance.notes_base || []).join(', ') || 'Unknown'}

Performance:
- Longevity: ${fragrance.longevity_hours ? `${fragrance.longevity_hours} hours` : 'Unknown'}
- Projection: ${fragrance.projection ? `${fragrance.projection}/10` : 'Unknown'}
- Sillage: ${fragrance.sillage ? `${fragrance.sillage}/10` : 'Unknown'}

Best Seasons: ${[
  fragrance.season_spring > 6 ? 'Spring' : null,
  fragrance.season_summer > 6 ? 'Summer' : null,
  fragrance.season_fall > 6 ? 'Fall' : null,
  fragrance.season_winter > 6 ? 'Winter' : null,
].filter(Boolean).join(', ') || 'Year-round'}

Best Occasions: ${[
  fragrance.occasion_office > 6 ? 'Office' : null,
  fragrance.occasion_date > 6 ? 'Date' : null,
  fragrance.occasion_casual > 6 ? 'Casual' : null,
  fragrance.occasion_formal > 6 ? 'Formal' : null,
  fragrance.occasion_club > 6 ? 'Night Out' : null,
].filter(Boolean).join(', ') || 'Versatile'}`;

    // Call Claude
    const response = await callClaude(
      {
        messages: [{ role: 'user', content: prompt }],
        system: SYSTEM_PROMPTS.fragranceDescription,
        maxTokens: 600,
        temperature: 0.8,
      },
      {
        model: 'claude-sonnet-4-20250514',
        userId: user.id,
        requestType: 'fragrance_description',
        supabase,
      }
    );

    if (isClaudeError(response)) {
      console.error('Claude API error:', response.error);
      return errorResponse('Failed to generate description. Please try again.', 500);
    }

    // Save the description to the fragrance
    const { error: updateError } = await supabase
      .from('fragrances')
      .update({
        ai_description: response.content,
        ai_description_generated_at: new Date().toISOString(),
        ai_description_cost_usd: response.costUsd,
      })
      .eq('id', fragrance.id);

    if (updateError) {
      console.error('Failed to save description:', updateError);
      // Still return the description even if save failed
    }

    return new Response(
      JSON.stringify({
        fragrance_id: fragrance.id,
        description: response.content,
        generated_at: new Date().toISOString(),
        cached: false,
        saved: !updateError,
        usage: {
          tokens_input: response.inputTokens,
          tokens_output: response.outputTokens,
          cost_usd: response.costUsd,
        },
        rate_limit: {
          remaining: rateLimit.remaining,
          limit: rateLimit.limit,
          resets_at: rateLimit.resetsAt,
        },
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          ...getRateLimitHeaders(rateLimit),
          'Content-Type': 'application/json',
        },
      }
    );
  } catch (error) {
    console.error('Generate description error:', error);
    return errorResponse('An unexpected error occurred', 500);
  }
});
