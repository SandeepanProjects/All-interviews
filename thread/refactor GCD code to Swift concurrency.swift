//
//  refactor GCD code to Swift concurrency.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Great question! Refactoring legacy **Grand Central Dispatch (GCD)** code to modern **Swift concurrency** (async/await, actors, structured concurrency) can make your code easier to read, maintain, and less error-prone.

---

## 🧰 Common GCD Patterns & How to Refactor Them

---

### 1. **Dispatching to Background Thread**

**Legacy GCD:**

```swift
DispatchQueue.global().async {
    let data = fetchData()
    DispatchQueue.main.async {
        updateUI(with: data)
    }
}
```

**Refactored with Swift concurrency:**

```swift
func loadData() async {
    let data = await fetchData()
    await MainActor.run {
        updateUI(with: data)
    }
}
```

* `fetchData()` becomes `async` function.
* Use `await MainActor.run {}` to update UI on the main thread.

---

### 2. **Completion Handlers → Async/Await**

**Legacy GCD with completion handler:**

```swift
func fetchData(completion: @escaping (Data) -> Void) {
    DispatchQueue.global().async {
        let data = // long running work
        DispatchQueue.main.async {
            completion(data)
        }
    }
}
```

**Refactor to async function:**

```swift
func fetchData() async -> Data {
    // Perform long running work asynchronously
}
```

Then you can call it with `await`:

```swift
let data = await fetchData()
```

---

### 3. **Serial Queues → Actors**

**Legacy serial queue for thread safety:**

```swift
class ThreadSafeCounter {
    private var value = 0
    private let queue = DispatchQueue(label: "counter.queue")

    func increment() {
        queue.sync {
            value += 1
        }
    }

    func getValue() -> Int {
        queue.sync {
            value
        }
    }
}
```

**Refactor using Swift actor:**

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        value
    }
}
```

Actors serialize access automatically, eliminating manual queue management.

---

### 4. **DispatchGroup → TaskGroup**

**Legacy:**

```swift
let group = DispatchGroup()
var results: [ResultType] = []

for item in items {
    group.enter()
    process(item) { result in
        results.append(result)
        group.leave()
    }
}

group.notify(queue: .main) {
    updateUI(with: results)
}
```

**Refactor with Swift concurrency:**

```swift
func processAll(items: [Item]) async -> [ResultType] {
    await withTaskGroup(of: ResultType.self) { group in
        for item in items {
            group.addTask {
                await process(item)
            }
        }
        
        var results: [ResultType] = []
        for await result in group {
            results.append(result)
        }
        return results
    }
}
```

---

### 5. **Handling Cancellation**

Swift concurrency has built-in **cancellation** support, which you can’t get easily with GCD.

Example:

```swift
func fetchData() async throws -> Data {
    try Task.checkCancellation()
    // fetch data
}
```

---

## 🧩 Summary: What to Replace

| GCD Construct                  | Swift Concurrency Equivalent             |
| ------------------------------ | ---------------------------------------- |
| `DispatchQueue.global().async` | `async` functions + `Task {}`            |
| `DispatchQueue.main.async`     | `await MainActor.run {}` or `@MainActor` |
| Serial DispatchQueue           | `actor`                                  |
| `DispatchGroup`                | `withTaskGroup`                          |
| Completion Handlers            | `async/await` functions                  |

---

## Tips for Smooth Refactor

* Start by **converting completion handlers to async functions**.
* Replace **explicit queue calls** with `async/await` and actors.
* Use **`@MainActor`** to mark UI code.
* Gradually migrate code to Swift concurrency for better safety and clarity.

---

Would you like me to help refactor a specific snippet of your legacy GCD code?
