//
//  QuickLogSheet.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct QuickLogSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    @Query(sort: \Fragrance.name, order: .forward)
    var fragrances: [Fragrance]

    @Query(sort: \UserFragrance.createdAt, order: .reverse)
    var userFragrances: [UserFragrance]

    // Form state
    @State private var selectedFragrance: Fragrance?
    @State private var selectedOccasion: Occasion = .casual
    @State private var selectedTimeOfDay: TimeOfDay = .morning
    @State private var selectedDate: Date = Date()
    @State private var selectedLayeredWith: Fragrance?
    @State private var weatherText: String = ""
    @State private var temperatureText: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Fragrance") {
                    Picker("Select Fragrance", selection: $selectedFragrance) {
                        Text("Choose a fragrance").tag(nil as Fragrance?)
                        Divider()
                        ForEach(fragrances, id: \.self) { fragrance in
                            Text(fragrance.displayName).tag(fragrance as Fragrance?)
                        }
                    }
                    .tint(.appGold)
                }

                Section("Optional Layering") {
                    Picker("Layered with", selection: $selectedLayeredWith) {
                        Text("None").tag(nil as Fragrance?)
                        Divider()
                        ForEach(fragrances, id: \.self) { fragrance in
                            if fragrance.id != selectedFragrance?.id {
                                Text(fragrance.displayName).tag(fragrance as Fragrance?)
                            }
                        }
                    }
                    .tint(.appGold)
                }

                Section("When & Why") {
                    DatePicker(
                        "Date Worn",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .tint(.appGold)

                    Picker("Time of Day", selection: $selectedTimeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            Text(time.rawValue).tag(time)
                        }
                    }
                    .tint(.appGold)

                    Picker("Occasion", selection: $selectedOccasion) {
                        ForEach(Occasion.allCases, id: \.self) { occasion in
                            Text(occasion.rawValue).tag(occasion)
                        }
                    }
                    .tint(.appGold)
                }

                Section("Conditions") {
                    TextField("Weather (e.g., Sunny, Rainy)", text: $weatherText)

                    HStack {
                        TextField("Temperature (°C)", text: $temperatureText)
                            .keyboardType(.decimalPad)
                        Text("°C")
                            .foregroundColor(.gray)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Log a Wear")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .topBarLeading
                    #else
                    return .cancellationAction
                    #endif
                }()) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appNavy)
                }

                ToolbarItem(placement: {
                    #if os(iOS)
                    return .topBarTrailing
                    #else
                    return .confirmationAction
                    #endif
                }()) {
                    Button("Save") {
                        saveWearLog()
                    }
                    .foregroundColor(.appGold)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Error", isPresented: $showAlert, actions: {
            Button("OK") { }
        }, message: {
            Text(alertMessage)
        })
    }

    // MARK: - Actions

    private func saveWearLog() {
        guard let fragrance = selectedFragrance else {
            alertMessage = "Please select a fragrance"
            showAlert = true
            return
        }

        // Find or create UserFragrance
        let userFragrance = userFragrances.first { $0.fragrance.id == fragrance.id } ??
            createUserFragrance(for: fragrance)

        // Create WearLog
        let wearLog = WearLog(
            fragrance: fragrance,
            userFragrance: userFragrance,
            dateWorn: selectedDate,
            timeOfDay: selectedTimeOfDay,
            occasion: selectedOccasion,
            weather: weatherText.isEmpty ? nil : weatherText,
            temperature: Double(temperatureText),
            layeredWith: selectedLayeredWith
        )

        // Update UserFragrance
        userFragrance.timesWorn += 1
        userFragrance.lastWornDate = selectedDate

        // Insert into context
        context.insert(wearLog)

        do {
            try context.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save wear log: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func createUserFragrance(for fragrance: Fragrance) -> UserFragrance {
        let userFragrance = UserFragrance(fragrance: fragrance)
        context.insert(userFragrance)
        return userFragrance
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    // Sample fragrances
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

    container.mainContext.insert(frag1)
    container.mainContext.insert(frag2)

    return QuickLogSheet()
        .modelContainer(container)
}
