//
//  FragranceStackiosApp.swift
//  FragranceStackios
//
//  Created by Stuart Nealy Jr. on 12/28/25.
//

import SwiftUI
import SwiftData

@main
struct FragranceStackiosApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Fragrance.self, Note.self, FragranceNote.self, FragranceMetrics.self, UserFragrance.self, LayeringCombination.self, WearLog.self, Recommendation.self)
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    // Seed data on first launch
                    seedDataIfNeeded()
                }
        }
        .modelContainer(container)
    }

    private func seedDataIfNeeded() {

        let context = container.mainContext

        // Check if already seeded
        let fetchDescriptor = FetchDescriptor<Fragrance>()
        let existingFragrances = try? context.fetch(fetchDescriptor)

        if let count = existingFragrances?.count, count > 0 {
            print("Data already seeded (\(count) fragrances)")
            return
        }

        print("Seeding initial data...")

        // Create notes first
        let notes = createNotes(context: context)

        // Create Stuart's 10-fragrance collection
        let fragrances = createFragrances(context: context, notes: notes)

        // Create 5 layering combinations
        createLayeringCombinations(context: context, fragrances: fragrances)

        // Save context
        try? context.save()
        print("Seeding complete!")
    }

    private func createNotes(context: ModelContext) -> [String: Note] {
        var notesDict: [String: Note] = [:]

        let noteData: [(String, NoteCategory)] = [
            ("Pineapple", .fruity),
            ("Bergamot", .citrus),
            ("Apple", .fruity),
            ("Blackcurrant", .fruity),
            ("Birch", .woody),
            ("Patchouli", .woody),
            ("Jasmine", .floral),
            ("Rose", .floral),
            ("Musk", .animalic),
            ("Oakmoss", .green),
            ("Ambergris", .animalic),
            ("Vanilla", .gourmand),
            ("Saffron", .spicy),
            ("Amberwood", .woody),
            ("Fir Resin", .resinous),
            ("Cedar", .woody),
            ("Nutmeg", .spicy),
            ("Lavender", .herbal),
            ("Oud", .woody),
            ("Lemon", .citrus),
            ("Mandarin", .citrus),
            ("Tonka Bean", .gourmand),
            ("Neroli", .citrus),
            ("Iris", .floral),
            ("Amber", .resinous)
        ]

        for (name, category) in noteData {
            let note = Note(name: name, category: category)
            context.insert(note)
            notesDict[name] = note
        }

        return notesDict
    }

    private func createFragrances(context: ModelContext, notes: [String: Note]) -> [String: Fragrance] {
        var fragrancesDict: [String: Fragrance] = [:]

        // 1. Afnan Supremacy Silver (Aventus clone)
        let supremacy = Fragrance(
            name: "Supremacy Silver",
            brand: "Afnan",
            concentration: .edp,
            fragranceFamily: .fresh,
            gender: .masculine,
            releaseYear: 2019,
            cloneAccuracy: 95
        )
        context.insert(supremacy)

        let supremacyMetrics = FragranceMetrics(
            longevityHours: 12.0,
            projection: 8,
            sillage: 8,
            seasonSpring: 9, seasonSummer: 8, seasonFall: 9, seasonWinter: 7,
            occasionOffice: 8, occasionDate: 9, occasionCasual: 9, occasionFormal: 8, occasionClub: 7,
            vibes: ["fresh", "fruity", "sophisticated"],
            reviewCount: 250,
            averageRating: 4.5
        )
        supremacy.metrics = supremacyMetrics
        context.insert(supremacyMetrics)

        if let pineapple = notes["Pineapple"], let bergamot = notes["Bergamot"],
           let birch = notes["Birch"], let musk = notes["Musk"] {
            let note1 = FragranceNote(fragrance: supremacy, note: pineapple, type: .top, intensity: 9)
            let note2 = FragranceNote(fragrance: supremacy, note: bergamot, type: .top, intensity: 8)
            let note3 = FragranceNote(fragrance: supremacy, note: birch, type: .heart, intensity: 7)
            let note4 = FragranceNote(fragrance: supremacy, note: musk, type: .base, intensity: 8)
            context.insert(note1)
            context.insert(note2)
            context.insert(note3)
            context.insert(note4)
        }

        // 2. Vintage Radio (BR540 clone)
        let vintageRadio = Fragrance(
            name: "Vintage Radio",
            brand: "Generic Perfumes",
            concentration: .edp,
            fragranceFamily: .oriental,
            gender: .unisex,
            cloneAccuracy: 90
        )
        context.insert(vintageRadio)

        let vintageMetrics = FragranceMetrics(
            longevityHours: 20.0,
            projection: 9,
            sillage: 9,
            seasonSpring: 5, seasonSummer: 3, seasonFall: 9, seasonWinter: 10,
            occasionOffice: 3, occasionDate: 9, occasionCasual: 5, occasionFormal: 8, occasionClub: 9,
            vibes: ["sweet", "luxurious", "warm"],
            reviewCount: 180,
            averageRating: 4.7
        )
        vintageRadio.metrics = vintageMetrics
        context.insert(vintageMetrics)

        if let saffron = notes["Saffron"], let jasmine = notes["Jasmine"],
           let amberwood = notes["Amberwood"], let firResin = notes["Fir Resin"] {
            context.insert(FragranceNote(fragrance: vintageRadio, note: saffron, type: .top, intensity: 8))
            context.insert(FragranceNote(fragrance: vintageRadio, note: jasmine, type: .top, intensity: 7))
            context.insert(FragranceNote(fragrance: vintageRadio, note: amberwood, type: .heart, intensity: 9))
            context.insert(FragranceNote(fragrance: vintageRadio, note: firResin, type: .base, intensity: 8))
        }

        // 3. Shaghaf Oud Abyad (Oud for Greatness clone)
        let shaghaf = Fragrance(
            name: "Shaghaf Oud Abyad",
            brand: "Lattafa",
            concentration: .edp,
            fragranceFamily: .oriental,
            gender: .unisex,
            cloneAccuracy: 85
        )
        context.insert(shaghaf)

        let shaghafMetrics = FragranceMetrics(
            longevityHours: 24.0,
            projection: 10,
            sillage: 10,
            seasonSpring: 4, seasonSummer: 3, seasonFall: 10, seasonWinter: 10,
            occasionOffice: 3, occasionDate: 8, occasionCasual: 4, occasionFormal: 9, occasionClub: 9,
            vibes: ["oud", "powerful", "statement"],
            reviewCount: 320,
            averageRating: 4.6
        )
        shaghaf.metrics = shaghafMetrics
        context.insert(shaghafMetrics)

        if let nutmeg = notes["Nutmeg"], let lavender = notes["Lavender"],
           let oud = notes["Oud"], let musk = notes["Musk"] {
            context.insert(FragranceNote(fragrance: shaghaf, note: nutmeg, type: .top, intensity: 7))
            context.insert(FragranceNote(fragrance: shaghaf, note: lavender, type: .top, intensity: 6))
            context.insert(FragranceNote(fragrance: shaghaf, note: oud, type: .heart, intensity: 10))
            context.insert(FragranceNote(fragrance: shaghaf, note: musk, type: .base, intensity: 9))
        }

        // 4. Chanel Allure Homme Sport Eau Extreme
        let allure = Fragrance(
            name: "Allure Homme Sport Eau Extreme",
            brand: "Chanel",
            concentration: .edt,
            fragranceFamily: .fresh,
            gender: .masculine,
            releaseYear: 2012
        )
        context.insert(allure)

        let allureMetrics = FragranceMetrics(
            longevityHours: 10.0,
            projection: 6,
            sillage: 6,
            seasonSpring: 9, seasonSummer: 10, seasonFall: 8, seasonWinter: 6,
            occasionOffice: 10, occasionDate: 8, occasionCasual: 9, occasionFormal: 7, occasionClub: 6,
            vibes: ["fresh", "citrus", "versatile"],
            reviewCount: 500,
            averageRating: 4.8
        )
        allure.metrics = allureMetrics
        context.insert(allureMetrics)

        // 5. Prada L'Homme
        let prada = Fragrance(
            name: "L'Homme",
            brand: "Prada",
            concentration: .edt,
            fragranceFamily: .aromatic,
            gender: .masculine,
            releaseYear: 2016
        )
        context.insert(prada)

        let pradaMetrics = FragranceMetrics(
            longevityHours: 8.0,
            projection: 5,
            sillage: 5,
            seasonSpring: 9, seasonSummer: 8, seasonFall: 9, seasonWinter: 7,
            occasionOffice: 10, occasionDate: 7, occasionCasual: 7, occasionFormal: 9, occasionClub: 5,
            vibes: ["clean", "professional", "iris"],
            reviewCount: 450,
            averageRating: 4.6
        )
        prada.metrics = pradaMetrics
        context.insert(pradaMetrics)

        // Add 5 more simplified fragrances
        let tiger = Fragrance(name: "Tiger Cal", brand: "Generic Perfumes", cloneAccuracy: 80)
        let halloween = Fragrance(name: "Halloween Man X", brand: "J. Del Pozo")
        let amber = Fragrance(name: "Amber Oud Gold", brand: "Al Haramain")
        let explorer = Fragrance(name: "Explorer", brand: "Montblanc")
        let versace = Fragrance(name: "Pour Homme", brand: "Versace")

        [tiger, halloween, amber, explorer, versace].forEach { context.insert($0) }

        return [
            "supremacy": supremacy,
            "vintageRadio": vintageRadio,
            "shaghaf": shaghaf,
            "allure": allure,
            "prada": prada,
            "tiger": tiger
        ]
    }

    private func createLayeringCombinations(context: ModelContext, fragrances: [String: Fragrance]) {
        guard let supremacy = fragrances["supremacy"],
              let vintageRadio = fragrances["vintageRadio"],
              let shaghaf = fragrances["shaghaf"],
              let allure = fragrances["allure"],
              let prada = fragrances["prada"],
              let tiger = fragrances["tiger"] else { return }

        let combo1 = LayeringCombination(
            name: "The Signature Stack",
            comboDescription: "Sweet smokiness meets fresh fruitiness",
            compatibility: 9,
            ratioFragrance1: 2,
            ratioFragrance2: 2,
            applicationOrder: .simultaneous,
            bestSeasons: [.spring, .summer, .fall, .winter],
            bestOccasions: [.date, .formal],
            fragrance1: supremacy,
            fragrance2: vintageRadio
        )

        let combo2 = LayeringCombination(
            name: "The Statement Maker",
            comboDescription: "Gourmand oud fusion",
            compatibility: 8,
            ratioFragrance1: 2,
            ratioFragrance2: 1,
            bestSeasons: [.fall, .winter],
            bestOccasions: [.formal, .club],
            fragrance1: shaghaf,
            fragrance2: tiger
        )

        let combo3 = LayeringCombination(
            name: "The Daily Driver",
            comboDescription: "Citrus freshness with depth",
            compatibility: 9,
            ratioFragrance1: 2,
            ratioFragrance2: 2,
            bestSeasons: [.spring, .summer, .fall, .winter],
            bestOccasions: [.office, .casual],
            fragrance1: allure,
            fragrance2: supremacy
        )

        let combo4 = LayeringCombination(
            name: "The Gourmand",
            comboDescription: "Ultra-sweet with oud complexity",
            compatibility: 7,
            ratioFragrance1: 3,
            ratioFragrance2: 1,
            bestSeasons: [.winter],
            bestOccasions: [.date, .club],
            fragrance1: vintageRadio,
            fragrance2: shaghaf
        )

        let combo5 = LayeringCombination(
            name: "The Professional",
            comboDescription: "Iris cleanliness with fruity kick",
            compatibility: 8,
            ratioFragrance1: 2,
            ratioFragrance2: 1,
            bestSeasons: [.spring, .summer, .fall, .winter],
            bestOccasions: [.office, .formal],
            fragrance1: prada,
            fragrance2: supremacy
        )

        [combo1, combo2, combo3, combo4, combo5].forEach { context.insert($0) }
    }
}
