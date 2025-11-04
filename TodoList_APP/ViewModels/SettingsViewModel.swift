//
//  SettingsViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 11/2/25.
//


import Foundation
import SwiftUI


class SettingsViewModel: ObservableObject {
    @Published var moodScorecard: Bool = true
    @Published var productivityScorecard: Bool = true
    @Published var sleepScorecard: Bool = true
    @Published var sleepStartScorecard: Bool = false
    @Published var sleepEndScorecard: Bool = false
    @Published var exerciseScorecard: Bool = false
    @Published var temperatureScorecard: Bool = false
    @Published var totalCaloriesScorecard: Bool = false
    
    
}
