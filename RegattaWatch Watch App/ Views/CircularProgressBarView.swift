//
//  CircularProgressBarView.swift
//  RegattaWatch Watch App
//
//  Circular version of the progress bar
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - CircularTextView (Add this new struct)
struct CircularTextView: View {
    @State var letterWidths: [Int:Double] = [:]
    
    var text: String // Changed from 'title' to 'text' for clarity
    var radius: Double
    var textSize: CGFloat
    var textColor: Color
    var initialRotationDegrees: Double // New parameter for initial rotation

    var lettersOffset: [(offset: Int, element: Character)] {
        return Array(text.enumerated())
    }
    
    var body: some View {
        ZStack {
            ForEach(lettersOffset, id: \.offset) { index, letter in
                VStack {
                    Text(String(letter))
                        .font(.zenithBeta(size: textSize))
//                        .font(.system(size: textSize, design: .monospaced)) // Use textSize
                        .foregroundColor(textColor) // Use textColor
                        .scaleEffect(x:1.4)
                        .kerning(5) // Adjust kerning as needed for better fit
                        .background(LetterWidthSize())
                        .onPreferenceChange(WidthLetterPreferenceKey.self) { width in
                            letterWidths[index] = width
                        }
                    Spacer()
                }
                .rotationEffect(fetchAngle(at: index))
            }
        }
        .frame(width: radius * 2, height: radius * 2) // Frame based on radius
        .rotationEffect(.degrees(initialRotationDegrees)) // Apply initial rotation
    }
    
    func fetchAngle(at letterPosition: Int) -> Angle {
        let times2pi: (Double) -> Double = { $0 * 2 * .pi }
        
        // Calculate the circumference based on the desired radius for text placement
        let circumference = times2pi(radius)
                        
        // Calculate the cumulative width of letters up to the current letter
        let cumulativeWidth = letterWidths.filter{$0.key <= letterPosition}.map(\.value).reduce(0, +)
        
        // Calculate the angle for the current letter
        let finalAngle = times2pi(cumulativeWidth / circumference)
        
        return .radians(finalAngle)
    }
}

// MARK: - PreferenceKey for Letter Width (Keep this as is)
struct WidthLetterPreferenceKey: PreferenceKey {
    static var defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

// MARK: - LetterWidthSize (Keep this as is)
struct LetterWidthSize: View {
    var body: some View {
        GeometryReader { geometry in
            Color
                .clear
                .preference(key: WidthLetterPreferenceKey.self,
                            value: geometry.size.width)
        }
    }
}

// MARK: - Gradient Compass Manager
class GradientCompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var smoothHeading: Double = 0
    @Published var isLargeRotation: Bool = false
    
    private let locationManager = CLLocationManager()
    private var previousHeading: Double = 0
    private var continuousHeading: Double = 0
    private var hasInitialHeading = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            let rawHeading = newHeading.magneticHeading
            
            if !self.hasInitialHeading {
                // First heading - no animation needed
                self.heading = rawHeading
                self.smoothHeading = rawHeading
                self.previousHeading = rawHeading
                self.continuousHeading = rawHeading
                self.hasInitialHeading = true
                return
            }
            
            // Calculate the difference between new and previous heading
            let diff = self.calculateShortestAngleDifference(from: self.previousHeading, to: rawHeading)
            
            // Detect if this is a large rotation (> 120°)
            let isLargeChange = abs(diff) > 120
            
            // Update continuous heading to avoid 0°/360° boundary jumps
            self.continuousHeading += diff
            
            // Update published values
            self.heading = rawHeading
            self.smoothHeading = self.continuousHeading
            self.isLargeRotation = isLargeChange
            self.previousHeading = rawHeading
        }
    }
    
    private func calculateShortestAngleDifference(from: Double, to: Double) -> Double {
        var diff = to - from
        
        // Normalize to [-180, 180] range for shortest path
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        
        return diff
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Compass error: \(error.localizedDescription)")
    }
}

struct CircularProgressBarView: View {
    @ObservedObject var timerState: WatchTimerState
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @Binding var realTime: Date
    @State private var lastAngle: Double = 0
    @State private var angleOffset: Double = 0
    @State private var continuousAngle: Double = 0
    @State private var lastSeconds: Double = 0
    @StateObject private var gradientCompass = GradientCompassManager()
    
    // Gradient overlay opacity controls
    @State private var whiteOpacity: Double = 0.9
    @State private var blackOpacity: Double = 0.0
    
