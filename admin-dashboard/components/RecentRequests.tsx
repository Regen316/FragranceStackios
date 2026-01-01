'use client';

import { useEffect, useState } from 'react';
import { createBrowserSupabaseClient, LLMRequest } from '@/lib/supabase';
import { formatDistanceToNow } from 'date-fns';

const REQUEST_TYPE_LABELS: Record<string, string> = {
  recommendation: 'Recommendation',
  natural_language: 'NL Query',
  fragrance_description: 'Description',
  fragrance_search: 'Search',
};

export default function RecentRequests() {
  const [requests, setRequests] = useState<(LLMRequest & { profiles?: { email: string } })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRecentRequests();
  }, []);

  async function fetchRecentRequests() {
    const supabase = createBrowserSupabaseClient();

    const { data } = await supabase
      .from('llm_requests')
      .select('*, profiles(email)')
      .order('created_at', { ascending: false })
      .limit(10);

    setRequests(data || []);
    setLoading(false);
  }

  if (loading) {
    return (
      <div className="animate-pulse space-y-3">
        {[...Array(5)].map((_, i) => (
          <div key={i} className="h-12 bg-gray-100 rounded"></div>
        ))}
      </div>
    );
  }

  if (requests.length === 0) {
    return <p className="text-gray-500 text-sm">No requests yet</p>;
  }

  return (
    <div className="table-container">
      <table>
        <thead>
          <tr>
            <th>User</th>
            <th>Type</th>
            <th>Tokens</th>
            <th>Cost</th>
            <th>Latency</th>
            <th>Time</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {requests.map((request) => (
            <tr key={request.id}>
              <td className="text-xs">{(request as any).profiles?.email || 'Unknown'}</td>
              <td>
                <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                  {REQUEST_TYPE_LABELS[request.request_type] || request.request_type}
                </span>
              </td>
              <td className="text-xs text-gray-500">
                {request.tokens_input + request.tokens_output}
              </td>
              <td className="font-mono text-xs">
                ${request.cost_usd.toFixed(4)}
              </td>
              <td className="text-xs text-gray-500">
                {request.latency_ms ? `${request.latency_ms}ms` : '-'}
              </td>
              <td className="text-xs text-gray-500">
                {formatDistanceToNow(new Date(request.created_at), { addSuffix: true })}
              </td>
              <td>
                {request.success ? (
                  <span className="inline-flex h-2 w-2 rounded-full bg-green-400"></span>
                ) : (
                  <span className="inline-flex h-2 w-2 rounded-full bg-red-400"></span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
