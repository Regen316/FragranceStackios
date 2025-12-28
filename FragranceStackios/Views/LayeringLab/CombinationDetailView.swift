//
//  CombinationDetailView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct CombinationDetailView: View {
    let combination: LayeringCombination
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with Compatibility Score
                    VStack(spacing: 16) {
                        Text(combination.displayName)
                            .font(.appTitle())
                            .foregroundColor(.appNavy)
                            .multilineTextAlignment(.center)

                        // Large Compatibility Circle
                        VStack(spacing: 4) {
                            Text("\(combination.compatibility)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)

                            Text("Compatibility")
                                .font(.appCaption())
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(width: 100, height: 100)
                        .background(Circle().fill(compatibilityColor(compatibility: combination.compatibility)))
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                    // Description
                    if let description = combination.comboDescription {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About This Pairing")
                                .font(.appHeadline())
                                .foregroundColor(.appNavy)

                            Text(description)
                                .font(.appBody())
                                .foregroundColor(.gray)
                                .lineSpacing(1.4)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Side-by-Side Fragrance Cards
                    VStack(spacing: 16) {
                        Text("Fragrances in This Combo")
                            .font(.appHeadline())
                            .foregroundColor(.appNavy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            FragranceCardView(
                                fragrance: combination.fragrance1,
                                ratio: combination.ratioFragrance1,
                                position: "First"
                            )

                            FragranceCardView(
                                fragrance: combination.fragrance2,
                                ratio: combination.ratioFragrance2,
                                position: "Second"
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    // Application Ratio
                    VStack(spacing: 12) {
                        Text("Application Ratio")
                            .font(.appHeadline())
                            .foregroundColor(.appNavy)

                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                // Ratio visual
                                ForEach(0..<combination.ratioFragrance1, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.appGold)
                                        .frame(height: 8)
                                }

                                Spacer()

                                ForEach(0..<combination.ratioFragrance2, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.6))
                                        .frame(height: 8)
                                }
                            }
                            .frame(height: 8)

                            // Ratio description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apply \(combination.ratioFragrance1) sprays of \(combination.fragrance1.name), then \(combination.ratioFragrance2) spray\(combination.ratioFragrance2 > 1 ? "s" : "") of \(combination.fragrance2.name)")
                                    .font(.appBody())
                                    .foregroundColor(.appNavy)

                                Text("Application Order: \(combination.applicationOrder.rawValue)")
                                    .font(.appCaption())
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(Color.appCream)
                        .cornerRadius(8)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Best Seasons
                    if !combination.bestSeasons.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Best Seasons")
                                .font(.appHeadline())
                                .foregroundColor(.appNavy)

                            HStack(spacing: 8) {
                                ForEach(combination.bestSeasons, id: \.self) { season in
                                    SeasonBadge(season: season)
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Best Occasions
                    if !combination.bestOccasions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Best Occasions")
                                .font(.appHeadline())
                                .foregroundColor(.appNavy)

                            HStack(spacing: 8) {
                                ForEach(combination.bestOccasions, id: \.self) { occasion in
                                    OccasionBadge(occasion: occasion)
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }

                    // Log This Combo Button
                    Button(action: { showLogSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log This Combo")
                        }
                        .font(.appSubheadline())
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .padding(.vertical, 20)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLogSheet) {
                LogComboSheet(combination: combination, isPresented: $showLogSheet)
            }
        }
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

// MARK: - Fragrance Card View

struct FragranceCardView: View {
    let fragrance: Fragrance
    let ratio: Int
    let position: String

    var body: some View {
        VStack(spacing: 12) {
            // Placeholder for fragrance image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appCream)
                .frame(height: 100)
                .overlay(
                    Image(systemName: "spray.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.appGold)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(fragrance.name)
                    .font(.appSubheadline())
                    .foregroundColor(.appNavy)
                    .lineLimit(2)

                Text(fragrance.brand)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(fragrance.concentration.rawValue)
                        .font(.appCaption())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.appNavy)
                        .cornerRadius(4)

                    Text(fragrance.gender.rawValue)
                        .font(.appCaption())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.6))
                        .cornerRadius(4)
                }

                // Ratio Circle
                VStack(spacing: 2) {
                    Text("\(ratio)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("spray\(ratio > 1 ? "s" : "")")
                        .font(.appCaption())
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.appGold)
                .cornerRadius(6)
            }
            .padding(12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Season Badge

struct SeasonBadge: View {
    let season: Season

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: seasonIcon(season))
                .font(.system(size: 10))

            Text(season.rawValue)
                .font(.appCaption())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(seasonColor(season))
        .cornerRadius(8)
    }

    private func seasonIcon(_ season: Season) -> String {
        switch season {
        case .spring:
            return "leaf.fill"
        case .summer:
            return "sun.max.fill"
        case .fall:
            return "wind"
        case .winter:
            return "snowflake"
        }
    }

    private func seasonColor(_ season: Season) -> Color {
        switch season {
        case .spring:
            return Color.green.opacity(0.7)
        case .summer:
            return Color.orange.opacity(0.7)
        case .fall:
            return Color.orange.opacity(0.5)
        case .winter:
            return Color.blue.opacity(0.7)
        }
    }
}

// MARK: - Occasion Badge

struct OccasionBadge: View {
    let occasion: Occasion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: occasionIcon(occasion))
                .font(.system(size: 10))

            Text(occasion.rawValue)
                .font(.appCaption())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(occasionColor(occasion))
        .cornerRadius(8)
    }

    private func occasionIcon(_ occasion: Occasion) -> String {
        switch occasion {
        case .office:
            return "briefcase.fill"
        case .date:
            return "heart.fill"
        case .casual:
            return "person.fill"
        case .formal:
            return "sparkles"
        case .club:
            return "music.note"
        }
    }

    private func occasionColor(_ occasion: Occasion) -> Color {
        switch occasion {
        case .office:
            return Color.appNavy
        case .date:
            return Color.pink.opacity(0.7)
        case .casual:
            return Color.blue.opacity(0.6)
        case .formal:
            return Color.purple.opacity(0.7)
        case .club:
            return Color.red.opacity(0.6)
        }
    }
}

// MARK: - Log Combo Sheet

struct LogComboSheet: View {
    let combination: LayeringCombination
    @Binding var isPresented: Bool
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Combo Being Logged")
                        .font(.appSubheadline())
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {
                        Text(combination.fragrance1.name)
                            .font(.appBody())
                            .foregroundColor(.appNavy)

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appGold)

                        Text(combination.fragrance2.name)
                            .font(.appBody())
                            .foregroundColor(.appNavy)
                    }
                }
                .padding(16)
                .background(Color.appCream)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Notes (Optional)")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.appCream)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Log Combo") {
                        // Placeholder action
                        isPresented = false
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(16)
            .navigationTitle("Log Combination")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: Fragrance.self, LayeringCombination.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    // Create sample fragrances
    let frag1 = Fragrance(name: "Blue Cologne", brand: "Bleu de Chanel", fragranceFamily: .fresh, gender: .masculine)
    let frag2 = Fragrance(name: "Jasmine Perfume", brand: "Chanel No. 5", fragranceFamily: .floral, gender: .feminine)

    // Create sample combination
    let combo = LayeringCombination(
        name: "Fresh & Floral Dream",
        comboDescription: "A beautiful fresh and floral pairing that works wonderfully in spring and summer. The crisp, clean notes of the first fragrance blend seamlessly with the romantic floral heart, creating a sophisticated and elegant scent that's perfect for romantic occasions.",
        compatibility: 9,
        ratioFragrance1: 2,
        ratioFragrance2: 1,
        applicationOrder: .frag1First,
        bestSeasons: [.spring, .summer],
        bestOccasions: [.date, .casual],
        fragrance1: frag1,
        fragrance2: frag2
    )

    container.mainContext.insert(frag1)
    container.mainContext.insert(frag2)
    container.mainContext.insert(combo)

    return CombinationDetailView(combination: combo)
        .modelContainer(container)
}
