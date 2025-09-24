//
//  ReportDatabaseHelper.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/6/25.
//


import Foundation
import SQLite
import Combine
import SQLite3

class ReportDatabaseHelper: ObservableObject {
    static let shared = ReportDatabaseHelper()
    
    private let db = DatabaseManager.shared.db
    private let mainTable = DatabaseManager.shared.mainTable
    
    private let dateColumn = DatabaseManager.shared.dateColumn
    private let moodColumn = DatabaseManager.shared.moodColumn
    private let productivityColumn = DatabaseManager.shared.productivityColumn
    private let sleepColumn = DatabaseManager.shared.sleepColumn
    private let exerciseColumn = DatabaseManager.shared.exerciseColumn
    private let tempColumn = DatabaseManager.shared.tempColumn
    private let conditionsColumn = DatabaseManager.shared.conditionsColumn
    private let locationColumn = DatabaseManager.shared.locationColumn
    
    
    
    // select non-null data function
    func selectAllNonNull() -> [reportDataRow] {
        var results: [reportDataRow] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            
            let filteredTable = mainTable
                .filter(moodColumn != nil)
                .filter(productivityColumn != nil)
                .filter(sleepColumn != nil)
                .filter(exerciseColumn != nil)
//                .filter(tempColumn != nil)
//                .filter(conditionsColumn != nil)
//                .filter(locationColumn != nil)
            
            for row in try db.prepare(filteredTable) {
                if let date = formatter.date(from: row[dateColumn]) {
                    results.append(
                        reportDataRow(
                            date: date,
                            mood: row[moodColumn] ?? -999,
                            productivity: row[productivityColumn] ?? -999,
                            sleep: row[sleepColumn] ?? -999.0,
                            exercise: row[exerciseColumn] ?? -999.0,
                            temp: row[tempColumn] ?? -999.0,
                            conditions: row[conditionsColumn] ?? "",
                            location: row[locationColumn] ?? ""
                        )
                    )
                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
        return results.sorted { $0.date < $1.date }
    }
    
    
    
    

    
    
    
    
    
    
    
    
    
}

