//
//  FragranceCard.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI
import SwiftData

struct FragranceCard: View {
    let fragrance: Fragrance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bottle image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCream)

                VStack {
                    Image(systemName: "bottle.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                }
                .frame(maxHeight: .infinity)

                // Signature badge
                if let userFrag = fragrance.userFragrances.first, userFrag.isSignature {
                    VStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appGold)
                                .font(.system(size: 12))

                            Spacer()
                        }

                        Spacer()
                    }
                    .padding(8)
                }
            }
            .frame(height: 160)
            .fragranceCardStyle()

            // Brand and name
            VStack(alignment: .leading, spacing: 2) {
                Text(fragrance.brand)
                    .font(.appCaption())
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Text(fragrance.name)
                    .font(.appSubheadline())
                    .foregroundColor(.appNavy)
                    .lineLimit(2)
            }

            // Rating if available
            if let userFrag = fragrance.userFragrances.first {
                if let rating = userFrag.personalRating {
                    StarRatingView(rating: rating)
                }

                // Season/occasion badges
                HStack(spacing: 4) {
                    Group {
                        if let metrics = fragrance.metrics {
                            // Show best seasons
                            if metrics.seasonSummer >= 7 {
                                Text("Summer")
                                    .badgeStyle(color: .blue.opacity(0.6))
                            } else if metrics.seasonWinter >= 7 {
                                Text("Winter")
                                    .badgeStyle(color: .blue.opacity(0.6))
                            }
                        }
                    }

                    Spacer()
                }
                .font(.system(size: 10, weight: .medium))
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Fragrance.self, configurations: config)

    let fragrance = Fragrance(
        name: "Aventus",
        brand: "Creed",
        concentration: .edp,
        fragranceFamily: .fresh
    )

    let metrics = FragranceMetrics(
        longevityHours: 8.0,
        projection: 8,
        sillage: 8,
        seasonSpring: 6,
        seasonSummer: 8,
        seasonFall: 7,
        seasonWinter: 5,
        occasionOffice: 9,
        occasionDate: 8,
        occasionCasual: 7,
        occasionFormal: 6,
        occasionClub: 5
    )
    fragrance.metrics = metrics

    let userFrag = UserFragrance(fragrance: fragrance, personalRating: 5, isSignature: true)
    fragrance.userFragrances = [userFrag]

    container.mainContext.insert(fragrance)

    return FragranceCard(fragrance: fragrance)
        .modelContainer(container)
        .padding(16)
        .background(Color.appBackground)
}
