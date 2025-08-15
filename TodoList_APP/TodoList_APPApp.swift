//
//  TodoList_APPApp.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
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
    @StateObject var routineVM = RoutineViewModel()
    @StateObject private var spotifyAuth = SpotifyAuthManager.shared
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate  // <-- pass the type
    
    var body: some Scene {
//        WindowGroup {
        Window("TodoList_APP", id: "mainWindow") {
            ContentView()
                .environmentObject(routineVM)
                .environmentObject(spotifyAuth)
        }
    }
}
