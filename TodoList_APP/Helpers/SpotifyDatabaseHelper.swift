//
//  SpotifyDatabaseHelper.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/17/25.
//


import Foundation
import SQLite
import Combine
import SQLite3

class SpotifyDatabaseHelper: ObservableObject {
    static let shared = SpotifyDatabaseHelper()
    
    
    private let mainDB = DatabaseManager.shared.db
    private let spotifyDB = MusicDatabaseManager.shared.db
    
    
    private let mainTable = DatabaseManager.shared.mainTable
    private let listeningHistoryTable = MusicDatabaseManager.shared.listeningHistory
    private let artistsTable = MusicDatabaseManager.shared.artists
    private let artistGenresTable = MusicDatabaseManager.shared.artistGenres
    
    
    private let dateColumn = DatabaseManager.shared.dateColumn
    
    // Listening history columns
    private let trackIDColumn = MusicDatabaseManager.shared.trackIDColumn
    private let trackNameColumn = MusicDatabaseManager.shared.trackNameColumn
    private let artistIDColumn = MusicDatabaseManager.shared.artistIDColumn
    private let playedAtColumn = MusicDatabaseManager.shared.playedAtColumn
    private let trackDurationColumn = MusicDatabaseManager.shared.trackDurationColumn
    
    // Artist columns
    private let artistIdColumn_artistTable = MusicDatabaseManager.shared.artistIdColumn_artistTable
    private let artistNameColumn = MusicDatabaseManager.shared.artistNameColumn
    //    private let genresColumn = MusicDatabaseManager.shared.genresColumn
    private let artistLastUpdatedColumn = MusicDatabaseManager.shared.artistLastUpdatedColumn
    
    // Artist genres columns
    private let artistIdColumn_genresTable = MusicDatabaseManager.shared.artistIdColumn_genresTable
    private let genreColumn = MusicDatabaseManager.shared.genreColumn
    
    let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    
    
    
    // function to insert listening history
    func insertListeningHistory(from item: RecentlyPlayedResponse.Item) {
        do {
            let trackID = item.track.id
            let trackName = item.track.name
            let artistID = item.track.artists.first?.id ?? "unknown"
            let playedAt = item.played_at
            let duration = item.track.duration_ms
            
            // avoid duplicates
            let query = listeningHistoryTable.filter(trackIDColumn == trackID && playedAtColumn == playedAt)
            if try spotifyDB.pluck(query) != nil {
                // skip duplicate play
                print("Skipping duplicate play: \(trackID) @ \(playedAt)")
                return
            }
            
            try spotifyDB.run(listeningHistoryTable.insert(
                trackIDColumn <- trackID,
                trackNameColumn <- trackName,
                artistIDColumn <- artistID,
                playedAtColumn <- playedAt,
                trackDurationColumn <- duration
            ))
            
            
        } catch {
            print("Error on inserting listening history: \(error)")
        }
    }
    
    
    
    // insert/update an artist
    func insertOrUpdateArtistDetails(from artist: ArtistDetails) {
        do {
            // Upsert into artists table
            let query = artistsTable.filter(artistIdColumn_artistTable == artist.id)
            if try spotifyDB.pluck(query) != nil {
                try spotifyDB.run(query.update(
                    artistNameColumn <- artist.name,
                    artistLastUpdatedColumn <- Date().timeIntervalSince1970
                ))
            } else {
                try spotifyDB.run(artistsTable.insert(
                    artistIdColumn_artistTable <- artist.id,
                    artistNameColumn <- artist.name,
                    artistLastUpdatedColumn <- Date().timeIntervalSince1970
                ))
            }
            
            // Clear old genres for this artist
            let deleteQuery = artistGenresTable.filter(artistIdColumn_genresTable == artist.id)
            try spotifyDB.run(deleteQuery.delete())
            
            // Insert new genres
            for genre in artist.genres {
                try spotifyDB.run(artistGenresTable.insert(
                    artistIdColumn_genresTable <- artist.id,
                    genreColumn <- genre
                ))
            }
            
        } catch {
            print("Insert/Update artist failed: \(error)")
        }
    }
    
    
    
