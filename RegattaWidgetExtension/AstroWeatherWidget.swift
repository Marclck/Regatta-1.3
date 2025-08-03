//
//  AstroWeatherWidget.swift
//  AstroWeatherWidget
//
//  Created by Chikai Lai on 12/07/2025.
//

import WidgetKit
import SwiftUI

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry {
        return WeatherEntry(
            date: Date(),
            currentTemp: 22,
            highTemp: 28,
            lowTemp: 18,
            weatherCondition: "sun.max.fill",
            themeColor: SharedDefaults.getTheme(),
            hasUltraAccess: getCachedUltraAccess()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> ()) {
        let entry = getWeatherEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> ()) {
        let entry = getWeatherEntry()
        
        // Create timeline with hourly updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getWeatherEntry() -> WeatherEntry {
        // Get weather data from LastReadingManager through UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.heart.astrolabe")!
        let temperature = defaults.double(forKey: "lastTemperature")
        let highTemp = defaults.double(forKey: "lastHighTemp")
        let lowTemp = defaults.double(forKey: "lastLowTemp")
        let weatherCondition = defaults.string(forKey: "lastWeatherCondition") ?? "sun.max.fill"
        let theme = SharedDefaults.getTheme()
        
        // Ensure we have valid temperature range for the gauge
        let validCurrentTemp = temperature
        let validHighTemp = highTemp
        let validLowTemp = lowTemp
        
        // Make sure low is actually lower than high
        let finalLowTemp = min(validLowTemp, validHighTemp - 1)
        let finalHighTemp = max(validHighTemp, validLowTemp + 1)
        
        return WeatherEntry(
            date: Date(),
            currentTemp: validCurrentTemp,
            highTemp: finalHighTemp,
            lowTemp: finalLowTemp,
            weatherCondition: weatherCondition,
            themeColor: theme,
            hasUltraAccess: getCachedUltraAccess()
        )
    }
    
    // Check Ultra access - only cache positive results for 5 days
    private func getCachedUltraAccess() -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.heart.astrolabe")!
        
        // Check if we have a cached POSITIVE result and if it's still valid
        if let lastCheckDate = defaults.object(forKey: "ultraAccessLastCheck") as? Date,
           defaults.bool(forKey: "cachedUltraAccess") == true {
            let daysSinceLastCheck = Calendar.current.dateComponents([.day], from: lastCheckDate, to: Date()).day ?? 0
            
            if daysSinceLastCheck < 5 {
                // Use cached positive result - user has Ultra, don't check for 5 days
                return true
            }
        }
        
        // Always perform fresh check (no positive cache or cache expired)
        let hasUltraAccess = IAPManager.shared.canAccessFeatures(minimumTier: .ultra)
        
        // Only cache positive results with timestamp
        if hasUltraAccess {
            defaults.set(true, forKey: "cachedUltraAccess")
            defaults.set(Date(), forKey: "ultraAccessLastCheck")
        } else {
            // Clear cache for negative results - always recheck
            defaults.removeObject(forKey: "cachedUltraAccess")
            defaults.removeObject(forKey: "ultraAccessLastCheck")
        }
        
        return hasUltraAccess
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
    let currentTemp: Double
    let highTemp: Double
    let lowTemp: Double
    let weatherCondition: String
    let themeColor: ColorTheme
    let hasUltraAccess: Bool
}

struct AstroWeatherWidgetEntryView: View {
    var entry: WeatherProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularWeatherView(entry: entry)
        case .accessoryCorner:
            CornerWeatherView(entry: entry)
        default:
            CircularWeatherView(entry: entry)
        }
    }
}

struct CircularWeatherView: View {
    let entry: WeatherEntry
    
