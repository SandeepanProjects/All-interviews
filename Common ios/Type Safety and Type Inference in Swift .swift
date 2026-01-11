//
//  Type Safety and Type Inference in Swift .swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

**Type safety** and **type inference** are two of Swift’s core design pillars. Together, they give you **compile-time correctness** *without* forcing verbose type annotations.

---

# 1️⃣ Type Safety in Swift

### What “Type Safe” Means

Swift ensures that:

* A value’s **type is known at compile time**
* You **cannot mix incompatible types**
* Invalid operations are **caught before runtime**

Example:

```swift
let count: Int = 5
count = "five"   // ❌ Compile-time error
```

This eliminates entire classes of bugs common in loosely typed languages.

---

## Key Type Safety Features

### 1. Strong Typing

Once a variable has a type, it cannot change.

```swift
var total = 10      // Int
total = 20          // OK
total = 20.5        // ❌
```

---

### 2. Optionals (Null Safety)

Swift **forces you to handle absence explicitly**.

```swift
var name: String? = nil
print(name.count)   // ❌
```

Correct handling:

```swift
if let name = name {
    print(name.count)
}
```

This prevents `null` dereference crashes.

---

### 3. Exhaustive Switching

```swift
enum State {
    case loading, success, failure
}

switch state {
case .loading:
case .success:
case .failure:
}
```

Compiler enforces completeness → safer state handling.

---

### 4. Generics with Constraints

```swift
func max<T: Comparable>(_ a: T, _ b: T) -> T {
    return a > b ? a : b
}
```

Type-safe abstraction without runtime casting.

---

### 5. Protocol-Oriented Safety

```swift
protocol Payable {
    func pay()
}

func process(_ item: Payable) {
    item.pay()
}
```

No need for type checks or casting.

---

# 2️⃣ Type Inference in Swift

### What Is Type Inference?

Swift **infers types automatically** from context, reducing verbosity.

```swift
let name = "Alice"        // String inferred
let numbers = [1, 2, 3]   // [Int]
```

The compiler still knows exact types internally.

---

## Where Swift Infers Types

### 1. Variables & Constants

```swift
let pi = 3.14   // Double
```

---

### 2. Closures

```swift
let doubled = numbers.map { $0 * 2 }
```

No need to write:

```swift
{ (x: Int) -> Int in x * 2 }
```

---

### 3. Generic Specialization

```swift
let set: Set = [1, 2, 3]
```

Compiler infers `Set<Int>`.

---

### 4. Return Types (Often)

```swift
func square(_ x: Int) -> Int {
    x * x
}
```

---

# 3️⃣ Type Safety + Type Inference Together

Swift combines:

* **Strict compile-time checks**
* **Minimal syntax noise**

Example:

```swift
let result = fetchUser()?.profile?.name?.uppercased()
```

This is:

* Fully type-checked
* Null-safe
* Concise

---

# 4️⃣ When to Be Explicit

Type inference is powerful—but not magic.

### Be explicit when:

* Public APIs
* Complex generics
* Compiler errors are unclear
* Performance-sensitive code

```swift
let cache: [String: User] = [:]
```

---

# 5️⃣ Performance Implications

* Type safety = **zero runtime cost**
* Type inference happens **at compile time**
* No dynamic dispatch unless explicitly used

---

# Interview-Ready Summary

> “Swift is strongly type-safe, catching invalid operations at compile time, and uses powerful type inference to reduce boilerplate. You get safety without sacrificing readability or performance.”

---

# Key Takeaway

> **Swift makes illegal states unrepresentable—without making code verbose.**

If you want:

* Comparison with Kotlin / TypeScript
* How type inference affects compile times
* Advanced generics & associated types
* Common pitfalls with inference
