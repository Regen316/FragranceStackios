//
//  LayeringLabView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct LayeringLabView: View {
    @Query var combinations: [LayeringCombination]
    @State private var selectedSeason: Season? = nil
    @State private var sortBy: SortOption = .compatibilityHighToLow
    @State private var selectedCombination: LayeringCombination?

    enum SortOption: String, CaseIterable {
        case compatibilityHighToLow = "Compatibility (High to Low)"
        case compatibilityLowToHigh = "Compatibility (Low to High)"
        case name = "Name"
    }

    var filteredAndSortedCombinations: [LayeringCombination] {
        var filtered = combinations

        // Filter by season if selected
        if let season = selectedSeason {
            filtered = filtered.filter { $0.bestSeasons.contains(season) }
        }

        // Sort
        switch sortBy {
        case .compatibilityHighToLow:
            filtered.sort { $0.compatibility > $1.compatibility }
        case .compatibilityLowToHigh:
            filtered.sort { $0.compatibility < $1.compatibility }
        case .name:
            filtered.sort { $0.displayName < $1.displayName }
        }

        return filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter and Sort Controls
                VStack(spacing: 12) {
                    // Season Filter Chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filter by Season")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "All Seasons" chip
                                Button(action: { selectedSeason = nil }) {
                                    Text("All Seasons")
                                        .font(.appCaption())
                                        .foregroundColor(selectedSeason == nil ? .white : .appNavy)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedSeason == nil ? Color.appGold : Color.gray.opacity(0.2))
                                        .cornerRadius(16)
                                }

                                // Season chips
                                ForEach(Season.allCases, id: \.self) { season in
                                    Button(action: { selectedSeason = season }) {
                                        Text(season.rawValue)
                                            .font(.appCaption())
                                            .foregroundColor(selectedSeason == season ? .white : .appNavy)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedSeason == season ? Color.appGold : Color.gray.opacity(0.2))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)

                    // Sort Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sort by")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)
                            .padding(.horizontal, 16)

                        Picker("Sort", selection: $sortBy) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                // Combinations List
                if filteredAndSortedCombinations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))

                        Text("No Combinations Found")
                            .font(.appHeadline())
                            .foregroundColor(.appNavy)

                        Text("Try adjusting your filters")
                            .font(.appBody())
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
                } else {
                    List {
                        ForEach(filteredAndSortedCombinations) { combo in
                            NavigationLink(destination: CombinationDetailView(combination: combo)) {
                                CombinationListRow(combination: combo)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.appBackground)
                }
            }
            .navigationTitle("Layering Lab")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .background(Color.appBackground)
            .onAppear {
                // Seed data if no combinations exist
                if combinations.isEmpty {
                    seedCombinations()
                }
            }
        }
    }

    private func seedCombinations() {
        // This would normally interact with the model container
        // For now, this is a placeholder for seeding logic
    }
}

// MARK: - Combination List Row

struct CombinationListRow: View {
    let combination: LayeringCombination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Compatibility Score
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(combination.displayName)
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)
                        .lineLimit(2)
                }

                Spacer()

                // Compatibility Score Circle
                VStack(spacing: 2) {
                    Text("\(combination.compatibility)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("/ 10")
                        .font(.appCaption())
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 50, height: 50)
                .background(Circle().fill(compatibilityColor(compatibility: combination.compatibility)))
            }

            // Fragrance Names
            HStack(spacing: 8) {
                Text(combination.fragrance1.displayName)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.appGold)

                Text(combination.fragrance2.displayName)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            // Ratio Badge
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.appGold)

                Text("Ratio: \(combination.ratioDescription)")
                    .font(.appCaption())
                    .foregroundColor(.appNavy)
            }
        }
        .padding(12)
    }

    private func compatibilityColor(compatibility: Int) -> Color {
        switch compatibility {
        case 9...10:
            return Color.green.opacity(0.8)
        case 7...8:
            return Color.appGold
        case 5...6:
            return Color.orange.opacity(0.8)
        default:
            return Color.red.opacity(0.6)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: Fragrance.self, LayeringCombination.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    // Create sample fragrances
    let frag1 = Fragrance(name: "Blue Cologne", brand: "Bleu de Chanel", fragranceFamily: .fresh, gender: .masculine)
    let frag2 = Fragrance(name: "Jasmine Perfume", brand: "Chanel No. 5", fragranceFamily: .floral, gender: .feminine)
    let frag3 = Fragrance(name: "Oud Noir", brand: "Tom Ford", fragranceFamily: .oriental, gender: .unisex)
    let frag4 = Fragrance(name: "Aqua Fresh", brand: "Acqua di Parma", fragranceFamily: .citrus, gender: .masculine)

    // Create sample combinations
    let combo1 = LayeringCombination(
        name: "Fresh & Floral Dream",
        comboDescription: "A beautiful fresh and floral pairing",
        compatibility: 9,
        ratioFragrance1: 2,
        ratioFragrance2: 1,
        bestSeasons: [.spring, .summer],
        bestOccasions: [.date, .casual],
        fragrance1: frag1,
        fragrance2: frag2
    )

    let combo2 = LayeringCombination(
        name: "Oriental Mystery",
        comboDescription: "Deep and alluring blend",
        compatibility: 8,
        ratioFragrance1: 1,
        ratioFragrance2: 2,
        bestSeasons: [.fall, .winter],
        bestOccasions: [.formal, .date],
        fragrance1: frag3,
        fragrance2: frag4
    )

    container.mainContext.insert(frag1)
    container.mainContext.insert(frag2)
    container.mainContext.insert(frag3)
    container.mainContext.insert(frag4)
    container.mainContext.insert(combo1)
    container.mainContext.insert(combo2)

    return LayeringLabView()
        .modelContainer(container)
}
