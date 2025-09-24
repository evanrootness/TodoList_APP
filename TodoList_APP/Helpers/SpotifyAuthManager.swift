//
//  SpotifyAuthManager.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import Foundation
import Combine
import AppKit
import CryptoKit


struct SpotifyTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String
    let expires_in: Int
    let refresh_token: String?
}

//struct RecentlyPlayedResponse: Codable {
//    struct Item: Codable, Identifiable {
//        var id: String { played_at }
//        let track: Track
//        let played_at: String // ISO8601 timestamp from Spotify
//        
//        
//        struct Track: Codable {
//            let id: String
//            let name: String
//            let duration_ms: Int
//            let album: Album
//            let artists: [Artist]
//            
//            struct Album: Codable {
//                let name: String
//            }
//            
//            struct Artist: Codable {
//                let id: String
//                let name: String
//            }
//        }
//    }
//    let items: [Item]
//}

struct RecentlyPlayedResponse: Codable {
    let items: [Item]

    struct Item: Codable {
        let track: Track
        let played_at: String
    }

    struct Track: Codable {
        let id: String
        let name: String
        let duration_ms: Int
        let artists: [Artist]
    }

    struct Artist: Codable {
        let id: String
        let name: String
    }
}

struct ArtistDetails: Codable {
    let id: String
    let name: String
    let genres: [String]
}




class SpotifyAuthManager: ObservableObject {
    static let shared = SpotifyAuthManager()
    
    private let spotifyDH = SpotifyDatabaseHelper.shared

    
//    @Published var recentlyPlayed: [RecentlyPlayedResponse.Item] = []
    @Published var timeListenedPastWeek: Double = 0
    @Published var topArtistPastWeek: String = ""
    @Published var topGenrePastWeek: String = ""
    @Published var recentTracks: [RecentTrack] = []
    @Published var isLoggedIn: Bool = false
    @Published private var accessToken: String? {
        didSet {
            isLoggedIn = (accessToken != nil)
        }
    }
    
    
    private var refreshToken: String?
    private var expirationDate: Date?
    
    private var artistGenreCache: [String: [String]] = [:]
    private var codeVerifier: String = ""
    private var accessTokenExpirationDate: Date?
    private var cancellables = Set<AnyCancellable>()
    private let scopes = "user-read-recently-played"
    
