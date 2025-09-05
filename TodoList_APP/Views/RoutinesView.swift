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
    @State private var isEditing = false
    
    private var rowHeight: CGFloat = 35
    
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
                
                
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    isEditing.toggle()
                }
                
                
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
                        
                        if isEditing {
                            Button(action: {
                                if let index = routineVM.routines.firstIndex(where: { $0.id == routine.id }) {
                                    routineVM.routines.remove(at: index)
                                }
                            }) {
//                                Image(systemName: "trash")
//                                    .foregroundColor(.red)
                                Text("Delete")
                                    .frame(maxWidth: 80)
                                    .frame(height: rowHeight)
                                    .background(Color.red)
                                    .foregroundColor(Color.white)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Prevent row selection
                            .listRowInsets(EdgeInsets()) // removes row padding
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.red)
                        }
                        
                    }
                    .frame(height: rowHeight)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .onTapGesture {
                        if !isEditing {
                            routineVM.toggleCompletion(of: routine)
                        }
                    }
                
                }
                .onDelete(perform: routineVM.delete)
            }
            .listStyle(PlainListStyle())
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
