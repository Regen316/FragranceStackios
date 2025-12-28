//
//  UserFragrance.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class UserFragrance {
    var id: UUID
    var purchaseDate: Date?
    var purchasePrice: Double?
    var bottleSize: Int // ml
    var amountRemaining: Int // ml
    var personalRating: Int? // 1-5 stars
    var personalNotes: String?
    var isSignature: Bool
    var isFavorite: Bool
    var timesWorn: Int
    var lastWornDate: Date?
    var createdAt: Date

    // Relationships
    var fragrance: Fragrance

    @Relationship(deleteRule: .cascade, inverse: \WearLog.userFragrance)
    var wearLogs: [WearLog]

    init(
        fragrance: Fragrance,
        purchaseDate: Date? = nil,
        purchasePrice: Double? = nil,
        bottleSize: Int = 100,
        amountRemaining: Int? = nil,
        personalRating: Int? = nil,
        isSignature: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.fragrance = fragrance
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.bottleSize = bottleSize
        self.amountRemaining = amountRemaining ?? bottleSize
        self.personalRating = personalRating
        self.isSignature = isSignature
        self.isFavorite = isFavorite
        self.timesWorn = 0
        self.createdAt = Date()
        self.wearLogs = []
    }
}

// MARK: - Computed Properties

extension UserFragrance {
    var percentRemaining: Double {
        Double(amountRemaining) / Double(bottleSize) * 100
    }

    var costPerWear: Double? {
        guard let price = purchasePrice, timesWorn > 0 else { return nil }
        return price / Double(timesWorn)
    }

    var daysSincePurchase: Int? {
        guard let purchaseDate = purchaseDate else { return nil }
        return Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day
    }
}
