//
//  SettingsViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 11/2/25.
//


import Foundation
import SwiftUI


class SettingsViewModel: ObservableObject {
    @AppStorage("moodScorecard") var moodScorecard: Bool = true
    @AppStorage("productivityScorecard") var productivityScorecard: Bool = true
    @AppStorage("sleepScorecard") var sleepScorecard: Bool = true
    @AppStorage("sleepStartScorecard") var sleepStartScorecard: Bool = false
    @AppStorage("sleepEndScorecard") var sleepEndScorecard: Bool = false
    @AppStorage("exerciseScorecard") var exerciseScorecard: Bool = false
    @AppStorage("temperatureScorecard") var temperatureScorecard: Bool = false
    @AppStorage("totalCaloriesScorecard") var totalCaloriesScorecard: Bool = false
    
    @AppStorage("lastWeeksMetrics") var lastWeeksMetrics: Bool = true
    @AppStorage("lastMonthsMetrics") var lastMonthsMetrics: Bool = false
    @AppStorage("lastYearsMetrics") var lastYearsMetrics: Bool = false
    @AppStorage("allTimeMetrics") var allTimeMetrics: Bool = true
    
    
    let scorecardOrder: [String] = ["Mood", "Productivity", "Sleep", "Exercise", "Temperature", "Total Calories"]
    let periodOrder: [String] = ["Last Week", "Last Month", "Last Year", "All Time"]
}
