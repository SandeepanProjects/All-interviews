//
//  protocols with associated types.swift
//  
//
//  Created by Apple on 02/12/25.
//

import Foundation

In Swift, **protocols with associated types** exist to make your code **generic, flexible, and type-safe** without tying it to specific concrete types. They’re especially useful when a protocol needs to describe a *relationship between types* rather than a single fixed type.

Here’s a simple explanation of **why and when to use them**:

---

# ✅ **1. When a protocol depends on a type that isn’t known yet**

Sometimes a protocol needs to refer to a type, but you don’t want to force a specific one.

Example: A `Container` protocol:

```swift
protocol Container {
    associatedtype Item
    func add(_ item: Item)
    func getAll() -> [Item]
}
```

Different types can adopt it with different associated types:

```swift
struct IntStack: Container {
    typealias Item = Int
    private var items: [Int] = []
}

struct StringQueue: Container {
    typealias Item = String
    private var items: [String] = []
}
```

**Why useful:**
One protocol works for many concrete types without restricting them.

---

# ✅ **2. To express relationships between types**

Associated types let you model protocols where methods rely on *each other’s* types.

Example: `IteratorProtocol`:

```swift
protocol IteratorProtocol {
    associatedtype Element
    mutating func next() -> Element?
}
```

Swift doesn’t know the element type until you implement it.

---

# ✅ **3. To build generic algorithms**

By using associated types in protocols, you allow functions or other types to work with *any* conforming type.

Example: `Sequence` uses associated types so it works with arrays, dictionaries, sets, custom collections, etc.

You can write functions like:

```swift
func printAll<S: Sequence>(_ sequence: S) {
    for element in sequence {
        print(element)
    }
}
```

Works for any sequence whose element type is known via its associated type.

---

# ✅ **4. When Self requirements are needed**

Some protocols can’t be turned into “existentials” (like `any MyProtocol`) because they have an associated type tied to `Self`.

Example:

```swift
protocol Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool
}
```

Associated types allow such relationships without needing concrete types upfront.

---

# 🆚 **Why not just use generics everywhere?**

* Generics are used on **functions or types**.
* Associated types are used on **protocols**.

You use **associated types** when you want protocols to describe generic behavior.

---

# 🧠 Summary — Why use protocols with associated types?

| Benefit                        | Description                                          |
| ------------------------------ | ---------------------------------------------------- |
| **Abstraction**                | Define behavior without fixing types.                |
| **Flexibility**                | Different conformers choose their own types.         |
| **Type Safety**                | Compiler knows what type is used for each conformer. |
| **Expressiveness**             | Describe complex relationships between types.        |
| **Generics at protocol level** | Create reusable components and algorithms.           |

---

If you want, I can also explain:

🔹 *When not to use associated types*
🔹 *Examples involving real-world apps*
🔹 *How `any` and opaque types (`some`) work with these protocols*
