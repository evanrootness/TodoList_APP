//
//  TabCoordinator.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI

struct TabCoordinator {
    @ViewBuilder
    static func view(for tab: SidebarTab) -> some View {
        switch tab {
        case .report:
            ReportView()
        case .input:
            DailyInputView()
        case .music:
            MusicView()
        case .weather:
            WeatherView()
        case .calendar:
            CalendarView()
//        case .routines:
//            RoutinesView()
//        case .history:
//            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
