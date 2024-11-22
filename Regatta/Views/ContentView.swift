//
//  ContentView.swift
//  Regatta
//
//  Created by Chikai Lai on 16/11/2024.
//

import SwiftUI

struct ContentView: View {
//    @StateObject private var timerState = WatchTimerState()
//    @State private var timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                // Title

                Spacer()
                    .frame(height: 10)
                
                Text("Regatta")
                    .font(.system(size: 36, weight: .bold, design: .monospaced).italic())
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
                
                Text("made for sailing athletes")
                    .font(.system(size: 16, design: .monospaced).italic())
                    .foregroundColor(.orange)
                    .padding(.bottom, 20)
                
                Spacer()
                    .frame(height: 50)
                
                // Support link
                Link("contact and support",
                     destination: URL(string: "mailto:placeholder@email.com")!)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
            }
            .multilineTextAlignment(.center)
        }
//        .onReceive(timer) { _ in
//            timerState.updateTimer()
//        }
    }
}

// Preview
#Preview {
    ContentView()
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