    var body: some View {
        ZStack {
            if entry.hasUltraAccess {
                // Show weather content for Ultra users
                // Background gauge showing temperature range
                Gauge(value: entry.currentTemp, in: entry.lowTemp...entry.highTemp) {
                    // Weather icon as gauge label
                    Image(systemName: entry.weatherCondition)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                } currentValueLabel: {
                    // Weather SF Symbol + current temperature as the main value
                    VStack(spacing: -1) {
                        Image(systemName: entry.weatherCondition)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        Text(formatTemperature(entry.currentTemp))
                            .font(.zenithBeta(size: 18))
                            .foregroundColor(.white)
                    }
                    .offset(y:-2)
                } minimumValueLabel: {
                    // Low temperature
                    Text(formatTemperature(entry.lowTemp))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                } maximumValueLabel: {
                    // High temperature
                    Text(formatTemperature(entry.highTemp))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [
                    .white,
                    Color(hex: entry.themeColor.rawValue)
                ]))
            } else {
                // Show "Ultra Only" for non-Ultra users
                VStack(spacing: 1) {
                    Text("ULTRA")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Access")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .containerBackground(.clear, for: .widget)
    }
}

struct CornerWeatherView: View {
    let entry: WeatherEntry
    
    var body: some View {
        ZStack {
            if entry.hasUltraAccess {
                // Show weather content for Ultra users
                // Main display with weather icon and temperature
                HStack(spacing: 0) {
                    Text("\(weatherEmoji(for: entry.weatherCondition))\(formatTemperature(entry.currentTemp))")
                        .font(.zenithBeta(size: 14))
                        .foregroundColor(.white)
                }
                .widgetCurvesContent()
                .widgetLabel {
                    Gauge(value: entry.currentTemp, in: entry.lowTemp...entry.highTemp) {
                        Text("Not shown")
                    } currentValueLabel: {
                        Text("Not shown")
                    } minimumValueLabel: {
                        Text(formatTemperature(entry.lowTemp))
                    } maximumValueLabel: {
                        Text(formatTemperature(entry.highTemp))
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(Gradient(colors: [
                        .white,
                        Color(hex: entry.themeColor.rawValue)
                    ]))
                    .foregroundColor(.white)
                }
            } else {
                // Show "Ultra Only" for non-Ultra users
                VStack(spacing: 1) {
                    Text("ULTRA")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Access")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .widgetCurvesContent()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .containerBackground(.clear, for: .widget)
    }
}

// Helper function to format temperature
private func formatTemperature(_ temp: Double) -> String {
    // Show actual temperature value, even if it's 0 (freezing)
    return String(format: "%.0f", temp)
}

// Helper function to check if we have valid weather data
private func hasValidWeatherData(_ entry: WeatherEntry) -> Bool {
    // Check if we have real weather data from LastReadingManager
    let defaults = UserDefaults.standard
    let hasTemp = defaults.object(forKey: "lastTemperature") != nil
    let hasHigh = defaults.object(forKey: "lastHighTemp") != nil
    let hasLow = defaults.object(forKey: "lastLowTemp") != nil
    return hasTemp && hasHigh && hasLow
}

private func weatherEmoji(for sfSymbol: String) -> String {
    switch sfSymbol {
    // Clear conditions
    case "sun.max.fill":
        return "☀️"
    case "moon.stars.fill":
        return "🌙"
    
    // Cloudy conditions
    case "cloud.fill":
        return "☁️"
    
    // Partly cloudy conditions
    case "cloud.sun.fill":
        return "⛅"
    case "cloud.moon.fill":
        return "☁️"
    
    // Rain conditions
    case "cloud.rain.fill":
        return "🌧️"
    
    // Default fallback (should match WeatherManager default)
    default:
        return "☀️"
    }
}

struct AstroWeatherWidget: Widget {
    let kind: String = "AstroWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            AstroWeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Shows current weather conditions with temperature and forecast")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// Clean up - remove the duplicate/unused code
#Preview(as: .accessoryCircular) {
    AstroWeatherWidget()
} timeline: {
    WeatherEntry(date: .now, currentTemp: 22, highTemp: 28, lowTemp: 18, weatherCondition: "sun.max.fill", themeColor: .ultraBlue, hasUltraAccess: true)
    WeatherEntry(date: .now, currentTemp: 15, highTemp: 20, lowTemp: 12, weatherCondition: "cloud.rain.fill", themeColor: .ultraBlue, hasUltraAccess: true)
    WeatherEntry(date: .now, currentTemp: 5, highTemp: 10, lowTemp: 0, weatherCondition: "snow", themeColor: .ultraBlue, hasUltraAccess: false)
}

#Preview(as: .accessoryCorner) {
    AstroWeatherWidget()
} timeline: {
    WeatherEntry(date: .now, currentTemp: 22, highTemp: 28, lowTemp: 18, weatherCondition: "sun.max.fill", themeColor: .ultraBlue, hasUltraAccess: true)
    WeatherEntry(date: .now, currentTemp: 15, highTemp: 20, lowTemp: 12, weatherCondition: "cloud.rain.fill", themeColor: .ultraBlue, hasUltraAccess: true)
    WeatherEntry(date: .now, currentTemp: 5, highTemp: 10, lowTemp: 0, weatherCondition: "snow", themeColor: .ultraBlue, hasUltraAccess: false)
}
