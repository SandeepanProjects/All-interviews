//
//  oops vs pop.swift
//  
//
//  Created by Apple on 20/10/25.
//

import Foundation


difference between **Object-Oriented Programming (OOP)** and **Protocol-Oriented Programming (POP)** is essential because **Swift supports both paradigms**, but leans heavily toward **protocol-oriented programming**.

Let’s break it down.

---

## 🔹 Object-Oriented Programming (OOP) in Swift

**OOP** is a paradigm based on **classes and inheritance**. It models software as a collection of objects with both data and behavior.

### 🔑 Core Concepts:

* **Class**: Blueprint for an object.
* **Inheritance**: Classes can inherit from other classes.
* **Encapsulation**: Hiding data inside classes.
* **Polymorphism**: Subclasses can override methods.
* **Reference Types**: Classes are passed by reference.

### ✅ Example:

```swift
class Animal {
    func speak() {
        print("Animal sound")
    }
}

class Dog: Animal {
    override func speak() {
        print("Bark")
    }
}
```

* `Dog` inherits from `Animal`
* This is classical OOP

---

## 🔹 Protocol-Oriented Programming (POP) in Swift

**POP** is a paradigm where **protocols** (interfaces) are the main tool to define behavior. It encourages using **structs** and **protocol extensions** instead of relying on class inheritance.

Swift's standard library is designed with POP in mind.

### 🔑 Core Concepts:

* **Protocol**: A blueprint of methods and properties.
* **Protocol Extensions**: Provide default implementations.
* **Composition over Inheritance**.
* **Value Types**: Encourages the use of structs (value types).
* **Decoupling**: Promotes modular, testable code.

### ✅ Example:

```swift
protocol Animal {
    func speak()
}

extension Animal {
    func speak() {
        print("Generic animal sound")
    }
}

struct Dog: Animal {
    func speak() {
        print("Bark")
    }
}

let myDog = Dog()
myDog.speak()  // Output: Bark
```

* `Dog` conforms to `Animal` without subclassing.
* No inheritance – just conformance.

---

## 🔄 OOP vs POP: Key Differences

| Feature               | OOP (Object-Oriented)          | POP (Protocol-Oriented)                        |
| --------------------- | ------------------------------ | ---------------------------------------------- |
| **Primary Unit**      | Class                          | Protocol                                       |
| **Code Reuse**        | Inheritance                    | Protocol extensions                            |
| **Type System**       | Reference types                | Value types (structs, enums)                   |
| **Flexibility**       | Less (tight coupling)          | More (loose coupling, composable)              |
| **Testability**       | Harder to mock                 | Easier with protocol-based design              |
| **State Management**  | Shared via reference           | Localized via value types                      |
| **Performance**       | May involve reference overhead | Value types are more efficient                 |
| **Examples in UIKit** | UIViewController, UITableView  | Delegate protocols (e.g., UITableViewDelegate) |

---

## 🧠 When to Use Each?

* Use **OOP** when:

  * You need identity, inheritance, or shared mutable state.
  * Working with legacy UIKit code that expects classes.

* Use **POP** when:

  * You want to write reusable, testable, and flexible code.
  * Working with SwiftUI or building modern Swift codebases.

---

## 🧪 Real-World Example in iOS

Using protocols to abstract dependencies (common in MVVM or Clean Architecture):

```swift
protocol DataService {
    func fetchData() -> [String]
}

class APIService: DataService {
    func fetchData() -> [String] {
        return ["A", "B", "C"]
    }
}

class ViewModel {
    let service: DataService
    
    init(service: DataService) {
        self.service = service
    }

    func load() {
        print(service.fetchData())
    }
}
```

* ViewModel doesn’t care **which** service it uses, only that it conforms to `DataService`.
* Easy to mock in unit tests.

---

## ✅ TL;DR

| Concept              | Object-Oriented Programming | Protocol-Oriented Programming |
| -------------------- | --------------------------- | ----------------------------- |
| Based On             | Classes & Inheritance       | Protocols & Composition       |
| Type                 | Reference (classes)         | Value (structs/enums)         |
| Flexibility          | Rigid hierarchy             | Flexible and modular          |
| Swift Recommendation | Supported                   | Preferred in modern Swift     |

---

Want a hands-on example comparing both side by side?

Perfect — let’s walk through a **side-by-side comparison** of **OOP** vs **POP** with a **real-world iOS-style example**.

