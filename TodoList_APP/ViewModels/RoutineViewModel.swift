//
//  RoutineViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//


import Foundation
import SwiftUI

class RoutineViewModel: ObservableObject {
    
    @Published var routines: [Routine] = [] {
        didSet {
            RoutineStorage.save(routines)
        }
    }
    
    @Published var selectedRepeatInterval: RepeatInterval = .none
    
    @Published var newRoutineName: String = ""
    var routineCount: Int {
        routines.count
    }
    
    
    init() {
        routines = RoutineStorage.load()
    }
    
    
    // Add a new routine
    func addRoutine() {
        // Ensure the new routine name is not empty; if it is, exit the function
        guard !newRoutineName.isEmpty else { return }
        
        // Create a new Routine object with the given name
        let newRoutine = Routine(name: newRoutineName)
        
        // Add the new routine to the list of routines
        routines.append(newRoutine)
        
        // Clear the input field for the next entry
        newRoutineName = ""
    }
    
    // Toggle completion
    func toggleCompletion(of routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index].isCompleted.toggle()
        }
    }
    
    // Delete routines
    func delete(at offsets: IndexSet) {
        routines.remove(atOffsets: offsets)
    }
}


