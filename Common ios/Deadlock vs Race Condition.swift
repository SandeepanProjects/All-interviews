//
//  Deadlock vs Race Condition.swift
//  
//
//  Created by Apple on 30/11/25.
//

import Foundation

Below is a **clear, deep, iOS-specific explanation** of the difference between a **deadlock** and a **race condition**, with examples in **Swift**, **GCD (Grand Central Dispatch)**, and **multithreading concepts** that matter in iOS development.

---

# 🟦 **Deadlock vs Race Condition (iOS Multithreading)**

They are both concurrency bugs—but **their causes, symptoms, and behaviors are completely different**.

---

# 🔴 **1. Deadlock (Threads Waiting Forever)**

### **Definition**

A **deadlock** occurs when two or more threads (or queues) are **blocked waiting on each other**, causing the app to **freeze permanently**.

### **Key Characteristics**

* Threads are **stuck**, waiting forever.
* No progress is made.
* Usually easy to reproduce.
* Often causes the app to **hang** or UI to freeze.

### **Common Causes in iOS**

1. **Calling `sync` on the main queue from the main queue**
2. **Circular waiting** between serial queues
3. **Trying to lock a resource that you're already holding** (mutex lock misuse)

---

## 🔥 **Example of Deadlock in Swift (Main Queue)**

```swift
DispatchQueue.main.sync {
    print("This will never run")
}
```

Explanation:

* The **main thread** is executing this code.
* It asks the **main queue** to run a sync task.
* But the main queue is already busy executing the current code.
* So the sync task can’t run → the current code waits forever → **deadlock**.

---

## 🔥 **Example of Deadlock Using Serial Queues**

```swift
let queue = DispatchQueue(label: "serial.queue")

queue.async {
    queue.sync {   // deadlock
        print("Blocked forever")
    }
}
```

The inner sync waits for the serial queue to be free,
but the serial queue is busy running the outer async block.

---

## ⚠️ **Symptoms of Deadlock in iOS**

* App freezes
* UI stops responding
* No CPU usage spike (threads just block)
* Debugger shows threads stuck on queue operations or locks

---

# 🟢 **2. Race Condition (Non-Deterministic Behavior)**

### **Definition**

A **race condition** occurs when **multiple threads read/write shared data at the same time**, causing unpredictable or incorrect results.

### **Key Characteristics**

* Behavior is **random**, varies each run.
* Hard to reproduce.
* App may crash or show incorrect values.
* Caused by **unsynchronized access to shared state**.

---

## 🔥 **Example of Race Condition in Swift**

```swift
var counter = 0

DispatchQueue.global().async {
    counter += 1
}

DispatchQueue.global().async {
    counter += 1
}
```

Two threads may:

* read the old value at the same time (0)
* both write 1
  → final result could be **1 instead of 2**.

This is a race condition.

---

## 🔥 **Bank-Account Example (Classic Race Condition)**

```swift
var balance = 100

func withdraw(amount: Int) {
    if balance >= amount {
        balance -= amount
    }
}
```

Call from two threads:

* Thread A sees balance = 100
* Thread B also sees balance = 100
  Both withdraw 100 → balance becomes **0 or -100** depending on timing.

---

## ⚠️ **Symptoms of Race Conditions in iOS**

* Random crashes
* Inconsistent UI updates
* Wrong values in models or objects
* List items appearing in incorrect order
* “Sometimes works, sometimes doesn’t” behavior

---

# 🟧 **Deadlock vs Race Condition (Side-by-Side)**

| Feature           | **Deadlock**                                 | **Race Condition**                         |
| ----------------- | -------------------------------------------- | ------------------------------------------ |
| **Definition**    | Threads wait for each other forever          | Threads access shared data unsafely        |
| **Symptoms**      | App freezes                                  | Random wrong behavior                      |
| **Thread State**  | Blocked                                      | Running unpredictably                      |
| **Repeatability** | 100% reproducible                            | Random, timing-dependent                   |
| **Cause**         | Incorrect waiting/sync                       | No mutual exclusion (no lock, no barrier)  |
| **Fix**           | Avoid circular waits, don’t block main queue | Use locks, serial queues, barriers, actors |
| **Severity**      | Severe (app freezes)                         | Can be subtle but dangerous                |

---

# 🟩 **iOS-Specific Techniques to Prevent Both**

## 🔐 **To prevent Race Conditions**

