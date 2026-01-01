import Foundation
import CoreLocation

/// Service for calling FragranceStack Edge Functions
@MainActor
@Observable
final class FragranceAPIService {
    // MARK: - Singleton

    static let shared = FragranceAPIService()

    // MARK: - Properties

    private(set) var isLoading = false
    private(set) var lastError: String?

    private let authManager = AuthManager.shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init() {}

    // MARK: - Recommendation API

    /// Get AI-powered fragrance recommendations
    func getRecommendations(
        occasion: String? = nil,
        timeOfDay: String? = nil,
        location: CLLocationCoordinate2D? = nil,
        mood: String? = nil,
        preferences: String? = nil
    ) async throws -> RecommendationResponse {
        var body: [String: Any] = [:]

        if let occasion { body["occasion"] = occasion }
        if let timeOfDay { body["time_of_day"] = timeOfDay }
        if let location {
            body["latitude"] = location.latitude
            body["longitude"] = location.longitude
        }
        if let mood { body["mood"] = mood }
        if let preferences { body["preferences"] = preferences }

        return try await callEdgeFunction(
            url: SupabaseConfig.recommendURL,
            body: body
        )
    }

    // MARK: - Natural Language Query API (Premium)

    /// Ask a natural language question about fragrances
    func askQuestion(
        query: String,
        location: CLLocationCoordinate2D? = nil,
        includeCollection: Bool = true
    ) async throws -> NLQueryResponse {
        guard authManager.isPremium else {
            throw APIError.premiumRequired
        }

        var body: [String: Any] = ["query": query]

        if let location {
            body["latitude"] = location.latitude
            body["longitude"] = location.longitude
        }
        body["include_collection"] = includeCollection

        return try await callEdgeFunction(
            url: SupabaseConfig.nlQueryURL,
            body: body
        )
    }

    // MARK: - Fragrance Search API

    /// Search for a fragrance by name
    func searchFragrance(
        query: String,
        skipExistingCheck: Bool = false
    ) async throws -> FragranceSearchResponse {
        let body: [String: Any] = [
            "query": query,
            "skip_existing_check": skipExistingCheck
        ]

        return try await callEdgeFunction(
            url: SupabaseConfig.searchFragranceURL,
            body: body
        )
    }

    // MARK: - Generate Description API

    /// Generate an AI description for a fragrance
    func generateDescription(
        fragranceId: UUID,
        forceRegenerate: Bool = false
    ) async throws -> DescriptionResponse {
        let body: [String: Any] = [
            "fragrance_id": fragranceId.uuidString,
            "force_regenerate": forceRegenerate
        ]

        return try await callEdgeFunction(
            url: SupabaseConfig.generateDescriptionURL,
            body: body
        )
    }

    // MARK: - Private Methods

    private func callEdgeFunction<T: Decodable>(
        url: String,
        body: [String: Any]
    ) async throws -> T {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = URL(string: url) else {
            throw APIError.invalidURL
        }

        // Get authorization header
        let authHeader: String
        do {
            authHeader = try await authManager.getAuthorizationHeader()
        } catch {
            throw APIError.notAuthenticated
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        // Serialize body
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.notAuthenticated
        case 403:
            throw APIError.premiumRequired
        case 429:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.rateLimitExceeded(message: errorResponse.error)
            }
            throw APIError.rateLimitExceeded(message: "Rate limit exceeded")
        case 400...499:
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.clientError(message: errorResponse.error)
            }
            throw APIError.clientError(message: "Request failed")
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.unknownError(statusCode: httpResponse.statusCode)
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
}

// MARK: - Response Models

struct RecommendationResponse: Codable {
    let recommendations: [Recommendation]?
    let summary: String?
    let message: String?
    let weather: WeatherData?
    let usage: UsageInfo?
    let rateLimit: RateLimitInfo?

    struct Recommendation: Codable, Identifiable {
        var id: String { fragranceId }
        let fragranceId: String
        let confidence: Double
        let reasoning: String
    }
}

struct NLQueryResponse: Codable {
    let answer: String
    let recommendations: [String]?
    let weather: WeatherData?
    let usage: UsageInfo?
    let rateLimit: RateLimitInfo?
}

struct FragranceSearchResponse: Codable {
    let source: String
    let fragrance: ExtractedFragrance?
    let matches: [FragranceMatch]?
    let searchUrls: SearchUrls?
    let message: String?
    let usage: UsageInfo?
    let rateLimit: RateLimitInfo?

    struct FragranceMatch: Codable, Identifiable {
        let id: UUID
        let name: String
        let brand: String
        let concentration: String?
        let aiDescription: String?
        let notesTop: [String]?
        let notesHeart: [String]?
        let notesBase: [String]?
    }

    struct SearchUrls: Codable {
        let fragrantica: String?
        let parfumo: String?
        let basenotes: String?
    }
}

struct ExtractedFragrance: Codable {
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
    var fragranticaUrl: String?
    var parfumoUrl: String?
}

struct DescriptionResponse: Codable {
    let fragranceId: UUID
    let description: String
    let generatedAt: Date?
    let cached: Bool
    let saved: Bool?
    let message: String?
    let usage: UsageInfo?
    let rateLimit: RateLimitInfo?
}

struct WeatherData: Codable {
    let temperatureF: Int
    let temperatureC: Int
    let condition: String
    let conditionCode: Int
    let humidity: Int
    let windSpeedMph: Int
    let feelsLikeF: Int
    let isDay: Bool
    let location: Location?

    struct Location: Codable {
        let city: String?
        let country: String?
    }
}

struct UsageInfo: Codable {
    let tokensInput: Int
    let tokensOutput: Int
    let costUsd: Double
}

struct RateLimitInfo: Codable {
    let remaining: Int
    let limit: Int
    let resetsAt: String
}

struct ErrorResponse: Codable {
    let error: String
    let upgradeHint: String?
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case notAuthenticated
    case premiumRequired
    case rateLimitExceeded(message: String)
    case clientError(message: String)
    case serverError
    case invalidResponse
    case decodingError
    case unknownError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .notAuthenticated:
            return "Please sign in to continue"
        case .premiumRequired:
            return "This feature requires a premium subscription"
        case .rateLimitExceeded(let message):
            return message
        case .clientError(let message):
            return message
        case .serverError:
            return "Server error. Please try again later."
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to process server response"
        case .unknownError(let statusCode):
            return "Request failed with status \(statusCode)"
        }
    }
}
