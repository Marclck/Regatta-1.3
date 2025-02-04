//
//  SettingsView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/12/2024.
//

import Foundation
import SwiftUI
import CoreLocation

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
            print("Team name changed to: \(teamName)")
        }
    }
    
    @Published var showRaceInfo: Bool {
        didSet {
            UserDefaults.standard.set(showRaceInfo, forKey: "showRaceInfo")
            print("ShowRaceInfo changed to: \(showRaceInfo)")
        }
    }
    
    @Published var showSpeedInfo: Bool {
        didSet {
            UserDefaults.standard.set(showSpeedInfo, forKey: "showSpeedInfo")
            print("ShowSpeedInfo changed to: \(showSpeedInfo)")
        }
    }
    
    @Published var smoothSecond: Bool {
        didSet {
            UserDefaults.standard.set(smoothSecond, forKey: "smoothSecond")
            print("SmoothSecond changed to: \(smoothSecond)")
        }
    }
    
    @Published var altTeamNameColor: Bool {
        didSet {
            UserDefaults.standard.set(altTeamNameColor, forKey: "altTeamNameColor")
            print("AltTeamNameColor changed to: \(altTeamNameColor)")
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
    
    @Published var useProButtons: Bool {
        didSet {
            UserDefaults.standard.set(useProButtons, forKey: "useProButtons")
            print("UseProButtons changed to: \(useProButtons)")
        }
    }
    
    init() {
        self.teamName = UserDefaults.standard.string(forKey: "teamName") ?? "Ultra"
        self.showRaceInfo = UserDefaults.standard.object(forKey: "showRaceInfo") as? Bool ?? true
        self.smoothSecond = UserDefaults.standard.bool(forKey: "smoothSecond")
        self.altTeamNameColor = UserDefaults.standard.bool(forKey: "altTeamNameColor")
        self.lightMode = UserDefaults.standard.bool(forKey: "lightMode")
        self.ultraModel = UserDefaults.standard.object(forKey: "ultraModel") as? Bool ?? true
        self.showSpeedInfo = UserDefaults.standard.object(forKey: "showSpeedInfo") as? Bool ?? false
        self.useProButtons = UserDefaults.standard.bool(forKey: "useProButtons") // Default to false
        UserDefaults.standard.synchronize()
    }
}

struct SpeedInfoToggle: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var locationManager = LocationManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Toggle("Dashboard", isOn: Binding(
            get: { settings.showSpeedInfo },
            set: { newValue in
                if newValue {
                    // User is trying to turn it on
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        // Permission already granted, allow toggle
                        settings.showSpeedInfo = true
                    } else {
                        // Need to request permission
                        showingPermissionAlert = true
                        // Don't set showSpeedInfo to true yet
                    }
                } else {
                    // User is turning it off, always allow
                    settings.showSpeedInfo = false
                }
            }
        ))
        .alert(
            "Location Access Required",
            isPresented: $showingPermissionAlert,
            actions: {
                Button("Not Now", role: .cancel) {
                    settings.showSpeedInfo = false  // Ensure toggle stays off
                }
                Button("Enable") {
                    locationManager.requestLocationPermission()
                }
            },
            message: {
                Text("Speed Info needs location access to show speed and distance while the features are active.")
            }
        )
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Permission was granted, enable the feature
                settings.showSpeedInfo = true
            } else if newStatus == .denied || newStatus == .restricted {
                // Permission was denied, ensure feature is disabled
                settings.showSpeedInfo = false
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @Binding var showSettings: Bool
    @State private var showThemePicker = false
    @State private var showTeamNameEdit = false
    @State private var refreshToggle = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            /*
            Text("Restart app after change")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .offset(y:-10)
            */
            
            List {

                Section ("ULTRA features") {
                    Toggle("ProControl", isOn: $settings.useProButtons)
                        .font(.system(size: 17))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: ColorTheme.signalOrange.rawValue)))
                                        
                    SpeedInfoToggle()
                        .font(.system(size: 17))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: ColorTheme.signalOrange.rawValue)))
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(1))
                
                Section ("PRO features") {
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
                    
                    Toggle("Race Info", isOn: $settings.showRaceInfo)
                    
                    Toggle("Smooth Second Movement", isOn: $settings.smoothSecond)
                    
                    Toggle("Alt Team Name Color", isOn: $settings.altTeamNameColor)
                    
                    Toggle("Light Mode", isOn: $settings.lightMode)
                    
                    Text("Restart the app for the changes to take effect. Double press digital crown and swipe left to close the app.")
                        .font(.caption2)
                }
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(1))

            }
         }
     }
 }

extension AppSettings {
    func resetToDefaults() {
        // Reset all settings to their default values
        teamName = "RACE!"
        showRaceInfo = true
        showSpeedInfo = false
        smoothSecond = false
        altTeamNameColor = false
        lightMode = false
        ultraModel = true
        useProButtons = false
        
        // Reset theme color to Cambridge Blue via SharedDefaults
        SharedDefaults.saveTheme(.cambridgeBlue)
        
        // Save defaults to UserDefaults
        UserDefaults.standard.set("RACE!", forKey: "teamName")
        UserDefaults.standard.set(true, forKey: "showRaceInfo")
        UserDefaults.standard.set(false, forKey: "showSpeedInfo")
        UserDefaults.standard.set(false, forKey: "smoothSecond")
        UserDefaults.standard.set(false, forKey: "altTeamNameColor")
        UserDefaults.standard.set(false, forKey: "lightMode")
        UserDefaults.standard.set(true, forKey: "ultraModel")
        UserDefaults.standard.set(false, forKey: "useProButtons")
        UserDefaults.standard.synchronize()
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
