'use client';

interface Stats {
  totalUsers: number;
  activeUsersToday: number;
  totalCostToday: number;
  totalCostThisMonth: number;
  requestsToday: number;
  avgCostPerUser: number;
}

export default function StatsCards({ stats }: { stats: Stats }) {
  const cards = [
    {
      label: 'Total Users',
      value: stats.totalUsers.toLocaleString(),
      change: null,
    },
    {
      label: 'Active Today',
      value: stats.activeUsersToday.toLocaleString(),
      change: null,
    },
    {
      label: "Today's Cost",
      value: `$${stats.totalCostToday.toFixed(4)}`,
      change: null,
    },
    {
      label: 'Monthly Cost',
      value: `$${stats.totalCostThisMonth.toFixed(2)}`,
      change: null,
    },
    {
      label: 'Requests Today',
      value: stats.requestsToday.toLocaleString(),
      change: null,
    },
    {
      label: 'Avg Cost/User',
      value: `$${stats.avgCostPerUser.toFixed(4)}`,
      change: null,
    },
  ];

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
      {cards.map((card) => (
        <div key={card.label} className="stat-card">
          <span className="stat-value">{card.value}</span>
          <span className="stat-label">{card.label}</span>
          {card.change && (
            <span className={`stat-change ${card.change > 0 ? 'positive' : 'negative'}`}>
              {card.change > 0 ? '+' : ''}{card.change}%
            </span>
          )}
        </div>
      ))}
    </div>
  );
}
