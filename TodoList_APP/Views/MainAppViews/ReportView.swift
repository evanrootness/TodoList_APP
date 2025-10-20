//
//  ReportView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI
import Foundation


struct ReportView: View {
    @EnvironmentObject var reportVM: ReportViewModel
    @State private var selectedMonth: Date = Date() // start at today
    @State private var selectedXAxis: String = "Sleep"
    @State private var selectedYAxis: String = "Mood"
    
    var filteredDataPoints: [ScatterPlotView.DataPoint] {
        reportVM.reportData.compactMap { data in
            let x: Double?
            let y: Double?
            
            // X-axis mapping
            switch selectedXAxis {
            case "Sleep Start":
                x = sleepHourForChart(data.sleepStart)
            case "Sleep End":
                x = timeToHourFraction(data.sleepEnd)
            case "Mood":
                x = data.mood
            case "Productivity":
                x = data.productivity
            case "Sleep":
                x = data.sleep
            case "Exercise":
                x = data.exercise
            case "Temperature":
                x = data.temp
            default:
                x = nil
            }
            
            // Y-axis mapping
            switch selectedYAxis {
            case "Sleep Start":
                y = sleepHourForChart(data.sleepStart)
            case "Sleep End":
                y = timeToHourFraction(data.sleepEnd)
            case "Mood":
                y = data.mood
            case "Productivity":
                y = data.productivity
            case "Sleep":
                y = data.sleep
            case "Exercise":
                y = data.exercise
            case "Temperature":
                y = data.temp
            default:
                y = nil
            }
            
            // Only keep rows with valid numeric X and Y
            if let x = x, let y = y, !x.isNaN, !y.isNaN {
                return ScatterPlotView.DataPoint(x: x, y: y)
            } else {
                return nil
            }
        }
    }

    
    let availableAxes = ["Mood", "Productivity", "Temperature", "Sleep", "Exercise", "Sleep Start", "Sleep End"]
    
    let calendar = Calendar.current
    
