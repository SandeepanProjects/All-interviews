//
//  common ios.swift
//  
//
//  Created by Apple on 04/11/25.
//

import Foundation

Excellent — this is one of the **core concepts** in Swift property management.
Let’s break down the differences between **stored**, **computed**, and **lazy** properties with examples, use-cases, and memory behavior 👇

---

## 🧩 **1️⃣ Stored Properties**

### 🔹 Definition

A **stored property** is a constant or variable that **stores a value** as part of an instance of a class or struct.

It physically **occupies memory** in the instance.

### 🔹 Syntax

```swift
struct Person {
    var name: String          // stored property
    let birthYear: Int        // stored property (constant)
}

var person = Person(name: "Alice", birthYear: 1995)
print(person.name) // "Alice"
```

### 🔹 Key Points

* They hold **actual data**.
* Can be `var` (mutable) or `let` (immutable).
* Must be initialized before use (either with a default value or in an initializer).
* Only available in **classes and structs** (not enums).

---

## 🧮 **2️⃣ Computed Properties**

### 🔹 Definition

A **computed property** doesn’t store any value.
Instead, it **computes** its value **each time it’s accessed** — using a `get` block, and optionally a `set` block.

### 🔹 Syntax

```swift
struct Rectangle {
    var width: Double
    var height: Double
    
    var area: Double {         // computed property
        return width * height
    }
}
let rect = Rectangle(width: 5, height: 10)
print(rect.area) // 50.0
```

With both getter and setter:

```swift
struct Circle {
    var radius: Double
    
    var diameter: Double {     // computed property
        get {
            return radius * 2
        }
        set {
            radius = newValue / 2
        }
    }
}

var c = Circle(radius: 4)
print(c.diameter) // 8
c.diameter = 10
print(c.radius)   // 5
```

### 🔹 Key Points

* **No stored memory** for the property value — computed on demand.
* Can have only `get` (read-only) or both `get` and `set`.
* Can be used in **classes, structs, and enums**.

---

## 💤 **3️⃣ Lazy Stored Properties**

### 🔹 Definition

A **lazy stored property** is a stored property whose **initial value isn’t calculated until the first time it’s accessed**.

You declare it with the `lazy` keyword.

### 🔹 Syntax

```swift
class DataManager {
    lazy var data = loadData()   // only called when 'data' is first accessed
    
    func loadData() -> [String] {
        print("Loading data...")
        return ["Apple", "Banana", "Cherry"]
    }
}

let manager = DataManager()
print("Before accessing data")   // nothing printed yet
print(manager.data)              // triggers loadData()
```

### 🔹 Key Points

* Must be declared with `var` (cannot be `let`).
* Useful when initialization is **expensive** (e.g., reading from disk, fetching from network).
* Only available in **classes and structs** (not in constants or enums).
* Thread-safety: not guaranteed in multithreaded access (handle carefully).

---

## 🧠 **Summary Table**

| Property Type | Stores Value     | When Initialized  | Computed? | Keyword                  | Example Use                                      |
| ------------- | ---------------- | ----------------- | --------- | ------------------------ | ------------------------------------------------ |
| **Stored**    | ✅ Yes            | At initialization | ❌         | —                        | Basic instance data like `name`, `age`           |
| **Computed**  | ❌ No             | On every access   | ✅         | `var` with `{ get set }` | Derived values like `area`, `fullName`           |
| **Lazy**      | ✅ Yes (deferred) | First access      | ❌         | `lazy var`               | Expensive setup like loading data or image cache |

---

## ⚙️ **Example Combining All Three**

```swift
struct Employee {
    // Stored property
    var hourlyRate: Double
    var hoursWorked: Double
    
    // Computed property
    var salary: Double {
        get { hourlyRate * hoursWorked }
    }
    
    // Lazy property
    lazy var profile: String = {
        print("Generating profile...")
        return "Employee earning \(salary)"
    }()
}

var emp = Employee(hourlyRate: 50, hoursWorked: 160)
print(emp.salary)    // computed instantly (8000)
print(emp.profile)   // triggers lazy property initialization
```

---

