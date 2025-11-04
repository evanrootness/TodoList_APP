//
//  ScatterPlotView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 9/7/25.
//


import SwiftUI
import Charts

struct ScatterPlotView: View {
    
//    let scatterSymbol = Circle().stroke(lineWidth: 2)
//    let scatterSymbol: some SymbolShape = .circle
    
    let xAxisTitle: String
    let yAxisTitle: String
    let showFit: Bool
    let fit: [Double]
    let points: [DataPoint] // pass in multiple points as parameter
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
    }
    

    var xMin: Double { points.map(\.x).min() ?? 0 }
    var xMax: Double { points.map(\.x).max() ?? 1 }
    var yMin: Double { points.map(\.y).min() ?? 0 }
    var yMax: Double { points.map(\.y).max() ?? 1 }
    
    var xBorderSpace: Double { (xMax - xMin) * 0.1 }
    var yBorderSpace: Double { (yMax - yMin) * 0.1 }

    var xBorderMin: Double { xMin - xBorderSpace }
    var xBorderMax: Double { xMax + xBorderSpace }
    var yBorderMin: Double { yMin - yBorderSpace }
    var yBorderMax: Double { yMax + yBorderSpace }

    
    var linePoints: [(x: Double, y: Double)] {
        guard fit.count >= 2 else { return [] }
        let slope = fit[0]
        let intercept = fit[1]
        
        return [
            (x: xBorderMin, y: slope * xBorderMin + intercept),
            (x: xBorderMax, y: slope * xBorderMax + intercept)
        ]
    }
    
    
    
    var body: some View {
        if points.isEmpty {
            Text("No valid data to display")
                .foregroundStyle(.secondary)
                .frame(height: 300)
        } else {
            Chart {
                ForEach(points) { point in
                    PointMark(
                        x: .value("\(xAxisTitle)", point.x),
                        y: .value("\(yAxisTitle)", point.y)
                    )
//                    .symbol(Circle())
                    .symbolSize(100)
                    .foregroundStyle(Color(red: 0.9, green: 0.15, blue: 0.45))
                    .opacity(0.65)
                }
                
                if showFit, linePoints.count == 2 {
                    ForEach(linePoints, id: \.x) { point in
                        LineMark(
                            x: .value(xAxisTitle, point.x),
                            y: .value(yAxisTitle, point.y)
                            )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
            }
            .frame(height: 300)
            .padding()
            .chartXAxisLabel(xAxisTitle)
            .chartYAxisLabel(yAxisTitle)
            .chartXScale(domain: [xBorderMin, xBorderMax])
            .chartYScale(domain: [yBorderMin, yBorderMax])
        }
    }
}
