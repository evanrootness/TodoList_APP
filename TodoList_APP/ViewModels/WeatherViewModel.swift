//
//  Untitled.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/17/25.
//

import Foundation
import SwiftUI

struct HistoricalWeatherDay: Identifiable, Codable {
    var id: Date { date } // computed property avoids Codable issues
    let date: Date
    let temp: Double
    let conditions: String
    let location: String
    
    var conditionsArray: [String] {
        let parts = conditions.components(separatedBy: ",")
        return parts.compactMap { part in
            let lower = part.lowercased().trimmingCharacters(in: .whitespaces)
            
            if lower.contains("rain") {
                return "Rainy"
            } else if lower.contains("clear") {
                return "Sunny"
            } else if lower.contains("partly") || lower.contains("partial") {
                return "Partly Cloudy"
            } else if lower.contains("cloud") {
                return "Cloudy"
            } else {
                return nil
            }
        }
    }
}

//enum Units: String, CaseIterable, Identifiable {
//    case metric = "Metric"
//    case us = "Imperial"
//    
//    var id: String { self.rawValue}
//}

class WeatherViewModel: ObservableObject {
    @Published var weatherData: [HistoricalWeatherDay] = [] // I think this'll be the "just fetched" data that displays in the list
    // new published variable for calendar weather data
    @Published var calendarWeatherData: [HistoricalWeatherDay] = []
    @Published var isLoading = false
    @Published var location: String
//    @Published var selectedUnits: Units = .us
    @Published var showSetupWindow = false
    
    // May want to persist the users location (and other variables) across app launches
//    @AppStorage("usersLocation") var usersLocation: String = ""

    private let weatherDH = WeatherDatabaseHelper.shared

    let userTimeZone = TimeZone.current
    let calendar = Calendar.current
    lazy var oneDayAgo: Date = getStartOfYesterday()
    
    init() {
//        print("WeatherViewModel initialization running...")
        
        // try to fetch latest location from the database
        if let latestLocation = weatherDH.fetchLatestLocation() {
            self.location = latestLocation
        } else {
            self.location = "" // fallback value
        }
        
        // now run checkAndFetchWeather.
        checkAndFetchWeather()
        
        // fill calendarWeatherData
        fillCalendarWeatherData()
        
    }
    
    
    func getStartOfYesterday() -> Date {
        let userTimeZone = TimeZone.current
        var calendar = Calendar.current
        calendar.timeZone = userTimeZone
        
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -1, to: startOfToday)!
//        return startOfToday
    }
    
    
    
    func fetchLastWeekWeather() {
        // Fetch last week's weather once location and units are set
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: oneDayAgo)!
        let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate)!
        
        // load weather into table
        loadWeather(start: startDate, end: endDate)
        
        // close setup window
        showSetupWindow = false
    }
    
    
    // function to check what the latest weather day that has been retrieved and then modify the table if it needs modifying
    func checkAndFetchWeather() {
        // get latest day
        guard let latestDay = weatherDH.getMostRecentWeatherDay() else {
            print("No latest date of weather data found.")
            
            // pop up the set up location window
            showSetupWindow = true
            return
        }
                
        // if there's weather data greater than or equal to one day ago
        if (latestDay < oneDayAgo) {
            // if latest day of weather data is more than a day ago, then fetch most recent weather days
            fetchLatestWeatherDays(latestDay: latestDay)
        }
    }
    
    
    //  function to fetch weather days from latest weather days, up to yesterday
    func fetchLatestWeatherDays(latestDay: Date) {
        let oldestDayMissing = Calendar.current.date(byAdding: .day, value: 1, to: latestDay) ?? Date()
        loadWeather(start: oldestDayMissing, end: oneDayAgo)
    }
    
    
    func loadWeather(start: Date, end: Date) {
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        
        weatherDH.fetchWeather(start: start, end: end, location: location) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let data):
                    let dataWithIDs = data.map { day in
                        HistoricalWeatherDay(
                            date: day.date,
                            temp: day.temp,
                            conditions: day.conditions,
                            location: day.location
                        )
                    }
                    self?.weatherData = dataWithIDs
                case .failure(let error):
                    print("Error loading weather: \(error)")
                }
            }
        }
        
        // lastly, fill calendar weather data after updates have been made to the table
        fillCalendarWeatherData()
    }
    
    
    func formatLocation(_ location: String) -> String {
        // Split into parts around comma
        let parts = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard parts.count == 2 else {
            return location.capitalized  // fallback
        }
        
        let city = parts[0].capitalized
        let state: String
        
        if parts[1].count == 2 {
            state = parts[1].uppercased() // State usually uppercase (MN)
        } else {
            state = parts[1].capitalized // State usually uppercase (MN)
        }
        
        return "\(city), \(state)"
    }
    
    
    // function to fill calendarWeatherData with all weather data from the database
    func fillCalendarWeatherData() {
        // select all weather from DB
        self.calendarWeatherData = weatherDH.selectAllWeather()
        
    }
    
    
    func getWeatherSymbol(for condition: String?) -> String {
        guard let condition = condition?.lowercased() else {
            return "questionmark"
        }
        
        if condition.contains("clear") {
            return "sun.max"
        } else if condition.contains("rain") {
            return "cloud.drizzle"
        } else if condition.contains("partially") {
            return "cloud.sun"
        } else if condition.contains("cloudy") {
            return "cloud.fill"
        } else {
            return "questionmark"
        }
    }
    
        
    func getWeatherColor(for condition: String?) -> Color {
        guard let condition = condition?.lowercased() else {
            return Color(red: 0.96, green: 0.96, blue: 0.96)
        }
        if condition.contains("clear") {
            return Color(red: 1.00, green: 0.99, blue: 0.87)
        } else if condition.contains("rain") {
            return Color(red: 0.65, green: 0.82, blue: 0.91)
        } else if condition.contains("partially") {
            return Color(red: 0.85, green: 0.95, blue: 1.00)
        } else if condition.contains("cloudy") {
            return Color(red: 0.76, green: 0.76, blue: 0.76)
        } else {
            return Color(red: 0.96, green: 0.96, blue: 0.96)
        }
    }
    
    
    
}

// MARK: - Response Models

struct VisualCrossingResponse: Decodable {
    let days: [VisualCrossingDay]
    let unavailableReasons: [String]? // optional
}

struct VisualCrossingDay: Decodable {
    let datetime: Date
    let tempmax: Double
    let conditions: String
    
    enum CodingKeys: String, CodingKey {
        case datetime, tempmax, conditions
    }
    
    // Decode datetime string -> Date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .datetime)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .datetime,
                                                   in: container,
                                                   debugDescription: "Invalid date format")
        }
        //        self.datetime = date.addingTimeInterval(12 * 3600) // shifts to midday to avoid rollover
        self.datetime = date
        self.tempmax = try container.decode(Double.self, forKey: .tempmax)
        self.conditions = try container.decode(String.self, forKey: .conditions)
    }
}
