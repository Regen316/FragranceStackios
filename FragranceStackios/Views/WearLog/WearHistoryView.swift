//
//  WearHistoryView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct WearHistoryView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \WearLog.dateWorn, order: .reverse)
    var allWearLogs: [WearLog]

    @Query(sort: \UserFragrance.timesWorn, order: .reverse)
    var userFragrances: [UserFragrance]

    @State private var showQuickLog = false
    @State private var selectedFragranceFilter: Fragrance?
    @State private var selectedOccasionFilter: Occasion?
    @State private var selectedDateRange: DateRange = .allTime
    @State private var showFilters = false

    // MARK: - Computed Properties

    var filteredWearLogs: [WearLog] {
        var filtered = allWearLogs

        // Filter by fragrance
        if let fragrance = selectedFragranceFilter {
            filtered = filtered.filter { $0.fragrance.id == fragrance.id }
        }

        // Filter by occasion
        if let occasion = selectedOccasionFilter {
            filtered = filtered.filter { $0.occasion == occasion }
        }

        // Filter by date range
        let calendar = Calendar.current
        let now = Date()
        let dateLimit: Date?

        switch selectedDateRange {
        case .allTime:
            dateLimit = nil
        case .thisMonth:
            dateLimit = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .thisYear:
            dateLimit = calendar.date(from: calendar.dateComponents([.year], from: now))
        case .thisWeek:
            dateLimit = calendar.date(byAdding: .day, value: -7, to: now)
        }

        if let limit = dateLimit {
            filtered = filtered.filter { $0.dateWorn >= limit }
        }

        return filtered
    }

    var mostWornFragrance: UserFragrance? {
        userFragrances.max { $0.timesWorn < $1.timesWorn }
    }

    var totalWearsThisMonth: Int {
        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        return allWearLogs.filter { $0.dateWorn >= monthStart }.count
    }

    var varietyScore: Int {
        guard userFragrances.count > 0 else { return 0 }
        let uniqueFragrancesWorn = Set(allWearLogs.map { $0.fragrance.id }).count
        return Int(Double(uniqueFragrancesWorn) / Double(userFragrances.count) * 100)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Cards Section
                        StatsCardsSection(
                            mostWornFragrance: mostWornFragrance,
                            totalWearsThisMonth: totalWearsThisMonth,
                            varietyScore: varietyScore
                        )

                        // Filter Section
                        FilterSection(
                            selectedFragrance: $selectedFragranceFilter,
                            selectedOccasion: $selectedOccasionFilter,
                            selectedDateRange: $selectedDateRange,
                            userFragrances: userFragrances
                        )

                        // Wear History List
                        if filteredWearLogs.isEmpty {
                            EmptyStateView(
                                icon: "calendar",
                                title: "No Wear History",
                                message: selectedFragranceFilter != nil || selectedOccasionFilter != nil
                                    ? "No entries match your filters"
                                    : "Start logging your fragrances to see history here"
                            )
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(filteredWearLogs, id: \.id) { log in
                                    WearHistoryRow(wearLog: log)

                                    if log.id != filteredWearLogs.last?.id {
                                        Divider()
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }

                // Quick Log Button
                VStack {
                    Button(action: { showQuickLog = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))

                            Text("Log Wear")
                                .font(.appSubheadline())
                                .fontWeight(.semibold)

                            Spacer()
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.appGold, .appGold.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(16)
                }
                .background(Color.appBackground)
            }
            .background(Color.appBackground)
            .navigationTitle("Wear History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQuickLog) {
                QuickLogSheet()
            }
        }
    }
}

// MARK: - Stats Cards Section

struct StatsCardsSection: View {
    let mostWornFragrance: UserFragrance?
    let totalWearsThisMonth: Int
    let varietyScore: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                // Most Worn Fragrance
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Most Worn", systemImage: "heart.fill")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        if let fragrance = mostWornFragrance {
                            Text(fragrance.fragrance.name)
                                .font(.appSubheadline())
                                .foregroundColor(.appNavy)
                                .lineLimit(1)

