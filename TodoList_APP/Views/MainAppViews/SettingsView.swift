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
            "Exercise": $settingsVM.exerciseScorecard,
            "Temperature": $settingsVM.temperatureScorecard,
            "Total Calories": $settingsVM.totalCaloriesScorecard
        ]
    }
    
    var timePeriods: [String: Binding<Bool>] {
        [
            "Last Week": $settingsVM.lastWeeksMetrics,
            "Last Month": $settingsVM.lastMonthsMetrics,
            "Last Year": $settingsVM.lastYearsMetrics,
            "All Time": $settingsVM.allTimeMetrics
        ]
    }
    
    
    var body: some View {
                
        VStack {
            Text("Settings")
                .font(.system(size: 28, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Text("Report:")
                .font(.system(size: 20, design: .serif))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            
            VStack {
                Text("Scorecards")
                    .font(.system(size: 14, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                // Select scorecards hstack
                HStack {
                    ForEach(settingsVM.scorecardOrder, id: \.self) { key in
                        Toggle(isOn: selections[key]!) { Text(key) }
                        .toggleStyle(.checkbox)
                        .padding()
                    }
                }
                
                Text("Time Periods")
                    .font(.system(size: 14, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                // Select scorecards hstack
                HStack {
                    ForEach(settingsVM.periodOrder, id: \.self) { key in
                        Toggle(isOn: timePeriods[key]!) { Text(key) }
                        .toggleStyle(.checkbox)
                        .padding()
                    }
                    
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
