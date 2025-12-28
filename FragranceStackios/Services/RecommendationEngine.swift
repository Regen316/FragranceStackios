//
//  RecommendationEngine.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftData

/// The brain of FragranceStack - generates personalized fragrance recommendations
/// based on occasion, season, time of day, and user preferences.
///
/// Algorithm: Score = (Season_Match × 0.3) + (Occasion_Match × 0.3) +
///                    (Performance_Score × 0.2) + (User_Preference × 0.2)
class RecommendationEngine {

    // MARK: - Constants

    /// Maximum possible score a fragrance can achieve
    private let maxPossibleScore: Double = 1.0

    /// Number of recommendations to return
    private let recommendationCount: Int = 5

    /// Minimum score threshold for recommendations (0-1 scale)
    private let minimumScoreThreshold: Double = 0.2

    // MARK: - Scoring Weights

    private struct Weights {
        static let season: Double = 0.3
        static let occasion: Double = 0.3
        static let performance: Double = 0.2
        static let userPreference: Double = 0.2
    }

    // MARK: - Public Methods

    /// Generates personalized fragrance recommendations based on context
    ///
    /// - Parameters:
    ///   - occasion: The occasion for which to recommend fragrances
    ///   - season: Optional season (defaults to current season inferred from date)
    ///   - timeOfDay: The time of day for the recommendation
    ///   - context: SwiftData model context for database operations
    /// - Returns: Array of Recommendation objects, sorted by confidence score (descending)
    func generate(
        occasion: Occasion,
        season: Season? = nil,
        timeOfDay: TimeOfDay,
        context: ModelContext
    ) async -> [Recommendation] {
        // Infer season from current date if not provided
        let targetSeason = season ?? inferSeason()

        // Fetch all fragrances with their relationships
        let descriptor = FetchDescriptor<Fragrance>(
            sortBy: [SortDescriptor(\.name)]
        )

        guard let fragrances = try? context.fetch(descriptor) else {
            print("⚠️ RecommendationEngine: Failed to fetch fragrances")
            return []
        }

        // Handle edge case: no fragrances in database
        guard !fragrances.isEmpty else {
            print("⚠️ RecommendationEngine: No fragrances available for recommendations")
            return []
        }

        // Score each fragrance
        var scoredFragrances: [(fragrance: Fragrance, score: Double)] = []

        for fragrance in fragrances {
            // Skip fragrances without metrics
            guard fragrance.metrics != nil else {
                continue
            }

            let score = calculateScore(
                fragrance: fragrance,
                occasion: occasion,
                season: targetSeason,
                context: context
            )

            // Only include fragrances above minimum threshold
            if score >= minimumScoreThreshold {
                scoredFragrances.append((fragrance, score))
            }
        }

        // Handle edge case: no fragrances meet threshold
        guard !scoredFragrances.isEmpty else {
            print("⚠️ RecommendationEngine: No fragrances meet minimum score threshold")
            return []
        }

        // Sort by score (descending) and take top N
        let topFragrances = scoredFragrances
            .sorted { $0.score > $1.score }
            .prefix(recommendationCount)

        // Create Recommendation objects
        var recommendations: [Recommendation] = []

        for (fragrance, score) in topFragrances {
            // Convert score to confidence percentage (0-100)
            let confidenceScore = (score / maxPossibleScore) * 100

            let recommendation = Recommendation(
                fragrance: fragrance,
                occasion: occasion,
                weather: nil, // Can be enhanced with weather API
                temperature: nil, // Can be enhanced with weather API
                timeOfDay: timeOfDay,
                confidenceScore: confidenceScore
            )

            // Insert into context
            context.insert(recommendation)
            recommendations.append(recommendation)
        }

        // Save recommendations to database
        do {
            try context.save()
            print("✅ RecommendationEngine: Generated \(recommendations.count) recommendations")
        } catch {
            print("❌ RecommendationEngine: Failed to save recommendations: \(error)")
        }

        return recommendations
    }

    // MARK: - Helper Methods

    /// Infers the current season based on the current month
    ///
    /// - Returns: The inferred season
    func inferSeason() -> Season {
        let currentMonth = Calendar.current.component(.month, from: Date())

        switch currentMonth {
        case 3, 4, 5:
            return .spring
        case 6, 7, 8:
            return .summer
        case 9, 10, 11:
            return .fall
        case 12, 1, 2:
            return .winter
        default:
            // Fallback (should never happen)
            return .spring
        }
    }

