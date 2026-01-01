'use client';

import { useEffect, useState } from 'react';
import { createBrowserSupabaseClient, Profile } from '@/lib/supabase';
import { formatDistanceToNow } from 'date-fns';

export default function RecentUsers() {
  const [users, setUsers] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRecentUsers();
  }, []);

  async function fetchRecentUsers() {
    const supabase = createBrowserSupabaseClient();

    const { data } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(5);

    setUsers(data || []);
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

  if (users.length === 0) {
    return <p className="text-gray-500 text-sm">No users yet</p>;
  }

  return (
    <div className="space-y-3">
      {users.map((user) => (
        <div key={user.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
          <div>
            <p className="font-medium text-sm">{user.display_name || user.email}</p>
            <p className="text-xs text-gray-500">{user.email}</p>
          </div>
          <div className="text-right">
            <span className={`badge badge-${user.tier}`}>
              {user.tier}
            </span>
            <p className="text-xs text-gray-500 mt-1">
              {formatDistanceToNow(new Date(user.created_at), { addSuffix: true })}
            </p>
          </div>
        </div>
      ))}
    </div>
  );
}
