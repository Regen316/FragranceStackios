# iOS App Integration Guide

This guide explains how to connect the iOS app to the Supabase backend.

## Prerequisites

- Xcode 15+
- iOS 17+ target
- Supabase project set up (see `02-supabase-setup.md`)

## Step 1: Add Supabase Swift SDK

### Using Swift Package Manager

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter the URL: `https://github.com/supabase/supabase-swift`
3. Select version `2.0.0` or later
4. Add to your target

### Verify Import

Add to any Swift file to verify:
```swift
import Supabase
```

## Step 2: Configure Supabase Credentials

Edit `/FragranceStackios/Services/SupabaseConfig.swift`:

```swift
enum SupabaseConfig {
    // Replace with your Supabase project URL
    static let projectURL = "https://xxxxx.supabase.co"

    // Replace with your anon/public key
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Where to find these values:**
1. Go to your Supabase Dashboard
2. Click **Settings** → **API**
3. Copy "Project URL" and "anon public" key

## Step 3: Initialize Services

The app uses three main services:

### AuthManager
Handles authentication state and user sessions.

```swift
// Check if user is signed in on app launch
@main
struct FragranceStackiosApp: App {
    init() {
        Task {
            await AuthManager.shared.checkSession()
        }
    }
}
```

### FragranceAPIService
Calls Edge Functions for AI features.

```swift
// Get recommendations
let response = try await FragranceAPIService.shared.getRecommendations(
    occasion: "date",
    timeOfDay: "evening",
    location: userLocation
)
```

### SupabaseDataService
Syncs data with the database.

```swift
// Fetch user's collection
let collection = try await SupabaseDataService.shared.fetchUserCollection()
```

## Step 4: Add Authentication UI

### Sign In View

```swift
struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .disabled(isLoading)
        }
        .padding()
    }

    func signIn() {
        isLoading = true
        error = nil

        Task {
            do {
                try await AuthManager.shared.signIn(
                    email: email,
                    password: password
                )
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

### Sign in with Apple

```swift
import AuthenticationServices

struct AppleSignInButton: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    Task {
                        try await AuthManager.shared.signInWithApple(credential: credential)
                    }
                }
            case .failure(let error):
                print("Apple sign in failed: \(error)")
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
    }
}
```

## Step 5: Use AI Features

### Get Recommendations

```swift
struct RecommenderView: View {
    @State private var recommendations: [RecommendationResponse.Recommendation] = []
    @State private var isLoading = false

    func fetchRecommendations() async {
        isLoading = true

        do {
            let response = try await FragranceAPIService.shared.getRecommendations(
                occasion: "casual",
                timeOfDay: "afternoon"
            )

            recommendations = response.recommendations ?? []
        } catch {
            print("Error: \(error)")
        }

        isLoading = false
    }
}
```

### Natural Language Query (Premium)

```swift
func askQuestion(_ query: String) async throws -> String {
    let response = try await FragranceAPIService.shared.askQuestion(
        query: query,
        location: locationManager.location?.coordinate
    )
    return response.answer
}
```

### Search for New Fragrance

```swift
func searchFragrance(_ name: String) async throws -> ExtractedFragrance? {
    let response = try await FragranceAPIService.shared.searchFragrance(query: name)
    return response.fragrance
}
```

## Step 6: Sync Data

### Fetch User Collection

```swift
@Observable
class CollectionViewModel {
    var fragrances: [UserFragranceWithDetails] = []
    var isLoading = false

    func fetchCollection() async {
        isLoading = true

        do {
            fragrances = try await SupabaseDataService.shared.fetchUserCollection()
        } catch {
            print("Error fetching collection: \(error)")
        }

        isLoading = false
    }
}
```

### Add to Collection

```swift
func addToCollection(fragrance: RemoteFragrance) async throws {
    let request = AddToCollectionRequest(
        fragranceId: fragrance.id,
        purchaseDate: Date(),
        purchasePrice: nil
    )

    try await SupabaseDataService.shared.addToCollection(request)
}
```

### Log a Wear

```swift
func logWear(fragranceId: UUID) async throws {
    let request = CreateWearLogRequest(
        fragranceId: fragranceId,
        dateWorn: Date(),
        timeOfDay: "evening",
        occasion: "date"
    )

    try await SupabaseDataService.shared.createWearLog(request)
}
```

## Step 7: Handle Premium Features

### Check Premium Status

```swift
struct PremiumFeatureView: View {
    var body: some View {
        Group {
            if AuthManager.shared.isPremium {
                NLQueryView()
            } else {
                UpgradePromptView()
            }
        }
    }
}
```

### Show Rate Limit Info

```swift
struct UsageIndicatorView: View {
    @State private var usage: UsageStats?

    var body: some View {
        if let usage {
            VStack {
                Text("\(usage.dailyAiRemaining) AI requests remaining today")
                Text("\(usage.monthlySearchRemaining) searches remaining this month")
            }
        }
    }

    func fetchUsage() async {
        usage = try? await SupabaseDataService.shared.fetchUsageStats()
    }
}
```

## Error Handling

### API Errors

```swift
do {
    let response = try await FragranceAPIService.shared.getRecommendations()
} catch APIError.notAuthenticated {
    // Redirect to sign in
} catch APIError.premiumRequired {
    // Show upgrade prompt
} catch APIError.rateLimitExceeded(let message) {
    // Show rate limit message
} catch {
    // Generic error handling
}
```

### Network Errors

```swift
do {
    try await SupabaseDataService.shared.fetchUserCollection()
} catch {
    if (error as NSError).domain == NSURLErrorDomain {
        // Network error - show offline message
    }
}
```

## Offline Support

The app uses SwiftData for local storage. To sync:

1. On app launch, fetch from Supabase
2. Update local SwiftData models
3. Use local data for display
4. Sync changes back to Supabase

```swift
func syncCollection() async {
    // Fetch from server
    let remoteCollection = try await SupabaseDataService.shared.fetchUserCollection()

    // Update local SwiftData
    for remote in remoteCollection {
        if let local = localFragrances.first(where: { $0.id == remote.fragranceId }) {
            // Update existing
            local.timesWorn = remote.timesWorn
        } else {
            // Create new
            let newLocal = Fragrance(from: remote)
            modelContext.insert(newLocal)
        }
    }
}
```

## Testing

### Mock Services for Previews

```swift
#Preview {
    RecommenderView()
        .environment(MockFragranceAPIService())
}
```

### Test with Supabase Local

1. Install Supabase CLI
2. Run `supabase start`
3. Update `SupabaseConfig.swift` to use local URL

## Troubleshooting

### "Unauthorized" Errors
- Check that the anon key is correct
- Verify the user's JWT token is valid
- Check RLS policies in Supabase

### "Rate limit exceeded"
- Check user's tier
- Wait for rate limit to reset
- Consider upgrading to premium

### Edge Function Not Found
- Verify function is deployed
- Check function name spelling
- Ensure JWT verification is enabled

### Network Timeouts
- Check internet connection
- Verify Supabase project is not paused
- Try increasing timeout in URLSession
