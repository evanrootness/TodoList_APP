//
//  RoutineStorage.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/6/25.
//

import Foundation

class RoutineStorage {
    static let key = "routines"

    static func save(_ routines: [Routine]) {
        if let data = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> [Routine] {
        if let data = UserDefaults.standard.data(forKey: key),
           let routines = try? JSONDecoder().decode([Routine].self, from: data) {
            return routines
        }
        return []
    }
}
