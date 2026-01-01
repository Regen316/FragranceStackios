'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createBrowserSupabaseClient, ModelPricing } from '@/lib/supabase';
import Sidebar from '@/components/Sidebar';

export default function SettingsPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [pricing, setPricing] = useState<ModelPricing[]>([]);
  const [message, setMessage] = useState('');

  useEffect(() => {
    checkAuthAndFetchData();
  }, []);

  async function checkAuthAndFetchData() {
    const supabase = createBrowserSupabaseClient();

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      router.push('/login');
      return;
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('tier')
      .eq('id', user.id)
      .single();

    if (profile?.tier !== 'admin') {
      router.push('/login?error=unauthorized');
      return;
    }

    await fetchPricing(supabase);
    setLoading(false);
  }

  async function fetchPricing(supabase: ReturnType<typeof createBrowserSupabaseClient>) {
    const { data } = await supabase
      .from('model_pricing')
      .select('*')
      .order('model_name');

    setPricing(data || []);
  }

  async function handleUpdatePricing(
    id: string,
    field: 'input_price_per_million' | 'output_price_per_million',
    value: string
  ) {
    const numValue = parseFloat(value);
    if (isNaN(numValue) || numValue < 0) return;

    setPricing((prev) =>
      prev.map((p) => (p.id === id ? { ...p, [field]: numValue } : p))
    );
  }

  async function handleSave() {
    setSaving(true);
    setMessage('');

    const supabase = createBrowserSupabaseClient();

    try {
      for (const model of pricing) {
        await supabase
          .from('model_pricing')
          .update({
            input_price_per_million: model.input_price_per_million,
            output_price_per_million: model.output_price_per_million,
            updated_at: new Date().toISOString(),
          })
          .eq('id', model.id);
      }
      setMessage('Pricing updated successfully');
    } catch (error) {
      setMessage('Failed to update pricing');
    }

    setSaving(false);
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-amber-600"></div>
      </div>
    );
  }

  return (
    <div className="flex">
      <Sidebar activePage="settings" />

      <main className="flex-1 p-8">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-2xl font-bold text-gray-900 mb-8">Settings</h1>

          {/* Model Pricing Section */}
          <div className="card">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-lg font-semibold">Model Pricing</h2>
                <p className="text-sm text-gray-500 mt-1">
                  Update pricing per million tokens. These values are used to calculate costs.
                </p>
              </div>
              <a
                href="https://docs.anthropic.com/claude/docs/pricing"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-amber-600 hover:text-amber-700"
              >
                View Anthropic Pricing
              </a>
            </div>

            <div className="space-y-4">
              {pricing.map((model) => (
                <div key={model.id} className="border rounded-lg p-4">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <h3 className="font-medium">{model.display_name || model.model_name}</h3>
                      <p className="text-xs text-gray-500 font-mono">{model.model_name}</p>
                    </div>
                    <span className={`badge ${model.is_active ? 'badge-premium' : 'badge-free'}`}>
                      {model.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Input ($/1M tokens)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={model.input_price_per_million}
                        onChange={(e) =>
                          handleUpdatePricing(model.id, 'input_price_per_million', e.target.value)
                        }
                        className="input mt-1"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Output ($/1M tokens)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={model.output_price_per_million}
                        onChange={(e) =>
                          handleUpdatePricing(model.id, 'output_price_per_million', e.target.value)
                        }
                        className="input mt-1"
                      />
                    </div>
                  </div>

                  <p className="text-xs text-gray-400 mt-2">
                    Last updated: {new Date(model.updated_at).toLocaleString()}
                  </p>
                </div>
              ))}
            </div>

            {message && (
              <div
                className={`mt-4 p-3 rounded-md ${
                  message.includes('success')
                    ? 'bg-green-50 text-green-700'
                    : 'bg-red-50 text-red-700'
                }`}
              >
                {message}
              </div>
            )}

            <div className="mt-6 flex justify-end">
              <button onClick={handleSave} disabled={saving} className="btn-primary">
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>

          {/* Rate Limits Section */}
          <div className="card mt-8">
            <h2 className="text-lg font-semibold mb-4">Rate Limits</h2>
            <p className="text-sm text-gray-500 mb-4">
              Current rate limits by tier. These are hardcoded in the Edge Functions.
            </p>

            <div className="overflow-x-auto">
              <table>
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th>Free Tier</th>
                    <th>Premium Tier</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>Fragrances in Collection</td>
                    <td>5</td>
                    <td>Unlimited</td>
                  </tr>
                  <tr>
                    <td>AI Recommendations / Day</td>
                    <td>5</td>
                    <td>50</td>
                  </tr>
                  <tr>
                    <td>Natural Language Queries / Day</td>
                    <td>Not available</td>
                    <td>20</td>
                  </tr>
                  <tr>
                    <td>Fragrance Searches / Month</td>
                    <td>3</td>
                    <td>30</td>
                  </tr>
                  <tr>
                    <td>Daily Spending Cap</td>
                    <td>$0.50</td>
                    <td>$5.00</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <p className="text-xs text-gray-400 mt-4">
              To modify rate limits, update the Edge Function configuration and redeploy.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
