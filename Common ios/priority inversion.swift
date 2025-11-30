//
//  priority inversion.swift
//  
//
//  Created by Apple on 30/11/25.
//

import Foundation

Below is a **clear, deep, iOS-specific explanation** of **Deadlocks** and **Priority Inversion**, along with their **causes, real iOS examples, and correct solutions**.
I will keep the explanation practical, relevant to **GCD**, **Swift concurrency**, **NSLock**, **serial queues**, and **thread scheduling on iOS**.

---

# ✅ **1. What is a Deadlock in iOS?**

A **deadlock** happens when two or more threads or queues are **blocked waiting for each other**, and none of them can continue.
This causes your app to **freeze** permanently.

### ⚠️ Characteristics:

* The app stops responding.
* Threads are stuck waiting.
* 100% reproducible.
* Often caused by improper **dispatch_sync** or **locking**.

---

# 🔥 **Deadlock in GCD (Common in iOS)**

### ❌ Example 1 — Calling `sync` on the main queue from the main thread

```swift
DispatchQueue.main.sync {
    print("This will never execute")
}
```

Why this deadlocks:

1. The main thread is executing this code.
2. It requests the **main queue** to run a **sync** task.
3. The main queue is already busy → it can’t run the new task.
4. The current thread waits forever → **deadlock**.

This freezes the app.

---

### ❌ Example 2 — A serial queue waiting on itself

```swift
let queue = DispatchQueue(label: "serial.queue")

queue.async {
    queue.sync {    // Deadlock
        print("Never reaches here")
    }
}
```

The serial queue cannot execute the inner sync because it's already occupied by the outer async.

---

### ❌ Example 3 — Using `NSLock` incorrectly

```swift
let lock = NSLock()
lock.lock()
lock.lock()   // Deadlock: same thread locking twice without unlocked
```

---

# 🔵 **How to Prevent Deadlocks in iOS**

### ✔ **Solution 1: Never call `sync` on the main queue from the main queue**

Use `async` instead:

```swift
DispatchQueue.main.async {
    print("safe")
}
```

---

### ✔ **Solution 2: Never call `sync` from a queue onto itself**

If you need work to happen on the same queue, use `async` or remove nesting.

---

### ✔ **Solution 3: Use Swift concurrency (async/await) instead of GCD sync**

Swift concurrency avoids most deadlocks because:

* It does not block threads.
* Tasks suspend instead of waiting.

---

### ✔ **Solution 4: Use `dispatchPrecondition(condition:)` in debug mode**

```swift
dispatchPrecondition(condition: .notOnQueue(.main))
```

This crashes early in debug if you're on the wrong queue → protects you from deadlocks.

---

### ✔ **Solution 5: For locks, use NSRecursiveLock if recursion is needed**

```swift
let lock = NSRecursiveLock()
lock.lock()
lock.lock()  // Now allowed
```

---

---

# 🟦 **2. What is Priority Inversion in iOS?**

**Priority Inversion** happens when:

* A **low-priority** thread/queue holds a shared resource (lock, queue, variable).
* A **high-priority** thread needs that resource and blocks waiting.
* Meanwhile, a **medium-priority** thread keeps running and prevents the low-priority thread from finishing.

### ❗ Result:

The **high-priority code is delayed** because a **low-priority** task indirectly blocks it.

---

# 🔥 Priority Inversion Example in iOS (lock-based)

Assume:

* High-priority thread = UI thread
* Low-priority thread = background queue
* Medium priority = many system tasks

### Scenario:

```swift
let lock = NSLock()
var sharedData = 0
```

Low priority thread acquires the lock:

```swift
DispatchQueue.global(qos: .background).async {
    lock.lock()
    sleep(2)        // Work
    sharedData = 42
    lock.unlock()
}
```

High priority thread needs the lock:

```swift
DispatchQueue.main.async {
    lock.lock()     // UI thread is now blocked
    print(sharedData)
    lock.unlock()
}
```

Meanwhile, medium priority threads (network callbacks, system tasks) run, preventing low priority thread from finishing → **the UI is indirectly blocked** even though the high-priority queue has the highest priority.

This is priority inversion.

---

# 🟩 **How iOS Mitigates Priority Inversion Automatically**

iOS uses:

### ✔ **"Priority Inheritance"**

When a low-priority thread holds a lock that a high-priority thread needs:

→ The OS **temporarily boosts the low-priority thread’s priority**
→ It finishes quickly
→ Releases the lock
→ High-priority thread continues

This prevents the medium-priority thread from starving the low-priority one.

**NSLock, pthread mutex, and GCD queues support this.**

---

