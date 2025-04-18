//
//  PrivacyOverlay.swift
//  Regatta
//
//  Created by Chikai Lai on 13/04/2025.
//

import SwiftUI

struct PrivacyOverlayView: View {
    @ObservedObject var colorManager = ColorManager.shared
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                VStack() {
                    // Top blurry section
                    RoundedRectangle(cornerRadius: 55)
                        .fill(settings.lightMode ? Color.white.opacity(1)
                              : Color.black.opacity(1)
                        )
                        .frame(width: geometry.size.width - 30, height: geometry.size.height * 0.55)
                    
                    Spacer()
                        .frame(width: geometry.size.width - 30, height: 40)
                    
                    // Bottom blurry section
                    RoundedRectangle(cornerRadius: 55)
                        .fill(settings.lightMode ? Color.white.opacity(1)
                              : Color.black.opacity(1)
                        )
                        .frame(width: geometry.size.width - 30, height: geometry.size.height * 0.6)
                }
                 .offset(y:-44)
                
                
                VStack {
                    // 1. Circle of 25x25 filled with theme color
                    Circle()
                        .fill(Color(hex: colorManager.selectedTheme.rawValue).gradient)
                        .frame(width: 35, height: 35)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                        )
                        .padding(.top, 20)
                        .offset(y:0)
                    
                    // 2. Art Deco Semicircle with alternating sections
                    
