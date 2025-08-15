//
//  Routine.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//


import Foundation

// Defines how often a routine repeats
enum RepeatInterval: String, Codable, CaseIterable, Identifiable {
    case none, daily, weekly, monthly
    var id: String { rawValue } // For use in SwiftUI Pickers
}


struct Routine: Identifiable, Codable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    let dateCreated: Date
    var dateModified: Date
    
    var startDate: Date
    var repeatInterval: RepeatInterval
    var daysOfWeek: [Int]?

    init(id: UUID = UUID(),
         name: String,
         isCompleted: Bool = false,
         startDate: Date = Date(),
         repeatInterval: RepeatInterval = .none,
         daysOfWeek: [Int]? = nil
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.dateCreated = Date()
        self.dateModified = Date()
        
        self.startDate = startDate
        self.repeatInterval = repeatInterval
        self.daysOfWeek = daysOfWeek
    }
}





