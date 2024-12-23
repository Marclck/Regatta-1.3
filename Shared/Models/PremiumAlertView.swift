//
//  PremiumAlertView.swift
//  Regatta
//
//  Created by Chikai Lai on 22/12/2024.
//

import Foundation
import StoreKit
import SwiftUI

struct PremiumAlertView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var iapManager = IAPManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Premium Feature")
                .font(.headline)
            
            Text("Access advanced settings and customization options")
                .font(.caption)
                .multilineTextAlignment(.center)
            
            if isPurchasing {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        isPurchasing = true
                        do {
                            try await iapManager.purchasePremium()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isPurchasing = false
                    }
                }) {
                    Text("Unlock Premium")
                        .bold()
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
