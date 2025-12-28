//
//  PostWearFeedbackView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct PostWearFeedbackView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    let wearLog: WearLog

    @State private var satisfactionRating: Int = 3
    @State private var complimentsCount: Int = 0
    @State private var personalNotes: String = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Fragrance") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(wearLog.fragrance.displayName)
                                .font(.appSubheadline())
                                .foregroundColor(.appNavy)

                            Text("Logged on \(formattedDate)")
                                .font(.appCaption())
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if wearLog.wasLayered, let layered = wearLog.layeredWith {
                                Label("Layered", systemImage: "link")
                                    .font(.appCaption())
                                    .foregroundColor(.appGold)

                                Text(layered.name)
                                    .font(.appCaption())
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section("How did it feel?") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Satisfaction")
                                .font(.appSubheadline())
                                .foregroundColor(.appNavy)

                            Spacer()

                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { index in
                                    Button(action: { satisfactionRating = index }) {
                                        Image(systemName: index <= satisfactionRating ? "star.fill" : "star")
                                            .font(.system(size: 24))
                                            .foregroundColor(index <= satisfactionRating ? .appGold : .gray.opacity(0.3))
                                    }
                                }
                            }
                        }

                        Text(satisfactionDescription)
                            .font(.appCaption())
                            .foregroundColor(.gray)
                            .italic()
                    }
                }

                Section("Feedback") {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Compliments", systemImage: "heart.fill")
                                .font(.appSubheadline())
                                .foregroundColor(.appNavy)

                            Text("Times complimented")
                                .font(.appCaption())
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: { if complimentsCount > 0 { complimentsCount -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appGold)
                            }

                            Text("\(complimentsCount)")
                                .font(.appStat())
                                .foregroundColor(.appNavy)
                                .frame(minWidth: 40)

                            Button(action: { complimentsCount += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.appGold)
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $personalNotes)
                        .frame(minHeight: 100)
                        .font(.appBody())
                        .scrollContentBackground(.hidden)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    Text("\(personalNotes.count)/500")
                        .font(.appCaption())
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Section {
                    Button(action: saveFeedback) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Feedback")
                        }
                        .frame(maxWidth: .infinity)
                        .font(.appSubheadline())
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("End-of-Day Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.appNavy)
                }
            }
        }
        .alert("Success", isPresented: $showAlert, actions: {
            Button("OK") {
                dismiss()
            }
        }, message: {
            Text(alertMessage)
        })
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: wearLog.dateWorn)
    }

    var satisfactionDescription: String {
        switch satisfactionRating {
        case 1:
            return "Not satisfied - wouldn't wear again"
        case 2:
            return "Somewhat satisfied - okay experience"
        case 3:
            return "Neutral - it was alright"
        case 4:
            return "Very satisfied - great day"
        case 5:
            return "Extremely satisfied - amazing experience!"
        default:
            return ""
        }
    }

    // MARK: - Actions

    private func saveFeedback() {
        // Update WearLog with feedback
        wearLog.satisfactionRating = satisfactionRating
        wearLog.compliments = complimentsCount
        wearLog.personalNotes = personalNotes.isEmpty ? nil : personalNotes

        do {
            try context.save()
            alertMessage = "Feedback saved successfully!"
            showAlert = true
        } catch {
            alertMessage = "Failed to save feedback: \(error.localizedDescription)"
            showAlert = true
        }
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

    let userFragrance = UserFragrance(fragrance: fragrance)

    let wearLog = WearLog(
        fragrance: fragrance,
        userFragrance: userFragrance,
        dateWorn: Date(),
        timeOfDay: .morning,
        occasion: .office
    )

    container.mainContext.insert(fragrance)
    container.mainContext.insert(userFragrance)
    container.mainContext.insert(wearLog)

    return PostWearFeedbackView(wearLog: wearLog)
        .modelContainer(container)
}