# 🟢 **But priority inversion STILL happens in iOS**

Especially when you:

* Misuse custom locks
* Use spin locks
* Hold locks for too long
* Use semaphores incorrectly
* Use bad queue priorities

---

# 🔧 **Solutions for Priority Inversion**

### ✔ **Solution 1: Use GCD queues instead of locks**

GCD serial queues have built-in priority inheritance.

```swift
let queue = DispatchQueue(label: "worker.queue", qos: .userInitiated)
queue.async {
    // Safe work here
}
```

---

### ✔ **Solution 2: Keep critical sections VERY short**

Hold locks only for microseconds, not seconds.

---

### ✔ **Solution 3: Use Swift Actors**

Actors are isolated and eliminate many lock contention issues.

```swift
actor DataStore {
    var value = 0
    func update() { value += 1 }
}
```

Actors serialize access without manually locking, preventing priority inversion.

---

### ✔ **Solution 4: Avoid blocking APIs (e.g., semaphores)**

Avoid:

```swift
semaphore.wait()
```

Prefer:

```swift
await semaphore.wait()
```

Or even better, avoid semaphores completely.

---

### ✔ **Solution 5: Set proper QoS when scheduling work**

Don’t do:

```swift
DispatchQueue.global(qos: .background).async {
    lock.lock()
    // long work that UI needs!
}
```

Use:

```swift
DispatchQueue.global(qos: .userInitiated).async {
    lock.lock()
    // Work the UI depends on
}
```

---

# 🟦 **Summary (Quick Comparison)**

| Concept      | Deadlock                               | Priority Inversion                          |
| ------------ | -------------------------------------- | ------------------------------------------- |
| What happens | Threads wait forever                   | High-priority thread waits on low-priority  |
| Cause        | Circular waiting, misuse of sync/locks | Incorrect QoS, lock contention              |
| Symptoms     | App freeze                             | Lag, UI stutters, degraded performance      |
| Outcome      | No progress ever                       | Slow performance, delayed responses         |
| Fixed by     | Avoid sync, proper locking             | GCD, actors, lock minimization, correct QoS |

---

# 🟩 Want next?

I can also provide:

* **Real-world iOS examples** of both issues
* **Diagrams** showing how priority inversion happens in threads
* **Sample project code** demonstrating both issues and fixes
* **Swift Concurrency version (async/await)** improvements over GCD

Just tell me!


Modern Concurrency Solutions

Below is a **modern, Swift Concurrency–based explanation** of **deadlocks** and **priority inversion** in iOS — **and how modern concurrency (async/await, actors, Task, TaskGroup, AsyncSequence)** solves or prevents them entirely.

This will help you understand how to shift from GCD problems → to Swift concurrency safety.

---

# 🚀 Swift Modern Concurrency = Structured Concurrency

Swift’s modern concurrency model is designed to **eliminate classes of problems** that were common with:

* GCD queues
* Locks (`NSLock`, `os_unfair_lock`, `pthread_mutex`)
* Semaphores
* Dispatch groups
* Callback pyramids

Two major benefits:

### **1. Deadlocks are much harder to create**

because async/await **never blocks threads**.

### **2. Priority inversion is largely avoided**

because Swift concurrency uses **cooperative scheduling** and **executor hopping**.

Let’s go step-by-step.

---

# 🟥 1. Deadlocks — Modern Concurrency Explanation

## ❌ **Deadlocks in old GCD-based code**

Deadlocks occur when threads block each other:

```swift
DispatchQueue.main.sync {
    // stuck forever
}
```

or

```swift
lock.lock()
lock.lock() // deadlock
```

or nested serial sync calls.

---

# 🟩 **How Swift Concurrency Prevents Deadlocks**

Swift concurrency uses **non-blocking suspension**, not blocking calls.

### 🔑 Key Rule:

**await never blocks a thread — it suspends the task.**

So instead of:

```swift
semaphore.wait()   // blocks the thread -> can deadlock
```

We use:

```swift
await semaphore.wait()   // suspends the task -> no deadlock
```

Suspension allows the executor to run other tasks → preventing circular waits.

---

# 🟦 Deadlock Example Rewritten with Modern Concurrency

### ❌ GCD version (deadlocks):

```swift
DispatchQueue.main.sync {
    print("deadlock")
}
```

### ✔ Modern concurrency version (no deadlock):

```swift
@MainActor
func updateUI() async {
    print("safe")
}
```

Even if `updateUI()` calls itself indirectly, the concurrency system **queues tasks**, not block threads.

---

# ✔ Why deadlocks are harder with modern concurrency:

### 1. **Tasks cannot synchronously wait on other tasks**

