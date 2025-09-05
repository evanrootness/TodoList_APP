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
//    static let shared = DailyInputDatabaseHelper()
    static var shared: DailyInputDatabaseHelper!
    
    private var db: Connection?
    
    private let mainTable = Table("main_table")
    private let dateColumn = Expression<String>("date") // date is not optional
    private let tempColumn = Expression<Double?>("temp")
    private let conditionsColumn = Expression<String?>("conditions")
    private let locationColumn = Expression<String?>("location")
    private let moodColumn = Expression<Int?>("mood")
    private let productivityColumn = Expression<Int?>("productivity")
    private let sleepColumn = Expression<Double?>("sleep")
    private let exerciseColumn = Expression<Double?>("exercise")
    
    private var cancellables = Set<AnyCancellable>()
    private var inputVM: DailyInputViewModel
    
    private let apiKey: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "VISUAL_CROSSING_API_KEY") as? String else {
            fatalError("Missing VISUAL_CROSSING_API_KEY in Info.plist")
        }
        return value
    }()
    
    
    private init(inputViewModel: DailyInputViewModel) {
        self.inputVM = inputViewModel
        
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/main_table.sqlite3")
            ensureTableExists()
//            print("Database path in database helper initialization: \(db?.description ?? "nil")")
        } catch {
            print("Database connection failed: \(error)")
        }
        
        // if latest day of dailyInput data is not today, set dailyInputComplete to false
        if let mostRecentInputDay = getMostRecentInputDay() {
            if !Calendar.current.isDateInToday(mostRecentInputDay) {
//                guard let inputVM = inputVM else { return }
                self.inputVM.dailyInputComplete = false
            }
        }

        
        // TO-DO: pull weather data if there is any missing
        
        
        // TO-DO: pull latest music data if missing
        
        
    }
    
    
    
    static func configureShared(with vm: DailyInputViewModel) {
        shared = DailyInputDatabaseHelper(inputViewModel: vm)
        
//        if shared == nil {
//            shared = DailyInputDatabaseHelper(inputViewModel: vm)
//        }
    }

    
    
    private func createTable() throws {
        do {
//            print("starting db create table")
//            print("Database path in createTable: \(db?.description ?? "nil")")
            try db?.run(mainTable.create(ifNotExists: true) { t in
                t.column(dateColumn, primaryKey: true) // unique date
                t.column(moodColumn)
                t.column(productivityColumn)
                t.column(sleepColumn)
                t.column(exerciseColumn)
                t.column(tempColumn)
                t.column(conditionsColumn)
                t.column(locationColumn)
            })
//            print("Main table created or already exists")
        } catch {
            print("Main table creation error: \(error)")
        }
    }
    
    func ensureTableExists() {
        do {
            try createTable()
        } catch {
            print("Error ensuring table exists: \(error)")
        }
    }
    
    
    // overwrite a row of daily input data if already in table, otherwise insert new row
    func forceInsertDailyInput(date: Date, mood: Int, productivity: Int, sleep: Double, exercise: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
//            print("Database path in forceInsertDailyInput: \(db?.description ?? "nil")")
            // Check if row does not exist
            let query = mainTable.filter(dateColumn == dateString)
            if try db?.pluck(query) == nil {
//                print("Inserting new daily input row for \(dateString)")
                // Insert new record
                try db?.run(mainTable.insert(
                    dateColumn <- dateString,
                    moodColumn <- mood,
                    productivityColumn <- productivity,
                    sleepColumn <- sleep,
                    exerciseColumn <- exercise
                ))
            } else { // row does exist, so we need to update row
//                print("Daily input for \(dateString) already exists. Overwriting row")
                // make sure we scope the update to only be the row we want
                let query = mainTable.filter(dateColumn == dateString)
                // update row
                try db?.run(query.update(
                    moodColumn <- mood,
                    productivityColumn <- productivity,
                    sleepColumn <- sleep,
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
                .filter(moodColumn != nil && productivityColumn != nil && sleepColumn != nil && exerciseColumn != nil)

            // Order by date descending
            if let latestRow = try db?.pluck(filteredTable.order(dateColumn.desc)) {
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
