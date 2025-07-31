//
//  CalendarView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI
import Foundation


struct CalendarView: View {
    var body: some View {
        Text("calendar view fr")
    }
}

//struct BasicCalendarView: View {
//    private let calendar = Calendar.current
//    private let currentDate = Date()
//
//    private var daysInMonth: [Date] {
//        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
//              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
//            return []
//        }
//
//        return range.compactMap { day -> Date? in
//            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
//        }
//    }
//
//    private var weekdaySymbols: [String] {
//        calendar.shortWeekdaySymbols
//    }
//
//    var body: some View {
//        VStack {
//            Text(monthYearTitle)
//                .font(.title2)
//                .padding()
//
//            // Weekday headers
//            HStack {
//                ForEach(weekdaySymbols, id: \.self) { day in
//                    Text(day)
//                        .font(.subheadline)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//
//            // Days grid
//            let firstWeekday = calendar.component(.weekday, from: daysInMonth.first ?? Date()) - 1
//            let leadingEmptyDays = Array(repeating: nil as Date?, count: firstWeekday)
//            let allDays = leadingEmptyDays + daysInMonth.map { Optional($0) }
//
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
//                ForEach(allDays.indices, id: \.self) { index in
//                    if let date = allDays[index] {
//                        Text("\(calendar.component(.day, from: date))")
//                            .frame(maxWidth: .infinity, minHeight: 40)
//                            .background(Color(.systemGray6))
//                            .cornerRadius(4)
//                    } else {
//                        Color.clear.frame(minHeight: 40)
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//
//    private var monthYearTitle: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "LLLL yyyy"
//        return formatter.string(from: currentDate)
//    }
//}
//
//struct BasicCalendarView_Previews: PreviewProvider {
//    static var previews: some View {
//        BasicCalendarView()
//    }
//}
