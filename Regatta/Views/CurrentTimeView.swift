//
//  CurrentTimeView.swift
//  Regatta
//
//  Created by Chikai Lai on 17/11/2024.
//

import SwiftUI

struct CurrentTimeView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString(from: currentTime))
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.cyan)
            .onReceive(timer) { input in
                currentTime = input
            }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
