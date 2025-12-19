//
//  FPS (Frames Per Second).swift
//  
//
//  Created by Apple on 16/12/25.
//

import Foundation

### FPS (Frames Per Second) and Its Significance in **iOS / SwiftUI**

**FPS (Frames Per Second)** measures how many times per second the screen is updated with a new image (frame). In iOS development, FPS is a key indicator of **UI performance and smoothness**.

---

## 1. Why FPS Matters in iOS

Most iOS devices use:

* **60 FPS** → Standard smooth animations
* **120 FPS** → ProMotion displays (iPhone Pro models)

If your app drops below these targets:

* Animations feel **janky or laggy**
* Scrolling becomes **choppy**
* User experience degrades significantly

### Human perception

* **60 FPS** → Smooth
* **30–45 FPS** → Noticeable stutter
* **<30 FPS** → Poor, unresponsive feel

---

## 2. FPS in SwiftUI

SwiftUI is **declarative**, meaning:

* The system recalculates and redraws views when state changes
* Excessive or expensive updates can reduce FPS

### Common FPS killers in SwiftUI

* Frequent `@State` updates (especially in loops/timers)
* Heavy work in `body`
* Large view hierarchies
* Unoptimized animations
* Layout recalculations (e.g., GeometryReader misuse)
* Expensive drawing in `Canvas`

---

## 3. FPS Targets for SwiftUI Apps

| Scenario                  | Target FPS                |
| ------------------------- | ------------------------- |
| Normal UI                 | 60 FPS                    |
| ProMotion devices         | 120 FPS                   |
| Animations                | Match device refresh rate |
| Games / real-time visuals | Max possible              |

---

## 4. Measuring FPS in SwiftUI

### A. Xcode Instruments (Recommended)

Use **Instruments → Core Animation**:

* FPS graph
* Frame drops
* Offscreen rendering
* GPU vs CPU load

### B. Debug FPS Counter (Simple)

You can create a basic FPS monitor using `CADisplayLink`:

```swift
class FPSCounter: ObservableObject {
    @Published var fps: Int = 0

    private var link: CADisplayLink?
    private var lastTime: CFTimeInterval = 0
    private var frames: Int = 0

    func start() {
        link = CADisplayLink(target: self, selector: #selector(tick))
        link?.add(to: .main, forMode: .common)
    }

    @objc private func tick(link: CADisplayLink) {
        if lastTime == 0 {
            lastTime = link.timestamp
            return
        }

        frames += 1
        let delta = link.timestamp - lastTime

        if delta >= 1 {
            fps = frames
            frames = 0
            lastTime = link.timestamp
        }
    }
}
```

Use in SwiftUI:

```swift
struct ContentView: View {
    @StateObject private var fpsCounter = FPSCounter()

    var body: some View {
        Text("FPS: \(fpsCounter.fps)")
            .onAppear { fpsCounter.start() }
    }
}
```

---

## 5. Improving FPS in SwiftUI

### Best Practices

✅ Minimize state changes
✅ Use `EquatableView` to prevent unnecessary redraws
✅ Prefer `LazyVStack` / `LazyHStack` for lists
✅ Avoid heavy logic in `body`
✅ Use `.drawingGroup()` sparingly
✅ Reduce overdraw and transparency
✅ Use `.animation(_:value:)` instead of implicit animations

### Example: Bad vs Good

❌ **Bad**

```swift
var body: some View {
    Text(expensiveCalculation())
}
```

✅ **Good**

```swift
@State private var cachedText = ""

var body: some View {
    Text(cachedText)
        .onAppear {
            cachedText = expensiveCalculation()
        }
}
```

---

## 6. FPS and SwiftUI Animations

* SwiftUI animations aim to sync with display refresh rate
* Dropped frames cause animations to **skip**
* Prefer:

  * `.spring()` (system-optimized)
  * `.easeInOut(duration:)`

Avoid long-running synchronous work during animations.

---

## 7. Key Takeaways

* FPS measures **UI smoothness**
* Aim for **60–120 FPS**
* SwiftUI can drop FPS if views update too often
* Use **Instruments** to diagnose issues
* Optimize state updates and view rendering

---

If you want, I can:

* Explain **FPS vs Refresh Rate**
* Show **real-world SwiftUI FPS optimizations**
* Compare **SwiftUI vs UIKit FPS behavior**
* Help you debug FPS drops in your app 🚀
