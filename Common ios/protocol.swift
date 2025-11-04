//
//  protocol.swift
//  
//
//  Created by Apple on 07/08/25.
//

import Foundation

Great! Let’s go through these protocol and POP questions one by one with clear explanations and Swift code examples. I’ll keep it practical so you can use these in an interview.

---

### 1. What is a protocol in Swift? How is it different from an interface in other languages?

**Answer:**
A protocol in Swift defines a blueprint of methods, properties, and other requirements that suit a particular task or piece of functionality. Types (classes, structs, enums) conform to protocols by implementing these requirements.

Unlike interfaces in some languages (which are often class-only), Swift protocols can be adopted by value types like structs and enums, allowing for more flexible and safe designs.

**Example:**

```swift
protocol Drivable {
    func drive()
}

struct Car: Drivable {
    func drive() {
        print("Car is driving")
    }
}
```

---

### 2. What is Protocol-Oriented Programming (POP)? How is it different from Object-Oriented Programming (OOP)?

**Answer:**
POP is a programming paradigm that uses protocols to define interfaces and protocol extensions to provide default behavior. It promotes composition over inheritance, encouraging flexible, reusable, and decoupled code.

OOP focuses on class inheritance hierarchies and shared behavior through subclassing, which can lead to rigid and tightly coupled designs.

**Example:**

```swift
protocol CanFly {
    func fly()
}

extension CanFly {
    func fly() {
        print("Flying...")
    }
}

struct Bird: CanFly {}
let bird = Bird()
bird.fly() // Uses default implementation
```

---

### 3. What are protocol extensions? How do they work?

**Answer:**
Protocol extensions allow you to provide default implementations of methods or computed properties in protocols. Types conforming to the protocol automatically gain these implementations unless they provide their own.

**Example:**

```swift
protocol Greetable {
    func greet()
}

extension Greetable {
    func greet() {
        print("Hello!")
    }
}

struct Person: Greetable {}

let p = Person()
p.greet()  // Prints "Hello!"
```

---

### 4. Can structs or enums adopt protocols? Why is this useful?

**Answer:**
Yes! Structs and enums can conform to protocols. This allows value types to participate in polymorphism and abstraction, enabling safer and more predictable code since value types avoid issues like shared mutable state that can occur with classes.
---

### Why is this useful?

* **Polymorphism with value types:** Unlike many languages where only classes can implement interfaces, Swift allows value types (structs and enums) to conform to protocols. This means you get polymorphism **without** needing inheritance or reference types.
* **Safety & performance:** Structs and enums are value types, which means they are copied when passed around. This avoids shared mutable state bugs common in classes.
* **Flexibility:** You can write generic code that works with any type conforming to a protocol, whether it’s a class, struct, or enum.

---

### Example:

```swift
protocol Describable {
    func describe() -> String
}

struct User: Describable {
    let name: String
    func describe() -> String {
        return "User named \(name)"
    }
}

enum Status: Describable {
    case success
    case failure(String)
    
    func describe() -> String {
        switch self {
        case .success:
            return "Success"
        case .failure(let message):
            return "Failure: \(message)"
        }
    }
}

let user = User(name: "Alice")
print(user.describe())  // Output: User named Alice

let status = Status.failure("Network error")
print(status.describe())  // Output: Failure: Network error
```

---

So yes, structs and enums adopting protocols is a key feature of Swift’s design and makes your code more modular and safer!

Want me to show you how this plays with protocol extensions or generics?

Great! Let’s explore how structs and enums adopting protocols work with **protocol extensions** and **generics**. This will help you see how Swift leverages protocol-oriented programming for clean, reusable code.

---

### 1. Protocol Extensions with Structs and Enums

You can add **default implementations** to protocol methods using **protocol extensions**. Types conforming to the protocol get these implementations automatically unless they provide their own.

#### Example:

```swift
protocol Describable {
    func describe() -> String
}

extension Describable {
    func describe() -> String {
        return "This is something describable."
    }
}

struct User: Describable {
    let name: String
    // No need to implement describe() here; default is used.
}

enum Status: Describable {
    case success, failure

    func describe() -> String {
        switch self {
        case .success: return "Success!"
        case .failure: return "Failure!"
        }
    }
}

let user = User(name: "Alice")
print(user.describe())  // Output: This is something describable.

let status = Status.success
print(status.describe())  // Output: Success!
```

**Explanation:**

* `User` uses the default implementation from the extension.
* `Status` provides its own custom implementation.

---

### 2. Generics with Protocol Constraints

You can write generic functions or types that work with any type conforming to a protocol.

#### Example:

```swift
func printDescription<T: Describable>(_ item: T) {
    print(item.describe())
}

let user = User(name: "Bob")
let status = Status.failure

printDescription(user)   // Prints default description
printDescription(status) // Prints custom description
```

---

### 3. Generic Collections with Protocols

You can also create generic containers constrained to protocol types.

```swift
struct Box<T: Describable> {
    var item: T
    func printItemDescription() {
        print(item.describe())
    }
}

let userBox = Box(item: User(name: "Charlie"))
userBox.printItemDescription()  // Prints default description
```

---

### Summary:

* **Protocol extensions** let you provide default behavior for structs, enums, and classes.
* **Generics** allow writing flexible, reusable code constrained by protocol conformance.
* Together, they form the backbone of Swift’s protocol-oriented programming paradigm.

---

---

### 5. What are associated types in protocols?

**Answer:**
Associated types define a placeholder type within a protocol that gets specified by the conforming type. This allows protocols to be generic-like.

