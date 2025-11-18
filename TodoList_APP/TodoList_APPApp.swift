//
//  TodoList_APPApp.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("AppDelegate received URLs:", urls)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)  // bring existing window to front
        }
        for url in urls {
            SpotifyAuthManager.shared.handleRedirectURL(url)
        }
    }
}


@main
struct TodoList_APPApp: App {
    // Initialize all ViewModels here
    @StateObject var settingsVM = SettingsViewModel()
//    @StateObject var reportVM: ReportViewModel
    
    @StateObject var routineVM = RoutineViewModel()
    @StateObject var spotifyAuth = SpotifyAuthManager.shared
    @StateObject var weatherVM = WeatherViewModel()
    @StateObject var inputVM = DailyInputViewModel()
    
    
    init() {
        _ = DatabaseManager.shared
        
//        _reportVM = StateObject(wrappedValue: ReportViewModel(settingsVM: settingsVM))
    }
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate  // <-- pass the type
    
    var body: some Scene {
        
        // Initialize reportVM here, *after* settingsVM exists
        let reportVM = ReportViewModel(settingsVM: settingsVM)
        
        Window("TodoList_APP", id: "mainWindow") {
            ContentView()
                .environmentObject(settingsVM)
                .environmentObject(reportVM)
                .environmentObject(routineVM)
                .environmentObject(spotifyAuth)
                .environmentObject(weatherVM)
                .environmentObject(inputVM)
        }
    }
}
