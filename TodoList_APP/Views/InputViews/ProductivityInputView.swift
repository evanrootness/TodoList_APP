//
//  ProductivityInputView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/27/25.
//

import SwiftUI


struct ProductivityInputView: View {
    @EnvironmentObject var inputVM: DailyInputViewModel
    
    @Binding var dailyInputDict: [String: String]
    
    var body: some View {
        
//        TextField("How much did you accomplish today? (1-10)", text: $dailyInputDict.stringBinding(forKey: "productivity"))
        
        VStack{
            
            Spacer()
            
            VStack{
                Text("How much did you accomplish today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "productivity"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

            }
            .frame(maxHeight: .infinity)
            .padding(80)
            
            Spacer()
            
            HStack {
                Spacer()
//                Button(action: { inputVM.currentInputView = .productivity }) {
//                    HStack {
//                        Image(systemName: "arrow.right")
//                            .frame(width: 24, height: 24)
//                    }
//                }
                .padding()
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    
    
    
}
