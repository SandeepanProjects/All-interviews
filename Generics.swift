//
//  Generics.swift
//  
//
//  Created by Apple on 07/08/25.
//

import Foundation

Absolutely! Here’s a detailed explanation for each question about generics in iOS (Swift):

---

### 1. What are generics? Why are they used?

**Explanation:**
Generics are a feature of Swift that allows you to write flexible, reusable functions and types that can work with any data type. Instead of writing multiple versions of the same code for different types, generics let you write one version that works with any type, while maintaining type safety.

**Benefits:**

* **Code reusability:** Write once, use with any type.
* **Type safety:** The compiler checks the types at compile-time, reducing runtime errors.
* **Abstraction:** They hide type details, focusing on what the code does rather than the exact data type.

---

### 2. How do generics work in Swift?

**Explanation:**
Swift uses angle brackets `<>` to define generic types or functions. Inside the brackets, you specify placeholder types (often named `T`, `U`, `V`, but can be anything) that get replaced with actual types when used.

**Example:**

```swift
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}
```

Here, `T` is a placeholder type. This function works with any type because the compiler replaces `T` with the actual type when you call the function.

Generics can be applied to:

* Functions
* Classes
* Structs
* Enums
* Protocols (using associated types)

---

### 3. What is the difference between generics and type casting?

**Explanation:**

| Aspect           | Generics                    | Type Casting                          |
| ---------------- | --------------------------- | ------------------------------------- |
| **When checked** | Compile-time                | Runtime                               |
| **Type safety**  | Guaranteed                  | Risk of runtime failure if cast fails |
| **Usage**        | Abstracts over types safely | Converts type to another type         |
| **Example**      | `func swap<T>(...)`         | `as?`, `as!` casting operators        |

**Generics** allow writing code that works with any type safely and the compiler ensures correctness. **Casting** involves converting types at runtime and may fail or crash if the cast is invalid.

---

### 4. Can you write a generic function/class?

**Generic Function Example:**

```swift
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}
```

**Generic Class Example (Stack):**

```swift
class Stack<T> {
    private var items = [T]()
    
    func push(_ item: T) {
        items.append(item)
    }
    
    func pop() -> T? {
        return items.popLast()
    }
}
```

This `Stack` can hold elements of any type.

---

### 5. What are associated types in protocols? How do they relate to generics?

**Explanation:**
Associated types are placeholders declared inside protocols, representing a type that is used by the protocol but is not specified until the protocol is adopted.

```swift
protocol Container {
    associatedtype Item
    func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}
```

When a type conforms to this protocol, it defines what `Item` actually is. This allows protocols to be generic-like but with flexibility for the conforming type.

---

### 6. What is type constraint in generics?

**Explanation:**
Type constraints restrict the types you can use with generics. They ensure that the generic type conforms to a specific protocol or inherits from a certain class.

**Syntax:**

```swift
func someFunction<T: Numeric>(value: T) {
    // T must conform to Numeric protocol
}
```

This means `T` can only be a type that supports numeric operations, e.g., `Int`, `Double`, etc.

---

### 7. Can you explain variance and how it relates to generics?

**Explanation:**
Variance describes how subtyping between more complex types relates to subtyping between their component types:

* **Covariance:** If `B` is a subtype of `A`, then `Container<B>` is a subtype of `Container<A>`. (e.g., arrays are covariant in many languages)
* **Contravariance:** If `B` is a subtype of `A`, then `Container<A>` is a subtype of `Container<B>`.
* **Invariance:** No subtyping relationship.

Swift’s generics are **invariant**, meaning `Array<Dog>` is not a subtype of `Array<Animal>`, even if `Dog` is a subtype of `Animal`.

---

### 8. How do generics improve performance and type safety compared to using `Any`?

**Explanation:**
`Any` can hold any type but loses type information, requiring runtime casting which can be unsafe and slow.

Generics keep type information at compile time, avoiding casting overhead and improving safety by catching type errors early.

---

### 9. Explain generic subscripts or extensions.

**Generic Subscript Example:**

```swift
struct GenericCollection<T> {
    var items: [T]
    
    subscript(index: Int) -> T {
        return items[index]
    }
}
```

You can also extend generic types with extra functionality:

```swift
extension Stack {
    func peek() -> T? {
        return items.last
    }
}
```

---

### 10. What are some real-world use cases of generics in iOS development?

* **Collections:** `Array<T>`, `Dictionary<Key, Value>`
* **Result Type:** `Result<Success, Failure>` for handling success or error cases
* **Networking:** Parsing JSON into generic models
* **Reusable UI components:** Like generic table view data sources or cells
* **Dependency Injection containers** and service locators

---

If you'd like, I can provide code examples or help you practice answers for any of these topics!

Associated Types in Protocols
This shows how you can create a generic-like protocol with an associated type.
protocol Container {
    associatedtype Item
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

struct IntStack: Container {
    var items = [Int]()
    
    mutating func append(_ item: Int) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> Int {
        return items[i]
    }
}


Type Constraints
You can restrict generics to types that meet certain requirements.

func add<T: Numeric>(_ a: T, _ b: T) -> T {
    return a + b
}

print(add(3, 5))        // 8
print(add(3.5, 2.5))    // 6.0

Generics vs Any
Using Any loses type safety:

var items: [Any] = []
items.append(5)
items.append("Hello")

for item in items {
    if let number = item as? Int {
        print("Number: \(number)")
    } else if let text = item as? String {
        print("String: \(text)")
    }
}

With generics, you keep type safety and avoid casting:

struct Box<T> {
    let value: T
}

let intBox = Box(value: 5)
// intBox.value is guaranteed to be Int

