import Foundation
import Supabase

/// Service for syncing data with Supabase database
@MainActor
@Observable
final class SupabaseDataService {
    // MARK: - Singleton

    static let shared = SupabaseDataService()

    // MARK: - Properties

    private(set) var isLoading = false
    private(set) var lastError: String?

    private let supabase: SupabaseClient
    private let authManager = AuthManager.shared

    // MARK: - Initialization

    private init() {
        supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // MARK: - Fragrances

    /// Fetch all fragrances from the database
    func fetchAllFragrances() async throws -> [RemoteFragrance] {
        try await supabase
            .from("fragrances")
            .select()
            .order("name")
            .execute()
            .value
    }

    /// Search fragrances by name or brand
    func searchFragrances(query: String) async throws -> [RemoteFragrance] {
        try await supabase
            .rpc("search_fragrances", params: ["p_query": query])
            .execute()
            .value
    }

    /// Create a new fragrance
    func createFragrance(_ fragrance: CreateFragranceRequest) async throws -> RemoteFragrance {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        var request = fragrance
        request.createdBy = userId

        return try await supabase
            .from("fragrances")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update a fragrance
    func updateFragrance(id: UUID, updates: UpdateFragranceRequest) async throws {
        try await supabase
            .from("fragrances")
            .update(updates)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - User Collection

    /// Fetch user's fragrance collection
    func fetchUserCollection() async throws -> [UserFragranceWithDetails] {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        return try await supabase
            .rpc("get_user_collection", params: ["p_user_id": userId.uuidString])
            .execute()
            .value
    }

    /// Add fragrance to user's collection
    func addToCollection(_ request: AddToCollectionRequest) async throws -> RemoteUserFragrance {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        // Check collection limit
        if let profile = authManager.profile, profile.tier == "free" {
            let collection = try await fetchUserCollection()
            if collection.count >= profile.fragranceLimit {
                throw DataServiceError.collectionLimitReached
            }
        }

        var fullRequest = request
        fullRequest.userId = userId

        return try await supabase
            .from("user_fragrances")
            .insert(fullRequest)
            .select()
            .single()
            .execute()
            .value
    }

    /// Remove fragrance from user's collection
    func removeFromCollection(userFragranceId: UUID) async throws {
        try await supabase
            .from("user_fragrances")
            .delete()
            .eq("id", value: userFragranceId)
            .execute()
    }

    /// Update user fragrance (rating, notes, etc.)
    func updateUserFragrance(id: UUID, updates: UpdateUserFragranceRequest) async throws {
        try await supabase
            .from("user_fragrances")
            .update(updates)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Wear Logs

    /// Fetch user's wear logs
    func fetchWearLogs(limit: Int = 50) async throws -> [RemoteWearLog] {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        return try await supabase
            .from("wear_logs")
            .select("*, fragrances(name, brand)")
            .eq("user_id", value: userId)
            .order("date_worn", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Create a wear log entry
    func createWearLog(_ request: CreateWearLogRequest) async throws -> RemoteWearLog {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        var fullRequest = request
        fullRequest.userId = userId

        return try await supabase
            .from("wear_logs")
            .insert(fullRequest)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update a wear log entry
    func updateWearLog(id: UUID, updates: UpdateWearLogRequest) async throws {
        try await supabase
            .from("wear_logs")
            .update(updates)
            .eq("id", value: id)
            .execute()
    }

    /// Delete a wear log entry
    func deleteWearLog(id: UUID) async throws {
        try await supabase
            .from("wear_logs")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Usage Stats

    /// Get user's usage statistics
    func fetchUsageStats() async throws -> UsageStats {
        guard let userId = authManager.currentUser?.id else {
            throw DataServiceError.notAuthenticated
        }

        // Fetch rate limits
        let rateLimits: [RateLimitRecord] = try await supabase
            .from("rate_limits")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        // Fetch LLM costs for this month
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!

        let llmRequests: [LLMRequestRecord] = try await supabase
            .from("llm_requests")
            .select("cost_usd, request_type")
            .eq("user_id", value: userId)
            .gte("created_at", value: ISO8601DateFormatter().string(from: startOfMonth))
            .execute()
            .value

        let totalCostThisMonth = llmRequests.reduce(0) { $0 + $1.costUsd }
        let requestCountThisMonth = llmRequests.count

        return UsageStats(
            rateLimits: rateLimits,
            totalCostThisMonth: totalCostThisMonth,
            requestCountThisMonth: requestCountThisMonth
        )
    }
}

// MARK: - Error Types

enum DataServiceError: Error, LocalizedError {
    case notAuthenticated
    case collectionLimitReached
    case fragranceNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue"
        case .collectionLimitReached:
            return "Collection limit reached. Upgrade to premium for unlimited fragrances."
        case .fragranceNotFound:
            return "Fragrance not found"
        }
    }
}

// MARK: - Remote Models

struct RemoteFragrance: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String
    var concentration: String?
    var gender: String?
    var releaseYear: Int?
    var fragranceFamily: String?
    var notesTop: [String]?
    var notesHeart: [String]?
    var notesBase: [String]?
    var longevityHours: Double?
    var projection: Int?
    var sillage: Int?
    var seasonSpring: Int?
    var seasonSummer: Int?
    var seasonFall: Int?
    var seasonWinter: Int?
    var occasionOffice: Int?
    var occasionDate: Int?
    var occasionCasual: Int?
    var occasionFormal: Int?
    var occasionClub: Int?
    var aiDescription: String?
    var imageUrl: String?
    var fragranticaUrl: String?
    var parfumoUrl: String?
    var isVerified: Bool?
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, concentration, gender
        case releaseYear = "release_year"
        case fragranceFamily = "fragrance_family"
        case notesTop = "notes_top"
        case notesHeart = "notes_heart"
        case notesBase = "notes_base"
        case longevityHours = "longevity_hours"
        case projection, sillage
        case seasonSpring = "season_spring"
        case seasonSummer = "season_summer"
        case seasonFall = "season_fall"
        case seasonWinter = "season_winter"
        case occasionOffice = "occasion_office"
        case occasionDate = "occasion_date"
        case occasionCasual = "occasion_casual"
        case occasionFormal = "occasion_formal"
        case occasionClub = "occasion_club"
        case aiDescription = "ai_description"
        case imageUrl = "image_url"
        case fragranticaUrl = "fragrantica_url"
        case parfumoUrl = "parfumo_url"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RemoteUserFragrance: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let fragranceId: UUID
    var purchaseDate: Date?
    var purchasePrice: Double?
    var bottleSizeMl: Int?
    var amountRemainingPercent: Int?
    var personalRating: Int?
    var personalNotes: String?
    var isSignature: Bool
    var isFavorite: Bool
    var timesWorn: Int
    var lastWornAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fragranceId = "fragrance_id"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case bottleSizeMl = "bottle_size_ml"
        case amountRemainingPercent = "amount_remaining_percent"
        case personalRating = "personal_rating"
        case personalNotes = "personal_notes"
        case isSignature = "is_signature"
        case isFavorite = "is_favorite"
        case timesWorn = "times_worn"
        case lastWornAt = "last_worn_at"
        case createdAt = "created_at"
    }
}

struct UserFragranceWithDetails: Codable, Identifiable {
    var id: UUID { userFragranceId }
    let userFragranceId: UUID
    let fragranceId: UUID
    let name: String
    let brand: String
    let concentration: String?
    let personalRating: Int?
    let timesWorn: Int
    let isSignature: Bool
    let isFavorite: Bool
    let aiDescription: String?
    let notesTop: [String]?
    let notesHeart: [String]?
    let notesBase: [String]?
    let longevityHours: Double?
    let projection: Int?
    let sillage: Int?
    let seasonSpring: Int?
    let seasonSummer: Int?
    let seasonFall: Int?
    let seasonWinter: Int?
    let occasionOffice: Int?
    let occasionDate: Int?
    let occasionCasual: Int?
    let occasionFormal: Int?
    let occasionClub: Int?

    enum CodingKeys: String, CodingKey {
        case userFragranceId = "user_fragrance_id"
        case fragranceId = "fragrance_id"
        case name, brand, concentration
        case personalRating = "personal_rating"
        case timesWorn = "times_worn"
        case isSignature = "is_signature"
        case isFavorite = "is_favorite"
        case aiDescription = "ai_description"
        case notesTop = "notes_top"
        case notesHeart = "notes_heart"
        case notesBase = "notes_base"
        case longevityHours = "longevity_hours"
        case projection, sillage
        case seasonSpring = "season_spring"
        case seasonSummer = "season_summer"
        case seasonFall = "season_fall"
        case seasonWinter = "season_winter"
        case occasionOffice = "occasion_office"
        case occasionDate = "occasion_date"
        case occasionCasual = "occasion_casual"
        case occasionFormal = "occasion_formal"
        case occasionClub = "occasion_club"
    }
}

struct RemoteWearLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let userFragranceId: UUID?
    let fragranceId: UUID
    let dateWorn: Date
    var timeOfDay: String?
    var occasion: String?
    var weatherCondition: String?
    var temperatureF: Int?
    var humidityPercent: Int?
    var locationCity: String?
    var locationCountry: String?
    var satisfactionRating: Int?
    var complimentsReceived: Int?
    var notes: String?
    var layeredWith: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userFragranceId = "user_fragrance_id"
        case fragranceId = "fragrance_id"
        case dateWorn = "date_worn"
        case timeOfDay = "time_of_day"
        case occasion
        case weatherCondition = "weather_condition"
        case temperatureF = "temperature_f"
        case humidityPercent = "humidity_percent"
        case locationCity = "location_city"
        case locationCountry = "location_country"
        case satisfactionRating = "satisfaction_rating"
        case complimentsReceived = "compliments_received"
        case notes
        case layeredWith = "layered_with"
        case createdAt = "created_at"
    }
}

// MARK: - Request Models

struct CreateFragranceRequest: Codable {
    let name: String
    let brand: String
    var concentration: String?
    var gender: String?
    var releaseYear: Int?
    var fragranceFamily: String?
    var notesTop: [String]?
    var notesHeart: [String]?
    var notesBase: [String]?
    var longevityHours: Double?
    var projection: Int?
    var sillage: Int?
    var seasonSpring: Int?
    var seasonSummer: Int?
    var seasonFall: Int?
    var seasonWinter: Int?
    var occasionOffice: Int?
    var occasionDate: Int?
    var occasionCasual: Int?
    var occasionFormal: Int?
    var occasionClub: Int?
    var aiDescription: String?
    var createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case name, brand, concentration, gender
        case releaseYear = "release_year"
        case fragranceFamily = "fragrance_family"
        case notesTop = "notes_top"
        case notesHeart = "notes_heart"
        case notesBase = "notes_base"
        case longevityHours = "longevity_hours"
        case projection, sillage
        case seasonSpring = "season_spring"
        case seasonSummer = "season_summer"
        case seasonFall = "season_fall"
        case seasonWinter = "season_winter"
        case occasionOffice = "occasion_office"
        case occasionDate = "occasion_date"
        case occasionCasual = "occasion_casual"
        case occasionFormal = "occasion_formal"
        case occasionClub = "occasion_club"
        case aiDescription = "ai_description"
        case createdBy = "created_by"
    }
}

struct UpdateFragranceRequest: Codable {
    var concentration: String?
    var gender: String?
    var releaseYear: Int?
    var fragranceFamily: String?
    var notesTop: [String]?
    var notesHeart: [String]?
    var notesBase: [String]?
    var longevityHours: Double?
    var projection: Int?
    var sillage: Int?
    var seasonSpring: Int?
    var seasonSummer: Int?
    var seasonFall: Int?
    var seasonWinter: Int?
    var occasionOffice: Int?
    var occasionDate: Int?
    var occasionCasual: Int?
    var occasionFormal: Int?
    var occasionClub: Int?
    var aiDescription: String?

