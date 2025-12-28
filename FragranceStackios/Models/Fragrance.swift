//
//  Fragrance.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Fragrance {
    var id: UUID
    var name: String
    var brand: String
    var concentration: Concentration
    var fragranceFamily: FragranceFamily
    var gender: Gender
    var releaseYear: Int?
    var cloneAccuracy: Int? // 0-100%
    var imageURL: String?
    var bottleImageURL: String?
    var priceRange: String?
    var fragrancticaID: String?
    var parfumoID: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Fragrance.clones)
    var cloneOf: Fragrance?

    @Relationship(deleteRule: .cascade)
    var clones: [Fragrance]

    @Relationship(deleteRule: .cascade, inverse: \FragranceNote.fragrance)
    var notes: [FragranceNote]

    @Relationship(deleteRule: .nullify)
    var metrics: FragranceMetrics?

    @Relationship(deleteRule: .nullify, inverse: \UserFragrance.fragrance)
    var userFragrances: [UserFragrance]

    init(
        name: String,
        brand: String,
        concentration: Concentration = .edp,
        fragranceFamily: FragranceFamily = .fresh,
        gender: Gender = .unisex,
        releaseYear: Int? = nil,
        cloneOf: Fragrance? = nil,
        cloneAccuracy: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.concentration = concentration
        self.fragranceFamily = fragranceFamily
        self.gender = gender
        self.releaseYear = releaseYear
        self.cloneOf = cloneOf
        self.cloneAccuracy = cloneAccuracy
        self.createdAt = Date()
        self.notes = []
        self.clones = []
        self.userFragrances = []
    }
}

// MARK: - Computed Properties

extension Fragrance {
    var displayName: String {
        "\(brand) - \(name)"
    }

    var isClone: Bool {
        cloneOf != nil
    }

    var topNotes: [Note] {
        notes.filter { $0.type == .top }.map { $0.note }
    }

    var heartNotes: [Note] {
        notes.filter { $0.type == .heart }.map { $0.note }
    }

    var baseNotes: [Note] {
        notes.filter { $0.type == .base }.map { $0.note }
    }
}

// MARK: - Enums

enum Concentration: String, Codable, CaseIterable {
    case edt = "EDT"
    case edp = "EDP"
    case parfum = "Parfum"
    case cologne = "Cologne"
    case edc = "EDC"
}

enum FragranceFamily: String, Codable, CaseIterable {
    case citrus = "Citrus"
    case woody = "Woody"
    case oriental = "Oriental"
    case floral = "Floral"
    case fresh = "Fresh"
    case aromatic = "Aromatic"
    case fougere = "Fougère"
    case chypre = "Chypre"
    case gourmand = "Gourmand"
}

enum Gender: String, Codable, CaseIterable {
    case masculine = "Masculine"
    case feminine = "Feminine"
    case unisex = "Unisex"
}
