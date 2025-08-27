//
//  struct vs class vs actor.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

Great! Let's compare **`struct`**, **`class`**, and **`actor`** in **Swift**, focusing on their **behavior**, **use cases**, and especially how they handle **memory, ownership, and concurrency**.

This comparison is key to understanding **how data flows**, **who owns it**, and **how safe it is in a multithreaded environment**.

---

## 🧱 1. STRUCTS (`struct`)

### 🔑 Characteristics:

* **Value type** ✅
* **Copied on assignment**
* **Thread-safe by default** ✅ (no shared mutable state)
* Cannot inherit from other types
* Very lightweight

### 📦 Example:

```swift
struct User {
    var name: String
}

var user1 = User(name: "Alice")
var user2 = user1
user2.name = "Bob"

print(user1.name) // "Alice"
print(user2.name) // "Bob"
```

✅ The two users are separate **copies** — changing one doesn’t affect the other.

### ✅ Best for:

* Simple data models (like `Point`, `User`, `Rectangle`)
* Immutable or copy-on-write data
* SwiftUI `View`s

---

## 🏛️ 2. CLASSES (`class`)

### 🔑 Characteristics:

* **Reference type** ❗️
* **Shared on assignment**
* **NOT thread-safe by default** ❌
* Supports **inheritance**
* Stored in the **heap**
* Lifecycle managed with **reference counting** (ARC)

### 📦 Example:

```swift
class User {
    var name: String
    init(name: String) {
        self.name = name
    }
}

let user1 = User(name: "Alice")
let user2 = user1
user2.name = "Bob"

print(user1.name) // "Bob"
```

🔁 Both `user1` and `user2` point to the **same object**. Changes affect both.

### ❗️ Thread-safety concern:

If two threads modify the same instance → **data race** 💥

### ✅ Best for:

* Shared mutable state
* Complex object graphs
* When identity matters (e.g., `===` comparisons)
* Legacy frameworks (UIKit, Foundation, etc.)

---

## 🎭 3. ACTORS (`actor`)

### 🔑 Characteristics:

* **Reference type** ✅ (like class)
* Designed for **concurrent safety**
* **Isolated internal state** — only one task can access it at a time
* Uses **structured concurrency**
* No inheritance (like `struct`)

### 📦 Example:

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

let counter = Counter()

Task {
    await counter.increment()
    print(await counter.getValue()) // Safe!
}
```

✅ All access is automatically serialized → **no data races**

### ❗ Requires `await` when accessing from outside:

```swift
await counter.increment()
```

### ✅ Best for:

* Managing shared mutable state across threads
* Caching, data stores, services
* Avoiding manual locking (no need for `DispatchQueue` or `NSLock`)

---

## 🧠 Summary Table

| Feature                           | `struct`          | `class`              | `actor`                     |
| --------------------------------- | ----------------- | -------------------- | --------------------------- |
| **Type**                          | Value             | Reference            | Reference                   |
| **Copy behavior**                 | Copies on assign  | Shared reference     | Shared reference            |
| **Thread-safe by default**        | ✅ Yes             | ❌ No                 | ✅ Yes (isolated state)      |
| **Mutability**                    | Must use `var`    | Mutable              | Mutable                     |
| **Inheritance**                   | ❌ No              | ✅ Yes                | ❌ No                        |
| **Equatable by identity (`===`)** | ❌ No              | ✅ Yes                | ✅ Yes                       |
| **Memory**                        | Stack or Heap     | Heap                 | Heap                        |
| **Concurrency safety**            | Safe if immutable | Unsafe unless locked | ✅ Safe (serialized access)  |
| **Access**                        | Direct            | Direct               | `await` for external access |

---

## 🔍 When to Use Each

| Use Case                                                                       | Choose   |
| ------------------------------------------------------------------------------ | -------- |
| Lightweight data (e.g., `Point`, `User`, `Settings`)                           | `struct` |
| Shared, mutable object (e.g., view controller, service class)                  | `class`  |
| Shared mutable state across threads (e.g., counter, network manager, database) | `actor`  |

---

## 🧪 Example Comparison

### Struct (Safe, copied):

```swift
struct Counter {
    var value: Int
}
```

### Class (Shared, unsafe if multithreaded):

```swift
class Counter {
    var value: Int
}
```

### Actor (Shared, safe):

```swift
actor Counter {
    var value = 0
}
```

---

## 🧠 Final Thoughts

* Use `struct` for most simple data models and UI code
* Use `class` when identity or inheritance is needed
* Use `actor` when you need **shared mutable state with safety** across threads — it’s Swift’s answer to multithreaded bugs

---

Would you like a real-world example showing how switching from a `class` to an `actor` fixes a data race?
