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
           let refresh = String(data: refreshData, encoding: .utf8) {
            // You can refresh the access token here if needed
            refreshAccessToken(using: refresh)
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
        return raw.removingPercentEncoding ?? raw
    }()
    private let scopes = "user-read-recently-played"
    
    private var codeVerifier: String = ""
    
    @Published var accessToken: String?
    @Published var recentlyPlayed: [RecentlyPlayedResponse.Item] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    func startAuthorization() {
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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("No code found in URL")
            return
        }
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
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
                self?.accessToken = tokenResponse.access_token
                
                // Save to Keychain
                if let accessData = tokenResponse.access_token.data(using: .utf8) {
                    KeychainHelper.shared.save(accessData, service: "Spotify", account: "accessToken")
                }
                if let refresh = tokenResponse.refresh_token,
                   let refreshData = refresh.data(using: .utf8) {
                    KeychainHelper.shared.save(refreshData, service: "Spotify", account: "refreshToken")
                }
                
                self?.fetchRecentlyPlayed()
            })
            .store(in: &cancellables)
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
        KeychainHelper.shared.delete(service: "Spotify", account: "accessToken")
        KeychainHelper.shared.delete(service: "Spotify", account: "refreshToken")
        self.accessToken = nil
    }
    
    
    // If already saved Spotify credentials, use refresh token
    private func refreshAccessToken(using refreshToken: String) {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        
        let params = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
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
                    print("Token refresh failed: \(error)")
                }
            }, receiveValue: { [weak self] tokenResponse in
                self?.accessToken = tokenResponse.access_token
                
                // Save updated access token
                if let accessData = tokenResponse.access_token.data(using: .utf8) {
                    KeychainHelper.shared.save(accessData, service: "Spotify", account: "accessToken")
                }
                
                // If Spotify returns a new refresh token, store it
                if let newRefresh = tokenResponse.refresh_token,
                   let refreshData = newRefresh.data(using: .utf8) {
                    KeychainHelper.shared.save(refreshData, service: "Spotify", account: "refreshToken")
                }
                
                // Fetch data now that we have a valid token
                self?.fetchRecentlyPlayed()
            })
            .store(in: &cancellables)
    }
    
    
    
    
    
    
    
}
