//
//  WearLog.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class WearLog {
    var id: UUID
    var dateWorn: Date
    var timeOfDay: TimeOfDay
    var occasion: Occasion
    var weather: String?
    var temperature: Double? // Celsius
    var compliments: Int
    var satisfactionRating: Int? // 1-5
    var personalNotes: String?
    var createdAt: Date

    // Relationships
    var fragrance: Fragrance
    var userFragrance: UserFragrance?
    var layeredWith: Fragrance?

    init(
        fragrance: Fragrance,
        userFragrance: UserFragrance? = nil,
        dateWorn: Date = Date(),
        timeOfDay: TimeOfDay = .morning,
        occasion: Occasion,
        weather: String? = nil,
        temperature: Double? = nil,
        layeredWith: Fragrance? = nil
    ) {
        self.id = UUID()
        self.fragrance = fragrance
        self.userFragrance = userFragrance
        self.dateWorn = dateWorn
        self.timeOfDay = timeOfDay
        self.occasion = occasion
        self.weather = weather
        self.temperature = temperature
        self.layeredWith = layeredWith
        self.compliments = 0
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension WearLog {
    var wasLayered: Bool {
        layeredWith != nil
    }

    var daysSinceWorn: Int {
        Calendar.current.dateComponents([.day], from: dateWorn, to: Date()).day ?? 0
    }
}

// MARK: - Enums

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"
}
