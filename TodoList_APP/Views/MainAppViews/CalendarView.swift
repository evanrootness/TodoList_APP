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
            
            // test mood color gradients
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) { day in
                    
                    let cellGradient = getMoodGradient(for: day)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Day number
                        Text("\(day)")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
                        
                    }
                    .padding(4)
                    .background(cellGradient)
                    .cornerRadius(6)
                    
                }
            }
            
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
//            
//            // Days grid
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
//                ForEach(daysInMonth, id: \.self) { day in
//                    VStack(alignment: .leading, spacing: 4) {
//                        // Day number
//                        Text("\(calendar.component(.day, from: day))")
//                            .fontWeight(.bold)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        // Routines for this day
//                        ForEach(routineVM.routines) { routine in
////                        ForEach(routineVM.routines.filter { $0.occurs(on: day) }) { routine in
//
//                            Text(routine.name)
//                                .font(.caption2)
//                                .foregroundColor(.blue)
//                                .lineLimit(1)
//                        }
//                    }
//                    .padding(4)
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(6)
//                }
//            }
//            .padding(.top)
        }
        .padding()
    }
    
    
    
    func getMoodGradient(for mood: Int) -> LinearGradient {
        switch mood {
        case let c where c == 1:
            return LinearGradient(
                colors: [Color(red: 0.01, green: 0.01, blue: 0.03), Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.15, green: 0.1, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 2:
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.02, blue: 0.14), Color(red: 0.15, green: 0.11, blue: 0.32), Color(red: 0.25, green: 0.2, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 3:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.05, blue: 0.25), Color(red: 0.27, green: 0.2, blue: 0.5), Color(red: 0.35, green: 0.4, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 4:
            return LinearGradient(
                colors: [Color(red: 0.35, green: 0.1, blue: 0.4), Color(red: 0.35, green: 0.35, blue: 0.6), Color(red: 0.3, green: 0.55, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 5:
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.2, blue: 0.5), Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.2, green: 0.8, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 6:
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.35, blue: 0.7), Color(red: 0.22, green: 0.65, blue: 0.85), Color(red: 0.47, green: 0.87, blue: 0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 7:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.65, blue: 0.85), Color(red: 0.14, green: 0.95, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 8:
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.75, blue: 0.83), Color(red: 0.35, green: 0.9, blue: 0.7), Color(red: 0.78, green: 0.9, blue: 0.29)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 9:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.82, blue: 0.75), Color(red: 0.6, green: 0.96, blue: 0.45), Color(red: 0.83, green: 0.92, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 10:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.95, blue: 0.7), Color(red: 0.8, green: 0.93, blue: 0.4), Color(red: 1.0, green: 0.8, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 11:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.4, blue: 0.6), Color(red: 0.4, green: 0.7, blue: 0.8), Color(red: 0.3, green: 0.8, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 12:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.4, blue: 0.5), Color(red: 0.65, green: 0.5, blue: 0.6), Color(red: 0.4, green: 0.5, blue: 0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 13:
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.75, blue: 0.6), Color(red: 0.98, green: 0.87, blue: 0.34), Color(red: 0.9, green: 0.5, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 14:
            return LinearGradient(
                colors: [Color(red: 0.7, green: 0.5, blue: 0.9), Color(red: 0.98, green: 0.4, blue: 0.34), Color(red: 0.98, green: 0.87, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let c where c == 15:
            return LinearGradient(
                colors: [Color(red: 0.4, green: 0.3, blue: 0.8), Color(red: 0.7, green: 0.4, blue: 0.5), Color(red: 0.6, green: 0.4, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
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





struct  CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .environmentObject(RoutineViewModel())
    }
}


