//
//  WeeklyPromoView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 15/02/2025.
//

import Foundation
import SwiftUI

// UserDefaults extension for managing the last shown date
extension UserDefaults {
    static let lastPromoShowDateKey = "lastPromoShowDate"
    
    static func getLastPromoShowDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastPromoShowDateKey) as? Date
    }
    
    static func setLastPromoShowDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastPromoShowDateKey)
    }
}

// The promotional view
struct WeeklyPromoView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Welcome!")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("To keep the app open while sailing, go to")
                .font(.system(size: 16))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap

            Text("Settings > General > Return to Clock")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            Text("Set to After 1 hour")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            
            Button("Continue") {
                isPresented = false
                UserDefaults.setLastPromoShowDate(Date())
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    WeeklyPromoView(isPresented: .constant(true))
}
