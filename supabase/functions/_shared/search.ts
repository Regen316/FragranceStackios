// Brave Search API wrapper
// Used for looking up fragrance information from the web

export interface SearchResult {
  title: string;
  url: string;
  description: string;
}

export interface SearchResponse {
  results: SearchResult[];
  query: string;
}

export interface SearchError {
  error: string;
}

// Search for fragrance information using Brave Search API
export async function searchFragrance(
  fragranceName: string
): Promise<SearchResponse | SearchError> {
  const apiKey = Deno.env.get('BRAVE_SEARCH_API_KEY');

  if (!apiKey) {
    return { error: 'Brave Search API key not configured' };
  }

  try {
    // Clean up the search query
    const query = `${fragranceName} fragrance perfume notes`;

    const url = new URL('https://api.search.brave.com/res/v1/web/search');
    url.searchParams.set('q', query);
    url.searchParams.set('count', '10');
    url.searchParams.set('safesearch', 'moderate');

    const response = await fetch(url.toString(), {
      headers: {
        'Accept': 'application/json',
        'X-Subscription-Token': apiKey,
      },
    });

    if (!response.ok) {
      if (response.status === 429) {
        return { error: 'Search rate limit exceeded. Please try again later.' };
      }
      return { error: `Search API error: ${response.status}` };
    }

    const data = await response.json();

    const results: SearchResult[] = (data.web?.results || []).map(
      (result: { title: string; url: string; description: string }) => ({
        title: result.title,
        url: result.url,
        description: result.description,
      })
    );

    return {
      results,
      query,
    };
  } catch (error) {
    return {
      error: error instanceof Error ? error.message : 'Failed to search for fragrance',
    };
  }
}

// Check if search response is an error
export function isSearchError(
  response: SearchResponse | SearchError
): response is SearchError {
  return 'error' in response;
}

// Format search results for LLM context
export function formatSearchResultsForPrompt(results: SearchResult[]): string {
  if (results.length === 0) {
    return 'No search results found.';
  }

  return results
    .slice(0, 5) // Limit to top 5 results to save tokens
    .map((result, index) => {
      return `[${index + 1}] ${result.title}\nURL: ${result.url}\n${result.description}`;
    })
    .join('\n\n');
}

// Extract relevant fragrance URLs from search results
export function extractFragranceUrls(results: SearchResult[]): {
  fragrantica?: string;
  parfumo?: string;
  basenotes?: string;
} {
  const urls: { fragrantica?: string; parfumo?: string; basenotes?: string } = {};

  for (const result of results) {
    const url = result.url.toLowerCase();

    if (url.includes('fragrantica.com') && !urls.fragrantica) {
      urls.fragrantica = result.url;
    } else if (url.includes('parfumo.com') && !urls.parfumo) {
      urls.parfumo = result.url;
    } else if (url.includes('basenotes.com') && !urls.basenotes) {
      urls.basenotes = result.url;
    }
  }

  return urls;
}

// Validate fragrance name input
export function validateFragranceName(name: string): { valid: boolean; error?: string } {
  if (!name || typeof name !== 'string') {
    return { valid: false, error: 'Fragrance name is required' };
  }

  const trimmed = name.trim();

  if (trimmed.length < 2) {
    return { valid: false, error: 'Fragrance name must be at least 2 characters' };
  }

  if (trimmed.length > 200) {
    return { valid: false, error: 'Fragrance name is too long' };
  }

  // Check for suspicious input (basic injection prevention)
  const suspiciousPatterns = [
    /<script/i,
    /javascript:/i,
    /on\w+=/i,
    /\{\{/,
    /\$\{/,
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(trimmed)) {
      return { valid: false, error: 'Invalid characters in fragrance name' };
    }
  }

  return { valid: true };
}
