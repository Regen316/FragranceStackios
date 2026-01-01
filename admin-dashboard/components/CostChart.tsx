'use client';

import { useEffect, useState } from 'react';
import { createBrowserSupabaseClient, DailyCostSummary } from '@/lib/supabase';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { format, subDays } from 'date-fns';

interface ChartData {
  date: string;
  displayDate: string;
  cost: number;
  requests: number;
}

export default function CostChart() {
  const [data, setData] = useState<ChartData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCostData();
  }, []);

  async function fetchCostData() {
    const supabase = createBrowserSupabaseClient();

    // Get last 7 days of data
    const { data: dailyCosts } = await supabase
      .from('daily_cost_summary')
      .select('*')
      .order('date', { ascending: true })
      .limit(7);

    // Create a map of dates to costs
    const costMap = new Map<string, { cost: number; requests: number }>();

    (dailyCosts || []).forEach((day: DailyCostSummary) => {
      const dateStr = day.date;
      const existing = costMap.get(dateStr) || { cost: 0, requests: 0 };
      costMap.set(dateStr, {
        cost: existing.cost + (day.total_cost || 0),
        requests: existing.requests + (day.request_count || 0),
      });
    });

    // Fill in last 7 days
    const chartData: ChartData[] = [];
    for (let i = 6; i >= 0; i--) {
      const date = subDays(new Date(), i);
      const dateStr = format(date, 'yyyy-MM-dd');
      const displayDate = format(date, 'MMM d');
      const dayData = costMap.get(dateStr) || { cost: 0, requests: 0 };

      chartData.push({
        date: dateStr,
        displayDate,
        cost: dayData.cost,
        requests: dayData.requests,
      });
    }

    setData(chartData);
    setLoading(false);
  }

  if (loading) {
    return (
      <div className="h-64 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-600"></div>
      </div>
    );
  }

  return (
    <div className="h-64">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="displayDate"
            stroke="#6b7280"
            fontSize={12}
            tickLine={false}
          />
          <YAxis
            stroke="#6b7280"
            fontSize={12}
            tickLine={false}
            tickFormatter={(value) => `$${value.toFixed(2)}`}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: 'white',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
              boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
            }}
            formatter={(value: number) => [`$${value.toFixed(4)}`, 'Cost']}
          />
          <Area
            type="monotone"
            dataKey="cost"
            stroke="#d97706"
            fill="#fef3c7"
            strokeWidth={2}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
