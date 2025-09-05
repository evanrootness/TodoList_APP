//
//  DailyInputView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/25/25.
//


import SwiftUI


struct DailyInputView: View {
    @EnvironmentObject var inputVM: DailyInputViewModel
    
    @State private var dailyInputDict: [String: String] = [:]

    
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
                TextField("Enter in hours", text: $dailyInputDict.stringBinding(forKey: "sleep"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("How long did you exercise today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter in hours", text: $dailyInputDict.stringBinding(forKey: "exercise"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

            }
            .frame(maxHeight: .infinity)
            .padding(80)
            
            Spacer()
            
            
            Button(action: { inputVM.logDailyData(dailyInputDict: dailyInputDict) }) {
                Text("Log Data")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



extension Binding where Value == [String: String] {

    func stringBinding(forKey key: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue[key] ?? "" },
            set: { self.wrappedValue[key] = $0 }
        )
    }
}



struct DailyInputView_Previews: PreviewProvider {
    static var previews: some View {
        DailyInputView()
            .environmentObject(DailyInputViewModel())
    }
}
