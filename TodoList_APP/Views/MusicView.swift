//
//  MusicView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI


struct MusicView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    
    var body: some View {
        if spotifyAuth.accessToken == nil {
            VStack {
                Text("Please log in to Spotify")
                Button("Login with Spotify") {
                    spotifyAuth.startAuthorization()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(spotifyAuth.recentlyPlayed) { item in
                VStack(alignment: .leading) {
                    Text(item.track.name).font(.headline)
                    Text(item.track.artists.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(item.track.album.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

