//
//  enum : struct : class.swift
//  
//
//  Created by Apple on 30/08/25.
//

import Foundation

Great question — knowing **when to use an enum vs a struct or class** is key to writing clean, safe, and idiomatic Swift code.

Let’s break it down by use case, differences, and decision points.

---

## ✅ **Use an `enum` when:**

1. ### You want to **represent a fixed set of choices or states**

   Enums are perfect for defining **finite, well-known options**.

   ```swift
   enum Direction {
       case north, south, east, west
   }
   ```

2. ### You want to **leverage Swift’s powerful pattern matching**

   Enums shine when combined with `switch`, `if case`, etc.

   ```swift
   switch state {
   case .loading: ...
   case .error(let message): ...
   }
   ```

3. ### You need to model **mutually exclusive states**

   Only one case can be active at a time.

   ```swift
   enum Result {
       case success(data: String)
       case failure(error: Error)
   }
   ```

4. ### You want **type safety over stringly-typed code**

   Enums prevent bugs caused by mistyped strings like `"light"` vs `"Light"`.

   ```swift
   enum Theme: String {
       case light, dark
   }
   ```

5. ### You’re modeling **recursive data**

   Such as expression trees or file systems (with `indirect`).

---

## ✅ **Use a `struct` when:**

1. ### You need to model a **simple data type** with properties.

   For example, a user profile or product info.

   ```swift
   struct User {
       let name: String
       let age: Int
   }
   ```

2. ### You want **value semantics** (copy-on-write behavior)

   Value types are copied on assignment, useful for safer concurrency.

3. ### You don’t need inheritance or reference sharing.

---

## ✅ **Use a `class` when:**

1. ### You need **reference semantics**

   Multiple parts of your app need to share and mutate the same object.

   ```swift
   class ViewModel {
       var isLoading: Bool = false
   }
   ```

2. ### You need to use **inheritance or polymorphism**

   Classes allow one type to inherit from another (enums and structs do not).

3. ### You’re working with APIs that require **reference types**

   UIKit, Combine, and many Apple APIs rely on classes.

---

## 🧠 Key Differences Cheat Sheet

| Feature                  | `enum`                         | `struct`                    | `class`                     |
| ------------------------ | ------------------------------ | --------------------------- | --------------------------- |
| Represents               | One-of-many states             | Group of related properties | Group of related properties |
| Inheritance              | ❌ No                           | ❌ No                        | ✅ Yes                       |
| Value/reference          | ✅ Value type                   | ✅ Value type                | ❌ Reference type            |
| Mutually exclusive cases | ✅ Yes                          | ❌ No                        | ❌ No                        |
| Associated values        | ✅ Yes                          | ❌ No (use properties)       | ❌ No (use properties)       |
| Pattern matching         | ✅ Yes (powerful with `switch`) | ❌ No                        | ❌ No                        |
| Recursive data support   | ✅ Yes (`indirect`)             | ⚠️ Manual                   | ⚠️ Manual                   |

---

## ✅ When to Choose `enum` over `struct`/`class`

Use an `enum` when:

* You’re modeling **a state machine**, like `.idle`, `.loading`, `.success`, `.error`.
* You want **explicit control over branching logic** with `switch`.
* Your data has **clearly distinct forms**, and only one can exist at a time.
* You want **exhaustiveness checking** — compiler forces you to handle every case.
* You need to **prevent invalid combinations** of values.

---

## 🧠 Real-World Examples:

* `Result<T, Error>` → `enum` (because it's one of two states)
* `User`, `Product`, `Book` → `struct` (holds data, no identity)
* `ViewModel`, `Service`, `Coordinator` → `class` (identity + shared state)

---

Let me know if you'd like decision flowcharts or real examples from UIKit/SwiftUI!
