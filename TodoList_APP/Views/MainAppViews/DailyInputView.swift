//
//  DailyInputView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/25/25.
//


import SwiftUI


struct DailyInputView: View {
    @EnvironmentObject var inputVM: DailyInputViewModel
    
    @State private var dailyInputDict: [String: String] = [:]
    
    @State private var sleepStart = Date()
    @State private var sleepEnd = Date()
    @State private var inputDate = Date()
    
    
    var body: some View {
        VStack{
            Spacer()
            VStack{
                
//                Text("Day of Input")
//                    .frame(maxWidth: .infinity, alignment: .leading)
                DatePicker(
                    "Day of Input",
                    selection: $inputDate,
                    displayedComponents: [.date]
                )
                .onChange(of: inputDate) { oldValue, newValue in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    dailyInputDict["date"] = formatter.string(from: newValue)
//                    dailyInputDict["date"] = $inputDate.stringBinding(forKey: "date")
                }
                
                
                Text("How did you feel today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "mood"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("How productive were you today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("1-10", text: $dailyInputDict.stringBinding(forKey: "productivity"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                
                Form {
                    Section(header: Text("Sleep")) {
                        DatePicker(
                            "Sleep Start",
                            selection: $sleepStart,
                            displayedComponents: [.hourAndMinute]
                        )
                        .onChange(of: sleepStart) { oldValue, newValue in
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
                        
                        DatePicker(
                            "Sleep End",
                            selection: $sleepEnd,
                            displayedComponents: [.hourAndMinute]
                        )
                        .onChange(of: sleepEnd) { oldValue, newValue in
                            // Combine inputDate with sleep end time (same day)
                            let calendar = Calendar.current
                            let endDate = calendar.date(
                                bySettingHour: calendar.component(.hour, from: sleepEnd),
                                minute: calendar.component(.minute, from: sleepEnd),
                                second: 0,
                                of: inputDate
                            )!

                            dailyInputDict["sleepEnd"] = iso8601String(from: endDate)
                        }
                    }
                }
                
//                Text("How long did you sleep last night?")
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                TextField("Enter in hours", text: $dailyInputDict.stringBinding(forKey: "sleep"))
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("How long did you exercise today?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter in hours", text: $dailyInputDict.stringBinding(forKey: "exercise"))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
            }
            .frame(maxHeight: .infinity)
            .padding(80)
            
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
                
                inputVM.logDailyData(dailyInputDict: dailyInputDict, inputDate: inputDate)
                
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
    
    
    func combineDatetime(date: Date, time: Date) -> Date {
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
