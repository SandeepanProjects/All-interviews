//
//  Dependency injection and dependency inversion.swift
//  
//
//  Created by Apple on 18/09/25.
//

import Foundation

Sure! Let's break down **Dependency Injection (DI)** and **Dependency Inversion Principle (DIP)** in the context of Swift with **clear explanations and code samples**.

---

## 🧩 1. Dependency Injection (DI)

**Definition**:
**Dependency Injection** is a technique where an object’s dependencies are provided from the outside rather than the object creating them itself.

### 🔧 Why use DI?

* Makes code more modular and testable.
* Encourages separation of concerns.
* Easier to substitute mock or fake dependencies for testing.

### 🧪 Example without DI (bad practice):

```swift
class Engine {
    func start() {
        print("Engine started")
    }
}

class Car {
    private let engine = Engine() // Car creates its own dependency

    func drive() {
        engine.start()
        print("Car is driving")
    }
}
```

In this example, `Car` directly depends on a specific implementation of `Engine`. This makes it hard to test or replace `Engine`.

---

### ✅ Example with DI (good practice):

```swift
class Engine {
    func start() {
        print("Engine started")
    }
}

// Car now gets its dependency injected from the outside
class Car {
    private let engine: Engine

    init(engine: Engine) {
        self.engine = engine
    }

    func drive() {
        engine.start()
        print("Car is driving")
    }
}
```

### 🔍 Usage:

```swift
let engine = Engine()
let car = Car(engine: engine)
car.drive()
```

Now, you can easily inject a **MockEngine** for testing.

---

## 📐 2. Dependency Inversion Principle (DIP)

**Definition**:
DIP is one of the SOLID principles. It says:

> **"High-level modules should not depend on low-level modules. Both should depend on abstractions."**

> **"Abstractions should not depend on details. Details should depend on abstractions."**

### 🛑 Without DIP (tight coupling):

```swift
class GasEngine {
    func start() {
        print("Gas engine started")
    }
}

class Car {
    private let engine = GasEngine()

    func drive() {
        engine.start()
        print("Car is driving")
    }
}
```

Here, `Car` is tightly coupled with `GasEngine`. You can’t switch to a `ElectricEngine` easily.

---

### ✅ With DIP (good design):

1. Create a protocol (abstraction).
2. Depend on the protocol, not the concrete implementation.

```swift
// Abstraction
protocol Engine {
    func start()
}

// Low-level modules
class GasEngine: Engine {
    func start() {
        print("Gas engine started")
    }
}

class ElectricEngine: Engine {
    func start() {
        print("Electric engine started silently")
    }
}

// High-level module
class Car {
    private let engine: Engine // Depends on abstraction

    init(engine: Engine) {
        self.engine = engine
    }

    func drive() {
        engine.start()
        print("Car is driving")
    }
}
```

### 🔍 Usage:

```swift
let gasCar = Car(engine: GasEngine())
gasCar.drive()

let electricCar = Car(engine: ElectricEngine())
electricCar.drive()
```

---

## ✅ Summary

| Concept              | Key Idea                                                                 | Benefit                     |
| -------------------- | ------------------------------------------------------------------------ | --------------------------- |
| Dependency Injection | Inject dependencies from the outside instead of creating them internally | Loose coupling, testability |
| Dependency Inversion | Depend on abstractions, not concrete implementations                     | Flexibility, extensibility  |

---

Would you like a version using Swift protocols for unit testing (e.g. with mock engines)?

Great! Let's enhance the previous example using **Swift protocols and mocks** for **unit testing** to show **Dependency Injection** + **Dependency Inversion** in a testable setup.
                                                    
---
                                                    
## 🧪 Goal
                                                    
We’ll build:
                                                        
1. An abstract `Engine` protocol.
2. Two real implementations: `GasEngine`, `ElectricEngine`.
3. A `MockEngine` used only for unit tests.
4. A `Car` class that depends only on `Engine` (protocol).
5. A unit test that verifies `Car.drive()` calls `engine.start()`.
                                                    
---
                                                    
## ✅ 1. Define the `Engine` Protocol (Abstraction)
                                                    
```swift
protocol Engine {
    func start()
}
```

---

## ✅ 2. Real Implementations

```swift
class GasEngine: Engine {
    func start() {
        print("Gas engine started")
    }
}

class ElectricEngine: Engine {
    func start() {
        print("Electric engine started silently")
    }
}
```

---

## ✅ 3. The High-Level Module: `Car`

```swift
class Car {
    private let engine: Engine
    
    init(engine: Engine) {
        self.engine = engine
    }
    
    func drive() {
        engine.start()
        print("Car is driving")
    }
}
```

This is where **Dependency Injection** and **Dependency Inversion** meet:

* `Car` doesn't know or care what kind of engine it has.
* It just needs something that conforms to `Engine`.

---

## 🧪 4. Mocking for Unit Tests
                        
                        Now let’s write a mock class to simulate the engine in tests.
                        
                        ```swift
                        class MockEngine: Engine {
    var didStart = false
    
    func start() {
        didStart = true
        print("MockEngine start called")
    }
}
```

---

## ✅ 5. Unit Test Example

```swift
func testCarDrivesAndStartsEngine() {
    let mockEngine = MockEngine()
    let car = Car(engine: mockEngine)
    
    car.drive()
    
    assert(mockEngine.didStart == true, "Expected engine to start when driving")
}
```

### Output:

```
MockEngine start called
Car is driving
✅ Test passed!
```

> In real apps, you'd use a testing framework like **XCTest** instead of `assert`.

---

## 📌 Summary of Benefits

| Technique                                   | Benefit                           |
| ------------------------------------------- | --------------------------------- |
| `protocol Engine`                           | Allows different types of engines |
| `init(engine:)`                             | Dependency Injection              |
| `MockEngine`                                | Enables unit testing              |
| `Car` depends on `Engine` (not `GasEngine`) | Dependency Inversion Principle    |

---

