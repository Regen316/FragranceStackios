// Natural Language Query Endpoint (Premium Feature)
// POST /nl-query
// Answers fragrance questions in natural language

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { verifyAuth, isPremium } from '../_shared/auth.ts';
import { checkRateLimit, checkSpendingCap, getRateLimitHeaders } from '../_shared/rate-limit.ts';
import { callClaude, isClaudeError, SYSTEM_PROMPTS } from '../_shared/claude.ts';
import { getWeatherWithLocation, isWeatherError, formatWeatherForPrompt } from '../_shared/weather.ts';

// Request validation
interface NLQueryRequest {
  query: string;
  latitude?: number;
  longitude?: number;
  include_collection?: boolean;
}

// Validate request body
function validateRequest(body: unknown): { valid: boolean; error?: string; data?: NLQueryRequest } {
  if (!body || typeof body !== 'object') {
    return { valid: false, error: 'Request body is required' };
  }

  const req = body as NLQueryRequest;

  // Query is required
  if (!req.query || typeof req.query !== 'string') {
    return { valid: false, error: 'Query is required' };
  }

  if (req.query.trim().length < 3) {
    return { valid: false, error: 'Query must be at least 3 characters' };
  }

  if (req.query.length > 1000) {
    return { valid: false, error: 'Query is too long (max 1000 characters)' };
  }

  // Basic input sanitization check
  const suspiciousPatterns = [
    /<script/i,
    /javascript:/i,
    /\{\{/,
    /\$\{/,
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(req.query)) {
      return { valid: false, error: 'Invalid characters in query' };
    }
  }

  // Validate coordinates if provided
  if (req.latitude !== undefined) {
    if (typeof req.latitude !== 'number' || req.latitude < -90 || req.latitude > 90) {
      return { valid: false, error: 'Invalid latitude' };
    }
  }
  if (req.longitude !== undefined) {
    if (typeof req.longitude !== 'number' || req.longitude < -180 || req.longitude > 180) {
      return { valid: false, error: 'Invalid longitude' };
    }
  }

  return { valid: true, data: req };
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

    // Check if user has premium access
    if (!isPremium(user)) {
      return errorResponse('Natural language queries require a premium subscription', 403);
    }

    // Check rate limit
    const rateLimit = await checkRateLimit(supabase, user, 'natural_language');
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

    // Parse and validate request body
    const body = await req.json().catch(() => ({}));
    const validation = validateRequest(body);

    if (!validation.valid) {
      return errorResponse(validation.error!, 400);
    }

    const request = validation.data!;

    // Get user's fragrance collection (default to include)
    let collectionContext = '';
    if (request.include_collection !== false) {
      const { data: collection, error: collectionError } = await supabase
        .rpc('get_user_collection', { p_user_id: user.id });

      if (!collectionError && collection && collection.length > 0) {
        const collectionSummary = collection.map((f: Record<string, unknown>) => ({
          id: f.fragrance_id,
          name: f.name,
          brand: f.brand,
          concentration: f.concentration,
          personal_rating: f.personal_rating,
          times_worn: f.times_worn,
          is_signature: f.is_signature,
          is_favorite: f.is_favorite,
          ai_description: f.ai_description,
          notes: {
            top: f.notes_top,
            heart: f.notes_heart,
            base: f.notes_base,
          },
          performance: {
            longevity: f.longevity_hours,
            projection: f.projection,
            sillage: f.sillage,
          },
        }));

        collectionContext = `\n\nUser's Fragrance Collection (${collection.length} fragrances):\n${JSON.stringify(collectionSummary, null, 2)}`;
      } else {
        collectionContext = '\n\nUser has no fragrances in their collection yet.';
      }
    }

    // Get weather if coordinates provided
    let weatherContext = '';
    let weatherData = null;

    if (request.latitude !== undefined && request.longitude !== undefined) {
      const weather = await getWeatherWithLocation(request.latitude, request.longitude);

      if (!isWeatherError(weather)) {
        weatherData = weather;
        weatherContext = `\n\nCurrent Weather & Location:\n${formatWeatherForPrompt(weather)}`;
      }
    }

    // Get current time context
    const now = new Date();
    const hour = now.getHours();
    let timeOfDay: string;
    if (hour >= 5 && hour < 12) timeOfDay = 'morning';
    else if (hour >= 12 && hour < 17) timeOfDay = 'afternoon';
    else if (hour >= 17 && hour < 21) timeOfDay = 'evening';
    else timeOfDay = 'night';

    const timeContext = `\nCurrent time: ${now.toLocaleTimeString()} (${timeOfDay})`;

    // Build the prompt
    const userMessage = `${request.query}

Context:${timeContext}${weatherContext}${collectionContext}`;

    // Call Claude
    const response = await callClaude(
      {
        messages: [{ role: 'user', content: userMessage }],
        system: SYSTEM_PROMPTS.naturalLanguage,
        maxTokens: 1500,
        temperature: 0.7,
      },
      {
        model: 'claude-sonnet-4-20250514',
        userId: user.id,
        requestType: 'natural_language',
        supabase,
      }
    );

    if (isClaudeError(response)) {
      console.error('Claude API error:', response.error);
      return errorResponse('Failed to process your query. Please try again.', 500);
    }

    // Extract any embedded recommendations from the response
    let recommendations: string[] = [];
    let cleanContent = response.content;

    const recMatch = response.content.match(/<!--RECOMMENDATIONS:(\{.*?\})-->/);
    if (recMatch) {
      try {
        const recData = JSON.parse(recMatch[1]);
        recommendations = recData.fragrance_ids || [];
        cleanContent = response.content.replace(/<!--RECOMMENDATIONS:.*?-->/, '').trim();
      } catch {
        // Ignore parse errors
      }
    }

    return new Response(
      JSON.stringify({
        answer: cleanContent,
        recommendations: recommendations.length > 0 ? recommendations : undefined,
        weather: weatherData,
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
    console.error('NL Query error:', error);
    return errorResponse('An unexpected error occurred', 500);
  }
});