Use one of:

### 1. **Serial Dispatch Queue**

```swift
let serialQueue = DispatchQueue(label: "safe.queue")

serialQueue.async {
    counter += 1
}
```

### 2. **NSLock / Mutex**

```swift
let lock = NSLock()

lock.lock()
counter += 1
lock.unlock()
```

### 3. **Dispatch Barriers**

```swift
let concurrentQueue = DispatchQueue(label: "q", attributes: .concurrent)

concurrentQueue.async(flags: .barrier) {
    sharedData = newValue
}
```

### 4. **Swift Actors (Swift concurrency)**

```swift
actor Counter {
    var value = 0
    func increment() { value += 1 }
}
```

Actors make shared state safe automatically.

---

## 🧩 **To prevent Deadlocks**

* **Never call `sync` on the main queue on the main thread**.
* **Avoid calling `sync` on a queue you are already inside**.
* Prefer **async** over **sync** whenever possible.
* For Swift concurrency (async/await), avoid using GCD `sync` altogether.
* Use tools like `dispatchPrecondition` to detect unsafe queue usage.

---

# 🟦 **Quick Summary**

### **Deadlock**

* Always caused by **waiting incorrectly**
* App **freezes**
* Easy to reproduce
* Example: `DispatchQueue.main.sync` on main thread

### **Race Condition**

* Caused by **unsafe read/write**
* App behaves **randomly**
* Hard to reproduce
* Example: two threads modifying a variable

---

If you want, I can also provide:

✅ diagrams showing thread behavior
✅ real-world iOS examples from UIKit / SwiftUI
✅ deadlock detector tools (Xcode instruments)
✅ race condition debugging strategies

Just tell me!

Below is a **complete, iOS-specific, practical guide** to:

# **1️⃣ Deadlock Detector Tools in Xcode / Instruments**

# **2️⃣ Race Condition Debugging Strategies**

Explained clearly with steps, tips, screenshots-style descriptions, and real-world advice.

---

# 🔵 **1️⃣ Deadlock Detection Tools in Xcode / Instruments**

Deadlocks are usually *easier to detect* than race conditions because the app freezes or threads stop making progress. Here are the best tools and techniques:

---

# 🧩 **Tool A — Xcode “Thread Sanitizer (TSAN)”**

### YES — TSAN also detects *potential deadlocks*, not just races.

### **How to enable it:**

1. Edit Scheme → **Run**
2. Go to **Diagnostics**
3. Enable **Thread Sanitizer**

TSAN detects:

* Deadlocks caused by mutexes (e.g., NSLock, pthread mutex)
* Incorrect locking order
* Recursive lock issues

### 🔥 Example TSAN warning

```
WARNING: lock-order-inversion (potential deadlock)
```

TSAN will:

* Pause the app
* Show the conflicting locks
* Display stack traces for each thread

---

# 🧩 **Tool B — Xcode Debug Navigator (Live Thread Inspector)**

You can open:

```
Xcode → Debug Navigator → threads icon
```

### Signs of deadlock:

* Threads stuck in `__psynch_mutexwait`
* Main thread waiting on `dispatch_sync`
* Several threads waiting for the same lock
* Backtraces frozen at queue operations

This is useful for run-time freeze debugging.

---

# 🧩 **Tool C — Xcode’s Main Thread Checker**

Deadlock caused by blocking the main thread?
This tool flags suspicious calls.

Enable under:

```
Edit Scheme → Diagnostics → Main Thread Checker
```

It won’t detect the deadlock *directly*,
but it warns you if you call UI API from background → a common way to cause deadlocks indirectly.

---

# 🧩 **Tool D — Instruments → Time Profiler ("Stalled Threads")**

1. Open Instruments → **Time Profiler**
2. Profile your app
3. Look for:

   * Threads stuck at the same point
   * No CPU activity
   * A serial queue waiting on itself

Time Profiler highlights “Blocked” or “Waiting” states.

---

# 🧩 **Tool E — “System Trace” Instrument**

Shows queue activity at the system level.
Great for detecting:

* Deadlocked GCD queues
* Dispatch sync loops
* Priority inversion issues

Look for:

* Dispatch queues that never transition from "Running" to "Idle"
* Circular waiting patterns

---

# 🧩 **Tool F — Debugging GCD Precondition Failures**

`dispatchPrecondition(condition:)` helps detect misuse early.

