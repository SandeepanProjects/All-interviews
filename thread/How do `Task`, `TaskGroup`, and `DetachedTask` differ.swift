//
//  How do `Task`, `TaskGroup`, and `DetachedTask` differ.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

Great question! Swift’s concurrency model gives you several ways to run asynchronous work: `Task`, `TaskGroup`, and `DetachedTask`. Each serves a different purpose and has **different behavior** regarding **lifecycle, cancellation, and context inheritance**.

Here’s a detailed breakdown of each:

---

## ✅ 1. `Task`

### 📘 What it is:

`Task` creates a **structured** (or optionally unstructured) unit of asynchronous work. It runs concurrently and is **usually tied to a parent task or scope**, like a SwiftUI `.task {}` or inside another `async` function.

### 🔧 Syntax:

```swift
Task {
    await someAsyncWork()
}
```

* Runs immediately
* Inherits context: **priority, actor, task-local values**
* Can be **cancelled** by its parent
* Supports **structured concurrency** if used within an async context

### 📌 Example:

```swift
func loadData() async {
    Task {
        await fetchData()
    }
}
```

> In SwiftUI, `Task {}` is tied to the **view’s lifecycle** — it’s **automatically cancelled** when the view disappears.

---

## ✅ 2. `TaskGroup` / `withTaskGroup`

### 📘 What it is:

`TaskGroup` is used to **spawn and manage multiple concurrent child tasks** inside a structured block. All tasks run **in parallel**, and the parent waits for all of them to finish or throws.

### 🔧 Syntax:

```swift
func fetchAll() async throws -> [String] {
    return try await withTaskGroup(of: String.self) { group in
        for url in urls {
            group.addTask {
                return try await fetchData(from: url)
            }
        }

        var results = [String]()
        for try await result in group {
            results.append(result)
        }
        return results
    }
}
```

### ✅ Key Properties:

* Structured concurrency: tasks **bound to the group scope**
* Cancels **all children** if one throws
* Children inherit the parent’s **context**
* Great for **parallelism with aggregation**

---

## ✅ 3. `DetachedTask`

### 📘 What it is:

`DetachedTask` is used to run **unstructured** work — completely **independent of the current context**.

### 🔧 Syntax:

```swift
let task = Task.detached(priority: .background) {
    await someBackgroundWork()
}
```

### 🚨 Key Differences:

* Does **NOT inherit**:

  * **Actor context**
  * **Priority**
  * **Task-local values**
* Used when:

  * You want the task to outlive the caller
  * You need **full isolation** from the current task context
* Must **manually handle cancellation, errors**, etc.

### 📌 Example Use Case:

Running low-priority background cleanup work unrelated to UI or app state.

---

## 🧠 Summary Table

| Feature                 | `Task`                   | `TaskGroup`              | `DetachedTask`              |
| ----------------------- | ------------------------ | ------------------------ | --------------------------- |
| **Concurrency type**    | Structured (default)     | Structured               | Unstructured                |
| **Context Inheritance** | ✅ Yes (actor, priority)  | ✅ Yes (from parent task) | ❌ No                        |
| **Cancellation**        | ✅ Propagated from parent | ✅ Cancels all children   | ❌ Manual                    |
| **Use case**            | Single async task        | Parallel child tasks     | Completely independent work |
| **Error handling**      | try/await inside block   | Errors cancel group      | Must handle manually        |

---

## ✅ When to Use Each

* **Use `Task {}`**:

  * For UI-related async work in SwiftUI
  * When launching async tasks in structured scopes
* **Use `TaskGroup`**:

  * When doing **many parallel operations** and aggregating results
* **Use `DetachedTask`**:

  * When you want a task that’s **fully isolated**
  * For background work unrelated to caller (e.g., analytics, cleanup)

---

Would you like a real app example showing when you might use all three in the same project (like a SwiftUI view + background sync task + batch image loader)?
