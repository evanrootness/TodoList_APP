//
//  DailyInputViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/25/25.
//

import Foundation
import SwiftUI

class DailyInputViewModel: ObservableObject {
    @Published var dailyInputComplete: Bool = false
    
    private var dbHelper: DailyInputDatabaseHelper {
        DailyInputDatabaseHelper.shared
    }
    
    init() {
        if DailyInputDatabaseHelper.shared == nil {
            DailyInputDatabaseHelper.configureShared(with: self)
        }
    }
    
    
    // function to check that all fields have have been filled with the proper input
    func checkDailyInputComplete(dailyInputDict: [String: String]) -> Bool {
        if (
            // check mood has correct input
            checkMoodInput(moodInput: dailyInputDict["mood"] ?? "") &&
            
            // check productivity has correct input
            checkProductivityInput(productivityInput: dailyInputDict["productivity"] ?? "") &&
            
            // check sleep has correct input
            checkSleepInput(sleepInput: dailyInputDict["sleep"] ?? "") &&
            
            // check exercise has correct input
            checkExerciseInput(exerciseInput: dailyInputDict["exercise"] ?? "")
        ) {
            // return true if all conditions met
            return true
        }
        return false
        
    }
    
    // function to check mood has correct input
    func checkMoodInput(moodInput: String) -> Bool {
        if let moodFloat = Float(moodInput) {
            return moodFloat >= 1 && moodFloat <= 10
        }
        return false
    }
    
    // function to check productivity has correct input
    func checkProductivityInput(productivityInput: String) -> Bool {
        if let productivityFloat = Float(productivityInput) {
            return productivityFloat >= 1 && productivityFloat <= 10
        }
        return false
    }
    
    // function to check sleep has correct input
    func checkSleepInput(sleepInput: String) -> Bool {
        if let sleepFloat = Float(sleepInput) {
            return sleepFloat >= 0
        }
        return false
    }
    
    // function to check exercise has correct input
    func checkExerciseInput(exerciseInput: String) -> Bool {
        if let exerciseFloat = Float(exerciseInput) {
            return exerciseFloat >= 0
        }
        return false
    }
    
    
    
    // function to log daily data that has been input by user
    func logDailyData(dailyInputDict: [String: String]) {
        
        // first check that all fields have been filled
        if !checkDailyInputComplete(dailyInputDict: dailyInputDict) {
            return
        }
        
        // then run force insert function
        insertDailyInput(dailyInputDict: dailyInputDict)
        
        // then set dailyInputComplete to true to trigger the view changing to the report
        dailyInputComplete = true
        
        // later create a window that tells user they already logged for today
    }
    
    
    private func insertDailyInput(dailyInputDict: [String: String]) {
        // convert dict values' types from strings
        let (todaysMood, todaysProductivity, todaysSleep, todaysExercise) = convertInputStrings(inputDict: dailyInputDict)
        
        // run force insert
        dbHelper.forceInsertDailyInput(date: Date(), mood: todaysMood, productivity: todaysProductivity, sleep: todaysSleep, exercise: todaysExercise)
    }
    
    // convert strings to int and double
    private func convertInputStrings(inputDict: [String: String]) -> (mood: Int, productivity: Int, sleep: Double, exercise: Double) {
        let mood = Int(inputDict["mood"] ?? "0")!
        let productivity = Int(inputDict["productivity"] ?? "0")!
        let sleep = Double(inputDict["sleep"] ?? "0")!
        let exercise = Double(inputDict["exercise"] ?? "0")!
        
        return (mood, productivity, sleep, exercise)
    }
    
    
}
