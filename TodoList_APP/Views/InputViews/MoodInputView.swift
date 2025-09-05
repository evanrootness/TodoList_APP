//
//  MoodInputView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/27/25.
//


import SwiftUI

struct MoodInputView: View {
    @EnvironmentObject var inputVM: DailyInputViewModel
    @Binding var dailyInputDict: [String: String]
    
    var body: some View {
        VStack{
            Spacer()
            VStack{
                Text("How did you feel today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "mood"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("How productive were you today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "productivity"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("How long did you sleep last night?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter in minutes", text: $dailyInputDict.stringBinding(forKey: "sleep"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("How long did you exercise today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter in minutes", text: $dailyInputDict.stringBinding(forKey: "exercise"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

            }
            .frame(maxHeight: .infinity)
            .padding(80)
            
            Spacer()
            
//            HStack {
//                Spacer()
//                Button(action: { inputVM.currentInputView = .productivity }) {
//                    HStack {
//                        Image(systemName: "arrow.right")
//                            .frame(width: 24, height: 24)
//                    }
//                }
//                .padding()
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



//struct MoodInputView_Previews: PreviewProvider {
//    static var previews: some View {
//        MoodInputView(dailyInputDict: $dailyInputDict)
//            .environmentObject(DailyInputViewModel())
//    }
//}
