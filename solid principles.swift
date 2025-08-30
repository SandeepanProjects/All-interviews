//
//  solid principles.swift
//  
//
//  Created by Apple on 30/08/25.
//

import Foundation

The **SOLID principles** are a set of five design principles intended to help developers create more maintainable, scalable, and understandable software. They are particularly useful when writing object-oriented code, but can also be applied in other paradigms. In Swift, these principles are just as relevant, as it supports object-oriented programming.

### 1. **Single Responsibility Principle (SRP)**

A class should have one, and only one, reason to change. In other words, a class should have only one job or responsibility.

#### Example:

Imagine a `UserManager` class that handles both user data management and sending emails. If we want to change how emails are sent, we'd have to modify the `UserManager` class, even though its primary responsibility is to manage user data. This violates SRP.

##### Violating SRP:

```swift
class UserManager {
    func saveUserData(user: User) {
        // Save user data to the database
    }

    func sendEmail(user: User) {
        // Send email to the user
    }
}
```

##### Fix (Applying SRP):

We can split this responsibility into two separate classes:

```swift
class UserManager {
    func saveUserData(user: User) {
        // Save user data to the database
    }
}

class EmailService {
    func sendEmail(user: User) {
        // Send email to the user
    }
}
```

Now, `UserManager` is only responsible for managing user data, and `EmailService` is responsible for sending emails. This way, if we need to change how we send emails, we only need to modify the `EmailService`.

---

### 2. **Open/Closed Principle (OCP)**

Software entities (classes, modules, functions, etc.) should be open for extension but closed for modification. This means that the behavior of a class can be extended without modifying its existing code.

#### Example:

Consider a `Shape` class hierarchy with a method to calculate the area of different shapes. If we want to add new shapes (like a `Triangle`), we should be able to extend the class without modifying the existing code.

##### Violating OCP:

```swift
class AreaCalculator {
    func calculateArea(shape: Shape) -> Double {
        if shape is Circle {
            return 3.14 * (shape as! Circle).radius * (shape as! Circle).radius
        } else if shape is Rectangle {
            return (shape as! Rectangle).width * (shape as! Rectangle).height
        }
        return 0
    }
}
```

This violates the OCP principle, because every time you add a new shape, you have to modify the `AreaCalculator` class.

##### Fix (Applying OCP):

Instead of modifying `AreaCalculator`, we can make each shape responsible for calculating its own area.

```swift
protocol Shape {
    func area() -> Double
}

class Circle: Shape {
    var radius: Double
    init(radius: Double) {
        self.radius = radius
    }
    func area() -> Double {
        return 3.14 * radius * radius
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

class AreaCalculator {
    func calculateArea(shape: Shape) -> Double {
        return shape.area()
    }
}
```

Now, when you add a new shape, you don't need to modify the `AreaCalculator`. You simply implement the `area` method for the new shape.

---

### 3. **Liskov Substitution Principle (LSP)**

Objects of a superclass should be replaceable with objects of a subclass without affecting the correctness of the program. In other words, a subclass should extend the behavior of a superclass without changing its expected behavior.

#### Example:

Consider a `Bird` class and a `Penguin` subclass. The `Bird` class has a method called `fly()`. A `Penguin`, however, can't fly, so overriding the `fly()` method to do something nonsensical would violate LSP.

##### Violating LSP:

```swift
class Bird {
    func fly() {
        // Generic flying behavior
    }
}

class Penguin: Bird {
    override func fly() {
        // Penguins can't fly, this would break LSP
        print("Penguins can't fly!")
    }
}
```

##### Fix (Applying LSP):

Instead of making all birds implement `fly()`, we can introduce a protocol that only flying birds conform to.

```swift
protocol Flyable {
    func fly()
}

class Bird {
    // General bird behavior
}

class Sparrow: Bird, Flyable {
    func fly() {
        // Sparrow flying behavior
    }
}

class Penguin: Bird {
    // Penguin-specific behavior
}
```

Now, `Penguin` doesn't need to implement `fly()`, and we can replace any `Bird` with a `Sparrow` or other flying bird without breaking the program.

---

### 4. **Interface Segregation Principle (ISP)**

Clients should not be forced to depend on interfaces they do not use. This means that rather than having one large interface, we should have smaller, more specific ones.

#### Example:

Imagine a `Worker` protocol with methods for both `work` and `eat`. A robot that implements `Worker` would have to implement `eat()` even though it doesn't need to.

##### Violating ISP:

```swift
protocol Worker {
    func work()
    func eat()
}

class HumanWorker: Worker {
    func work() {
        // Work logic
    }
    
    func eat() {
        // Eating logic
    }
}

class RobotWorker: Worker {
    func work() {
        // Work logic
    }
    
    func eat() {
        // Robots don't eat, so this doesn't make sense
    }
}
```

##### Fix (Applying ISP):

Instead of having a single `Worker` protocol, we can create two smaller protocols.

```swift
protocol Workable {
    func work()
}

protocol Eatable {
    func eat()
}

class HumanWorker: Workable, Eatable {
    func work() {
        // Work logic
    }
    
    func eat() {
        // Eating logic
    }
}

class RobotWorker: Workable {
    func work() {
        // Work logic
    }
}
```

Now, `RobotWorker` doesn't have to implement `eat()`, adhering to the Interface Segregation Principle.

---

### 5. **Dependency Inversion Principle (DIP)**

High-level modules should not depend on low-level modules. Both should depend on abstractions. Furthermore, abstractions should not depend on details. Details should depend on abstractions.

#### Example:

Consider a `ReportGenerator` that directly depends on a specific `PDFExporter`. This violates DIP because the high-level `ReportGenerator` depends on a low-level class (`PDFExporter`).

##### Violating DIP:

```swift
class ReportGenerator {
    let pdfExporter = PDFExporter()
    
    func generateReport() {
        pdfExporter.export()
    }
}

class PDFExporter {
    func export() {
        // Export PDF logic
    }
}
```

##### Fix (Applying DIP):

We can introduce an abstraction (`Exporter` protocol) so that `ReportGenerator` depends on the abstraction, not a specific implementation.

```swift
protocol Exporter {
    func export()
}

class ReportGenerator {
    let exporter: Exporter
    
    init(exporter: Exporter) {
        self.exporter = exporter
    }
    
    func generateReport() {
        exporter.export()
    }
}

class PDFExporter: Exporter {
    func export() {
        // Export PDF logic
    }
}

class CSVExporter: Exporter {
    func export() {
        // Export CSV logic
    }
}
```

Now, `ReportGenerator` depends on the `Exporter` protocol, and we can easily swap out `PDFExporter` with `CSVExporter` or any other future export format.

---

### Conclusion

Applying the SOLID principles in Swift will lead to cleaner, more maintainable code. The key idea behind SOLID is to keep classes and modules focused, extendable, and easy to modify without introducing bugs in existing code. These principles also improve testability, readability, and reusability.
