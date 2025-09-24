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
    
    private var inputDH: DailyInputDatabaseHelper {
        DailyInputDatabaseHelper.shared
    }
    
    init() {
//        if DailyInputDatabaseHelper.shared == nil {
//            DailyInputDatabaseHelper.configureShared(with: self)
//        }
        
        // if latest day of dailyInput data is not today, set dailyInputComplete to false
        if let mostRecent = inputDH.getMostRecentInputDay() {
            dailyInputComplete = Calendar.current.isDateInToday(mostRecent)
            // use dailyInputComplete here
        } else {
            // handle no data yet
            print("No most recent input data found")
        }
        
        
        // TO-DO: pull weather data if there is any missing
        
        
        // TO-DO: pull latest music data if missing
        
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
    func logDailyData(dailyInputDict: [String: String], inputDate: Date) {
        
        // first check that all fields have been filled
        if !checkDailyInputComplete(dailyInputDict: dailyInputDict) {
            return
        }
        
        // then run force insert function
        insertDailyInput(dailyInputDict: dailyInputDict, inputDate: inputDate)
        
        // then set dailyInputComplete to true to trigger the view changing to the report
        dailyInputComplete = true
        
        // later create a window that tells user they already logged for today
    }
    
    
    private func insertDailyInput(dailyInputDict: [String: String], inputDate: Date) {
        // convert dict values' types from strings
        let (mood, productivity, sleep, sleepStart, sleepEnd, exercise) = convertInputStrings(inputDict: dailyInputDict)
        
        // run force insert
        inputDH.forceInsertDailyInput(date: inputDate, mood: mood, productivity: productivity, sleep: sleep, sleepStart: sleepStart, sleepEnd: sleepEnd, exercise: exercise)
    }
    
    // convert strings to int and double
    private func convertInputStrings(inputDict: [String: String]) -> (mood: Int, productivity: Int, sleep: Double, sleepStart: String, sleepEnd: String, exercise: Double) {
        let mood = Int(inputDict["mood"] ?? "0")!
        let productivity = Int(inputDict["productivity"] ?? "0")!
        let sleep = Double(inputDict["sleep"] ?? "0")!
        let sleepStart = inputDict["sleepStart"] ?? "0"
        let sleepEnd = inputDict["sleepEnd"] ?? "0"
        let exercise = Double(inputDict["exercise"] ?? "0")!
        
        return (mood, productivity, sleep, sleepStart, sleepEnd, exercise)
    }
    
    
}
