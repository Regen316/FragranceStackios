import Foundation
import Supabase
import AuthenticationServices

/// Manages user authentication with Supabase
@MainActor
@Observable
final class AuthManager {
    // MARK: - Singleton

    static let shared = AuthManager()

    // MARK: - Properties

    /// Current authenticated user
    private(set) var currentUser: User?

    /// Current user's profile
    private(set) var profile: UserProfile?

    /// Whether the user is authenticated
    var isAuthenticated: Bool { currentUser != nil }

    /// Whether the user has premium access
    var isPremium: Bool {
        guard let tier = profile?.tier else { return false }
        return tier == "premium" || tier == "admin"
    }

    /// Whether the user is an admin
    var isAdmin: Bool { profile?.tier == "admin" }

    /// Loading state
    private(set) var isLoading = false

    /// Error message
    private(set) var errorMessage: String?

    /// Supabase client
    private let supabase: SupabaseClient

    // MARK: - Initialization

    private init() {
        // Initialize Supabase client
        supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey
        )

        // Start listening for auth changes
        Task {
            await listenForAuthChanges()
        }
    }

    // MARK: - Auth State Listener

    private func listenForAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn, .tokenRefreshed:
                currentUser = session?.user
                if let userId = session?.user.id {
                    await fetchProfile(userId: userId)
                }
            case .signedOut:
                currentUser = nil
                profile = nil
            default:
                break
            }
        }
    }

    // MARK: - Session Management

    /// Check for existing session on app launch
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            await fetchProfile(userId: session.user.id)
        } catch {
            // No session exists, user needs to sign in
            currentUser = nil
            profile = nil
        }
    }

    // MARK: - Email Authentication

    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: displayName != nil ? ["full_name": .string(displayName!)] : nil
            )
            currentUser = response.user
            await fetchProfile(userId: response.user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            await fetchProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Sign out
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            profile = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Apple Sign In

    /// Handle Sign in with Apple credential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
            currentUser = session.user
            await fetchProfile(userId: session.user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Profile Management

    /// Fetch user profile from database
    private func fetchProfile(userId: UUID) async {
        do {
            let fetchedProfile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            profile = fetchedProfile
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }

    /// Update user profile
    func updateProfile(displayName: String? = nil) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        var updates: [String: AnyJSON] = [:]
        if let displayName {
            updates["display_name"] = .string(displayName)
        }

        try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()

        await fetchProfile(userId: userId)
    }

    // MARK: - Access Token

    /// Get current access token for API calls
    func getAccessToken() async throws -> String {
        let session = try await supabase.auth.session
        return session.accessToken
    }

    /// Get authorization header for API calls
    func getAuthorizationHeader() async throws -> String {
        let token = try await getAccessToken()
        return "Bearer \(token)"
    }
}

// MARK: - Error Types

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credential"
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        }
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    var displayName: String?
    var tier: String
    var fragranceLimit: Int
    var dailyAiLimit: Int
    var monthlySearchLimit: Int
    var totalCostUsd: Double
    let createdAt: Date
    var lastActiveAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, tier
        case displayName = "display_name"
        case fragranceLimit = "fragrance_limit"
        case dailyAiLimit = "daily_ai_limit"
        case monthlySearchLimit = "monthly_search_limit"
        case totalCostUsd = "total_cost_usd"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
    }
}
