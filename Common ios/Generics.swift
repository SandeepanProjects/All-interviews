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


In an iOS interview, when it comes to **Generics**, interviewers typically want to gauge your understanding of how generics work in Swift and how they are used to write type-safe, reusable, and flexible code. Here are some common interview questions you might encounter:

### 1. **What are Generics in Swift?**

* **Purpose**: To test your basic understanding of generics in Swift.
* **What to answer**: Generics allow you to write flexible, reusable functions and types that can work with any type, while still maintaining type safety. They are defined using angle brackets (`< >`) and can be applied to functions, methods, classes, structs, and enums.

### 2. **How do you define a generic function?**

* **Purpose**: To test if you can apply generics in practical scenarios.
* **What to answer**: You would define a generic function by placing a type placeholder within angle brackets in the function's declaration.

  ```swift
  func swap<T>(a: inout T, b: inout T) {
      let temp = a
      a = b
      b = temp
  }
  ```

  The type placeholder `T` allows the function to work with any data type.

### 3. **What are constraints in generics, and how do they work?**

* **Purpose**: To test your understanding of generic constraints and how to limit the types that can be used with generics.
* **What to answer**: Constraints allow you to specify that a generic type must conform to a certain protocol, class, or type. For example:

  ```swift
  func printDescription<T: CustomStringConvertible>(item: T) {
      print(item.description)
  }
  ```

  This ensures that only types that conform to `CustomStringConvertible` can be passed into `printDescription`.

### 4. **What is the difference between a generic function and a non-generic function?**

* **Purpose**: To check your understanding of the benefits and differences between generic and non-generic functions.
* **What to answer**: A non-generic function works with specific types, while a generic function can work with any type. The key benefit of generics is that it allows you to write reusable code without sacrificing type safety.

### 5. **Can you explain the concept of Generic Types (like generic classes and structs)?**

* **Purpose**: To test your knowledge of how generics can be applied to data types such as classes and structs.
* **What to answer**: You can define a generic class or struct by using a type placeholder. For example:

  ```swift
  struct Box<T> {
      var value: T
  }
  let intBox = Box(value: 5) // T is inferred to be Int
  let stringBox = Box(value: "Hello") // T is inferred to be String
  ```

  This allows `Box` to hold any type of value while ensuring type safety.

### 6. **What is the difference between `Any` and `AnyObject` in Swift when working with generics?**

* **Purpose**: To assess your knowledge of Swift's type system and how `Any` and `AnyObject` interact with generics.
* **What to answer**:

  * `Any` can represent any type, including function types, structs, enums, etc.
  * `AnyObject` is used specifically for class types (objects that inherit from `NSObject` or any class).
    Example:

  ```swift
  var obj: Any = 42 // can hold any type
  var objClass: AnyObject = SomeClass() // only holds class objects
  ```

### 7. **What is the purpose of `associatedtype` in protocols, and how does it relate to generics?**

* **Purpose**: To check if you are familiar with advanced concepts like associated types in protocols.
* **What to answer**: `associatedtype` allows you to define a placeholder for a type in a protocol, and this type is specified when the protocol is adopted. It is often used with generics to make protocols more flexible and reusable.

  ```swift
  protocol Container {
      associatedtype Item
      var items: [Item] { get }
      mutating func addItem(item: Item)
  }
  ```

### 8. **What are type constraints and why are they important in generics?**

* **Purpose**: To test your understanding of how constraints restrict the range of types that can be used with generics.
* **What to answer**: Constraints help enforce that a generic type must conform to a certain protocol, superclass, or other conditions. This ensures that the type can perform the necessary operations.

  ```swift
  func findMax<T: Comparable>(a: T, b: T) -> T {
      return a > b ? a : b
  }
  ```

### 9. **What are the limitations of using generics in Swift?**

* **Purpose**: To test your ability to recognize the limitations or drawbacks of using generics.
* **What to answer**:

  * You cannot instantiate a generic type with a specific type at runtime (e.g., `T` cannot be a dynamic type).
  * There are some performance concerns in certain cases where generics might introduce overhead due to type erasure.
  * You cannot use `==` to compare two values of a generic type unless you add constraints to ensure that the type conforms to `Equatable`.

### 10. **What is type erasure in Swift and how does it relate to generics?**

* **Purpose**: To see if you understand the concept of type erasure in Swift, especially in the context of generics.
* **What to answer**: Type erasure is a technique used to hide the specific type of a generic and provide a more general type. This is often used in situations where you want to work with heterogeneous collections of generic types or when working with protocols.
  Example:

  ```swift
  protocol SomeProtocol {
      func doSomething()
  }

  struct Box<T: SomeProtocol> {
      let item: T
  }

  class TypeErasedBox {
      let _doSomething: () -> Void

      init<T: SomeProtocol>(_ box: Box<T>) {
          _doSomething = box.item.doSomething
      }

      func doSomething() {
          _doSomething()
      }
  }
  ```

### 11. **Can you explain how generics help with code reuse and maintainability?**

* **Purpose**: To assess your understanding of the benefits of generics in real-world application development.
* **What to answer**: Generics enable you to write code that works with any type while maintaining type safety. This reduces redundancy because you can use the same function or type for multiple data types without having to write specific code for each one. This leads to better code reuse and maintainability.

### 12. **What are some real-world scenarios where you would use generics in iOS development?**

* **Purpose**: To check if you can apply generics to real-world problems.
* **What to answer**: Some examples:

  * Implementing reusable data structures like `Queue`, `Stack`, or `LinkedList`.
  * Creating generic network API services that can fetch data for any model type.
  * Writing utility functions like sorting, filtering, or mapping that work with any collection type (e.g., arrays, sets).

---

Understanding **Generics** deeply, including **protocols with associated types**, **type constraints**, and **type erasure**, is essential for writing reusable and efficient code in Swift.
