//
//  CollectionView.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var context
    @Query private var fragrances: [Fragrance]

    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var isGridView = true
    @State private var selectedSort: SortOption = .name
    @State private var showSignatureOnly = false

    // MARK: - Computed Properties

    var filteredAndSortedFragrances: [Fragrance] {
        var filtered = fragrances

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { fragrance in
                fragrance.name.localizedCaseInsensitiveContains(searchText) ||
                fragrance.brand.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply signature filter
        if showSignatureOnly {
            filtered = filtered.filter { fragrance in
                fragrance.userFragrances.contains { $0.isSignature }
            }
        }

        // Apply sorting
        switch selectedSort {
        case .name:
            return filtered.sorted { $0.name < $1.name }
        case .brand:
            return filtered.sorted { $0.brand < $1.brand }
        case .rating:
            return filtered.sorted { fragrance1, fragrance2 in
                let rating1 = fragrance1.userFragrances.first?.personalRating ?? 0
                let rating2 = fragrance2.userFragrances.first?.personalRating ?? 0
                return rating1 > rating2
            }
        case .timesWorn:
            return filtered.sorted { fragrance1, fragrance2 in
                let times1 = fragrance1.userFragrances.first?.timesWorn ?? 0
                let times2 = fragrance2.userFragrances.first?.timesWorn ?? 0
                return times1 > times2
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search fragrances", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.appCream)
                .cornerRadius(8)
                .padding(16)

                // Filter and sort controls
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // View toggle
                        Button(action: { isGridView.toggle() }) {
                            Image(systemName: isGridView ? "square.grid.2x2.fill" : "list.bullet")
                                .foregroundColor(isGridView ? .appGold : .gray)
                                .padding(8)
                        }

                        // Signature filter chip
                        Button(action: { showSignatureOnly.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("Signatures")
                            }
                            .font(.appCaption())
                            .foregroundColor(showSignatureOnly ? .white : .appNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(showSignatureOnly ? Color.appGold : Color.gray.opacity(0.15))
                            .cornerRadius(6)
                        }

                        // Sort options
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { selectedSort = option }) {
                                    HStack {
                                        Text(option.label)
                                        if selectedSort == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(selectedSort.label)
                            }
                            .font(.appCaption())
                            .foregroundColor(.appNavy)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(6)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)

                // Content
                if filteredAndSortedFragrances.isEmpty {
                    EmptyStateView(
                        icon: "bottle.2",
                        title: "No Fragrances",
                        message: searchText.isEmpty && !showSignatureOnly
                            ? "Start building your collection by adding fragrances"
                            : "No fragrances match your filters"
                    )
                    .frame(maxHeight: .infinity)
                } else if isGridView {
                    gridView
                } else {
                    listView
                }

                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle("My Collection")
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    return .topBarTrailing
                    #else
                    return .primaryAction
                    #endif
                }()) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appGold)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddFragranceView()
            }
        }
    }

    // MARK: - Grid View

    @ViewBuilder
    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(filteredAndSortedFragrances) { fragrance in
                    NavigationLink(value: fragrance) {
                        FragranceCard(fragrance: fragrance)
                    }
                }
            }
            .padding(16)
            .navigationDestination(for: Fragrance.self) { fragrance in
                FragranceDetailView(fragrance: fragrance)
            }
        }
    }

    // MARK: - List View

    @ViewBuilder
    private var listView: some View {
        List(filteredAndSortedFragrances) { fragrance in
            NavigationLink(value: fragrance) {
                HStack(spacing: 12) {
                    // Placeholder image
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCream)
                        .frame(width: 60, height: 80)
                        .overlay(
                            Image(systemName: "bottle.2")
                                .foregroundColor(.gray)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fragrance.name)
                            .font(.appSubheadline())
                            .foregroundColor(.appNavy)

                        Text(fragrance.brand)
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            if let userFrag = fragrance.userFragrances.first {
                                if let rating = userFrag.personalRating {
                                    StarRatingView(rating: rating)
                                }

                                if userFrag.isSignature {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.appGold)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(fragrance.concentration.rawValue)
                            .font(.appCaption())
                            .foregroundColor(.gray)

                        Text(fragrance.fragranceFamily.rawValue)
                            .font(.appCaption())
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationDestination(for: Fragrance.self) { fragrance in
                FragranceDetailView(fragrance: fragrance)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Sort Option Enum

enum SortOption: String, CaseIterable {
    case name = "Name"
    case brand = "Brand"
    case rating = "Rating"
    case timesWorn = "Times Worn"

    var label: String {
        self.rawValue
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    // Sample fragrance
    let fragrance1 = Fragrance(
        name: "Aventus",
        brand: "Creed",
        concentration: .edp,
        fragranceFamily: .fresh
    )
    let fragrance2 = Fragrance(
        name: "Sauvage",
        brand: "Dior",
        concentration: .edt,
        fragranceFamily: .aromatic
    )
    let fragrance3 = Fragrance(
        name: "Bleu de Chanel",
        brand: "Chanel",
        concentration: .edp,
        fragranceFamily: .woody
    )

    container.mainContext.insert(fragrance1)
    container.mainContext.insert(fragrance2)
    container.mainContext.insert(fragrance3)

    return CollectionView()
        .modelContainer(container)
}
