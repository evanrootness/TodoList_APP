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
    
    
    var body: some View {
//        Text("Hello, World!")
        ZStack {
            // Main App UI
            HStack(spacing: 0) {
                CollapsibleSidebar(selectedTab: $selectedTab)
            }
            
            if spotifyAuth.accessToken == nil {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("Please log in to Spotify")
                        .foregroundColor(.white)
                        .padding()
                    Button("Login with Spotify") {
                        spotifyAuth.startAuthorization()
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .frame(width: 300, height: 150)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environmentObject(RoutineViewModel())
//            .environmentObject(SpotifyAuthManager())
//        
//    }
//}

