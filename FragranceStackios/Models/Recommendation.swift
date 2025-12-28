//
//  Recommendation.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Recommendation {
    var id: UUID
    var occasion: Occasion
    var weather: String?
    var temperature: Double?
    var timeOfDay: TimeOfDay
    var confidenceScore: Double // 0-100
    var wasAccepted: Bool
    var rejectionReason: String?
    var createdAt: Date

    // Relationships
    var fragrance: Fragrance

    init(
        fragrance: Fragrance,
        occasion: Occasion,
        weather: String? = nil,
        temperature: Double? = nil,
        timeOfDay: TimeOfDay,
        confidenceScore: Double
    ) {
        self.id = UUID()
        self.fragrance = fragrance
        self.occasion = occasion
        self.weather = weather
        self.temperature = temperature
        self.timeOfDay = timeOfDay
        self.confidenceScore = min(max(confidenceScore, 0), 100)
        self.wasAccepted = false
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension Recommendation {
    var confidenceLevel: String {
        switch confidenceScore {
        case 0..<40: return "Low"
        case 40..<70: return "Medium"
        case 70...100: return "High"
        default: return "Unknown"
        }
    }

    var isRecent: Bool {
        guard let hoursAgo = Calendar.current.dateComponents([.hour], from: createdAt, to: Date()).hour else {
            return false
        }
        return hoursAgo < 24
    }
}
