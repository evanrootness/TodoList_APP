//
//  RoutinesView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI
import Foundation


struct RoutinesView: View {
    @EnvironmentObject var routineVM: RoutineViewModel
    
    var body: some View {
        VStack {
            HStack {
                TextField("New task", text: $routineVM.newRoutineName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Repeat", selection: $routineVM.selectedRepeatInterval) {
                    ForEach(RepeatInterval.allCases) { interval in
                        Text(interval.rawValue.capitalized)
                            .tag(interval)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button(action: routineVM.addRoutine) {
                    Image(systemName: "plus")
                        .padding(8)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(BorderlessButtonStyle())
                
            }
            Spacer()
            
            List {
                ForEach(routineVM.routines) { routine in
                    HStack {
                        Image(systemName: routine.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(routine.isCompleted ? .green : .gray)
                        Text(routine.name)
                            .strikethrough(routine.isCompleted)
                        Spacer()
                        Text(routine.dateCreated.formatted(date: .abbreviated, time: .shortened))
                            
                    }
                    .onTapGesture {
                        routineVM.toggleCompletion(of: routine)
                    }
                }
                .onDelete(perform: routineVM.delete)
            }
            .navigationTitle("My Routines")
            
        }
        .padding()

    }
}



struct  RoutinesView_Previews: PreviewProvider {
    @State static var selectedRepeatInterval: RepeatInterval = .none
    
    static var previews: some View {
        RoutinesView()
            .environmentObject(RoutineViewModel()) // <-- add this
        
    }
}
