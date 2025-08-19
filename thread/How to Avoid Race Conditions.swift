//
//  How to Avoid Race Conditions.swift
//  
//
//  Created by Apple on 19/08/25.
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