                    ZStack{
                        ArtDecoSemicircle(
                            width: geometry.size.width * 0.55,
                            height: geometry.size.height * 0.2,
                            sectionCount: 24,
                            color1: .black,
                            color2: .black,
                            strokeWidth: 35
                        )
                        
                        ArtDecoSemicircle(
                            width: geometry.size.width * 0.55,
                            height: geometry.size.height * 0.2,
                            sectionCount: 24,
                            color1: .white.opacity(0.7),
                            color2: .white.opacity(0.2),
                            strokeWidth: 35,
                            borderWidth: 3,
                            borderColor: Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7) // Silver color
                        )
                    }
                    .padding(.top, 10)
                    .rotationEffect(Angle(degrees: 180))
                    .offset(y:-25)
                    
                    // 3. Spacer
                    HStack{
                        Circle()
                            .fill(Color(hex: ColorTheme.racingRed.rawValue).gradient)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                            )
                            .offset(y:-2)
                        
                        Spacer()
                            .frame(width: 100)
                        
                        Triangle()
                            .foregroundColor(Color(hex: ColorTheme.marineYellow.rawValue))
                            .frame(width: 30, height: 30 * 0.866)
                            .overlay(
                                Triangle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                            )
                            .offset(x: 6)
                            .rotationEffect(Angle(degrees: 180))
                    }
                    .offset(y:-135)
                    
                    Spacer()
                        .frame(height: 0)
                    
                    // 4. Rounded rectangle with stripes
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.15)
                        .repeatingGradient(
                            colors: [
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.6),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.7),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.4),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(1)],
                            startPoint: .leading,
                            endPoint: .trailing,
                            repetitions: 12
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                        )
                        .offset(y:-45)
                    
                    
                    // 5. Three circles in HStack with different stripe patterns marimbaBlue
                    HStack(spacing: 5) {
                        // Left circle - vertical stripes (0°)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 50, height: 50)
                            .repeatingGradient(
                                colors: [
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.6),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.7),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1)],
                                startPoint: .leading,
                                endPoint: .trailing,
                                repetitions: 4
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                            )
                            .rotationEffect(Angle(degrees: 135))
                        
                        // Middle circle - 45° angled stripes
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .fill(.angularGradient(colors: [Color(hex: ColorTheme.marimbaBlue.rawValue).opacity(0.45), Color(hex: ColorTheme.marimbaBlue.rawValue).opacity(1)], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                                )
                        }
                        
                        // Right circle - horizontal stripes (90°)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                            .repeatingGradient(
                                colors: [
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.6),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.7),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(1)],
                                startPoint: .leading,
                                endPoint: .trailing,
                                repetitions: 4
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(0.7), lineWidth: 3) // Silver border
                            )
                            .rotationEffect(Angle(degrees: 90))
                    }
                    .padding(.bottom, 20)
                    .offset(y:-40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct PrivacyOverlayTwoView: View {
    @ObservedObject var colorManager = ColorManager.shared
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                VStack() {
                    // Top blurry section
                    RoundedRectangle(cornerRadius: 55)
                        .fill(settings.lightMode ? Color.white.opacity(1)
                              : Color.black.opacity(1)
                        )
                        .frame(width: geometry.size.width - 30, height: geometry.size.height * 0.55)
                    
                    Spacer()
                        .frame(width: geometry.size.width - 30, height: 40)
                    
                    // Bottom blurry section
                    RoundedRectangle(cornerRadius: 55)
                        .fill(settings.lightMode ? Color.white.opacity(1)
                              : Color.black.opacity(1)
                        )
                        .frame(width: geometry.size.width - 30, height: geometry.size.height * 0.6)
                }
                 .offset(y:-40)
                
                
                VStack {
                    // 1. Circle of 25x25 filled with theme color
                    Circle()
                        .fill(Color(hex: colorManager.selectedTheme.rawValue).gradient)
                        .frame(width: 30, height: 30)
                        .overlay(
                            ZStack{
                                Circle()
                                    .stroke(Color.black, lineWidth: 3.5) // Silver border
                                Circle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                            }
                        )
                        .padding(.top, 20)
                        .offset(y:-5)
                    
                    // 2. Art Deco Semicircle with alternating sections
                    
                    ZStack{
                        ArtDecoSemicircle(
                            width: geometry.size.width * 0.55,
                            height: geometry.size.height * 0.2,
                            sectionCount: 56,
                            color1: .white.opacity(0.8),
                            color2: .black,
                            strokeWidth: 35
                        )
                        
                        ArtDecoSemicircle(
                            width: geometry.size.width * 0.55,
                            height: geometry.size.height * 0.2,
                            sectionCount: 56,
                            color1: .white.opacity(0.7),
                            color2: .white.opacity(0.2),
                            strokeWidth: 35,
                            borderWidth: 3,
                            borderColor: Color(red: 0.75, green: 0.75, blue: 0.8) // Silver color
                        )
                    }
                    .padding(.top, 10)
                    .rotationEffect(Angle(degrees: 180))
                    .offset(y:-25)
                    
                    // 3. Spacer
                    
                    HStack{
                        Circle()
                            .fill(Color(hex: ColorTheme.racingRed.rawValue).gradient)
                            .frame(width: 30, height: 30)
                            .overlay(
                                ZStack{
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3.5) // Silver border
                                    Circle()
                                        .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                                }
                            )
                            .offset(y:0)
                        
                        Spacer()
                            .frame(width: 112)
                        
                        Triangle()
                            .foregroundColor(Color(hex: ColorTheme.marineYellow.rawValue))
                            .frame(width: 30, height: 30 * 0.866)
                            .overlay(
                                ZStack{
                                    Triangle()
                                        .stroke(Color.black, lineWidth: 3.5) // Silver border
                                    Triangle()
                                        .stroke(Color(red: 0.75, green: 0.75, blue: 0.8), lineWidth: 3) // Silver border
                                }
                            )
                            .offset(x: 0)
                            .rotationEffect(Angle(degrees: 90))
                    }
                    .offset(y:-48)
                    
                    
                    Spacer()
                        .frame(height: 0)
                    
                    // 4. Rounded rectangle with stripes
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.15)
                        .repeatingGradient(
                            colors: [
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.6),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.7),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(0.4),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(1),
                                Color(hex: ColorTheme.ultraBlue.rawValue).opacity(1)],
                            startPoint: .leading,
                            endPoint: .trailing,
                            repetitions: 12
                        )
                        .overlay(
                            ZStack{
                                Rectangle()
                                    .stroke(Color.black, lineWidth: 3.5)
                                Rectangle()
                                    .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                            }
                        )
                        .offset(y:-42)
                    
                    
                    // 5. Three circles in HStack with different stripe patterns marimbaBlue
                    HStack(spacing: 5) {
                        // Left circle - vertical stripes (0°)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 50, height: 50)
                            .repeatingGradient(
                                colors: [
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.6),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.7),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1),
                                    Color(hex: ColorTheme.kiwiBlue.rawValue).opacity(1)],
                                
                                startPoint: .leading,
                                endPoint: .trailing,
                                repetitions: 4
                            )
                            .overlay(
                                ZStack{
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3.5) // Silver border
                                    Circle()
                                        .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                                }
                            )
                            .rotationEffect(Angle(degrees: 135))
                        
                        // Middle circle - 45° angled stripes
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .fill(.angularGradient(colors: [Color(hex: ColorTheme.marimbaBlue.rawValue).opacity(0.45), Color(hex: ColorTheme.marimbaBlue.rawValue).opacity(1)], center: .center, startAngle: .degrees(0), endAngle: .degrees(360)))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    ZStack{
                                        Circle()
                                            .stroke(Color.black, lineWidth: 3.5) // Silver border
                                        Circle()
                                            .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                                    }
                                )
                        }
                        
                        // Right circle - horizontal stripes (90°)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                            .repeatingGradient(
                                colors: [
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.6),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.7),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(0.4),
                                    Color(hex: ColorTheme.signalOrange.rawValue).opacity(1)],
                                startPoint: .leading,
                                endPoint: .trailing,
                                repetitions: 4
                            )
                            .overlay(
                                ZStack{
                                    Circle()
                                        .stroke(Color.black, lineWidth: 3.5) // Silver border
                                    Circle()
                                        .stroke(Color(red: 0.75, green: 0.75, blue: 0.8).opacity(1), lineWidth: 3) // Silver border
                                }
                            )
                            .rotationEffect(Angle(degrees: 90))
                    }
                    .padding(.bottom, 20)
                    .offset(y:-40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y:3)
            }
        }
    }
}


struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        }
    }
}

struct PrivacyOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyOverlayView()
            .environmentObject(AppSettings())
    }
}

struct PrivacyOverlayTwoView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyOverlayTwoView()
            .environmentObject(AppSettings())
    }
}

// MARK: - Striped Pattern Modifier with Independent Width Control
struct StripedPattern: ViewModifier {
    var stripeWidth1: CGFloat  // Width for color1
    var stripeWidth2: CGFloat  // Width for color2
    var spacing: CGFloat
    var rotation: Double // in degrees, 0 = vertical stripes
    var color1: Color
    var color2: Color
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    StripedView(
                        stripeWidth1: stripeWidth1,
                        stripeWidth2: stripeWidth2,
                        spacing: spacing,
                        rotation: rotation,
                        color1: color1,
                        color2: color2,
                        size: geometry.size
                    )
                    .mask(
                        content
                            .foregroundColor(.white)
                    )
                }
            )
    }
}

// MARK: - Enhanced Striped View
struct StripedView: View {
    var stripeWidth1: CGFloat
    var stripeWidth2: CGFloat
    var spacing: CGFloat
    var rotation: Double
    var color1: Color
    var color2: Color
    var size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Calculate total width of one pattern cycle (color1 + spacing + color2 + spacing)
            let patternUnit = stripeWidth1 + stripeWidth2 + spacing * 2
            
            // Calculate the diagonal length to ensure we cover the entire shape after rotation
            let diagonalLength = sqrt(pow(size.width, 2) + pow(size.height, 2))
            
            // Calculate how many pattern cycles we need
            let numberOfPatterns = Int(ceil(diagonalLength / patternUnit)) * 2
            
            // Apply rotation from center
            let rotationInRadians = Angle(degrees: rotation).radians
            let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Create rotation transform
            let rotationTransform = CGAffineTransform(translationX: centerPoint.x, y: centerPoint.y)
                .rotated(by: rotationInRadians)
                .translatedBy(x: -centerPoint.x, y: -centerPoint.y)
            
            // Calculate the starting point (negative to ensure coverage after rotation)
            let startX = -diagonalLength / 2
            
