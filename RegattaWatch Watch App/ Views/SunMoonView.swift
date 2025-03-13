//
//  SunMoonView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 08/03/2025.
//

import SwiftUI
import WeatherKit

struct SunMoonView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @StateObject private var weatherManager = WeatherManager()
    
    // Timer for continuous updates of sun/moon position
    @State private var currentDate = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // Animation states for radial gradient
    @State private var animationScale: CGFloat = 0
    
    // Date formatter for next event time
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private var isDaytime: Bool {
        guard let sunrise = weatherManager.nauticalSunrise,
              let sunset = weatherManager.nauticalSunset else {
            return true
        }
        return currentDate >= sunrise && currentDate <= sunset
    }
    
    private var nextEvent: (type: SunEvent, time: Date)? {
        guard let sunrise = weatherManager.nauticalSunrise,
              let sunset = weatherManager.nauticalSunset else {
            return nil
        }
        
        if currentDate < sunrise {
            return (.sunrise, sunrise)
        } else if currentDate < sunset {
            return (.sunset, sunset)
        } else {
            // Get next day's sunrise
            let calendar = Calendar.current
            if let nextSunrise = calendar.date(byAdding: .day, value: 1, to: sunrise) {
                return (.sunrise, nextSunrise)
            } else {
                return (.sunrise, sunrise) // Fallback
            }
        }
    }
    
    private enum SunEvent {
        case sunrise, sunset
    }
    
    private func angleForTime(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double(components.hour ?? 0) * 60 + Double(components.minute ?? 0)
        return (totalMinutes / (24 * 60)) * 360 + 90 // -90 to start at top (12 o'clock position)
    }
    
    private func pointOnCircle(angle: Double, radius: CGFloat) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: cos(radians) * radius,
            y: sin(radians) * radius
        )
    }
    
    var body: some View {
        ZStack {
            // Background circle with theme color
            Circle()
                .fill(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3))
                .frame(width: 50, height: 50)
            
            if !isLuminanceReduced {
                // Radial gradient when in day mode
                if isDaytime {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.6),
                                    Color(hex: colorManager.selectedTheme.rawValue).opacity(0.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 25 * animationScale
                            )
                        )
                        .frame(width: 50, height: 50)
                }
            }
            
            // Time markers circle
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                let radius: CGFloat = 20
                
                ZStack {
                    // Current time indicator
                    let currentAngle = angleForTime(currentDate)
                    let point = pointOnCircle(angle: currentAngle, radius: radius)
                    
                    if isDaytime {
                        // Sun indicator
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                            .position(x: center.x + point.x, y: center.y + point.y)
                    } else {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 5, height: 5)
                            .position(x: center.x + point.x, y: center.y + point.y)
/*
                        // Moon phase
                        MoonPhaseView(phase: weatherManager.moonPhase)
                            .frame(width: 8, height: 8)
                            .position(x: center.x + point.x, y: center.y + point.y)
 */
                    }
                    
                    // Sunrise/sunset markers
                    if let sunrise = weatherManager.nauticalSunrise,
                       let sunset = weatherManager.nauticalSunset {
                        let sunriseAngle = angleForTime(sunrise)
                        let sunsetAngle = angleForTime(sunset)
                        
                        // Sunrise marker
                        Circle()
                            .fill(settings.lightMode ? .black : .white)
                            .frame(width: 3, height: 3)
                            .position(
                                x: center.x + pointOnCircle(angle: sunriseAngle, radius: radius).x,
                                y: center.y + pointOnCircle(angle: sunriseAngle, radius: radius).y
                            )
                        
                        // Sunset marker
                        Circle()
                            .fill(settings.lightMode ? .black : .white)
                            .frame(width: 3, height: 3)
                            .position(
                                x: center.x + pointOnCircle(angle: sunsetAngle, radius: radius).x,
                                y: center.y + pointOnCircle(angle: sunsetAngle, radius: radius).y
                            )
                    }
                }
            }
            .frame(width: 50, height: 50)
            
            // Next event information
            VStack(spacing: 0) {
                if let next = nextEvent {
                    Image(systemName: next.type == .sunrise ? "sunrise.fill" : "sunset.fill")
                        .font(.system(size: 8, weight: .heavy))
                        .symbolVariant(.fill)
                        .foregroundColor(settings.lightMode ? .black.opacity(0.4) : .white.opacity(0.4))
                        .offset(y: -2)
                    
                    Text(timeFormatter.string(from: next.time))
                        .font(.zenithBeta(size: 10, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y: 0)
                    
                    Text(next.type == .sunrise ? "rise" : "set")
                        .font(.zenithBeta(size: 10, weight: .medium))
                        .foregroundColor(settings.lightMode ? .black : .white)
                        .offset(y: 1)
                }
            }
        }
        .onAppear {
            startRadialAnimation()
        }
        .onChange(of: isLuminanceReduced) { newValue in
            if !newValue {
                startRadialAnimation()
            }
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private func startRadialAnimation() {
        guard isDaytime && !isLuminanceReduced else {
            animationScale = 1
            return
        }
        
        withAnimation(.easeOut(duration: 0.5)) {
            animationScale = 1
        }
    }
}

// MARK: - Moon Phase View
struct MoonPhaseView: View {
    let phase: MoonPhase
    
    private func phaseValue() -> Double {
        switch phase {
        case .new: return 0.0
        case .waxingCrescent: return 0.125
        case .firstQuarter: return 0.25
        case .waxingGibbous: return 0.375
        case .full: return 0.5
        case .waningGibbous: return 0.625
        case .lastQuarter: return 0.75
        case .waningCrescent: return 0.875
        @unknown default: return 0.0
        }
    }
    
    var body: some View {
        ZStack {
            // Moon base circle
            Circle()
                .fill(.black)
            
            // Moon phase shadow
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                let normalizedPhase = phaseValue()
                
                // Create appropriate shadow shape based on moon phase value
                if normalizedPhase < 0.5 {
                    // Waxing moon (new → full)
                    let x = width * (1 - normalizedPhase * 2)
                    
                    // Elliptical shadow that moves from right to left
                    Ellipse()
                        .fill(.white)
                        .frame(width: width, height: height)
                        .offset(x: x)
                } else {
                    // Waning moon (full → new)
                    let x = width * ((normalizedPhase - 0.5) * 2)
                    
                    // Elliptical shadow that moves from left to right
                    Ellipse()
                        .fill(.white)
                        .frame(width: width, height: height)
                        .offset(x: -width + x)
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct SunMoonView_Previews: PreviewProvider {
    static var settings = AppSettings()
    static var colorManager = ColorManager()
    
    static var previews: some View {
        SunMoonView()
            .environmentObject(settings)
            .environmentObject(colorManager)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
