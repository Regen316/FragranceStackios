// CORS and security headers for Edge Functions
// Allows requests from iOS app and admin dashboard

// Security headers to prevent common attacks
export const securityHeaders = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(self), microphone=()',
  'Cache-Control': 'no-store, no-cache, must-revalidate',
};

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

// Combined headers for all responses
export const allHeaders = {
  ...corsHeaders,
  ...securityHeaders,
};

// Handle CORS preflight requests
export function handleCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: allHeaders });
  }
  return null;
}

// Create JSON response with CORS and security headers
export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...allHeaders,
      'Content-Type': 'application/json',
    },
  });
}

// Create error response with CORS and security headers
// IMPORTANT: Never include internal error details in response
export function errorResponse(message: string, status = 400): Response {
  // Sanitize error message - remove any potential sensitive info
  const safeMessage = sanitizeErrorMessage(message);
  return jsonResponse({ error: safeMessage }, status);
}

// Sanitize error messages to prevent information leakage
function sanitizeErrorMessage(message: string): string {
  // Remove file paths
  let safe = message.replace(/\/[\w\/.-]+/g, '[path]');

  // Remove stack traces
  safe = safe.replace(/at\s+[\w.]+\s+\([^)]+\)/g, '');

  // Remove database table/column names from errors
  safe = safe.replace(/relation\s+"[\w.]+"/, 'resource');
  safe = safe.replace(/column\s+"[\w.]+"/, 'field');

  // Truncate long messages
  if (safe.length > 200) {
    safe = safe.substring(0, 200) + '...';
  }

  return safe.trim();
}
