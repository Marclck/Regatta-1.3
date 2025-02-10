//
//  UltraTrialPromotionSheet.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 10/02/2025.
//

import SwiftUI

struct UltraTrialPromotionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var iapManager = IAPManager.shared
    var showSettings: Binding<Bool>
    @State private var isStartingTrial = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var timer: Timer?
    @State private var trialTimeRemaining: TimeInterval = 7 * 24 * 60 * 60 // 7 days in seconds
    
    var formattedTimeRemaining: String {
        let days = Int(trialTimeRemaining / (24 * 60 * 60))
        let hours = Int((trialTimeRemaining.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Ultra Free Trial")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("As a Pro subscriber, you have a 7-day free access to Ultra features.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("**Dashboard**")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("**ProControl**")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("**CruiseMode**")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                
                if isStartingTrial {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Trial period remaining")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(formattedTimeRemaining)
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showSettings.wrappedValue = true
                    dismiss()
                }) {
                    Text("**Open Settings**")
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error)
        }
        .onAppear {
            startTrialCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTrialCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if trialTimeRemaining > 0 {
                trialTimeRemaining -= 1
            } else {
                timer?.invalidate()
                startTrial()
            }
        }
    }
    
    private func startTrial() {
        isStartingTrial = true
        
        Task {
            do {
                try await iapManager.startProUltraTrialFromPrompt()
                await MainActor.run {
                    showSettings.wrappedValue = true
                    dismiss()
                }
            } catch let error as IAPError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isStartingTrial = false
                    trialTimeRemaining = 7 * 24 * 60 * 60
                    startTrialCountdown()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred"
                    showError = true
                    isStartingTrial = false
                    trialTimeRemaining = 7 * 24 * 60 * 60
                    startTrialCountdown()
                }
            }
        }
    }
}

#if DEBUG
private class MockIAPManager: ObservableObject {
    static let shared = MockIAPManager()
    
    func startProUltraTrialFromPrompt() async throws {
        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
    }
}

struct UltraTrialPromotionSheet_Previews: PreviewProvider {
    static var previews: some View {
        UltraTrialPromotionSheet(showSettings: .constant(false))
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra"))
            .previewDisplayName("Watch Ultra")
        
        UltraTrialPromotionSheet(showSettings: .constant(false))
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 9 - 45mm"))
            .previewDisplayName("Series 9 45mm")
    }
}
#endif
