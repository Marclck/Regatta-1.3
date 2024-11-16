//
//  ContentView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI
import AVFoundation
import AVKit

struct OverlayPlayerForTimeRemove: View {
    var body: some View {
        VideoPlayer(player: nil,videoOverlay: { })
        .focusable(false)
        .disabled(true)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
struct ContentView: View {
    @StateObject private var timerState = WatchTimerState()
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let centerY = geometry.size.height/2
                ZStack {
                
                    
                    // Progress bar and separators
                    WatchProgressBarView(timerState: timerState)
                    
                    // Content
                    VStack(spacing: 0) {
                        
                        CurrentTimeView()
                            .padding(.top, -10)
                        
                        Spacer()
                            .frame(height: 0) // Space after current time
                        
                        TimeDisplayView(timerState: timerState)
                            .frame(height: 150)  // Fixed height for picker
                            .position(x: geometry.size.width/2, y: centerY/2+10)
                        
                        Spacer()
                            .frame(height: 0) // Adjust this value to control space between picker and buttons
                        
                        ButtonsView(timerState: timerState)
                            .padding(.bottom, -10) // this control the position of the buttons to match numbers in timer and picker
                            .background(OverlayPlayerForTimeRemove())

                    }
                    .padding(.horizontal, 0)
                }
                .onReceive(timer) { _ in
                    timerState.updateTimer()
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
