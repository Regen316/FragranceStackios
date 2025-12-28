//
//  MainTabView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            CollectionPlaceholder()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }

            RecommenderPlaceholder()
                .tabItem {
                    Label("Recommend", systemImage: "sparkles")
                }

            LayeringLabPlaceholder()
                .tabItem {
                    Label("Layering", systemImage: "square.stack.3d.up.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.appGold)
    }
}

// MARK: - Placeholder Views

struct DashboardPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appGold)

                Text("Dashboard")
                    .font(.appTitle())
                    .foregroundColor(.appNavy)

                Text("Coming soon")
                    .font(.appBody())
                    .foregroundColor(.gray)
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct CollectionPlaceholder: View {
    var body: some View {
        CollectionView()
    }
}

struct RecommenderPlaceholder: View {
    var body: some View {
        ContextSelectionView()
    }
}

struct LayeringLabPlaceholder: View {
    var body: some View {
        LayeringLabContainerView()
    }
}

// MARK: - Layering Lab Container

struct LayeringLabContainerView: View {
    @State private var selectedTab: LayeringLabTab = .browse

    enum LayeringLabTab {
        case browse
        case calculator
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Layering Lab", selection: $selectedTab) {
                    Text("Browse").tag(LayeringLabTab.browse)
                    Text("Calculator").tag(LayeringLabTab.calculator)
                }
                .pickerStyle(.segmented)
                .padding(16)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                // Tab Content
                if selectedTab == .browse {
                    LayeringLabView()
                } else {
                    LayeringCalculatorView()
                }
            }
            .navigationTitle("Layering Lab")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.appBackground)
        }
    }
}

struct ProfilePlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appGold)

                Text("Profile")
                    .font(.appTitle())
                    .foregroundColor(.appNavy)

                Text("Coming soon")
                    .font(.appBody())
                    .foregroundColor(.gray)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
}