                            Text("\(fragrance.timesWorn) times")
                                .font(.appCaption())
                                .foregroundColor(.gray)
                        } else {
                            Text("No data yet")
                                .font(.appCaption())
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    if let fragrance = mostWornFragrance {
                        Text("\(fragrance.timesWorn)")
                            .font(.appStat())
                            .foregroundColor(.appGold)
                    }
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(10)

                HStack(spacing: 12) {
                    // This Month Wears
                    VStack(spacing: 8) {
                        Label("This Month", systemImage: "calendar")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        Text("\(totalWearsThisMonth)")
                            .font(.appStat())
                            .foregroundColor(.appGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.appCream)
                    .cornerRadius(10)

                    // Variety Score
                    VStack(spacing: 8) {
                        Label("Variety", systemImage: "sparkles")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                            .textCase(.uppercase)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(varietyScore)")
                                .font(.appStat())
                                .foregroundColor(.appGold)

                            Text("%")
                                .font(.appCaption())
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.appCream)
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Filter Section

struct FilterSection: View {
    @Binding var selectedFragrance: Fragrance?
    @Binding var selectedOccasion: Occasion?
    @Binding var selectedDateRange: DateRange

    let userFragrances: [UserFragrance]

    var body: some View {
        VStack(spacing: 12) {
            Text("Filters")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Date Range Filter
                    Menu {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Button(action: { selectedDateRange = range }) {
                                HStack {
                                    Text(range.label)
                                    if selectedDateRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            text: selectedDateRange.label,
                            isActive: true,
                            icon: "calendar"
                        )
                    }

                    // Occasion Filter
                    Menu {
                        Button("All Occasions") {
                            selectedOccasion = nil
                        }
                        Divider()
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            Button(action: { selectedOccasion = occasion }) {
                                HStack {
                                    Text(occasion.rawValue)
                                    if selectedOccasion == occasion {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            text: selectedOccasion?.rawValue ?? "Occasion",
                            isActive: selectedOccasion != nil,
                            icon: "tag.fill"
                        )
                    }

                    // Fragrance Filter
                    Menu {
                        Button("All Fragrances") {
                            selectedFragrance = nil
                        }
                        Divider()
                        ForEach(userFragrances, id: \.id) { userFrag in
                            Button(action: { selectedFragrance = userFrag.fragrance }) {
                                HStack {
                                    Text(userFrag.fragrance.name)
                                    if selectedFragrance?.id == userFrag.fragrance.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        FilterChip(
                            text: selectedFragrance?.name ?? "Fragrance",
                            isActive: selectedFragrance != nil,
                            icon: "bottle.2.fill"
                        )
                    }

                    // Clear filters button
                    if selectedFragrance != nil || selectedOccasion != nil || selectedDateRange != .allTime {
                        Button(action: {
                            selectedFragrance = nil
                            selectedOccasion = nil
                            selectedDateRange = .allTime
                        }) {
                            FilterChip(
                                text: "Clear",
                                isActive: false,
                                icon: "xmark.circle"
                            )
                        }
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let text: String
    let isActive: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.appCaption())
        .foregroundColor(isActive ? .white : .appNavy)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.appGold : Color.gray.opacity(0.15))
        .cornerRadius(6)
    }
}

// MARK: - Wear History Row Component

struct WearHistoryRow: View {
    let wearLog: WearLog

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: wearLog.dateWorn)
    }

    var daysSinceWorn: String {
        let days = wearLog.daysSinceWorn
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else {
            return "\(days)d ago"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

                        if wearLog.wasLayered {
                            Label("Layered", systemImage: "link")
                                .font(.appCaption())
                                .foregroundColor(.appGold)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(daysSinceWorn)
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

            // Additional details
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text(wearLog.timeOfDay.rawValue)
                        .font(.appCaption())
                }
                .foregroundColor(.gray)

                if let weather = wearLog.weather {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.sun.fill")
                            .font(.system(size: 10))
                        Text(weather)
                            .font(.appCaption())
                    }
                    .foregroundColor(.gray)
                }

                if let temp = wearLog.temperature {
                    HStack(spacing: 2) {
                        Image(systemName: "thermometer")
                            .font(.system(size: 10))
                        Text("\(Int(temp))°C")
                            .font(.appCaption())
                    }
                    .foregroundColor(.gray)
                }

                Spacer()
            }
        }
        .padding(12)
    }
}

// MARK: - Date Range Enum

enum DateRange: String, CaseIterable {
    case allTime = "All Time"
    case thisYear = "This Year"
    case thisMonth = "This Month"
    case thisWeek = "This Week"

    var label: String {
        self.rawValue
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    // Sample data
    let frag1 = Fragrance(
        name: "Aventus",
        brand: "Creed",
        concentration: .edp,
        fragranceFamily: .fresh
    )
    let frag2 = Fragrance(
        name: "Sauvage",
        brand: "Dior",
        concentration: .edt,
        fragranceFamily: .aromatic
    )

    let userFrag1 = UserFragrance(fragrance: frag1)
    userFrag1.timesWorn = 12
    userFrag1.lastWornDate = Date()

    let userFrag2 = UserFragrance(fragrance: frag2)
    userFrag2.timesWorn = 5
    userFrag2.lastWornDate = Date(timeIntervalSinceNow: -86400)

    let wearLog1 = WearLog(
        fragrance: frag1,
        userFragrance: userFrag1,
        dateWorn: Date(),
        timeOfDay: .morning,
        occasion: .office
    )

    let wearLog2 = WearLog(
        fragrance: frag2,
        userFragrance: userFrag2,
        dateWorn: Date(timeIntervalSinceNow: -86400),
        timeOfDay: .evening,
        occasion: .date
    )

    container.mainContext.insert(frag1)
    container.mainContext.insert(frag2)
    container.mainContext.insert(userFrag1)
    container.mainContext.insert(userFrag2)
    container.mainContext.insert(wearLog1)
    container.mainContext.insert(wearLog2)

    return WearHistoryView()
        .modelContainer(container)
}
