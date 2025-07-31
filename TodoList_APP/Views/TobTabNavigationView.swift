//
//  TabView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 7/30/25.
//

import SwiftUI
import Foundation

struct TopTabNavigationView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case list = "List"
        case calendar = "Calendar"
        case settingss = "Settings"

        var id: String { self.rawValue }
    }

    @State private var selectedTab: Tab = .list

    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Tab content
            Spacer()
            switch selectedTab {
            case .list:
                ListView()
            case .calendar:
                CalendarView()
            case .settingss:
                Text("This is the Calendar")
            }
            Spacer()
        }
        .navigationTitle("My App")
    }
}

struct TopTabNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TopTabNavigationView()
        }
    }
}
