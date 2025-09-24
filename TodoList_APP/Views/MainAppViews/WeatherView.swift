//
//  WeatherView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/17/25.
//

import SwiftUI


struct WeatherView: View {
    @EnvironmentObject var weatherVM: WeatherViewModel
    
    // Current month start date
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    
    // User selected month to view
    @State private var selectedMonth: Date = Date() // start at today

    let calendar = Calendar.current
    let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    let buttonBlue = Color(red: 0.4, green: 0.55, blue: 1.0)
    
    //    private var unitCharacter: String {
    //        if (weatherVM.selectedUnits == .us) {
    //            return "°F"
    //        } else {
    //            return "°C"
    //        }
    //    }
    
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()
    
    
    
    // All days in the current month
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))
        else { return [] }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    // Weekday symbols (Sun, Mon, Tue...)
    let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols
    
    var firstWeekdayOfMonth: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: selectedMonth)
        let firstOfMonth = Calendar.current.date(from: components)!
        // weekday is 1=Sunday, 2=Monday, etc.
        return Calendar.current.component(.weekday, from: firstOfMonth)
    }
    
    var daysWithOffset: [Date?] {
        let emptySlots = firstWeekdayOfMonth - 1
        let placeholders = Array(repeating: nil as Date?, count: emptySlots)
        let days = daysInMonth.map { Optional($0) } // convert to Date?
        return placeholders + days
    }
    
    
    var body: some View {
        VStack() {
            
            // Calendar View
            HStack{
                Button(action: {
                    // Go to previous month
                    if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                        selectedMonth = newDate
                    }
                }) { Image(systemName: "arrow.left") }
                    .frame(width: 35, height: 25, alignment: .trailing)
                
                //                Text("\(viewMonthString)")
                Text(selectedMonth, formatter: monthFormatter)
                //                    .padding(5)
                    .frame(alignment: .center)
                
                Button(action: {
                    // Go to next month
                    if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                        selectedMonth = newDate
                    }
                }) { Image(systemName: "arrow.right") }
                    .frame(width: 35, height: 35, alignment: .leading)
                
            }
            .padding(.top)
            
            
            
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { daySymbol in
                    Text(daySymbol)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(daysWithOffset.indices, id: \.self) { index in
                    
                    if let day = daysWithOffset[index] {
                        let filteredWeather = weatherVM.calendarWeatherData.filter {
                            Calendar.current.isDate($0.date, inSameDayAs: day)
                        }
                        let cellGradient = filteredWeather.first.map { getWeatherGradient(for: $0.conditions) }
                        ?? LinearGradient(colors: [Color(red: 0.7, green: 0.7, blue: 0.7, opacity: 0.2), Color(red: 0.85, green: 0.85, blue: 0.85, opacity: 0.05)],
                                          startPoint: .top,
                                          endPoint: .bottom)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // Left side: day number (top) and condition icon (bottom)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(Calendar.current.component(.day, from: day))")
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(4)
                                        .shadow(color: Color(red: 0.4, green: 0.4, blue: 0.4), radius: 1, x: 1, y: 1)
                                    Spacer()
                                    
                                    if let weatherDay = filteredWeather.first {
                                        WeatherIconView(
                                            symbol: weatherVM.getWeatherSymbol(for: weatherDay.conditions)
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(4)
                                        .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.3), radius: 1, x: 1, y: 1)
                                    }
                                }
                                //                                .padding(4)
                                
                                Spacer()
                                
                                VStack{
                                    // Right side: temperature
                                    if let weatherDay = filteredWeather.first {
                                        Text("\(Int(weatherDay.temp))°")
                                            .font(.system(size: 24, design: .serif))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                            .frame(width: 40)
                                            .frame(maxWidth: .infinity)
                                            .padding([.trailing, .top] , 10)
                                            .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.3), radius: 1, x: 1, y: 1)
                                    }
                                    Spacer()
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                        }
                        .padding(4)
                        //                        .background(cellColor)
                        .background(cellGradient)
                        .cornerRadius(6)
                    } else {
                        Color(.clear)
                            .frame(height: 50)
                    }
                }
                .frame(height: 80)
            }
            .frame(minWidth: 800)
            //            .frame(height: 400)
            
            
            // manual input hstack
            HStack {
                TextField("Location", text: $weatherVM.location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                DatePicker("Start",
                           selection: $startDate,
                           in: ...oneDayAgo,
                           displayedComponents: .date)
                .padding([.leading, .trailing], 5)
                .layoutPriority(1)
                DatePicker("End",
                           selection: $endDate,
                           in: min(startDate, oneDayAgo)...oneDayAgo,
                           displayedComponents: .date
                )
                .padding([.leading, .trailing], 5)
                .layoutPriority(1)
                
                
                Button("Fetch Weather") {
                    // Normalize start
                    let startLocalMidnight = calendar.startOfDay(for: startDate)
                    let startUTC = startLocalMidnight.addingTimeInterval(-TimeInterval(TimeZone.current.secondsFromGMT(for: startLocalMidnight)))
                    
                    // Normalize end → subtract 1 day
                    let endLocalMidnight = calendar.startOfDay(for: endDate)
                    let inclusiveEndLocal = calendar.date(byAdding: .day, value: -1, to: endLocalMidnight)!
                    let endUTC = inclusiveEndLocal.addingTimeInterval(-TimeInterval(TimeZone.current.secondsFromGMT(for: inclusiveEndLocal)))
                    
                    weatherVM.loadWeather(start: startUTC, end: endUTC)
                }
                .padding(5)
                .background(buttonBlue)
                .foregroundColor(.white)
                .cornerRadius(7)
                .buttonStyle(PlainButtonStyle())
                .padding([.leading, .trailing], 10)
            }
            .padding([.top, .bottom], 5)
            
            
            if weatherVM.isLoading {
                ProgressView("Fetching...")
            }
            
            // manual input data
            VStack {
                List(weatherVM.weatherData) { day in
                    HStack {
                        Text(day.date, style: .date)
                        Spacer()
                        //                        Text("\(Int(day.temp))\(unitCharacter)")
                        Text("\(Int(day.temp))°F")
                        Text(day.conditions)
                        //                            .italic()
                        //                            .foregroundColor(.gray)
                        Text(weatherVM.formatLocation(day.location))
                            .italic()
                            .foregroundColor(.gray)
                    }
                }
                .frame(minHeight: 100)
                .padding(.bottom)
                
            }
        }
        .padding([.leading, .trailing])
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    
    func getWeatherGradient(for conditions: String) -> LinearGradient {
        switch conditions.lowercased() {
        case let c where c.contains("clear"):
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.4, blue: 0.9), Color(red: 0.4, green: 0.7, blue: 0.9), Color(red: 0.7, green: 0.95, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c.contains("rain"):
            return LinearGradient(
                colors: [Color(red: 0.0, green: 0.3, blue: 0.4), Color(red: 0.35, green: 0.55, blue: 0.65), Color(red: 0.5, green: 0.8, blue: 0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c.contains("partially"):
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.6, blue: 0.9), Color(red: 0.8, green: 0.9, blue: 0.95), Color(red: 0.99, green: 0.95, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c.contains("cloudy"):
            return LinearGradient(
                colors: [Color(red: 0.0, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.4, blue: 0.5), Color(red: 0.4, green: 0.5, blue: 0.6)],
                startPoint: .topLeading,
                endPoint: .bottom
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


struct WeatherIconView: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18))
            .padding(2)
        //            .frame(width: 20, height: 20)
        //            .symbolRenderingMode(.multicolor)
            .foregroundColor(.white)
    }
}

private let monthFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "LLLL yyyy" // e.g. "September 2025"
    return df
}()



struct WeatherPreviews: PreviewProvider {
    static var previews: some View {
        WeatherView()
            .environmentObject(WeatherViewModel())
    }
}


