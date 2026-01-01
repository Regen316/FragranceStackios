// Fragrance Search & Data Extraction Endpoint
// POST /search-fragrance
// Searches the web for fragrance info and extracts structured data

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders, handleCors, jsonResponse, errorResponse } from '../_shared/cors.ts';
import { verifyAuth } from '../_shared/auth.ts';
import { checkRateLimit, checkSpendingCap, getRateLimitHeaders } from '../_shared/rate-limit.ts';
import { callClaude, isClaudeError, SYSTEM_PROMPTS } from '../_shared/claude.ts';
import { searchFragrance, isSearchError, formatSearchResultsForPrompt, extractFragranceUrls, validateFragranceName } from '../_shared/search.ts';

// Request validation
interface SearchRequest {
  query: string;
  skip_existing_check?: boolean;
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

    // Check rate limit (monthly for searches)
    const rateLimit = await checkRateLimit(supabase, user, 'fragrance_search');
    if (!rateLimit.allowed) {
      return new Response(
        JSON.stringify({
          error: rateLimit.error || 'Monthly search limit reached',
          upgrade_hint: user.tier === 'free' ? 'Upgrade to premium for more searches' : undefined,
        }),
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

    // Parse request body
    const body = await req.json().catch(() => ({}));
    const request = body as SearchRequest;

    // Validate query
    const nameValidation = validateFragranceName(request.query);
    if (!nameValidation.valid) {
      return errorResponse(nameValidation.error!, 400);
    }

    const query = request.query.trim();

    // Check if fragrance already exists in database (unless skipped)
    if (!request.skip_existing_check) {
      const { data: existingFragrances } = await supabase
        .rpc('search_fragrances', { p_query: query });

      if (existingFragrances && existingFragrances.length > 0) {
        // Return existing matches
        return jsonResponse({
          source: 'database',
          matches: existingFragrances.slice(0, 5).map((f: Record<string, unknown>) => ({
            id: f.id,
            name: f.name,
            brand: f.brand,
            concentration: f.concentration,
            ai_description: f.ai_description,
            notes_top: f.notes_top,
            notes_heart: f.notes_heart,
            notes_base: f.notes_base,
          })),
          message: 'Found existing fragrances matching your search',
        });
      }
    }

    // Search the web for fragrance information
    const searchResults = await searchFragrance(query);

    if (isSearchError(searchResults)) {
      console.error('Search error:', searchResults.error);
      return errorResponse('Failed to search for fragrance information. Please try again.', 500);
    }

    if (searchResults.results.length === 0) {
      return jsonResponse({
        source: 'web',
        fragrance: null,
        message: 'No results found for this fragrance. Please check the spelling and try again.',
      });
    }

    // Extract URLs for reference
    const urls = extractFragranceUrls(searchResults.results);

    // Format search results for Claude
    const searchContext = formatSearchResultsForPrompt(searchResults.results);

    // Call Claude to extract structured data
    const userMessage = `Extract structured fragrance data from these search results for: "${query}"

Search Results:
${searchContext}

Please extract and return the fragrance information as JSON. If some information is not available in the search results, use reasonable defaults or null.`;

    const response = await callClaude(
      {
        messages: [{ role: 'user', content: userMessage }],
        system: SYSTEM_PROMPTS.fragranceExtraction,
        maxTokens: 1500,
        temperature: 0.3, // Lower temperature for more consistent extraction
      },
      {
        model: 'claude-sonnet-4-20250514',
        userId: user.id,
        requestType: 'fragrance_search',
        supabase,
      }
    );

    if (isClaudeError(response)) {
      console.error('Claude API error:', response.error);
      return errorResponse('Failed to extract fragrance information. Please try again.', 500);
    }

    // Parse the extracted data
    let fragranceData;
    try {
      const jsonMatch = response.content.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        fragranceData = JSON.parse(jsonMatch[0]);

        // Add URLs from search
        if (urls.fragrantica) fragranceData.fragrantica_url = urls.fragrantica;
        if (urls.parfumo) fragranceData.parfumo_url = urls.parfumo;
      } else {
        throw new Error('No JSON found in response');
      }
    } catch (parseError) {
      console.error('Failed to parse fragrance data:', parseError);
      return errorResponse('Failed to parse fragrance information. Please try again.', 500);
    }

    // Generate AI description for the fragrance
    const descriptionPrompt = `Create an evocative description for this fragrance:

Name: ${fragranceData.name}
Brand: ${fragranceData.brand}
Concentration: ${fragranceData.concentration}
Top Notes: ${(fragranceData.notes_top || []).join(', ')}
Heart Notes: ${(fragranceData.notes_heart || []).join(', ')}
Base Notes: ${(fragranceData.notes_base || []).join(', ')}
Fragrance Family: ${fragranceData.fragrance_family}
Gender: ${fragranceData.gender}`;

    const descriptionResponse = await callClaude(
      {
        messages: [{ role: 'user', content: descriptionPrompt }],
        system: SYSTEM_PROMPTS.fragranceDescription,
        maxTokens: 500,
        temperature: 0.8,
      },
      {
        model: 'claude-sonnet-4-20250514',
        userId: user.id,
        requestType: 'fragrance_description',
        supabase,
      }
    );

    if (!isClaudeError(descriptionResponse)) {
      fragranceData.ai_description = descriptionResponse.content;
    }

    // Calculate total cost
    const totalCost = response.costUsd + (isClaudeError(descriptionResponse) ? 0 : descriptionResponse.costUsd);

    return new Response(
      JSON.stringify({
        source: 'web',
        fragrance: fragranceData,
        search_urls: urls,
        message: 'Please review and confirm the fragrance details before adding to your collection.',
        usage: {
          tokens_input: response.inputTokens + (isClaudeError(descriptionResponse) ? 0 : descriptionResponse.inputTokens),
          tokens_output: response.outputTokens + (isClaudeError(descriptionResponse) ? 0 : descriptionResponse.outputTokens),
          cost_usd: totalCost,
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
    console.error('Search fragrance error:', error);
    return errorResponse('An unexpected error occurred', 500);
  }
});
