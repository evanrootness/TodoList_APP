//
//  HistoryView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/4/25.
//

import SwiftUI
import Foundation

struct HistoryView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    
    var body: some View {
        VStack {

        List {
                ForEach(routineVM.routines) { routine in
                    HStack {
                        Image(systemName: routine.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(routine.isCompleted ? .green : .gray)
                            .onTapGesture {
                                routineVM.toggleCompletion(of: routine)
                            }
                        
                        Text(routine.name)
                            .strikethrough(routine.isCompleted)
                    }
                    .contentShape(Rectangle())
                }
                .onDelete(perform: routineVM.delete)
            }
            .navigationTitle("My Routines")
            
        }
        .padding()
    }
}

