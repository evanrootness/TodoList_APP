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

struct RecentlyPlayedResponse: Codable {
    struct Item: Codable, Identifiable {
        let track: Track
        var id: String { track.id }
        
        struct Track: Codable {
            let id: String
            let name: String
            let album: Album
            let artists: [Artist]
            
            struct Album: Codable {
                let name: String
            }
            
            struct Artist: Codable {
                let name: String
            }
        }
    }
    let items: [Item]
}

class SpotifyAuthManager: ObservableObject {
    static let shared = SpotifyAuthManager()
    
    private init() {
        // Load access token
        if let accessData = KeychainHelper.shared.read(service: "Spotify", account: "accessToken"),
           let token = String(data: accessData, encoding: .utf8) {
            self.accessToken = token
        }
        
        // Load refresh token (optional)
        if let refreshData = KeychainHelper.shared.read(service: "Spotify", account: "refreshToken"),
           let refresh = String(data: refreshData, encoding: .utf8), !refresh.isEmpty {
            // You can refresh the access token here if needed
            self.refreshToken = refresh
        }
    }
    
    private let clientID: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String else {
            fatalError("Missing SPOTIFY_CLIENT_ID in Info.plist")
        }
        return value
    }()
    //    private let redirectURI = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_REDIRECT_URI") as! String
    private let redirectURI: String = {
        let raw = Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_REDIRECT_URI") as! String
//        print(raw.removingPercentEncoding ?? raw)
        return raw.removingPercentEncoding ?? raw
    }()
    
    private let scopes = "user-read-recently-played"
    
    private var codeVerifier: String = ""
    
    @Published var accessToken: String?
    private var accessTokenExpirationDate: Date?
    @Published var refreshToken: String?
    @Published var recentlyPlayed: [RecentlyPlayedResponse.Item] = []
    
    private var cancellables = Set<AnyCancellable>()
    
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

                // Fetch data now that we have a valid access token
                self.fetchRecentlyPlayedSafe()
            })
            .store(in: &cancellables)
    }
    
    func ensureValidAccessToken(completion: @escaping (Bool) -> Void) {
        // If access token exists and is still valid, do nothing
        if let token = accessToken, !isTokenExpired() {
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

    
    
    func fetchRecentlyPlayedSafe() {
        ensureValidAccessToken { [weak self] ok in
            guard let self = self else { return }
            if ok {
                self.fetchRecentlyPlayed()
            } else {
                self.startAuthorization()
            }
        }
    }
    
    func fetchRecentlyPlayed() {
        guard let token = accessToken else {
            print("No access token")
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/player/recently-played?limit=20")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: RecentlyPlayedResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Fetch recently played failed: \(error)")
                }
            }, receiveValue: { [weak self] response in
                self?.recentlyPlayed = response.items
            })
            .store(in: &cancellables)
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
    
    
    
    
    
}
