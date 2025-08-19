//
//  Ensure Thread Safety.swift
//  
//
//  Created by Apple on 19/08/25.
//

import Foundation

**Thread safety** means that your code behaves correctly when accessed by multiple threads **at the same time**—without causing data corruption, crashes, or unexpected behavior.

In iOS development (and any concurrent programming), multiple threads can try to **read and write shared data** at once. If not handled properly, this can lead to **race conditions**, **deadlocks**, or **inconsistent state**.

---

## ✅ What Is Thread Safety?

A **thread-safe** component ensures that:

* **Shared mutable state** is protected.
* Access to resources is **synchronized**.
* The program works as expected even with **concurrent access**.

---

## 🛠️ How to Ensure Thread Safety in Swift (iOS):

Here are **common strategies**:

---

### 1. **Use Serial Queues (GCD)**

Run code on a serial `DispatchQueue` to avoid concurrent access.

```swift
let serialQueue = DispatchQueue(label: "com.myapp.serialQueue")

serialQueue.async {
    // Only one thread executes here at a time
    sharedResource.modify()
}
```

---

### 2. **Use `DispatchQueue.sync` for Reads**

```swift
private var name: String = "John"
private let queue = DispatchQueue(label: "com.myapp.nameQueue")

func getName() -> String {
    return queue.sync {
        return name
    }
}

func setName(_ newName: String) {
    queue.async {
        self.name = newName
    }
}
```

---

### 3. **Use Locks (Low-Level Option)**

```swift
let lock = NSLock()

func threadSafeMethod() {
    lock.lock()
    // critical section
    sharedData.append("new")
    lock.unlock()
}
```

* Also available: `NSRecursiveLock`, `os_unfair_lock`, `pthread_mutex`.

---

### 4. **Use Actors (Swift Concurrency)** 🧠

Introduced in Swift 5.5, **actors** ensure thread-safe access to their internal state **automatically**.

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        return value
    }
}
```

Usage:

```swift
let counter = Counter()
await counter.increment()
let value = await counter.getValue()
```

Actors make it much easier to write thread-safe code without worrying about locks or queues.

---

### 5. **Immutable Data Structures**

Make objects immutable by using `let` and value types (`struct`) wherever possible.

```swift
struct User {
    let name: String
    let age: Int
}
```

Immutable data doesn’t need synchronization since it can’t be changed.

---

### 6. **Avoid Shared Mutable State**

Pass data between threads instead of sharing it.

```swift
queue.async {
    let localCopy = self.data
    // Work with localCopy instead of self.data
}
```

---

## 🧪 Quick Checklist

| ✅ Safe Practice               | ⚠️ Risky Practice                         |
| ----------------------------- | ----------------------------------------- |
| Use serial queues             | Accessing shared vars on multiple threads |
| Use actors                    | Using global variables without sync       |
| Use immutable structures      | Modifying data from multiple threads      |
| Synchronize critical sections | Relying on thread timing                  |

---

Using **shared mutable state across threads** without proper synchronization is one of the most common causes of bugs in concurrent programming. It leads to **race conditions**, **data corruption**, and **crashes**, making your app unreliable and hard to debug.

---

## ⚠️ Risks of Using Shared Mutable State Across Threads

### 1. **Race Conditions**

When two or more threads access and modify the same data at the same time, the final outcome depends on the timing of those accesses.

```swift
var count = 0

DispatchQueue.global().async {
    count += 1
}

DispatchQueue.global().async {
    count += 1
}
```

* You might expect `count` to be 2, but it could end up being 1 or even crash—because the threads race to read, modify, and write `count`.

---

### 2. **Data Corruption**

If one thread is modifying data while another is reading or writing the same data, the state can become inconsistent.

Example: a thread writes a partially updated object while another reads it.

---

### 3. **Crashes (EXC\_BAD\_ACCESS / Segmentation Faults)**

Unsynchronized access to mutable memory can lead to memory access violations.

Example: Thread A deallocates an object while Thread B tries to access it.

---

### 4. **Deadlocks**

When multiple threads wait for each other to release resources (like locks), they can end up waiting forever.

Example:

```swift
lockA.lock()
lockB.lock()
// do work
lockB.unlock()
lockA.unlock()
```

If another thread does `lockB.lock()` → `lockA.lock()`, both could get stuck.

---

### 5. **Nondeterministic Behavior**

Code behaves differently each time it runs depending on thread timing. This makes bugs **hard to reproduce and test**.

---

### 6. **Difficult Debugging and Maintenance**

Concurrency issues often appear under specific, rare timing conditions, making them:

* Hard to trace
* Hard to fix
* Hard to trust that they’re fully resolved

---

## 🔒 Example of Unsafe vs. Safe Access

❌ **Unsafe Shared Access:**

```swift
var items: [String] = []

