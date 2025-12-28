//
//  LayeringCalculatorView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct LayeringCalculatorView: View {
    @Query var allFragrances: [Fragrance]
    @State private var fragrance1: Fragrance?
    @State private var fragrance2: Fragrance?
    @State private var calculatedScore: Int?
    @State private var suggestedRatio1: Int = 2
    @State private var suggestedRatio2: Int = 1
    @State private var showSaveSheet = false
    @State private var comboName: String = ""
    @State private var comboDescription: String = ""
    @State private var selectedSeasons: [Season] = []
    @State private var selectedOccasions: [Occasion] = []

    var canCalculate: Bool {
        fragrance1 != nil && fragrance2 != nil && fragrance1?.id != fragrance2?.id
    }

    var body: some View {
        NavigationStack {
            Form {
                // Fragrance Selections
                Section(header: Text("Select Fragrances").font(.appSubheadline())) {
                    Picker("Fragrance 1", selection: $fragrance1) {
                        Text("Choose a fragrance").tag(nil as Fragrance?)

                        ForEach(allFragrances) { frag in
                            Text(frag.displayName)
                                .tag(Optional(frag))
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Picker("Fragrance 2", selection: $fragrance2) {
                        Text("Choose a fragrance").tag(nil as Fragrance?)

                        ForEach(allFragrances) { frag in
                            Text(frag.displayName)
                                .tag(Optional(frag))
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if fragrance1?.id == fragrance2?.id {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)

                            Text("Please select two different fragrances")
                                .font(.appCaption())
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Calculate Button
                Section {
                    Button(action: calculateCompatibility) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Calculate Compatibility")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!canCalculate)
                    .buttonStyle(PrimaryButtonStyle())
                }

                // Results Section
                if let score = calculatedScore {
                    Section(header: Text("Results").font(.appSubheadline())) {
                        VStack(spacing: 16) {
                            // Compatibility Score
                            VStack(spacing: 4) {
                                HStack {
                                    Text("Compatibility Score")
                                        .font(.appBody())
                                        .foregroundColor(.gray)

                                    Spacer()

                                    VStack(spacing: 2) {
                                        Text("\(score)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("/ 10")
                                            .font(.appCaption())
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(compatibilityColor(score)))
                                }

                                // Description
                                Text(compatibilityDescription(score))
                                    .font(.appCaption())
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                            .padding(12)
                            .background(Color.appCream)
                            .cornerRadius(8)

                            // Suggested Ratio
                            VStack(spacing: 12) {
                                Text("Suggested Ratio")
                                    .font(.appSubheadline())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.appNavy)

                                HStack(spacing: 12) {
                                    VStack(alignment: .center, spacing: 8) {
                                        Text("\(suggestedRatio1)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)

                                        Stepper(
                                            "",
                                            value: $suggestedRatio1,
                                            in: 1...5
                                        )
                                        .labelsHidden()

                                        if let frag = fragrance1 {
                                            Text(frag.name)
                                                .font(.appCaption())
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.appGold.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.appGold, lineWidth: 1)
                                    )

                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 28))

                                    VStack(alignment: .center, spacing: 8) {
                                        Text("\(suggestedRatio2)")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)

                                        Stepper(
                                            "",
                                            value: $suggestedRatio2,
                                            in: 1...5
                                        )
                                        .labelsHidden()

                                        if let frag = fragrance2 {
                                            Text(frag.name)
                                                .font(.appCaption())
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(12)
                            .background(Color.appCream)
                            .cornerRadius(8)
                        }
                    }

                    // Save Section
                    Section {
                        Button(action: { showSaveSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Save as Combination")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .navigationTitle("Layering Calculator")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .background(Color.appBackground)
            .sheet(isPresented: $showSaveSheet) {
                SaveComboSheet(
                    fragrance1: fragrance1,
                    fragrance2: fragrance2,
                    score: calculatedScore ?? 5,
                    ratio1: suggestedRatio1,
                    ratio2: suggestedRatio2,
                    isPresented: $showSaveSheet
                )
            }
        }
    }

    private func calculateCompatibility() {
        // Simulate compatibility calculation based on fragrance characteristics
        guard let frag1 = fragrance1, let frag2 = fragrance2 else { return }

        // Simple algorithm: check if families complement each other
        let score = calculateScore(frag1: frag1, frag2: frag2)
        calculatedScore = score

        // Suggest ratio based on concentration
        suggestedRatio1 = frag1.concentration == .parfum ? 1 : 2
        suggestedRatio2 = frag2.concentration == .parfum ? 1 : 2
    }

    private func calculateScore(frag1: Fragrance, frag2: Fragrance) -> Int {
        var score = 5 // Base score

        // Same family bonus
        if frag1.fragranceFamily == frag2.fragranceFamily {
            score += 1
        }

        // Complementary families bonus
        if isComplementaryFamily(frag1.fragranceFamily, frag2.fragranceFamily) {
            score += 2
        }

        // Same concentration bonus
        if frag1.concentration == frag2.concentration {
            score += 1
        }

        // Add some randomness for variety
        score += Int.random(in: -1...2)

        return min(max(score, 1), 10)
    }

    private func isComplementaryFamily(_ family1: FragranceFamily, _ family2: FragranceFamily) -> Bool {
        let pairs: Set<Set<FragranceFamily>> = [
            [.citrus, .floral],
            [.woody, .oriental],
            [.fresh, .aromatic],
            [.floral, .oriental],
            [.citrus, .woody],
        ]

        return pairs.contains(Set([family1, family2]))
    }

    private func compatibilityColor(_ score: Int) -> Color {
        switch score {
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

    private func compatibilityDescription(_ score: Int) -> String {
        switch score {
        case 9...10:
            return "Excellent pairing! These fragrances complement each other beautifully."
        case 7...8:
            return "Great compatibility! This is a well-matched combination."
        case 5...6:
            return "Good pairing with interesting contrasts."
        case 3...4:
            return "Interesting combination that might work for adventurous wearers."
        default:
            return "Challenging pairing. Experiment with ratios to find your preference."
        }
    }
}

// MARK: - Save Combo Sheet

struct SaveComboSheet: View {
    let fragrance1: Fragrance?
    let fragrance2: Fragrance?
    let score: Int
    let ratio1: Int
    let ratio2: Int
    @Binding var isPresented: Bool
    @State private var comboName: String = ""
    @State private var comboDescription: String = ""
    @State private var selectedSeasons: [Season] = []
    @State private var selectedOccasions: [Occasion] = []
    @State private var applicationOrder: ApplicationOrder = .simultaneous

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Combination Details").font(.appSubheadline())) {
                    TextField("Combination Name (Optional)", text: $comboName)
                        .font(.appBody())

                    TextEditor(text: $comboDescription)
                        .frame(minHeight: 80)
                        .font(.appBody())
                }

                Section(header: Text("Best For").font(.appSubheadline())) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seasons")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)

                        HStack(spacing: 8) {
                            ForEach(Season.allCases, id: \.self) { season in
                                Button(action: { toggleSeason(season) }) {
                                    Text(season.rawValue)
                                        .font(.appCaption())
                                        .foregroundColor(selectedSeasons.contains(season) ? .white : .appNavy)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedSeasons.contains(season) ? Color.appGold : Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Occasions")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)

                        HStack(spacing: 8) {
                            ForEach(Occasion.allCases, id: \.self) { occasion in
                                Button(action: { toggleOccasion(occasion) }) {
                                    Text(occasion.rawValue)
                                        .font(.appCaption())
                                        .foregroundColor(selectedOccasions.contains(occasion) ? .white : .appNavy)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedOccasions.contains(occasion) ? Color.appGold : Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    Picker("Application Order", selection: $applicationOrder) {
                        ForEach(ApplicationOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Save Combination") {
                            // Placeholder action to save the combination
                            // In a real app, this would persist to SwiftData
                            isPresented = false
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .navigationTitle("Save Combination")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func toggleSeason(_ season: Season) {
        if selectedSeasons.contains(season) {
            selectedSeasons.removeAll { $0 == season }
        } else {
            selectedSeasons.append(season)
        }
    }

    private func toggleOccasion(_ occasion: Occasion) {
        if selectedOccasions.contains(occasion) {
            selectedOccasions.removeAll { $0 == occasion }
        } else {
            selectedOccasions.append(occasion)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: Fragrance.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    // Create sample fragrances
    let fragrances = [
        Fragrance(name: "Blue Cologne", brand: "Bleu de Chanel", concentration: .edp, fragranceFamily: .fresh, gender: .masculine),
        Fragrance(name: "Jasmine Perfume", brand: "Chanel No. 5", concentration: .edp, fragranceFamily: .floral, gender: .feminine),
        Fragrance(name: "Oud Noir", brand: "Tom Ford", concentration: .edp, fragranceFamily: .oriental, gender: .unisex),
        Fragrance(name: "Aqua Fresh", brand: "Acqua di Parma", concentration: .edt, fragranceFamily: .citrus, gender: .masculine),
        Fragrance(name: "Rose Garden", brand: "Guerlain", concentration: .edp, fragranceFamily: .floral, gender: .feminine),
    ]

    fragrances.forEach { container.mainContext.insert($0) }

    return LayeringCalculatorView()
        .modelContainer(container)
}
