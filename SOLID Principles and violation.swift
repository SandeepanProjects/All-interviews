//
//  SOLID Principles and violation.swift
//  
//
//  Created by Apple on 20/10/25.
//

import Foundation

**SOLID** is an acronym representing five design principles intended to make software designs more understandable, flexible, and maintainable. These principles are especially important in **object-oriented programming (OOP)** but are applicable in other paradigms too.

---

## 🔑 **SOLID Principles Overview**

| Letter | Principle Name                        | Purpose                                             |
| ------ | ------------------------------------- | --------------------------------------------------- |
| S      | Single Responsibility Principle (SRP) | One reason to change                                |
| O      | Open/Closed Principle (OCP)           | Open for extension, closed for modification         |
| L      | Liskov Substitution Principle (LSP)   | Subtypes must be substitutable for their base types |
| I      | Interface Segregation Principle (ISP) | No client should depend on methods it does not use  |
| D      | Dependency Inversion Principle (DIP)  | Depend on abstractions, not concretions             |

---

Now, let's go **one by one**, with **examples in Swift** (using protocols) and show how each can be **violated**.

---

### 1. 🧱 **Single Responsibility Principle (SRP)**

> **Definition**: A class should have **only one reason to change** — i.e., only one job or responsibility.

#### ✅ Good Example (SRP followed):

```swift
protocol ReportFormatter {
    func format(report: String) -> String
}

class PDFReportFormatter: ReportFormatter {
    func format(report: String) -> String {
        return "PDF Formatted Report: \(report)"
    }
}

class ReportPrinter {
    func printReport(formattedReport: String) {
        print(formattedReport)
    }
}
```

* `PDFReportFormatter`: Only formats.
* `ReportPrinter`: Only prints.

#### ❌ Violation Example:

```swift
class ReportManager {
    func generateReport() -> String {
        return "Report Data"
    }

    func formatReport(report: String) -> String {
        return "Formatted: \(report)"
    }

    func printReport(report: String) {
        print("Printing: \(report)")
    }
}
```

* `ReportManager` has **multiple responsibilities** (generate, format, print).
* **SRP violated** — a change in printing logic could impact formatting.

---

### 2. 🚪 **Open/Closed Principle (OCP)**

> **Definition**: Software entities should be **open for extension but closed for modification**.

#### ✅ Good Example (OCP followed):

```swift
protocol DiscountStrategy {
    func apply(to price: Double) -> Double
}

class NoDiscount: DiscountStrategy {
    func apply(to price: Double) -> Double { price }
}

class BlackFridayDiscount: DiscountStrategy {
    func apply(to price: Double) -> Double { price * 0.7 }
}

class Checkout {
    let discount: DiscountStrategy
    init(discount: DiscountStrategy) {
        self.discount = discount
    }

    func finalPrice(for price: Double) -> Double {
        return discount.apply(to: price)
    }
}
```

* New discount types can be added **without modifying** `Checkout`.

#### ❌ Violation Example:

```swift
class Checkout {
    enum DiscountType {
        case none, blackFriday
    }

    func finalPrice(for price: Double, discountType: DiscountType) -> Double {
        switch discountType {
        case .none:
            return price
        case .blackFriday:
            return price * 0.7
        }
    }
}
```

* To add a new discount, you must **modify** the `Checkout` logic.
* **OCP violated**.

---

### 3. 🧬 **Liskov Substitution Principle (LSP)**

> **Definition**: Subtypes must be **substitutable** for their base types.

#### ✅ Good Example (LSP followed):

```swift
protocol Bird {
    func fly()
}

class Sparrow: Bird {
    func fly() {
        print("Sparrow flying")
    }
}
```

* `Sparrow` correctly substitutes `Bird`.

#### ❌ Violation Example:

```swift
class Penguin: Bird {
    func fly() {
        fatalError("Penguins can't fly!")
    }
}
```

* `Penguin` is **not substitutable** — calling `fly()` causes a runtime error.
* **LSP violated**.

🔧 **Fix**:

```swift
protocol Bird {}
protocol FlyingBird: Bird {
    func fly()
}

class Penguin: Bird {}
class Eagle: FlyingBird {
    func fly() {
        print("Eagle flying")
    }
}
```

---

### 4. 🧩 **Interface Segregation Principle (ISP)**

> **Definition**: No client should be forced to depend on **interfaces it does not use**.

#### ✅ Good Example (ISP followed):

```swift
protocol Printer {
    func printDocument()
}

protocol Scanner {
    func scanDocument()
}

class AllInOnePrinter: Printer, Scanner {
    func printDocument() { print("Printing...") }
    func scanDocument() { print("Scanning...") }
}

class SimplePrinter: Printer {
    func printDocument() { print("Printing only") }
}
```

* Clients implement only what they need.

#### ❌ Violation Example:

```swift
protocol Machine {
    func printDocument()
    func scanDocument()
}

class SimplePrinter: Machine {
    func printDocument() { print("Printing...") }
    func scanDocument() {
        fatalError("Cannot scan")
    }
}
```

* `SimplePrinter` is forced to implement `scanDocument()`.
* **ISP violated**.

---

### 5. 🧱 **Dependency Inversion Principle (DIP)**

> **Definition**: High-level modules should not depend on low-level modules; both should depend on **abstractions**.

#### ✅ Good Example (DIP followed):

```swift
protocol Database {
    func save(data: String)
}

class SQLDatabase: Database {
    func save(data: String) {
        print("Saving to SQL: \(data)")
    }
}

class DataManager {
    let db: Database
    init(db: Database) {
        self.db = db
    }

    func storeData(_ data: String) {
        db.save(data: data)
    }
}
```

* `DataManager` depends on abstraction `Database`, not a specific database.

#### ❌ Violation Example:

```swift
class SQLDatabase {
    func save(data: String) {
        print("Saving to SQL: \(data)")
    }
}

class DataManager {
    let db = SQLDatabase()
    
    func storeData(_ data: String) {
        db.save(data: data)
    }
}
```

* `DataManager` is tightly coupled to `SQLDatabase`.
* **DIP violated** — harder to test or switch databases.

---

## 🧾 Summary Table

| Principle | What to do                            | How it's violated                                 |
| --------- | ------------------------------------- | ------------------------------------------------- |
| SRP       | One responsibility per class          | Mixing unrelated logic                            |
| OCP       | Use abstraction for extension         | Modifying existing code to add features           |
| LSP       | Derived types should behave like base | Throwing errors or changing behavior              |
| ISP       | Small, specific interfaces            | Fat protocols forcing unnecessary implementations |
| DIP       | High-level code depends on protocols  | Directly using concrete implementations           |

---

Would you like code examples in another language (like Python, Kotlin, Java)?