Example:

```swift
dispatchPrecondition(condition: .notOnQueue(.main))
```

If you accidentally call this function from the main queue → immediate crash in debug = easier debugging.

This prevents common deadlock scenarios.

---

---

# 🟢 **2️⃣ Race Condition Debugging Strategies**

Race conditions are **much harder** because:

* They are timing-dependent
* They may not reproduce consistently
* They often corrupt memory silently

Here are the best strategies:

---

# 🧩 **Strategy A — Enable “Thread Sanitizer (TSAN)”**

This is *the* most powerful tool for finding race conditions in iOS.

### TSAN detects:

* Race conditions (read/write or write/write)
* Data races on properties or global variables
* Improper use of user-defined locks
* Incorrect access to UI from background threads
* Bad GCD usage
* Unsafe Swift concurrency mixing

### Example TSAN output:

```
WARNING: ThreadSanitizer: data race (Swift access)
Write of size 8 at …
Previous read of size 8 at …
```

TSAN gives:

* Exact lines of code where conflict occurred
* Stack trace for each conflicting thread

This is GOLD.

---

# 🧩 **Strategy B — Turn On “Zombie Objects”**

Although not for races specifically, zombies detect:

* Overreleased / double-freed objects
* Memory corruption from race conditions

Enable:

```
Edit Scheme → Diagnostics → Enable Zombie Objects
```

Race conditions often cause invalid memory access; zombies expose this.

---

# 🧩 **Strategy C — Use Logging with Timestamps and Thread IDs**

Example:

```swift
print("[\(Date())][Thread: \(Thread.current)] Counter = \(counter)")
```

Helps detect:

* Out-of-order execution
* Unexpected thread usage
* Conflicting modifications

---

# 🧩 **Strategy D — Make Shared State Immutable When Possible**

Immutable data can’t cause races.

For example, instead of:

```swift
var array = [Int]()
```

Use:

```swift
let array = [Int]()
```

Or produce new values rather than mutating existing ones (functional style).

---

# 🧩 **Strategy E — Isolate state using Actors (Swift concurrency)**

Actors automatically serialize access.

Example:

```swift
actor Account {
    private var balance = 0
    func deposit(_ amount: Int) { balance += amount }
}
```

This *eliminates* most classic race conditions.

---

# 🧩 **Strategy F — Use Serial Dispatch Queues for Shared State**

Instead of doing:

```swift
sharedValue += 1
```

Do:

```swift
let serialQueue = DispatchQueue(label: "state.queue")

serialQueue.sync {
    sharedValue += 1
}
```

This adds safety while staying compatible with GCD.

---

# 🧩 **Strategy G — Add “debug-only” locks**

Create a lock only in `#if DEBUG` builds:

```swift
#if DEBUG
let debugLock = NSLock()
#endif

func safeAccess() {
    #if DEBUG
    debugLock.lock()
    defer { debugLock.unlock() }
    #endif

    // real code here
}
```

This allows you to detect concurrency issues *without affecting release performance*.

---

# 🧩 **Strategy H — Intentionally Stress Test with High Concurrency**

Create artificial stress:

```swift
DispatchQueue.concurrentPerform(iterations: 1000) { _ in
    sharedValue += 1
}
```

OR

Run your function in 100 simultaneous queues:

```swift
for _ in 0..<100 {
    DispatchQueue.global().async {
        testFunction()
    }
}
```

If a race exists, this often triggers it.

---

# 🟧 Deadlock vs Race Condition: Tools Summary

| Issue              | Best Tool        | Why                                  |
| ------------------ | ---------------- | ------------------------------------ |
| **Deadlock**       | Debug Navigator  | Shows blocked threads                |
|                    | Time Profiler    | Shows stalled queues                 |
|                    | Thread Sanitizer | Detects lock-order inversion         |
| **Race Condition** | Thread Sanitizer | Catches most data races at runtime   |
|                    | Zombies          | Detects memory corruption from races |
|                    | Stress testing   | Trigger timing issues                |
|                    | Actors           | Prevents races entirely              |

---

# 🟩 Want me to show…?

I can also provide:

✔ Real screenshots illustrating TSAN warnings
✔ Sample Xcode project intentionally containing a race condition
✔ A Swift sample showing how to eliminate both issues using `async/await`
✔ A cheat sheet of best concurrency practices in iOS

Just tell me!
