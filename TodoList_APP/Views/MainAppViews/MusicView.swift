//
//  MusicView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI


struct MusicView: View {
    @EnvironmentObject var spotifyAuth: SpotifyAuthManager
    
    let scorecardGradient = LinearGradient(
        colors: [Color(red: 0.4, green: 0.1, blue: 0.6), Color(red: 0.32, green: 0.33, blue: 0.67), Color(red: 0.22, green: 0.5, blue: 0.8)],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    var body: some View {
        if !spotifyAuth.isLoggedIn {
//        if !spotifyAuth.isTokenValid() {
//        if spotifyAuth.accessToken == nil {
            VStack {
                Text("Please log in to Spotify")
                Button("Login with Spotify") {
                    spotifyAuth.startAuthorization()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack(alignment: .bottomTrailing) {
                
                HStack {
                    
                    VStack {
                        
                        Text("Past Week Stats")
                            .font(.headline)
                        HStack(spacing: 20) {
                            VStack {
                                Text("Listened to")
                                    .padding([.top, .leading, .trailing], 15)
                                    .padding(.bottom, 1)
                                    .font(.system(size: 20, design: .serif))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                HStack(alignment:.firstTextBaseline) {
                                    Text(String(format: "%.1f", spotifyAuth.timeListenedPastWeek))
                                        .font(.system(size: 28, design: .serif))
                                        .foregroundColor(.white)
                                        .fontWeight(.thin)
                                    Text("Hrs.")
                                        .font(.system(size: 24, design: .serif))
                                        .foregroundColor(.white)
                                        .fontWeight(.thin)
                                }
                                .padding([.leading, .trailing], 20)
                                .padding(.bottom, 15)

                            }
                            .frame(width: 150, height: 120)
                            .background(scorecardGradient)
                            .cornerRadius(10)
                            
                            VStack {
                                Text("Top Artist")
                                    .padding([.top, .leading, .trailing], 15)
                                    .padding(.bottom, 1)
                                    .font(.system(size: 20, design: .serif))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                Text("\(spotifyAuth.topArtistPastWeek)")
                                    .padding([.leading, .trailing], 30)
                                    .padding(.bottom, 15)
                                    .font(.system(size: 24, design: .serif))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .fontWeight(.thin)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 150, height: 120)
                            .background(scorecardGradient)
                            .cornerRadius(10)
                            
                            VStack {
                                Text("Top Genre")
                                    .padding([.top, .leading, .trailing], 15)
                                    .padding(.bottom, 1)
                                    .font(.system(size: 20, design: .serif))
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                Text("\(spotifyAuth.topGenrePastWeek)".capitalized)
                                    .padding([.leading, .trailing], 30)
                                    .padding(.bottom, 15)
                                    .font(.system(size: 26, design: .serif))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .fontWeight(.thin)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 150, height: 120)
                            .background(scorecardGradient)
                            .cornerRadius(10)
 
                        }
                        
                        
                        
                        Text("Listening Time")
                            .font(.headline)
                        ListeningTimeChartView()

                        
                        
                    }
                    
                    VStack {
                        Text("Recent Tracks")
                            .padding(4)
                            .font(.headline)
                        
                        List(spotifyAuth.recentTracks) { item in
                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text(item.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                //                            Text(item.artist.map { $0.name }.joined(separator: ", "))
                                //                                .font(.subheadline)
                                //                                .foregroundColor(.secondary)
                                //                            Text(item.track.album.name)
                                //                                .font(.caption)
                                //                                .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .frame(maxWidth: 300)
                        
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

//
//
//struct MusicView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Mock SpotifyAuthManager for preview
//        let mockAuth = SpotifyAuthManager.shared
//        mockAuth.accessToken = "preview-token"
//        mockAuth.recentlyPlayed = [
//            RecentlyPlayedResponse.Item(
//                track: RecentlyPlayedResponse.Item.Track(
//                    id: "1",
//                    name: "Preview Song 1",
//                    album: RecentlyPlayedResponse.Item.Track.Album(name: "Preview Album"),
//                    artists: [RecentlyPlayedResponse.Item.Track.Artist(name: "Preview Artist")]
//                )
//            ),
//            RecentlyPlayedResponse.Item(
//                track: RecentlyPlayedResponse.Item.Track(
//                    id: "2",
//                    name: "Preview Song 2",
//                    album: RecentlyPlayedResponse.Item.Track.Album(name: "Another Album"),
//                    artists: [RecentlyPlayedResponse.Item.Track.Artist(name: "Another Artist")]
//                )
//            )
//        ]
//        
//        return MusicView()
//            .environmentObject(mockAuth)
//            .previewDisplayName("With Mock Data")
//    }
//}

