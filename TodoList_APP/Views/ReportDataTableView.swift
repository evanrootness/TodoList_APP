//
//  ReportDataTableView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 10/13/25.
//


import SwiftUI

struct ReportDataTableView: View {
    @ObservedObject var reportVM: ReportViewModel
    
    var body: some View {
        VStack {
            Text("Report Data Table")
                .font(.title2)
                .fontWeight(.medium)
                .padding(.top)

            if reportVM.reportData.isEmpty {
                Spacer()
                Text("No data available")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView([.vertical, .horizontal]) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Table header
                        HStack {
                            Text("Date").bold().frame(width: 100)
                            Text("Mood").bold().frame(width: 60)
                            Text("Prod").bold().frame(width: 60)
                            Text("Sleep").bold().frame(width: 60)
                            Text("Exercise").bold().frame(width: 80)
                            Text("Temp").bold().frame(width: 60)
                            Text("Sleep Start").bold().frame(width: 150)
                            Text("Sleep End").bold().frame(width: 150)
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        
                        Divider()

                        // Table rows
                        ForEach(reportVM.reportData.indices, id: \.self) { i in
                            let row = reportVM.reportData[i]
                            HStack {
                                Text(dateFormatter.string(from: row.date))
                                    .frame(width: 100, alignment: .leading)
                                Text(String(format: "%.1f", row.mood))
                                    .frame(width: 60)
                                Text(String(format: "%.1f", row.productivity))
                                    .frame(width: 60)
                                Text(String(format: "%.1f", row.sleep))
                                    .frame(width: 60)
                                Text(String(format: "%.1f", row.exercise))
                                    .frame(width: 80)
                                
                                if let temp = row.temp {
                                    Text(String(format: "%.1f", temp))
                                        .frame(width: 60)
                                } else {
                                    Text("—").foregroundStyle(.secondary)
                                        .frame(width: 60)
                                }
                                
                                
                                if let start = row.sleepStart {
                                    Text(timeFormatter.string(from: start))
                                        .frame(width: 150)
                                } else {
                                    Text("—").foregroundStyle(.secondary)
                                        .frame(width: 150)
                                }
                                
                                if let end = row.sleepEnd {
                                    Text(timeFormatter.string(from: end))
                                        .frame(width: 150)
                                } else {
                                    Text("—").foregroundStyle(.secondary)
                                        .frame(width: 150)
                                }
                            }
                            .padding(.vertical, 3)
                            Divider()
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Helpers

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d"
    return df
}()

private let timeFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "MMM d, h:mm a"
    return df
}()




//#Preview {
//    // Mock preview data
//    let mockVM = ReportViewModel()
//    mockVM.reportData = [
//        reportDataRow(date: Date(), mood: 7.5, productivity: 6.0, sleep: 8.0, exercise: 0.5, temp: 70.0, conditions: "Clear", location: "Home", sleepStart: Date().addingTimeInterval(-8*3600), sleepEnd: Date()),
//        reportDataRow(date: Date().addingTimeInterval(-86400), mood: 6.0, productivity: 7.0, sleep: 7.5, exercise: 1.0, temp: 68.0, conditions: "Cloudy", location: "Cabin", sleepStart: nil, sleepEnd: nil)
//    ]
//    return ReportDataTableView(reportVM: mockVM)
//}