---

## 🧩 Scenario

Let’s say we’re building a simple app where a **User** can **log in** using different services (like Google, Facebook, etc.).

---

# 🔷 OOP Approach (Class + Inheritance)

```swift
// Base class
class LoginService {
    func login(user: String) {
        print("Default login for \(user)")
    }
}

// Subclass for Google
class GoogleLoginService: LoginService {
    override func login(user: String) {
        print("Google login for \(user)")
    }
}

// Subclass for Facebook
class FacebookLoginService: LoginService {
    override func login(user: String) {
        print("Facebook login for \(user)")
    }
}

// Using it
let service: LoginService = GoogleLoginService()
service.login(user: "Alice")
```

### 🔍 Pros:

* Simple to understand.
* Inheritance gives reuse.

### ❌ Cons:

* Rigid hierarchy.
* Harder to test/mock.
* Tightly coupled.

---

# 🔶 POP Approach (Protocol + Struct or Class)

```swift
// Define protocol
protocol LoginService {
    func login(user: String)
}

// Google implementation
struct GoogleLoginService: LoginService {
    func login(user: String) {
        print("Google login for \(user)")
    }
}

// Facebook implementation
struct FacebookLoginService: LoginService {
    func login(user: String) {
        print("Facebook login for \(user)")
    }
}

// Using it
let service: LoginService = FacebookLoginService()
service.login(user: "Bob")
```

### 🔍 Pros:

* Flexible and loosely coupled.
* Easier to mock for tests.
* Encourages value types (structs).
* You can swap out implementations at runtime.

### ❌ Cons:

* Requires understanding of protocols and composition.
* Slightly more upfront setup.

---

## 🧪 Bonus: Mocking in Unit Tests (Why POP shines)

### In POP:

```swift
struct MockLoginService: LoginService {
    func login(user: String) {
        print("Mock login for \(user)")
    }
}

let testService = MockLoginService()
testService.login(user: "TestUser")
```

### In OOP:

You’d often need to subclass or override, which can get messy.

---

## ✅ Summary Table

| Feature            | OOP (Classes & Inheritance) | POP (Protocols & Composition)    |
| ------------------ | --------------------------- | -------------------------------- |
| Code Sharing       | Inheritance                 | Protocol Extensions              |
| Testability        | Harder to mock              | Easy with mock structs           |
| Flexibility        | Less (rigid hierarchy)      | High (plug & play)               |
| Reusability        | Subclassing                 | Conforming to multiple protocols |
| Type Preference    | Classes (Reference)         | Structs (Value)                  |
| Preferred by Swift | Supported                   | ✅ Recommended                    |

---

## 🤔 When to Use What?

* **Use OOP** when:

  * You need identity (e.g., `UIViewController`).
  * You’re subclassing UIKit components.

* **Use POP** when:

  * You’re building clean, testable logic.
  * You want to reduce coupling and increase flexibility.
  * You're working with SwiftUI or modern Swift patterns.

---

Multiple inheritance

Swift **doesn’t support multiple inheritance for classes** — and that’s by design. Instead, it offers **protocols and protocol composition** to achieve similar (and often better) flexibility, while avoiding the problems that multiple inheritance can introduce.

---

## 🔍 What is Multiple Inheritance?

**Multiple inheritance** is when a class can inherit from **more than one superclass**.

### 🚫 Example (not allowed in Swift):

```swift
class Animal { }
class CanFly { }

class Bird: Animal, CanFly { }  // ❌ Not allowed in Swift
```

This would raise an error in Swift: **"Class 'Bird' has multiple inheritance"**.

---

## ✅ Why Swift Avoids Multiple Inheritance

### 1. **Avoids the Diamond Problem**

In multiple inheritance, if two parent classes have methods or properties with the same name, the compiler doesn't know which one to inherit.

```text
       A
      / \
     B   C
      \ /
       D
```

If both `B` and `C` inherit from `A` and then `D` inherits from both `B` and `C`, there’s ambiguity:

> Which version of `A`'s properties/methods does `D` use?

### ✅ Swift avoids this by **allowing only single class inheritance**, and instead encouraging:

* **Protocols** (interfaces)
* **Protocol composition**
* **Protocol extensions**

---

### 2. **Encourages Composition Over Inheritance**

Swift’s philosophy prefers **composition** (building types by combining behaviors) over **deep inheritance trees**.

