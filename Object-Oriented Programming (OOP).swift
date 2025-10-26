//
//  Object-Oriented Programming (OOP).swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Absolutely! Let’s break down **Object-Oriented Programming (OOP) in Swift** in a clear, structured way with examples. Swift supports the main OOP concepts: **Encapsulation, Inheritance, Polymorphism, and Abstraction**.

---

## 1️⃣ What is OOP?

OOP is a programming paradigm that uses **“objects”** to model real-world entities.
Objects encapsulate **data (properties)** and **behavior (methods)**.

In Swift, **classes** and **structures** are the main building blocks, but OOP is usually demonstrated with **classes** because they support inheritance.

---

## 2️⃣ Four Main OOP Principles

### **a) Encapsulation**

* **Definition:** Wrapping data (properties) and behavior (methods) together, restricting direct access to some parts.
* **Swift Feature:** Access control (`private`, `fileprivate`, `internal`, `public`)

```swift
class BankAccount {
    private var balance: Double = 0.0
    
    func deposit(amount: Double) {
        guard amount > 0 else { return }
        balance += amount
    }
    
    func getBalance() -> Double {
        return balance
    }
}

let account = BankAccount()
account.deposit(amount: 100)
print(account.getBalance()) // 100
// account.balance = 500 -> Error: balance is private
```

✅ Encapsulation keeps data safe from **unauthorized access**.

---

### **b) Inheritance**

* **Definition:** A class can inherit properties and methods from another class.
* **Swift Feature:** Use `class Child: Parent { ... }`

```swift
class Vehicle {
    var currentSpeed = 0.0
    
    func description() -> String {
        return "Moving at \(currentSpeed) km/h"
    }
}

class Car: Vehicle {
    var gear = 1
    
    override func description() -> String {
        return super.description() + " in gear \(gear)"
    }
}

let car = Car()
car.currentSpeed = 60
car.gear = 3
print(car.description()) // Moving at 60.0 km/h in gear 3
```

✅ Inheritance allows **code reuse** and **hierarchical modeling**.

---

### **c) Polymorphism**

* **Definition:** Same interface, different implementations.
* **Types in Swift:**

  * **Compile-time (method overloading)**
  * **Runtime (method overriding)**

```swift
class Animal {
    func sound() {
        print("Some sound")
    }
}

class Dog: Animal {
    override func sound() {
        print("Woof!")
    }
}

class Cat: Animal {
    override func sound() {
        print("Meow!")
    }
}

let animals: [Animal] = [Dog(), Cat()]
for animal in animals {
    animal.sound()
}
// Output:
// Woof!
// Meow!
```

✅ Polymorphism lets you **treat different objects uniformly** but behave differently at runtime.

---

### **d) Abstraction**

* **Definition:** Hiding implementation details and showing only functionality.
* **Swift Feature:** Use **protocols** and **abstract classes** (via protocols + class constraints).

```swift
protocol Shape {
    func area() -> Double
}

class Circle: Shape {
    var radius: Double
    init(radius: Double) { self.radius = radius }
    
    func area() -> Double {
        return .pi * radius * radius
    }
}

class Rectangle: Shape {
    var width: Double
    var height: Double
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    
    func area() -> Double {
        return width * height
    }
}

let shapes: [Shape] = [Circle(radius: 5), Rectangle(width: 4, height: 6)]
for shape in shapes {
    print(shape.area())
}
```

✅ Abstraction **hides implementation** and exposes only the interface.

---

## 3️⃣ Putting It All Together

```swift
protocol Vehicle {
    func start()
}

class Car: Vehicle {
    var brand: String
    var speed: Double = 0.0
    
    init(brand: String) { self.brand = brand }
    
    func start() {
        print("\(brand) car started")
    }
    
    func accelerate(by value: Double) {
        speed += value
        print("\(brand) car speed: \(speed) km/h")
    }
}

let myCar: Vehicle = Car(brand: "Tesla")
myCar.start() // Tesla car started
// myCar.accelerate(by: 20) -> Not allowed because 'myCar' is typed as Vehicle
```

* **Encapsulation:** `speed` is internal, can be controlled via methods.
* **Inheritance:** Could extend `Car` to `ElectricCar`.
* **Polymorphism:** `Vehicle` interface allows handling different vehicles.
* **Abstraction:** Only exposes `start()` method via `Vehicle`.

---

### ✅ Summary

| OOP Principle | Swift Example                                   |
| ------------- | ----------------------------------------------- |
| Encapsulation | `private`/`fileprivate` properties              |
| Inheritance   | `class Car: Vehicle {}`                         |
| Polymorphism  | Overriding methods, protocol-based polymorphism |
| Abstraction   | Protocols to hide implementation details        |

---

If you want, I can make a **diagram showing all four OOP principles in Swift with a Car/Vehicle example**, which makes it super easy to visualize.

Do you want me to do that?

Ah! This is a common question in Swift and many modern languages. Let’s break it down carefully.

---

## 1️⃣ What is Multiple Inheritance?

**Multiple inheritance** means a class can inherit from **more than one superclass**:

```text
class A { ... }
class B { ... }
class C: A, B { ... } // Multiple inheritance
```

Some languages allow this (like C++), but Swift **does not**.

---

## 2️⃣ Why Swift Doesn’t Allow Multiple Inheritance

### **a) Diamond Problem**

The **diamond problem** occurs when two superclasses have the **same method or property**:

```text
    A
   / \
  B   C
   \ /
    D
```

* Class `D` inherits from both `B` and `C`.
* Both `B` and `C` inherit from `A`.
* If `D` calls a method from `A`, which path should it take?
* Resolving this ambiguity is **complex and error-prone**.

Swift avoids this problem by **not supporting multiple inheritance**.

---

### **b) Simplifies Language Design**

* Single inheritance keeps the **class hierarchy clear and predictable**.
* Avoids **ambiguities in memory layout, method dispatch, and property overrides**.

---

### **c) Swift Provides Alternatives**

1. **Protocols (Interfaces)** – Swift uses **protocols** to achieve similar functionality:

```swift
protocol Flyable {
    func fly()
}

protocol Swimmable {
    func swim()
}

class Duck: Flyable, Swimmable {
    func fly() { print("Duck is flying") }
    func swim() { print("Duck is swimming") }
}
```

✅ Duck can **“inherit behavior” from multiple sources”** via protocols without multiple inheritance.

2. **Protocol Extensions** – Protocols can provide **default method implementations**:

```swift
protocol Runnable {
    func run()
}

extension Runnable {
    func run() { print("Running...") }
}

class Athlete: Runnable { }

let athlete = Athlete()
athlete.run() // Running...
```

* This allows code reuse **without the complexity of multiple inheritance**.

---

## 3️⃣ Summary

| Concept              | Swift Approach                                  |
| -------------------- | ----------------------------------------------- |
| Multiple inheritance | ❌ Not allowed                                   |
| Reason               | Avoids diamond problem and ambiguity            |
| Alternative          | ✅ Protocols + Protocol Extensions               |
| Code reuse           | ✅ Achieved via protocol default implementations |

---

### ✅ Takeaway

Swift avoids multiple inheritance **to keep code safe and predictable**.

* Use **single class inheritance** for shared state/implementation.
* Use **protocols** for shared behavior or capabilities.

---
