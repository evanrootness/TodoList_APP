//
//  RoutineOccurs.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/8/25.
//


import Foundation




extension Routine {
    // Returns true if the routine occurs on the given date
    func occurs(on date: Date) -> Bool {
        let calendar = Calendar.current
        
        switch repeatInterval {
        case .none:
            // Only happens on the start date
            return calendar.isDate(date, inSameDayAs: startDate)
            
        case .daily:
            // Happens every day starting from startDate
            return date >= startDate
            
        case .weekly:
            // Happens once a week on the same weekday as startDate
            guard let startWeekday = calendar.dateComponents([.weekday], from: startDate).weekday,
                  let currentWeekday = calendar.dateComponents([.weekday], from: date).weekday
            else { return false }
            return date >= startDate && startWeekday == currentWeekday
            
        case .monthly:
            // Happens once a month on the same day number as startDate
            let startDay = calendar.component(.day, from: startDate)
            let currentDay = calendar.component(.day, from: date)
            return date >= startDate && startDay == currentDay
        }
    }
}
