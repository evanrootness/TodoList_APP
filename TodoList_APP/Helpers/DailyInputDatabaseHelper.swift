//
//  DailyInputDatabaseHelper.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/29/25.
//

import Foundation
import SQLite
import Combine
import SQLite3



class DailyInputDatabaseHelper: ObservableObject {
    static let shared = DailyInputDatabaseHelper()
//    static var shared: DailyInputDatabaseHelper!
    
    private let db = DatabaseManager.shared.db
    private let mainTable = DatabaseManager.shared.mainTable
        
    private let dateColumn = DatabaseManager.shared.dateColumn
    private let moodColumn = DatabaseManager.shared.moodColumn
    private let productivityColumn = DatabaseManager.shared.productivityColumn
    private let sleepColumn = DatabaseManager.shared.sleepColumn
    private let sleepStartColumn = DatabaseManager.shared.sleepStartColumn
    private let sleepEndColumn = DatabaseManager.shared.sleepEndColumn
    private let exerciseColumn = DatabaseManager.shared.exerciseColumn
    

    
    // overwrite a row of daily input data if already in table, otherwise insert new row
    func forceInsertDailyInput(date: Date, mood: Int, productivity: Int, sleep: Double, sleepStart: String, sleepEnd: String, exercise: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
//            print("Database path in forceInsertDailyInput: \(db?.description ?? "nil")")
            // Check if row does not exist
            let query = mainTable.filter(dateColumn == dateString)
            if try db.pluck(query) == nil {
//                print("Inserting new daily input row for \(dateString)")
                // Insert new record
                try db.run(mainTable.insert(
                    dateColumn <- dateString,
                    moodColumn <- mood,
                    productivityColumn <- productivity,
                    sleepColumn <- sleep,
                    sleepStartColumn <- sleepStart,
                    sleepEndColumn <- sleepEnd,
                    exerciseColumn <- exercise
                ))
            } else { // row does exist, so we need to update row
//                print("Daily input for \(dateString) already exists. Overwriting row")
                // make sure we scope the update to only be the row we want
                let query = mainTable.filter(dateColumn == dateString)
                // update row
                try db.run(query.update(
                    moodColumn <- mood,
                    productivityColumn <- productivity,
                    sleepColumn <- sleep,
                    sleepStartColumn <- sleepStart,
                    sleepEndColumn <- sleepEnd,
                    exerciseColumn <- exercise
                ))
            }
        } catch {
            print("Insert error: \(error)")
        }
    }
    

    
    // function to get the most recent day of input data
    func getMostRecentInputDay() -> Date? {
        do {
            // Only select rows where none of the required columns are NULL or empty
            let filteredTable = mainTable
                .filter(moodColumn != nil )
                .filter(productivityColumn != nil)
                .filter(sleepColumn != nil)
                .filter(exerciseColumn != nil)

            // Order by date descending
            if let latestRow = try db.pluck(filteredTable.order(dateColumn.desc)) {
                let latestDayString = latestRow[dateColumn]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                return dateFormatter.date(from: latestDayString)
            } else {
                print("No valid data in table yet.")
                return nil
            }
        } catch {
            print("Query Error:", error)
            return nil
        }
    }

    
    

}
