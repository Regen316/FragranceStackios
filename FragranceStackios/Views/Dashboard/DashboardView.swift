//
//  DashboardView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \UserFragrance.createdAt, order: .reverse)
    var userFragrances: [UserFragrance]

    @Query(sort: \WearLog.dateWorn, order: .reverse)
    var allWearLogs: [WearLog]

    @Query(sort: \Recommendation.createdAt, order: .reverse)
    var recommendations: [Recommendation]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Today's Recommendation Card
                    TodayRecommendationCard(recommendations: recommendations)

                    // Quick Stats Section
                    QuickStatsSection(
                        userFragrances: userFragrances,
                        wearLogs: allWearLogs
                    )

                    // Recent Wear Log Entries
                    RecentWearLogsSection(wearLogs: allWearLogs)

                    // What should I wear CTA
                    NavigationLink(destination: RecommenderPlaceholder()) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .semibold))

                            Text("What should I wear?")
                                .font(.appHeadline())

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.appGold, .appGold.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.visible)
            .background(Color.appBackground)
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - Today's Recommendation Card

struct TodayRecommendationCard: View {
    let recommendations: [Recommendation]

    var todayRecommendation: Recommendation? {
        recommendations.first { Calendar.current.isDateInToday($0.createdAt) }
    }

    var body: some View {
        if let recommendation = todayRecommendation {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Recommendation")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        Text(recommendation.fragrance.displayName)
                            .font(.appHeadline())
                            .foregroundColor(.appNavy)
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 4) {
                        Text("\(Int(recommendation.confidenceScore))%")
                            .font(.appStat())
                            .foregroundColor(.appGold)

                        Text(recommendation.confidenceLevel)
                            .font(.appCaption())
                            .foregroundColor(.gray)
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Occasion")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                        Text(recommendation.occasion.rawValue)
                            .font(.appBody())
                            .foregroundColor(.appNavy)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time of Day")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                        Text(recommendation.timeOfDay.rawValue)
                            .font(.appBody())
                            .foregroundColor(.appNavy)
                    }

                    Spacer()
                }
            }
            .padding(16)
            .fragranceCardStyle()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Recommendation")
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .textCase(.uppercase)

                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.appGold)

                    Text("No recommendation yet")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    Text("Check the Recommender tab to get started")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding(16)
            .fragranceCardStyle()
        }
    }
}

// MARK: - Quick Stats Section

struct QuickStatsSection: View {
    let userFragrances: [UserFragrance]
    let wearLogs: [WearLog]

    var collectionSize: Int {
        userFragrances.count
    }

    var thisMonthWears: Int {
        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return wearLogs.filter { $0.dateWorn >= monthStart }.count
    }

    var mostWornFragrance: UserFragrance? {
        userFragrances.max { $0.timesWorn < $1.timesWorn }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Stats")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                // Collection Size Card
                StatCard(
                    icon: "square.grid.2x2.fill",
                    stat: "\(collectionSize)",
                    label: "In Collection"
                )

                // This Month Wears Card
                StatCard(
                    icon: "calendar",
                    stat: "\(thisMonthWears)",
                    label: "Wears This Month"
                )

                // Favorite Fragrance Card
                if let favorite = mostWornFragrance {
                    StatCard(
                        icon: "heart.fill",
                        stat: "\(favorite.timesWorn)",
                        label: favorite.fragrance.name.count > 15
                            ? String(favorite.fragrance.name.prefix(10)) + "..."
                            : favorite.fragrance.name
                    )
                } else {
                    StatCard(
                        icon: "heart.fill",
                        stat: "0",
                        label: "Most Worn"
                    )
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let stat: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appGold)

            Text(stat)
                .font(.appStat())
                .foregroundColor(.appNavy)

            Text(label)
                .font(.appCaption())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .fragranceCardStyle()
    }
}

// MARK: - Recent Wear Logs Section

struct RecentWearLogsSection: View {
    let wearLogs: [WearLog]

    var recentLogs: [WearLog] {
        Array(wearLogs.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Wears")
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            if recentLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No wear logs yet")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    Text("Start logging your fragrances to see them here")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentLogs, id: \.id) { log in
                        WearLogRow(wearLog: log)

                        if log.id != recentLogs.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding(12)
                .fragranceCardStyle()
            }
        }
    }
}

// MARK: - Wear Log Row Component

struct WearLogRow: View {
    let wearLog: WearLog

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: wearLog.dateWorn)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(wearLog.fragrance.displayName)
                    .font(.appSubheadline())
                    .foregroundColor(.appNavy)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(wearLog.occasion.rawValue, systemImage: "tag.fill")
                        .font(.appCaption())
                        .foregroundColor(.gray)

                    Label(wearLog.timeOfDay.rawValue, systemImage: "clock.fill")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                }
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDate)
                    .font(.appCaption())
                    .foregroundColor(.gray)

                if wearLog.compliments > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        Text("\(wearLog.compliments)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Fragrance.self, inMemory: true)
}
