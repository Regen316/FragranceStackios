// Claude API wrapper with cost tracking
// Handles all LLM calls and logs usage to database

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

export interface ClaudeMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface ClaudeRequest {
  messages: ClaudeMessage[];
  system?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface ClaudeResponse {
  content: string;
  inputTokens: number;
  outputTokens: number;
  model: string;
  costUsd: number;
}

export interface ClaudeError {
  error: string;
  code?: string;
}

// Model pricing (updated Jan 2025)
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  'claude-sonnet-4-20250514': { input: 3.0, output: 15.0 },
  'claude-haiku-35-20241022': { input: 0.8, output: 4.0 },
  'claude-opus-4-20250514': { input: 15.0, output: 75.0 },
};

// Default model to use
const DEFAULT_MODEL = 'claude-sonnet-4-20250514';

// Calculate cost from token usage
export function calculateCost(
  model: string,
  inputTokens: number,
  outputTokens: number
): number {
  const pricing = MODEL_PRICING[model] || MODEL_PRICING[DEFAULT_MODEL];
  const inputCost = (inputTokens * pricing.input) / 1_000_000;
  const outputCost = (outputTokens * pricing.output) / 1_000_000;
  return Math.round((inputCost + outputCost) * 1_000_000) / 1_000_000; // Round to 6 decimal places
}

// Call Claude API
export async function callClaude(
  request: ClaudeRequest,
  options?: {
    model?: string;
    userId?: string;
    requestType?: string;
    supabase?: SupabaseClient;
  }
): Promise<ClaudeResponse | ClaudeError> {
  const apiKey = Deno.env.get('ANTHROPIC_API_KEY');

  if (!apiKey) {
    return { error: 'Anthropic API key not configured' };
  }

  const model = options?.model || DEFAULT_MODEL;
  const startTime = Date.now();

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model,
        max_tokens: request.maxTokens || 1024,
        temperature: request.temperature ?? 0.7,
        system: request.system,
        messages: request.messages,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      return {
        error: errorData.error?.message || `API error: ${response.status}`,
        code: errorData.error?.type,
      };
    }

    const data = await response.json();
    const latencyMs = Date.now() - startTime;

    const inputTokens = data.usage?.input_tokens || 0;
    const outputTokens = data.usage?.output_tokens || 0;
    const costUsd = calculateCost(model, inputTokens, outputTokens);

    const content = data.content?.[0]?.text || '';

    // Log to database if supabase client and user ID provided
    if (options?.supabase && options?.userId) {
      await logLlmRequest(options.supabase, {
        userId: options.userId,
        requestType: options.requestType || 'unknown',
        promptSummary: request.messages[request.messages.length - 1]?.content.slice(0, 500),
        responseSummary: content.slice(0, 500),
        model,
        inputTokens,
        outputTokens,
        costUsd,
        latencyMs,
        success: true,
      });
    }

    return {
      content,
      inputTokens,
      outputTokens,
      model,
      costUsd,
    };
  } catch (error) {
    const latencyMs = Date.now() - startTime;

    // Log error if we can
    if (options?.supabase && options?.userId) {
      await logLlmRequest(options.supabase, {
        userId: options.userId,
        requestType: options.requestType || 'unknown',
        promptSummary: request.messages[request.messages.length - 1]?.content.slice(0, 500),
        model,
        inputTokens: 0,
        outputTokens: 0,
        costUsd: 0,
        latencyMs,
        success: false,
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
      });
    }

    return {
      error: error instanceof Error ? error.message : 'Unknown error calling Claude API',
    };
  }
}

