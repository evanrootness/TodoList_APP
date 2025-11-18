//
//  NutritionPieChartView.swift
//  TodoList_APP
//
//  Created by Evan Rootness on 10/19/25.
//


import SwiftUI

//// MARK: - Model
//struct FoodCategory: Identifiable {
//    let id = UUID()
//    var name: String
//    var startColor: Color
//    var endColor: Color
//}

// MARK: - Pie Chart View
struct NutritionPieChartView: View {
    @ObservedObject var model: NutritionPieChartModel
    
    // boundaries in degrees (cumulative): [0, b1, b2, ..., 360]
    // inner boundaries (1..n-1) are mutable by dragging.
    @State private var boundaries: [Double] = []
    
    // radius <-> calories mapping
//    private let minRadius: CGFloat = 1
//    private let maxRadius: CGFloat = 100
//    private let maxCalories: Double = 1500
    
//    @State private var radius: CGFloat = 110 // initial radius; will set from default calories if needed
    
    // Gesture tracking
    enum DragMode { case none, resizing, adjusting }
    @State private var dragMode: DragMode = .none
    @State private var activeBoundaryIndex: Int? = nil // index in 'boundaries' array to move (1..n-1)
    @State private var startLocation: CGPoint = .zero
    @State private var startBoundaries: [Double] = []
    
    // UX tuning
    private let edgeThreshold: CGFloat = 10      // px tolerance to detect outer edge drags
    private let minimumSliceDegrees: Double = 2   // don't allow a slice to collapse under this angle
    
    
    var body: some View {
        VStack(spacing: 0) {
//            Text("Total Calories: \(Int(caloriesFromRadius(radius)))")
            Text("Total Calories: \(Int(model.totalCalories))")
                .font(.title2)
                .bold()
            
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                
                ZStack {
                    // Draw slices
                    ForEach(model.categories.indices, id: \.self) { i in
                        let startDeg = boundaries[safe: i] ?? 0
                        let endDeg = boundaries[safe: i + 1] ?? 360
//                        let midDeg = (startDeg + endDeg) / 2
                        
                        PieSlice(startAngle: .degrees(startDeg),
                                 endAngle: .degrees(endDeg))
                        .fill(
                            RadialGradient(gradient: Gradient(colors: [model.categories[i].startColor, model.categories[i].endColor]),
                                           center: .center,
                                           startRadius: 0,
                                           endRadius: model.radius)
                        )
                        .overlay(PieSlice(startAngle: .degrees(startDeg),
                                          endAngle: .degrees(endDeg))
                            .stroke(Color.white, lineWidth: 3))
                        .frame(width: model.radius * 2, height: model.radius * 2)
                        .position(center)
                    }
                    
                    ForEach(model.categories.indices, id: \.self) { i in
                        let startDeg = boundaries[safe: i] ?? 0
                        let endDeg = boundaries[safe: i + 1] ?? 360
                        // Callout lines & labels
                        drawCallout(forIndex: i, center: center, radius: model.radius, startDeg: startDeg, endDeg: endDeg)
                    }
                    
                    // Optional: subtle circle outline to show edge area for resizing
//                    Circle()
//                        .strokeBorder(Color.black.opacity(0.9), lineWidth: 2)
//                        .frame(width: model.radius * 2, height: model.radius * 2)
//                        .position(center)
                }
                .contentShape(Rectangle()) // allow gesture anywhere in geometry
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // On first change, determine mode
                            if dragMode == .none {
                                startLocation = value.startLocation
                                // compute distance from center at start
                                let dx = startLocation.x - center.x
                                let dy = startLocation.y - center.y
                                let startDist = sqrt(dx*dx + dy*dy)
                                
                                // If near the circumference => resizing
                                if abs(startDist - model.radius) <= edgeThreshold {
                                    dragMode = .resizing
                                } else {
                                    dragMode = .adjusting
                                    // compute angle of start to find nearest boundary index
                                    let angle = angleFrom(center: center, to: startLocation) // 0..360
                                    activeBoundaryIndex = nearestBoundaryIndex(forAngle: angle)
                                    // record starting boundaries
                                    startBoundaries = boundaries
                                }
                            }
                            
                            switch dragMode {
                            case .resizing:
                                // Use current touch position's distance to center as new radius
                                let cur = value.location
                                let dx = cur.x - center.x
                                let dy = cur.y - center.y
                                let dist = sqrt(dx*dx + dy*dy)
                                //                                let clamped = clamp(dist, min: Double(minRadius), max: Double(maxRadius))
                                let clamped = min(max(dist, Double(model.minRadius)), Double(model.maxRadius))
                                withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.1)) {
                                    model.radius = CGFloat(clamped)
                                }
                            case .adjusting:
                                guard let idx = activeBoundaryIndex else { return }
                                let currentAngle = angleFrom(center: center, to: value.location)
                                // clamp between neighbors + minimum gap
                                let leftNeighbor = startBoundaries[idx - 1]
                                let rightNeighbor = startBoundaries[idx + 1]
                                let minAllowed = leftNeighbor + minimumSliceDegrees
                                let maxAllowed = rightNeighbor - minimumSliceDegrees
                                // We should convert currentAngle into an angle that preserves monotonicity relative to startBoundaries.
                                // Because angleFrom returns 0..360, we need to choose the equivalent angle nearest to startBoundaries[idx].
                                var candidate = closestEquivalentAngle(reference: startBoundaries[idx], target: currentAngle)
                                //                                candidate = clamp(candidate, min: minAllowed, max: maxAllowed)
                                candidate = min(max(candidate, minAllowed), maxAllowed)
                                
                                // Update the working boundaries (not startBoundaries) so user sees real-time change
                                var newBoundaries = startBoundaries
                                newBoundaries[idx] = candidate
                                boundaries = newBoundaries
                            case .none:
                                break
                            }
                        }
                        .onEnded { _ in
                            // stop dragging
                            dragMode = .none
                            activeBoundaryIndex = nil
                            startBoundaries = []
                            // Ensure boundaries sorted and normalized if any rounding drift
                            boundaries = normalizeBoundaries(boundaries)
                            model.updateFractions(from: boundaries)
                        }
                )
                .onAppear {
                    // initialize boundaries if needed (even spacing)
                    if boundaries.isEmpty {
                        let fractions = [0.2, 0.1, 0.3, 0.1, 0.25, 0.05]
                        boundaries = initialManualBoundaries(fractions: fractions)
//                         set a comfortable initial radius mapped from a default calorie number
                        let defaultCalories: Double = 700
                        model.radius = radiusFromCalories(defaultCalories)
                    }
                }
            }
            .frame(height: 210) // gives room for labels
            
            // Small legend-ish inline breakdown under the pie (compact)
