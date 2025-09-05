//
//  OpenMeteoViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/19/25.
//

import Foundation
import SwiftUI
import OpenMeteoSdk
import CoreLocation

struct DailyWeather: Identifiable {
    let id = UUID()
    let date: Date
    let tmin: Float
    let tmax: Float
    let weatherCode: Float
    let weatherCondition: String
}


enum OpenMeteoWeatherCode: Int {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case lightDrizzle = 51
    case moderateDrizzle = 53
    case denseDrizzle = 55
    case lightFreezingDrizzle = 56
    case moderateOrDenseFreezingDrizzle = 57
    case lightRain = 61
    case moderateRain = 63
    case heavyRain = 65
    case lightFreezingRain = 66
    case moderateOrHeavyFreezingRain = 67
    case slightSnowfall = 71
    case moderateSnowfall = 73
    case heavySnowfall = 75
    case snowGrains = 77
    case slightRainShowers = 80
    case moderateRainShowers = 81
    case heavyRainShowers = 82
    case slightSnowShowers = 85
    case heavySnowShowers = 86
    case thunderstormSlightOrModerate = 95
    case thunderstormStrong = 96
    case thunderstormHeavy = 99
    
    var conditionString: String {
        switch self {
        case .clearSky: return "Clear"
        case .mainlyClear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .overcast: return "Cloudy"
        case .fog: return "Fog"
        case .depositingRimeFog: return "Deposting Rime Fog"
        case .lightDrizzle: return "Drizzle"
        case .moderateDrizzle: return "Drizzle"
        case .denseDrizzle: return "Drizzle"
        case .lightFreezingDrizzle: return "Freezing Drizzle"
        case .moderateOrDenseFreezingDrizzle: return "Freezing Drizzle"
        case .lightRain: return "Rain"
        case .moderateRain: return "Rain"
        case .heavyRain: return "Rain"
        case .lightFreezingRain: return "Freezing Rain"
        case .moderateOrHeavyFreezingRain: return "Freezing Rain"
        case .slightSnowfall: return "Snow"
        case .moderateSnowfall: return "Snow"
        case .heavySnowfall: return "Snow"
        case .snowGrains: return "Snow Grains"
        case .slightRainShowers: return "Rain"
        case .moderateRainShowers: return "Rain"
        case .heavyRainShowers: return "Rain"
        case .slightSnowShowers: return "Snow"
        case .heavySnowShowers: return "Snow"
        case .thunderstormSlightOrModerate: return "Thunderstorm"
        case .thunderstormStrong: return "Thunderstorm"
        case .thunderstormHeavy: return "Thunderstorm"
        }
    }
}
    
    

@MainActor
class OpenMeteoWeatherViewModel: ObservableObject {
    @Published var town: String = ""
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var dailyWeather: [DailyWeather] = []
    @Published var errorMessage: String?

    private let geocoder = CLGeocoder()

    func fetchWeather() async {
        guard !town.isEmpty else {
            errorMessage = "Please enter a town."
            return
        }

        do {
            // Step 1: Geocode town → lat/lon
            let placemarks = try await geocoder.geocodeAddressString(town)
            guard let location = placemarks.first?.location else {
                errorMessage = "Could not find location."
                return
            }

            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude

            // Step 2: Format dates as yyyy-MM-dd
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let start = formatter.string(from: startDate)
            let end = formatter.string(from: endDate)

            // Step 3: Build API URL
            guard let url = URL(string:
                "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=temperature_2m_min,temperature_2m_max,weather_code&timezone=auto&start_date=\(start)&end_date=\(end)&format=flatbuffers"
            ) else {
                errorMessage = "Invalid URL"
                return
            }

            // Step 4: Fetch from OpenMeteo SDK
            let responses = try await WeatherApiResponse.fetch(url: url)
            guard let response = responses.first, let daily = response.daily else {
                errorMessage = "No data found"
                return
            }

            let utcOffset = response.utcOffsetSeconds
            let dates = daily.getDateTime(offset: utcOffset)

            let tminValues = daily.variables(at: 0)?.values ?? []
            let tmaxValues = daily.variables(at: 1)?.values ?? []
            let wcodeValues = daily.variables(at: 2)?.values ?? []

            // Step 5: Build DailyWeather objects
            var results: [DailyWeather] = []
            for i in 0..<dates.count {
                if i < tminValues.count, i < tmaxValues.count, i < wcodeValues.count {
                    results.append(DailyWeather(
                        date: dates[i],
                        tmin: tminValues[i] * 9 / 5 + 32,
                        tmax: tmaxValues[i] * 9 / 5 + 32,
                        weatherCode: wcodeValues[i],
                        weatherCondition: OpenMeteoWeatherCode(rawValue: Int(wcodeValues[i]))?.conditionString ?? "Code: \(wcodeValues[i]) is unknown"
                    ))
                }
            }

            self.dailyWeather = results.sorted { $0.date < $1.date }
            self.errorMessage = nil

        } catch {
            self.errorMessage = "Fetch failed: \(error.localizedDescription)"
        }
    }
}