**Example:**

```swift
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
    var count: Int { items.count }
    subscript(i: Int) -> Int { items[i] }
}
```

---

### 6. How do protocols help in dependency injection and testing?

**Answer:**
By coding to protocols rather than concrete implementations, you can inject dependencies that conform to protocols. This makes it easy to swap out real objects for mocks or stubs during testing.

---

### 7. Explain protocol composition and when you would use it.

**Answer:**
Protocol composition lets you require a type to conform to multiple protocols at once using `&`.

**Example:**

```swift
protocol Drivable {
    func drive()
}

protocol Refuelable {
    func refuel()
}

func operate(vehicle: Drivable & Refuelable) {
    vehicle.drive()
    vehicle.refuel()
}
```

Use it when a function or variable needs multiple capabilities.

---

### 8. What is the difference between class-bound protocols and regular protocols?

**Answer:**
Class-bound protocols use the `AnyObject` or `class` keyword to restrict adoption to classes only. This is useful when you need reference semantics or want to hold weak references to prevent retain cycles.

---

### 9. How does protocol inheritance work?

**Answer:**
Protocols can inherit from other protocols to build upon requirements.

**Example:**

```swift
protocol Vehicle {
    func drive()
}

protocol FlyingVehicle: Vehicle {
    func fly()
}

struct Drone: FlyingVehicle {
    func drive() { print("Driving") }
    func fly() { print("Flying") }
}
```

---

### 10. Explain the difference between optional and required protocol methods.

**Answer:**
Optional protocol methods are only available in protocols marked with `@objc` and are used primarily for interoperability with Objective-C. These methods do not have to be implemented.

Required methods are those that must be implemented by conforming types and are the default in Swift protocols.
                                                                                                            
Certainly! Here’s a detailed explanation of **Optional Protocols** in Swift:
                                                                                                                
                                                                                                                ---
                                                                                                                
### What is an Optional Protocol?
                                                                                                            
An **Optional Protocol** is a protocol where some of its methods or properties are **optional** for conforming types to implement. This means the conforming type **can choose whether or not** to implement those methods or properties.

---

### Why are Optional Protocols used?

* Optional protocol methods are especially useful when you want to provide **flexible APIs** where some functionality is not mandatory.
* This is common in **delegation patterns**, where the delegate may implement only the methods it cares about.

---

### How to Declare Optional Protocols in Swift?

* Optional protocol requirements are **only available in protocols marked with `@objc`**.
* Because of `@objc`, only **classes** (reference types) can adopt these protocols. This means protocols with optional requirements must inherit from `AnyObject` or use the `class` keyword to limit adoption to classes.
* This feature is designed for **Objective-C interoperability**, as Objective-C protocols support optional methods natively.
                                    
                                    ---
                                    
### Syntax Example:
                                        
                                        ```swift
@objc protocol DownloadDelegate: AnyObject {
    @objc optional func downloadDidStart()
    @objc optional func downloadDidFinish()
    func downloadFailed()  // required method
}

class Downloader: DownloadDelegate {
    func downloadFailed() {
        print("Download failed.")
    }
    
    func downloadDidStart() {
        print("Download started.")  // This method is optional to implement
    }
}
```

* Here, `downloadDidStart` and `downloadDidFinish` are optional methods.
* The class `Downloader` implements `downloadDidStart` and the required `downloadFailed`.
* It **can skip** implementing `downloadDidFinish`.

---

### How to Call Optional Methods?

Since optional methods might not be implemented, you must safely call them using optional chaining:

```swift
var delegate: DownloadDelegate?

delegate?.downloadDidStart?()
delegate?.downloadDidFinish?()
```

Notice the **double question marks**:

* The first `?` unwraps the optional delegate itself.
* The second `?` unwraps the optional method.

---

### Limitations of Optional Protocols:

* Only available on **class-bound protocols** (`@objc` protocols).
* Not available for structs or enums.
* Less type safe than Swift’s usual protocol methods because calls are optional and checked at runtime.
* Less idiomatic in pure Swift — prefer protocol extensions and default implementations if you don’t need Objective-C interoperability.
                        
                        ---
                        
### Alternative in Pure Swift:
                            
If you want optional-like behavior in Swift without `@objc`, use **protocol extensions** to provide default implementations:
                            
                            ```swift
protocol DownloadDelegate {
    func downloadDidStart()
    func downloadDidFinish()
    func downloadFailed()
}

extension DownloadDelegate {
    func downloadDidStart() { }  // default empty implementation
    func downloadDidFinish() { } // default empty implementation
}

class Downloader: DownloadDelegate {
    func downloadFailed() {
        print("Download failed.")
    }
    // downloadDidStart and downloadDidFinish are optional to implement due to default empty implementations
}
```

---

### Summary:

| Aspect           | Optional Protocols (`@objc`)                | Protocol Extensions (Swift)                    |
| ---------------- | ------------------------------------------- | ---------------------------------------------- |
| Availability     | Only in `@objc` class-bound protocols       | Pure Swift protocols                           |
| Conforming Types | Classes only                                | Classes, structs, enums                        |
| Optional Methods | Declared with `@objc optional`              | Default implementations via protocol extension |
| Runtime Safety   | Optional chaining needed (runtime check)    | Compile-time safety                            |
| Use Case         | Interop with Objective-C, delegate patterns | Pure Swift, safer and more flexible            |

---

Would you like me to help you prepare a concise answer or practice some code examples for interviews?


---

Would you like me to role-play a mock interview to practice your answers or provide more complex examples and explanations on any of these?
