//
//  HeartRateDisplayView.swift
//  Regatta
//
//  Created by Chikai Lai on 21/01/2025.
//

import SwiftUI

protocol HeartRateManagerProtocol: ObservableObject {
    var heartRate: Double { get }
}

struct HeartRateDisplayView<Manager: HeartRateManagerProtocol>: View {
    @ObservedObject var heartRateManager: Manager
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Text("\(Int(heartRateManager.heartRate))")
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red,
                                Color.red.opacity(0.80),
                                Color.red
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50 * scale
                        )
                    )
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                }
            }
            .animation(.easeInOut(duration: 0.5), value: heartRateManager.heartRate)
    }
}

// MARK: - Preview Helpers
#if DEBUG
private class PreviewHeartRateManager: ObservableObject {
    @Published var heartRate: Double = 142
}

extension PreviewHeartRateManager: HeartRateManagerProtocol {}

struct PreviewHeartRateDisplayView: View {
    @StateObject private var heartRateManager = PreviewHeartRateManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                HeartRateDisplayView(
                    heartRateManager: heartRateManager
                )
            }
        }
    }
}

#Preview("Static Heart Rate") {
    PreviewHeartRateDisplayView()
        .frame(width: 180, height: 180)
}

#Preview("Changing Heart Rate") {
    PreviewHeartRateDisplayView()
        .frame(width: 180, height: 180)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                let previewManager = PreviewHeartRateManager()
                previewManager.heartRate = Double.random(in: 130...160)
            }
        }
}
#endif
