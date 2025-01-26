//
//  StartLineView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 26/01/2025.
//

import Foundation
import SwiftUI
import WatchKit

struct StartLineView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var startLineManager: StartLineManager
    
    func getButtonImage(state: StartLineManager.ButtonState, isLeft: Bool) -> Image {
        if state == .red {
            return Image(systemName: "xmark")
        }
        return Image(systemName: isLeft ? "triangle.fill" : "square.fill")
    }
    
    var body: some View {
        ZStack {
            if startLineManager.leftButtonState == .green && startLineManager.rightButtonState == .green {
                ZStack {
                    Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .frame(height: 24)
                        .frame(maxWidth: 84)
                    
                    Text("START")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack {
                        
                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height:24)
                        
                        Spacer().frame(width: 55)

                        Circle()
                            .fill(Color.black)
                            .frame(width: 24, height:24)
                        
                    }
                }
            }
            
            HStack(spacing: 0) {
                Button {
                    startLineManager.handleLeftButtonPress(currentLocation: locationManager.lastLocation)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    getButtonImage(state: startLineManager.leftButtonState, isLeft: true)
                        .font(.system(size: 16))
                        .foregroundColor(getButtonColor(state: startLineManager.leftButtonState))
                        .frame(width: 24, height: 24)
                        .background(getButtonColor(state: startLineManager.leftButtonState).opacity(0.5))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(getButtonColor(state: startLineManager.leftButtonState), lineWidth: 0)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(startLineManager.leftButtonState == .disabled)
                
                Spacer().frame(width: 55)
                
                Button {
                    startLineManager.handleRightButtonPress(currentLocation: locationManager.lastLocation)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    getButtonImage(state: startLineManager.rightButtonState, isLeft: false)
                        .font(.system(size: 16))
                        .foregroundColor(getButtonColor(state: startLineManager.rightButtonState))
                        .frame(width: 24, height: 24)
                        .background(getButtonColor(state: startLineManager.rightButtonState).opacity(0.5))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(getButtonColor(state: startLineManager.rightButtonState), lineWidth: 0)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(startLineManager.rightButtonState == .disabled)
            }
        }
        .onAppear {
            updateButtonStates()
        }
        .onChange(of: locationManager.isLocationValid) { _ in
            updateButtonStates()
        }
    }
    
    private func getButtonColor(state: StartLineManager.ButtonState) -> Color {
        switch state {
        case .white:
            return .white
        case .green:
            return .green
        case .red:
            return .red
        case .disabled:
            return .white.opacity(0.3)
        }
    }
    
    private func updateButtonStates() {
        print("🔄 Updating button states")
        print("📱 Location valid: \(locationManager.isLocationValid)")
        print("📍 Last location: \(String(describing: locationManager.lastLocation))")
        
        if !locationManager.isLocationValid {
            print("⚠️ Location invalid - disabling buttons")
            if startLineManager.leftButtonState == .white {
                startLineManager.leftButtonState = .disabled
            }
            if startLineManager.rightButtonState == .white {
                startLineManager.rightButtonState = .disabled
            }
        } else {
            print("✅ Location valid - enabling buttons")
            if startLineManager.leftButtonState == .disabled {
                startLineManager.leftButtonState = .white
            }
            if startLineManager.rightButtonState == .disabled {
                startLineManager.rightButtonState = .white
            }
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
struct PreviewStartLineView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var startLineManager = StartLineManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                StartLineView(
                    locationManager: locationManager,
                    startLineManager: startLineManager
                )
            }
        }
    }
}

#Preview {
    PreviewStartLineView()
        .frame(width: 180, height: 180)
}
#endif