            // Draw each pattern cycle
            for i in 0..<numberOfPatterns {
                // Calculate the start position for this pattern cycle
                let patternStartX = startX + CGFloat(i) * patternUnit
                
                // Create a rectangle for color1 stripe
                var color1StripePath = Path()
                color1StripePath.addRect(CGRect(
                    x: patternStartX,
                    y: -diagonalLength / 2,
                    width: stripeWidth1,
                    height: diagonalLength * 2
                ))
                
                // Apply rotation to the path
                color1StripePath = color1StripePath.applying(rotationTransform)
                
                // Draw color1 stripe
                context.fill(color1StripePath, with: .color(color1))
                
                // Create a rectangle for color2 stripe
                var color2StripePath = Path()
                color2StripePath.addRect(CGRect(
                    x: patternStartX + stripeWidth1 + spacing,
                    y: -diagonalLength / 2,
                    width: stripeWidth2,
                    height: diagonalLength * 2
                ))
                
                // Apply rotation to the path
                color2StripePath = color2StripePath.applying(rotationTransform)
                
                // Draw color2 stripe
                context.fill(color2StripePath, with: .color(color2))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}


// MARK: - Semicircle Shape
struct SemicircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        return path
    }
}

// MARK: - Art Deco Semicircle with Radial Sections and Silver Border
struct ArtDecoSemicircle: View {
    var width: CGFloat
    var height: CGFloat
    var sectionCount: Int
    var color1: Color
    var color2: Color
    var strokeWidth: CGFloat
    var borderWidth: CGFloat = 3  // Width of the silver border
    var borderColor: Color = Color(red: 0.75, green: 0.75, blue: 0.8) // Silver color
    
    var body: some View {
        ZStack {
            // Inner alternating color semicircle
            Circle()
                .trim(from: 0, to: 0.5) // Make it a semicircle
                .stroke(
                    RadialAlternatingColors(count: sectionCount, color1: color1, color2: color2),
                    lineWidth: strokeWidth
                )
                .frame(width: width, height: width) // Using width for both to ensure a perfect circle
            
            // Outer silver border (slightly larger)
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: width + strokeWidth + borderWidth,
                       height: width + strokeWidth + borderWidth)
            
            // Inner silver border
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: width - strokeWidth - borderWidth,
                       height: width - strokeWidth - borderWidth)
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Radial Alternating Color Shader
struct RadialAlternatingColors: ShapeStyle {
    var count: Int
    var color1: Color
    var color2: Color
    
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        AngularGradient(
            colors: createAlternatingColors(),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
    
    private func createAlternatingColors() -> [Color] {
        var colors: [Color] = []
        // We need 2x the count to create full alternating sections
        for i in 0..<(count * 2) {
            colors.append(i % 2 == 0 ? color1 : color2)
        }
        return colors
    }
}

// MARK: - Alternative Implementation Using Shape
struct RadialSectionsShape: Shape {
    var count: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate center and radius
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Calculate angle for each section
        let sectionAngle = 2 * .pi / Double(count)
        
        // Draw each section
        for i in 0..<count {
            let startAngle = Double(i) * sectionAngle
            let endAngle = startAngle + sectionAngle
            
            // Create a wedge/section
            var sectionPath = Path()
            sectionPath.move(to: center)
            sectionPath.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(radians: startAngle),
                endAngle: Angle(radians: endAngle),
                clockwise: false
            )
            sectionPath.closeSubpath()
            
            // Add to main path
            path.addPath(sectionPath)
        }
        
        return path
    }
}

