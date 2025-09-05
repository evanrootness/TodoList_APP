//
//  WeatherDatabaseHelper.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/20/25.
//

import Foundation
import SQLite
import Combine
import SQLite3

class WeatherDatabaseHelper: ObservableObject {
    static let shared = WeatherDatabaseHelper()
    private var db: Connection?
    
    private let weatherTable = Table("weather")
    private let dateColumn = Expression<String>("date")
    private let tempColumn = Expression<Double>("temp")
    private let conditionsColumn = Expression<String>("conditions")
    private let locationColumn = Expression<String>("location")
    private var cancellables = Set<AnyCancellable>()
    
    private let apiKey: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "VISUAL_CROSSING_API_KEY") as? String else {
            fatalError("Missing VISUAL_CROSSING_API_KEY in Info.plist")
        }
        return value
    }()
    
    // initialize the latest day as
    var latestDay = Calendar.current.date(byAdding: .year, value: -69, to: Date())! // #evan wuz here
    // initialize one day ago
    var oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    //    private init() {
    //        do {
    //            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //            db = try Connection(path.appendingPathComponent("weather.sqlite3").path)
    //            try createTable()
    //            print("Database path: \(path.appendingPathComponent("weather.sqlite3").path)")
    //        } catch {
    //            print("Database connection error: \(error)")
    //        }
    //    }
    
    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            db = try Connection("\(path)/weather.sqlite3")
//            print("Database connection success")
        } catch {
            print("Database connection failed: \(error)")
        }
    }
    
    func tableExists() -> Bool {
        guard let db = db else { return false }
        do {
            let stmt = try db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='weather'")
            return try stmt.makeIterator().next() != nil
        } catch {
            print("Error checking table existence: \(error)")
            return false
        }
    }
    
    private func createTable() throws {
        do {
            try db?.run(weatherTable.create(ifNotExists: true) { t in
                t.column(dateColumn, primaryKey: true) // unique date
                t.column(tempColumn)
                t.column(conditionsColumn)
                t.column(locationColumn)
            })
            print("Table created or already exists")
        } catch {
            print("Table creation error: \(error)")
        }
    }
    
    func ensureTableExists() {
        do {
            try createTable()
        } catch {
            print("Error ensuring table exists: \(error)")
        }
    }
    
    
    // replace a row of weather data if already in table, otherwise insert new row
    func forceInsertWeatherRow(date: Date, temp: Double, conditions: String, location: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        do {
            // Check if row does not exist
            let query = weatherTable.filter(dateColumn == dateString)
            if try db?.pluck(query) == nil {
                // Insert new record
                try db?.run(weatherTable.insert(
                    dateColumn <- dateString,
                    tempColumn <- temp,
                    conditionsColumn <- conditions,
                    locationColumn <- location
                ))
            } else { // row does exist, so we need to update row
//                print("Weather for \(dateString) already exists.")
                // make sure we scope the update to only be the row we want
                let query = weatherTable.filter(dateColumn == dateString)
                // update row
                try db?.run(query.update(
                    tempColumn <- temp,
                    conditionsColumn <- conditions,
                    locationColumn <- location
                ))
                
            }
        } catch {
            print("Insert error: \(error)")
        }
    }
    
    func selectAllWeather() -> [HistoricalWeatherDay] {
        var results: [HistoricalWeatherDay] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        do {
            for row in try db!.prepare(weatherTable) {
                if let date = formatter.date(from: row[dateColumn]) {
                    results.append(
                        HistoricalWeatherDay(
                            date: date,
                            temp: row[tempColumn],
                            conditions: row[conditionsColumn],
                            location: row[locationColumn]
                        )
                    )
                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
        return results
    }
    
    
    
    func fetchWeather(start: Date, end: Date, selectedUnits: Units, location: String, completion: @escaping (Swift.Result<[HistoricalWeatherDay], Error>) -> Void) {
        
        // Ensure the location is not empty
        guard !location.isEmpty else {
            print("Location is empty. Exiting fetchWeather function.")
            completion(.success([])) // Return empty array
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        
        let urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(location)/\(startStr)/\(endStr)?unitGroup=\(selectedUnits)&include=days&key=\(apiKey)&contentType=json"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Weather fetch failed:", error)
                completion(.failure(error))
                return
            }
            
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                print("Bad server response for URL:", urlString)
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.unknown)))
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(VisualCrossingResponse.self, from: data)
                
                // Insert into database
                for day in decoded.days {
                    self.forceInsertWeatherRow(
                        date: day.datetime,
                        temp: day.tempmax,
                        conditions: day.conditions,
                        location: location
                    )
                }
                
                // select all weather from DB
                let allWeather = self.selectAllWeather()
                
                DispatchQueue.main.async {
                    completion(.success(allWeather))
                }
                
            } catch {
                print("Decoding error:", error)
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    
    
    //    function to get the most recent weather day that has been retrieved
    func getMostRecentWeatherDay() -> Date? {
        // get latest day
        do {
            if let latestRow = try self.db?.pluck(self.weatherTable.order(self.dateColumn.desc)) {
                let latestDayString = latestRow[self.dateColumn]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let latestDay = dateFormatter.date(from: latestDayString) {
//                    print("Latest weather date in table:", latestDay)
                    return latestDay
                }
            } else {
                print("No data in table yet.")
                return nil
            }
        } catch {
            print("Query Error:", error)
            return nil
        }
        return nil
    }
    
    
    func fetchLatestLocation() -> String? {
        do {
            // Path to your database
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let db = try Connection(path.appendingPathComponent("weather.sqlite3").path)
            
            //            // Reference to the table
            //            let weatherTable = Table("weather")
            
            //            // Columns (must match your schema)
            //            let locationColumn = Expression<String>("location")
            //            let dateColumn = Expression<Date>("date")
            
            // Query to get the latest location by most recent date
            if let row = try db.pluck(weatherTable.order(dateColumn.desc)) {
                return row[locationColumn]
            } else {
                return nil
            }
        } catch {
            print("Error fetching latest location: \(error)")
            return nil
        }
    }
    
    
    
}