    /// Calculates a comprehensive score for a fragrance based on multiple factors
    ///
    /// Algorithm: Score = (Season_Match × 0.3) + (Occasion_Match × 0.3) +
    ///                    (Performance_Score × 0.2) + (User_Preference × 0.2)
    ///
    /// - Parameters:
    ///   - fragrance: The fragrance to score
    ///   - occasion: Target occasion
    ///   - season: Target season
    ///   - context: SwiftData context for fetching user data
    /// - Returns: Normalized score between 0.0 and 1.0
    func calculateScore(
        fragrance: Fragrance,
        occasion: Occasion,
        season: Season,
        context: ModelContext
    ) -> Double {
        // Safety check: ensure metrics exist
        guard let metrics = fragrance.metrics else {
            return 0.0
        }

        // 1. Season Match Component (normalized to 0-1)
        let seasonRawScore = Double(metrics.seasonScore(for: season))
        let seasonNormalized = seasonRawScore / 10.0
        let seasonComponent = seasonNormalized * Weights.season

        // 2. Occasion Match Component (normalized to 0-1)
        let occasionRawScore = Double(metrics.occasionScore(for: occasion))
        let occasionNormalized = occasionRawScore / 10.0
        let occasionComponent = occasionNormalized * Weights.occasion

        // 3. Performance Score Component (normalized to 0-1)
        let performanceRawScore = metrics.performanceScore
        let performanceNormalized = performanceRawScore / 10.0
        let performanceComponent = performanceNormalized * Weights.performance

        // 4. User Preference Component (normalized to 0-1)
        let userPreferenceNormalized = getUserPreferenceScore(
            fragrance: fragrance,
            metrics: metrics,
            context: context
        )
        let userPreferenceComponent = userPreferenceNormalized * Weights.userPreference

        // Calculate total score
        let totalScore = seasonComponent +
                        occasionComponent +
                        performanceComponent +
                        userPreferenceComponent

        // Ensure score is within valid range
        return min(max(totalScore, 0.0), maxPossibleScore)
    }

    /// Gets the user preference score for a fragrance
    ///
    /// Uses personal rating if available, otherwise falls back to community average rating
    ///
    /// - Parameters:
    ///   - fragrance: The fragrance to evaluate
    ///   - metrics: The fragrance's metrics
    ///   - context: SwiftData context for fetching user data
    /// - Returns: Normalized score between 0.0 and 1.0
    private func getUserPreferenceScore(
        fragrance: Fragrance,
        metrics: FragranceMetrics,
        context: ModelContext
    ) -> Double {
        // Try to find user's personal rating
        if let userFragrance = fragrance.userFragrances.first {
            if let personalRating = userFragrance.personalRating {
                // User has rated this fragrance - use their rating
                return Double(personalRating) / 5.0
            }
        }

        // No personal rating - use community average
        // Handle edge case: no reviews yet
        if metrics.reviewCount == 0 || metrics.averageRating == 0.0 {
            // Return neutral score for unrated fragrances
            return 0.5
        }

        return metrics.averageRating / 5.0
    }

    // MARK: - Advanced Features (Future Enhancements)

    /// Applies bonus points for signature fragrances and favorites
    ///
    /// This can be integrated into the scoring algorithm for personalization
    ///
    /// - Parameter fragrance: The fragrance to evaluate
    /// - Returns: Bonus multiplier (1.0 = no bonus, >1.0 = boosted)
    private func getPersonalizationBonus(fragrance: Fragrance) -> Double {
        var bonus: Double = 1.0

        if let userFragrance = fragrance.userFragrances.first {
            // Boost signature fragrances
            if userFragrance.isSignature {
                bonus *= 1.15 // 15% boost
            }

            // Boost favorites
            if userFragrance.isFavorite {
                bonus *= 1.1 // 10% boost
            }

            // Small boost for frequently worn fragrances
            if userFragrance.timesWorn > 10 {
                bonus *= 1.05 // 5% boost
            }
        }

        return bonus
    }

    /// Applies diversity penalty to avoid recommending too similar fragrances
    ///
    /// Future enhancement: penalize fragrances from same family or brand
    ///
    /// - Parameters:
    ///   - fragrance: The fragrance to evaluate
    ///   - alreadyRecommended: Array of already recommended fragrances
    /// - Returns: Penalty multiplier (1.0 = no penalty, <1.0 = penalized)
    private func getDiversityPenalty(
        fragrance: Fragrance,
        alreadyRecommended: [Fragrance]
    ) -> Double {
        var penalty: Double = 1.0

        for recommended in alreadyRecommended {
            // Penalize same brand
            if fragrance.brand == recommended.brand {
                penalty *= 0.9
            }

            // Penalize same fragrance family
            if fragrance.fragranceFamily == recommended.fragranceFamily {
                penalty *= 0.95
            }
        }

        return penalty
    }
}

// MARK: - Recommendation Extensions

extension RecommendationEngine {

    /// Generates quick recommendations for common scenarios
    ///
    /// - Parameters:
    ///   - scenario: Predefined scenario name
    ///   - context: SwiftData model context
    /// - Returns: Array of recommendations
    func generateForScenario(
        _ scenario: RecommendationScenario,
        context: ModelContext
    ) async -> [Recommendation] {
        return await generate(
            occasion: scenario.occasion,
            season: scenario.season,
            timeOfDay: scenario.timeOfDay,
            context: context
        )
    }
}

// MARK: - Recommendation Scenarios

/// Predefined recommendation scenarios for common use cases
enum RecommendationScenario {
    case workMorning
    case dateNight
    case casualWeekend
    case formalEvent
    case nightOut

    var occasion: Occasion {
        switch self {
        case .workMorning: return .office
        case .dateNight: return .date
        case .casualWeekend: return .casual
        case .formalEvent: return .formal
        case .nightOut: return .club
        }
    }

    var timeOfDay: TimeOfDay {
        switch self {
        case .workMorning: return .morning
        case .dateNight: return .evening
        case .casualWeekend: return .afternoon
        case .formalEvent: return .evening
        case .nightOut: return .night
        }
    }

    var season: Season? {
        // Use current season for all scenarios
        return nil
    }
}