✅ **Quick Recap**

* **Stored** → Holds actual data.
* **Computed** → Calculates on demand, doesn’t store.
* **Lazy** → Stored, but initialized only when first accessed.

---

why extensions cannot use stored properties?

Excellent and very common Swift interview question 👏

Let’s go step by step — understanding **why extensions in Swift cannot have stored properties** (and what you can do instead).

---

## 🧩 **1️⃣ What Extensions Are**

An **extension** in Swift lets you:

* Add **new functionality** to an existing type (like methods, computed properties, initializers, etc.).
* You can extend:

  * Classes
  * Structs
  * Enums
  * Protocols

Example:

```swift
extension String {
    var reversedText: String {
        String(self.reversed())
    }
}
print("hello".reversedText)  // "olleh"
```

✅ Works perfectly — we’ve added **behavior**, not stored data.

---

## 🚫 **2️⃣ Why Extensions Can’t Have Stored Properties**

### 🔹 **Reason 1: Memory Layout is Fixed at Compile-Time**

When a type (class, struct, etc.) is compiled, Swift determines:

* How much **memory** each instance will occupy.
* Where each stored property will live in memory.

If extensions could add stored properties, that would **change the memory layout** of the type — but extensions can be added in *different source files* or even *different modules* (like frameworks).

That means the compiler could no longer guarantee:

* The size of the object in memory.
* The position of its existing properties.

So, allowing stored properties in extensions would **break binary compatibility** and Swift’s **type-safety guarantees**.

---

### 🔹 **Reason 2: Extensions Don’t Create a New Type**

Extensions *don’t subclass or redefine* the type — they just “decorate” it with new functionality.

Since they don’t own the type, they can’t modify its **stored data layout** — only its **behavior**.

Think of an extension as adding “computed behavior” on top of an existing object, not changing its structure.

---

### 🔹 **Reason 3: Backward and Binary Compatibility**

Apple’s frameworks (and Swift libraries) rely on strict binary interfaces.
If extensions could modify memory structure, precompiled binaries (apps or libraries) could **crash** when loaded together with new extensions that alter layouts.

---

## 💡 **3️⃣ What You *Can* Do Instead**

You have **alternatives** that achieve the same effect, depending on your use case.

---

### ✅ **Option 1: Use Computed Properties**

You *can* add **computed properties** in extensions, since they don’t store data.

```swift
extension Int {
    var squared: Int {
        return self * self
    }
}
print(4.squared) // 16
```

This adds behavior — not memory.

---

### ✅ **Option 2: Use Associated Objects (for classes only)**

If you *really* need to attach stored-like data to an existing class (e.g., in UIKit), you can use **Objective-C runtime association**.

Example:

```swift
import ObjectiveC

private var key: UInt8 = 0

extension UIView {
    var customTag: String? {
        get {
            return objc_getAssociatedObject(self, &key) as? String
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
```

Now you’ve effectively “added” a stored property to `UIView`!
👉 But this works **only for classes** that inherit from `NSObject` (Objective-C compatible).

---

### ✅ **Option 3: Use Wrapper Types**

Wrap the type in your own struct or subclass that defines the stored properties.

Example:

```swift
struct ExtendedUser {
    var user: User
    var isActive: Bool = false   // new stored property
}
```

This is safe and Swift-native.

---

## 🧠 **4️⃣ Summary**

| Concept                          | Description                                                                      |
| -------------------------------- | -------------------------------------------------------------------------------- |
| **Extensions**                   | Add new behavior (methods, computed properties) to existing types                |
| **Cannot Add Stored Properties** | Because memory layout is fixed and extensions don’t own the type                 |
| **Can Add**                      | Computed properties, methods, convenience initializers, subscripts, nested types |
| **Workarounds**                  | Use computed properties, associated objects (for classes), or wrapper types      |

---

### 🚀 **In One Sentence**

> Extensions in Swift can’t have stored properties because they **don’t change a type’s memory layout** — they only extend its behavior, not its structure.

---

Would you like me to show a **diagram** visualizing this — how memory layout is fixed for a type and why extensions can’t alter it?