DispatchQueue.global().async {
    items.append("Hello") // Unsafe
}
```

✅ **Safe Access Using Serial Queue:**

```swift
let queue = DispatchQueue(label: "com.example.syncQueue")
var items: [String] = []

queue.async {
    items.append("Hello") // Safe
}
```

✅ **Safe Access Using Actor (Swift 5.5+):**

```swift
actor ItemStore {
    private var items: [String] = []

    func addItem(_ item: String) {
        items.append(item)
    }

    func getItems() -> [String] {
        return items
    }
}
```

---

## 🧠 Rule of Thumb

> **Never access shared mutable state from multiple threads without a synchronization mechanism.**

---

debugging concurrency issues in Xcode can be challenging, but Apple provides several powerful tools to help.

---

## 🛠️ **Tools in Xcode for Concurrency Debugging**

### 1. ✅ **Thread Sanitizer (TSan)**

**What it does:**

* Detects **race conditions** and **data races** at runtime.

**How to enable:**

* In Xcode:
  **Product > Scheme > Edit Scheme > Diagnostics > Enable Thread Sanitizer**

**What it catches:**

* Simultaneous read/write or write/write access to the same memory from multiple threads
* Misuse of low-level synchronization (e.g., `NSLock`, `DispatchQueue`)

**Example warning:**

> "Data race detected: variable accessed from multiple threads without synchronization"

🔍 **Thread Sanitizer is the #1 tool for catching hidden thread-safety bugs.**

---

### 2. 🧭 **Debug Navigator (⌘ + 7)**

**What it does:**

* Shows all running threads during a paused state.
* Useful for spotting **deadlocks** and identifying **blocked threads**.

**How to use:**

* When your app hangs or you suspect a deadlock, press **Pause (||)**.
* Inspect each thread’s stack trace.
* Look for threads stuck waiting on `dispatch_sync`, semaphores, or locks.

---

### 3. 🔍 **Instruments > Time Profiler + Threads View**

**Use case:**

* Analyze **thread usage** and performance impact of concurrency.
* View what code each thread is executing over time.

**Steps:**

* Open **Instruments** from Xcode.
* Choose **Time Profiler** → Run the app.
* Use the **“Call Tree” and “Threads” view** to see how concurrency is handled.

---

### 4. 🔍 **Instruments > Thread Sanitizer Instrument**

This is a GUI version of Thread Sanitizer that gives a **visual call stack** when a race is detected.

* Can trace exactly which threads were involved
* Helpful for large or complex codebases

---

### 5. 🧪 **LLDB Commands in Debugger**

Use debugger commands like:

```lldb
thread list
thread backtrace
```

To manually inspect where each thread is and whether they’re waiting on locks or semaphores.

---

## 🧪 How to **Test Thread Safety** of Your Code

Here are best practices for testing and validating thread-safe behavior:

---

### 1. **Use Thread Sanitizer (First Line of Defense)**

* Run your app with different flows, especially those using background threads, networking, or async tasks.
* Test edge cases: rapid tapping, simultaneous API calls, etc.

---

### 2. **Write Stress Tests**

In unit tests, simulate concurrent access:

```swift
func testConcurrentAccess() {
    let queue = DispatchQueue(label: "test.queue", attributes: .concurrent)
    let group = DispatchGroup()
    
    let counter = ThreadSafeCounter()

    for _ in 0..<1000 {
        group.enter()
        queue.async {
            counter.increment()
            group.leave()
        }
    }

    group.wait()
    XCTAssertEqual(counter.value, 1000)
}
```

> This kind of test helps expose race conditions and unsafe access in logic like counters, caches, or settings managers.

---

### 3. **Audit Access Patterns**

* Look for shared mutable state (`var`, `class` properties).
* Check if they're accessed on **multiple threads or queues**.
* Confirm there's **synchronization** (locks, queues, actors, etc.).

---

### 4. **Use Swift Concurrency (Actors, Task Groups, etc.)**

Prefer **actors** and structured concurrency to avoid common mistakes:

```swift
actor UserStore {
    private var users: [User] = []
    func add(_ user: User) {
        users.append(user)
    }
    func getAll() -> [User] {
        return users
    }
}
```

Actors eliminate the need for manual locking in most cases.

---

## ✅ Summary

| Tool                            | Use                                    |
| ------------------------------- | -------------------------------------- |
| **Thread Sanitizer**            | Detects race conditions during runtime |
| **Debug Navigator**             | Paused thread inspection for deadlocks |
| **Instruments > Time Profiler** | Analyze thread usage and performance   |
| **Thread Sanitizer Instrument** | Visual debugger for thread races       |
| **LLDB Commands**               | Manual thread and lock inspection      |

---

Testing thread safety:

* Run **stress tests** simulating concurrent access
* Use **Thread Sanitizer**
* Prefer **actors** or **serial queues** for safe state access

---

