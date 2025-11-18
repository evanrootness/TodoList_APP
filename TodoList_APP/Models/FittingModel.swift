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
    
    
    // any order polynomial fit
    /// Extremely fast polynomial least-squares fit using normal equations + Cholesky.
    /// Polynomial order should be small (≤ 5 recommended).
    static func polynomialFit(x: [Double], y: [Double], order: Int) -> [Double] {
        precondition(order <= 5, "This solver is optimized for small polynomials (order ≤ 5).")
        precondition(x.count == y.count, "x and y must have same length")
        precondition(x.count > order, "Not enough points")

        let n = x.count
        let m = order + 1

        // Build AᵀA (m×m) and Aᵀy (m×1)
        var ATA = Array(repeating: Array(repeating: 0.0, count: m), count: m)
        var ATy = Array(repeating: 0.0, count: m)

        for (xi, yi) in zip(x, y) {
            var powers = [Double](repeating: 0.0, count: m)
            powers[0] = 1.0
            for j in 1..<m {
                powers[j] = powers[j-1] * xi
            }

            // Update ATA and ATy
            for i in 0..<m {
                ATy[i] += powers[i] * yi
                for j in 0..<m {
                    ATA[i][j] += powers[i] * powers[j]
                }
            }
        }

        // Solve ATA * c = ATy using Cholesky (since ATA is symmetric positive definite)
        return choleskySolve(A: ATA, b: ATy)
    }

    // MARK: - Cholesky Solver
    private static func choleskySolve(A: [[Double]], b: [Double]) -> [Double] {
        let n = A.count
        var L = Array(repeating: Array(repeating: 0.0, count: n), count: n)

        // Cholesky factorization: A = L Lᵀ
        for i in 0..<n {
            for j in 0...i {
                var sum = A[i][j]
                for k in 0..<j { sum -= L[i][k] * L[j][k] }

                if i == j {
                    L[i][i] = sqrt(max(sum, 1e-12))
                } else {
                    L[i][j] = sum / L[j][j]
                }
            }
        }

        // Solve L y = b
        var y = Array(repeating: 0.0, count: n)
        for i in 0..<n {
            var sum = b[i]
            for k in 0..<i { sum -= L[i][k] * y[k] }
            y[i] = sum / L[i][i]
        }

        // Solve Lᵀ x = y
        var x = Array(repeating: 0.0, count: n)
        for i in stride(from: n-1, through: 0, by: -1) {
            var sum = y[i]
            for k in i+1..<n { sum -= L[k][i] * x[k] }
            x[i] = sum / L[i][i]
        }

        return x
    }

    
    

}
