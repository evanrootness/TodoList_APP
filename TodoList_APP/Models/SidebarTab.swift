//
//  Sidebar.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI

enum SidebarTab: String, CaseIterable {
    case report = "Report",
         input = "Daily Input",
         music = "Music",
         weather = "Weather",
         calendar = "Calendar",
//         routines = "Routines",
//         history = "History",
         settings = "Settings"

    var icon: String {
        switch self {
        case .report: return "chart.bar"
        case .input: return "smiley"
        case .music: return "music.note"
        case .weather: return "sun.max"
        case .calendar: return "calendar"
//        case .routines: return "clock.arrow.circlepath"
//        case .history: return "book"
        case .settings: return "gearshape"
        }
    }
}


