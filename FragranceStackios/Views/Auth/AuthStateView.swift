//
//  AuthStateView.swift
//  FragranceStackios
//
//  Root view that shows sign in or main app based on auth state
//

import SwiftUI

struct AuthStateView: View {
    @State private var authManager = AuthManager.shared
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                // Loading state while checking session
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground)
            } else if authManager.isAuthenticated {
                // User is signed in - show main app
                MainTabView()
            } else {
                // User is not signed in - show sign in
                SignInView()
            }
        }
        .task {
            await authManager.checkSession()
            isCheckingSession = false
        }
    }
}

#Preview {
    AuthStateView()
}