    private let clientID: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String else {
            fatalError("Missing SPOTIFY_CLIENT_ID in Info.plist")
        }
        return value
    }()
    private let redirectURI: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_REDIRECT_URI") as! String
        return raw.removingPercentEncoding ?? raw
    }()
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    /// Store the last successful fetch date
    private(set) var lastFetchDate: Date? {
        didSet {
            if let date = lastFetchDate {
                UserDefaults.standard.set(date, forKey: "SpotifyLastFetchDate")
            }
        }
    }
    
    
    
    private init() {
        // Load last fetch date
        if let savedDate = UserDefaults.standard.object(forKey: "SpotifyLastFetchDate") as? Date {
            self.lastFetchDate = savedDate
        }
        
        // Load access token
        if let accessData = KeychainHelper.shared.read(service: "Spotify", account: "accessToken"),
           let token = String(data: accessData, encoding: .utf8) {
            self.accessToken = token
        }
        
        // Load refresh token
        if let refreshData = KeychainHelper.shared.read(service: "Spotify", account: "refreshToken"),
           let refresh = String(data: refreshData, encoding: .utf8), !refresh.isEmpty {
            self.refreshToken = refresh
//            print("Refresh token on startup:", self.refreshToken ?? "nil")
        }
        
        // Load expiration date
        if let savedDate = UserDefaults.standard.object(forKey: "SpotifyAccessTokenExpirationDate") as? Date {
            self.accessTokenExpirationDate = savedDate
            print("Access token expiration date:", self.accessTokenExpirationDate ?? Date.distantPast)
        }
        
        // Check validity and refresh if needed
        if self.accessToken != nil, !isTokenExpired() {
            print("✅ Token is valid")
            self.fetchRecentlyPlayedSafe {
                self.recalculateMetrics()
            }
        } else if let refresh = self.refreshToken {
            print("⚠️ Token expired or missing — attempting refresh")
            refreshAccessToken(using: refresh) { success in
                DispatchQueue.main.async {
                    if success {
                        print("✅ Successfully refreshed token")
                        self.fetchRecentlyPlayedSafe {
                            self.recalculateMetrics()
                        }
                    } else {
                        print("❌ Failed to refresh token — user needs to log in")
                    }
                }
            }
        } else {
            print("❌ No valid token or refresh token — user needs to log in")
        }
    }
    
    
    
    func recalculateMetrics() {
        let startLW = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let today = Date()

        self.timeListenedPastWeek = Double(spotifyDH.calculateListeningTime(startDate: startLW, endDate: today)) / 1000.0 / 60.0 / 24.0
        self.topArtistPastWeek = spotifyDH.calculateTopArtist(startDate: startLW, endDate: today)
        self.topGenrePastWeek = spotifyDH.calculateTopGenre(startDate: startLW, endDate: today)
        self.recentTracks = spotifyDH.selectRecentTracks(startDate: threeDaysAgo, endDate: today)
    }
    
    
    func fetchRecentlyPlayedSafe(completion: (() -> Void)? = nil) {
        ensureValidAccessToken { [weak self] ok in
            guard let self = self else { return }
            if ok {
                self.fetchRecentTracksCatchUp()
            } else {
                self.startAuthorization()
            }
        }
        
        completion?()
    }
    
    
    func fetchRecentTracksCatchUp() {
        guard let token = accessToken else { return }
        
        let now = Date()
        // Default to last 24 hours
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        // Use last fetch timestamp if available, otherwise attempt to pull tracks within the past day
        let startDate = lastFetchDate ?? oneDayAgo
        let afterTimestamp = Int(startDate.timeIntervalSince1970 * 1000) // ms
        var allItems: [RecentlyPlayedResponse.Item] = []
//        print("lastFetchDate", lastFetchDate ?? Calendar.current.date(byAdding: .day, value: -999, to: Date())!)
//        print("Start date to fetch Spotify tracks", startDate)
        
        func fetchPage() {
            var urlComponents = URLComponents(string: "https://api.spotify.com/v1/me/player/recently-played")!
            urlComponents.queryItems = [
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "after", value: "\(afterTimestamp)")
            ]
            
            var request = URLRequest(url: urlComponents.url!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil,
                      let resp = try? JSONDecoder().decode(RecentlyPlayedResponse.self, from: data),
                      !resp.items.isEmpty else {
                    // No more data
                    DispatchQueue.main.async {
                        self.lastFetchDate = now
                    }
                    return
                }
                
                allItems.append(contentsOf: resp.items)
        
                DispatchQueue.main.async {
                    self.lastFetchDate = now
                }
                
                // Insert into DB as soon as each page is done
                for item in resp.items {
                    SpotifyDatabaseHelper.shared.insertListeningHistory(from: item)
                    
                    for artist in item.track.artists {
                        // Fetch full artist info (with genres)
                        self.fetchArtistDetails(artistID: artist.id) { artistDetails in
                            SpotifyDatabaseHelper.shared.insertOrUpdateArtistDetails(from: artistDetails)
                        }
                    }
                }
            }.resume()
        }
        fetchPage()
    }
    
    
    func fetchArtistDetails(artistID: String, completion: @escaping (ArtistDetails) -> Void) {
        guard let token = accessToken else { return }
        let url = URL(string: "https://api.spotify.com/v1/artists/\(artistID)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(ArtistDetails.self, from: data)
                completion(decoded)
            } catch {
                print("Error decoding artist details: \(error)")
            }
        }.resume()
    }

    
    func startAuthorization() {
        //        print("starting auth with redirectURI = ", redirectURI)
        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(codeVerifier)
        
        let authURLString = """
        https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scopes)&code_challenge_method=S256&code_challenge=\(codeChallenge)
        """
        
        if let url = URL(string: authURLString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    
    func handleRedirectURL(_ url: URL) {
        //        print("handleRedirectURL CALLED with:", url.absoluteString)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("No code found in URL")
            return
        }
        //        print("Got code:", code)
        exchangeCodeForToken(code: code)
    }
    
    
    private func exchangeCodeForToken(code: String) {
        //        print("Exchanging code with redirectURI =", redirectURI)
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        
        let params = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]
        
        request.httpBody = params
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: SpotifyTokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Token exchange failed: \(error)")
                }
            }, receiveValue: { [weak self] tokenResponse in
                
                guard let self = self else { return }
                
                // Save access token
                self.accessToken = tokenResponse.access_token
                self.accessTokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
                UserDefaults.standard.set(self.accessTokenExpirationDate, forKey: "SpotifyAccessTokenExpirationDate")
                
                if let accessData = tokenResponse.access_token.data(using: .utf8) {
                    KeychainHelper.shared.save(accessData, service: "Spotify", account: "accessToken")
                }
                
                // Save refresh token only if Spotify returns a new one
                if let newRefresh = tokenResponse.refresh_token, !newRefresh.isEmpty {
                    self.refreshToken = newRefresh
                    if let refreshData = newRefresh.data(using: .utf8) {
                        KeychainHelper.shared.save(refreshData, service: "Spotify", account: "refreshToken")
                    }
                    print("Received new refresh token, saved to Keychain.")
                } else {
                    print("No new refresh token returned. Keeping existing refresh token.")
                }
            })
            .store(in: &cancellables)
    }
    
    
    func ensureValidAccessToken(completion: @escaping (Bool) -> Void) {
        // If access token exists and is still valid, do nothing
        if let _ = accessToken, !isTokenExpired() {
            completion(true)
            return
        }
        
        // Otherwise, try to refresh
        guard let refresh = refreshToken else {
            // No refresh token, user needs to log in
            completion(false)
            return
        }
        refreshAccessToken(using: refresh) { ok in
            completion(ok)
        }
        
    }
    
    
    private func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<128).compactMap { _ in characters.randomElement() })
    }
    
    
    private func generateCodeChallenge(_ verifier: String) -> String {
        guard let data = verifier.data(using: .ascii) else { return "" }
        let hash = sha256(data: data)
        return base64URLEncode(data: hash)
    }
    
    
    private func sha256(data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }
    
    
    private func base64URLEncode(data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    
    func logout() {
        cancellables.removeAll()
        KeychainHelper.shared.delete(service: "Spotify", account: "accessToken")
        KeychainHelper.shared.delete(service: "Spotify", account: "refreshToken")
        self.accessToken = nil
        self.refreshToken = nil
        self.accessTokenExpirationDate = nil
    }
    
    
    // If already saved Spotify credentials, use refresh token
    private func refreshAccessToken(using refreshToken: String, completion: @escaping (Bool) -> Void) {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.httpBody = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&").data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: SpotifyTokenResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completionState in
                if case .failure(let error) = completionState {
                    print("Token refresh failed: \(error)")
                    completion(false)
                }
            }, receiveValue: { [weak self] tokenResponse in
                guard let self = self else { return }
                self.accessToken = tokenResponse.access_token
                self.accessTokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
                UserDefaults.standard.set(self.accessTokenExpirationDate, forKey: "SpotifyAccessTokenExpirationDate")
                
                if let data = tokenResponse.access_token.data(using: .utf8) {
                    KeychainHelper.shared.save(data, service: "Spotify", account: "accessToken")
                }
                if let newRefresh = tokenResponse.refresh_token, !newRefresh.isEmpty,
                   let rdata = newRefresh.data(using: .utf8) {
                    KeychainHelper.shared.save(rdata, service: "Spotify", account: "refreshToken")
                    self.refreshToken = newRefresh
                }
                completion(true)
            })
            .store(in: &cancellables)
    }
    
    
    private func isTokenExpired() -> Bool {
        guard let expiration = accessTokenExpirationDate else {
            return true // no token → consider expired
        }
        // Add a small buffer (e.g., 60s) to refresh slightly before expiry
        return Date() >= expiration.addingTimeInterval(-60)
    }
    
    
    func testTokenValidity() {
        guard let token = accessToken else {
            print("No access token in memory.")
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error checking token: \(error)")
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                if httpResp.statusCode == 200 {
                    print("✅ Token is valid")
                } else {
                    print("❌ Token invalid, status:", httpResp.statusCode)
                }
            }
        }.resume()
    }
    
    
    func getValidToken(completion: @escaping (String?) -> Void) {
        if let token = accessToken, let expDate = expirationDate {
            if Date() < expDate {
                // ✅ Still valid
                completion(token)
                return
            }
        }
        // ❌ Expired or missing → refresh
        refreshAccessToken { newToken in
            completion(newToken)
        }
    }
    
    
    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        // Make sure we have a refresh token
        guard let refreshToken = self.refreshToken else {
            print("No refresh token available")
            completion(nil)
            return
        }
        
        // Build request
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        
        let bodyString = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(clientID)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Refresh token request failed:", error?.localizedDescription ?? "unknown error")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let newToken = json?["access_token"] as? String {
                    DispatchQueue.main.async {
                        self.accessToken = newToken
                        
                        if let expiresIn = json?["expires_in"] as? Int {
                            self.accessTokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
                            // Optionally save to UserDefaults
                            UserDefaults.standard.set(self.accessTokenExpirationDate, forKey: "SpotifyAccessTokenExpirationDate")
                        }
                        
                        completion(newToken)
                    }
                } else {
                    print("No access token returned in refresh response")
                    completion(nil)
                }
            } catch {
                print("Failed to parse refresh token response:", error)
                completion(nil)
            }
        }.resume()
    }
    
    
    func isTokenValid() -> Bool {
        guard let expDate = accessTokenExpirationDate else {
            return false
        }
        return Date() < expDate
    }
    
}
