//
//  WeatherView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/17/25.
//

import SwiftUI


struct WeatherView: View {
    @StateObject private var weatherVM = WeatherViewModel()
    
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    //    @State private var selectedUnits = "Metric"
    
    
    // User selected month to view
    @State private var viewMonthNumber: Int = Calendar.current.component(.month, from: Date())
    private var viewMonthString: String { DateFormatter().monthSymbols[viewMonthNumber - 1] }
    
    let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    
    private let dbHelper = WeatherDatabaseHelper.shared

    let buttonBlue = Color(red: 0.4, green: 0.55, blue: 1.0)
    
    private var unitCharacter: String {
        if (weatherVM.selectedUnits == .us) {
            return "°F"
        } else {
            return "°C"
        }
    }
    
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        return formatter
    }()
    
    // Current month start date
    let calendar = Calendar.current

    
    //    var currentMonthString: String = displayFormatter.string(from: Date().month())
    
    // All days in the current month
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: Date()),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))
        else { return [] }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    // Weekday symbols (Sun, Mon, Tue...)
    let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols
    
    var firstWeekdayOfMonth: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
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
                }) { Image(systemName: "arrow.left") }
                    .frame(width: 35, height: 25, alignment: .trailing)
                
                Text("\(viewMonthString)")
//                    .padding(5)
                    .frame(alignment: .center)

                Button(action: {
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
                        let cellColor = filteredWeather.first.map { weatherVM.getWeatherColor(for: $0.conditions) }
                                         ?? Color(red: 0.96, green: 0.96, blue: 0.96)

                        VStack(alignment: .leading, spacing: 4) {
                            // Day number
                            Text("\(Calendar.current.component(.day, from: day))")
//                                .font(.caption)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .font(.system(size: 10, design: .serif))
                                .foregroundColor(.black)


                            // Loop over weather for this day
                            ForEach(filteredWeather) { weatherDay in
                                HStack {
//                                    WeatherIconView(condition: weatherDay.conditions)
                                    WeatherIconView(
                                        symbol: weatherVM.getWeatherSymbol(for: weatherDay.conditions)
                                    )
//                                    .backgroundColor(.black)

                                    
                                    Text("\(Int(weatherDay.temp))°")
                                        .font(.system(size: 18, design: .serif))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(4)
                        .background(cellColor)
                        .cornerRadius(6)
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
                .frame(height: 50)
            }
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
                    weatherVM.loadWeather(start: startDate, end: endDate)
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
                        //                        Text(WeatherView.displayFormatter.string(from: day.id))
                        //                        Text(day.date)
                        
                        //                        Text(displayFormatter.string(from: day.date))
                        Text(day.date, style: .date)
                        Spacer()
                        Text("\(Int(day.temp))\(unitCharacter)")
                        Text(day.conditions)
//                            .italic()
//                            .foregroundColor(.gray)
                        Text(weatherVM.formatLocation(day.location))
                            .italic()
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                .padding(.bottom)

            }
        }
        .padding([.leading, .trailing])
        .frame(maxHeight: .infinity, alignment: .top)
    }
}


struct WeatherIconView: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .frame(width: 25, height: 25)
            .foregroundColor(.black)
//            .onAppear() {
//                print("WeatherIconView appeared")
//            }
    }
}
    
//
//    let condition: String?
//
//    var body: some View {
//        let symbol = weatherVM.getWeatherSymbol(for: condition)
//        Image(systemName: symbol)
//            .frame(width: 20, height: 20)
//    }
//}


struct WeatherPreviews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
