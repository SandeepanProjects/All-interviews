//
//  producer-consumer problem.swift
//  
//
//  Created by Apple on 19/08/25.
//

import Foundation

The **producer-consumer problem** is a classic synchronization challenge in concurrent programming. It describes a scenario where:

* **Producers** generate data and add it to a **shared buffer**.
* **Consumers** take data from the buffer and process it.
* The buffer has **limited capacity**.
* Both producer and consumer run concurrently, possibly on separate threads.

The goal is to:

* Avoid the **producer overfilling** the buffer.
* Prevent the **consumer from reading from an empty buffer**.
* Ensure **thread-safe access** to the buffer.

---

## 📦 Real-World Analogy

Imagine a bakery:

* The **baker (producer)** makes loaves of bread and places them on a shelf.
* The **customer (consumer)** takes loaves from the shelf.
* The shelf (buffer) can only hold, say, 5 loaves at a time.

---

## ⚠️ Key Problems to Solve

1. **Synchronization** between producer and consumer
2. Avoid **race conditions** when accessing the buffer
3. Prevent **deadlocks** and **starvation**

---

## ✅ Solutions in Swift

There are multiple ways to solve the producer-consumer problem. Here are three common approaches in iOS/Swift:

---

### ✅ 1. Using **DispatchSemaphore** (Manual Synchronization)

```swift
class Buffer<T> {
    private var queue: [T] = []
    private let capacity: Int
    private let accessQueue = DispatchQueue(label: "buffer.queue")
    private let full: DispatchSemaphore
    private let empty: DispatchSemaphore

    init(capacity: Int) {
        self.capacity = capacity
        full = DispatchSemaphore(value: 0)
        empty = DispatchSemaphore(value: capacity)
    }

    func produce(_ item: T) {
        empty.wait() // Wait if buffer is full
        accessQueue.async {
            self.queue.append(item)
            print("Produced: \(item)")
            self.full.signal() // Signal that buffer has at least one item
        }
    }

    func consume() -> T? {
        full.wait() // Wait if buffer is empty
        var item: T?
        accessQueue.sync {
            item = self.queue.removeFirst()
            print("Consumed: \(String(describing: item))")
        }
        empty.signal() // Signal that buffer has space
        return item
    }
}
```

#### ✅ Use:

```swift
let buffer = Buffer<Int>(capacity: 5)

DispatchQueue.global().async {
    for i in 1...10 {
        buffer.produce(i)
        sleep(1)
    }
}

DispatchQueue.global().async {
    for _ in 1...10 {
        _ = buffer.consume()
        sleep(2)
    }
}
```

---

### ✅ 2. Using **Actors** (Swift Concurrency – Safe and Modern)

With Swift 5.5+, you can use `actor` to manage state safely:

```swift
actor BoundedBuffer<T> {
    private var buffer: [T] = []
    private let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
    }

    func produce(_ item: T) async {
        while buffer.count >= capacity {
            await Task.yield() // Give up time if full
        }
        buffer.append(item)
        print("Produced: \(item)")
    }

    func consume() async -> T? {
        while buffer.isEmpty {
            await Task.yield() // Give up time if empty
        }
        let item = buffer.removeFirst()
        print("Consumed: \(item)")
        return item
    }
}
```

#### ✅ Use:

```swift
let buffer = BoundedBuffer<Int>(capacity: 5)

Task {
    for i in 1...10 {
        await buffer.produce(i)
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

Task {
    for _ in 1...10 {
        _ = await buffer.consume()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}
```

---

### ✅ 3. Using `OperationQueue` (Less common, but possible)

You can model producers and consumers as `Operation`s and manage their dependencies manually, but this is less flexible for dynamic producer-consumer setups.

---

## 🧠 Summary

| Concept       | Description                                          |
| ------------- | ---------------------------------------------------- |
| Producer      | Generates data and adds to a shared buffer           |
| Consumer      | Takes data from the buffer and processes it          |
| Shared buffer | Needs synchronization to avoid corruption            |
| Risks         | Race conditions, buffer overflow/underflow, deadlock |
| Solutions     | DispatchSemaphore, Actors, Serial Queues             |

---
