//
//  ReportViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/6/25.
//

import Foundation
import SwiftUI


class ReportViewModel: ObservableObject {
    @Published var reportData: [reportDataRow] = []
    
    @Published var inputStreak: Int = 0
    @Published var avgMoodLastWeek: Double = -999.0
    @Published var avgProdLastWeek: Double = -999.0
    @Published var avgSleepLastWeek: Double = -999.0
    @Published var avgExerciseLastWeek: Double = -999.0
    
    @Published var avgMoodLastMonth: Double = -999.0
    @Published var avgProdLastMonth: Double = -999.0
    @Published var avgSleepLastMonth: Double = -999.0
    @Published var avgExerciseLastMonth: Double = -999.0

    
    private let reportDH = ReportDatabaseHelper.shared
    
    init() {
        // initalize reportData as whatever it is on open
//        self.reportData = reportDH.selectAllNonNull()
        self.reportData = reportDH.selectAllMain()
        self.inputStreak = getInputStreak()
        
        self.avgMoodLastWeek = getAvg(\.mood, numDays: -7)
        self.avgProdLastWeek = getAvg(\.productivity, numDays: -7)
        self.avgSleepLastWeek = getAvg(\.sleep, numDays: -7)
        self.avgExerciseLastWeek = getAvg(\.exercise, numDays: -7)
        
        self.avgMoodLastMonth = getAvg(\.mood, numDays: -30)
        self.avgProdLastMonth = getAvg(\.productivity, numDays: -30)
        self.avgSleepLastMonth = getAvg(\.sleep, numDays: -30)
        self.avgExerciseLastMonth = getAvg(\.exercise, numDays: -30)
        
    }
    
    
    
    func refreshReportData() {
        // select report data and recalculate all metrics
        self.reportData = reportDH.selectAllMain()
        self.inputStreak = getInputStreak()
        
        self.avgMoodLastWeek = getAvg(\.mood, numDays: -7)
        self.avgProdLastWeek = getAvg(\.productivity, numDays: -7)
        self.avgSleepLastWeek = getAvg(\.sleep, numDays: -7)
        self.avgExerciseLastWeek = getAvg(\.exercise, numDays: -7)
        
        self.avgMoodLastMonth = getAvg(\.mood, numDays: -30)
        self.avgProdLastMonth = getAvg(\.productivity, numDays: -30)
        self.avgSleepLastMonth = getAvg(\.sleep, numDays: -30)
        self.avgExerciseLastMonth = getAvg(\.exercise, numDays: -30)
    }
    
    
    // get streak of daily input
    func getInputStreak () -> Int {
        var streak: Int = 0
        
        guard let latestRow = reportData.last else {
            return 0
        }
        
        var tempDate: Date = latestRow.date
        
        // if the most recently input day is not today or yesterday, return 0 (no streak)
        if tempDate == Date() || tempDate == Calendar.current.date(byAdding: .day, value: -1, to: Date())! {
            return 0
        }
        
        // otherwise, loop through each subsequent date in reportData (reversed), and if that date is not
        for row in reportData.reversed() {
            if (tempDate == row.date) || (tempDate == Date()) {
                streak += 1
                tempDate = Calendar.current.date(byAdding: .day, value: -1, to: tempDate)!
            } else {
                break
            }
        }
        return streak
    }
    
    
    
    
    // Generic function to get average of any numeric field in the past week
    func getAvg<T: BinaryInteger>(_ keyPath: KeyPath<reportDataRow, T>, numDays: Int) -> Double {
        var total: Double = 0
        var count: Int = 0
        let aWeekAgo = Calendar.current.date(byAdding: .day, value: numDays, to: Date())!

        for row in reportData where row.date >= aWeekAgo {
            total += Double(row[keyPath: keyPath])
            count += 1
        }

        return count > 0 ? total / Double(count) : 0.0
    }

    
    func getAvg(_ keyPath: KeyPath<reportDataRow, Double>, numDays: Int) -> Double {
        var total: Double = 0
        var count: Int = 0
        let aWeekAgo = Calendar.current.date(byAdding: .day, value: numDays, to: Date())!

        for row in reportData where row.date >= aWeekAgo {
            total += row[keyPath: keyPath]
            count += 1
        }

        return count > 0 ? total / Double(count) : 0.0
    }
    
    
    
    func getMoodGradient(for mood: Double) -> LinearGradient {
        switch mood {
        case let c where c == 1:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.05, blue: 0.1), Color(red: 0.2, green: 0.1, blue: 0.25), Color(red: 0.3, green: 0.3, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 2:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.05, blue: 0.2), Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.3, green: 0.4, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 3:
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.1, blue: 0.3), Color(red: 0.4, green: 0.3, blue: 0.6), Color(red: 0.3, green: 0.5, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 4:
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.2, blue: 0.35), Color(red: 0.5, green: 0.4, blue: 0.65), Color(red: 0.5, green: 0.7, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 5:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.4, blue: 0.5), Color(red: 0.5, green: 0.6, blue: 0.8), Color(red: 0.4, green: 0.8, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 6:
            return LinearGradient(
                colors: [Color(red: 0.45, green: 0.55, blue: 0.7), Color(red: 0.22, green: 0.8, blue: 0.85), Color(red: 0.47, green: 0.87, blue: 0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 7:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.7, blue: 0.85), Color(red: 0.14, green: 0.95, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 8:
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.75, blue: 0.83), Color(red: 0.35, green: 0.9, blue: 0.7), Color(red: 0.78, green: 0.9, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 9:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.82, blue: 0.75), Color(red: 0.6, green: 0.96, blue: 0.45), Color(red: 0.83, green: 0.92, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 10:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.95, blue: 0.7), Color(red: 0.8, green: 0.93, blue: 0.4), Color(red: 1.0, green: 0.8, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            
            
            
            
        default:
            return LinearGradient(
                colors: [Color(red: 0.96, green: 0.96, blue: 0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    
}


struct reportDataRow: Identifiable, Codable {
    var id: Date { date } // computed property avoids Codable issues
    let date: Date
    let mood: Double
    let productivity: Double
    let sleep: Double
    let exercise: Double
    let temp: Double?
    let conditions: String?
    let location: String?
    let sleepStart: Date?
    let sleepEnd: Date?
}

    
    
