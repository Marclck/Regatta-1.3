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
            MainInfoView()
                .environmentObject(colorManager)  // Add explicitly
                .tabItem {
                    Label("Timer", systemImage: "timer.circle.fill")
                }

            // Journal Tab
            JournalView()
                .environmentObject(colorManager)  // Add explicitly
                .tabItem {
                    Label("Journal", systemImage: "book.closed.circle.fill")
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
//    @StateObject private var timerState = WatchTimerState()
//    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    @StateObject private var timerState = TimerState()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                // Title

                Spacer()
                    .frame(height: 10)
                
                Text("Regatta")
                    .font(.system(size: 40, weight: .bold, design: .monospaced).italic())
                    .foregroundColor(.cyan)
                
                Spacer()
                    .frame(height: 10)
                
                // Description
                Text("countdown timer")
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text("&")
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text("stopwatch")
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                    .frame(height: 2)
                
                Text("made for sailing enthusiasts")
                    .font(.system(size: 16, design: .monospaced).italic())
                    .foregroundColor(.orange)
                    .padding(.bottom, 20)
                
                Spacer()
                    .frame(height: 50)
                
                // Support link
                Link("contact | support | suggestion",
                     destination: URL(string: "mailto:normalappco@gmail.com")!)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
            }
            .multilineTextAlignment(.center)
        }
        
        .onAppear {
            // Add observer for shortcut
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("StartCountdownFromShortcut"),
                object: nil,
                queue: .main) { notification in
                    if let minutes = notification.userInfo?["minutes"] as? Int {
                        timerState.startFromShortcut(minutes: minutes)
                    }
                }
        }
        
//        .onReceive(timer) { _ in
//            timerState.updateTimer()
//        }
    }
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
