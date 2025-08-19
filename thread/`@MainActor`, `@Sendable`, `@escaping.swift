//
//  `@MainActor`, `@Sendable`, `@escaping.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Great question! These three attributes/modifiers in Swift serve very different purposes related to concurrency, thread safety, and closure behavior. Here’s a clear breakdown:

---

## 1. `@MainActor`

* **Purpose:** Marks a function, property, or type to always run on the **main thread (main actor)**.
* **Use case:** Ensures UI updates or any main-thread-only code runs safely on the main thread.
* **How it works:** Swift’s concurrency model treats the `MainActor` as a special **serial executor** tied to the main thread.

### Example:

```swift
@MainActor
func updateUI() {
    // This code runs on the main thread
}
```

* Calling `await updateUI()` from a background thread switches to the main thread before running.

---

## 2. `@Sendable`

* **Purpose:** Marks a closure as **safe to be used concurrently** — meaning it does **not capture or mutate non-thread-safe state**.
* **Use case:** Ensures closures passed between concurrent contexts (like tasks or thread pools) won’t cause race conditions.
* **How it works:** The compiler enforces that the closure only captures immutable values or thread-safe references.

### Example:

```swift
let closure: @Sendable () -> Void = {
    print("Safe for concurrency!")
}
```

* Useful in APIs like `Task { @Sendable in ... }` or `withTaskGroup` where closures run concurrently.

---

## 3. `@escaping`

* **Purpose:** Marks a closure that **may outlive the function call** it’s passed to.
* **Use case:** Used when a closure is stored, dispatched asynchronously, or otherwise escapes the immediate scope.
* **How it works:** Allows the closure to be called later, after the function returns.

### Example:

```swift
func fetchData(completion: @escaping (Data) -> Void) {
    DispatchQueue.global().async {
        let data = ... // fetch data
        completion(data) // called later, after fetchData returns
    }
}
```

* If a closure parameter is not marked `@escaping`, it must be called **before the function returns**.

---

## ⚡ Summary Table

| Attribute    | Purpose                              | When to Use                                      |
| ------------ | ------------------------------------ | ------------------------------------------------ |
| `@MainActor` | Run code on main thread (main actor) | UI updates, main-thread-only work                |
| `@Sendable`  | Closure is safe to use concurrently  | Concurrent APIs needing thread-safe closures     |
| `@escaping`  | Closure can outlive function call    | Async calls, storing closures, delayed execution |

---

If you want, I can show examples combining these or explain how they interact in real code!
