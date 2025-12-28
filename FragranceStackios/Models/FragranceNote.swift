//
//  FragranceNote.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class FragranceNote {
    var id: UUID
    var type: NoteType
    var intensity: Int // 1-10

    // Relationships
    var fragrance: Fragrance
    var note: Note

    init(fragrance: Fragrance, note: Note, type: NoteType, intensity: Int) {
        self.id = UUID()
        self.fragrance = fragrance
        self.note = note
        self.type = type
        self.intensity = min(max(intensity, 1), 10) // Clamp to 1-10
    }
}

// MARK: - Enums

enum NoteType: String, Codable, CaseIterable {
    case top = "Top"
    case heart = "Heart"
    case base = "Base"
}
