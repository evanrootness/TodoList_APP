//
//  MusicDatabaseManager.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/17/25.
//

import Foundation
import SQLite
import Combine
import SQLite3

class MusicDatabaseManager {
    static let shared = MusicDatabaseManager()
    let db: Connection
    let listeningHistory = Table("listening_history")
    let artists = Table("artists")
    let artistGenres = Table("artist_genres")
    

    let trackIDColumn = Expression<String>("track_id")
    let trackNameColumn = Expression<String>("track_name")
    let artistIDColumn = Expression<String>("artist_id")
    let playedAtColumn = Expression<String>("played_at")
    let trackDurationColumn = Expression<Int?>("duration_ms")

    let artistIdColumn_artistTable = Expression<String>("artist_id")
    let artistNameColumn = Expression<String>("name")
    let artistLastUpdatedColumn = Expression<Double?>("last_updated") // seconds since 1970 UTC in seconds
    
    let artistIdColumn_genresTable = Expression<String>("artist_id")
    let genreColumn = Expression<String>("genre")
    
    
    
    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/music_data.sqlite3")
            ensureTablesExist()
        } catch {
            fatalError("Database connection failed: \(error)")
        }
    }

    private func ensureTablesExist() {
        do {
            try db.run(listeningHistory.create(ifNotExists: true) { t in
                t.column(playedAtColumn, primaryKey: true)
                t.column(trackIDColumn)
                t.column(trackNameColumn)
                t.column(artistIDColumn)
                t.column(trackDurationColumn)
            })
            try db.run(artists.create(ifNotExists: true) { t in
                t.column(artistIdColumn_artistTable, primaryKey: true)
                t.column(artistNameColumn)
                t.column(artistLastUpdatedColumn)
            })
            try db.run(artistGenres.create(ifNotExists: true) { t in
                t.column(artistIdColumn_genresTable)
                t.column(genreColumn)
                t.foreignKey(artistIdColumn_genresTable, references: artists, artistIdColumn_artistTable)
            })
        } catch {
            print("Table creation error: \(error)")
        }
    }
}
