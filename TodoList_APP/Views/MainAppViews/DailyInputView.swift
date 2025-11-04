//
//  DailyInputView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/25/25.
//


import SwiftUI


struct DailyInputView: View {
    @EnvironmentObject var inputVM: DailyInputViewModel
    
    @StateObject var pieChart1: NutritionPieChartModel
    @StateObject var pieChart2: NutritionPieChartModel
    @StateObject var pieChart3: NutritionPieChartModel
    
    @State private var dailyInputDict: [String: String] = [:]
//    @State private var dailyInputNutrition:

    @State private var sleepStart: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var sleepEnd: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 40
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var inputDate: Date = Date()
    
    init() {
            let categories = DailyInputView.defaultCategories()
            _pieChart1 = StateObject(wrappedValue: NutritionPieChartModel(categories: categories))
            _pieChart2 = StateObject(wrappedValue: NutritionPieChartModel(categories: categories))
            _pieChart3 = StateObject(wrappedValue: NutritionPieChartModel(categories: categories))
        }
    
    
    var body: some View {
        VStack{
            Spacer()
            VStack{
            
                // Input day date picker
                DatePicker(
                    "Day of Input",
                    selection: $inputDate,
                    displayedComponents: [.date]
                )
                .onChange(of: inputDate) { oldValue, newValue in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    dailyInputDict["date"] = formatter.string(from: newValue)
                    
                    // set sleepStart and sleepEnd in dictionary
                    setDictSleepStart()
                    setDictSleepEnd()
                }
                
                
                Text("How did you feel today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "mood"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("How productive were you today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "productivity"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("How long did you exercise today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter in hours", text: $dailyInputDict.stringBinding(forKey: "exercise"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Sleep start and end date pickers
                Form {
//                    Section(header: Text("Sleep")) {
                    HStack {
                        DatePicker(
                            "Sleep Start",
                            selection: $sleepStart,
                            displayedComponents: [.hourAndMinute]
                        )
                        .onChange(of: sleepStart) { oldValue, newValue in
                            setDictSleepStart()
                        }
                        
                        DatePicker(
                            "Sleep End",
                            selection: $sleepEnd,
                            displayedComponents: [.hourAndMinute]
                        )
                        .onChange(of: sleepEnd) { oldValue, newValue in
                            setDictSleepEnd()
                        }
                    }
                }
                .padding(10)
                
                
                // Daily Nutrition input
                HStack(spacing: 10) {
                    NutritionPieChartView(model: pieChart1)
                    NutritionPieChartView(model: pieChart2)
                    NutritionPieChartView(model: pieChart3)
                }
                .frame(minWidth: 600)
                
            }
            .frame(maxHeight: .infinity)
            .padding(80)
            .onAppear {
                // set initial date string
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                dailyInputDict["date"] = formatter.string(from: inputDate)

                // set initial sleepStart and sleepEnd in ISO8601 (same as onChange)
                setDictSleepStart()
                setDictSleepEnd()
            }
            
            Spacer()
            
            Button(action: {
                let startDate = combineDatetime(date: inputDate, time: sleepStart)
                var endDate = combineDatetime(date: inputDate, time: sleepEnd)
                
                // If end < start, add 1 day (user slept past midnight)
                if endDate < startDate {
                    endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
                }

                let hoursSlept = endDate.timeIntervalSince(startDate) / 3600.0
                
                dailyInputDict["sleep"] = String(format: "%.2f", hoursSlept)
                
                inputVM.logDailyData(dailyInputDict: dailyInputDict, inputDate: inputDate, nutritionPieModels: [pieChart1, pieChart2, pieChart3])
                
            }) {
                Text("Log Data")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // store in UTC
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    
    private func combineDatetime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second
        
        return calendar.date(from: combined)!
    }
    
    
    static func defaultCategories() -> [FoodCategory] {
        [
            FoodCategory(name: "Protein", startColor: Color(red: 0.7, green: 0.3, blue: 0.6), endColor: Color(red: 0.25, green: 0.05, blue: 0.4), fraction: 0.2),
            FoodCategory(name: "Dairy/Fat", startColor: Color(red: 0.4, green: 0.65, blue: 1), endColor: Color(red: 0.05, green: 0.3, blue: 0.85), fraction: 0.1),
            FoodCategory(name: "Veg.", startColor: Color(red: 0.7, green: 0.8, blue: 0.0), endColor: Color(red: 0.0, green: 0.3, blue: 0.05), fraction: 0.3),
            FoodCategory(name: "Fruit", startColor: Color(red: 0.8, green: 0.8, blue: 0.25), endColor: Color(red: 0.7, green: 0.0, blue: 0.0), fraction: 0.1),
            FoodCategory(name: "Carbs", startColor: Color(red: 0.7, green: 0.5, blue: 0.4), endColor: Color(red: 0.4, green: 0.2, blue: 0.05), fraction: 0.25),
            FoodCategory(name: "Sugar", startColor: Color(red: 0.2, green: 0.2, blue: 0.2), endColor: Color(red: 0.03, green: 0.03, blue: 0.03), fraction: 0.05)
        ]
    }
    
    
    private func setDictSleepStart() {
        // Combine inputDate with the time from sleepStart
        let calendar = Calendar.current
        var startDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: sleepStart),
            minute: calendar.component(.minute, from: sleepStart),
            second: 0,
            of: inputDate
        )!
        
        let hour = calendar.component(.hour, from: sleepStart)
        // if sleep start time is between noon and midnight, subtract one day from the inputdate to get the day of sleep start
        if hour >= 12 && hour <= 23 {
            startDate = calendar.date(byAdding: .day, value: -1, to: startDate)!
        }
        
        // Convert to ISO8601 for the dictionary
        dailyInputDict["sleepStart"] = iso8601String(from: startDate)
    }
    
    
    private func setDictSleepEnd() {
        // Combine inputDate with sleep end time (same day)
        let calendar = Calendar.current
        let endDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: sleepEnd),
            minute: calendar.component(.minute, from: sleepEnd),
            second: 0,
            of: inputDate
        )!
        
        // Convert to ISO8601 for the dictionary
        dailyInputDict["sleepEnd"] = iso8601String(from: endDate)
    }
}



extension Binding where Value == [String: String] {
    func stringBinding(forKey key: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue[key] ?? "" },
            set: { self.wrappedValue[key] = $0 }
        )
    }
}



struct DailyInputView_Previews: PreviewProvider {
    static var previews: some View {
        DailyInputView()
            .environmentObject(DailyInputViewModel())
    }
}
