//
//  SettingsView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/12/2024.
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    // Timer interval in seconds (1.0 when smooth is off, 0.01 when on)
    var timerInterval: Double {
        return smoothSecond ? 0.01 : 1.0
    }
    
    // Team name color hex value (ultraBlue when on, speedPapaya when off)
    var teamNameColorHex: String {
        return altTeamNameColor ? "#000000" : ColorTheme.speedPapaya.rawValue
    }
    
    @Published var teamName: String {
        didSet {
            UserDefaults.standard.set(teamName, forKey: "teamName")
            print("Team name changed to: \(teamName)") // Debug print
        }
    }
    
    @Published var showRaceInfo: Bool {
        didSet {
            UserDefaults.standard.set(showRaceInfo, forKey: "showRaceInfo")
            print("ShowRaceInfo changed to: \(showRaceInfo)") // Debug print
        }
    }
    
    @Published var smoothSecond: Bool {
        didSet {
            UserDefaults.standard.set(smoothSecond, forKey: "smoothSecond")
            print("SmoothSecond changed to: \(smoothSecond)") // Debug print
        }
    }
    
    @Published var altTeamNameColor: Bool {
        didSet {
            UserDefaults.standard.set(altTeamNameColor, forKey: "altTeamNameColor")
            print("AltTeamNameColor changed to: \(altTeamNameColor)") // Debug print
        }
    }
    
    @Published var lightMode: Bool {
        didSet {
            UserDefaults.standard.set(lightMode, forKey: "lightMode")
            print("LightMode changed to: \(lightMode)")
        }
    }
    
    @Published var ultraModel: Bool {
        didSet {
            UserDefaults.standard.set(ultraModel, forKey: "ultraModel")
            print("UltraModel changed to: \(ultraModel)")
        }
    }
    
    init() {
        self.teamName = UserDefaults.standard.string(forKey: "teamName") ?? "Ultra"
        self.showRaceInfo = UserDefaults.standard.bool(forKey: "showRaceInfo")
        self.smoothSecond = UserDefaults.standard.bool(forKey: "smoothSecond")
        self.altTeamNameColor = UserDefaults.standard.bool(forKey: "altTeamNameColor")
        self.lightMode = UserDefaults.standard.bool(forKey: "lightMode")
        self.ultraModel = UserDefaults.standard.object(forKey: "ultraModel") as? Bool ?? true
        UserDefaults.standard.synchronize()  // Force save
    }
}

struct SettingsView: View {
    @EnvironmentObject var colorManager: ColorManager
    @StateObject private var settings = AppSettings()
    @Binding var showSettings: Bool
    @State private var showThemePicker = false
    @State private var showTeamNameEdit = false
    @State private var refreshToggle = false  // Add at top with other state variables
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            // Settings content
            List {
                // Theme Color Button
                Button(action: {
                    showThemePicker.toggle()
                }) {
                    HStack {
                        Text("Theme Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: colorManager.selectedTheme.rawValue))
                            .frame(width: 16, height: 16)
                    }
                }
                .sheet(isPresented: $showThemePicker) {
                    List {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Button(action: {
                                colorManager.selectedTheme = theme
                                showThemePicker = false
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: theme.rawValue))
                                        .frame(width: 20, height: 20)
                                    Text(theme.name)
                                    Spacer()
                                    if colorManager.selectedTheme == theme {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Team Name Button
                Button(action: {
                    showTeamNameEdit.toggle()
                }) {
                    HStack {
                        Text("Team Name")
                        Spacer()
                        Text(settings.teamName)
                            .foregroundColor(.gray)
                    }
                }
                .sheet(isPresented: $showTeamNameEdit) {
                    List {
                        Section {
                            TextField("Team Name", text: $settings.teamName)
                                .onChange(of: settings.teamName) { _, newValue in
                                    settings.teamName = String(newValue.prefix(14))
                                }
                            Text("\(14 - settings.teamName.count) characters remaining")
                                .font(.caption2)
                        }
                        
                        Button("Reset to Default") {
                            settings.teamName = "RACE!"
                            showTeamNameEdit = false
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Toggle("Ultra Model", isOn: $settings.ultraModel)
                
                // Race Info Toggle
                Toggle("Race Info", isOn: $settings.showRaceInfo)
                
                // Smooth Second Toggle
                Toggle("Smooth Second Movement", isOn: $settings.smoothSecond)
                
                // Alt Team Name Color Toggle
                Toggle("Alt Team Name Color", isOn: $settings.altTeamNameColor)
                
                Toggle("Light Mode", isOn: $settings.lightMode)

                
                Text("Restart the app for the changes to take effect. Double press digital crown and swipe left to close the app.")
                    .font(.caption2)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSettings: .constant(true))
            .environmentObject(ColorManager())
    }
}
