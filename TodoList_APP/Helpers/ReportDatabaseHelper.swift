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
    private let sleepStartColumn = DatabaseManager.shared.sleepStartColumn
    private let sleepEndColumn = DatabaseManager.shared.sleepEndColumn
    
    
    
    // select non-null data function
    func selectAllNonNull() -> [reportDataRow] {
        var results: [reportDataRow] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let isoFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            // Include fractional seconds because your string has ".000"
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            // "Z" at the end means UTC, so no need to set timeZone explicitly
            return formatter
        }()
        
        
        do {
            
            let filteredTable = mainTable
                .filter(moodColumn != nil)
                .filter(productivityColumn != nil)
                .filter(sleepColumn != nil)
                .filter(exerciseColumn != nil)
                .filter(tempColumn != nil)
                .filter(conditionsColumn != nil)
                .filter(locationColumn != nil)
                .filter(sleepStartColumn != nil)
                .filter(sleepEndColumn != nil)
            
            for row in try db.prepare(filteredTable) {
                guard
                    let date = formatter.date(from: row[dateColumn])
                else {
                        continue // skip row if date is missing or invalid
                }
                      
                if
                   let sleepStartString = row[sleepStartColumn], !sleepStartString.isEmpty,
                   let sleepEndString = row[sleepEndColumn], !sleepEndString.isEmpty,
                   let sleepStart = isoFormatter.date(from: sleepStartString),
                   let sleepEnd = isoFormatter.date(from: sleepEndString)
                
                {
//                    print("appending row")
                    results.append(
                        reportDataRow(
                            date: date,
                            mood: Double(row[moodColumn] ?? -999),
                            productivity: Double(row[productivityColumn] ?? -999),
                            sleep: row[sleepColumn] ?? -999.0,
                            exercise: row[exerciseColumn] ?? -999.0,
                            temp: row[tempColumn] ?? -999.0,
                            conditions: row[conditionsColumn] ?? "",
                            location: row[locationColumn] ?? "",
                            sleepStart: sleepStart,
                            sleepEnd: sleepEnd
                        )
                    )
                } else {
                    print("Skipping row; missing or invalid sleepStart or sleepEnd")
                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
//        print(results)
        return results.sorted { $0.date < $1.date }
    }
    
    
    
    
    // select all data from main table function
    func selectAllMain() -> [reportDataRow] {
        var results: [reportDataRow] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let isoFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            // Include fractional seconds because your string has ".000"
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            // "Z" at the end means UTC, so no need to set timeZone explicitly
            return formatter
        }()
        
        
        do {
            
            let filteredTable = mainTable
                .filter(moodColumn != nil)
            
            for row in try db.prepare(filteredTable) {
                guard
                    let date = formatter.date(from: row[dateColumn])
                else {
                    continue // skip row if date is missing or invalid
                }
                
                let moodValue: Double
                let prodValue: Double
                      
                var sleepStart: Date? = nil
                var sleepEnd: Date? = nil
                
                var tempFinal: Double? = nil
                var conditionsFinal: String? = nil
                var locationFinal: String? = nil
                
                
                if let moodRaw = row[moodColumn] {
                    moodValue = Double(moodRaw)
                } else {
                    moodValue = -999
                }
                
                if let prodRaw = row[productivityColumn] {
                    prodValue = Double(prodRaw)
                } else {
                    prodValue = -999
                }
                
                if let sleepStartString = row[sleepStartColumn],
                   !sleepStartString.isEmpty {
                    sleepStart = isoFormatter.date(from: sleepStartString)
                }

                if let sleepEndString = row[sleepEndColumn],
                   !sleepEndString.isEmpty {
                    sleepEnd = isoFormatter.date(from: sleepEndString)
                }
                
                if let temp = row[tempColumn],
                   !temp.isNaN {
                    tempFinal = temp
                }
                
                if let conditions = row[conditionsColumn],
                   !conditions.isEmpty {
                    conditionsFinal = conditions
                }
                
                if let location = row[locationColumn],
                   !location.isEmpty {
                    locationFinal = location
                }
                
//                print("Row mood:", row[moodColumn] as Any,
//                      "prod:", row[productivityColumn] as Any,
//                      "temp:", row[tempColumn] as Any)
//                
//                if
//                   let sleepStartString = row[sleepStartColumn], !sleepStartString.isEmpty,
//                   let sleepEndString = row[sleepEndColumn], !sleepEndString.isEmpty,
//                   let sleepStart = isoFormatter.date(from: sleepStartString),
//                   let sleepEnd = isoFormatter.date(from: sleepEndString)
//                
//                {
//                    print("appending row")
                results.append(
                    reportDataRow(
                        date: date,
//                        mood: row[moodColumn] ?? -999,
                        mood: moodValue,
//                        productivity: row[productivityColumn] ?? -999,
                        productivity: prodValue,
                        sleep: row[sleepColumn] ?? -999.0,
                        exercise: row[exerciseColumn] ?? -999.0,
//                        temp: row[tempColumn] ?? -999.0,
//                        conditions: row[conditionsColumn] ?? "",
//                        location: row[locationColumn] ?? "",
                        temp: tempFinal,
                        conditions: conditionsFinal,
                        location: locationFinal,
                        sleepStart: sleepStart,
                        sleepEnd: sleepEnd
                    )
                )
//                } else {
//                    print("Skipping row; missing or invalid sleepStart or sleepEnd")
//                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
//        print(results)
        return results.sorted { $0.date < $1.date }
    }

    

    
    
    
    
    
    
}

