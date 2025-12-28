//
//  RecommendationResultsView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct RecommendationResultsView: View {
    // MARK: - Properties

    @Query(sort: \Fragrance.name) private var allFragrances: [Fragrance]
    @Environment(\.modelContext) private var context
    @State private var showMoreAlternatives = false

    private let maxRecommendations = 5
    private let topConfidenceScore = 85

    // MARK: - Computed Properties

    var recommendations: [Fragrance] {
        Array(allFragrances.prefix(maxRecommendations))
    }

    var todaysPick: Fragrance? {
        recommendations.first
    }

    var alternatives: [Fragrance] {
        Array(recommendations.dropFirst())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if let pick = todaysPick {
                        // Today's Pick Hero Card
                        todaysPickHeroCard(pick)

                        // Why This Pick Explanation
                        whyThisPickView(pick)

                        // Alternative Suggestions
                        alternativesSectionView

                        // Accept & Log Button
                        acceptLogButtonView

                        // Show More Button
                        showMoreButtonView
                    } else {
                        // Empty State
                        EmptyStateView(
                            icon: "sparkles",
                            title: "No Fragrances Available",
                            message: "Please add fragrances to your collection to get recommendations."
                        )
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.appBackground)
            .navigationTitle("Today's Pick")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Today's Pick Hero Card

    @ViewBuilder
    private func todaysPickHeroCard(_ fragrance: Fragrance) -> some View {
        VStack(spacing: 16) {
            // Fragrance Image Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.appGold.opacity(0.1), Color.appGold.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.appGold)

                    Text("Fragrance Image")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 250)

            // Fragrance Details
            VStack(alignment: .leading, spacing: 12) {
                Text(fragrance.brand)
                    .font(.appCaption())
                    .foregroundColor(.gray)

                Text(fragrance.name)
                    .font(.appTitle())
                    .foregroundColor(.appNavy)
                    .lineLimit(2)

                // Confidence Score Badge
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appGold)

                    Text("\(topConfidenceScore)% Match")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    Spacer()
                }
                .padding(12)
                .background(Color.appGold.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Why This Pick View

    @ViewBuilder
    private func whyThisPickView(_ fragrance: Fragrance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why this pick?")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.appGold)

                Text("Perfect for casual occasions in pleasant weather. The fresh notes complement sunny days.")
                    .font(.appBody())
                    .foregroundColor(.appNavy)
                    .lineLimit(3)

                Spacer()
            }
            .padding(16)
            .background(Color.appCream)
            .cornerRadius(12)
        }
    }

    // MARK: - Alternatives Section View

    @ViewBuilder
    private var alternativesSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alternative Suggestions")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            if alternatives.isEmpty {
                Text("No alternatives available")
                    .font(.appBody())
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(alternatives, id: \.id) { fragrance in
                        alternativeFragranceRow(fragrance)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func alternativeFragranceRow(_ fragrance: Fragrance) -> some View {
        HStack(spacing: 12) {
            // Fragrance Image Placeholder
            ZStack {
                Circle()
                    .fill(Color.appGold.opacity(0.1))

                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appGold)
            }
            .frame(width: 60, height: 60)

            // Fragrance Info
            VStack(alignment: .leading, spacing: 4) {
                Text(fragrance.brand)
                    .font(.appCaption())
                    .foregroundColor(.gray)

                Text(fragrance.name)
                    .font(.appSubheadline())
                    .foregroundColor(.appNavy)
                    .lineLimit(1)

                Text(fragrance.fragranceFamily.rawValue)
                    .font(.appCaption())
                    .foregroundColor(.gray.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appGold)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Accept & Log Button View

    @ViewBuilder
    private var acceptLogButtonView: some View {
        Button(action: acceptRecommendation) {
            Text("Accept & Log")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    // MARK: - Show More Button View

    @ViewBuilder
    private var showMoreButtonView: some View {
        Button(action: { showMoreAlternatives = true }) {
            Text("Show More")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    // MARK: - Actions

    private func acceptRecommendation() {
        // Placeholder action for now
        // In the future, this will:
        // 1. Create a WearLog entry
        // 2. Track the recommendation
        // 3. Navigate to confirmation screen
    }
}

// MARK: - Preview

#Preview("With Recommendations") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    // Add sample fragrances
    let fragrance1 = Fragrance(
        name: "Aventus",
        brand: "Creed",
        concentration: .edp,
        fragranceFamily: .citrus,
        gender: .masculine
    )
    let fragrance2 = Fragrance(
        name: "Bleu de Chanel",
        brand: "Chanel",
        concentration: .edp,
        fragranceFamily: .woody,
        gender: .masculine
    )
    let fragrance3 = Fragrance(
        name: "Sauvage",
        brand: "Dior",
        concentration: .edp,
        fragranceFamily: .aromatic,
        gender: .masculine
    )
    let fragrance4 = Fragrance(
        name: "Acqua di Gioia",
        brand: "Giorgio Armani",
        concentration: .edt,
        fragranceFamily: .fresh,
        gender: .unisex
    )
    let fragrance5 = Fragrance(
        name: "La Vie Est Belle",
        brand: "Lancôme",
        concentration: .edp,
        fragranceFamily: .gourmand,
        gender: .feminine
    )

    container.mainContext.insert(fragrance1)
    container.mainContext.insert(fragrance2)
    container.mainContext.insert(fragrance3)
    container.mainContext.insert(fragrance4)
    container.mainContext.insert(fragrance5)

    return RecommendationResultsView()
        .modelContainer(container)
}

#Preview("Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)
    return RecommendationResultsView()
        .modelContainer(container)
}
