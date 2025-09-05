//
//  SetupView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 8/23/25.
//


// Eventually this setup view might contain a number of other set up items (setting up spotify, access to screen time, etc.)
// So basically it might be the intial start up page someday

import SwiftUI



struct SetupView: View {
    @ObservedObject var weatherVM: WeatherViewModel

    var body: some View {
        VStack {
            Text("Location needed for weather data")
            TextField("Town, State", text: $weatherVM.location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Continue") {
                weatherVM.fetchLastWeekWeather()
            }
            .padding()
        }
        .frame(width: 300, height: 200)
    }
}
