//
//  common protocols.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Absolutely! Let’s go **in-depth** into **Hashable, Equatable, Identifiable, and Comparable** protocols in Swift, including **what they are, why they’re used, and sample code** for each.

---

# **1. Equatable**

### **What is Equatable?**

`Equatable` is a protocol that allows instances of a type to be **compared for equality** using `==` and `!=`.

* **Required:** Implement `==` function (Swift can automatically synthesize it for structs with only Equatable properties).

---

### **When to use**

* Comparing objects for equality.
* Removing duplicates from arrays (`Array.unique()` via `Set` or `filter`).
* Searching in collections.

---

### **Example**

```swift
struct User: Equatable {
    let id: Int
    let name: String
}

// Automatic synthesis works here
let user1 = User(id: 1, name: "John")
let user2 = User(id: 2, name: "Jane")
let user3 = User(id: 1, name: "John")

print(user1 == user2) // false
print(user1 == user3) // true

// Custom Equatable
struct Point: Equatable {
    var x: Int
    var y: Int
    
    static func == (lhs: Point, rhs: Point) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
```

---

# **2. Hashable**

### **What is Hashable?**

`Hashable` allows a type to be used in **hash-based collections** like `Set` or `Dictionary` keys.

* Every Hashable object must provide a `hash(into:)` method.
* **Important:** Types that are `Hashable` must also be `Equatable`.

---

### **When to use**

* Dictionary keys
* Set elements (unique collections)
* Deduplicating objects

---

### **Example**

```swift
struct User: Hashable {
    var id: Int
    var name: String
}

// Automatic synthesis
let user1 = User(id: 1, name: "John")
let user2 = User(id: 2, name: "Jane")
let user3 = User(id: 1, name: "John")

var set: Set<User> = [user1, user2, user3] // Duplicate removed automatically
print(set.count) // 2

// Custom hash implementation
struct Point: Hashable {
    var x: Int
    var y: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
```

---

# **3. Identifiable**

### **What is Identifiable?**

`Identifiable` is a protocol that gives a **unique identity** to an object.

* Commonly used in SwiftUI for lists.
* Requires a property: `id` (usually `UUID` or some unique identifier).

---

### **When to use**

* SwiftUI `List` or `ForEach` requires items to be identifiable.
* Tracking objects in a collection uniquely.

---

### **Example**

```swift
struct User: Identifiable {
    var id: UUID
    var name: String
}

let users = [
    User(id: UUID(), name: "John"),
    User(id: UUID(), name: "Jane")
]

// SwiftUI usage
/*
List(users) { user in
    Text(user.name)
}
*/
```

* You can also use existing property as `id`:

```swift
struct User: Identifiable {
    var id: Int
    var name: String
}
```

---

# **4. Comparable**

### **What is Comparable?**

`Comparable` allows objects to be **ordered**, using `<, <=, >, >=`.

* Requires implementation of the `<` operator.
* Automatically gives access to other comparison operators.

---

### **When to use**

* Sorting arrays of custom types.
* Comparing objects based on some property.

---

### **Example**

```swift
struct User: Comparable {
    var id: Int
    var name: String
    
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.id < rhs.id
    }
}

let users = [
    User(id: 3, name: "Alice"),
    User(id: 1, name: "Bob"),
    User(id: 2, name: "Charlie")
]

let sortedUsers = users.sorted()
for user in sortedUsers {
    print(user.name) // Bob, Charlie, Alice
}
```

---

# **Summary Table**

| Protocol         | Purpose                             | Required      | Common Use Cases                       |
| ---------------- | ----------------------------------- | ------------- | -------------------------------------- |
| **Equatable**    | Compare two objects for equality    | `==`          | Searching, removing duplicates         |
| **Hashable**     | Hashing for collections (Set, Dict) | `hash(into:)` | Dictionary keys, Set elements          |
| **Identifiable** | Unique identity for objects         | `id` property | SwiftUI List/ForEach, tracking objects |
| **Comparable**   | Ordering of objects                 | `<` operator  | Sorting, min/max operations            |

---

✅ **Key Notes:**

* `Hashable` requires `Equatable`.
* `Identifiable` is mostly used in **UI frameworks**.
* `Comparable` is mostly for **sorting or ranking**.
* Swift can often **auto-synthesize** these protocols for structs with compatible properties.

