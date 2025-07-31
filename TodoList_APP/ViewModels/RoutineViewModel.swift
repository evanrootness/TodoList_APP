//
//  RoutineViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//


import Foundation
import SwiftUI

class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    @Published var newRoutineName: String = ""

    // Add a new routine
    func addRoutine() {
        guard !newRoutineName.isEmpty else { return }
        let newRoutine = Routine(name: newRoutineName)
        routines.append(newRoutine)
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


