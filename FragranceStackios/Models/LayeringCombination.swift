//
//  LayeringCombination.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class LayeringCombination {
    var id: UUID
    var name: String
    var comboDescription: String?
    var compatibility: Int // 1-10
    var ratioFragrance1: Int
    var ratioFragrance2: Int
    var applicationOrder: ApplicationOrder
    var bestSeasons: [Season]
    var bestOccasions: [Occasion]
    var userSubmitted: Bool
    var upvotes: Int
    var downvotes: Int
    var createdAt: Date

    // Relationships
    var fragrance1: Fragrance
    var fragrance2: Fragrance

    init(
        name: String,
        comboDescription: String? = nil,
        compatibility: Int,
        ratioFragrance1: Int = 2,
        ratioFragrance2: Int = 2,
        applicationOrder: ApplicationOrder = .simultaneous,
        bestSeasons: [Season] = [],
        bestOccasions: [Occasion] = [],
        fragrance1: Fragrance,
        fragrance2: Fragrance,
        userSubmitted: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.comboDescription = comboDescription
        self.compatibility = min(max(compatibility, 1), 10)
        self.ratioFragrance1 = ratioFragrance1
        self.ratioFragrance2 = ratioFragrance2
        self.applicationOrder = applicationOrder
        self.bestSeasons = bestSeasons
        self.bestOccasions = bestOccasions
        self.fragrance1 = fragrance1
        self.fragrance2 = fragrance2
        self.userSubmitted = userSubmitted
        self.upvotes = 0
        self.downvotes = 0
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension LayeringCombination {
    var ratioDescription: String {
        "\(ratioFragrance1):\(ratioFragrance2)"
    }

    var displayName: String {
        name.isEmpty ? "\(fragrance1.name) + \(fragrance2.name)" : name
    }
}

// MARK: - Enums

enum ApplicationOrder: String, Codable, CaseIterable {
    case frag1First = "Fragrance 1 First"
    case frag2First = "Fragrance 2 First"
    case simultaneous = "Simultaneous"
}

enum Season: String, Codable, CaseIterable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
}

enum Occasion: String, Codable, CaseIterable {
    case office = "Office"
    case date = "Date"
    case casual = "Casual"
    case formal = "Formal"
    case club = "Club"
}