---

If you want, I can also make a **“Swift Protocol Cheat Sheet”** combining **Codable + Equatable + Hashable + Identifiable + Comparable** with **code examples**, perfect for interviews.

Do you want me to make that?

Absolutely! Let’s go through **practical SwiftUI examples** using `Equatable`, `Hashable`, `Identifiable`, and `Comparable` in real SwiftUI contexts. I’ll show **how each protocol is used in lists, views, and state management**.
                                                
---
                                                
# **1. Identifiable in SwiftUI**
                                                
`Identifiable` is **most commonly used in SwiftUI**, especially for `List` and `ForEach`.
                                                
```swift
import SwiftUI
                                                
struct User: Identifiable {
    var id: UUID
    var name: String
}

struct ContentView: View {
    let users = [
        User(id: UUID(), name: "John"),
        User(id: UUID(), name: "Jane"),
        User(id: UUID(), name: "Alice")
    ]
    
    var body: some View {
        List(users) { user in
            Text(user.name)
        }
    }
}
```

✅ **Why:** SwiftUI needs to uniquely identify each row to manage updates efficiently.

---

# **2. Equatable in SwiftUI**

`Equatable` can be used to **optimize view updates** with `EquatableView`. SwiftUI will **skip re-rendering** if the view’s data hasn’t changed.
                                                                                                                    
```swift
struct User: Equatable {
    let id: Int
    let name: String
}

struct UserRow: View, Equatable {
    let user: User
    
    static func == (lhs: UserRow, rhs: UserRow) -> Bool {
        return lhs.user.id == rhs.user.id && lhs.user.name == rhs.user.name
    }
    
    var body: some View {
        Text(user.name)
    }
}

struct ContentView: View {
    @State private var users = [
        User(id: 1, name: "John"),
        User(id: 2, name: "Jane")
    ]
    
    var body: some View {
        List(users, id: \.id) { user in
            UserRow(user: user)
        }
    }
}
```

✅ **Why:** Prevents unnecessary redraws when only some data changes.

---

# **3. Hashable in SwiftUI**

`Hashable` is used when you need **Set collections** or **unique identifiers** in SwiftUI, often with `ForEach`.

```swift
struct User: Hashable, Identifiable {
    var id: UUID
    var name: String
}

struct ContentView: View {
    let users: Set<User> = [
        User(id: UUID(), name: "John"),
        User(id: UUID(), name: "Jane"),
        User(id: UUID(), name: "John") // Duplicate will be ignored
    ]
    
    var body: some View {
        List(Array(users)) { user in
            Text(user.name)
        }
    }
}
```

✅ **Why:** Ensures uniqueness when dealing with sets, which can help remove duplicates automatically.

---

# **4. Comparable in SwiftUI**

`Comparable` is helpful when you want to **sort your data** before displaying in SwiftUI.

```swift
struct User: Comparable, Identifiable {
    var id: Int
    var name: String
    
    static func < (lhs: User, rhs: User) -> Bool {
        lhs.id < rhs.id
    }
}

struct ContentView: View {
    let users = [
        User(id: 3, name: "Alice"),
        User(id: 1, name: "Bob"),
        User(id: 2, name: "Charlie")
    ]
    
    var body: some View {
        List(users.sorted()) { user in
            Text("\(user.id): \(user.name)")
        }
    }
}
```

✅ **Why:** Makes it easy to display sorted lists without extra manual sorting.

---

# **5. Combining Protocols in a SwiftUI Example**

```swift
struct User: Identifiable, Hashable, Comparable {
    var id: Int
    var name: String
    
    static func < (lhs: User, rhs: User) -> Bool {
        lhs.id < rhs.id
    }
}

struct ContentView: View {
    @State private var users: Set<User> = [
        User(id: 3, name: "Alice"),
        User(id: 1, name: "Bob"),
        User(id: 2, name: "Charlie"),
        User(id: 1, name: "Bob") // Duplicate ignored by Set
    ]
    
    var body: some View {
        List(users.sorted()) { user in
            Text("\(user.id): \(user.name)")
        }
    }
}
```

✅ **Explanation:**

* `Identifiable` → Needed for `List`.
* `Hashable` → Needed for `Set` to remove duplicates.
* `Comparable` → Needed for sorting.
                                
---
                              
