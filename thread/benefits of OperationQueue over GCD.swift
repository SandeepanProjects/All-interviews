//
//  benefits of OperationQueue over GCD.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

Great question — `OperationQueue` and **Grand Central Dispatch (GCD)** (`DispatchQueue`) are both tools for managing **concurrent** and **asynchronous** tasks in iOS, but they serve different purposes and offer different levels of abstraction.

Here's a detailed breakdown of the **benefits of `OperationQueue` over GCD**:

---

## ✅ 1. **Support for Dependencies Between Tasks**

### OperationQueue:

You can define dependencies between operations — i.e., tell one task to **wait for another** to finish before starting.

```swift
let op1 = BlockOperation { print("Download") }
let op2 = BlockOperation { print("Process") }
op2.addDependency(op1) // op2 runs after op1 finishes

queue.addOperations([op1, op2], waitUntilFinished: false)
```

### GCD:

❌ No built-in support for task dependencies — you'd need to manually chain tasks or use semaphores/group notifications.

---

## ✅ 2. **Cancellability**

### OperationQueue:

You can cancel individual operations or the whole queue:

```swift
operation.cancel()
queue.cancelAllOperations()
```

* `Operation` supports `isCancelled`, `isFinished`, and `isExecuting`.

### GCD:

❌ Dispatch queues **cannot cancel** blocks once they’ve been dispatched.

---

## ✅ 3. **Prioritization with `qualityOfService` (QoS)**

### OperationQueue:

You can set the **QoS** (priority) for operations or the queue:

```swift
operation.qualityOfService = .userInitiated
```

### GCD:

Also supports QoS via `DispatchQoS`, but **OperationQueue** is easier to fine-tune on a per-operation basis, especially with multiple tasks on the same queue.

---

## ✅ 4. **KVO Compliance**

### OperationQueue:

Operations are **KVO-compliant**:

* You can observe `isExecuting`, `isFinished`, `isCancelled`, etc.
* Useful for tracking state and progress in a more structured way

### GCD:

❌ GCD blocks don’t expose state — you can’t observe execution or completion directly.

---

## ✅ 5. **More Abstraction and Flexibility**

### OperationQueue:

* Supports subclassing `Operation` for complex behavior
* Easier to reuse, extend, and encapsulate logic
* Can pause/resume the queue:

```swift
queue.isSuspended = true
```

### GCD:

Lower-level, procedural. Less suited to encapsulation or reuse without custom wrappers.

---

## ✅ 6. **Thread Management is Automatic**

Both GCD and OperationQueue manage threads efficiently under the hood using **Grand Central Dispatch**, but:

* `OperationQueue` gives you **explicit control** via `maxConcurrentOperationCount`
* You can create **serial queues** just by setting that count to `1`, no need for special setup

---

## ✅ 7. **Wait Until Completion**

With `OperationQueue`, you can block the current thread until tasks finish (optional):

```swift
queue.addOperations([op1, op2], waitUntilFinished: true)
```

Not recommended for UI work, but useful for synchronous contexts like tests.

---

## ✅ Summary: Benefits of `OperationQueue` over GCD

| Feature                   | `OperationQueue` ✅ | `DispatchQueue` (GCD) ❌ |
| ------------------------- | ------------------ | ----------------------- |
| Task Dependencies         | ✅ Yes              | ❌ Manual                |
| Cancellation Support      | ✅ Yes              | ❌ No                    |
| Task State Tracking (KVO) | ✅ Yes              | ❌ No                    |
| Pause/Resume Queue        | ✅ Yes              | ❌ No                    |
| Operation Reusability     | ✅ Yes              | ❌ No                    |
| Fine-grained QoS Control  | ✅ Yes              | ⚠️ Limited              |
| Serial/Concurrent Control | ✅ Yes              | ✅ Yes                   |

---

## 🧠 When to Use `OperationQueue`?

Use `OperationQueue` when:

* You need **task dependencies**
* You need to **cancel or monitor** tasks
* You want **more structure** and **modularity**
* You're building **complex workflows**, like:

  * Image downloading & processing
  * Batch data import with progress/cancellation
  * Chain of operations with priority

---

                            
Cancelling an `Operation` in Swift is straightforward — but **how effective cancellation is** depends on **how you implement your operation**.
                            
Let’s walk through **how to cancel an operation** using `Operation` and `OperationQueue`, and how to implement it **properly**.
                            
                            ---
                            
## ✅ 1. **Calling `cancel()`**
                            
### Basic Example:
                                
```swift
let operation = BlockOperation {
    // Work here
}

operation.cancel() // This marks it as cancelled
```

* This **does NOT stop the operation automatically**.
* It **sets `isCancelled = true`**.
* You must **check** for cancellation inside your operation and exit early if it's set.
                            
                            ---
                            
## ✅ 2. **Checking `isCancelled` inside the operation**
                            
### Example with `BlockOperation`:
                                
```swift
let operation = BlockOperation {
    for i in 1...10_000 {
        if operation.isCancelled {
            print("Cancelled at iteration \(i)")
            return
        }
        // Simulate work
    }
}
```

> ⚠️ You must **periodically check `isCancelled`** in long or looped tasks.

---

## ✅ 3. **Cancelling a queue**

You can cancel **all operations in a queue**:

```swift
queue.cancelAllOperations()
```

Each operation will get its `isCancelled` flag set to `true`. Again — they must respect it to stop early.

---

## ✅ 4. **Custom `Operation` Subclass**

If you're writing a custom `Operation`, you have full control over how cancellation is handled.

```swift
class MyOperation: Operation {
    override func main() {
        if isCancelled { return }
        
        // Do some work
        for i in 0..<10000 {
            if isCancelled {
                print("Cancelled at step \(i)")
                return
            }
            // Simulate work
        }
        
        print("Completed")
    }
}
```

> `main()` must **explicitly check** `isCancelled`.

---

## ✅ 5. **Thread-Safety Notes**

* `cancel()` is **thread-safe**
* `isCancelled` is **safe to call from multiple threads**

---

## ✅ Summary: How to Cancel an Operation Properly

| Step | What You Do                              | Why                              |
| ---- | ---------------------------------------- | -------------------------------- |
| 1    | Call `operation.cancel()`                | Marks the operation as cancelled |
| 2    | Check `isCancelled` in `main()` or block | Stop work early if cancelled     |
| 3    | (Optional) `queue.cancelAllOperations()` | Cancels all tasks in a queue     |
                                                                        
                                                                        ---
                                                                        
### 🔄 Without checking `isCancelled`, cancellation is ignored.
                                                                        