    let scorecardGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.2, blue: 0.6), Color(red: 0.22, green: 0.6, blue: 0.8), Color(red: 0.85, green: 0.8, blue: 0.3)],
        startPoint: .bottomLeading,
        endPoint: .top
    )
    let streakGradient = LinearGradient(
//        colors: [Color(red: 0.8, green: 0.1, blue: 0.1), Color(red: 0.85, green: 0.5, blue: 0.2), Color(red: 0.8, green: 0.87, blue: 0.4)],
        colors: [Color(red: 0.8, green: 0.87, blue: 0.4), Color(red: 0.85, green: 0.3, blue: 0.15), Color(red: 0.1, green: 0.3, blue: 0.65)],
        startPoint: .topLeading,
        endPoint: .bottom
    )
    
    // Helper to extract values dynamically
    func values(for axis: String) -> [Double] {
        switch axis {
        case "Mood": return reportVM.reportData.map { Double($0.mood) }
        case "Productivity": return reportVM.reportData.map { Double($0.productivity) }
        case "Sleep": return reportVM.reportData.map { $0.sleep }
        case "Exercise": return reportVM.reportData.map { $0.exercise }
            
        case "Temp": return reportVM.reportData.map {
//            $0.temp
            
            $0.temp != nil ? $0.temp! : Double.nan
        }
            

//        case "Sleep Start": return reportVM.reportData.map { sleepHourForChart($0.sleepStart)}
        case "Sleep Start": return reportVM.reportData.compactMap { data in
//            guard let sleepStart = dataRow.sleepStart else { return nil }
//            return sleepHourForChart(sleepStart)
            
//            $0.sleepStart != nil ? sleepHourForChart($0.sleepStart!) : Double.nan
            
            let value = sleepHourForChart(data.sleepStart)
            return value.isNaN ? nil : value
        }
            
//        case "Sleep End": return reportVM.reportData.map { timeToHourFraction($0.sleepEnd) }
        case "Sleep End": return reportVM.reportData.compactMap { data in
//            guard let sleepEnd = dataRow.sleepEnd else { return nil }
//            return timeToHourFraction(sleepEnd)
            
//            $0.sleepEnd != nil ? timeToHourFraction($0.sleepEnd!) : Double.nan
            
            let value = timeToHourFraction(data.sleepEnd)
            return value.isNaN ? nil : value
        }
        
        default: return []
        }
    }
    
    func timeToHourFraction(_ date: Date?) -> Double {
        guard let date = date else { return Double.nan }
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
    }
    
    func hoursSinceMidnight(_ date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hours = Double(comps.hour ?? 0)
        let minutes = Double(comps.minute ?? 0)
        return hours + minutes / 60.0
    }
    
    func sleepHourForChart(_ date: Date?) -> Double {
        guard let date = date else { return Double.nan }
        var hour = hoursSinceMidnight(date)
        if hour < 12 { // consider times after midnight as +24
            hour += 24
        }
        return hour
    }
    
    
    var body: some View {
        
        ScrollView {
            VStack {
                
//                Text("Key Metrics")
//                    .font(.system(size: 16, design: .serif))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding()

                // Scorecard row
                HStack (spacing: 10) {
                    
                    // Streak
                    VStack{
                        Text("Streak")
                            .font(.system(size: 16, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        VStack {
                            Text("Streak")
                                .padding(.top, 15)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.white)
                            Text("\(reportVM.inputStreak)")
                                .padding([.leading, .trailing], 30)
                                .font(.system(size: 28, design: .serif))
                                .foregroundColor(.white)
                            Text("Days")
                                .padding(.bottom, 15)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.white)
                        }
                        .background(streakGradient)
                        .cornerRadius(10)
                        .frame(width: 150)
                        .frame(minHeight: 50)
                    }
                    
                    // Last Week
                    VStack {
                        
                        Text("Last Week's Averages")
                            .font(.system(size: 16, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.leading], 10)
                        
                        HStack(spacing: 10) {
                            lastWeekScorecard(title: "Mood", avg: reportVM.getAvg(\.mood, numDays: -7))
                            lastWeekScorecard(title: "Prod", avg: reportVM.getAvg(\.productivity, numDays: -7))
                            lastWeekScorecard(title: "Sleep", avg: reportVM.getAvg(\.sleep, numDays: -7))
                            lastWeekScorecard(title: "Exercise", avg: reportVM.getAvg(\.exercise, numDays: -7))
                        }
                        .frame(alignment: .leading)
                        
                        // Last Month
                        
                        Text("Last Month's Averages")
                            .font(.system(size: 16, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.leading], 10)
                        
                        HStack(spacing: 10) {
                            lastMonthScorecard(title: "Mood", avg: reportVM.getAvg(\.mood, numDays: -30))
                            lastMonthScorecard(title: "Prod", avg: reportVM.getAvg(\.productivity, numDays: -30))
                            lastMonthScorecard(title: "Sleep", avg: reportVM.getAvg(\.sleep, numDays: -30))
                            lastMonthScorecard(title: "Exercise", avg: reportVM.getAvg(\.exercise, numDays: -30))
                        }
                        .frame(alignment: .leading)
                            
 
                        
                    }
                    .padding([.top, .leading, .trailing], 10)
                    .frame(maxWidth: .infinity)
                    
                }
                
                
                // Hstack calendar and chart
                HStack {
                    
                    // mood calendar
                    VStack {
                        HStack {
                            Text("Your Moods")
                                .font(.system(size: 20, design: .serif))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        
                        // Month switcher row
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
                                .padding([.leading, .trailing], 0)
                                .font(.system(size: 14, design: .serif))
                            
                            Button(action: {
                                // Go to next month
                                if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                                    selectedMonth = newDate
                                }
                            }) { Image(systemName: "arrow.right") }
                                .frame(width: 35, height: 35, alignment: .leading)
                            
                        }
//                        .padding(.top)
                        
                        // Weekday headers
                        HStack {
                            ForEach(weekdaySymbols, id: \.self) { daySymbol in
                                Text(daySymbol)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // day cells
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                            ForEach(daysWithOffset.indices, id: \.self) { index in
                                
                                if let day = daysWithOffset[index] {
                                    let filteredRow = reportVM.reportData.filter {
                                        Calendar.current.isDate($0.date, inSameDayAs: day)
                                    }
                                    let cellGradient = filteredRow.first.map { reportVM.getMoodGradient(for: $0.mood) }
                                    ?? LinearGradient(colors: [Color(red: 0.9, green: 0.8, blue: 0.85, opacity: 0.2)],
                                                      startPoint: .top,
                                                      endPoint: .bottom)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("\(Calendar.current.component(.day, from: day))")
                                            .font(.system(size: 16, design: .serif))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .shadow(color: Color(red: 0.5, green: 0.5, blue: 0.5), radius: 1, x: 0.8, y: 0.8)
                                        
//                                        if let row = filteredRow.first {
//                                            Text("\(row.mood)")
//                                                .font(.system(size: 15, design: .serif))
//                                                .foregroundColor(.white)
//                                                .lineLimit(1)
//                                                .frame(maxWidth: .infinity)
//                                                .padding([.trailing, .top] , 5)
//                                        }
                                    }
                                    .padding(4)
                                    .frame(minHeight: 40)
                                    .background(cellGradient)
                                    .cornerRadius(6)
                                } else {
                                    Color(.clear)
                                    .frame(minHeight: 50)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 350, maxWidth: 500)
                    .padding(10)
                    
                    
                    // correlation chart
                    VStack {
                        HStack {
                            Text("Your Correlations")
                                .font(.system(size: 20, design: .serif))
                                .padding(.leading, 20)
                            Spacer()
                        }
                        
//                        // Build correlation points dynamically
//                        let xValues = values(for: selectedXAxis)
//                        let yValues = values(for: selectedYAxis)
//                        
//                        let correlationPoints = zip(xValues, yValues).map { ScatterPlotView.DataPoint(x: $0, y: $1) }
                        
//                        ScatterPlotView(xAxisTitle: selectedXAxis, yAxisTitle: selectedYAxis, points: correlationPoints)
                        ScatterPlotView(xAxisTitle: selectedXAxis, yAxisTitle: selectedYAxis, points: filteredDataPoints)

                        
                        // Axes pickers
                        HStack {
                            Picker("X Axis", selection: $selectedXAxis) {
                                ForEach(availableAxes, id: \.self) { axis in
                                    Text(axis).tag(axis)
                                }
                            }
                            Picker("Y Axis", selection: $selectedYAxis) {
                                ForEach(availableAxes, id: \.self) { axis in
                                    Text(axis).tag(axis)
                                }
                            }
                        }
                        .pickerStyle(MenuPickerStyle()) // or SegmentedPickerStyle()
                        
                    }
                    .padding(10)
                }
                
                
                // Row of listening history and ...
                HStack {
                    ListeningTimeChartView()
                    
                }
                
                ReportDataTableView(reportVM: reportVM)
                
            }
        }
//        .onAppear {
//            reportVM.refreshReportData()
//        }
    }
        

    
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
    
}


private let monthFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "LLLL" // yyyy" // e.g. "September 2025"
    return df
}()





