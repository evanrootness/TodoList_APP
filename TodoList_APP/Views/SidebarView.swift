//
//  CallapsibleSidebar.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/10/25.
//

import SwiftUI

struct CollapsibleSidebar: View {
    @State private var isHovered = false
    @Binding var selectedTab: SidebarTab
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
        }
    }
    
    var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack {
                        Image(systemName: tab.icon)
                            .frame(width: 24, height: 24)
                        if isHovered {
                            Text(tab.rawValue)
                                .foregroundStyle(.primary)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            Spacer()
        }
        .padding(.top, 20)
        .padding(.horizontal, isHovered ? 12 : 4)
        .frame(width: isHovered ? 160 : 50)
        .background(Color.gray.opacity(0.1))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var content: some View {
        ZStack {
            switch selectedTab {
            case .report:
                ReportView()
            case .input:
                DailyInputView()
            case .music:
                MusicView()
            case .weather:
                WeatherView()
//            case .calendar:
//                CalendarView()
//            case .routines:
//                RoutinesView()
//            case .history:
//                HistoryView()
            case.settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


