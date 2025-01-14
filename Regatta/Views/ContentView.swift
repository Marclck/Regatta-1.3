//
//  ContentView.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    @EnvironmentObject var colorManager: ColorManager


    var body: some View {
        TabView {
            // Journal Tab
            JournalView()
                .environmentObject(colorManager)  // Add explicitly
                .tabItem {
                    Label("Journal", systemImage: "book.closed.circle.fill")
                }

            MainInfoView()
                .environmentObject(colorManager)  // Add explicitly
                .tabItem {
                    Label("Info", systemImage: "timer.circle.fill")
                }
            
            // settings
//            SettingsView()
//                .environmentObject(colorManager)  // Add explicitly
//                .tabItem {
//                    Label("Settings", systemImage: "gear.circle.fill")
//                }
        }
    }
}

// Move existing content to new MainInfoView
struct MainInfoView: View {
    @StateObject private var timerState = TimerState()
    @ObservedObject private var iapManager = IAPManager.shared

    
    var body: some View {
        NavigationView {
            List {
                
                Section("App Access") {
                    NavigationLink(destination: SubscriptionView()) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading) {
                                Text("Astrolabe Pro")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Text(iapManager.isPremiumUser ? "Active" : "7-day free trial, $5.99/year after") //update!!
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("What is Astrolabe?") {
                    HStack {
                        Image(systemName: "sailboat.fill")
                        Text("Race countdown timer & sailing stopwatch")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "timer.circle.fill")
                        Text("Set countdown from 1-30 minutes for race start sequence")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "stopwatch.fill")
                        Text("Auto-transitions to stopwatch at zero for race timing")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack{
                        Image(systemName: "applewatch")
                        Text("Designed for Apple Watch Ultra with iPhone companion app")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                }
                
                Section("How to Use") {
                    HStack {
                        Image(systemName: "1.circle.fill")
                        Text("Open the Watch app")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "2.circle.fill")
                        Text("Set countdown duration (1-30 minutes)")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "3.circle.fill")
                        Text("Start the countdown")
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    HStack {
                        Image(systemName: "4.circle.fill")
                        Text("Countdown automatically transitions to stopwatch at zero")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "6.circle.fill")
                        Text("Stop the timer to record your race; session stopped before stopwatch started will not be recorded")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "5.circle.fill")
                        Text("Add complication to your watch face for quick timer access")
                    }
                    .font(.system(.body, design: .monospaced))

                }
                
                Section("Features") {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Haptic feedback at key moments")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Runs in background with notifications")
                    }
                    .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        Image(systemName: "book.closed.fill")
                        Text("Race history stored in Journal")
                    }
                    .font(.system(.body, design: .monospaced))
                }
                
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Text("made for sailing enthusiasts")
                            .font(.system(.subheadline, design: .monospaced))
                            .italic()
                            .foregroundColor(.secondary)
                        
//                        Link("contact | support | suggestion",
//                             destination: URL(string: "mailto:normalappco@gmail.com")!)
//                            .font(.system(.caption, design: .monospaced))
//                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("About")
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StartCountdownFromShortcut"),
                object: nil,
                queue: .main) { notification in
                    if let minutes = notification.userInfo?["minutes"] as? Int {
                        timerState.startFromShortcut(minutes: minutes)
                    }
                }
        }
    }
}

#Preview {
    MainInfoView()
}

// Preview
#Preview {
    ContentView()
        .environmentObject(ColorManager())

}

//struct ContentView: View {
//    @StateObject private var timerState = TimerState()
  //  @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    //var body: some View {
      //  ZStack {
        //    Color.black.edgesIgnoringSafeArea(.all)
            
            // Progress Bar
          //  ProgressBarView(timerState: timerState)
            
            // Main Content
            //VStack(spacing: 20) {
              //  CurrentTimeView()
                //    .padding(.top, 60)
                
                //Spacer()
                
                //TimeDisplayView(timerState: timerState)
                
               // Spacer()
                
               // ButtonsView(timerState: timerState)
                 //   .padding(.bottom, 80)
            //}
            //.padding(.horizontal)
        //}
        //.onReceive(timer) { _ in
          //  timerState.updateTimer()
        //}
    //}
//}
