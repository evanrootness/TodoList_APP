//
//  ScatterViewModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 11/3/25.
//

import Foundation

// WIP
@MainActor
class ScatterViewModel: ObservableObject {
    @Published var selectedXAxis: String = "Height" {
        didSet { computeFit() }
    }
    @Published var selectedYAxis: String = "Weight" {
        didSet { computeFit() }
    }
    @Published var fit: [Double] = []
    @Published var points: [ScatterPlotView.DataPoint] = []

    func computeFit() {
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        guard xs.count > 1 else {
            fit = []
            return
        }

        let meanX = xs.reduce(0, +) / Double(xs.count)
        let meanY = ys.reduce(0, +) / Double(ys.count)

        let numerator = zip(xs, ys).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let denominator = xs.map { pow($0 - meanX, 2) }.reduce(0, +)
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX

        fit = [slope, intercept]
    }
}
