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
    
    private func groupedSessions() -> [String: [RaceSession]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return Dictionary(grouping: sessionStore.sessions) { session in
            formatter.string(from: session.date)
        }
    }
    
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
                        ForEach(groupedSessions().keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(date)) {
                                ForEach(groupedSessions()[date]!.sorted(by: { $0.date > $1.date }), id: \.date) { session in
                                    SessionRowView(session: session)
                                }
                            }
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
//                Text(session.formattedDate())
//                    .font(.system(.headline))
//                Spacer()
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
        // Today
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
        ),
        // Yesterday
        RaceSession(
            date: Date().addingTimeInterval(-86400),
            countdownDuration: 5,
            raceStartTime: Date().addingTimeInterval(-86700),
            raceDuration: 145.30
        ),
        // Last week
        RaceSession(
            date: Date().addingTimeInterval(-604800),
            countdownDuration: 4,
            raceStartTime: Date().addingTimeInterval(-605100),
            raceDuration: 112.20
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
