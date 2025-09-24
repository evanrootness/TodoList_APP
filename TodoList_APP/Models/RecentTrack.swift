//
//  RecentTrack.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/21/25.
//

import Foundation

struct RecentTrack: Identifiable, Codable {
    var id: Date { played_at } // computed property avoids Codable issues
    let played_at: Date
    let name: String
    let artist: String
}