// Log LLM request to database
async function logLlmRequest(
  supabase: SupabaseClient,
  data: {
    userId: string;
    requestType: string;
    promptSummary?: string;
    responseSummary?: string;
    model: string;
    inputTokens: number;
    outputTokens: number;
    costUsd: number;
    latencyMs: number;
    success: boolean;
    errorMessage?: string;
  }
): Promise<void> {
  try {
    await supabase.from('llm_requests').insert({
      user_id: data.userId,
      request_type: data.requestType,
      prompt_summary: data.promptSummary,
      response_summary: data.responseSummary,
      model: data.model,
      tokens_input: data.inputTokens,
      tokens_output: data.outputTokens,
      cost_usd: data.costUsd,
      latency_ms: data.latencyMs,
      success: data.success,
      error_message: data.errorMessage,
    });

    // Update user's total cost
    if (data.success && data.costUsd > 0) {
      await supabase.rpc('increment_user_cost', {
        p_user_id: data.userId,
        p_amount: data.costUsd,
      });
    }
  } catch (error) {
    console.error('Failed to log LLM request:', error);
    // Don't throw - logging failure shouldn't break the main request
  }
}

// Check if response is an error
export function isClaudeError(response: ClaudeResponse | ClaudeError): response is ClaudeError {
  return 'error' in response;
}

// System prompts for different use cases
export const SYSTEM_PROMPTS = {
  recommendation: `You are a sophisticated fragrance expert and personal stylist. Your role is to recommend fragrances from the user's collection based on the context provided (occasion, weather, time of day, mood).

Guidelines:
- Only recommend fragrances from the user's collection
- Consider performance metrics (longevity, projection) for the occasion
- Factor in weather and temperature when relevant
- Provide brief, elegant explanations for your recommendations
- If the collection is limited, acknowledge this gracefully
- Be confident but not pretentious

Response format: JSON with structure:
{
  "recommendations": [
    {
      "fragrance_id": "uuid",
      "confidence": 0.95,
      "reasoning": "Brief explanation"
    }
  ],
  "summary": "One sentence summary of recommendations"
}`,

  naturalLanguage: `You are a sophisticated fragrance expert and personal stylist. The user will ask you questions about fragrances in natural language. You have access to their collection and current context (weather, location if provided).

Guidelines:
- Answer naturally and conversationally
- When recommending, only suggest from their collection
- If they ask about fragrances they don't own, you can discuss them but note they're not in the collection
- Consider context like weather, occasion, time of day
- Be knowledgeable but approachable

If making recommendations, include structured data at the end:
<!--RECOMMENDATIONS:{"fragrance_ids":["uuid1","uuid2"],"confidence":[0.9,0.8]}-->`,

  fragranceDescription: `You are a professional fragrance copywriter. Create an evocative, sensory description of the fragrance based on its notes and characteristics.

Guidelines:
- Be poetic but not flowery
- Describe the scent journey (opening, heart, dry down)
- Mention occasions or moods it suits
- Keep it to 2-3 paragraphs
- Be specific about the notes mentioned
- Avoid clichés like "perfect for any occasion"`,

  fragranceExtraction: `You are a fragrance data extraction expert. Given search results about a fragrance, extract structured information.

Return JSON with this exact structure:
{
  "name": "Full fragrance name",
  "brand": "Brand name",
  "concentration": "EDT|EDP|Parfum|Cologne|EDC|Other",
  "gender": "masculine|feminine|unisex",
  "release_year": 2020,
  "fragrance_family": "Woody|Fresh|Oriental|Floral|Fougere|Chypre|Gourmand|Citrus|Aquatic",
  "notes_top": ["Note 1", "Note 2"],
  "notes_heart": ["Note 1", "Note 2"],
  "notes_base": ["Note 1", "Note 2"],
  "longevity_hours": 8,
  "projection": 7,
  "sillage": 6,
  "season_spring": 7,
  "season_summer": 5,
  "season_fall": 8,
  "season_winter": 6,
  "occasion_office": 8,
  "occasion_date": 9,
  "occasion_casual": 7,
  "occasion_formal": 6,
  "occasion_club": 5,
  "fragrantica_url": "URL if found",
  "parfumo_url": "URL if found"
}

If information is not available, use reasonable defaults or null.
All numeric ratings should be 1-10 scale.`,
};
