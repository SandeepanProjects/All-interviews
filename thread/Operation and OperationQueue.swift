//
//  Operation and OperationQueue.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

In Swift (iOS development), `Operation` and `OperationQueue` are part of the **Foundation framework** and are used to manage **concurrent** or **asynchronous tasks** in a structured way.

They are part of a **higher-level abstraction** over Grand Central Dispatch (GCD), giving you more control over how tasks are executed, their dependencies, cancellation, and priorities.

---

## ✅ `Operation` (formerly `NSOperation`)

An `Operation` is a single unit of work — a **task** — that can be executed either **synchronously** or **asynchronously**.

### ➤ Key Points:

* It is an **abstract class** (`Operation`), so you either:

  * Subclass it (custom `Operation`)
  * Use the built-in `BlockOperation` to wrap a closure

### ➤ Subclassing Example:

```swift
class MyOperation: Operation {
    override func main() {
        if isCancelled { return }
        print("Doing some work in MyOperation")
    }
}
```

### ➤ Using `BlockOperation`:

```swift
let blockOp = BlockOperation {
    print("Executing block operation")
}
```

---

## ✅ `OperationQueue` (formerly `NSOperationQueue`)

An `OperationQueue` is a queue that **manages a collection of operations** and executes them **concurrently or serially**, depending on configuration.

### ➤ Key Points:

* Runs operations **on background threads by default**
* Automatically manages threads for you
* Can set:

  * `maxConcurrentOperationCount` (for limiting parallelism)
  * `qualityOfService` (QoS for priority)
  * You can **cancel**, **suspend**, or **add dependencies** between operations

### ➤ Example:

```swift
let queue = OperationQueue()

let op1 = BlockOperation {
    print("Task 1")
}

let op2 = BlockOperation {
    print("Task 2")
}

// Add dependency: op2 will not start until op1 finishes
op2.addDependency(op1)

queue.addOperations([op1, op2], waitUntilFinished: false)
```

---

## ✅ Key Features of `Operation` & `OperationQueue` vs GCD

| Feature                | Operation / OperationQueue  | GCD (`DispatchQueue`) |
| ---------------------- | --------------------------- | --------------------- |
| Add dependencies       | ✅ Yes                       | ❌ No                  |
| Cancel operations      | ✅ Yes                       | ❌ No                  |
| KVO-compliant          | ✅ Yes (`isExecuting`, etc.) | ❌ No                  |
| Priorities / QoS       | ✅ Yes                       | ✅ Yes                 |
| Better control & reuse | ✅ Yes                       | ⚠️ Less control       |

---

## 🧠 Summary

* Use `Operation` for **more complex task management**, where you need:

  * Dependencies between tasks
  * Task cancellation
  * Progress tracking
  * Reusability
* Use `OperationQueue` to **run these tasks concurrently or serially**.

It's a powerful model for managing **background work** and provides more structure than raw GCD.

Would you like a real-world use case or demo project snippet showing how this might be used in an app (e.g., image downloading, parsing, etc.)?

Great — let's dive deeper into the two important properties of `OperationQueue`:
                                
## 1. `maxConcurrentOperationCount`
                            
### ✅ What is it?
                            
This property **controls how many operations** the queue is allowed to **run simultaneously**.
                            
### 📘 Default Behavior:
                                
By default, an `OperationQueue` will run operations **concurrently** and automatically decide how many can run in parallel (based on system resources, cores, etc).
                            
But with `maxConcurrentOperationCount`, **you control that limit** explicitly.
                            
                            ---
                            
### 🔧 Usage:
                                
```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 2
```
                            
This means:
                                
* At **most two operations** will run **at the same time**
* Others will **wait in the queue** until a slot is free
                            
                            ---
                            
### 🧠 Use Cases:
                                
* You are downloading multiple images and want to limit network usage:
                                
```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 3 // max 3 downloads at once
                            ```
* You want to **serialize tasks** (i.e., run one after another)? Set:
                                
```swift
queue.maxConcurrentOperationCount = 1
                            ```
                            
This makes the queue **serial**, like `DispatchQueue(serial:)`.
                            
                            ---
                            
### ⚠️ Notes:
                                
* This **does not guarantee** that the queue will always run that many — it’s the **maximum allowed**.
* Setting this to `OperationQueue.defaultMaxConcurrentOperationCount` resets it to system default.
* Setting it to `1` is useful for **thread-safe, sequential execution** (e.g., writing to file).
                            
                            ---
                            
## 2. `qualityOfService` (QoS)
                            
### ✅ What is it?
                            
QoS defines the **priority level** of operations — how **important** they are in relation to system resources (CPU, memory, battery, etc).
                            
iOS uses QoS to decide:
                                
* When and how quickly to schedule operations
* How aggressively to allocate resources
* Power efficiency based on task urgency
                            
                            ---
                            
### 🚦 Common QoS Levels:
                                
| QoS Level          | Description                                                                                            |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| `.userInteractive` | Highest priority. Immediate results needed to update UI (e.g., animations, touch responses).           |
| `.userInitiated`   | High priority. Tasks started by user that should complete soon (e.g., opening a document).             |
| `.utility`         | Medium priority. Long-running tasks that don’t need immediate results (e.g., downloading, processing). |
| `.background`      | Lowest priority. Maintenance or prefetching tasks (e.g., syncing, backups).                            |
| `.default`         | System default. Treated similarly to `.utility`.                                                       |
                            
                            ---
                            
### 🔧 Usage:
                                
```swift
let queue = OperationQueue()
queue.qualityOfService = .userInitiated
                            ```
                            
Or for individual `Operation`:
                                
```swift
let op = BlockOperation {
    // Some work
}
op.qualityOfService = .utility
```

> ⚠️ If both `Operation` and `OperationQueue` have QoS set, the operation’s QoS **wins** (i.e., overrides queue's).

---

### 🧠 Example Scenarios:

| Task                       | Recommended QoS    |
| -------------------------- | ------------------ |
| Updating UI based on touch | `.userInteractive` |
| User opens PDF document    | `.userInitiated`   |
| Background file sync       | `.background`      |
| Downloading a video        | `.utility`         |

---

### 🔄 Combining Both Properties

```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 2
queue.qualityOfService = .utility
```

This creates a queue that:

* Runs **up to 2 tasks in parallel**
* Schedules them with **medium priority**, suitable for longer-running background work
                                                            
                                                            ---
                                                            
## 🔚 Summary
                                                            
| Property                      | Purpose                                    |
| ----------------------------- | ------------------------------------------ |
| `maxConcurrentOperationCount` | Controls **how many tasks** run at once    |
| `qualityOfService`            | Controls **how important** those tasks are |
                                                            
These two are **essential tools** to tune performance and resource usage for **background operations** in your iOS app.
                                                            
                                                            
