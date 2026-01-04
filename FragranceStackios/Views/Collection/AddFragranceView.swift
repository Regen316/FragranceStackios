//
//  AddFragranceView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct AddFragranceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var fragranceName = ""
    @State private var brand = ""
    @State private var selectedConcentration: Concentration = .edp
    @State private var selectedFamily: FragranceFamily = .fresh
    @State private var selectedGender: Gender = .unisex
    @State private var selectedRating: Int? = nil
    @State private var isSignature = false
    @State private var releaseYear: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name field
                    fieldSection(
                        label: "Fragrance Name",
                        content: {
                            TextField("e.g., Aventus", text: $fragranceName)
                                .appTextFieldStyle()
                        }
                    )

                    // Brand field
                    fieldSection(
                        label: "Brand",
                        content: {
                            TextField("e.g., Creed", text: $brand)
                                .appTextFieldStyle()
                        }
                    )

                    // Concentration picker
                    fieldSection(
                        label: "Concentration",
                        content: {
                            Picker("Concentration", selection: $selectedConcentration) {
                                ForEach(Concentration.allCases, id: \.self) { concentration in
                                    Text(concentration.rawValue).tag(concentration)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    )

                    // Family picker
                    fieldSection(
                        label: "Fragrance Family",
                        content: {
                            Picker("Family", selection: $selectedFamily) {
                                ForEach(FragranceFamily.allCases, id: \.self) { family in
                                    Text(family.rawValue).tag(family)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    )

                    // Gender picker
                    fieldSection(
                        label: "Gender",
                        content: {
                            Picker("Gender", selection: $selectedGender) {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    )

                    // Release year field (optional)
                    fieldSection(
                        label: "Release Year (optional)",
                        content: {
                            TextField("e.g., 2010", text: $releaseYear)
                                #if os(iOS)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.plain)
                                #endif
                                .padding(12)
                                .background(Color.appCream)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    )

                    Divider()

                    // Personal rating picker
                    fieldSection(
                        label: "Personal Rating",
                        content: {
                            ratingPickerView
                        }
                    )

                    // Signature toggle
                    fieldSection(
                        label: "Mark as Signature",
                        content: {
                            Toggle("Add to signature collection", isOn: $isSignature)
                                .tint(.appGold)
                        }
                    )

                    // Action buttons
                    actionButtonsView
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .padding(16)
            }
            .scrollIndicators(.visible)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Add Fragrance")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .navigationBarLeading
                    #else
                    return .cancellationAction
                    #endif
                }()) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.appNavy)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func fieldSection<Content: View>(
        label: String,
        content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.appSubheadline())
                .foregroundColor(.appNavy)

            content()
        }
    }

    @ViewBuilder
    private var ratingPickerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button(action: { selectedRating = rating }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedRating == rating ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(
                                    selectedRating == rating ? .appGold : .gray.opacity(0.3)
                                )

                            Text("\(rating)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(
                                    selectedRating == rating ? .appGold : .gray
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(
                            selectedRating == rating
                                ? Color.appGold.opacity(0.1)
                                : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
            }

            if selectedRating == nil {
                Text("Not yet rated")
                    .font(.appCaption())
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: saveFragrance) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Save Fragrance")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isFormValid)

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !fragranceName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !brand.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveFragrance() {
        let fragrance = Fragrance(
            name: fragranceName.trimmingCharacters(in: .whitespaces),
            brand: brand.trimmingCharacters(in: .whitespaces),
            concentration: selectedConcentration,
            fragranceFamily: selectedFamily,
            gender: selectedGender,
            releaseYear: Int(releaseYear.trimmingCharacters(in: .whitespaces))
        )

        context.insert(fragrance)

        // Create associated UserFragrance
        let userFragrance = UserFragrance(
            fragrance: fragrance,
            personalRating: selectedRating,
            isSignature: isSignature
        )

        context.insert(userFragrance)

        do {
            try context.save()
            dismiss()
        } catch {
            print("Error saving fragrance: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    return AddFragranceView()
        .modelContainer(container)
}
