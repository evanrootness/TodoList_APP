//
//  Sidebar.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI

enum SidebarTab: String, CaseIterable {
    case report, music, calendar, routines, history, settings

    var icon: String {
        switch self {
        case .report: return "exclamationmark.triangle.fill"
        case .music: return "music.note"
        case .calendar: return "calendar"
        case .routines: return "clock.arrow.circlepath"
        case .history: return "book"
        case .settings: return "gearshape"
        }
    }
}


