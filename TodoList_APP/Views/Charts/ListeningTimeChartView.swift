//
//  ListeningTimeChartView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/24/25.
//

import SwiftUI
import Charts
import SQLite

struct ListeningTimeChartView: SwiftUI.View {
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
    @State private var endDate: Date = Date()
    @State private var bins: [ListeningBin] = []

    var body: some SwiftUI.View {
        VStack {
            // Date pickers
            HStack {
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                DatePicker("End", selection: $endDate, displayedComponents: .date)
            }
            .padding()

            Button("Load Data") {
                bins = fetchListeningBins(start: startDate, end: endDate)
            }
            .padding()

            if bins.isEmpty {
                Text("No data for selected range")
                    .foregroundStyle(.secondary)
            } else {
                Chart(bins) { bin in
                    BarMark(
                        x: .value("Period", bin.date, unit: .day),
                        y: .value("Minutes Listened", bin.minutesListened)
                    )
                    .foregroundStyle(Color(red:0.35, green:0.15, blue:0.9))
                    .cornerRadius(7)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 300)
                .padding()
            }
        }
        .onAppear {
            bins = fetchListeningBins(start: startDate, end: endDate)
        }
    }

    // MARK: Data Fetch + Aggregation
    func fetchListeningBins(start: Date, end: Date) -> [ListeningBin] {
        let db = MusicDatabaseManager.shared
        var results: [ListeningBin] = []

        do {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            let startString = formatter.string(from: start)
            let endString = formatter.string(from: end)

            let query = db.listeningHistory
                .filter(db.playedAtColumn >= startString && db.playedAtColumn <= endString)

            var buckets: [String: Int] = [:]
            var dateForLabel: [String: Date] = [:]

            // Decide granularity: days if <= 30 days, else weeks
            let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
            let useWeeks = days > 30

            for row in try db.db.prepare(query) {
                guard let duration = row[db.trackDurationColumn] else { continue }
                let playedAtString = row[db.playedAtColumn]

                if let playedAt = formatter.date(from: playedAtString) {
                    let label: String
                    let groupingDate: Date
                    
                    if useWeeks {
                        // Group by ISO week number
                        let comps = Calendar.current.dateComponents([.weekOfYear, .yearForWeekOfYear], from: playedAt)
                        let startOfWeek = Calendar.current.date(from: comps) ?? playedAt
                        groupingDate = startOfWeek
                        label = "Week \(comps.weekOfYear ?? 0), \(comps.yearForWeekOfYear ?? 0)"
                    } else {
                        // Group by date
                        groupingDate = Calendar.current.startOfDay(for: playedAt)
                        let df = DateFormatter()
                        df.dateFormat = "MMM d"
                        label = df.string(from: groupingDate)
                    }

                    buckets[label, default: 0] += duration
                    dateForLabel[label] = groupingDate
                }
            }

            // Convert ms → minutes and store the actual date
            results = buckets.compactMap { key, value in
                dateForLabel[key].map { actualDate in
                    ListeningBin(date: actualDate, label: key, minutesListened: value / 60000)
                }
                
            }
            .sorted { $0.date < $1.date }

        } catch {
            print("DB error: \(error)")
        }

        return results
    }
}

struct ListeningBin: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let minutesListened: Int
}
