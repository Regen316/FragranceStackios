//
//  FragranceMetrics.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class FragranceMetrics {
    var id: UUID
    var longevityHours: Double
    var projection: Int // 1-10
    var sillage: Int // 1-10

    // Season suitability (1-10 each)
    var seasonSpring: Int
    var seasonSummer: Int
    var seasonFall: Int
    var seasonWinter: Int

    // Occasion suitability (1-10 each)
    var occasionOffice: Int
    var occasionDate: Int
    var occasionCasual: Int
    var occasionFormal: Int
    var occasionClub: Int

    // Vibes (array of strings)
    var vibes: [String]

    // Community metrics
    var reviewCount: Int
    var averageRating: Double // 1.0-5.0

    // Relationships
    var fragrance: Fragrance?

    init(
        longevityHours: Double,
        projection: Int,
        sillage: Int,
        seasonSpring: Int,
        seasonSummer: Int,
        seasonFall: Int,
        seasonWinter: Int,
        occasionOffice: Int,
        occasionDate: Int,
        occasionCasual: Int,
        occasionFormal: Int,
        occasionClub: Int,
        vibes: [String] = [],
        reviewCount: Int = 0,
        averageRating: Double = 0.0
    ) {
        self.id = UUID()
        self.longevityHours = longevityHours
        self.projection = min(max(projection, 1), 10)
        self.sillage = min(max(sillage, 1), 10)
        self.seasonSpring = min(max(seasonSpring, 1), 10)
        self.seasonSummer = min(max(seasonSummer, 1), 10)
        self.seasonFall = min(max(seasonFall, 1), 10)
        self.seasonWinter = min(max(seasonWinter, 1), 10)
        self.occasionOffice = min(max(occasionOffice, 1), 10)
        self.occasionDate = min(max(occasionDate, 1), 10)
        self.occasionCasual = min(max(occasionCasual, 1), 10)
        self.occasionFormal = min(max(occasionFormal, 1), 10)
        self.occasionClub = min(max(occasionClub, 1), 10)
        self.vibes = vibes
        self.reviewCount = reviewCount
        self.averageRating = min(max(averageRating, 1.0), 5.0)
    }
}

// MARK: - Computed Properties

extension FragranceMetrics {
    var performanceScore: Double {
        let longevityScore = min(longevityHours / 20.0, 1.0) * 10
        return (longevityScore * 0.4) + (Double(projection) * 0.3) + (Double(sillage) * 0.3)
    }

    func seasonScore(for season: Season) -> Int {
        switch season {
        case .spring: return seasonSpring
        case .summer: return seasonSummer
        case .fall: return seasonFall
        case .winter: return seasonWinter
        }
    }

    func occasionScore(for occasion: Occasion) -> Int {
        switch occasion {
        case .office: return occasionOffice
        case .date: return occasionDate
        case .casual: return occasionCasual
        case .formal: return occasionFormal
        case .club: return occasionClub
        }
    }
}
