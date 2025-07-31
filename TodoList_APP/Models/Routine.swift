//
//  Routine.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//


import Foundation

struct Routine: Identifiable, Codable {
    let id: UUID
    var name: String
    var isCompleted: Bool

    init(id: UUID = UUID(), name: String, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
    }
}