// MARK: - Alternative Semicircle Implementation
struct AlternativeArtDecoSemicircle: View {
    var width: CGFloat
    var height: CGFloat
    var sectionCount: Int
    var color1: Color
    var color2: Color
    var strokeWidth: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Create alternating colored sections
                ForEach(0..<sectionCount, id: \.self) { i in
                    SectionWedge(
                        index: i,
                        count: sectionCount,
                        color: i % 2 == 0 ? color1 : color2
                    )
                }
            }
            .frame(width: width, height: width) // Square frame for the circle
            .clipShape(
                // Clip to make it a semicircle
                Circle()
                    .trim(from: 0, to: 0.5)
                    .rotation(Angle(degrees: 180))
            )
            // Cut out the inner circle to create the stroke effect
            .mask(
                ZStack {
                    Circle()
                    Circle()
                        .scaleEffect((width - strokeWidth * 2) / width)
                        .blendMode(.destinationOut)
                }
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Helper for creating a single section wedge
struct SectionWedge: View {
    var index: Int
    var count: Int
    var color: Color
    
    var body: some View {
        let angle = 360.0 / Double(count)
        let startAngle = Double(index) * angle
        let endAngle = startAngle + angle
        
        Path { path in
            path.move(to: .zero)
            path.addArc(
                center: .zero,
                radius: 1000, // Large enough to cover the view
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
        .frame(width: 0, height: 0) // Zero size to position at center
    }
}

// MARK: - Stripe Configuration
struct StripeConfig {
    var width: CGFloat
    var color: Color
    var gradient: Gradient?
    
    init(width: CGFloat, color: Color) {
        self.width = width
        self.color = color
        self.gradient = nil
    }
    
    init(width: CGFloat, gradient: Gradient) {
        self.width = width
        self.color = .clear // Color won't be used when gradient is provided
        self.gradient = gradient
    }
    
    var isGradient: Bool {
        return gradient != nil
    }
}

// MARK: - Multi-Stripe Pattern Modifier
struct MultiStripePattern: ViewModifier {
    var stripes: [StripeConfig]
    var spacing: CGFloat
    var rotation: Double // in degrees, 0 = vertical stripes
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    MultiStripeView(
                        stripes: stripes,
                        spacing: spacing,
                        rotation: rotation,
                        size: geometry.size
                    )
                    .mask(
                        content
                            .foregroundColor(.white)
                    )
                }
            )
    }
}

// MARK: - Multi-Stripe View
struct MultiStripeView: View {
    var stripes: [StripeConfig]
    var spacing: CGFloat
    var rotation: Double
    var size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Calculate total width of one pattern cycle (sum of all stripes + spacings)
            let patternWidth = calculatePatternWidth()
            
            // Calculate the diagonal length to ensure we cover the entire shape after rotation
            let diagonalLength = sqrt(pow(size.width, 2) + pow(size.height, 2))
            
            // Calculate how many pattern cycles we need
            let numberOfPatterns = Int(ceil(diagonalLength / patternWidth)) * 2
            
            // Apply rotation from center
            let rotationInRadians = Angle(degrees: rotation).radians
            let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Create rotation transform
            let rotationTransform = CGAffineTransform(translationX: centerPoint.x, y: centerPoint.y)
                .rotated(by: rotationInRadians)
                .translatedBy(x: -centerPoint.x, y: -centerPoint.y)
            
            // Calculate the starting point (negative to ensure coverage after rotation)
            let startX = -diagonalLength / 2
            
