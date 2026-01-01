// AI Fragrance Recommendation Endpoint
// POST /recommend
// Returns personalized fragrance recommendations from user's collection

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { verifyAuth, AuthUser } from '../_shared/auth.ts';
import { checkRateLimit, checkSpendingCap, getRateLimitHeaders } from '../_shared/rate-limit.ts';
import { callClaude, isClaudeError, SYSTEM_PROMPTS } from '../_shared/claude.ts';
import { getWeatherWithLocation, isWeatherError, formatWeatherForPrompt, getSeasonFromTemperature } from '../_shared/weather.ts';

// Request validation
interface RecommendRequest {
  occasion?: 'office' | 'date' | 'casual' | 'formal' | 'club';
  time_of_day?: 'morning' | 'afternoon' | 'evening' | 'night';
  latitude?: number;
  longitude?: number;
  mood?: string;
  preferences?: string;
}

// Validate request body
function validateRequest(body: unknown): { valid: boolean; error?: string; data?: RecommendRequest } {
  if (!body || typeof body !== 'object') {
    return { valid: false, error: 'Request body is required' };
  }

  const req = body as RecommendRequest;

  // Validate occasion if provided
  if (req.occasion && !['office', 'date', 'casual', 'formal', 'club'].includes(req.occasion)) {
    return { valid: false, error: 'Invalid occasion value' };
  }

  // Validate time_of_day if provided
  if (req.time_of_day && !['morning', 'afternoon', 'evening', 'night'].includes(req.time_of_day)) {
    return { valid: false, error: 'Invalid time_of_day value' };
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

  // Validate mood/preferences length
  if (req.mood && req.mood.length > 200) {
    return { valid: false, error: 'Mood description too long (max 200 characters)' };
  }
  if (req.preferences && req.preferences.length > 500) {
    return { valid: false, error: 'Preferences too long (max 500 characters)' };
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

    // Check rate limit
    const rateLimit = await checkRateLimit(supabase, user, 'recommendation');
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

    // Get user's fragrance collection
    const { data: collection, error: collectionError } = await supabase
      .rpc('get_user_collection', { p_user_id: user.id });

    if (collectionError) {
      console.error('Failed to get collection:', collectionError);
      return errorResponse('Failed to retrieve your collection', 500);
    }

    if (!collection || collection.length === 0) {
      return jsonResponse({
        recommendations: [],
        message: 'Your collection is empty. Add some fragrances to get recommendations!',
      });
    }

    // Get weather if coordinates provided (premium feature check is in the function)
    let weatherContext = '';
    let weatherData = null;

    if (request.latitude !== undefined && request.longitude !== undefined) {
      const isPremium = user.tier === 'premium' || user.tier === 'admin';

      if (isPremium) {
        const weather = await getWeatherWithLocation(request.latitude, request.longitude);

        if (!isWeatherError(weather)) {
          weatherData = weather;
          weatherContext = `\n\nCurrent Weather:\n${formatWeatherForPrompt(weather)}`;
        }
      }
    }

    // Build the prompt
    const collectionSummary = collection.map((f: Record<string, unknown>) => ({
      id: f.fragrance_id,
      name: f.name,
      brand: f.brand,
      concentration: f.concentration,
      personal_rating: f.personal_rating,
      times_worn: f.times_worn,
      is_signature: f.is_signature,
      is_favorite: f.is_favorite,
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
      seasons: {
        spring: f.season_spring,
        summer: f.season_summer,
        fall: f.season_fall,
        winter: f.season_winter,
      },
      occasions: {
        office: f.occasion_office,
        date: f.occasion_date,
        casual: f.occasion_casual,
        formal: f.occasion_formal,
        club: f.occasion_club,
      },
    }));

    let contextParts = [];

    if (request.occasion) {
      contextParts.push(`Occasion: ${request.occasion}`);
    }
    if (request.time_of_day) {
      contextParts.push(`Time of day: ${request.time_of_day}`);
    }
    if (request.mood) {
      contextParts.push(`Mood/vibe: ${request.mood}`);
    }
    if (request.preferences) {
      contextParts.push(`Preferences: ${request.preferences}`);
    }

    // Infer season from weather if available
    if (weatherData) {
      const season = getSeasonFromTemperature(weatherData.temperature_f);
      contextParts.push(`Current season (based on temperature): ${season}`);
    }

    const userMessage = `Here is my fragrance collection:

${JSON.stringify(collectionSummary, null, 2)}

${contextParts.length > 0 ? 'Context:\n' + contextParts.join('\n') : 'No specific context provided - give me your best general recommendations.'}${weatherContext}

Please recommend the top 3-5 fragrances from my collection that would be most suitable, with confidence scores and brief reasoning for each.`;

    // Call Claude
    const response = await callClaude(
      {
        messages: [{ role: 'user', content: userMessage }],
        system: SYSTEM_PROMPTS.recommendation,
        maxTokens: 1024,
        temperature: 0.7,
      },
      {
        model: 'claude-sonnet-4-20250514',
        userId: user.id,
        requestType: 'recommendation',
        supabase,
      }
    );

    if (isClaudeError(response)) {
      console.error('Claude API error:', response.error);
      return errorResponse('Failed to generate recommendations. Please try again.', 500);
    }

    // Parse Claude's response
    let recommendations;
    try {
      // Try to extract JSON from the response
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        recommendations = JSON.parse(jsonMatch[0]);
      } else {
        // If no JSON, return the text response
        recommendations = {
          recommendations: [],
          summary: response.content,
        };
      }
    } catch {
      recommendations = {
        recommendations: [],
        summary: response.content,
      };
    }

    return new Response(
      JSON.stringify({
        ...recommendations,
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
    console.error('Recommendation error:', error);
    return errorResponse('An unexpected error occurred', 500);
  }
});
