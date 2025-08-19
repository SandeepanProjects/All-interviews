//
//  What is a deadlock and how do you prevent it.swift
//  
//
//  Created by Apple on 19/08/25.
//

import Foundation

A **deadlock** is a situation where two or more threads are **waiting on each other to release resources**, and none of them can proceed—causing your app to freeze or hang indefinitely.

---

## 🕸️ What Is a Deadlock?

It typically happens when:

1. **Thread A** locks **Resource 1**, then tries to lock **Resource 2**.
2. **Thread B** locks **Resource 2**, then tries to lock **Resource 1**.
3. Both threads now **wait forever** for the other to release the resource.

---

### 🔒 Simple Example in Swift:

```swift
let lock1 = NSLock()
let lock2 = NSLock()

DispatchQueue.global().async {
    lock1.lock()
    sleep(1) // simulate some work
    lock2.lock() // waiting for lock2
    print("Thread 1")
    lock2.unlock()
    lock1.unlock()
}

DispatchQueue.global().async {
    lock2.lock()
    sleep(1)
    lock1.lock() // waiting for lock1 (which is held by Thread 1)
    print("Thread 2")
    lock1.unlock()
    lock2.unlock()
}
```

* This will **deadlock**, because both threads are **holding one lock and waiting for the other**.

---

## ❌ Common Causes of Deadlocks

1. **Locking resources in different orders across threads**
2. **Using blocking calls on main thread** (like `DispatchQueue.main.sync {}`)
3. **Nested locks** without proper ordering
4. **Waiting for a resource that’s never released**
5. **Infinite synchronous waits**

---

## ✅ How to Prevent Deadlocks

### 1. **Always Lock Resources in a Consistent Order**

If multiple locks must be acquired, always acquire them in the **same order** across all threads.

```swift
// Always lock lockA before lockB
lockA.lock()
lockB.lock()
// Do work
lockB.unlock()
lockA.unlock()
```

---

### 2. **Avoid Nested Locks Where Possible**

Nested locking increases complexity. Flatten or redesign logic to avoid requiring multiple locks simultaneously.

---

### 3. **Never Call `sync` on the Same Queue You're On**

This is a very common trap in iOS:

```swift
DispatchQueue.main.sync {
    // ❌ Deadlock if called from the main thread
}
```

* If the current thread is the main thread, it waits on itself—causing a deadlock.

---

### 4. **Use Concurrency Tools Designed to Avoid Deadlocks**

* Use **GCD queues** (especially serial queues) instead of locks.
* Use **Actors** in Swift concurrency for thread-safe access with less chance of deadlock.
* Use **semaphores** carefully (avoid overusing them or using them on the main thread).

---

### 5. **Use Timeouts**

If you must wait, use timeouts to avoid waiting forever.

```swift
if lock1.lock(before: Date().addingTimeInterval(2)) {
    // acquired lock
    lock1.unlock()
} else {
    print("Timeout — possible deadlock avoided")
}
```

---

## 🧠 Summary

| Deadlock Cause                       | Prevention Strategy                        |
| ------------------------------------ | ------------------------------------------ |
| Locking resources in different order | Always lock in the same order              |
| Sync call on same queue              | Never call `sync` on current queue         |
| Nested locks                         | Avoid or simplify locking logic            |
| Holding locks too long               | Keep lock duration minimal                 |
| Shared mutable state                 | Use actors, serial queues, or immutability |

---

Would you like a live example of a deadlock and how to fix it in Swift code?
