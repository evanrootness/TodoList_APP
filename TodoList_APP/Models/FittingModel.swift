//
//  FittingModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 11/3/25.
//

import Foundation
import Accelerate

struct FittingModel {
    
    /// Performs simple linear regression using least squares.
    static func linearFit(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        precondition(x.count == y.count && x.count > 1, "x and y must have same length and contain at least 2 points")
        
        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        
        // Compute covariance(x, y) and variance(x)
        let numerator = zip(x, y).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let denominator = x.map { pow($0 - meanX, 2) }.reduce(0, +)
        
        let slope = numerator / denominator
        let intercept = meanY - slope * meanX
        
        return (slope, intercept)
    }

    /// Bootstraps linear fits to estimate uncertainty.
    static func bootstrapFit(
        x: [Double],
        y: [Double],
        nBoot: Int = 100
    ) -> (meanSlope: Double, meanIntercept: Double, stdSlope: Double, stdIntercept: Double) {
        precondition(x.count == y.count && x.count > 1, "x and y must have same length and contain at least 2 points")

        let n = x.count
        var slopes = [Double]()
        var intercepts = [Double]()

        for _ in 0..<nBoot {
            var xb = [Double]()
            var yb = [Double]()
            for _ in 0..<n {
                let i = Int.random(in: 0..<n)
                xb.append(x[i])
                yb.append(y[i])
            }
            let (slope, intercept) = linearFit(x: xb, y: yb)
            slopes.append(slope)
            intercepts.append(intercept)
        }

        let meanSlope = slopes.reduce(0, +) / Double(nBoot)
        let meanIntercept = intercepts.reduce(0, +) / Double(nBoot)
        
        let stdSlope = sqrt(slopes.map { pow($0 - meanSlope, 2) }.reduce(0, +) / Double(nBoot))
        let stdIntercept = sqrt(intercepts.map { pow($0 - meanIntercept, 2) }.reduce(0, +) / Double(nBoot))

        return (meanSlope, meanIntercept, stdSlope, stdIntercept)
    }
}
