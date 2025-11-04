//
//  DatabaseManager.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/3/25.
//

import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()
    let db: Connection
    let mainTable = Table("main_table")

    // columns
    let dateColumn = Expression<String>("date")
    let moodColumn = Expression<Int?>("mood")
    let productivityColumn = Expression<Int?>("productivity")
    let sleepColumn = Expression<Double?>("sleep")
    let sleepStartColumn = Expression<String?>("sleep_start")
    let sleepEndColumn = Expression<String?>("sleep_end")
    let exerciseColumn = Expression<Double?>("exercise")
    let tempColumn = Expression<Double?>("temp")
    let conditionsColumn = Expression<String?>("conditions")
    let locationColumn = Expression<String?>("location")
    // nutrition columns
    let totalCaloriesColumn = Expression<Double?>("total_calories")
    let sugarCaloriesColumn = Expression<Double?>("sugar_calories")
    let vegetableCaloriesColumn = Expression<Double?>("vegetable_calories")
    let fruitCaloriesColumn = Expression<Double?>("fruit_calories")
    let carbCaloriesColumn = Expression<Double?>("carb_calories")
    let proteinCaloriesColumn = Expression<Double?>("protein_calories")
    let dairyFatCaloriesColumn = Expression<Double?>("dairy_fat_calories")
    
    

    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/main_table.sqlite3")
            ensureTableExists()
        } catch {
            fatalError("Database connection failed: \(error)")
        }
    }

    private func ensureTableExists() {
        do {
            try db.run(mainTable.create(ifNotExists: true) { t in
                t.column(dateColumn, primaryKey: true)
                t.column(moodColumn)
                t.column(productivityColumn)
                t.column(sleepColumn)
                t.column(sleepStartColumn)
                t.column(sleepEndColumn)
                t.column(exerciseColumn)
                t.column(tempColumn)
                t.column(conditionsColumn)
                t.column(locationColumn)
                
                t.column(totalCaloriesColumn)
                t.column(sugarCaloriesColumn)
                t.column(vegetableCaloriesColumn)
                t.column(fruitCaloriesColumn)
                t.column(carbCaloriesColumn)
                t.column(proteinCaloriesColumn)
                t.column(dairyFatCaloriesColumn)
            })
        } catch {
            print("Table creation error: \(error)")
        }
    }
}






