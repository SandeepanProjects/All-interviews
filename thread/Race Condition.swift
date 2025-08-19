//
//  Race Condition.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

A **race condition** occurs when two or more threads **access shared data at the same time**, and the **final outcome depends on the timing** of how those threads are scheduled.

This can lead to:

* **Unexpected behavior**
* **Data corruption**
* **Crashes**
* **Inconsistent results**

---

## 🧠 Simple Example (Race Condition)

```swift
var count = 0

DispatchQueue.global().async {
    count += 1
}

DispatchQueue.global().async {
    count += 1
}
```

You might expect `count` to be `2`, but it could be `1`, `2`, or even crash, because:

* Both threads read `count` (value 0),
* Both increment it (to 1),
* Both write it back — one result overwrites the other.

---

## 🔥 Why It Happens

Because `count += 1` is **not atomic** — it's three steps:

1. Read value
2. Increment it
3. Write new value

When done by multiple threads **without synchronization**, they interfere with each other.

---

## ✅ How to Avoid Race Conditions

Here are several common and safe solutions in **Swift/iOS**:

---

### 1. **Use Serial Queues (GCD)**

Serialize access to shared data using a private queue:

```swift
let syncQueue = DispatchQueue(label: "com.example.syncQueue")
var count = 0

syncQueue.async {
    count += 1
}
```

---

### 2. **Use `DispatchQueue.sync` for Reads/Writes**

```swift
let queue = DispatchQueue(label: "com.example.data", attributes: .concurrent)
private var name: String = ""

func setName(_ newName: String) {
    queue.async(flags: .barrier) {
        name = newName
    }
}

func getName() -> String {
    queue.sync {
        return name
    }
}
```

* `barrier` ensures exclusive write access.
* Reads can happen concurrently, but not during a write.

---

### 3. **Use `NSLock`**

Low-level locking to make critical sections exclusive:

```swift
let lock = NSLock()
var count = 0

func increment() {
    lock.lock()
    count += 1
    lock.unlock()
}
```

---

### 4. **Use Actors (Swift 5.5+)**

Actors ensure **thread-safe access** to internal state.

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

// Usage
let counter = Counter()
await counter.increment()
let current = await counter.getValue()
```

Actors eliminate race conditions without manual locks or queues.

---

### 5. **Immutable Data**

Use `let` and avoid shared mutable state whenever possible.

```swift
struct User {
    let name: String
}
```

Immutable data is naturally thread-safe.

---

## ✅ Summary: How to Avoid Race Conditions

| Strategy             | Description                              |
| -------------------- | ---------------------------------------- |
| Serial DispatchQueue | Ensures only one task accesses the data  |
| Dispatch barriers    | Allow concurrent reads, exclusive writes |
| Locks (`NSLock`)     | Explicit mutual exclusion                |
| Swift Actors         | Built-in thread safety in Swift 5.5+     |
| Immutable data       | No need for synchronization              |

---

Debugging **deadlocks** and **race conditions** can be tricky because they are often **intermittent**, **non-deterministic**, and don't always crash your app. However, there are effective techniques and tools to help you detect and fix them.
                                        
                                        ---
                                        
## 🧵 How to Debug a **Race Condition**
                                        
### 1. **Enable Thread Sanitizer (Xcode)** ✅
                                        
* Go to your scheme → **Edit Scheme** → **Diagnostics**
* Enable **Thread Sanitizer**
                                        
🧪 Thread Sanitizer will detect:
                                            
* Simultaneous access to shared variables
* Data races
* Incorrect memory usage patterns
                                        
> 🚨 **Must run in Debug mode** — Thread Sanitizer slows down your app.
                                        
                                        ---
                                        
### 2. **Review Shared Mutable State**
                                        
* Look for `var` properties accessed from multiple threads.
* Check if any background queues or async tasks modify the same state.
                                        
### 3. **Isolate Problem Areas**
                                        
* Reproduce the bug with **extensive logging**, e.g., print thread identifiers or queue labels:
                                            
```swift
print("Accessing value on thread: \(Thread.current)")
```
                                        
### 4. **Add Synchronization**
                                        
* Use serial queues, locks, or actors to protect shared state.
* Check if race disappears after guarding access.
                                        
---
                                        
## 🕸️ How to Debug a **Deadlock**
                                        
### 1. **Recognize the Signs**
                                        
* App freezes or hangs indefinitely.
* UI becomes unresponsive.
* Debugger shows threads waiting on locks or queues.
                                        
### 2. **Pause Execution in Xcode**
                                        
* Run the app → When it hangs, click **Pause (||)** in the debugger.
* Look at the **thread stack traces** in the Debug Navigator (⌘ + 7).
* Look for:
                                            
* Threads stuck on `dispatch_sync`
* Threads waiting on `NSLock`, semaphores, or mutexes
                                        
### 3. **Look for Synchronous Calls on the Same Queue**
                                        
This is a common mistake:
                                            
```swift
DispatchQueue.main.sync {
    // ❌ Deadlock if already on main thread
}
```

Or:

```swift
queue.sync {
    queue.sync {
        // ❌ Nested sync on same serial queue = deadlock
    }
}
```

### 4. **Simplify and Reorder Locks**

* If you must use multiple locks, **always acquire them in the same order**.
* Use `lockA` → `lockB` consistently to avoid circular waits.

### 5. **Use Timeouts in Locks or Semaphores**

Avoid infinite waits:

```swift
if lock.lock(before: Date().addingTimeInterval(2)) {
    // do work
    lock.unlock()
} else {
    print("Potential deadlock avoided")
}
```

---

## 🧰 Tools & Techniques Summary

| Tool / Technique                   | Use Case                         |
| ---------------------------------- | -------------------------------- |
| **Thread Sanitizer**               | Detect race conditions           |
| **Debugger Pause**                 | Analyze deadlocks or app freezes |
| **Logging Threads**                | Understand concurrency behavior  |
| **Serial Queues / Locks / Actors** | Fix unsafe access to shared data |
| **Timeouts**                       | Avoid infinite lock waits        |

---

## ✅ Pro Tips

* 🧪 **Race conditions** often disappear with logging or debugger attached — don’t be fooled.
* 🧯 **Deadlocks** are usually deterministic — find the code path where threads wait on each other.
* 🧵 Use **unique queue labels** and **thread identifiers** in logs to trace issues.

---
