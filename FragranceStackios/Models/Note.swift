//
//  Note.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var name: String
    var category: NoteCategory
    var noteDescription: String?
    var imageURL: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \FragranceNote.note)
    var fragrances: [FragranceNote]

    init(name: String, category: NoteCategory, noteDescription: String? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.noteDescription = noteDescription
        self.fragrances = []
    }
}

// MARK: - Enums

enum NoteCategory: String, Codable, CaseIterable {
    case citrus = "Citrus"
    case floral = "Floral"
    case woody = "Woody"
    case spicy = "Spicy"
    case fruity = "Fruity"
    case green = "Green"
    case aquatic = "Aquatic"
    case gourmand = "Gourmand"
    case herbal = "Herbal"
    case animalic = "Animalic"
    case resinous = "Resinous"
    case powdery = "Powdery"
}
