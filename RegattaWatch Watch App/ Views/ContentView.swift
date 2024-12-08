//
//  ContentView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI
import AVFoundation
import WatchKit
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
    @State private var showingWatchFace = false
    
    var body: some View {
        ZStack {
            if showingWatchFace {
                AltRaceView(timerState: timerState)
            } else {
                TimerView(timerState: timerState)
            }
            
            // Toggle overlay
            GeometryReader { geometry in
                Color.clear
                    //.opacity(0.5)
                    .frame(width: 80, height: 40) // Adjust to match CurrentTimeView size
                    .contentShape(Rectangle())
                    .position(x: geometry.size.width/2, y: geometry.size.height/2 - 90)
                    .onTapGesture {
                        print("!! watchface toggled")
                        withAnimation {
                            showingWatchFace.toggle()
                        }
                    }
            }
        }
    }
}
    
struct TimerView: View {
    @ObservedObject var timerState: WatchTimerState
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
                        
                        CurrentTimeView(timerState: timerState)
                            .padding(.top, -10)
                            .offset(y:-10)
                                                
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
                            .offset(y:5)

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