struct lastWeekScorecard: View {
    @EnvironmentObject var reportVM: ReportViewModel
    let title: String
    let avg: Double
    
    let scorecardGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.2, blue: 0.6), Color(red: 0.22, green: 0.6, blue: 0.8), Color(red: 0.5, green: 0.8, blue: 0.6)],
        startPoint: .bottomLeading,
        endPoint: .top
    )
    
    var body: some View {
        
        VStack {
            Text("\(title)")
//                .padding([.leading, .top, .trailing], 15)
                .padding(.top, 20)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.white)
                .frame(width: 100)
            Text(String(format: "%.1f", avg))
//                .padding([.leading, .trailing], 20)
                .padding(.bottom, 20)
                .font(.system(size: 28, design: .serif))
                .foregroundColor(.white)
                .frame(width: 100)
        }
        .background(scorecardGradient)
        .cornerRadius(10)
        .frame(height: 100)
//        .frame(maxWidth: 150, minHeight: 50)
    }
}


struct lastMonthScorecard: View {
    @EnvironmentObject var reportVM: ReportViewModel
    let title: String
    let avg: Double
    
    let scorecardGradient = LinearGradient(
        colors: [Color(red: 0.5, green: 0.15, blue: 0.6), Color(red: 0.45, green: 0.4, blue: 0.85), Color(red: 0.8, green: 0.6, blue: 0.6)],
        startPoint: .bottomLeading,
        endPoint: .top
    )
    
    var body: some View {
        
        VStack {
            Text("\(title)")
//                .padding([.leading, .top, .trailing], 15)
                .padding(.top, 20)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.white)
                .frame(width: 100)
            Text(String(format: "%.1f", avg))
//                .padding([.leading, .trailing], 20)
                .padding(.bottom, 20)
                .font(.system(size: 28, design: .serif))
                .foregroundColor(.white)
                .frame(width: 100)
        }
        .background(scorecardGradient)
        .cornerRadius(10)
        .frame(height: 100)
//        .frame(maxWidth: 150, minHeight: 50)
    }
}






struct  ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView()
            .environmentObject(ReportViewModel())
    }
}