//            HStack(spacing: 12) {
//                ForEach(0..<categories.count, id: \.self) { i in
//                    let proportion = sliceProportion(index: i)
//                    let calories = Int(caloriesFromRadius(radius) * proportion)
//                    HStack(spacing: 6) {
//                        RoundedRectangle(cornerRadius: 3)
//                            .fill(LinearGradient(gradient: Gradient(colors: [categories[i].startColor, categories[i].endColor]),
//                                                 startPoint: .leading, endPoint: .trailing))
//                            .frame(width: 20, height: 10)
//                        Text("\(categories[i].name): \(calories) cal")
//                            .font(.caption)
//                    }
//                }
//            }
//            .padding(.bottom, 8)
//            .padding(.horizontal)
            
            
        }
//        .padding()
//        .frame(maxWidth: 400, maxHeight: 200)
    }
    
    // MARK: - Drawing helpers

    /// Draw a slice label: inside if there's enough room, otherwise outside with callout
    @ViewBuilder
    func drawCallout(forIndex i: Int, center: CGPoint, radius: CGFloat, startDeg: Double, endDeg: Double) -> some View {
        let midDeg = (startDeg + endDeg) / 2
        let midRad = (midDeg - 90) * .pi / 180// offset so 0 deg at top
        let sliceProportion = sliceProportion(index: i)
        let totalCal = caloriesFromRadius(radius)
        let calForSlice = Int((totalCal * sliceProportion).rounded())
        
        // Determine if the slice is big enough for an inside label
        let sliceDegrees = endDeg - startDeg
        let minSliceDegreesForInsideLabel: Double = 0   // tweak as needed
        let minRadiusForInsideLabel: CGFloat = 70       // chart must be big enough
        let useInsideLabel = sliceDegrees >= minSliceDegreesForInsideLabel && radius >= minRadiusForInsideLabel
        
        if useInsideLabel {
            // Label inside the slice
            let labelRadius = radius * 0.58 // halfway to edge; adjust 0.4-0.6 for aesthetics
            let labelPoint = CGPoint(
                x: center.x + cos(CGFloat(midRad)) * labelRadius,
                y: center.y + sin(CGFloat(midRad)) * labelRadius
            )
            
            Text("\(model.categories[i].name)\n\(calForSlice) cal")
                .font(.caption2)
                .bold()
                .multilineTextAlignment(.center)
                .position(labelPoint)
        } else {
            // Label outside with callout line
            let edgePoint = CGPoint(
                x: center.x + cos(CGFloat(midRad)) * radius,
                y: center.y + sin(CGFloat(midRad)) * radius
            )
            let labelDistance: CGFloat = radius + 28
            let labelPoint = CGPoint(
                x: center.x + cos(CGFloat(midRad)) * labelDistance,
                y: center.y + sin(CGFloat(midRad)) * labelDistance
            )
            
            // Callout line
            Path { path in
                path.move(to: edgePoint)
                path.addLine(to: CGPoint(
                    x: center.x + cos(CGFloat(midRad)) * (radius + 12),
                    y: center.y + sin(CGFloat(midRad)) * (radius + 12)
                ))
                path.addLine(to: labelPoint)
            }
            .stroke(Color.primary.opacity(0.7), lineWidth: 0.8)
            
            // Outside label
            Text("\(model.categories[i].name)\n\(calForSlice) cal")
                .font(.caption2)
                .bold()
                .multilineTextAlignment(.center)
                .fixedSize()
                .position(labelPoint)
        }
    }

    
    // MARK: - Geometry & math
    
    /// Compute angle 0..360 where 0 is at 0 degrees (top) and increases clockwise.
    func angleFrom(center: CGPoint, to point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        // atan2 returns -π..π with 0 on x-axis. We want 0 at top.
        let radians = atan2(Double(dy), Double(dx))
        var degrees = radians * 180 / .pi // -180..180, 0 corresponds to +x axis
        // Convert so 0 at top (-90 from +x): add 90
        degrees += 90
        if degrees < 0 { degrees += 360 }
        return degrees.truncatingRemainder(dividingBy: 360)
    }
    
    /// Find nearest interior boundary index to an angle.
    /// Boundaries array length = n+1 (0..360)
    func nearestBoundaryIndex(forAngle angle: Double) -> Int {
        // ignore the fixed 0 and 360 ends when returning — but we return the index into full boundaries array
        let diffs = boundaries.enumerated().map { (idx, b) in (idx: idx, d: abs(angleBetween(a: b, b: angle))) }
        // pick index with smallest distance but not first(0) or last(n)
        let filtered = diffs.filter { $0.idx != 0 && $0.idx != boundaries.count - 1 }
        if let best = filtered.min(by: { $0.d < $1.d }) {
            return best.idx
        }
        return 1
    }
    
    /// Return smallest signed difference between two angles in degrees (a-b) mapped into -180..180 then abs
    func angleBetween(a: Double, b: Double) -> Double {
        var diff = (a - b).truncatingRemainder(dividingBy: 360)
        if diff < -180 { diff += 360 }
        if diff > 180 { diff -= 360 }
        return diff
    }
    
