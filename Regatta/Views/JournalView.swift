//
//  JournalView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import SwiftUI

struct JournalView: View {
    //@StateObject private var journalManager = JournalManager.shared
    
    var body: some View {
        //List(journalManager.allSessions.reversed(), id: \.date) { session in
            VStack(alignment: .leading, spacing: 4) {
                Text("Countdown: 0 min")
//                Text("Countdown: \(session.countdownDuration) min")
                    .font(.headline)
                Text("Start: 0")
//                Text("Start: \(session.formattedStartTime)")
                    .font(.subheadline)
                Text("Race Time: 0")
//                Text("Race Time: \(session.formattedRaceTime)")
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
