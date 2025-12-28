//
//  ContextSelectionView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct ContextSelectionView: View {
    // MARK: - Properties

    @State private var selectedOccasion: Occasion = .casual
    @State private var selectedTimeOfDay: TimeOfDay = .afternoon
    @State private var selectedVibes: Set<String> = []
    @Environment(\.modelContext) private var context

    private let occasionOptions: [Occasion] = [.office, .date, .casual, .formal, .club]
    private let vibeOptions: [String] = ["Sophisticated", "Energetic", "Calm", "Playful", "Sensual"]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerView

                    // Occasion Picker
                    occasionPickerView

                    // Time of Day Segmented Control
                    timeOfDayView

                    // Weather Display
                    weatherDisplayView

                    // Vibe/Mood Tag Selector
                    vibeTagsView

                    Spacer(minLength: 24)

                    // Get Recommendations Button
                    NavigationLink(destination: RecommendationResultsView()) {
                        Button(action: {}) {
                            Text("Get Recommendations")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.appBackground)
            .navigationTitle("Find Your Fragrance")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Let's find your perfect scent")
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            Text("Tell us about your mood, the occasion, and the time of day")
                .font(.appBody())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Occasion Picker View

    @ViewBuilder
    private var occasionPickerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Occasion")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            Picker("Occasion", selection: $selectedOccasion) {
                ForEach(occasionOptions, id: \.self) { occasion in
                    Text(occasion.rawValue).tag(occasion)
                }
            }
            .pickerStyle(.segmented)
            .accentColor(.appGold)
        }
    }

    // MARK: - Time of Day View

    @ViewBuilder
    private var timeOfDayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time of Day")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            Picker("Time of Day", selection: $selectedTimeOfDay) {
                ForEach(TimeOfDay.allCases, id: \.self) { time in
                    Text(time.rawValue).tag(time)
                }
            }
            .pickerStyle(.segmented)
            .accentColor(.appGold)
        }
    }

    // MARK: - Weather Display View

    @ViewBuilder
    private var weatherDisplayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sunny, 72°F")
                        .font(.appBody())
                        .foregroundColor(.appNavy)

                    Text("Perfect for fresh and citrus scents")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Vibe/Mood Tags View

    @ViewBuilder
    private var vibeTagsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vibe (Optional)")
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(vibeOptions, id: \.self) { vibe in
                    Button(action: { toggleVibe(vibe) }) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedVibes.contains(vibe) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(selectedVibes.contains(vibe) ? .appGold : .gray.opacity(0.5))

                            Text(vibe)
                                .font(.appBody())
                                .foregroundColor(.appNavy)

                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedVibes.contains(vibe) ? Color.appGold : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func toggleVibe(_ vibe: String) {
        if selectedVibes.contains(vibe) {
            selectedVibes.remove(vibe)
        } else {
            selectedVibes.insert(vibe)
        }
    }
}

// MARK: - Preview

#Preview {
    ContextSelectionView()
        .modelContainer(for: [Fragrance.self, Recommendation.self])
}
