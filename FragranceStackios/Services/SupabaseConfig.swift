import Foundation

/// Configuration for Supabase connection
/// IMPORTANT: Replace these values with your actual Supabase project credentials
enum SupabaseConfig {
    // MARK: - Supabase Credentials
    // Get these from your Supabase project settings: Settings > API

    /// Your Supabase project URL (e.g., "https://xxxxx.supabase.co")
    static let projectURL = "YOUR_SUPABASE_PROJECT_URL"

    /// Your Supabase anon/public key
    /// This key is safe to include in the app - RLS protects your data
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"

    // MARK: - Edge Function URLs
    // These are automatically derived from your project URL

    /// Base URL for Edge Functions
    static var functionsURL: String {
        projectURL.replacingOccurrences(of: ".supabase.co", with: ".supabase.co/functions/v1")
    }

    /// Recommendation endpoint
    static var recommendURL: String { "\(functionsURL)/recommend" }

    /// Natural language query endpoint (premium)
    static var nlQueryURL: String { "\(functionsURL)/nl-query" }

    /// Fragrance search endpoint
    static var searchFragranceURL: String { "\(functionsURL)/search-fragrance" }

    /// Generate description endpoint
    static var generateDescriptionURL: String { "\(functionsURL)/generate-description" }

    // MARK: - Validation

    /// Check if configuration is properly set up
    static var isConfigured: Bool {
        projectURL != "YOUR_SUPABASE_PROJECT_URL" &&
        anonKey != "YOUR_SUPABASE_ANON_KEY" &&
        projectURL.contains("supabase.co")
    }

    /// Validate configuration and throw if invalid
    static func validate() throws {
        guard isConfigured else {
            throw SupabaseConfigError.notConfigured
        }
    }
}

enum SupabaseConfigError: Error, LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please update SupabaseConfig.swift with your project credentials."
        }
    }
}