            // Draw each pattern cycle
            for i in 0..<numberOfPatterns {
                // Calculate the start position for this pattern cycle
                let patternStartX = startX + CGFloat(i) * patternWidth
                
                // Current X position within the pattern
                var currentX = patternStartX
                
                // Draw each stripe in the pattern
                for stripe in stripes {
                    // Create a rectangle for this stripe
                    var stripePath = Path()
                    stripePath.addRect(CGRect(
                        x: currentX,
                        y: -diagonalLength / 2,
                        width: stripe.width,
                        height: diagonalLength * 2
                    ))
                    
                    // Apply rotation to the path
                    stripePath = stripePath.applying(rotationTransform)
                    
                    // Draw the stripe with either solid color or gradient
                    if let gradient = stripe.gradient {
                        // Create a gradient for this specific stripe
                        let gradientRect = CGRect(
                            x: currentX,
                            y: -diagonalLength / 2,
                            width: stripe.width,
                            height: diagonalLength * 2
                        )
                        
                        let transformedRect = gradientRect.applying(rotationTransform)
                        
                        let gradientStyle = GraphicsContext.Shading.linearGradient(
                            Gradient(colors: gradient.stops.map { $0.color }),
                            startPoint: CGPoint(x: transformedRect.minX, y: transformedRect.midY),
                            endPoint: CGPoint(x: transformedRect.maxX, y: transformedRect.midY)
                        )
                        
                        context.fill(stripePath, with: gradientStyle)
                    } else {
                        // Use solid color
                        context.fill(stripePath, with: .color(stripe.color))
                    }
                    
                    // Move to the next position (stripe width + spacing)
                    currentX += stripe.width + spacing
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    // Calculate the total width of one complete pattern
    private func calculatePatternWidth() -> CGFloat {
        let stripeWidthsSum = stripes.reduce(0) { $0 + $1.width }
        let spacingSum = spacing * CGFloat(stripes.count) // Add spacing after each stripe
        return stripeWidthsSum + spacingSum
    }
}

// MARK: - View Extension for Multi-Stripe Usage
extension View {
    // Method for multiple stripe configurations
    func multiStriped(
        stripes: [StripeConfig],
        spacing: CGFloat = 2,
        rotation: Double = 0 // 0 = vertical stripes
    ) -> some View {
        self.modifier(MultiStripePattern(
            stripes: stripes,
            spacing: spacing,
            rotation: rotation
        ))
    }
    
    // Convenience method for two-color stripes with individual widths
    func striped(
        stripeWidth1: CGFloat = 4,
        stripeWidth2: CGFloat = 4,
        spacing: CGFloat = 2,
        rotation: Double = 0, // 0 = vertical stripes
        color1: Color = .clear,
        color2: Color = .black
    ) -> some View {
        self.multiStriped(
            stripes: [
                StripeConfig(width: stripeWidth1, color: color1),
                StripeConfig(width: stripeWidth2, color: color2)
            ],
            spacing: spacing,
            rotation: rotation
        )
    }
    
    // Gradient version for two stripes
    func stripedGradient(
        stripeWidth1: CGFloat = 4,
        stripeWidth2: CGFloat = 4,
        spacing: CGFloat = 2,
        rotation: Double = 0,
        gradient1: Gradient,
        gradient2: Gradient
    ) -> some View {
        self.multiStriped(
            stripes: [
                StripeConfig(width: stripeWidth1, gradient: gradient1),
                StripeConfig(width: stripeWidth2, gradient: gradient2)
            ],
            spacing: spacing,
            rotation: rotation
        )
    }
}

// MARK: - Repeating Gradient Pattern Modifier
struct RepeatingGradientPattern: ViewModifier {
    var colors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    var repetitions: Int
    var rotation: Double // in degrees
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    RepeatingGradientView(
                        colors: colors,
                        startPoint: startPoint,
                        endPoint: endPoint,
                        repetitions: repetitions,
                        rotation: rotation,
                        size: geometry.size
                    )
                    .mask(
                        content
                            .foregroundColor(.white)
                    )
                }
            )
    }
}

// MARK: - Repeating Gradient View
struct RepeatingGradientView: View {
    var colors: [Color]
    var startPoint: UnitPoint
    var endPoint: UnitPoint
    var repetitions: Int
    var rotation: Double
    var size: CGSize
    
