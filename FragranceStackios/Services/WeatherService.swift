//
//  WeatherService.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import Foundation
import SwiftUI

/// Simple weather service for MVP - returns mock data
/// TODO: Integrate WeatherKit when capabilities are configured
@Observable
class WeatherService {

    var temperature: Double?
    var condition: String?
    var humidity: Double?
    var errorMessage: String?
    var isLoading = false

    /// Fetch current weather (mock implementation for MVP)
    func getCurrentWeather() async throws {
        isLoading = true

        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Return mock data
        temperature = 22.0 // 72°F
        condition = "Sunny"
        humidity = 45.0

        isLoading = false
    }

    /// Manually set weather (for testing or manual input)
    func setManualWeather(temperature: Double, condition: String, humidity: Double) {
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
    }
}
