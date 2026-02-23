//
//  Deadlock scenario explanation.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

Excellent — this is **senior/staff-level concurrency knowledge**.

We’ll cover:

1. Deadlock in **Modern Swift Concurrency**
2. How Swift avoids many classical deadlocks
3. Priority Inversion (real production issue)
4. How iOS solves it internally
5. How YOU prevent it in modern Swift

---

# 🔥 Part 1: Deadlock in Modern Swift Concurrency

With **GCD**, deadlocks usually happen because of:

* `sync` calls
* Multiple locks
* Serial queues waiting on themselves

With **Swift Concurrency (async/await + actors)**, the model changes.

---

## ✅ Why Modern Swift Prevents Many Deadlocks

### 1️⃣ No Explicit Locks (Usually)

Actors isolate state:

```swift
actor Counter {
    private var value = 0
    
    func increment() {
        value += 1
    }
}
```

No `NSLock`
No `DispatchSemaphore`
No manual blocking

👉 You eliminate circular wait caused by locks.

---

## 🚨 But Deadlocks Can Still Happen

### Case 1: Actor Calling Itself with await Improperly

```swift
actor Example {
    
    func outer() async {
        await inner()
    }
    
    func inner() async {
        await outer() // ❌ Infinite recursion / logical deadlock
    }
}
```

This creates suspension cycle.

---

### Case 2: Blocking Inside Async Code (Very Dangerous)

```swift
actor Example {
    func doWork() {
        DispatchQueue.main.sync {   // ❌ Blocking
            print("Deadlock risk")
        }
    }
}
```

Never mix blocking sync calls inside async world.

---

# ⚠️ Golden Rule in Modern Concurrency

> Do not block threads. Suspend instead.

Blocking = `sync`, `wait()`, `sleep()`
Suspending = `await`

Swift concurrency is designed around **cooperative suspension**, not blocking.

---

# 🔥 Actor Reentrancy (Important Concept)

Actors are **reentrant by default**.

Example:

```swift
actor BankAccount {
    var balance = 100
    
    func withdraw(_ amount: Int) async {
        if balance >= amount {
            await Task.sleep(1_000_000_000)
            balance -= amount
        }
    }
}
```

During `await`, actor can process another request.

This avoids deadlock…
BUT introduces race-like logical bugs.

This is not deadlock — it's reentrancy issue.

Senior engineers must understand this.

---

# 🔥 Part 2: Priority Inversion

This is a **real production issue in iOS apps**.

---

## 🧠 What is Priority Inversion?

When:

* High-priority thread waits for a resource
* Low-priority thread holds it
* Medium-priority threads keep running
* Low-priority thread never gets CPU to release resource

So:
High waits for Low
Medium blocks Low
System appears frozen

---

## 🎯 Real Example

* UI thread (high priority) waits for lock
* Background thread (low priority) holds lock
* Many medium tasks running
* UI freezes

---

# 🛠️ How iOS Solves Priority Inversion

### ✅ 1️⃣ Priority Inheritance (Kernel-Level)

If high-priority thread waits on low-priority thread,
system temporarily boosts low-priority thread.

This is automatic for:

* `NSLock`
* `pthread_mutex`
* Dispatch queues

---

### ✅ 2️⃣ Avoid Long Critical Sections

Bad:

```swift
lock.lock()
heavyComputation()
networkCall()
lock.unlock()
```

Good:

```swift
lock.lock()
updateSharedState()
lock.unlock()

heavyComputation()
```

Keep lock duration minimal.

---

### ✅ 3️⃣ Use QoS Properly

```swift
DispatchQueue.global(qos: .userInitiated)
DispatchQueue.global(qos: .background)
```

Match priority to work type.

Wrong QoS causes starvation + inversion-like behavior.

---

# 🚀 Modern Swift Solution to Priority Inversion

## ✅ Use Actors Instead of Locks

Actors use cooperative scheduling.

No thread blocking.
Tasks yield instead of block.

This reduces inversion dramatically.

---

## ✅ Avoid Blocking Calls

Never use:

```swift
DispatchSemaphore.wait()
Thread.sleep()
DispatchQueue.sync
```

Inside async code.

Blocking prevents executor from scheduling properly.

---

## ✅ Use Structured Concurrency

Instead of unmanaged background tasks:

```swift
Task.detached { } // dangerous
```

Prefer:

```swift
async let
TaskGroup
```

Structured tasks inherit priority automatically.

---

# 🔥 Advanced: Task Priority in Swift

You can specify:

```swift
Task(priority: .high) {
    await doWork()
}
```

Available priorities:

* .high
* .userInitiated
* .medium
* .low
* .background

Swift runtime propagates priority to child tasks.

This reduces inversion.

---

# 🔥 Deadlock vs Priority Inversion

| Feature                 | Deadlock | Priority Inversion |
| ----------------------- | -------- | ------------------ |
| Threads stuck forever   | ✅        | ❌                  |
| Performance degradation | ❌        | ✅                  |
| Circular waiting        | ✅        | ❌                  |
| Caused by blocking      | Often    | Always             |
| Solved by actor         | Often    | Usually            |

---

# 🏆 Senior-Level Best Practices

1. Prefer actors over locks
2. Avoid nested awaits across actors unnecessarily
3. Never block inside async context
4. Keep critical sections tiny
5. Use proper QoS
6. Use structured concurrency
7. Avoid shared mutable state

---

# 🔬 How to Debug

* Thread Sanitizer
* Instruments → Time Profiler
* Instruments → System Trace
* Debug Navigator → Thread view

For priority inversion:
Look for:

* UI thread waiting
* Low priority thread holding lock

---

# 🎯 Interview-Perfect Summary

Deadlock in modern concurrency is reduced because actors eliminate explicit locking and use cooperative suspension. However, logical deadlocks can still occur if tasks await each other cyclically.

Priority inversion happens when a high-priority task waits on a low-priority one, while medium-priority tasks prevent progress. iOS mitigates this with priority inheritance, but developers must avoid blocking calls and long critical sections.

Modern best practice:
Use actors, avoid blocking, keep critical sections small, use structured concurrency, and rely on cooperative scheduling.

---

If you want, next I can explain:

* ⭐ Actor reentrancy deep dive (very important)
* ⭐ Executors and hopping
* ⭐ How Swift runtime schedules tasks internally
* ⭐ Lock-free vs actor comparison
* ⭐ Real production concurrency architecture for iOS

Tell me which direction you want 🚀
