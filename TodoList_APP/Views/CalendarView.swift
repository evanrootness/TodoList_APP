//
//  CalendarView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI
import Foundation

struct CalendarView: View {
    
    @EnvironmentObject var routineVM: RoutineViewModel


//// Inside your calendar view grid:
//ForEach(routines.filter { $0.occurs(on: day) }) { routine in
//    Text(routine.name)
//        .font(.caption)
//        .foregroundColor(.blue)
//}



//    @EnvironmentObject var routineVM: RoutineViewModel
    
    // Current month start date
    let calendar = Calendar.current
    let currentMonth: Date = Date()
    
    // All days in the current month
    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }
    
    // Weekday symbols (Sun, Mon, Tue...)
    let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols
    
    var body: some View {
        VStack {
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 4) {
                        // Day number
                        Text("\(calendar.component(.day, from: day))")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Routines for this day
                        ForEach(routineVM.routines) { routine in
//                        ForEach(routineVM.routines.filter { $0.occurs(on: day) }) { routine in

                            Text(routine.name)
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.top)
        }
        .padding()
    }
}


struct  CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(RoutineViewModel())
    }
}


