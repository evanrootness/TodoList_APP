//
//  SettingView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/4/25.
//

import SwiftUI
import Foundation


struct SettingsView: View {
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    
    var selections: [String: Binding<Bool>] {
        [
            "Mood": $settingsVM.moodScorecard,
            "Productivity": $settingsVM.productivityScorecard,
            "Sleep": $settingsVM.sleepScorecard,
            "Sleep Start": $settingsVM.sleepStartScorecard,
            "Sleep End": $settingsVM.sleepEndScorecard,
            "Exercise": $settingsVM.exerciseScorecard,
            "Temperature": $settingsVM.temperatureScorecard,
            "Total Calories": $settingsVM.totalCaloriesScorecard
        ]
    }
    
    
    var body: some View {
                
        VStack {
            Text("Settings")
                .font(.system(size: 28, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
            
            Text("Report scorecards")
                .font(.system(size: 16, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            // Select scorecards hstack
            HStack {
                
                ForEach(selections.keys.sorted(), id: \.self) { key in
                    Toggle(isOn: selections[key]!) {
                        Text(key)
                    }
                    .toggleStyle(.checkbox)
                    .padding()
                    
                }
                
            }
        }
        
        
    }
    
}












struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
