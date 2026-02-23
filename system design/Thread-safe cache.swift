//
//  Thread-safe cache.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

Designing a **thread-safe cache in Swift (iOS)** is a very common senior-level interview topic (especially for Staff/Lead roles). I’ll give you **multiple optimal approaches**, explain trade-offs, and show when to use each.

---

# ✅ 1️⃣ Best Practical Solution: `NSCache` (Production Ready)

`NSCache` is:

* Thread-safe ✅
* Auto-evicts under memory pressure ✅
* Supports count & cost limits ✅
* Ideal for images, API responses, computed data ✅

```swift
final class ThreadSafeCache<Key: AnyObject, Value: AnyObject> {
    
    private let cache = NSCache<Key, Value>()
    
    init(countLimit: Int = 100, totalCostLimit: Int = 0) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }
    
    func set(_ value: Value, for key: Key, cost: Int = 0) {
        cache.setObject(value, forKey: key, cost: cost)
    }
    
    func value(for key: Key) -> Value? {
        return cache.object(forKey: key)
    }
    
    func remove(for key: Key) {
        cache.removeObject(forKey: key)
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
}
```

### ✅ Why This Is Optimal

* No manual locking required
* Automatically removes items under memory pressure
* Highly optimized by Apple
* O(1) average access

### 🔥 When To Use

* Image caching
* Network response caching
* Temporary in-memory objects

---

# ✅ 2️⃣ Modern Swift Concurrency Solution (Actor-Based)

If you're using **Swift Concurrency (iOS 15+)**, this is the cleanest design.

```swift
actor ThreadSafeCache<Key: Hashable, Value> {
    
    private var storage: [Key: Value] = [:]
    
    func set(_ value: Value, for key: Key) {
        storage[key] = value
    }
    
    func value(for key: Key) -> Value? {
        return storage[key]
    }
    
    func remove(for key: Key) {
        storage.removeValue(forKey: key)
    }
    
    func removeAll() {
        storage.removeAll()
    }
}
```

### ✅ Why This Is Excellent

* No locks needed
* No race conditions
* Automatic isolation
* Very readable

### ⚡ Time Complexity

* O(1) average for get/set

### 🔥 When To Use

* Modern async/await projects
* Clean architecture apps
* High-concurrency environments

---

# ✅ 3️⃣ GCD-Based Concurrent Queue (High Performance Classic)

This is commonly asked in interviews.

```swift
final class ThreadSafeCache<Key: Hashable, Value> {
    
    private var storage: [Key: Value] = [:]
    private let queue = DispatchQueue(
        label: "com.cache.concurrent",
        attributes: .concurrent
    )
    
    func set(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.storage[key] = value
        }
    }
    
    func value(for key: Key) -> Value? {
        return queue.sync {
            storage[key]
        }
    }
    
    func remove(for key: Key) {
        queue.async(flags: .barrier) {
            self.storage.removeValue(forKey: key)
        }
    }
}
```

### 🔥 Why Use Barrier?

* Multiple reads can happen simultaneously
* Writes are exclusive
* Much better than serial queue for read-heavy systems

### ⚡ Performance

* Excellent for read-heavy workloads
* Avoids unnecessary locking

---

# 🚀 4️⃣ Enterprise-Level: LRU Cache (Most Interviewers Love This)

If interviewer wants “optimal cache design”, they usually expect **LRU**.

LRU requires:

* Dictionary for O(1) lookup
* Doubly linked list for O(1) insert/remove

### High-Level Structure

```swift
final class LRUCache<Key: Hashable, Value> {
    
    private final class Node {
        var key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    private var dict: [Key: Node] = [:]
    private let capacity: Int
    
    private var head: Node?
    private var tail: Node?
    
    private let queue = DispatchQueue(
        label: "com.cache.lru",
        attributes: .concurrent
    )
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let node = dict[key] else { return nil }
            moveToHead(node)
            return node.value
        }
    }
    
    func put(_ key: Key, value: Value) {
        queue.async(flags: .barrier) {
            if let node = self.dict[key] {
                node.value = value
                self.moveToHead(node)
            } else {
                let newNode = Node(key: key, value: value)
                self.dict[key] = newNode
                self.addToHead(newNode)
                
                if self.dict.count > self.capacity {
                    self.removeTail()
                }
            }
        }
    }
    
    private func moveToHead(_ node: Node) {
        removeNode(node)
        addToHead(node)
    }
    
    private func addToHead(_ node: Node) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
        if tail == nil { tail = head }
    }
    
    private func removeNode(_ node: Node) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        
        if node === head { head = node.next }
        if node === tail { tail = node.prev }
    }
    
    private func removeTail() {
        guard let tail = tail else { return }
        dict.removeValue(forKey: tail.key)
        removeNode(tail)
    }
}
```

### ⏱ Complexity

* Get → O(1)
* Put → O(1)

---

# 🧠 Interview-Level Explanation

If asked:

> How would you design a thread-safe cache in iOS?

You answer:

1. For production → Use `NSCache`
2. For Swift Concurrency → Use `actor`
3. For performance tuning → Concurrent queue + barrier
4. For system design → LRU with O(1) operations

---

# 🔥 Senior-Level Follow-Up Points

Be ready to explain:

* Why `NSCache` is better than Dictionary
* Why barrier improves concurrency
* Why serial queue is slower for read-heavy systems
* Memory pressure eviction behavior
* Why actor eliminates data races
* When to use weak references
* TTL-based eviction strategies

---

# 🏆 Which One Should YOU Use?

Since you’re preparing for senior/lead iOS interviews:

| Scenario               | Best Choice |
| ---------------------- | ----------- |
| Production app         | `NSCache`   |
| Modern Swift app       | `actor`     |
| Interview coding round | GCD barrier |
| System design round    | LRU         |

---

If you want, I can now give:

* ⭐ A production-ready **LRU + TTL + Thread-safe** implementation
* ⭐ Disk + Memory hybrid cache
* ⭐ Image pipeline style cache like `Nuke`
* ⭐ Combine + async cache
* ⭐ Benchmark comparison

Just tell me which level you want.
