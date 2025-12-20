//
//  Variadic Function.swift
//  
//
//  Created by Apple on 20/12/25.
//

import Foundation

**diagram showing how variadic, generics, and protocol types interact**

Great! Here’s a **diagram-style explanation of how Variadic Functions, Generics, and Protocols interact in Swift**, perfect for interviews. I’ll describe it clearly so you can visualize or even draw it on a whiteboard.

---

# 🔹 Diagram: Variadic + Generics + Protocols

```
                 ┌─────────────────────────────┐
                 │        Function Call        │
                 │ sumItems(items: 1,2,3)     │
                 └─────────────┬──────────────┘
                               │
                               ▼
                 ┌─────────────────────────────┐
                 │   Variadic Parameter `T...` │
                 │   Internally: Array [T]     │
                 └─────────────┬──────────────┘
                               │
                               ▼
                 ┌─────────────────────────────┐
                 │       Generic Type T        │
                 │ Flexible type decided at    │
                 │ compile-time (Int, Double) │
                 └─────────────┬──────────────┘
                               │
                               ▼
                 ┌─────────────────────────────┐
                 │  Protocol Constraint (Opt)  │
                 │   T: Summable / Printable  │
                 │  Restricts allowed types    │
                 └─────────────────────────────┘
```

---

## How to Read It (Step-by-Step)

1. **Function Call**

   * Pass any number of arguments: `sumItems(items: 1,2,3)`
2. **Variadic Parameter**

   * Swift converts all arguments into an **array `[T]`**
3. **Generic Type**

   * Swift infers `T` based on arguments (`Int` in this example)
4. **Protocol Constraint**

   * Ensures `T` conforms to the protocol (`Summable`) so you can perform operations like `+`
5. **Inside Function**

   * Iterate over the array and perform operations safely

---

### Example Recap:

```swift
protocol Summable {
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Int: Summable {}
extension Double: Summable {}

func sumItems<T: Summable>(items: T...) -> T {
    var total = items.first ?? T.self.init()
    for item in items.dropFirst() {
        total = total + item
    }
    return total
}

sumItems(items: 1,2,3)       // 6
sumItems(items: 1.1, 2.2, 3.3) // 6.6
```

* `items` → `[T]` → `Int` or `Double`
* Generic + Protocol ensures **type-safe addition**
* Variadic allows **any number of arguments**

---

### Interview Tip:

> Draw this diagram on a whiteboard when asked:
> “Explain variadic functions with generics and protocols in Swift.”
> It clearly shows **function call → array → generic → protocol constraint → operation**.

---



explain **Variadic Functions with Generics and Protocols**, which is a **common advanced Swift interview topic**.

Do you want me to do that next?

Here’s a **detailed explanation of Variadic Functions with Generics and Protocols in Swift**, which is an **advanced topic often asked in interviews**:

---

# 🔹 Variadic Functions with Generics in Swift

A **variadic generic function** lets you accept **zero or more arguments of any type** while still keeping **type safety**.

---

## 1️⃣ Basic Generic Variadic Function

```swift
func printItems<T>(items: T...) {
    for item in items {
        print(item)
    }
}
```

### Usage:

```swift
printItems(items: 1, 2, 3)           // works with Int
printItems(items: "a", "b", "c")     // works with String
printItems(items: 1.1, 2.2, 3.3)     // works with Double
```

✅ Internally, `items` is `[T]`.

---

## 2️⃣ Generic Constraint with Protocols

You can **limit the types** using a protocol:

```swift
protocol Summable {
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Int: Summable { }
extension Double: Summable { }

func sumItems<T: Summable>(items: T...) -> T {
    var total = items.first ?? T.self.init()
    for item in items.dropFirst() {
        total = total + item
    }
    return total
}
```

### Usage:

```swift
sumItems(items: 1, 2, 3)       // 6
sumItems(items: 1.1, 2.2, 3.3) // 6.6
// sumItems(items: "a", "b")   // ❌ Error, String does not conform to Summable
```

✅ This shows **how to combine variadic + generics + protocol constraints**.

---

## 3️⃣ Variadic Function with Multiple Generic Parameters

