//
//  Structured concurrency.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

**Structured concurrency** is a modern approach to **concurrent programming** that helps you manage the **lifecycle, scope, and relationships** between asynchronous tasks in a **safe and predictable way**.

It was introduced in Swift with **Swift Concurrency** (`async/await`, `Task`, etc.) starting in **Swift 5.5** (iOS 15+).

---

## ✅ What Is Structured Concurrency?

### 📘 Definition:

Structured concurrency means that **child tasks are bound to the lifetime of their parent scope**. This structure:

* Ensures that **no task is left running unexpectedly**
* Makes async code **easier to reason about**, **debug**, and **clean up**
* Automatically **waits for child tasks to complete**, unless explicitly cancelled

---

## 🔍 Traditional Concurrency vs. Structured Concurrency

### ❌ Traditional (Unstructured):

```swift
func loadData() {
    DispatchQueue.global().async {
        // Work happens here
    }
    // Function returns, task keeps running
}
```

* The async task runs independently.
* You have **no control** over when it finishes or if it's cancelled.

---

### ✅ Structured Concurrency:

```swift
func loadData() async {
    async let user = fetchUser()
    async let posts = fetchPosts()

    let result = try await (user, posts)
}
```

* The tasks are **scoped** to the `loadData()` function.
* If `loadData()` is cancelled or throws, the `fetchUser()` and `fetchPosts()` tasks are **automatically cancelled**.
* They **don’t leak outside** the function.

---

## ✅ Benefits of Structured Concurrency

| Feature                       | Description                                               |
| ----------------------------- | --------------------------------------------------------- |
| 🔒 Safer concurrency          | Tasks are tied to scope; avoids "detached" tasks          |
| 🧼 Automatic cleanup          | Cancels child tasks if parent is cancelled or exits early |
| 📚 More readable code         | Looks like regular code (with `await`)                    |
| 🧪 Easier testing & debugging | All async tasks complete within their scopes              |
| 📦 Built into the language    | Fully integrated into Swift’s `async/await` system        |

---

## 🧱 Key Concepts

### 1. `async let`

Creates a **child task** within a function:

```swift
async let image = loadImage()
let result = try await image
```

* This is structured concurrency — the child task's lifetime is tied to the scope.

---

### 2. `Task` Groups

Used for **parallelism and task coordination** within a structured scope.

```swift
func fetchMultiple() async throws -> [String] {
    return try await withThrowingTaskGroup(of: String.self) { group in
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

* All child tasks are **scoped to the `withThrowingTaskGroup` block**
* They are **automatically cancelled** if one throws or the block exits early

---

### 3. `Task` (Unstructured — Use with Care)

```swift
Task {
    await doSomeWork()
}
```

* This is **not structured** by default.
* It creates a **detached task** unless scoped explicitly (e.g., inside a view model or actor).
* Can lead to **leaky tasks** if you don’t manage them carefully.

---

## ✅ Structured Concurrency and `View` Hierarchies (SwiftUI)

In SwiftUI, structured concurrency works naturally:

```swift
.task {
    await loadData()
}
```

* The `Task` here is **structured** — tied to the view lifecycle.
* If the view disappears, SwiftUI cancels the task automatically.

---

## 🚨 What Happens on Cancellation?

With structured concurrency:

* If a parent task is cancelled:

  * All its child tasks are **automatically cancelled**
* If a child task throws an error in a task group:

  * Other child tasks are cancelled
  * Error is propagated

This ensures **predictable and safe cleanup** — unlike traditional GCD-based concurrency.

---

## ✅ Summary

| Concept                    | Description                                     |
| -------------------------- | ----------------------------------------------- |
| **Structured Concurrency** | Tasks follow a strict scope/lifecycle model     |
| **Key benefits**           | Safety, cleanup, predictability, readability    |
| **`async let`**            | Lightweight parallelism within a function       |
| **`TaskGroup`**            | Manage multiple child tasks with error handling |
| **Automatic cancellation** | Parent cancels → children are cancelled         |

---

## 🧠 Mental Model

Think of structured concurrency like nesting blocks in code:

* Tasks are **children** of the scope they’re created in
* When the **parent ends**, all **children are cleaned up**

---

Would you like a real-world example — like fetching data in parallel with task groups and error handling?