    private let circleSize: CGFloat = 100
    private let lineWidth: CGFloat = 15 //10
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3), lineWidth: lineWidth)
                .frame(width: circleSize, height: circleSize)
            
            // Progress fill
            Circle()
                .trim(from: 0, to: timerState.progress)
                .stroke(
                    Color(timerState.currentTime <= 60 && timerState.mode == .countdown ? .orange : Color(hex: colorManager.selectedTheme.rawValue)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-90))  // Start from top
            
            /*
            // NEW: Compass-oriented gradient overlay
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(whiteOpacity), location: 0.0),      // 12 o'clock - white
                            .init(color: Color.black.opacity(blackOpacity), location: 0.25),     // 3 o'clock - black
                            .init(color: Color.white.opacity(whiteOpacity), location: 0.5),      // 6 o'clock - white
                            .init(color: Color.black.opacity(blackOpacity), location: 0.75),     // 9 o'clock - black
                            .init(color: Color.white.opacity(whiteOpacity), location: 1.0)       // Back to 12 o'clock - white
                        ]),
                        center: .center,
                        startAngle: .degrees(-90), // Start from top (12 o'clock)
                        endAngle: .degrees(270)    // Complete full circle
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-gradientCompass.smoothHeading)) // Counter-rotate to maintain north orientation
                .animation(
                    gradientCompass.isLargeRotation ?
                        .easeInOut(duration: 1.2) : // Slower animation for large rotations
                        .easeInOut(duration: 0.3),   // Normal speed for small adjustments
                    value: gradientCompass.smoothHeading
                ) // Adaptive animation timing
            */
            
            // glass effect layer
            Button(action: {
            }) {
                Circle()
                    .fill(.white.opacity(0))
            }
            .buttonStyle(.plain)
//            .glassEffect(in: .circle)
            .frame(width: 90, height: 90)
            .colorScheme(settings.lightMode ? .light : .dark)
            .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 0) // Added shadow
            
            /*
            // --- NEW: Circular Text for "20 40 60" ---
            ZStack{
                CircularTextView(
                    text: "60", // Add spaces to distribute evenly //40          60          20
                    radius: 58, // Half of 90 circle size
                    textSize: 12, // Adjust text size to fit
                    textColor: settings.lightMode ? .white : .black, // Match current theme
                    initialRotationDegrees: -16.5 // Adjust this to position "60" at the top
                )
                
                CircularTextView(
                    text: "40", // Add spaces to distribute evenly //40          60          20
                    radius: 58, // Half of 90 circle size
                    textSize: 12, // Adjust text size to fit
                    textColor: settings.lightMode ? .white : .black, // Match current theme
                    initialRotationDegrees: -136.5 // Adjust this to position "60" at the top
                )
                
                CircularTextView(
                    text: "20", // Add spaces to distribute evenly //40          60          20
                    radius: 58, // Half of 90 circle size
                    textSize: 12, // Adjust text size to fit
                    textColor: settings.lightMode ? .white : .black, // Match current theme
                    initialRotationDegrees: 103.5 // Adjust this to position "60" at the top
                )
            }
            .frame(width: 90, height: 90) // Ensure it fits the 90 circle
                // --- END NEW ---
            */
            
            // Timer display text
            ZStack{
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(settings.lightMode ? .white : .black)
                    .frame(width: 50, height: 20)
                    .padding (2)
                
                Text(formatTime(timerState.currentTime))
                    .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 16) : .zenithBeta(size: 16, weight: .regular)) //82?
                    .foregroundColor(settings.lightMode ? .black : .white)
            }
//            .glassEffect(in: RoundedRectangle(cornerRadius: 8.0))
            .frame(width: 50, height: 20)
            .offset(y:-20)
            .colorScheme(.light)
            
            ZStack{
                RoundedRectangle(cornerRadius: 8.0)
                    .fill(settings.lightMode ? .white : .black)
                    .frame(width: 20, height: 20)
                
            Text("\(Calendar.current.component(.day, from: Date()))")
                    .font(settings.debugMode ? Font.custom("Hermes-Numbers",size: 18) : .zenithBeta(size: 18, weight: .regular)) //82?
                    .foregroundColor(settings.lightMode ? .black : .white)
            }
            .padding(3)
