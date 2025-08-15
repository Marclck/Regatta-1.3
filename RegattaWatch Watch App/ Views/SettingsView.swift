//
//  SettingsView.swift
//  RegattaWatch Watch App
//
//  Created by Chikai Lai on 09/12/2024.
//

import Foundation
import SwiftUI
import CoreLocation

enum LaunchScreen: String, CaseIterable {
    case timer = "TimeR"
    case cruiser = "CruiseR"
    case time = "Time"
    
    var displayName: String {
        return self.rawValue
    }
}

enum GunSyncOption: String, CaseIterable {
    case closestMin = "Closest Min"
    case roundUp = "Round Up"
    case roundDown = "Round Down"
    
    var displayName: String {
        return self.rawValue
    }
}

enum FontSelection: String, CaseIterable {
    case defaultFont = "Default"
    
    var displayName: String {
        return self.rawValue
    }
}

class AppSettings: ObservableObject {
    // Timer interval in seconds (1.0 when smooth is off, 0.01 when on)
    var timerInterval: Double {
        return smoothSecond ? 0.01 : 1.0
    }
    
    // Team name color hex value (ultraBlue when on, speedPapaya when off)
    var teamNameColorHex: String {
        return altTeamNameColor ? "#000000" : ColorTheme.speedPapaya.rawValue
    }
    
    @Published var gpsDebug: Bool {
        didSet {
            UserDefaults.standard.set(gpsDebug, forKey: "gpsDebug")
            print("GPSDebug changed to: \(gpsDebug)")
        }
    }
    
    @Published var launchScreen: LaunchScreen {
        didSet {
            UserDefaults.standard.set(launchScreen.rawValue, forKey: "launchScreen")
            print("LaunchScreen changed to: \(launchScreen.rawValue)")
        }
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
    
    @Published var showCruiser: Bool {
        didSet {
            UserDefaults.standard.set(showCruiser, forKey: "showCruiser")
            print("ShowCruiser changed to: \(showCruiser)")
        }
    }
    
    @Published var maxBoatSpeed: Double {
        didSet {
            UserDefaults.standard.set(maxBoatSpeed, forKey: "maxBoatSpeed")
            print("MaxBoatSpeed changed to: \(maxBoatSpeed)")
        }
    }
    
    @Published var gunSyncOption: GunSyncOption {
        didSet {
            UserDefaults.standard.set(gunSyncOption.rawValue, forKey: "gunSyncOption")
            print("GunSyncOption changed to: \(gunSyncOption.rawValue)")
        }
    }
    
    @Published var quickStartMinutes: Int {
        didSet {
            UserDefaults.standard.set(quickStartMinutes, forKey: "quickStartMinutes")
            print("QuickStartMinutes changed to: \(quickStartMinutes)")
        }
    }
    
    @Published var privacyOverlay: Bool {
        didSet {
            UserDefaults.standard.set(privacyOverlay, forKey: "privacyOverlay")
            print("PrivacyOverlay changed to: \(privacyOverlay)")
        }
    }
    
    @Published var stopwatchBuzz: Bool {
        didSet {
            UserDefaults.standard.set(stopwatchBuzz, forKey: "stopwatchBuzz")
            print("StopwatchBuzz changed to: \(stopwatchBuzz)")
        }
    }
    
    @Published var debugMode: Bool {
        didSet {
            UserDefaults.standard.set(debugMode, forKey: "debugMode")
            print("DebugMode changed to: \(debugMode)")
        }
    }
    
    @Published var timeFont: String {
        didSet {
            UserDefaults.standard.set(timeFont, forKey: "timeFont")
            print("TimeFont changed to: \(timeFont)")
        }
    }
    
    @Published var teamNameFont: String {
        didSet {
            UserDefaults.standard.set(teamNameFont, forKey: "teamNameFont")
            print("TeamNameFont changed to: \(teamNameFont)")
        }
    }
    
    init() {
        self.gpsDebug = UserDefaults.standard.bool(forKey: "gpsDebug") // Default to false
        
        self.teamName = UserDefaults.standard.string(forKey: "teamName") ?? "Ultra"
        self.showRaceInfo = UserDefaults.standard.object(forKey: "showRaceInfo") as? Bool ?? true
        self.smoothSecond = UserDefaults.standard.bool(forKey: "smoothSecond")
        self.altTeamNameColor = UserDefaults.standard.bool(forKey: "altTeamNameColor")
        self.lightMode = UserDefaults.standard.bool(forKey: "lightMode")
        self.ultraModel = UserDefaults.standard.object(forKey: "ultraModel") as? Bool ?? true
        self.showSpeedInfo = UserDefaults.standard.object(forKey: "showSpeedInfo") as? Bool ?? false
        self.useProButtons = UserDefaults.standard.bool(forKey: "useProButtons") // Default to false
        self.showCruiser = UserDefaults.standard.object(forKey: "showCruiser") as? Bool ?? false
        self.maxBoatSpeed = UserDefaults.standard.double(forKey: "maxBoatSpeed") != 0 ?
            UserDefaults.standard.double(forKey: "maxBoatSpeed") : 50.0
        self.gunSyncOption = GunSyncOption(rawValue: UserDefaults.standard.string(forKey: "gunSyncOption") ?? "Closest Min") ?? .closestMin
        self.quickStartMinutes = UserDefaults.standard.integer(forKey: "quickStartMinutes") != 0 ?
            UserDefaults.standard.integer(forKey: "quickStartMinutes") : 5
        self.privacyOverlay = UserDefaults.standard.bool(forKey: "privacyOverlay") // Default to false
        self.stopwatchBuzz = UserDefaults.standard.object(forKey: "stopwatchBuzz") as? Bool ?? true // Default to true
        self.debugMode = UserDefaults.standard.bool(forKey: "debugMode") // Default to false
        self.launchScreen = LaunchScreen(rawValue: UserDefaults.standard.string(forKey: "launchScreen") ?? "TimeR") ?? .timer
        self.timeFont = UserDefaults.standard.string(forKey: "timeFont") ?? "Default"
        self.teamNameFont = UserDefaults.standard.string(forKey: "teamNameFont") ?? "Default"
        UserDefaults.standard.synchronize()
    }
}

struct SpeedInfoToggle: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var iapManager = IAPManager.shared
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
                        // Permission already granted, respect user's toggle choice
                        settings.showSpeedInfo = newValue
                    } else {
                        // Need to request permission
                        showingPermissionAlert = true
                        // Don't set showSpeedInfo yet
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
                // Permission was granted, but don't automatically enable the feature
                // Let the user decide if they want it on or off
                // Do nothing here
            } else if newStatus == .denied || newStatus == .restricted {
                // Permission was denied, ensure feature is disabled
                settings.showSpeedInfo = false
            }
        }
    }
}

