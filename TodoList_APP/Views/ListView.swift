//
//  ListView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI


struct ListView: View {
    @StateObject private var viewModel = RoutineViewModel()
    
    var body: some View {
        VStack {
            HStack {
                TextField("New routine", text: $viewModel.newRoutineName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: viewModel.addRoutine) {
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
                ForEach(viewModel.routines) { routine in
                    HStack {
                        Image(systemName: routine.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(routine.isCompleted ? .green : .gray)
                            .onTapGesture {
                                viewModel.toggleCompletion(of: routine)
                            }
                        
                        Text(routine.name)
                            .strikethrough(routine.isCompleted)
                    }
                }
                .onDelete(perform: viewModel.delete)
            }
            .navigationTitle("My Routines")
            
        }
        .padding()

    }
}
