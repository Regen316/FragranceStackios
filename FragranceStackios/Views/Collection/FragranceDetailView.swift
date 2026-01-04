//
//  FragranceDetailView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct FragranceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let fragrance: Fragrance

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero image placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appCream)

                        VStack {
                            Image(systemName: "bottle.2")
                                .font(.system(size: 80))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .frame(height: 280)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        // Brand + Name heading
                        Text(fragrance.brand)
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        Text(fragrance.name)
                            .font(.appTitle())
                            .foregroundColor(.appNavy)

                        HStack(spacing: 12) {
                            Text(fragrance.concentration.rawValue)
                                .font(.appBody())
                                .foregroundColor(.appNavy)

                            Text(fragrance.fragranceFamily.rawValue)
                                .font(.appBody())
                                .foregroundColor(.appNavy)

                            Text(fragrance.gender.rawValue)
                                .font(.appBody())
                                .foregroundColor(.appNavy)
                        }
                    }
                    .padding(.horizontal, 16)

                    Divider()
                        .padding(.horizontal, 16)

                    // Note pyramid
                    notePyramidSection

                    // Performance bars
                    if let metrics = fragrance.metrics {
                        performanceSection(metrics)
                    }

                    // Season/occasion scores
                    if let metrics = fragrance.metrics {
                        seasonOccasionSection(metrics)
                    }

                    // Personal notes section
                    if let userFrag = fragrance.userFragrances.first {
                        personalNotesSection(userFrag)
                    }

                    // Action buttons
                    actionButtonsSection
                        .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.visible)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .topBarLeading
                    #else
                    return .navigation
                    #endif
                }()) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.appGold)
                    }
                }
            }
        }
    }

    // MARK: - Note Pyramid Section

    @ViewBuilder
    private var notePyramidSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fragrance Notes")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .padding(.horizontal, 16)

            HStack(spacing: 16) {
                // Top notes
                noteColumn(
                    title: "Top",
                    notes: fragrance.topNotes,
                    color: Color.appGold.opacity(0.3)
                )

                // Heart notes
                noteColumn(
                    title: "Heart",
                    notes: fragrance.heartNotes,
                    color: Color.appGold.opacity(0.5)
                )

                // Base notes
                noteColumn(
                    title: "Base",
                    notes: fragrance.baseNotes,
                    color: Color.appGold.opacity(0.8)
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func noteColumn(title: String, notes: [Note], color: Color) -> some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.appCaption())
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)

            VStack(alignment: .center, spacing: 6) {
                ForEach(notes, id: \.id) { note in
                    Text(note.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(color)
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity)
                }

                if notes.isEmpty {
                    Text("–")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                }
            }
        }
    }

    // MARK: - Performance Section

    @ViewBuilder
    private func performanceSection(_ metrics: FragranceMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                performanceBar(
                    label: "Longevity",
                    value: Int(metrics.longevityHours),
                    maxValue: 24
                )

                performanceBar(
                    label: "Projection",
                    value: metrics.projection,
                    maxValue: 10
                )

                performanceBar(
                    label: "Sillage",
                    value: metrics.sillage,
                    maxValue: 10
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func performanceBar(
        label: String,
        value: Int,
        maxValue: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.appCaption())
                    .foregroundColor(.gray)

                Spacer()

                Text("\(value)/\(maxValue)")
                    .font(.appCaption())
                    .foregroundColor(.appNavy)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appGold)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Season/Occasion Section

    @ViewBuilder
    private func seasonOccasionSection(_ metrics: FragranceMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best For")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                // Seasons
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seasons")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    HStack(spacing: 8) {
                        seasonBadge("Spring", score: metrics.seasonSpring)
                        seasonBadge("Summer", score: metrics.seasonSummer)
                        seasonBadge("Fall", score: metrics.seasonFall)
                        seasonBadge("Winter", score: metrics.seasonWinter)
                    }
                    .padding(.horizontal, 16)
                }

                // Occasions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Occasions")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            occasionBadge("Office", score: metrics.occasionOffice)
                            occasionBadge("Date", score: metrics.occasionDate)
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            occasionBadge("Casual", score: metrics.occasionCasual)
                            occasionBadge("Formal", score: metrics.occasionFormal)
                            occasionBadge("Club", score: metrics.occasionClub)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func seasonBadge(_ label: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)

            Text("\(score)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(score >= 7 ? Color.appGold : Color.gray.opacity(0.3))
        .cornerRadius(8)
    }

    private func occasionBadge(_ label: String, score: Int) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)

            Text("\(score)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(score >= 7 ? Color.appGold : Color.gray.opacity(0.3))
        .cornerRadius(8)
    }

    // MARK: - Personal Notes Section

    @ViewBuilder
    private func personalNotesSection(_ userFrag: UserFragrance) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Notes")
                .font(.appHeadline())
                .foregroundColor(.appNavy)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                if let rating = userFrag.personalRating {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Rating")
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        StarRatingView(rating: rating)
                    }
                }

                if let notes = userFrag.personalNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        Text(notes)
                            .font(.appBody())
                            .foregroundColor(.appNavy)
                            .lineLimit(4)
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Times Worn")
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        Text("\(userFrag.timesWorn)")
                            .font(.appStat())
                            .foregroundColor(.appGold)
                    }

                    Spacer()

                    if let lastWorn = userFrag.lastWornDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Worn")
                                .font(.appCaption())
                                .foregroundColor(.gray)

                            Text(lastWornDateFormatted(lastWorn))
                                .font(.appSubheadline())
                                .foregroundColor(.appNavy)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.appCream)
            .cornerRadius(8)
            .padding(.horizontal, 16)
        }
    }

    private func lastWornDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                HStack {
                    Image(systemName: "clock.badge.checkmark")
                    Text("Log Wear")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: {}) {
                HStack {
                    Image(systemName: "link")
                    Text("Find Layers")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    let fragrance = Fragrance(
        name: "Aventus",
        brand: "Creed",
        concentration: .edp,
        fragranceFamily: .fresh
    )

    let topNote1 = Note(name: "Pineapple", category: .fruity)
    let topNote2 = Note(name: "Lemon", category: .citrus)
    let heartNote1 = Note(name: "Ambroxan", category: .resinous)
    let heartNote2 = Note(name: "Jasmine", category: .floral)
    let baseNote1 = Note(name: "Oakmoss", category: .woody)
    let baseNote2 = Note(name: "Guaiacwood", category: .woody)

    fragrance.notes = [
        FragranceNote(fragrance: fragrance, note: topNote1, type: .top, intensity: 8),
        FragranceNote(fragrance: fragrance, note: topNote2, type: .top, intensity: 7),
        FragranceNote(fragrance: fragrance, note: heartNote1, type: .heart, intensity: 9),
        FragranceNote(fragrance: fragrance, note: heartNote2, type: .heart, intensity: 7),
        FragranceNote(fragrance: fragrance, note: baseNote1, type: .base, intensity: 8),
        FragranceNote(fragrance: fragrance, note: baseNote2, type: .base, intensity: 8)
    ]

    let metrics = FragranceMetrics(
        longevityHours: 8.0,
        projection: 8,
        sillage: 8,
        seasonSpring: 6,
        seasonSummer: 9,
        seasonFall: 7,
        seasonWinter: 4,
        occasionOffice: 9,
        occasionDate: 8,
        occasionCasual: 7,
        occasionFormal: 5,
        occasionClub: 6
    )
    fragrance.metrics = metrics

    let userFrag = UserFragrance(
        fragrance: fragrance,
        purchaseDate: Date(),
        personalRating: 5,
        isSignature: true
    )
    userFrag.personalNotes = "Incredible projection and longevity. Perfect for spring and summer days."
    userFrag.timesWorn = 12
    userFrag.lastWornDate = Date().addingTimeInterval(-86400 * 3)
    fragrance.userFragrances = [userFrag]

    container.mainContext.insert(fragrance)
    container.mainContext.insert(topNote1)
    container.mainContext.insert(topNote2)
    container.mainContext.insert(heartNote1)
    container.mainContext.insert(heartNote2)
    container.mainContext.insert(baseNote1)
    container.mainContext.insert(baseNote2)

    return FragranceDetailView(fragrance: fragrance)
        .modelContainer(container)
}