```swift
func combine<T, U>(firsts: T..., seconds: U...) -> [(T, U)] {
    var result: [(T, U)] = []
    for (f, s) in zip(firsts, seconds) {
        result.append((f, s))
    }
    return result
}
```

### Usage:

```swift
combine(firsts: 1, 2, 3, seconds: "a", "b", "c")
// [(1, "a"), (2, "b"), (3, "c")]
```

✅ Useful for **pairing multiple lists in a type-safe way**.

---

## 4️⃣ Variadic Protocol Example

Sometimes you want a **variadic function to accept any type conforming to a protocol**:

```swift
protocol Printable {
    func printValue()
}

extension Int: Printable {
    func printValue() { print(self) }
}

extension String: Printable {
    func printValue() { print(self) }
}

func printAll(items: Printable...) {
    for item in items {
        item.printValue()
    }
}

printAll(items: 1, "Hello", 42)
// prints: 1, Hello, 42
```

✅ This shows **protocol-based polymorphism** in variadic functions.

---

## 5️⃣ Interview Tips

1. **Always mention:**

   * Variadic parameters are **arrays internally**
   * Only **one variadic parameter** per function
   * Must be **last parameter**

2. **Combine with generics and protocols** for:

   * Type safety
   * Code reusability
   * Advanced Swift interviews

3. **Common trick question:**

   * Can a function have **two variadic parameters**?
     ❌ No, only one is allowed.

---

### Summary

* **Basic Variadic Function** → handles multiple values of same type
* **Generic Variadic Function** → handles multiple values of any type
* **Generic + Protocol** → restricts allowed types while keeping flexibility

> **Golden interview line:**
> “A variadic parameter is internally an array. By combining it with generics and protocols, we can write flexible, type-safe, reusable functions.”

---


Here’s a **complete, interview-ready explanation of Variadic Functions in Swift**, including syntax, usage, rules, and examples:

---

# 🔹 Variadic Function in Swift

A **variadic function** is a function that can accept **zero or more values of the same type** as input.
Instead of passing a fixed number of arguments, you can pass **any number of arguments**.

---

## 1️⃣ Syntax

Use `...` after the parameter type to indicate it’s **variadic**:

```swift
func sum(numbers: Int...) -> Int {
    var total = 0
    for number in numbers {
        total += number
    }
    return total
}
```

---

## 2️⃣ Usage

```swift
let result1 = sum(numbers: 1, 2, 3, 4, 5)  // 15
let result2 = sum(numbers: 10, 20)         // 30
let result3 = sum(numbers: )               // 0
```

✅ You can pass **any number of arguments**, including none.

---

## 3️⃣ Important Rules

1. **Only one variadic parameter is allowed per function**

   * Must be **the last parameter**:

```swift
func log(message: String, values: Int...) { } // ✅
func log(values: Int..., message: String) { } // ❌ Error
```

2. Variadic parameters are treated as **arrays inside the function**:

```swift
func greet(names: String...) {
    print("Hello, \(names)") // names is [String]
}
```

3. Can be combined with **regular parameters**:

```swift
func multiply(factor: Int, numbers: Int...) -> [Int] {
    return numbers.map { $0 * factor }
}

multiply(factor: 2, numbers: 1, 2, 3) // [2, 4, 6]
```

4. Variadic + Default Parameters:

```swift
func greet(greeting: String = "Hello", names: String...) {
    for name in names {
        print("\(greeting), \(name)!")
    }
}

greet(names: "Alice", "Bob")             // "Hello, Alice!" "Hello, Bob!"
greet(greeting: "Hi", names: "Charlie")  // "Hi, Charlie!"
```

---

## 4️⃣ Use Cases

* Logging or debug functions
* Mathematical operations (sum, average)
* Building strings (concatenation)
* Any function where the **number of arguments can vary**

---

## 5️⃣ Variadic Function vs Array Parameter

* **Variadic:** can call like `sum(numbers: 1,2,3)`
* **Array:** must call like `sum(numbers: [1,2,3])`

```swift
func sum(numbers: [Int]) -> Int { ... }   // takes an array
func sum(numbers: Int...) -> Int { ... }   // takes multiple Ints
```

✅ Variadic is syntactic sugar for array arguments.

---

### Interview Tip

> Always mention: **“A variadic parameter is internally an array, must be the last parameter, and only one per function.”**

---
