//
//  SignInView.swift
//  FragranceStackios
//
//  Sign in and sign up view for authentication
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Header
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.appAccent)

                        Text("FragranceStack")
                            .font(.appTitle())
                            .foregroundStyle(Color.appPrimary)

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.appSubheadline())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Form fields
                    VStack(spacing: 16) {
                        if isSignUp {
                            TextField("Display Name", text: $displayName)
                                .textContentType(.name)
                                #if os(iOS)
                                .autocorrectionDisabled()
                                #endif
                                .padding()
                                .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            #if os(iOS)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            #endif
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Sign in/up button
                    Button(action: handleEmailAuth) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Toggle sign in/up
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.callout)
                            .foregroundStyle(Color.appAccent)
                    }
                        .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.visible)
            .background(Color.appBackground)
        }
    }

    private func handleEmailAuth() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await AuthManager.shared.signUp(
                        email: email,
                        password: password,
                        displayName: displayName.isEmpty ? nil : displayName
                    )
                } else {
                    try await AuthManager.shared.signIn(
                        email: email,
                        password: password
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                isLoading = true
                errorMessage = nil

                Task {
                    do {
                        try await AuthManager.shared.signInWithApple(credential: credential)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
}
