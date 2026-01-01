'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createBrowserSupabaseClient } from '@/lib/supabase';
import Sidebar from '@/components/Sidebar';
import StatsCards from '@/components/StatsCards';
import CostChart from '@/components/CostChart';
import RecentUsers from '@/components/RecentUsers';
import RecentRequests from '@/components/RecentRequests';

interface DashboardStats {
  totalUsers: number;
  activeUsersToday: number;
  totalCostToday: number;
  totalCostThisMonth: number;
  requestsToday: number;
  avgCostPerUser: number;
}

export default function Dashboard() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    checkAuthAndFetchData();
  }, []);

  async function checkAuthAndFetchData() {
    const supabase = createBrowserSupabaseClient();

    // Check if user is authenticated and is admin
    const { data: { user } } = await supabase.auth.getUser();

    if (!user) {
      router.push('/login');
      return;
    }

    // Check if user is admin
    const { data: profile } = await supabase
      .from('profiles')
      .select('tier')
      .eq('id', user.id)
      .single();

    if (profile?.tier !== 'admin') {
      // Not an admin, redirect to login
      router.push('/login?error=unauthorized');
      return;
    }

    setIsAdmin(true);
    await fetchStats(supabase);
    setLoading(false);
  }

  async function fetchStats(supabase: ReturnType<typeof createBrowserSupabaseClient>) {
    const today = new Date().toISOString().split('T')[0];
    const startOfMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString();

    // Fetch total users
    const { count: totalUsers } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true });

    // Fetch active users today
    const { count: activeUsersToday } = await supabase
      .from('profiles')
      .select('*', { count: 'exact', head: true })
      .gte('last_active_at', `${today}T00:00:00Z`);

    // Fetch today's costs
    const { data: todayCosts } = await supabase
      .from('llm_requests')
      .select('cost_usd')
      .gte('created_at', `${today}T00:00:00Z`);

    const totalCostToday = (todayCosts || []).reduce((sum, r) => sum + (r.cost_usd || 0), 0);
    const requestsToday = todayCosts?.length || 0;

    // Fetch this month's costs
    const { data: monthCosts } = await supabase
      .from('llm_requests')
      .select('cost_usd')
      .gte('created_at', startOfMonth);

    const totalCostThisMonth = (monthCosts || []).reduce((sum, r) => sum + (r.cost_usd || 0), 0);

    // Calculate average cost per user
    const avgCostPerUser = totalUsers && totalUsers > 0
      ? totalCostThisMonth / totalUsers
      : 0;

    setStats({
      totalUsers: totalUsers || 0,
      activeUsersToday: activeUsersToday || 0,
      totalCostToday,
      totalCostThisMonth,
      requestsToday,
      avgCostPerUser,
    });
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-amber-600"></div>
      </div>
    );
  }

  if (!isAdmin) {
    return null;
  }

  return (
    <div className="flex">
      <Sidebar activePage="dashboard" />

      <main className="flex-1 p-8">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-2xl font-bold text-gray-900 mb-8">Dashboard</h1>

          {stats && <StatsCards stats={stats} />}

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-8">
            <div className="card">
              <h2 className="text-lg font-semibold mb-4">Cost Trend (Last 7 Days)</h2>
              <CostChart />
            </div>

            <div className="card">
              <h2 className="text-lg font-semibold mb-4">Recent Users</h2>
              <RecentUsers />
            </div>
          </div>

          <div className="mt-8 card">
            <h2 className="text-lg font-semibold mb-4">Recent AI Requests</h2>
            <RecentRequests />
          </div>
        </div>
      </main>
    </div>
  );
}