//            .glassEffect(in: RoundedRectangle(cornerRadius: 8.0))
            .frame(width: 40, height: 30)
            .offset(y:22)
            .colorScheme(.light)
            
            // Only show separators for non-stopwatch modes
            if timerState.mode != .stopwatch {
                // 12 o'clock trim compensator (only needed if there are separators)
                if timerState.selectedMinutes > 0 {
                    Circle()
                        .trim(from: 0, to: 0.003)
                        .stroke(settings.lightMode ? Color.white : Color.black,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: 0.997, to: 1)
                        .stroke(settings.lightMode ? Color.white : Color.black,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .rotationEffect(.degrees(-90))
                }
                
                // Regular minute separators
                ForEach(0..<timerState.selectedMinutes, id: \.self) { index in
                    let separatorPosition = Double(index) / Double(timerState.selectedMinutes)
                    
                    Circle()
                        .trim(from: max(0, separatorPosition - 0.003),
                              to: min(1, separatorPosition + 0.003))
                        .stroke(settings.lightMode ? Color.white : Color.black,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                        )
                        .frame(width: circleSize, height: circleSize)
                        .rotationEffect(.degrees(-90))
                        .transition(.scale.combined(with: .opacity))
                        .animation(
                            .spring(
                                response: 0.6,
                                dampingFraction: 0.9,
                                blendDuration: 0
                            )
                            .delay(calculateDelay(for: index)),
                            value: timerState.selectedMinutes
                        )
                }
                
                // Last minute separators (only in countdown mode and during last minute)
                if timerState.mode == .countdown && timerState.currentTime <= 60 && timerState.currentTime > 0 && timerState.selectedMinutes > 0 {
                    ForEach(0..<5, id: \.self) { index in
                        let minuteSegmentWidth = 1.0 / Double(timerState.selectedMinutes)
                        let lastSegmentStart = minuteSegmentWidth
                        let subSegmentPosition = lastSegmentStart - (minuteSegmentWidth / 6.0 * Double(index + 1))
                        
                        Circle()
                            .trim(from: max(0, subSegmentPosition - 0.003),
                                  to: min(1, subSegmentPosition + 0.003))
                            .stroke(settings.lightMode ? Color.white : Color.black,
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                            )
                            .frame(width: circleSize, height: circleSize)
                            .rotationEffect(.degrees(-90))
                    }
                }
                
                // Second hand
                secondHandView
                    .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                        updateSecondHandState()
                    }
                
            }
        }
        .frame(width: circleSize, height: circleSize)
    }
    
    // MARK: - Time Formatting
    private func formatTime(_ timeInSeconds: Double) -> String {
        let totalSeconds = Int(timeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Second Hand View
    private var secondHandView: some View {
        ZStack {
            // Second hand line
            Rectangle()
                .fill(settings.lightMode ? Color(hex: ColorTheme.signalOrange.rawValue) : Color(hex: ColorTheme.signalOrange.rawValue))
//                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                // Total height of the rectangle will be the sum of the long part and the short part
                .frame(width: 2, height: (circleSize / 2) + 10) // 50 (long side) + 10 (short side) = 60
                // Offset calculation: (Total Height / 2) - Short Part Length
                // (60 / 2) - 10 = 30 - 10 = 20. Negative because it points upwards.
                .offset(y: -((circleSize / 4) - 5)) // Adjusted offset for correct protrusion
            
            // Center dot
            Circle()
                .fill(settings.lightMode ? Color(hex: ColorTheme.signalOrange.rawValue) : Color(hex: ColorTheme.signalOrange.rawValue))
//                .fill(Color(hex: colorManager.selectedTheme.rawValue))
                .frame(width: 4, height: 4)
        }
        .rotationEffect(.degrees(secondHandAngle))
        // Apply spring animation directly to the ZStack containing the hand
        .animation(shouldAnimate ? .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0) : nil, value: secondHandAngle)
//        .animation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0), value: secondHandAngle)
    }
    
    private var shouldAnimate: Bool {
        let timeSource = timerState.isRunning ? timerState.currentTime : realTime.timeIntervalSince1970
        let secondsInCurrentMinute = timeSource.truncatingRemainder(dividingBy: 60)
        return secondsInCurrentMinute > 1 && secondsInCurrentMinute < 59 // Don't animate near 0
    }
    
    // MARK: - Second Hand Angle Calculation
    
    // MARK: - Second Hand Angle Calculation
    
    private var secondHandAngle: Double {
        let timeSource = timerState.isRunning ? timerState.currentTime : 0
        let secondsInCurrentMinute = timeSource.truncatingRemainder(dividingBy: 60)
        
        // Calculate base angle without modifying state
        let baseAngle = (secondsInCurrentMinute / 60.0) * 360.0
        
        return baseAngle + continuousAngle
    }
    
    // MARK: - Update Second Hand State
    private func updateSecondHandState() {
        let timeSource = timerState.isRunning ? timerState.currentTime : 0
        let secondsInCurrentMinute = timeSource.truncatingRemainder(dividingBy: 60)
        
        // Detect when we cross from 59 to 0 seconds
        if secondsInCurrentMinute < 10 && lastSeconds > 50 {
            continuousAngle += 360 // Add full rotation instead of jumping back
        }
        
        lastSeconds = secondsInCurrentMinute
    }
    
    // Delay calculation for smooth animation when adding/removing separators
    private func calculateDelay(for index: Int) -> Double {
        let isAdding = timerState.selectedMinutes > timerState.previousMinutes
        
        if isAdding {
            guard index >= timerState.previousMinutes && index < timerState.selectedMinutes else { return 0 }
            return Double(index - timerState.previousMinutes) * 0.1
        } else {
            guard index < timerState.previousMinutes else { return 0 }
            let distanceFromEnd = timerState.previousMinutes - index - 1
            return Double(distanceFromEnd) * 0.1
        }
    }
}