    enum CodingKeys: String, CodingKey {
        case concentration, gender
        case releaseYear = "release_year"
        case fragranceFamily = "fragrance_family"
        case notesTop = "notes_top"
        case notesHeart = "notes_heart"
        case notesBase = "notes_base"
        case longevityHours = "longevity_hours"
        case projection, sillage
        case seasonSpring = "season_spring"
        case seasonSummer = "season_summer"
        case seasonFall = "season_fall"
        case seasonWinter = "season_winter"
        case occasionOffice = "occasion_office"
        case occasionDate = "occasion_date"
        case occasionCasual = "occasion_casual"
        case occasionFormal = "occasion_formal"
        case occasionClub = "occasion_club"
        case aiDescription = "ai_description"
    }
}

struct AddToCollectionRequest: Codable {
    var userId: UUID?
    let fragranceId: UUID
    var purchaseDate: Date?
    var purchasePrice: Double?
    var bottleSizeMl: Int?
    var personalRating: Int?
    var isSignature: Bool?
    var isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fragranceId = "fragrance_id"
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case bottleSizeMl = "bottle_size_ml"
        case personalRating = "personal_rating"
        case isSignature = "is_signature"
        case isFavorite = "is_favorite"
    }
}

struct UpdateUserFragranceRequest: Codable {
    var purchaseDate: Date?
    var purchasePrice: Double?
    var bottleSizeMl: Int?
    var amountRemainingPercent: Int?
    var personalRating: Int?
    var personalNotes: String?
    var isSignature: Bool?
    var isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case purchaseDate = "purchase_date"
        case purchasePrice = "purchase_price"
        case bottleSizeMl = "bottle_size_ml"
        case amountRemainingPercent = "amount_remaining_percent"
        case personalRating = "personal_rating"
        case personalNotes = "personal_notes"
        case isSignature = "is_signature"
        case isFavorite = "is_favorite"
    }
}

