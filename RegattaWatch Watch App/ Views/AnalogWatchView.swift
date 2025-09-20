//
//  AnalogWatchView.swift
//  Regatta
//
//  Created by Chikai Lai on 07/09/2025.
//

import Foundation
import SwiftUI
import WatchKit

struct AnalogWatchView: View {
    @StateObject private var fontManager = CustomFontManager.shared
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var colorManager: ColorManager
    
    @State private var currentTime = Date()
    @State private var hourPositions: [Int: CGPoint] = [:]
    @State private var hourAngles: [Int: Angle] = [:]
    @State private var viewCenter: CGPoint = .zero
    @State private var hasCalculatedPositions = false
    
    let timeTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    private let warmBeige = Color(red: 218/255, green: 199/255, blue: 188/255)
    
    // Watch face dimensions
    private let radius: CGFloat = 70
    private let centerRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Black background
            if settings.lightMode {
                Color(hex: "efe7df").edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }
            
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let currentHour = currentHourNumber(from: currentTime)

                ZStack {
                    // Numbers positioned in a circle
                    ForEach(1...12, id: \.self) { number in
                        if number == 3 {
                            // Date display at 3 o'clock position
                            Text("\(dayNumber(from: currentTime))")
                                .offset(x:1)
                                .font(customFont(size: !(settings.timeFont == "Default") ? 16 : 24))
                                .foregroundColor(settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"))
                                .frame(width: 30, height: 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.clear)
                                        .stroke(Color(hex: colorManager.selectedTheme.rawValue), lineWidth: 1)
                                )
                                .position(hourPositions[number] ?? center)
                                .offset(x:-5, y:2)
                        } else {
                            ZStack {
                                Text("\(number)")
                                    .font(customFont(size: !(settings.timeFont == "Default") ? 28 : 38))
                                    .foregroundColor(isLuminanceReduced ? settings.lightMode ? Color(hex: "efe7df") : .black : number == currentHour ? settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc") : settings.lightMode ? Color(hex: "efe7df") : .black)
                                    .shadow(color: settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"), radius: 1)
                                    .shadow(color: settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"), radius: 1)
                                   // .shadow(color: settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"), radius: 0.3)
                                   // .shadow(color: settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"), radius: 0.3)
                                //                                .shadow(color: settings.lightMode ? Color(hex: "59524f") : Color(hex: "dac7bc"), radius: 0.3)
                                    .rotationEffect(hourAngles[number] ?? .degrees(0))
                                    .position(hourPositions[number] ?? center)
                                
                                Text("\(number)")
                                    .font(customFont(size: !(settings.timeFont == "Default") ? 28 : 38))
                                    .foregroundColor(isLuminanceReduced ? settings.lightMode ? Color(hex: "efe7df") : .black : getHourNumberColor(for: number, currentHour: currentHour))
                                    .rotationEffect(hourAngles[number] ?? .degrees(0))
                                    .position(hourPositions[number] ?? center)
                            }
                        }
                    }
                    
                    ForEach(1...12, id: \.self) { number in
                        if number == 3 {

                        } else {

                        }
                    }
                    
                    // Team name display
                    VStack(spacing: -3) {
                        if settings.teamName.contains("-") {
                            let parts = settings.teamName.split(separator: "-", maxSplits: 1)
                            if parts.count == 2 {
                                Text(String(parts[0]))
                                    .font(teamNameFont(size: 13))
                                    .foregroundColor(getHourNumberColor(for: currentHour, currentHour: currentHour))
                                    .kerning(1.5)
                                    .scaleEffect(x:1.05)
                                Text(String(parts[1]))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(getHourNumberColor(for: currentHour, currentHour: currentHour))
                                    .kerning(2.5)
                            } else {
                                Text(settings.teamName.replacingOccurrences(of: "-", with: ""))
                                    .font(teamNameFont(size: 13))
                                    .foregroundColor(getHourNumberColor(for: currentHour, currentHour: currentHour))
                                    .kerning(1.0)
                            }
                        } else {
                            Text(settings.teamName)
                                .font(teamNameFont(size: 13))
                                .foregroundColor(getHourNumberColor(for: currentHour, currentHour: currentHour))
                                .kerning(2.0)
                        }
                    }
                    .position(center)
                    .offset(y: -47)
                    
                    BarometerView()
                        .position(center)
                        .offset(y: 45)
                        .colorMultiply(settings.lightMode ? Color(hex:"efe7df") : Color(hex: "dac7bc"))

                    // Watch hands
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(settings.lightMode ? Color.black : Color.white)
                            .frame(width: 3, height: 20)
                            .offset(y: -10)
                            .rotationEffect(hourAngle(from: currentTime))
                            .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                        // Hour hand
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? Color.white : Color.black)
                            .frame(width: 6, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.lightMode ? Color.black : Color.white, lineWidth: 1.5)
                                    .frame(width: 6, height: 50)
                            )
                            .offset(y: -38)
                            .rotationEffect(hourAngle(from: currentTime))
                            .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                        // Minute hand
                        RoundedRectangle(cornerRadius: 12)
                            .fill(settings.lightMode ? Color.black : Color.white)
                            .frame(width: 3, height: 20)
                            .offset(y: -10)
                            .rotationEffect(minuteAngle(from: currentTime))
                            .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                        RoundedRectangle(cornerRadius: 12)
                            .fill(isLuminanceReduced ? Color(hex: colorManager.selectedTheme.rawValue) : settings.lightMode ? Color.white : Color.black)
                            .frame(width: 6, height: 85)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.lightMode ? Color.black : Color.white, lineWidth: 1.5)
                                    .frame(width: 6, height: 85)
                            )
                            .offset(y: -55)
                            .rotationEffect(minuteAngle(from: currentTime))
                            .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                        // Center dot
                        Circle()
                            .fill(settings.lightMode ? Color.black : Color.white)
                            .frame(width: 9, height: 9)
                        
