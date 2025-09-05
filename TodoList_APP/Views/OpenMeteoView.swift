//
//  OpenMeteoView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/19/25.
//

import SwiftUI

struct OMWeatherView: View {
    @StateObject private var vm = OpenMeteoWeatherViewModel()
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    var body: some View {

            VStack(spacing: 0) {
                // Town input
                TextField("Enter town name", text: $vm.town)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.all, 15)

                // Date pickers
                HStack {
                    DatePicker("Start", selection: $vm.startDate, displayedComponents: .date)
                    DatePicker("End", selection: $vm.endDate, displayedComponents: .date)
                    // Fetch button
                    Button("Fetch Weather") {
                        Task { await vm.fetchWeather() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.all, 10)

                // Error message
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }

                // Results
                List(vm.dailyWeather) { day in
                    VStack(alignment: .leading) {
                        Text(dateFormatter.string(from: day.date))
                            .font(.headline)
                        Text("Min: \(day.tmin, specifier: "%.1f")°F, Max: \(day.tmax, specifier: "%.1f")°F")
                        Text("Weather: \(day.weatherCondition)")
                            .foregroundColor(.secondary)
                    }
                }
                
            }
            .navigationTitle("Open-Meteo Weather")
        }
        
}

struct OMWeatherPreviews: PreviewProvider {
    static var previews: some View {
        OMWeatherView()
    }
}