struct CreateWearLogRequest: Codable {
    var userId: UUID?
    let fragranceId: UUID
    var userFragranceId: UUID?
    var dateWorn: Date?
    var timeOfDay: String?
    var occasion: String?
    var weatherCondition: String?
    var temperatureF: Int?
    var humidityPercent: Int?
    var locationCity: String?
    var locationCountry: String?
    var satisfactionRating: Int?
    var complimentsReceived: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fragranceId = "fragrance_id"
        case userFragranceId = "user_fragrance_id"
        case dateWorn = "date_worn"
        case timeOfDay = "time_of_day"
        case occasion
        case weatherCondition = "weather_condition"
        case temperatureF = "temperature_f"
        case humidityPercent = "humidity_percent"
        case locationCity = "location_city"
        case locationCountry = "location_country"
        case satisfactionRating = "satisfaction_rating"
        case complimentsReceived = "compliments_received"
        case notes
    }
}

struct UpdateWearLogRequest: Codable {
    var satisfactionRating: Int?
    var complimentsReceived: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case satisfactionRating = "satisfaction_rating"
        case complimentsReceived = "compliments_received"
        case notes
    }
}

// MARK: - Stats Models

struct UsageStats {
    let rateLimits: [RateLimitRecord]
    let totalCostThisMonth: Double
    let requestCountThisMonth: Int

    var dailyAiRemaining: Int {
        rateLimits.first { $0.endpoint == "recommendation" && $0.periodType == "daily" }?.requestsCount ?? 0
    }

    var monthlySearchRemaining: Int {
        rateLimits.first { $0.endpoint == "fragrance_search" && $0.periodType == "monthly" }?.requestsCount ?? 0
    }
}

struct RateLimitRecord: Codable {
    let userId: UUID
    let endpoint: String
    let periodType: String
    let requestsCount: Int
    let periodStart: Date
    let lastRequestAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case endpoint
        case periodType = "period_type"
        case requestsCount = "requests_count"
        case periodStart = "period_start"
        case lastRequestAt = "last_request_at"
    }
}

struct LLMRequestRecord: Codable {
    let costUsd: Double
    let requestType: String

    enum CodingKeys: String, CodingKey {
        case costUsd = "cost_usd"
        case requestType = "request_type"
    }
}