    func calculateTopArtist(startDate: Date, endDate: Date) -> String {
        let query = """
        SELECT lh.artist_id, a.name, COUNT(*) AS play_count
        FROM listening_history AS lh
        JOIN artists AS a ON lh.artist_id = a.artist_id
        WHERE lh.played_at >= ?
            AND lh.played_at <= ?
        GROUP BY lh.artist_id
        ORDER BY play_count DESC
        LIMIT 1;
        """
        
        do {
            let stmt = try spotifyDB.prepare(query, isoFormatter.string(from: startDate), isoFormatter.string(from: endDate))
            for row in stmt {
                //                let artistId = row[0] as! String
                let topArtist = row[1] as! String
                //                let playCount = row[2] as! Int
                
                return topArtist
            }
        } catch {
            print("Top artist raw SQL failed: \(error)")
        }
        
        // if nothing already returned
        return ""
    }
    
    
    
    func calculateTopGenre(startDate: Date, endDate: Date) -> String {
        let query = """
        SELECT g.genre, COUNT(*) AS play_count
        FROM listening_history AS lh
        JOIN artist_genres AS g ON lh.artist_id = g.artist_id
        WHERE lh.played_at >= ? 
            AND lh.played_at <= ?
        GROUP BY g.genre
        ORDER BY play_count DESC
        LIMIT 1;
        """
        
        do {
            let stmt = try spotifyDB.prepare(query, isoFormatter.string(from: startDate), isoFormatter.string(from: endDate))
            for row in stmt {
                return row[0] as! String
            }
        } catch {
            print("Top genre raw SQL failed: \(error)")
        }
        
        // if nothing already returned
        return ""
    }
    
    
    
    func calculateListeningTime(startDate: Date, endDate: Date) -> Int64 {
        let query = """
            WITH ordered_history AS (
                SELECT
                    track_id,
                    artist_id,
                    played_at,
                    duration_ms,
                    LEAD(played_at) OVER (ORDER BY played_at) AS next_played_at
                FROM listening_history
                WHERE played_at >= ? AND played_at <= ?
            )
            SELECT SUM(
                CASE
                    -- if the next play starts before this one would have ended, cut off overlap
                    WHEN next_played_at IS NOT NULL AND next_played_at < played_at + duration_ms
                        THEN (next_played_at - played_at)
                    ELSE duration_ms
                END
            ) AS total_listening_time
            FROM ordered_history;
            """
        
        do {
            let stmt = try spotifyDB.prepare(query, isoFormatter.string(from: startDate), isoFormatter.string(from: endDate))
            for row in stmt {
                // Handle NULL SUM safely
                if let total = row[0] {
                    if let intVal = total as? Int64 {
                        return intVal
                    } else if let doubleVal = total as? Double {
                        return Int64(doubleVal)
                    }
                }
            }
        } catch {
            print("Calculate listening time raw SQL failed: \(error)")
        }
        
        // if nothing already returned
        return 0
    }
    
    
    
    
    func selectRecentTracks(startDate: Date, endDate: Date) -> [RecentTrack] {
        let query = """
        SELECT lh.track_name, a.name, lh.played_at
        FROM listening_history AS lh
        JOIN artists AS a ON lh.artist_id = a.artist_id
        WHERE lh.played_at >= ?
            AND lh.played_at <= ?
        ORDER BY lh.played_at DESC
        LIMIT 50;
        """
        
        var results: [RecentTrack] = []
        
        do {
            let stmt = try spotifyDB.prepare(query, isoFormatter.string(from: startDate), isoFormatter.string(from: endDate))
            for row in stmt {
                if let trackName = row[0] as? String,
                   let artistName = row[1] as? String,
                   let playedAtString = row[2] as? String,
                   let playedAtDate = isoFormatter.date(from: playedAtString) {
                    results.append(RecentTrack(
                        played_at: playedAtDate,
                        name: trackName,
                        artist: artistName
                    ))
                }
            }
            return results
        } catch {
            print("Error selecting recent tracks: \(error)")
            return []
        }
    }

    
    
}
