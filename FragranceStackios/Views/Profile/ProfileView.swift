//
//  ProfileView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var userName: String = "Stuart"
    @State private var defaultLocation: String = "New York, NY"
    @State private var selectedOccasions: [Occasion] = [.office, .casual]
    @State private var isFahrenheit: Bool = true
    @State private var isDarkMode: Bool = false

    @Query(sort: \UserFragrance.createdAt, order: .reverse)
    var userFragrances: [UserFragrance]

    @Query(sort: \WearLog.dateWorn, order: .reverse)
    var allWearLogs: [WearLog]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info Section
                    UserInfoSection(userName: $userName)

                    // Preferences Section
                    PreferencesSection(
                        defaultLocation: $defaultLocation,
                        selectedOccasions: $selectedOccasions,
                        isFahrenheit: $isFahrenheit
                    )

                    // Collection Statistics
                    CollectionStatisticsSection(userFragrances: userFragrances)

                    // App Settings
                    AppSettingsSection(isDarkMode: $isDarkMode)

                    Spacer()
                        .frame(height: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - User Info Section

struct UserInfoSection: View {
    @Binding var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    Text(userName)
                        .font(.appHeadline())
                        .foregroundColor(.appNavy)
                }

                Spacer()
            }
            .padding(16)
            .fragranceCardStyle()
        }
    }
}

// MARK: - Preferences Section

struct PreferencesSection: View {
    @Binding var defaultLocation: String
    @Binding var selectedOccasions: [Occasion]
    @Binding var isFahrenheit: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            VStack(spacing: 16) {
                // Default Location
                VStack(alignment: .leading, spacing: 8) {
                    Label("Default Location", systemImage: "location.fill")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    TextField("New York, NY", text: $defaultLocation)
                        .appTextFieldStyle()
                }

                Divider()
                    .padding(.vertical, 4)

                // Favorite Occasions
                VStack(alignment: .leading, spacing: 10) {
                    Label("Favorite Occasions", systemImage: "star.fill")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach([Occasion.office, .casual, .date], id: \.self) { occasion in
                                OccasionChip(
                                    occasion: occasion,
                                    isSelected: selectedOccasions.contains(occasion),
                                    action: {
                                        toggleOccasion(occasion)
                                    }
                                )
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach([Occasion.formal, .club], id: \.self) { occasion in
                                OccasionChip(
                                    occasion: occasion,
                                    isSelected: selectedOccasions.contains(occasion),
                                    action: {
                                        toggleOccasion(occasion)
                                    }
                                )
                            }

                            Spacer()
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                // Temperature Preference
                HStack {
                    Label("Temperature Unit", systemImage: "thermometer")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    Spacer()

                    Picker("Temperature", selection: $isFahrenheit) {
                        Text("°F").tag(true)
                        Text("°C").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
            .padding(16)
            .fragranceCardStyle()
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

// MARK: - Occasion Chip Component

struct OccasionChip: View {
    let occasion: Occasion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(occasion.rawValue)
                .font(.appCaption())
                .foregroundColor(isSelected ? .white : .appNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.appGold : Color.appCream)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.appGold : Color.gray.opacity(0.2),
                            lineWidth: 1.5
                        )
                )
        }
    }
}

// MARK: - Collection Statistics Section

struct CollectionStatisticsSection: View {
    let userFragrances: [UserFragrance]

    var totalFragrances: Int {
        userFragrances.count
    }

    var signatureFragrances: Int {
        userFragrances.filter { $0.isSignature }.count
    }

    var familyBreakdown: [(family: FragranceFamily, count: Int)] {
        var breakdown: [FragranceFamily: Int] = [:]
        for userFrag in userFragrances {
            let family = userFrag.fragrance.fragranceFamily
            breakdown[family, default: 0] += 1
        }
        return breakdown.sorted { $0.value > $1.value }.map { (family: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collection Statistics")
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            VStack(spacing: 12) {
                // Total Fragrances
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Fragrances")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)
                        Text("Your complete collection")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("\(totalFragrances)")
                        .font(.appStat())
                        .foregroundColor(.appGold)
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(8)

                Divider()
                    .padding(.vertical, 4)

                // Family Breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Text("By Family")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    if familyBreakdown.isEmpty {
                        Text("No fragrances added yet")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(familyBreakdown, id: \.family) { family, count in
                                HStack {
                                    Text(family.rawValue)
                                        .font(.appBody())
                                        .foregroundColor(.appNavy)

                                    Spacer()

                                    Text("\(count)")
                                        .font(.appSubheadline())
                                        .foregroundColor(.appGold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.appGold.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                // Signature Fragrances
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Signature Fragrances")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)
                        Text("Marked as signature")
                            .font(.appCaption())
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("\(signatureFragrances)")
                        .font(.appStat())
                        .foregroundColor(.appGold)
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(8)
            }
            .padding(12)
            .fragranceCardStyle()
        }
    }
}

// MARK: - App Settings Section

struct AppSettingsSection: View {
    @Binding var isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Settings")
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            VStack(spacing: 12) {
                // Theme Toggle
                HStack {
                    Label("Dark Mode", systemImage: "moon.stars.fill")
                        .font(.appSubheadline())
                        .foregroundColor(.appNavy)

                    Spacer()

                    Toggle("", isOn: $isDarkMode)
                        .tint(.appGold)
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(8)

                Divider()
                    .padding(.vertical, 4)

                // Export/Backup Button
                Button(action: {}) {
                    HStack {
                        Label("Export & Backup", systemImage: "icloud.and.arrow.up.fill")
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appGold)
                    }
                    .padding(12)
                    .background(Color.appCream)
                    .cornerRadius(8)
                }

                // About Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("About")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .textCase(.uppercase)

                    HStack {
                        Text("Version")
                            .font(.appBody())
                            .foregroundColor(.appNavy)

                        Spacer()

                        Text("1.0.0")
                            .font(.appBody())
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(8)
            }
            .padding(12)
            .fragranceCardStyle()
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .modelContainer(for: UserFragrance.self, inMemory: true)
}
