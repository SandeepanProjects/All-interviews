//
//  Optional Protocol and Protocol Extension .swift
//  
//
//  Created by Apple on 20/12/25.
//

import Foundation


**diagram comparing Optional Protocols vs Protocol Extensions**

Perfect! Here’s a **diagram-style explanation comparing Optional Protocols vs Protocol Extensions in Swift**, which is very useful for interviews. You can visualize or draw it on a whiteboard.

---

# 🔹 Optional Protocols vs Protocol Extensions

```
               ┌─────────────────────────────┐
               │      Optional Protocol      │
               │        (@objc)             │
               └─────────────┬──────────────┘
                             │
                             ▼
           ┌────────────────────────────────────┐
           │ Must be a class (class-bound)      │
           │ Methods/properties marked optional │
           │ Call via ? (delegate?.method?())  │
           │ Requires Objective-C runtime      │
           │ Cannot be generic                  │
           └────────────────────────────────────┘
                             │
                             ▼
           ┌────────────────────────────────────┐
           │ Example:                            │
           │ @objc protocol MyDelegate {         │
           │   @objc optional func didFinish()  │
           │ }                                  │
           │ delegate?.didFinish?()             │
           └────────────────────────────────────┘

─────────────────────────────────────────────────────────────

               ┌─────────────────────────────┐
               │     Protocol Extension      │
               │       (Pure Swift)          │
               └─────────────┬──────────────┘
                             │
                             ▼
           ┌────────────────────────────────────┐
           │ Works with class, struct, enum     │
           │ Provide default implementation      │
           │ Conforming type can override       │
           │ Can use generics & associated types│
           │ Always callable (no ?)             │
           └────────────────────────────────────┘
                             │
                             ▼
           ┌────────────────────────────────────┐
           │ Example:                            │
           │ protocol Logger {                   │
           │   func logDebug()                   │
           │ }                                   │
           │ extension Logger {                  │
           │   func logDebug() { }              │
           │ }                                   │
           │ let logger: Logger = AppLogger()   │
           │ logger.logDebug()                   │
           └────────────────────────────────────┘
```

---

### ✅ Key Interview Takeaways

1. **Optional Protocols**

   * Use for **Objective-C interop**
   * Only **classes**
   * Call with `?`
   * Not type-safe with generics

2. **Protocol Extensions**

   * Use for **modern Swift**
   * Classes, structs, enums
   * Can override defaults
   * Fully type-safe
   * Supports generics, associated types

---

💡 **Golden line for interview:**

> “Optional protocols are Objective-C compatible and only for classes, whereas protocol extensions provide default implementations in pure Swift and work for any type.”

---

If you want, I can now make an **advanced diagram showing Optional Protocol + Protocol Extension combined with Delegates in a real iOS app**, which is **highly FAANG-interview-friendly**.

Do you want me to make that?


Here’s a **complete, interview-ready guide on Optional Protocols and Protocol Extensions in Swift**, including syntax, use cases, and differences.

---

# 🔹 Optional Protocols in Swift

**Optional protocols** allow a protocol method or property to be **optional**, meaning conforming types **don’t have to implement it**.

> Only available for protocols marked with `@objc`, i.e., **protocols compatible with Objective-C**.

---

## 1️⃣ Syntax

```swift
@objc protocol MyDelegate {
    @objc optional func didFinishTask()
    @objc optional func didFailTask(error: Error)
}
```

### Key points:

* Use `@objc` on the protocol
* Methods or properties must be marked `optional`
* Can only be used by **classes**, not structs or enums

---

## 2️⃣ Using Optional Protocols

```swift
class Worker {
    weak var delegate: MyDelegate?

    func startTask() {
        // Task finished
        delegate?.didFinishTask?()
        // Task failed
        // delegate?.didFailTask?(error: someError)
    }
}

class Manager: MyDelegate {
    func didFinishTask() {
        print("Task completed!")
    }
}

let worker = Worker()
let manager = Manager()
worker.delegate = manager
worker.startTask()  // prints: Task completed!
```

### Notes:

* Use `?` when calling optional methods: `delegate?.didFinishTask?()`
* Only classes can conform (`class` constraint is enforced via `@objc`)

---

## 3️⃣ Limitations

* Only for **class-bound protocols** (`@objc`)
* Cannot have **generic protocols**
* Not pure Swift (depends on Objective-C runtime)
* Optional properties **must be `@objc`** and var

---

# 🔹 Protocol Extensions in Swift

**Protocol extensions** allow you to **provide default implementation** of methods and properties in a protocol.

> This is **pure Swift**, works with structs, classes, and enums.

---

## 1️⃣ Syntax

```swift
protocol Vehicle {
    func start()
    func stop()
}

extension Vehicle {
    func stop() {
        print("Default stop implementation")
    }
}
```

### Usage:

```swift
struct Car: Vehicle {
    func start() {
        print("Car started")
    }
}

let myCar = Car()
myCar.start()  // Car started
myCar.stop()   // Default stop implementation
```

---

## 2️⃣ Key Points

* Provides **default behavior**
* Types conforming to protocol **can override** the default
* Works for **structs, enums, classes**
* No `@objc` required
* Supports **generics** and **associated types**

---

## 3️⃣ Optional Behavior via Protocol Extension

You can mimic “optional” methods without `@objc`:

```swift
protocol Logger {
    func logInfo(_ msg: String)
    func logDebug(_ msg: String)
}

extension Logger {
    func logDebug(_ msg: String) {
        // default empty implementation
    }
}

struct AppLogger: Logger {
    func logInfo(_ msg: String) {
        print("INFO: \(msg)")
    }
}

let logger = AppLogger()
logger.logInfo("App started")   // prints INFO
logger.logDebug("Debug info")   // does nothing (default)
```

✅ Advantages:

* Works with **structs & enums**
* Pure Swift
* No Objective-C dependency
* Safer and more flexible than `@objc optional`

---

## 4️⃣ Optional Protocol vs Protocol Extension

| Feature             | Optional Protocol (`@objc`)    | Protocol Extension (Pure Swift)             |
| ------------------- | ------------------------------ | ------------------------------------------- |
| Availability        | Classes only                   | Classes, structs, enums                     |
| Syntax              | `@objc optional func method()` | Provide default implementation in extension |
| Objective-C runtime | Required                       | Not required                                |
| Generic support     | ❌ Not supported                | ✅ Fully supported                           |
| Calling             | `delegate?.method?()`          | `instance.method()` (always available)      |
| Use Case            | Interoperability with Obj-C    | Modern Swift, type-safe optional behavior   |

---

## 5️⃣ Interview Tip

> Apple & product companies often ask:
> “How do you provide optional behavior in a protocol in Swift?”

**Best answer**:

* **If Obj-C interop needed → use `@objc optional`**
* **Otherwise → protocol extension with default implementation**

---

### Example Summary (All in One)

```swift
@objc protocol OldDelegate {
    @objc optional func oldMethod()
}

protocol NewDelegate {
    func newMethod()
}

extension NewDelegate {
    func newMethod() { print("Default newMethod") }
}

class MyClass: NewDelegate { }

let obj = MyClass()
obj.newMethod() // prints: Default newMethod
```

> Shows **Optional Protocol** vs **Protocol Extension** side by side.

---