struct CruiserToggle: View {
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var iapManager = IAPManager.shared
    @StateObject private var locationManager = LocationManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Toggle("CruiseR", isOn: Binding(
            get: { settings.showCruiser },
            set: { newValue in
                if newValue {
                    // User is trying to turn it on
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        // Permission already granted, respect user's toggle choice
                        settings.showCruiser = newValue
                    } else {
                        // Need to request permission
                        showingPermissionAlert = true
                        // Don't set showCruiser yet
                    }
                } else {
                    // User is turning it off, always allow
                    settings.showCruiser = false
                }
            }
        ))
        .alert(
            "Location Access Required",
            isPresented: $showingPermissionAlert,
            actions: {
                Button("Not Now", role: .cancel) {
                    settings.showCruiser = false  // Ensure toggle stays off
                }
                Button("Enable") {
                    locationManager.requestLocationPermission()
                }
            },
            message: {
                Text("CruiseR needs location access to show speed and distance while the feature is active.")
            }
        )
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Permission was granted, but don't automatically enable the feature
                // Let the user decide if they want it on or off
                // Do nothing here
            } else if newStatus == .denied || newStatus == .restricted {
                // Permission was denied, ensure feature is disabled
                settings.showCruiser = false
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var colorManager: ColorManager
    @EnvironmentObject var settings: AppSettings
    @ObservedObject private var iapManager = IAPManager.shared
    @StateObject private var fontManager = CustomFontManager.shared
    @Binding var showSettings: Bool
    @State private var showThemePicker = false
    @State private var showTeamNameEdit = false
    @State private var showMaxSpeedEdit = false
    @State private var showGunSyncPicker = false
    @State private var refreshToggle = false
    @State private var maxSpeedInput: String = ""
    @State private var showQuickStartEdit = false
    @State private var quickStartInput: String = ""
    @State private var showTimeFontPicker = false
    @State private var showTeamNameFontPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            /*
             Text("Settings")
                .font(.system(size: 17, weight: .semibold))
                .padding(.horizontal)
                .padding(.vertical, 8)
            

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
                        .disabled(!iapManager.canAccessFeatures(minimumTier: .ultra))

                    SpeedInfoToggle()
                        .font(.system(size: 17))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: ColorTheme.signalOrange.rawValue)))
                        .disabled(!iapManager.canAccessFeatures(minimumTier: .ultra))
                    
                    CruiserToggle()
                        .font(.system(size: 17))
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: ColorTheme.signalOrange.rawValue)))
                        .disabled(!iapManager.canAccessFeatures(minimumTier: .ultra))
                    
                    if !iapManager.canAccessFeatures(minimumTier: .ultra) {
                        Text("Requires Ultra subscription")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else {
                        Text("Dashboard and CruiseR use GPS. Stop timer in Dashboard or turn off GPS by pressing speed display in CruiseR to stop GPS update.")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: ColorTheme.signalOrange.rawValue).opacity(1))
                
                Section ("") {
                    Button(action: {
                        showGunSyncPicker = true
                    }) {
                        HStack {
                            Text("GunSync")
                            Spacer()
                            Text(settings.gunSyncOption.displayName)
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showGunSyncPicker) {
                        List {
                            Section("GunSync Options") {
                                ForEach(GunSyncOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        settings.gunSyncOption = option
                                        showGunSyncPicker = false
                                    }) {
                                        HStack {
                                            Text(option.displayName)
                                            Spacer()
                                            if settings.gunSyncOption == option {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Section {
                                Text("Closest Min: Rounds to nearest minute\nRound Up: Always rounds up to next minute\nRound Down: Always rounds down to current minute")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Button(action: {
                        // Initialize the text field with current value
                        quickStartInput = String(settings.quickStartMinutes)
                        showQuickStartEdit = true
                    }) {
                        HStack {
                            Text("QuickStart (min)")
                            Spacer()
                            Text("\(settings.quickStartMinutes)")
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showQuickStartEdit) {
                        List {
                            Section {
                                TextField("Minutes", text: $quickStartInput)
                                    .onSubmit {
                                        validateAndUpdateQuickStart()
                                    }
                                Text("Enter quick start time (1-30 minutes)")
                                    .font(.caption2)
                            }
                            
                            Button("Apply") {
                                validateAndUpdateQuickStart()
                                showQuickStartEdit = false
                            }
                            
                            Button("Reset to Default") {
                                settings.quickStartMinutes = 5
                                showQuickStartEdit = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        // Initialize the text field with current value
                        maxSpeedInput = String(format: "%.1f", settings.maxBoatSpeed)
                        showMaxSpeedEdit = true
                    }) {
                        HStack {
                            Text("Max speed")
                            Spacer()
                            Text(String(format: "%.1f", settings.maxBoatSpeed))
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showMaxSpeedEdit) {
                        List {
                            Section {
                                TextField("Max Speed", text: $maxSpeedInput)
                                    .onSubmit {
                                        validateAndUpdateMaxSpeed()
                                    }
                                Text("Enter max boat speed (knots)")
                                    .font(.caption2)
                            }
                            
                            Button("Apply") {
                                validateAndUpdateMaxSpeed()
                                showMaxSpeedEdit = false
                            }
                            
                            Button("Reset to Default") {
                                settings.maxBoatSpeed = 50.0
                                showMaxSpeedEdit = false
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(1))
                
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
                    
                    Toggle("Stopwatch Buzz", isOn: $settings.stopwatchBuzz)
                    
                    Toggle("Alt Team Name Color", isOn: $settings.altTeamNameColor)
                    
                    Toggle("Light Mode", isOn: $settings.lightMode)
                    
                    Toggle("Privacy Overlay", isOn: $settings.privacyOverlay)
                    
                    Text("Restart the app for the changes to take effect. Double press digital crown and swipe left to close the app.")
                        .font(.caption2)
                
                    
                }
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(1))

                // UPDATED FONTS SECTION
                Section("Fonts") {
                    Button(action: {
                        showTimeFontPicker = true
                    }) {
                        HStack {
                            Text("Time Font")
                            Spacer()
                            Text(settings.timeFont == "Default" ? "Default" :
                                 fontManager.customFonts.first(where: { $0.id.uuidString == settings.timeFont })?.displayName ?? "Default")
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showTimeFontPicker) {
                        VStack(spacing: 0) {
                            // Header Preview Section
                            VStack {
                                HStack(spacing: 2) {
                                    Text("09")
                                        .font(getTimeFontForPreview(size: 42))
                                        .dynamicTypeSize(.xSmall)
                                        .foregroundColor(.white)
                                    
                                    VStack(spacing: 10) {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 6, height: 6)
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 6, height: 6)
                                    }
                                    .offset(x:-0.5, y:-0.5)

                                    Text("41")
                                        .font(getTimeFontForPreview(size: 42))
                                        .dynamicTypeSize(.xSmall)
                                        .foregroundColor(.white)
                                        .offset(x:2)
                                }
                                .frame(width: 150, height: 60)
                            }
                            .padding()
                            .background(Color.black.opacity(0.1))
                            
                            // Font Options List
                            List {
                                Section("Time Font Options") {
                                    // Default option
                                    Button(action: {
                                        settings.timeFont = "Default"
                                    }) {
                                        HStack {
                                            Text("Default")
                                                .font(.zenithBeta(size: 17))
                                            Spacer()
                                            if settings.timeFont == "Default" {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Custom fonts
                                    ForEach(fontManager.customFonts) { font in
                                        Button(action: {
                                            settings.timeFont = font.id.uuidString
                                        }) {
                                            HStack {
                                                Text(font.displayName)
                                                    .font(Font.customFont(font, size: 17) ?? .system(size: 17))
                                                Spacer()
                                                if settings.timeFont == font.id.uuidString {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        showTeamNameFontPicker = true
                    }) {
                        HStack {
                            Text("Team Name Font")
                            Spacer()
                            Text(settings.teamNameFont == "Default" ? "Default" :
                                 fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont })?.displayName ?? "Default")
                                .foregroundColor(.gray)
                        }
                    }
                    .sheet(isPresented: $showTeamNameFontPicker) {
                        VStack(spacing: 0) {
                            // Header Preview Section
                            VStack {
                                Text(settings.teamName)
                                    .font(getTeamNameFontForPreview(size: 12))
                                    .dynamicTypeSize(.xSmall)
                                    .foregroundColor(.white)
                                    .frame(width: 150, height: 60)
                            }
                            .padding()
                            .background(Color.black.opacity(0.1))
                            
                            // Font Options List
                            List {
                                Section("Team Name Font Options") {
                                    // Default option
                                    Button(action: {
                                        settings.teamNameFont = "Default"
                                    }) {
                                        HStack {
                                            Text("Default")
                                                .font(.system(size: 17, weight: .semibold))
                                            Spacer()
                                            if settings.teamNameFont == "Default" {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Custom fonts
                                    ForEach(fontManager.customFonts) { font in
                                        Button(action: {
                                            settings.teamNameFont = font.id.uuidString
                                        }) {
                                            HStack {
                                                Text(font.displayName)
                                                    .font(Font.customFont(font, size: 17) ?? .system(size: 17))
                                                Spacer()
                                                if settings.teamNameFont == font.id.uuidString {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        FontsListView()
                    } label: {
                        Text("Custom Fonts")
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.white.opacity(0.8))

                Section("Developer") {
                    NavigationLink {
                        List {
                            Section("Launch Screen") {
                                Picker("Default Launch Screen", selection: $settings.launchScreen) {
                                    ForEach(LaunchScreen.allCases, id: \.self) { screen in
                                        Text(screen.displayName).tag(screen)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                
                                Text("Choose which screen appears when the app launches. TimeR: Timer view, CruiseR: Watch face with cruise info, Time: Watch face showing time only.")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            
                            Section("Debug Options") {
                                
                                if settings.teamName.contains("-") || settings.teamName.contains("P") {
                                    Toggle("Debug Mode", isOn: $settings.debugMode)
                                        .font(.system(size: 17))
                                        .toggleStyle(SwitchToggleStyle(tint: Color.white.opacity(0.5)))
                                        .disabled(!iapManager.canAccessFeatures(minimumTier: .ultra))
                                }
                                
                                Toggle("GPS Debug", isOn: $settings.gpsDebug)
                                    .font(.system(size: 17))
                                    .toggleStyle(SwitchToggleStyle(tint: Color.white.opacity(0.5)))
                                    .disabled(!iapManager.canAccessFeatures(minimumTier: .ultra))
                                
                                if !iapManager.canAccessFeatures(minimumTier: .ultra) {
                                    Text("Requires Ultra subscription")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("For development purpose only. Do not turn on.")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .navigationTitle("Debug Settings")
                    } label: {
                        Text("Debug Settings")
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.white.opacity(0.5))
                
            }
            .dynamicTypeSize(.xSmall)
         }
     }
     
     // Helper methods for font selection
     private func getTimeFontForPreview(size: CGFloat) -> Font {
         if settings.timeFont == "Default" {
             return .zenithBeta(size: size)
         } else if let customFont = fontManager.customFonts.first(where: { $0.id.uuidString == settings.timeFont }) {
             return Font.customFont(customFont, size: size) ?? .zenithBeta(size: size)
         } else {
             return .zenithBeta(size: size)
         }
     }
     
     private func getTeamNameFontForPreview(size: CGFloat) -> Font {
         if settings.teamNameFont == "Default" {
             return .system(size: size, weight: .semibold)
         } else if let customFont = fontManager.customFonts.first(where: { $0.id.uuidString == settings.teamNameFont }) {
             return Font.customFont(customFont, size: size) ?? .system(size: size, weight: .semibold)
         } else {
             return .system(size: size, weight: .semibold)
         }
     }
     
     private func validateAndUpdateMaxSpeed() {
         // Clean the input string
         let cleanedInput = maxSpeedInput.replacingOccurrences(of: ",", with: ".")
         
         // Check if input is numeric
         if let numericValue = Double(cleanedInput) {
             // Round to one decimal place
             let roundedValue = round(numericValue * 10) / 10
             settings.maxBoatSpeed = roundedValue
         }
         // If not numeric, don't update (silently rejected)
     }
    
    private func validateAndUpdateQuickStart() {
        // Check if input is numeric
        if let minutes = Int(quickStartInput) {
            // Validate within range (1-30)
            if minutes > 0 && minutes <= 30 {
                settings.quickStartMinutes = minutes
            } else if minutes > 30 {
                settings.quickStartMinutes = 30 // Clamp to max
            } else {
                settings.quickStartMinutes = 1 // Clamp to min
            }
        }
        // If not numeric, don't update (silently rejected)
    }
 }

extension AppSettings {
    func resetToDefaults(_ colorManager: ColorManager, forTier tier: SubscriptionTier = .none) {
        // Reset all settings to their default values
        teamName = "RACE!"
        showRaceInfo = true
        smoothSecond = false
        altTeamNameColor = false
        lightMode = false
        ultraModel = true
        maxBoatSpeed = 50.0
        gunSyncOption = .closestMin
        quickStartMinutes = 5
        privacyOverlay = false
        stopwatchBuzz = true
        debugMode = false
        launchScreen = .timer
        timeFont = "Default"
        teamNameFont = "Default"
        
        gpsDebug = false

        // Reset ultra features if tier is not ultra
        if tier != .ultra {
            showSpeedInfo = false
            showCruiser = false
            useProButtons = false
        }
        
        // Reset theme color to Cambridge Blue
        colorManager.selectedTheme = .cambridgeBlue
        
        // Save defaults to UserDefaults
        UserDefaults.standard.set(false, forKey: "gpsDebug")

        UserDefaults.standard.set("RACE!", forKey: "teamName")
        UserDefaults.standard.set(true, forKey: "showRaceInfo")
        UserDefaults.standard.set(false, forKey: "showSpeedInfo")
        UserDefaults.standard.set(false, forKey: "showCruiser")
        UserDefaults.standard.set(false, forKey: "smoothSecond")
        UserDefaults.standard.set(false, forKey: "altTeamNameColor")
        UserDefaults.standard.set(false, forKey: "lightMode")
        UserDefaults.standard.set(true, forKey: "ultraModel")
        UserDefaults.standard.set(false, forKey: "useProButtons")
        UserDefaults.standard.set(50.0, forKey: "maxBoatSpeed")
        UserDefaults.standard.set("Closest Min", forKey: "gunSyncOption")
        UserDefaults.standard.set(5, forKey: "quickStartMinutes")
        UserDefaults.standard.set(false, forKey: "privacyOverlay")
        UserDefaults.standard.set(true, forKey: "stopwatchBuzz")
        UserDefaults.standard.set(false, forKey: "debugMode")
        UserDefaults.standard.synchronize()
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
        .environmentObject(ColorManager())
        .environmentObject(AppSettings())
}
