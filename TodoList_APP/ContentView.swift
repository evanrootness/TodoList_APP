//
//  ContentView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: SidebarTab = .report
    @EnvironmentObject var routineVM: RoutineViewModel
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    @EnvironmentObject var weatherVM: WeatherViewModel
    @EnvironmentObject var inputVM: DailyInputViewModel
    @EnvironmentObject var reportVM: ReportViewModel
    
    var body: some View {
        ZStack {
            // Main App UI
            HStack(spacing: 0) {
                CollapsibleSidebar(selectedTab: $selectedTab)
            }
            
//            if !spotifyAuth.isTokenValid() {
//            if spotifyAuth.accessToken == nil {
            if !spotifyAuth.isLoggedIn {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Please log in to Spotify")
                        .foregroundColor(.white)
                        .padding()
                    Button("Login with Spotify") {
                        spotifyAuth.startAuthorization()
                    }
                }
                .frame(width: 300, height: 150)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
            
            if weatherVM.showSetupWindow {
                // Dimmed background that blocks touches
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                // SetupView on top
                SetupView(weatherVM: weatherVM)
                    .frame(width: 350, height: 250)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .zIndex(1) // on top of all other views
            }
        }
        .task {
            if !inputVM.dailyInputComplete {
                selectedTab = .input
            } else {
                selectedTab = .report
            }
        }
        .onChange(of: inputVM.dailyInputComplete) {
            // switch to the report view when daily input is complete
            selectedTab = inputVM.dailyInputComplete ? .report : .input
            // refresh reportData and recalculate report metrics
            reportVM.refreshReportData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RoutineViewModel())
            .environmentObject(SpotifyAuthManager.shared)
        
    }
}

