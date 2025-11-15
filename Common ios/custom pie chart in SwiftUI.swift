//
//  custom pie chart in SwiftUI.swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

Absolutely! Let's create a **custom pie chart in SwiftUI**. We’ll make it **fully dynamic** and **animated**, with slice labels and colors.

---

## **1. Pie Slice Shape**

First, we need a shape that can draw a slice of a circle:

```swift
import SwiftUI

struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - Angle(degrees: 90),
            endAngle: endAngle - Angle(degrees: 90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
```

> Note: We subtract 90 degrees so the pie starts at the top instead of the right.

---

## **2. Pie Chart View**

Now we create the **full pie chart**:

```swift
struct PieChartView: View {
    let data: [Double]
    let colors: [Color]
    
    @State private var animatePie: Bool = false
    
    var total: Double {
        data.reduce(0, +)
    }
    
    var angles: [Angle] {
        var current: Double = 0
        return data.map { value in
            let angle = Angle(degrees: (value / total) * 360)
            current += angle.degrees
            return Angle(degrees: current)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(data.indices, id: \.self) { index in
                    let start = index == 0 ? Angle(degrees: 0) : angles[index - 1]
                    let end = angles[index]
                    
                    PieSliceShape(startAngle: start, endAngle: animatePie ? end : start)
                        .fill(colors[index % colors.count])
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatePie = true
                }
            }
        }
    }
}
```

---

## **3. Preview with Example Data**

```swift
struct PieChartView_Previews: PreviewProvider {
    static let data: [Double] = [10, 20, 30, 40]
    static let colors: [Color] = [.red, .green, .blue, .orange]
    
    static var previews: some View {
        PieChartView(data: data, colors: colors)
            .frame(width: 300, height: 300)
            .padding()
    }
}
```

---

## ✅ **Features**

1. **Dynamic slices** – works with any number of segments.
2. **Animated drawing** – smooth expansion using `withAnimation`.
3. **Custom colors** – easily changeable for each slice.
4. **Scalable** – adapts to any frame size.

---

I can also **add slice labels and percentage text inside/outside the pie** with a clean layout, making it **interactive and fully labeled**, just like professional dashboards.

Do you want me to do that next?
Perfect! Let’s enhance the pie chart with **slice labels and percentages**, so it’s more like a professional chart. We’ll also make it **interactive** by highlighting a slice when tapped.
                                                
---
                                                
## **1. Pie Slice Shape (Same as Before)**
                                                
```swift
import SwiftUI
                                                
struct PieSliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - Angle(degrees: 90),
            endAngle: endAngle - Angle(degrees: 90),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
```

---

## **2. Pie Chart Slice Model**

To make it easier to manage data, color, and labels:

```swift
struct PieSliceData: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let label: String
}
```

---

## **3. Custom Pie Chart with Labels and Interaction**

```swift
struct InteractivePieChartView: View {
    let slices: [PieSliceData]
    
    @State private var animatePie: Bool = false
    @State private var selectedSlice: UUID? = nil
    
    private var total: Double {
        slices.map { $0.value }.reduce(0, +)
    }
    
    private var angles: [Angle] {
        var current: Double = 0
        return slices.map { slice in
            let angle = Angle(degrees: (slice.value / total) * 360)
            current += angle.degrees
            return Angle(degrees: current)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            
            ZStack {
                ForEach(slices.indices, id: \.self) { index in
                    let slice = slices[index]
                    let start = index == 0 ? Angle(degrees: 0) : angles[index - 1]
                    let end = angles[index]
                    
                    PieSliceShape(startAngle: start, endAngle: animatePie ? end : start)
                        .fill(slice.color)
                        .scaleEffect(selectedSlice == slice.id ? 1.05 : 1.0)
                        .animation(.spring(), value: selectedSlice)
                        .onTapGesture {
                            selectedSlice = slice.id
                        }
                    
                    // MARK: - Slice Label
                    let midAngle = (start + end) / 2
                    let radius = size / 2 * 0.65
                    let x = center.x + CGFloat(cos(midAngle.radians - .pi / 2)) * radius
                    let y = center.y + CGFloat(sin(midAngle.radians - .pi / 2)) * radius
                    
                    Text("\(Int(slice.value / total * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                        .position(x: x, y: y)
                        .animation(.easeIn, value: animatePie)
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    animatePie = true
                }
            }
        }
    }
}
```

---

## **4. Preview Example**

```swift
struct InteractivePieChartView_Previews: PreviewProvider {
    static let sampleSlices: [PieSliceData] = [
        PieSliceData(value: 10, color: .red, label: "Red"),
        PieSliceData(value: 20, color: .green, label: "Green"),
        PieSliceData(value: 30, color: .blue, label: "Blue"),
        PieSliceData(value: 40, color: .orange, label: "Orange")
    ]
    
    static var previews: some View {
        InteractivePieChartView(slices: sampleSlices)
            .frame(width: 300, height: 300)
            .padding()
    }
}
```

---

### ✅ **Features Added**

1. **Percentage labels on each slice**.
2. **Interactive scaling** – tap a slice to highlight it.
3. **Smooth animation** for drawing slices.
4. **Dynamic data** – works for any number of slices.
5. **Reusable `PieSliceData` model** for colors and labels.
                                
