//
//  NutritionPieChartModel.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 10/21/25.
//


import SwiftUI
import Combine

class NutritionPieChartModel: ObservableObject, Identifiable {
    @Published var radius: CGFloat = 120
    let minRadius: CGFloat = 1
    let maxRadius: CGFloat = 100
    let maxCalories: Double = 1500
    let exponent: Double = 0.44

    @Published var categories: [FoodCategory]


    /// Convert radius -> calories (inverse of nonlinear mapping)
    var totalCalories: Double {
        let clampedRadius = max(minRadius, min(maxRadius, radius))
        let frac = Double((clampedRadius - minRadius) / (maxRadius - minRadius))
        let calories = pow(frac, 1 / exponent) * maxCalories
        return max(0, min(maxCalories, calories))
    }

    // Calories per slice
    var caloriesPerCategory: [String: Int] {
        var result: [String: Int] = [:]
        let totalCal = totalCalories
        for cat in categories {
            result[cat.name] = Int(totalCal * cat.fraction)
        }
        return result
    }
    
    /// Fractions are derived from the view’s boundaries — this is updated externally
    func updateFractions(from boundaries: [Double]) {
        guard boundaries.count == categories.count + 1 else { return }
        for i in 0..<categories.count {
            let sliceAngle = boundaries[i + 1] - boundaries[i]
            categories[i].fraction = max(0, sliceAngle / 360.0)
        }
        objectWillChange.send()
    }
    
    
    init(categories: [FoodCategory]) {
        self.categories = categories
    }

}

struct FoodCategory {
    let name: String
    let startColor: Color
    let endColor: Color
    var fraction: Double
}

