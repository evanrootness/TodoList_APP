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
            ZStack(alignment: .bottomTrailing) {
                
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
                Button(action: {
                    spotifyAuth.logout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }
        }
    }
}



struct MusicView_Previews: PreviewProvider {
    static var previews: some View {
        // Mock SpotifyAuthManager for preview
        let mockAuth = SpotifyAuthManager.shared
        mockAuth.accessToken = "preview-token"
        mockAuth.recentlyPlayed = [
            RecentlyPlayedResponse.Item(
                track: RecentlyPlayedResponse.Item.Track(
                    id: "1",
                    name: "Preview Song 1",
                    album: RecentlyPlayedResponse.Item.Track.Album(name: "Preview Album"),
                    artists: [RecentlyPlayedResponse.Item.Track.Artist(name: "Preview Artist")]
                )
            ),
            RecentlyPlayedResponse.Item(
                track: RecentlyPlayedResponse.Item.Track(
                    id: "2",
                    name: "Preview Song 2",
                    album: RecentlyPlayedResponse.Item.Track.Album(name: "Another Album"),
                    artists: [RecentlyPlayedResponse.Item.Track.Artist(name: "Another Artist")]
                )
            )
        ]
        
        return MusicView()
            .environmentObject(mockAuth)
            .previewDisplayName("With Mock Data")
    }
}

