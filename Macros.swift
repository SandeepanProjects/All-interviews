//
//  Macros.swift
//  
//
//  Created by Apple on 12/10/25.
//

import Foundation

In Swift, **macros** are a powerful new feature introduced in **Swift 5.9** and expanded in **Swift 6**, allowing you to **generate or transform code at compile time**.

Think of macros as tools that **let you write code that writes code**—with better performance and safety than traditional runtime solutions like reflection.

---

## 🔧 What is a Macro in Swift?

A **macro** is a compile-time construct that performs code generation or modification. Swift currently supports **three types** of macros:

1. **Freestanding macros** – standalone expressions, attributes, or declarations
2. **Attached macros** – "attached" to declarations like `@MyMacro` on a function or type
3. **Expression macros** – transform expressions at compile time

---

## 📌 Why use macros?

* **Avoid boilerplate code**
* **Improve performance** (code generated at compile-time, not runtime)
* **Make APIs cleaner**
* **Enable domain-specific DSLs**

---

## 🧪 Example 1: Freestanding Macro (`#stringify`)

Swift includes a built-in macro `#stringify(expr)`, which returns a tuple with the expression and its string form:

```swift
let a = 10
let result = #stringify(a + 5)

print(result)  // prints: (value: 15, code: "a + 5")
```

---

## 🧩 Example 2: Custom Macro – `@CodingKeys`

Let’s say you have this:

```swift
struct Person: Codable {
    var fullName: String
    var age: Int
}
```

Normally, you'd have to manually write a `CodingKeys` enum if the JSON keys don’t match the property names.

With macros, you could write:

```swift
@AddCodingKeys
struct Person: Codable {
    var fullName: String
    var age: Int
}
```

### This could expand to:

```swift
struct Person: Codable {
    var fullName: String
    var age: Int

    enum CodingKeys: String, CodingKey {
        case fullName
        case age
    }
}
```

> ⚠️ You’d define `@AddCodingKeys` as an **attached macro**.

---

## 🛠️ How to Define Your Own Macro

To define macros, you need to:

1. Create a macro target in your Swift Package (using `Macro` module type)
2. Use **SwiftSyntax** to read and transform source code
3. Expose it via `@attached(...)` or `#freestanding(...)`

### Example: A simple macro that auto-generates `description`

Let’s define `@AutoDescription` that adds a `description` property to any struct:

```swift
@AutoDescription
struct User {
    var name: String
    var age: Int
}
```

This could expand to:

```swift
struct User: CustomStringConvertible {
    var name: String
    var age: Int

    var description: String {
        return "User(name: \(name), age: \(age))"
    }
}
```

> Behind the scenes, this macro uses the syntax tree of `User`, finds all properties, and builds the string accordingly.

---

## 🆕 What’s New in Swift 6 Macros?

Swift 6 adds:

* **Expression macros as default arguments**
* **@DebugDescription** macro (built-in for debugging custom types)
* **Improved macro expansion debugging** in Xcode
* **Macros that can add conformances** (`@Codable`, `@Sendable` helpers)

---

## ✅ Benefits

* Eliminates repetitive code
* Encourages DRY (Don't Repeat Yourself)
* Compile-time safety
* Easier debugging (you can view macro expansions in Xcode)

---

## ❗ Requirements

* Swift 5.9+ for basic macros
* Swift 6+ for advanced macro features
* Macros must be in **Swift Packages** (Xcode currently doesn’t support defining them directly in app targets)

---

Would you like to walk through how to write your first macro from scratch, or explore more built-in macro examples like `@Observable`, `@Preview`, etc.?
