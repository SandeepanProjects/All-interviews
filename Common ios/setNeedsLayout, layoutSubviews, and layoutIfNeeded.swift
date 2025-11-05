//
//  setNeedsLayout, layoutSubviews, and layoutIfNeeded.swift
//  
//
//  Created by Apple on 05/11/25.
//

import Foundation

These three methods — `setNeedsLayout`, `layoutSubviews`, and `layoutIfNeeded` — are part of **UIKit’s view layout system** in iOS. They control *when* and *how* a `UIView` updates its layout.

Let’s go through each one carefully:

---

### 🧩 1. `setNeedsLayout()`

**Purpose:** Marks the view as needing a layout update.

**What it does:**

* It tells the system, “Hey, this view’s layout is out of date — please recalculate it before the next render.”
* It **does not** immediately update the layout.
* Instead, the system will automatically call `layoutSubviews()` **on the next run loop** (before drawing happens).

**Typical use:**

```swift
myView.setNeedsLayout()
```

If you change something that affects layout (like frame, constraints, or subviews), you call this to ensure the layout updates later.

---

### 🧩 2. `layoutSubviews()`

**Purpose:** Performs the actual layout update.

**What it does:**

* This is where a `UIView` **positions and resizes** its subviews.
* UIKit automatically calls this method when layout is needed — you rarely call it yourself.
* You **override it** in custom views to implement custom layout logic.

**Example:**

```swift
override func layoutSubviews() {
    super.layoutSubviews()
    // Custom layout code
    titleLabel.frame = CGRect(x: 10, y: 10, width: bounds.width - 20, height: 30)
}
```

💡 Tip: When you use Auto Layout, you normally don’t override this — constraints handle layout automatically.

---

### 🧩 3. `layoutIfNeeded()`

**Purpose:** Forces an immediate layout update **if** one is pending.

**What it does:**

* If `setNeedsLayout()` was called earlier (marking the layout as “dirty”), this forces the system to **recalculate the layout immediately**, right now — synchronously.
* Useful when you need the view’s latest frame or constraints to be applied *before* performing an animation or measurement.

**Example:**

```swift
myView.setNeedsLayout()
myView.layoutIfNeeded()  // Forces layout update now
```

**Use case (common in animations):**

```swift
// Force layout to get current positions
view.layoutIfNeeded()

UIView.animate(withDuration: 0.3) {
    // Update constraints
    self.someViewTopConstraint.constant = 100
    // Force Auto Layout to recalculate within animation block
    self.view.layoutIfNeeded()
}
```

---

### 🧠 Summary Table

| Method             | When It Runs         | What It Does                     | Typical Use                                     |
| ------------------ | -------------------- | -------------------------------- | ----------------------------------------------- |
| `setNeedsLayout()` | Next run loop        | Marks the view as needing layout | Schedule layout update                          |
| `layoutSubviews()` | Automatically called | Actually positions subviews      | Override in custom views                        |
| `layoutIfNeeded()` | Immediately          | Forces layout update if needed   | Force layout before reading frames or animating |

---

Would you like me to show how these work together in an Auto Layout animation example?