There is no API equivalent to:

```swift
syncInSameContext()
```

### 2. **Executors serialize tasks safely**

When a `@MainActor` function calls another `@MainActor` function, Swift queues tasks instead of deadlocking.

### 3. **Locks are replaced with actors**

Actors prevent lock-based deadlocks entirely.

---

# 🟩 Deadlock-Free Example Using Actors

Old GCD:

```swift
let lock = NSLock()
lock.lock()
lock.lock() // deadlock
```

Modern Swift:

```swift
actor Counter {
    var value = 0
    func increment() { value += 1 }
}
```

Actors enforce:

* **Sequential access**
* **No manual locking**
* **No deadlocks**

Because you **cannot** lock an actor twice — you simply await:

```swift
await counter.increment()
```

Tasks don’t block each other.

---

---

# 🟥 2. Priority Inversion — Modern Concurrency Explanation

Priority inversion =
**A high-priority task gets blocked because a low-priority one holds a resource it needs.**

Example in old GCD:

* Low QoS background thread takes a lock
* High QoS main thread tries to take lock → blocks
* Meanwhile, medium threads starve the low-priority one
* UI stutters or freezes

---

# 🟦 How Swift Modern Concurrency Fixes / Mitigates Priority Inversion

Swift concurrency uses:

### **1. Cooperative, not preemptive scheduling**

Swift tasks yield automatically at suspension points:

```swift
await someAsyncFunc()
```

This gives executors a chance to schedule high priority tasks.

---

### **2. Executors isolate state — no locks needed**

Actors replace locks, so low-priority tasks don’t block critical UI paths.

Example:

```swift
actor UserSession {
    var tokens: [String: String] = [:]
}
```

Main thread:

```swift
let token = await session.tokens["auth"]
```

The actor’s executor **temporarily runs at the priority of the awaiting caller**, so the low-priority background work won’t block the main thread.

This is **dynamic priority inheritance at the task level**.

---

### **3. Task Priority Propagation**

When a high-priority task accesses an actor:

```swift
@MainActor
func load() async {
    let data = await store.getData()  // store is an actor
}
```

Swift automatically boosts the actor's executor priority so the main task is not blocked by low-priority operations.

This solves classic priority inversion.

---

# 🟩 Example: Priority Inversion Happening in GCD But Not in Swift Concurrency

### ❌ GCD Version (inversion):

```swift
DispatchQueue.global(qos: .background).async {
    lock.lock()
    sleep(2)
    lock.unlock()
}

DispatchQueue.main.async {
    lock.lock()  // stuck waiting on background queue
    lock.unlock()
}
```

### ✔ Swift Concurrency Version:

```swift
actor SharedResource {
    func use() {}
}

let resource = SharedResource()

Task(priority: .background) {
    await resource.use()
}

Task(priority: .userInitiated) {
    await resource.use()     // main task is NOT blocked
}
```

In Swift concurrency:

* The background task suspends while waiting.
* The high-priority task gets the actor immediately.
* No inversion.

---

---

# 🟦 Modern Concurrency Solutions Summary

### ✔ **1. Use async/await instead of blocking `sync` or semaphores**

This eliminates deadlocks.

### ✔ **2. Use actors instead of manual locks**

Actors prevent both deadlocks and priority inversion.

### ✔ **3. Use `@MainActor` instead of dispatching to main queue**

Safer and avoids main thread blocking.

### ✔ **4. Prefer `Task` and `TaskGroup` over dispatch groups**

They do not block threads.

### ✔ **5. Avoid synchronous APIs in async code**

Never do:

```swift
Task { semaphore.wait() }
```

Use:

```swift
await semaphore.wait()
```

### ✔ **6. Use correct task priorities**

Swift’s priorities propagate through `await`.

---

# 🟩 Final Overview Table

| Issue                  | Old GCD Model                         | Modern Concurrency                          | Fix                        |
| ---------------------- | ------------------------------------- | ------------------------------------------- | -------------------------- |
| **Deadlock**           | Very common due to sync calls & locks | Very rare due to suspension                 | Use `async/await` & actors |
| **Priority Inversion** | Caused by locks + QoS mismatch        | Fixed via dynamic task priority inheritance | Use actors, avoid locks    |
| **Blocking**           | Often blocks threads                  | Never blocks threads                        | Use structured concurrency |
| **Shared state**       | Must use locks                        | Actors provide isolation                    | Use `actor`                |

---

# 🚀 Want code examples?

I can provide:

* A real app example showing deadlock → modern fix
* Actor-based data layer architecture
* How Swift tasks hop executors to avoid inversion
* A diagram showing actor isolation

Just tell me!

