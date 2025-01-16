//
//  SecondProgressBarView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 01/12/2024.
//

import Foundation
import SwiftUI

struct SecondProgressBarView: View {
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings

    @State private var currentSecond: Double = 0
    @State private var timer = Timer.publish(every: AppSettings().timerInterval, on: .main, in: .common).autoconnect()

    
    private func updateSecond() {
        let components = Calendar.current.dateComponents([.second, .nanosecond], from: Date())
        
        // If timer interval is 1 second, only update on exact seconds
        if settings.timerInterval == 1.0 {
            currentSecond = Double(components.second!)
        } else {
            // For smooth animation, include nanoseconds
            currentSecond = Double(components.second!) + Double(components.nanosecond!) / 1_000_000_000
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            let barWidth = frame.width
            let barHeight = frame.height
            
            ZStack {
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .stroke(Color(hex: colorManager.selectedTheme.rawValue).opacity(0.3), lineWidth: 25)
                        .frame(width: barWidth, height: barHeight)
                        .position(x: frame.midX, y: frame.midY)
                // Progress fill for seconds
                    RoundedRectangle(cornerRadius: settings.ultraModel ? 55 : 42)
                        .trim(from: 0, to: currentSecond/60)
                        .stroke(
                            Color(hex: colorManager.selectedTheme.rawValue),
                            style: StrokeStyle(lineWidth: 25, lineCap: .butt)
                        )
                        .frame(width: barHeight, height: barWidth)
                        .position(x: frame.midX, y: frame.midY)
                        .rotationEffect(.degrees(-90))  // Align trim start to top
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Initialize the second value immediately when view appears
            updateSecond()
        }
        .onReceive(timer) { _ in
            // Regular timer updates
            updateSecond()
        }
    }
}