                        if !isLuminanceReduced {
                            // Second hand
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                                .frame(width: 1.5, height: 120)
                                .offset(y: -40)
                                .rotationEffect(secondAngle(from: currentTime))
                                .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                            Circle()
                                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                                .frame(width: 7, height: 7)
//                                .shadow(color: settings.lightMode ? .black : .white, radius: 1)

                        }
                        
                        Circle()
                            .fill(settings.lightMode ? Color(hex: "efe7df") : Color.black)
                            .frame(width: 2, height: 2)
                    }
                    .position(center)
                }
                .offset(y:-7)
                .onAppear {
                    if !hasCalculatedPositions || viewCenter != center {
                        calculateStaticPositions(center: center)
                    }
                }
                .onChange(of: geometry.size) { _ in
                    let newCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    if viewCenter != newCenter {
                        calculateStaticPositions(center: newCenter)
                    }
                }
            }
            .onReceive(timeTimer) { input in
                currentTime = input
            }
        }
        .onDisappear {
            timeTimer.upstream.connect().cancel()
        }
    }
    
    // MARK: - Helper Functions
    
    private func customFont(size: CGFloat) -> Font {
        if let customFont = CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.timeFont }) {
            return Font.customFont(customFont, size: size + CGFloat(settings.fontSize)) ?? .system(size: size, weight: .medium)
        }
        return .system(size: size, weight: .medium)
    }
    
    private func teamNameFont(size: CGFloat) -> Font {
        if settings.teamNameFont == "Default" {
            return .system(size: size, weight: .semibold)
        } else if let customFont = CustomFontManager.shared.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) {
            return Font.customFont(customFont, size: size) ?? .system(size: size, weight: .semibold)
        } else {
            return .system(size: size, weight: .semibold)
        }
    }
    
    private func calculateStaticPositions(center: CGPoint) {
        viewCenter = center
        
        // Calculate positions for each hour number
        for number in 1...12 {
            hourPositions[number] = calculateNumberPosition(for: number, center: center, radius: radius)
            hourAngles[number] = calculateTiltAngle(for: number)
        }
        
        hasCalculatedPositions = true
    }
    
    private func calculateNumberPosition(for number: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(number - 3) * 30 * .pi / 180 // Start from 12 o'clock (3 positions back)
        
        // Define different radii and oval shapes for each number group
        let (effectiveRadius, horizontalMultiplier, verticalMultiplier): (CGFloat, CGFloat, CGFloat)
        
        switch number {
        case 3, 6, 9, 12:
            effectiveRadius = radius * 1.1 // Main cardinal positions
            horizontalMultiplier = 1.05 // Oval shape for cardinal numbers
            verticalMultiplier = 1.3
        case 1, 5, 7, 11:
            effectiveRadius = radius * 1.15 // Slightly closer
            horizontalMultiplier = 1.4 // Oval shape for cardinal numbers
            verticalMultiplier = 1.3
        case 2, 4, 8, 10:
            effectiveRadius = radius * 1.02 // Medium distance
            horizontalMultiplier = 1.22 // Oval shape for cardinal numbers
            verticalMultiplier = 1.4
        default:
            effectiveRadius = radius
            horizontalMultiplier = 1.0
            verticalMultiplier = 1.0
        }
        
        let radiusX = effectiveRadius * horizontalMultiplier
        let radiusY = effectiveRadius * verticalMultiplier
        
        let x = center.x + radiusX * cos(angle)
        let y = center.y + radiusY * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    private func calculateTiltAngle(for number: Int) -> Angle {
        switch number {
        case 1, 7:
            return .degrees(30) // 30 degree clockwise
        case 2, 8:
            return .degrees(60) // 60 degree clockwise
        case 4, 10:
            return .degrees(-60) // 60 degree anticlockwise
        case 5, 11:
            return .degrees(-30) // 30 degree anticlockwise
        case 9:
            return .degrees(-90) // 90 degree anticlockwise
        case 6, 12:
            return .degrees(0) // No tilt
        default:
            return .degrees(0) // No tilt for 3 (date position)
        }
    }
    
    private func numberPosition(for number: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(number - 3) * 30 * .pi / 180 // Start from 12 o'clock (3 positions back)
        
        // Define different radii and oval shapes for each number group
        let (effectiveRadius, horizontalMultiplier, verticalMultiplier): (CGFloat, CGFloat, CGFloat)
        
        switch number {
        case 3, 6, 9, 12:
            effectiveRadius = radius * 1.1 // Main cardinal positions
            horizontalMultiplier = 1.05 // Oval shape for cardinal numbers
            verticalMultiplier = 1.3
        case 1, 5, 7, 11:
            effectiveRadius = radius * 1.15 // Slightly closer
            horizontalMultiplier = 1.4 // Oval shape for cardinal numbers
            verticalMultiplier = 1.3
        case 2, 4, 8, 10:
            effectiveRadius = radius * 1.02 // Medium distance
            horizontalMultiplier = 1.22 // Oval shape for cardinal numbers
            verticalMultiplier = 1.4
        default:
            effectiveRadius = radius
            horizontalMultiplier = 1.0
            verticalMultiplier = 1.0
        }
        
        let radiusX = effectiveRadius * horizontalMultiplier
        let radiusY = effectiveRadius * verticalMultiplier
        
        let x = center.x + radiusX * cos(angle)
        let y = center.y + radiusY * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    private func tiltAngle(for number: Int) -> Angle {
        switch number {
        case 1, 7:
            return .degrees(30) // 30 degree clockwise
        case 2, 8:
            return .degrees(60) // 60 degree clockwise
        case 4, 10:
            return .degrees(-60) // 60 degree anticlockwise
        case 5, 11:
            return .degrees(-30) // 30 degree anticlockwise
        case 9:
            return .degrees(-90) // 90 degree anticlockwise
        case 6, 12:
            return .degrees(0) // No tilt
        default:
            return .degrees(0) // No tilt for 3 (date position)
        }
    }
    
    private func hourAngle(from date: Date) -> Angle {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        // Smooth hour hand movement including seconds and nanoseconds
        let secondsFraction = Double(second) + Double(nanosecond) / 1_000_000_000
        let minutesFraction = Double(minute) + secondsFraction / 60
        let hourAngle = Double(hour % 12) * 30 + minutesFraction * 0.5
        
        return .degrees(hourAngle)
    }
    
    private func minuteAngle(from date: Date) -> Angle {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        // Smooth minute hand movement including nanoseconds
        let secondsFraction = Double(second) + Double(nanosecond) / 1_000_000_000
        let minuteAngle = Double(minute) * 6 + secondsFraction * 0.1
        
        return .degrees(minuteAngle)
    }
    
    private func secondAngle(from date: Date) -> Angle {
        let calendar = Calendar.current
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        // Smooth second hand movement including nanoseconds
        let secondsFraction = Double(second) + Double(nanosecond) / 1_000_000_000
        let secondAngle = secondsFraction * 6
        
        return .degrees(secondAngle)
    }
    
    private func dayNumber(from date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: date)
    }
    
    private func currentHourNumber(from date: Date) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Convert 24-hour format to 12-hour format
        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        
        return hour12
    }
    private func getHourNumberColor(for number: Int, currentHour: Int) -> Color {
        if settings.lightMode {
            // Light mode: use black instead of dac7bc
            if number == currentHour {
                return Color(hex: "59524f")
            } else if number == (currentHour == 1 ? 12 : currentHour - 1) {
                return Color(hex: "59524f").opacity(0.7)
            } else if number == (currentHour <= 2 ? (currentHour == 1 ? 11 : 12) : currentHour - 2) {
                return Color(hex: "59524f").opacity(0.4)
            } else {
                return .clear
            }
        } else {
            // Dark mode: use dac7bc
            if number == currentHour {
                return Color(hex: "dac7bc")
            } else if number == (currentHour == 1 ? 12 : currentHour - 1) {
                return Color(hex: "dac7bc").opacity(0.7)
            } else if number == (currentHour <= 2 ? (currentHour == 1 ? 11 : 12) : currentHour - 2) {
                return Color(hex: "dac7bc").opacity(0.4)
            } else {
                return .clear
            }
        }
    }
}

// Preview
struct AnalogWatchView_Previews: PreviewProvider {
    static var previews: some View {
        AnalogWatchView()
            .environmentObject(ColorManager())
            .environmentObject(AppSettings())
    }
}
