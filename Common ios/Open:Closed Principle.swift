//
//  Open:Closed Principle.swift
//  
//
//  Created by Apple on 30/03/26.
//

import Foundation

Suppose there is a logger class and it currently supports one function to print in console . Let's say I want to add another feature to print remote logging . Explain me what possible way I can do it


This is a classic **design / extensibility** interview question. The key idea is: *how do you extend functionality without breaking existing code?* (👉 **Open/Closed Principle** from SOLID).

Let’s walk through the **possible approaches**, from naive → scalable.

---

# 🔴 1. Naive Approach (Not Recommended)

```swift
class Logger {
    func log(_ message: String) {
        print(message)
    }

    func logToRemote(_ message: String) {
        // API call
    }
}
```

### ❌ Problems:

* Violates **Single Responsibility Principle**
* Every new logging type → modify class
* Becomes messy (file logging, DB logging, etc.)

---

# 🟡 2. Add Flags / Conditions (Still Bad)

```swift
class Logger {
    func log(_ message: String, toRemote: Bool) {
        print(message)

        if toRemote {
            // send to server
        }
    }
}
```

### ❌ Problems:

* Tight coupling
* Hard to test
* Adding more outputs → explosion of conditions

---

# 🟢 3. Protocol-Oriented Approach (Best Practice ✅)

👉 This is the **clean + scalable + interview-friendly solution**

### Step 1: Define a protocol

```swift
protocol LogDestination {
    func log(_ message: String)
}
```

---

### Step 2: Create implementations

```swift
class ConsoleLogger: LogDestination {
    func log(_ message: String) {
        print(message)
    }
}

class RemoteLogger: LogDestination {
    func log(_ message: String) {
        // API call to send logs
    }
}
```

---

### Step 3: Inject into Logger

```swift
class Logger {
    private let destinations: [LogDestination]

    init(destinations: [LogDestination]) {
        self.destinations = destinations
    }

    func log(_ message: String) {
        destinations.forEach { $0.log(message) }
    }
}
```

---

### Usage:

```swift
let logger = Logger(destinations: [
    ConsoleLogger(),
    RemoteLogger()
])

logger.log("Hello World")
```

---

### ✅ Benefits:

* Open for extension, closed for modification
* Easily add:

  * FileLogger
  * DatabaseLogger
* Testable (mock LogDestination)
* Clean Architecture friendly

---

# 🔵 4. Decorator Pattern (Advanced / Interview Bonus ⭐)

If you want to **wrap behaviors dynamically**:

```swift
class BaseLogger: LogDestination {
    func log(_ message: String) {}
}

class ConsoleLogger: BaseLogger {
    override func log(_ message: String) {
        print(message)
    }
}

class RemoteLoggerDecorator: BaseLogger {
    private let wrapped: LogDestination

    init(wrapped: LogDestination) {
        self.wrapped = wrapped
    }

    override func log(_ message: String) {
        wrapped.log(message)
        // send to server
    }
}
```

---

### Usage:

```swift
let logger = RemoteLoggerDecorator(wrapped: ConsoleLogger())
logger.log("Hello")
```

---

# 🟣 5. Using Dependency Injection (Production-Grade)

In real apps (especially iOS with Clean Architecture):

```swift
class Logger {
    private let destinations: [LogDestination]

    init(destinations: [LogDestination]) {
        self.destinations = destinations
    }
}
```

Inject via:

* AppContainer
* ViewModel
* Service layer

---

# 🧠 Interview Summary (What interviewer expects)

If asked this question, say:

> "I would avoid modifying the existing Logger class and instead introduce a protocol like `LogDestination`. Then I would create separate implementations like ConsoleLogger and RemoteLogger and inject them into Logger. This follows the Open/Closed Principle and keeps the system scalable and testable."

---

# ⚡ Bonus: Real-world analogy

Think of **Logger as a dispatcher**:

* It doesn’t care *where logs go*
* It just forwards them

---

# 🚀 Final Recommendation

👉 Use **Protocol + Dependency Injection**

That’s:

* Clean Architecture compliant
* SOLID-friendly
* Highly scalable

---

If you want, I can also show:
✅ SwiftUI + Clean Architecture logger implementation
✅ Async remote logging using `async/await`
✅ Thread-safe logger (important for real apps)

