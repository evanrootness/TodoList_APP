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

    private let db = DatabaseManager.shared.db
    private let mainTable = DatabaseManager.shared.mainTable
        
    private let dateColumn = DatabaseManager.shared.dateColumn
    private let tempColumn = DatabaseManager.shared.tempColumn
    private let conditionsColumn = DatabaseManager.shared.conditionsColumn
    private let locationColumn = DatabaseManager.shared.locationColumn
    
   
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
    
    
    
    // replace a row of weather data if already in table, otherwise insert new row
    func forceInsertWeatherRow(date: Date, temp: Double, conditions: String, location: String) {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        let dateString = formatter.string(from: date)
        
        do {
            // Check if row does not exist
            let query = mainTable.filter(dateColumn == dateString)
            if try db.pluck(query) == nil {
                // Insert new record
                try db.run(mainTable.insert(
                    dateColumn <- dateString,
                    tempColumn <- temp,
                    conditionsColumn <- conditions,
                    locationColumn <- location
                ))
            } else { // row does exist, so we need to update row
//                print("Weather for \(dateString) already exists. Running update on row...")
                // make sure we scope the update to only be the row we want
                let query = mainTable.filter(dateColumn == dateString)
                // update row
                try db.run(query.update(
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
            let filteredTable = mainTable
                .filter(tempColumn != nil)
                .filter(conditionsColumn != nil)
                .filter(locationColumn != nil)
            
            for row in try db.prepare(filteredTable) {
                if let date = formatter.date(from: row[dateColumn]) {
                    results.append(
                        HistoricalWeatherDay(
                            date: date,
                            temp: row[tempColumn] ?? 0,
                            conditions: row[conditionsColumn] ?? "",
                            location: row[locationColumn] ?? ""
                        )
                    )
                }
            }
        } catch {
            print("Fetch error: \(error)")
        }
        return results
    }
    
    
    
    func fetchWeather(start: Date, end: Date, location: String, completion: @escaping (Swift.Result<[HistoricalWeatherDay], Error>) -> Void) {
        // for now, always farenheit unit for temperature
        let units = "us"
        // Ensure the location is not empty
        guard !location.isEmpty else {
            print("Location is empty. Exiting fetchWeather function.")
            completion(.success([])) // Return empty array
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        let startStr = formatter.string(from: start)
        let endStr = formatter.string(from: end)
        let urlString: String
        
        if startStr == endStr {
            // One day only
            urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(location)/\(startStr)?unitGroup=\(units)&include=days&key=\(apiKey)&contentType=json"
        } else {
            // Range of days
            urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(location)/\(startStr)/\(endStr)?unitGroup=\(units)&include=days&key=\(apiKey)&contentType=json"
        }
        
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
                
//                // Insert into DB (convert returned UTC → local CST midnight)
//                let localCalendar = Calendar.current
//                let localTZ = TimeZone(identifier: "America/Chicago")!
//                
                // Insert into database
                for day in decoded.days {
//                    let utcDate = day.datetime
//                    let comps = localCalendar.dateComponents([.year, .month, .day], from: utcDate.addingTimeInterval(TimeInterval(localTZ.secondsFromGMT(for: utcDate))))
//                    let localDay = localCalendar.date(from: comps)!
//                    print("UTC date: \(utcDate), Local date: \(localDay)")
    
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
    
    
    
    //    function to get the most recent weather day that has been retrieved NEED TO ALTER FOR main_table with filters
    func getMostRecentWeatherDay() -> Date? {
//        print("running getMostRecentWeatherDay...")
        // get latest day
        do {
            // Only select rows where none of the required columns are NULL or empty
            let filteredTable = mainTable
                .filter(tempColumn != nil )
                .filter(conditionsColumn != nil)
                .filter(locationColumn != nil)
            
            if let latestRow = try db.pluck(filteredTable.order(dateColumn.desc)) {
                let latestDayString = latestRow[dateColumn]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let latestDay = dateFormatter.date(from: latestDayString) {
//                    print("Latest weather date in table:", latestDay)
                    return latestDay
                }
            } else {
                print("No weather data in table yet.")
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
            // Only select rows where none of the required columns are NULL or empty
            let filteredTable = mainTable
                .filter(tempColumn != nil )
                .filter(conditionsColumn != nil)
                .filter(locationColumn != nil)
            
            // Query to get the latest location by most recent date
            if let row = try db.pluck(filteredTable.order(dateColumn.desc)) {
//                print("Latest location: \(row[locationColumn])")
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
