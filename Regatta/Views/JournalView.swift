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
                if sessionStore.isLoading {
                    ProgressView("Loading sessions...")
                } else if sessionStore.sessions.isEmpty {
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
            .refreshable {
                print("📱 JournalView: Pull to refresh triggered")
                await withCheckedContinuation { continuation in
                    Task { @MainActor in
                        sessionStore.refreshSessions()
                        continuation.resume()
                    }
                }
                print("📱 JournalView: Refresh completed")
            }
        }
        .onAppear {
            print("📱 JournalView: View appeared")
            sessionStore.loadSessions()
        }
    }
}

struct SessionRowView: View {
    let session: RaceSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.formattedDate())
                    .font(.system(.headline))
                Spacer()
                Text("\(session.formattedTime()) \(session.timeZoneString())")
                    .font(.system(.headline))
            }
            
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

// MARK: - Previews
#Preview("Journal View - With Sessions") {
    let mockSessions = [
        RaceSession(
            date: Date(),
            countdownDuration: 5,
            raceStartTime: Date().addingTimeInterval(-300),
            raceDuration: 125.43
        ),
        RaceSession(
            date: Date().addingTimeInterval(-3600),
            countdownDuration: 3,
            raceStartTime: Date().addingTimeInterval(-3900),
            raceDuration: 98.76
        )
    ]
    
    return JournalView()
        .previewDisplayName("With Sessions")
        .onAppear {
            SharedDefaults.saveSessionsToContainer(mockSessions)
        }
}

#Preview("Journal View - Empty") {
    JournalView()
        .previewDisplayName("Empty State")
        .onAppear {
            SharedDefaults.saveSessionsToContainer([])
        }
}

#Preview("Session Row") {
    let mockSession = RaceSession(
        date: Date(),
        countdownDuration: 5,
        raceStartTime: Date().addingTimeInterval(-300),
        raceDuration: 125.43
    )
    
    return List {
        SessionRowView(session: mockSession)
    }
}
