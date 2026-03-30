//
//  State management.swift
//  
//
//  Created by Apple on 30/03/26.
//

import Foundation

State management in **SwiftUI** is where even experienced developers slip up. Most bugs, UI glitches, and performance issues come from *misunderstanding how state flows*.

Let’s break down the **most common mistakes (and how to fix them)**—this is exactly what interviewers look for 👇

---

# 🔴 1. Using the Wrong Property Wrapper

### ❌ Mistake:

Using `@State`, `@ObservedObject`, `@StateObject`, or `@EnvironmentObject` incorrectly.

```swift
@ObservedObject var viewModel = MyViewModel() // ❌ WRONG
```

### 💥 Problem:

* ViewModel gets recreated on every redraw → data resets

### ✅ Fix:

```swift
@StateObject var viewModel = MyViewModel() // ✅ correct
```

### 🧠 Rule:

* `@StateObject` → **owns lifecycle**
* `@ObservedObject` → **receives dependency**
* `@State` → **simple local value**
* `@EnvironmentObject` → **global/shared**

---

# 🔴 2. Putting Business Logic Inside Views

### ❌ Mistake:

```swift
Button("Login") {
    if username == "admin" && password == "123" {
        // logic here ❌
    }
}
```

### 💥 Problem:

* Breaks separation of concerns
* Hard to test and maintain

### ✅ Fix:

Move logic to ViewModel:

```swift
viewModel.login()
```

### 🧠 Insight:

SwiftUI views should be **dumb renderers**, not logic holders.

---

# 🔴 3. Overusing @State (God State Problem)

### ❌ Mistake:

```swift
@State var username = ""
@State var password = ""
@State var isLoading = false
@State var errorMessage = ""
```

### 💥 Problem:

* Scattered state
* Hard to scale

### ✅ Fix:

Use a ViewModel:

```swift
@StateObject var viewModel = LoginViewModel()
```

---

# 🔴 4. Not Understanding View Lifecycle (Re-rendering)

### ❌ Mistake:

Assuming SwiftUI views behave like UIKit (created once)

### 💥 Problem:

* Unexpected resets
* Performance issues

### 🧠 Reality:

SwiftUI views are **recreated frequently**

### ✅ Fix:

* Store persistent data in `@StateObject`
* Avoid side effects in `body`

---

# 🔴 5. Side Effects Inside `body`

### ❌ Mistake:

```swift
var body: some View {
    fetchData() // ❌ VERY BAD
    return Text("Hello")
}
```

### 💥 Problem:

* Called multiple times → API spam

### ✅ Fix:

```swift
.task {
    await viewModel.fetchData()
}
```

---

# 🔴 6. Incorrect Use of @EnvironmentObject

### ❌ Mistake:

* Using it everywhere like global variables

### 💥 Problem:

* Hidden dependencies
* Hard to debug crashes

### ✅ Fix:

* Use only for truly global state (theme, auth)

---

# 🔴 7. Two-Way Binding Misuse

### ❌ Mistake:

Passing full control of state to child views unnecessarily

```swift
ChildView(value: $parentState)
```

### 💥 Problem:

* Tight coupling
* Unexpected updates

### ✅ Fix:

* Pass value instead of binding unless needed
* Use binding only for editable state

---

# 🔴 8. Ignoring Threading (Main Thread Updates)

### ❌ Mistake:

Updating UI state from background thread

```swift
DispatchQueue.global().async {
    self.data = result // ❌ crash risk
}
```

### ✅ Fix:

```swift
@MainActor
class ViewModel: ObservableObject { }
```

or

```swift
await MainActor.run {
    self.data = result
}
```

---

# 🔴 9. Not Using Immutable State Properly

### ❌ Mistake:

Mutating deeply nested state unpredictably

### 💥 Problem:

* UI doesn’t update correctly

### ✅ Fix:

Prefer value types:

```swift
struct ViewState {
    var items: [Item]
}
```

---

# 🔴 10. Overusing EnvironmentObject Instead of Dependency Injection

### ❌ Mistake:

Using `@EnvironmentObject` for everything

### 💥 Problem:

* Hidden architecture
* Poor testability

### ✅ Fix:

* Pass dependencies explicitly via init

---

# 🔴 11. Multiple Sources of Truth

### ❌ Mistake:

```swift
@State var name = ""
@ObservedObject var viewModel: VM // also has name
```

### 💥 Problem:

* UI inconsistencies

### ✅ Fix:

👉 **Single source of truth**

* Either View OR ViewModel owns it

---

# 🔴 12. Not Resetting State Properly

### ❌ Mistake:

State persists unexpectedly when navigating

### 💥 Problem:

* Old data appears in new screens

### ✅ Fix:

* Reinitialize ViewModel when needed
* Use `id()` modifier if required

---

# 🔥 Senior-Level Insight

The biggest mindset shift:

👉 SwiftUI is **state-driven UI**, not event-driven like UIKit.

---

# 🧠 Golden Rules

1. **Single source of truth**
2. **Unidirectional data flow**
3. **Views are pure functions of state**
4. **State drives UI, not vice versa**

---

# 🚀 Real Interview One-Liner

> “Most SwiftUI bugs come from incorrect ownership of state and misunderstanding view lifecycle.”

---

If you want, I can go deeper into:

* ✅ Clean Architecture + SwiftUI state management (production-level)
* ✅ MVVM + async/await + state handling
* ✅ Real-world scalable folder structure (very useful for interviews)

