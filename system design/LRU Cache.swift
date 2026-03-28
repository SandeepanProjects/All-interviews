//
//  LRU Cache.swift
//  
//
//  Created by Apple on 28/03/26.
//

import Foundation

Let’s go deep into **LRU Cache**—this is a **very common interview + real-world problem**, and it fits perfectly with Clean Architecture + performance optimization.

---

# 🧠 1. What is LRU Cache?

**LRU = Least Recently Used**

👉 When cache is full:

* Remove the **least recently accessed item**
* Keep the **most recently used items**

---

## 🔥 Example

Capacity = 2

```
put(1, A)
put(2, B)
get(1) → A   (1 becomes most recent)
put(3, C)    (removes 2)
```

---

# ⚡ 2. Requirements (Important)

| Operation | Time Complexity |
| --------- | --------------- |
| get()     | O(1)            |
| put()     | O(1)            |

---

# 🧱 3. Core Idea

To achieve **O(1)**:

👉 Use **2 Data Structures**

1. **HashMap (Dictionary)** → Fast lookup
2. **Doubly Linked List** → Maintain order

---

## 🔄 Structure

```
Head (Most Recent)
   ⇄ Nodes ⇄
Tail (Least Recent)
```

---

# 🧩 4. Swift Implementation (Production Level)

---

## 🔹 Node

```swift
final class Node<Key: Hashable, Value> {
    let key: Key
    var value: Value
    var prev: Node?
    var next: Node?

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}
```

---

## 🔹 LRU Cache

```swift
final class LRUCache<Key: Hashable, Value> {

    private let capacity: Int
    private var dict: [Key: Node<Key, Value>] = [:]

    private var head: Node<Key, Value>? // Most recent
    private var tail: Node<Key, Value>? // Least recent

    init(capacity: Int) {
        self.capacity = capacity
    }

    // MARK: - Get
    func get(_ key: Key) -> Value? {
        guard let node = dict[key] else { return nil }

        moveToHead(node)
        return node.value
    }

    // MARK: - Put
    func put(_ key: Key, _ value: Value) {
        if let node = dict[key] {
            node.value = value
            moveToHead(node)
        } else {
            let newNode = Node(key: key, value: value)
            dict[key] = newNode
            addToHead(newNode)

            if dict.count > capacity {
                removeTail()
            }
        }
    }

    // MARK: - Helpers

    private func addToHead(_ node: Node<Key, Value>) {
        node.next = head
        node.prev = nil

        head?.prev = node
        head = node

        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: Node<Key, Value>) {
        let prev = node.prev
        let next = node.next

        prev?.next = next
        next?.prev = prev

        if node === head { head = next }
        if node === tail { tail = prev }
    }

    private func moveToHead(_ node: Node<Key, Value>) {
        removeNode(node)
        addToHead(node)
    }

    private func removeTail() {
        guard let tail = tail else { return }

        dict[tail.key] = nil
        removeNode(tail)
    }
}
```

---

# 🧵 5. Thread-Safe LRU (Using Actor 🔥)

Perfect for modern concurrency:

```swift
actor SafeLRUCache<Key: Hashable, Value> {
    private let cache: LRUCache<Key, Value>

    init(capacity: Int) {
        self.cache = LRUCache(capacity: capacity)
    }

    func get(_ key: Key) -> Value? {
        return cache.get(key)
    }

    func put(_ key: Key, _ value: Value) {
        cache.put(key, value)
    }
}
```

---

# 🚀 6. Real-World Usage (iOS)

### ✅ API Response Cache

* Avoid repeated network calls

### ✅ Image Cache

* Store downloaded images

### ✅ Pagination cache

* Store pages already fetched

---

## 🔹 Example in Repository

```swift
final class UserRepositoryImpl: UserRepository {

    private let api: APIService
    private let cache = SafeLRUCache<Int, [User]>(capacity: 10)

    func fetchUsers(page: Int) async throws -> [User] {

        if let cached = await cache.get(page) {
            return cached
        }

        let dtos = try await api.fetchUsers(page: page)
        let users = dtos.map { $0.toDomain() }

        await cache.put(page, users)

        return users
    }
}
```

---

# ❗ 7. Common Interview Mistakes

❌ Using Array → O(n)
❌ Forgetting to update order on `get()`
❌ Not removing from hashmap on eviction
❌ Using Singly Linked List

---

# 🎯 8. Interview One-Liner

> “LRU Cache uses a HashMap for O(1) lookup and a doubly linked list to maintain access order. On every get/put, we move the node to the head, and when capacity exceeds, we remove the tail.”

---

# 🔥 Want Next Level?

I can push you further with:

* LFU Cache (harder than LRU)
* System design: caching strategy like Netflix
* NSCache vs custom LRU (iOS-specific)
* Disk + memory hybrid cache

Just say 👍
