//
//  Custom Charts in SwiftUI.swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

Absolutely! In **SwiftUI**, you can create **custom charts** by combining shapes, paths, and stacks to create visualizations beyond the built-in `Chart` framework. I’ll guide you through a few approaches with examples, starting from simple bar charts to line charts and more advanced custom shapes.

---

## **1. Simple Bar Chart**

You can make a bar chart by using `Rectangle` views and `ForEach`.

```swift
import SwiftUI

struct BarChartView: View {
    let data: [Double] = [150, 75, 200, 125, 100]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(data.indices, id: \.self) { index in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 30, height: CGFloat(data[index]))
            }
        }
        .padding()
        .frame(height: 250)
    }
}

struct BarChartView_Previews: PreviewProvider {
    static var previews: some View {
        BarChartView()
    }
}
```

✅ This is straightforward, and you can make it dynamic by normalizing the data to fit your view height.

---

## **2. Line Chart Using `Path`**

For a line chart, you can draw custom paths:

```swift
import SwiftUI

struct LineChartView: View {
    let data: [Double] = [50, 100, 75, 125, 200, 150]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                let stepX = width / CGFloat(data.count - 1)
                let maxY = data.max() ?? 1
                
                path.move(to: CGPoint(x: 0, y: height - CGFloat(data[0]/maxY) * height))
                
                for i in 1..<data.count {
                    let x = CGFloat(i) * stepX
                    let y = height - CGFloat(data[i]/maxY) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
        .padding()
        .frame(height: 200)
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView()
    }
}
```

This allows full customization of the line color, width, and even adding gradients or animations.

---

## **3. Area Chart**

You can fill the area under the line with a gradient:

```swift
Path { path in
    // ... same as line chart
}
.fill(
    LinearGradient(
        gradient: Gradient(colors: [Color.red.opacity(0.3), Color.clear]),
        startPoint: .top,
        endPoint: .bottom
    )
)
```

---

## **4. Advanced: Using `Shape` Protocol**

For reusable custom charts, you can make your own `Shape`:

```swift
struct LineChartShape: Shape {
    let data: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }
        
        let stepX = rect.width / CGFloat(data.count - 1)
        let maxY = data.max() ?? 1
        
        path.move(to: CGPoint(x: 0, y: rect.height - CGFloat(data[0]/maxY) * rect.height))
        
        for i in 1..<data.count {
            let x = CGFloat(i) * stepX
            let y = rect.height - CGFloat(data[i]/maxY) * rect.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}
```

And then use it like:

```swift
LineChartShape(data: [10, 50, 30, 80])
    .stroke(Color.green, lineWidth: 2)
    .frame(height: 200)
    .padding()
```

This makes your chart **reusable** and composable in other views.

---

## **5. Tips for Custom Charts in SwiftUI**

* Normalize your data to the view height/width for consistency.
* Combine `ZStack` with `Path` for adding axes, grid lines, or labels.
* Use `ForEach` with shapes for discrete charts like bar or pie charts.
* Add animations with `.animation(.easeInOut, value: data)` for smooth updates.

---

If you want, I can make a **fully featured SwiftUI chart** that includes **axes, grid lines, labels, and animations**, all completely custom without using `Charts` framework. It would look professional and fully reusable.

Do you want me to do that?

Perfect! Let’s build a **fully custom SwiftUI chart** step by step. This chart will have:
                        
* **Line chart** with animation
* **Axes** with labels
* **Grid lines**
* **Reusable Shape**
* **Dynamic data support**
                    
Here’s the complete implementation:
                        
```swift
import SwiftUI
                    
// MARK: - Reusable Line Chart Shape
struct LineChartShape: Shape {
    let data: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }
        
        let maxY = data.max() ?? 1
        let minY = data.min() ?? 0
        let rangeY = maxY - minY == 0 ? 1 : maxY - minY
        let stepX = rect.width / CGFloat(data.count - 1)
        
        let startY = rect.height - CGFloat((data[0] - minY) / rangeY) * rect.height
        path.move(to: CGPoint(x: 0, y: startY))
        
        for i in 1..<data.count {
            let x = CGFloat(i) * stepX
            let y = rect.height - CGFloat((data[i] - minY) / rangeY) * rect.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Custom Line Chart View
struct CustomLineChartView: View {
    let data: [Double]
    let yAxisSteps: Int = 5
    
    @State private var animateLine: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxY = data.max() ?? 1
            let minY = data.min() ?? 0
            let rangeY = maxY - minY == 0 ? 1 : maxY - minY
            
            ZStack {
                // MARK: - Grid Lines
                VStack(spacing: 0) {
                    ForEach(0..<yAxisSteps + 1, id: \.self) { step in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .offset(y: CGFloat(step) * height / CGFloat(yAxisSteps))
                        Spacer()
                    }
                }
                
                // MARK: - Line Chart
                LineChartShape(data: data)
                    .trim(from: 0, to: animateLine)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .animation(.easeOut(duration: 1.2), value: animateLine)
                
                // MARK: - Area Fill
                LineChartShape(data: data)
                    .trim(from: 0, to: animateLine)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .animation(.easeOut(duration: 1.2), value: animateLine)
                
                // MARK: - Y-Axis Labels
                VStack {
                    ForEach(0..<yAxisSteps + 1, id: \.self) { step in
                        let yValue = maxY - (Double(step) * rangeY / Double(yAxisSteps))
                        Text(String(format: "%.0f", yValue))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(height: height / CGFloat(yAxisSteps), alignment: .top)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .onAppear {
            animateLine = 1.0
        }
    }
}

// MARK: - Preview
struct CustomLineChartView_Previews: PreviewProvider {
    static let sampleData: [Double] = [50, 120, 90, 180, 150, 200, 170, 220]
    
    static var previews: some View {
        CustomLineChartView(data: sampleData)
            .frame(height: 300)
    }
}
```

---

### ✅ **Features in This Chart**

1. **Dynamic data scaling** – works with any min/max values.
2. **Animated line drawing** – `.trim(from: 0, to: animateLine)` + `.animation`.
3. **Area under the line** – gradient fill for visual appeal.
4. **Y-axis grid lines & labels** – configurable number of steps.
5. **Reusable `LineChartShape`** – easy to integrate in other charts.
                                                
---