```swift
protocol Flyable {
    func fly()
}

protocol Swimmable {
    func swim()
}

struct Duck: Flyable, Swimmable {
    func fly() { print("Flying") }
    func swim() { print("Swimming") }
}
```

✅ `Duck` conforms to both `Flyable` and `Swimmable`, no inheritance needed.

---

### 3. **Simplifies the Type System**

Multiple inheritance makes type resolution and method dispatch more complex. Swift keeps it simple:

* Only **single inheritance** for classes.
* But allows **multiple protocol conformances**.

This helps with:

* Performance
* Predictability
* Readability

---

### 4. **Swift Has Protocol Extensions**

Swift's **protocol extensions** give you **default method implementations**, which solves one of the main reasons you'd use multiple inheritance in other languages (like C++ or Python).

```swift
protocol Logger {
    func log()
}

extension Logger {
    func log() {
        print("Default log message")
    }
}

struct FileLogger: Logger { }
let logger = FileLogger()
logger.log()  // Prints "Default log message"
```

---

## 🧠 TL;DR

| Feature                         | Swift's Approach                    |
| ------------------------------- | ----------------------------------- |
| Multiple inheritance of classes | ❌ Not allowed                       |
| Reason                          | Avoids ambiguity and complexity     |
| Alternative                     | ✅ Protocols + composition           |
| Protocol extensions             | ✅ Yes, with default implementations |
| Multiple conformances           | ✅ Fully supported                   |

---

If you’re coming from a language like C++, Python, or Java, Swift’s model might seem restrictive at first — but once you embrace **protocol-oriented programming**, you get **the flexibility of multiple inheritance without the headaches**.

Want an example that shows how to **mimic multiple inheritance using protocols**?

Great! Let’s look at a concrete example of how you can **mimic multiple inheritance using protocols** in Swift — which is actually the preferred approach in Swift’s **protocol-oriented programming** model.

---

## 🎯 Goal

Suppose we want a class or struct to have both:

* **Logging** behavior
* **Networking** behavior

In other languages with multiple inheritance, you might do this by inheriting from multiple base classes.

In Swift, we’ll use **multiple protocol conformances + protocol extensions** to achieve the same result.

---

## 🧪 Step-by-Step Example

### 🔹 Step 1: Define Protocols for Behaviors

```swift
protocol Loggable {
    func log(_ message: String)
}

protocol Networkable {
    func fetchData(from url: String)
}
```

### 🔹 Step 2: Provide Default Implementations (Optional)

Using **protocol extensions**:

```swift
extension Loggable {
    func log(_ message: String) {
        print("LOG: \(message)")
    }
}

extension Networkable {
    func fetchData(from url: String) {
        print("Fetching data from \(url)...")
    }
}
```

### 🔹 Step 3: Compose These Behaviors in a Concrete Type

```swift
class DataManager: Loggable, Networkable {
    func performTask() {
        log("Starting task...")
        fetchData(from: "https://api.example.com/data")
        log("Task completed.")
    }
}
```

### 🔹 Step 4: Use It

```swift
let manager = DataManager()
manager.performTask()
```

### 🟢 Output:

```
LOG: Starting task...
Fetching data from https://api.example.com/data...
LOG: Task completed.
```

---

## ✅ What Just Happened?

* `DataManager` didn’t **inherit from multiple classes** — it **conformed to multiple protocols**.
* We **composed** its behavior using **protocols and default implementations**.
* This is Swift's answer to multiple inheritance.

---

## 🧠 Bonus: Protocol Composition in Parameters

You can even **require multiple behaviors** in function parameters using **protocol composition**:

```swift
func startProcess(with component: Loggable & Networkable) {
    component.log("Process started")
    component.fetchData(from: "https://swift.org")
}
```

Now, any type passed to `startProcess(with:)` must conform to **both** `Loggable` and `Networkable`.

---

## 📦 Summary

| Inheritance Approach      | Swift Alternative                 |
| ------------------------- | --------------------------------- |
| Multiple base classes     | ❌ Not allowed                     |
| Multiple protocols        | ✅ Yes (preferred)                 |
| Shared behavior           | ✅ Use protocol extensions         |
| Custom behavior per type  | ✅ Override in conforming types    |
| Composition in parameters | ✅ `SomeProtocolA & SomeProtocolB` |

---
