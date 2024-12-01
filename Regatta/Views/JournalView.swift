//
//  JournalView.swift
//  Regatta
//
//  Created by Chikai Lai on 30/11/2024.
//

import Foundation
import SwiftUI

struct JournalView: View {
    @StateObject private var sessionStore = iOSSessionStore.shared
    
    var body: some View {
        NavigationView {
            Group {
                if sessionStore.sessions.isEmpty {
                    VStack {
                        Text("No race sessions recorded yet")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("Complete a race to see it here")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                } else {
                    List {
                        ForEach(sessionStore.sessions, id: \.date) { session in
                            SessionRowView(session: session)
                            
                            
                        }
                    }
                }
            }
            .navigationTitle("Race Journal")
        }
        .onAppear {
            sessionStore.loadSessions()
        }
    }
}

struct SessionRowView: View {
    let session: RaceSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.formattedStartTime)
                .font(.system(.headline, design: .monospaced))
            
            HStack {
                Text("Countdown: \(session.countdownDuration) min")
                Spacer()
                Text("Race: \(session.formattedRaceTime)")
            }
            .font(.system(.subheadline, design: .monospaced))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
