//
//  Float, Double, and CGFloat.swift
//  
//
//  Created by Apple on 20/12/25.
//

import Foundation

Here’s a **clear, interview-ready explanation** of `Float`, `Double`, and `CGFloat` in Swift/iOS, including **memory, precision, usage, and practical differences**.

---

# 🔹 Float vs Double vs CGFloat in Swift

| Feature              | Float                           | Double                                          | CGFloat                                                                      |
| -------------------- | ------------------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------- |
| **Size**             | 32-bit                          | 64-bit                                          | 32-bit (on 32-bit) / 64-bit (on 64-bit)                                      |
| **Precision**        | ~6 decimal digits               | ~15 decimal digits                              | Same as underlying platform (`Float` or `Double`)                            |
| **Default in Swift** | No                              | ✅ `Double` is default                           | Depends on platform (`CGFloat` adapts to device architecture)                |
| **Use Case**         | Low-precision, memory-sensitive | High-precision calculations (default for Swift) | Graphics/UI coordinates in UIKit & CoreGraphics                              |
| **Interoperability** | Less common in Swift            | Most common                                     | Required for UIKit/CoreGraphics functions like `CGRect`, `CGPoint`, `CGSize` |

---

## 1️⃣ Float

* 32-bit floating point
* ~6-7 digits precision
* Rarely used in Swift unless memory optimization is critical
* Example:

```swift
let floatValue: Float = 3.141592
```

* Use case: large arrays of floats in computation-heavy apps

---

## 2️⃣ Double

* 64-bit floating point
* ~15-16 digits precision
* **Default floating-point type in Swift**
* Preferred for most calculations
* Example:

```swift
let doubleValue: Double = 3.141592653589793
```

* Use case: math calculations, finance, physics, scientific apps

---

## 3️⃣ CGFloat

* Platform-dependent floating-point type

  * 32-bit on 32-bit devices
  * 64-bit on 64-bit devices
* Designed for **graphics frameworks**: UIKit, CoreGraphics, SwiftUI
* Example:

```swift
let point = CGPoint(x: 100.0, y: 200.0) // uses CGFloat
let width: CGFloat = 50.5
```

* Interoperability: Sometimes you need to **cast `Double` or `Float` to `CGFloat`**:

```swift
let doubleValue: Double = 10.0
let cgFloatValue = CGFloat(doubleValue)
```

* Use case: positions, sizes, coordinates, UI drawing

---

## 4️⃣ Key Differences in Practice

1. **Precision**

   * Double > Float
   * CGFloat precision depends on device

2. **Memory**

   * Float uses less memory → good for large numeric arrays
   * Double uses more memory → default in Swift

3. **UIKit / CoreGraphics**

   * Most APIs expect `CGFloat`
   * Always convert `Double`/`Float` to `CGFloat` when using graphics APIs

4. **Default Type in Swift**

   * Numeric literals default to `Double` unless specified as `Float`:

```swift
let x = 3.14   // Double
let y: Float = 3.14
```

---

## 5️⃣ Quick Tips for Interviews

* ✅ Default type for Swift floating point → **Double**
* ✅ Use **CGFloat for UI graphics**
* ✅ Use Float only if **memory optimization** matters
* ✅ Convert explicitly when needed:

```swift
let cgValue = CGFloat(doubleValue)
```

---

### One-liner Summary (Memory Aid)

> **Double for calculations, CGFloat for graphics, Float for memory-sensitive tasks.**

---

If you want, I can also make a **visual diagram showing Float, Double, CGFloat with precision and memory layout**, which is super useful for interviews.

Do you want me to make that diagram?
