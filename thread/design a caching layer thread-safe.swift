//
//  design a caching layer thread-safe.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Designing a **thread-safe caching layer** is a common and important task in iOS development, especially when multiple threads (e.g., network layer, UI layer, background processing) access shared resources.

---

## 🎯 **Goals for the Caching Layer**

* **Thread-safe**: Prevent race conditions during reads/writes
* **Efficient**: Fast access (especially reads)
* **Optional eviction policy**: (e.g., LRU or time-based)
* **Composable**: Easily integrated with other components

---

## ✅ Recommended Approach: Use `NSCache` + Serial Queue or Actor

### ✅ Option 1: **Swift Actor-Based Cache (Modern, Safe)**

> ✅ Use this if you’re targeting iOS 15+ (Swift 5.5+)

```swift
actor Cache<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]

    func get(_ key: Key) -> Value? {
        return storage[key]
    }

    func set(_ key: Key, value: Value) {
        storage[key] = value
    }

    func remove(_ key: Key) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
    }
}
```

### ✅ Usage

```swift
let imageCache = Cache<String, UIImage>()

Task {
    await imageCache.set("avatar", value: image)
    let cachedImage = await imageCache.get("avatar")
}
```

* **Thread-safe by design**: actors serialize access to internal state.
* Simple and efficient for most in-memory caching use cases.

---

### ✅ Option 2: **Using `NSCache` (Thread-Safe by Default)**

`NSCache` is a built-in thread-safe class with LRU eviction and memory management.

```swift
class ImageCache {
    private let cache = NSCache<NSString, UIImage>()

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func get(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}
```

* ✅ Thread-safe for concurrent access
* ✅ Built-in eviction based on memory pressure
* 🚫 Cannot easily customize eviction strategy (e.g. custom LRU)

---

### ✅ Option 3: **Manual Thread-Safe Cache with Serial Queue**

If you need full control over behavior (e.g., custom eviction):

```swift
class ThreadSafeCache<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "com.example.cacheQueue")

    func get(_ key: Key) -> Value? {
        queue.sync {
            return storage[key]
        }
    }

    func set(_ key: Key, value: Value) {
        queue.async {
            self.storage[key] = value
        }
    }

    func remove(_ key: Key) {
        queue.async {
            self.storage.removeValue(forKey: key)
        }
    }

    func clear() {
        queue.async {
            self.storage.removeAll()
        }
    }
}
```

* **Fine-grained control** over timing and behavior
* Ensures **reads/writes don’t clash**
* Slightly more work to maintain vs. actors

---

## 🧠 When to Use What

| Approach        | Pros                                | Use When...                            |
| --------------- | ----------------------------------- | -------------------------------------- |
| `actor`         | Modern, clean, safe                 | Using Swift Concurrency (iOS 15+)      |
| `NSCache`       | Built-in, memory-aware, thread-safe | Caching images or large in-memory data |
| `DispatchQueue` | Customizable, works with structs    | Need eviction logic or full control    |

---

## Bonus: Optional Additions

* Add **expiration timers** (e.g., TTL-based)
* Add **LRU logic** if using `[Key: Value]` dictionary
* Make cache **generic** with protocols
* Persist to disk for hybrid memory-disk caching

---

Would you like an example of a thread-safe cache with LRU eviction or expiry policy?

Great! Let's design a **thread-safe, in-memory cache with LRU (Least Recently Used) eviction**, using **Swift** and a **serial dispatch queue** for synchronization. This works on all iOS versions.
                        
                        ---
                        
## 🔁 What is LRU Cache?
                        
LRU keeps recently used items in memory. When the cache exceeds its capacity:
                            
* It **evicts** the **least recently used** item first.
                        
                        ---
                        
## ✅ Key Requirements
                        
* ✅ **Thread-safe** access
* ✅ LRU eviction when capacity is exceeded
* ✅ Generic over key and value
* ✅ Fast: O(1) get/set operations
                        
We'll implement it using:
                            
* A **dictionary** for fast lookup
* A **doubly linked list** to track usage order
                        
                        ---
                        
## 🧠 Final Design Overview
                        
```swift
class LRUCache<Key: Hashable, Value> {
    private class Node {
        let key: Key
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
    private let queue = DispatchQueue(label: "com.example.lruCache")
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func get(_ key: Key) -> Value? {
        queue.sync {
            guard let node = dict[key] else {
                return nil
            }
            moveToHead(node)
            return node.value
        }
    }
    
    func set(_ key: Key, value: Value) {
        queue.sync {
            if let node = dict[key] {
                node.value = value
                moveToHead(node)
            } else {
                let newNode = Node(key: key, value: value)
                dict[key] = newNode
                addToHead(newNode)
                
                if dict.count > capacity, let tail = tail {
                    removeNode(tail)
                    dict[tail.key] = nil
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
        if tail == nil {
            tail = head
        }
    }
    
    private func removeNode(_ node: Node) {
        if let prev = node.prev {
            prev.next = node.next
        } else {
            head = node.next
        }
        
        if let next = node.next {
            next.prev = node.prev
        } else {
            tail = node.prev
        }
    }
    
    func clear() {
        queue.sync {
            dict.removeAll()
            head = nil
            tail = nil
        }
    }
}
```

---

## ✅ Usage Example

```swift
let cache = LRUCache<String, String>(capacity: 3)

cache.set("A", value: "Apple")
cache.set("B", value: "Banana")
cache.set("C", value: "Cherry")

print(cache.get("A")!) // Apple — A becomes most recently used
cache.set("D", value: "Date") // Evicts "B" (least recently used)

print(cache.get("B")) // nil
print(cache.get("C")!) // Cherry
```

---

## 💡 Notes

* The cache is fully **thread-safe** using a serial dispatch queue.
* `get` and `set` are **O(1)** operations.
* Can be extended to support **TTL expiration**, **disk caching**, or **notifications** when evictions happen.

---
