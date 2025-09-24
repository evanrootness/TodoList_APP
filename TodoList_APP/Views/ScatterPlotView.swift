//
//  ScatterPlotView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/7/25.
//


import SwiftUI
import Charts

struct ScatterPlotView: View {
    
    let xAxisTitle: String
    let yAxisTitle: String
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
    }
    
    let points: [DataPoint] // pass in multiple points as parameter
    
    var xMin: Double? {
        points.map { $0.x }.min()
    }
    var xMax: Double? {
        points.map { $0.x }.max()
    }
    var yMin: Double? {
        points.map { $0.y }.min()
    }
    var yMax: Double? {
        points.map { $0.y }.max()
    }
    
    var xBorder: Double? {
        if let min = xMin, let max = xMax {
            return (max - min) * 0.2
        }
        return nil
    }
    
    var yBorder: Double? {
        if let min = yMin, let max = yMax {
            return (max - min) * 0.2
        }
        return nil
    }
    
    
    
    var body: some View {
        Chart {
            ForEach(points) { point in
                PointMark(
                    x: .value("\(xAxisTitle)", point.x),
                    y: .value("\(yAxisTitle)", point.y)
                )
                .foregroundStyle(.blue)
                .symbolSize(100) // adjust point size
            }
        }
        .frame(height: 300)
        .padding()
        .chartXAxisLabel(xAxisTitle)
        .chartYAxisLabel(yAxisTitle)
        .chartXScale(domain: [xMin! - xBorder!, xMax! + xBorder!])
        .chartYScale(domain: [yMin! - yBorder!, yMax! + yBorder!])
    }
}