    var body: some View {
        Canvas { context, size in
            // Create gradient with repetitions
            let steps = colors.count * repetitions
            
            // Calculate gradient stops with repetitions
            var stops: [Gradient.Stop] = []
            for i in 0..<steps {
                let colorIndex = i % colors.count
                let position = Double(i) / Double(steps - 1)
                stops.append(Gradient.Stop(color: colors[colorIndex], location: position))
            }
            
            let gradient = Gradient(stops: stops)
            
            // Create rectangular path for the gradient
            var path = Path(CGRect(origin: .zero, size: size))
            
            // Calculate transform for rotation
            let rotationInRadians = Angle(degrees: rotation).radians
            let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Create rotation transform
            let rotationTransform = CGAffineTransform(translationX: centerPoint.x, y: centerPoint.y)
                .rotated(by: rotationInRadians)
                .translatedBy(x: -centerPoint.x, y: -centerPoint.y)
            
            // Apply rotation
            path = path.applying(rotationTransform)
            
            // Convert UnitPoints to actual points
            let startPt = CGPoint(
                x: size.width * startPoint.x,
                y: size.height * startPoint.y
            )
            
            let endPt = CGPoint(
                x: size.width * endPoint.x,
                y: size.height * endPoint.y
            )
            
            // Create the gradient shader
            let shader = GraphicsContext.Shading.linearGradient(
                gradient,
                startPoint: startPt,
                endPoint: endPt
            )
            
            // Draw the gradient
            context.fill(path, with: shader)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - View Extension for easy usage
extension View {
    func repeatingGradient(
        colors: [Color],
        startPoint: UnitPoint = .leading,
        endPoint: UnitPoint = .trailing,
        repetitions: Int = 1,
        rotation: Double = 0 // 0 = horizontal gradient
    ) -> some View {
        self.modifier(RepeatingGradientPattern(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint,
            repetitions: repetitions,
            rotation: rotation
        ))
    }
}

// MARK: - Predefined Gradient Patterns
struct GradientPattern {
    static let rainbow = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple]
    static let sunset = [Color.orange, Color.red, Color.purple]
    static let ocean = [Color.blue, Color.cyan, Color.blue.opacity(0.7)]
    static let greyscale = [Color.black, Color.gray, Color.white, Color.gray]
    static let fire = [Color.yellow, Color.orange, Color.red]
    
    // Create a two-color alternating pattern
    static func alternating(_ color1: Color, _ color2: Color) -> [Color] {
        return [color1, color2]
    }
    
    // Create a smooth transition between two colors
    static func smooth(_ color1: Color, _ color2: Color) -> [Color] {
        return [color1, color2, color1]
    }
}

// MARK: - Example Usage
struct GradientPatternDemo: View {
    @State private var rotation: Double = 0
    @State private var repetitions: Int = 3
    @State private var selectedPattern: [Color] = GradientPattern.rainbow
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Repeating Gradient Patterns")
                .font(.headline)
            
            // Examples with different shapes
            HStack(spacing: 15) {
                // Circle with rainbow gradient
                Circle()
                    .frame(width: 80, height: 80)
                    .repeatingGradient(
                        colors: GradientPattern.rainbow,
                        repetitions: repetitions,
                        rotation: rotation
                    )
                
                // Rectangle with sunset gradient
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 80, height: 80)
                    .repeatingGradient(
                        colors: GradientPattern.sunset,
                        repetitions: repetitions,
                        rotation: rotation + 45
                    )
                
                // Custom shape with ocean gradient
                Diamond()
                    .frame(width: 80, height: 80)
                    .repeatingGradient(
                        colors: GradientPattern.ocean,
                        repetitions: repetitions,
                        rotation: rotation + 90
                    )
            }
            
            // Controls for adjusting the pattern
            VStack {
                Text("Rotation: \(Int(rotation))°")
                Slider(value: $rotation, in: 0...360)
                    .padding(.horizontal)
                
                Text("Repetitions: \(repetitions)")
                Slider(value: Binding(
                    get: { Double(repetitions) },
                    set: { self.repetitions = max(1, Int($0)) }
                ), in: 1...10, step: 1)
                    .padding(.horizontal)
            }
            
            // Pattern selection buttons
            VStack(alignment: .leading) {
                Text("Gradient Pattern:")
                    .font(.subheadline)
                
                HStack {
                    Button("Rainbow") { selectedPattern = GradientPattern.rainbow }
                    Button("Sunset") { selectedPattern = GradientPattern.sunset }
                    Button("Ocean") { selectedPattern = GradientPattern.ocean }
                }
                
                HStack {
                    Button("Greyscale") { selectedPattern = GradientPattern.greyscale }
                    Button("Fire") { selectedPattern = GradientPattern.fire }
                }
            }
            
            // Large example with the selected pattern
            RoundedRectangle(cornerRadius: 12)
                .frame(height: 120)
                .repeatingGradient(
                    colors: selectedPattern,
                    repetitions: repetitions,
                    rotation: rotation
                )
                .padding()
        }
        .padding()
    }
}

// MARK: - Custom Diamond Shape for Demo
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        
        return path
    }
}