//    /// Convert radius -> calories
//    func caloriesFromRadius(_ r: CGFloat) -> Double {
//        let frac = Double((r - minRadius) / (maxRadius - minRadius))
//        return max(0, min(maxCalories, frac * maxCalories))
//    }
//    
//    /// Convert calories -> radius
//    func radiusFromCalories(_ c: Double) -> CGFloat {
//        let frac = CGFloat(max(0, min(maxCalories, c)) / maxCalories)
//        return minRadius + frac * (maxRadius - minRadius)
//    }
    

    /// Convert radius -> calories (inverse of nonlinear mapping)
    func caloriesFromRadius(_ r: CGFloat) -> Double {
        let frac = Double((r - model.minRadius) / (model.maxRadius - model.minRadius))
//        let c = pow(frac, 1 / model.exponent) * model.maxCalories // invert the power
        let c = pow(frac, 1 / model.exponent) * model.maxCalories // invert the power
        return max(0, min(model.maxCalories, c))
    }
//    let clampedRadius = max(minRadius, min(maxRadius, radius))
//    let frac = Double((clampedRadius - minRadius) / (maxRadius - minRadius))
//    let calories = pow(frac, exponent) * maxCalories
//    return max(0, min(maxCalories, calories))

    /// Convert calories -> radius (nonlinear)
    func radiusFromCalories(_ c: Double) -> CGFloat {
        let clamped = max(0, min(model.maxCalories, c))
        let frac = pow(clamped / model.maxCalories, model.exponent)
        return model.minRadius + CGFloat(frac) * (model.maxRadius - model.minRadius)
    }
    
    /// Initial equal-split boundaries for n slices
    func initialEqualBoundaries(equalSplitFor n: Int) -> [Double] {
        guard n > 0 else { return [0, 360] }
        let step = 360.0 / Double(n)
        var arr: [Double] = []
        for i in 0...n {
            arr.append(Double(i) * step)
        }
        return arr
    }
    
    // Initial boundaries based on manually input fractions
    func initialManualBoundaries(fractions: [Double]) -> [Double] {
        var boundaries: [Double] = [0.0]
        var currentAngle = 0.0
        
        for fraction in fractions {
            currentAngle += fraction * 360.0
            boundaries.append(currentAngle)
        }
        boundaries[boundaries.count - 1] = 360.0
        return boundaries
    }
    
    /// normalize boundaries to ensure 0..360 and increasing
    func normalizeBoundaries(_ b: [Double]) -> [Double] {
        guard b.count >= 2 else { return [0,360] }
        var out = b
        // ensure strictly increasing with min gaps
        for i in 1..<(out.count - 1) {
            out[i] = max(out[i], out[i-1] + minimumSliceDegrees)
            out[i] = min(out[i], out[i+1] - minimumSliceDegrees)
        }
        out[0] = 0
        out[out.count - 1] = 360
        return out
    }
    
    /// proportion for slice i computed from boundaries
    func sliceProportion(index i: Int) -> Double {
        let start = boundaries[safe: i] ?? 0
        let end = boundaries[safe: i + 1] ?? 360
        return max(0, (end - start) / 360.0)
    }
    
    /// Find the equivalent angle to `target` that is numerically closest to `reference`
    /// This helps avoid 0/360 wrap issues when dragging near the 0-degree boundary.
    func closestEquivalentAngle(reference: Double, target: Double) -> Double {
        // produce variants of target: target +/- 360k that lie near reference
        let candidate = target
        var best = candidate
        var bestDiff = abs(reference - candidate)
        for k in -2...2 {
            let t = target + Double(k) * 360
            let d = abs(reference - t)
            if d < bestDiff {
                bestDiff = d
                best = t
            }
        }
        // wrap back into 0..360
        var wrapped = best.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        return wrapped
    }
    
    
    func caloriesForSlice(index i: Int) -> Int {
        guard i < boundaries.count-1 else { return 0 }
        let sliceFrac = (boundaries[i+1] - boundaries[i]) / 360
        return Int((caloriesFromRadius(model.radius)) * sliceFrac)
    }
}

// MARK: - PieSlice Shape
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        p.move(to: center)
        p.addArc(center: center,
                 radius: radius,
                 startAngle: startAngle - .degrees(90),
                 endAngle: endAngle - .degrees(90),
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Safe array access
fileprivate extension Array {
    subscript(safe idx: Int) -> Element? {
        return (indices.contains(idx) ? self[idx] : nil)
    }
}

//// MARK: - Preview
//struct NutritionPieChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        NutritionPieChartView()
//            .frame(width: 640, height: 720)
//    }
//}
