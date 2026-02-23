//
//  Producer-consumer problem.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

The **Producer–Consumer problem** is a classic synchronization problem:

* Producer → produces data
* Consumer → consumes data
* Shared resource → bounded buffer
* Must avoid:

  * Race conditions
  * Buffer overflow
  * Buffer underflow

I’ll give you **production-level Swift solutions**, from classic to modern concurrency.

---

# ✅ 1️⃣ Optimal Modern Swift Solution (Actor-Based) — iOS 15+

This is the **cleanest and safest** implementation.

```swift
actor BoundedBuffer<T> {
    
    private var buffer: [T] = []
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func produce(_ item: T) async {
        while buffer.count >= capacity {
            await Task.yield()
        }
        buffer.append(item)
    }
    
    func consume() async -> T? {
        while buffer.isEmpty {
            await Task.yield()
        }
        return buffer.removeFirst()
    }
}
```

### Usage

```swift
let buffer = BoundedBuffer<Int>(capacity: 5)

Task {
    for i in 1...10 {
        await buffer.produce(i)
        print("Produced \(i)")
    }
}

Task {
    for _ in 1...10 {
        if let value = await buffer.consume() {
            print("Consumed \(value)")
        }
    }
}
```

---

### ✅ Why This Is Good

* No locks
* No race conditions
* Automatic isolation
* Cleanest modern approach

### ⚠️ Limitation

Uses busy waiting (`Task.yield()`).

Let’s improve it properly.

---

# 🚀 2️⃣ Best Practical Implementation Using Semaphore (Optimal Classic Solution)

This is the **correct classical bounded-buffer solution**.

We use:

* `empty` semaphore → available buffer slots
* `full` semaphore → available items
* `mutex` → protect critical section

```swift
final class ProducerConsumerBuffer<T> {
    
    private var buffer: [T] = []
    private let capacity: Int
    
    private let empty: DispatchSemaphore
    private let full = DispatchSemaphore(value: 0)
    private let mutex = DispatchSemaphore(value: 1)
    
    init(capacity: Int) {
        self.capacity = capacity
        self.empty = DispatchSemaphore(value: capacity)
    }
    
    func produce(_ item: T) {
        empty.wait()              // wait for empty slot
        mutex.wait()              // enter critical section
        
        buffer.append(item)
        
        mutex.signal()            // exit critical section
        full.signal()             // signal item available
    }
    
    func consume() -> T {
        full.wait()               // wait for available item
        mutex.wait()              // enter critical section
        
        let item = buffer.removeFirst()
        
        mutex.signal()            // exit critical section
        empty.signal()            // signal empty slot
        
        return item
    }
}
```

---

### Usage

```swift
let buffer = ProducerConsumerBuffer<Int>(capacity: 5)

DispatchQueue.global().async {
    for i in 1...10 {
        buffer.produce(i)
        print("Produced \(i)")
    }
}

DispatchQueue.global().async {
    for _ in 1...10 {
        let value = buffer.consume()
        print("Consumed \(value)")
    }
}
```

---

# 🧠 Why This Is Optimal

| Feature            | Result |
| ------------------ | ------ |
| No busy waiting    | ✅      |
| Thread safe        | ✅      |
| Bounded buffer     | ✅      |
| O(1) operations    | ✅      |
| No race conditions | ✅      |

This is the **textbook optimal solution**.

---

# 🔥 3️⃣ High-Performance GCD Queue + Barrier Solution

Best for read-heavy scenarios.

```swift
final class ConcurrentBuffer<T> {
    
    private var buffer: [T] = []
    private let capacity: Int
    private let queue = DispatchQueue(
        label: "com.buffer.concurrent",
        attributes: .concurrent
    )
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func produce(_ item: T) {
        queue.async(flags: .barrier) {
            guard self.buffer.count < self.capacity else { return }
            self.buffer.append(item)
        }
    }
    
    func consume(completion: @escaping (T?) -> Void) {
        queue.async(flags: .barrier) {
            guard !self.buffer.isEmpty else {
                completion(nil)
                return
            }
            let item = self.buffer.removeFirst()
            completion(item)
        }
    }
}
```

⚠️ This does NOT block producers/consumers — it drops items instead.

---

# 🏆 Interview-Perfect Explanation

If interviewer asks:

> How would you implement Producer-Consumer in iOS?

You answer:

1. Use semaphores for classical bounded buffer.
2. Use actor for modern Swift concurrency.
3. Use concurrent queue + barrier for performance.
4. Avoid busy-waiting.
5. Maintain O(1) operations.

---

# ⚡ Complexity

| Operation | Time |
| --------- | ---- |
| Produce   | O(1) |
| Consume   | O(1) |
| Space     | O(N) |

---

# 🔥 Senior-Level Follow-Up Points

Be ready to explain:

* Why semaphore is better than just mutex
* Difference between mutex and binary semaphore
* Why busy waiting is bad
* Deadlock scenarios
* Priority inversion
* Fairness guarantees
* Backpressure
* How Combine handles producer-consumer
* How OperationQueue can model this

---

# 🚀 What Next?

Since you're preparing for advanced iOS/system-level topics, I can give you:

* ⭐ AsyncSequence-based Producer-Consumer
* ⭐ Combine-based implementation
* ⭐ Lock-free ring buffer (extremely advanced)
* ⭐ Condition variable based implementation
* ⭐ Real-world example (image processing pipeline)

Tell me the level you want.
