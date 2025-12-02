//
//  lazy and computed properties.swift
//  
//
//  Created by Apple on 02/12/25.
//

import Foundation

In Swift, **lazy** and **computed** properties both defer work, but they behave **very differently**. Here's a clear, practical comparison:

---

# 🔥 **Lazy vs Computed Properties — Key Differences**

| Feature                   | **Lazy Property**                                   | **Computed Property**                                                    |
| ------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------ |
| **Storage**               | Stored property (value is saved in memory)          | Not stored (computed every time)                                         |
| **When initialized?**     | First time you access it                            | Never “stored”—value is recalculated on access                           |
| **Can it have a setter?** | Yes, like any stored property                       | Yes, but setter updates something else (not itself)                      |
| **Common use case**       | Heavy initialization or dependent on external state | Value that depends on other properties and should always stay up-to-date |
| **Requires `var`?**       | Yes (because it changes from nil → actual value)    | Yes (because getter might depend on changeable data)                     |
| **Can use `let`?**        | ❌ No                                                | ❌ No                                                                     |
| **Thread-safe?**          | ❌ Not automatically                                 | ✔️ Safe (no internal mutation)                                           |

---

# 📘 **Lazy Property Example**

A lazy property initializes **only once**, the first time you use it.

```swift
class DataLoader {
    lazy var data: [String] = {
        print("Loading data...")
        return ["A", "B", "C"]
    }()
}

let loader = DataLoader()
print("Before accessing data")
print(loader.data) // "Loading data..." printed now
```

🔹 Useful when the property is **expensive** to create (network calls, big arrays, heavy calculations).
🔹 The result stays in memory after the first computation.

---

# 📘 **Computed Property Example**

A computed property recalculates each time it’s accessed.

```swift
struct Rectangle {
    var width: Double
    var height: Double

    var area: Double {
        return width * height
    }
}

var rect = Rectangle(width: 10, height: 5)
print(rect.area)  // 50
rect.width = 20
print(rect.area)  // 100 (recomputed)
```

🔹 Value always reflects **current state**
🔹 No storage—nothing saved to memory

---

# 🚩 **When to Use What**

## ✅ Use **lazy property** when:

* The value is expensive to compute
* The value might not always be needed
* The value does not depend on other fast-changing properties
* You want the value to be computed **once**

Example: loading images, making database queries, creating formatters.

---

## ✅ Use **computed property** when:

* You need a value derived from other properties
* It should always update automatically
* No need to store it

Example: formatting values, lightweight calculations, derived data.

---

# 🧠 Summary

* **Lazy = stored + computed once on demand**
* **Computed = recalculated every time, never stored**
* **Lazy is for heavy work**
* **Computed is for values derived from other state**

---

Why must lazy properties be declared with var and not let?
Answer:
Because their value is not known at initialization time.
let requires an immutable value available at instance initialization, while lazy var starts as “not initialized” and gets assigned later.

struct User {
    var first = "John"
    var last = "Doe"
    
    lazy var fullName: String = {
        print("Computing fullName...")
        return "\(first) \(last)"
    }()
}

var u = User()
print(u.fullName)
u.first = "Jane"
print(u.fullName)

Computing fullName...
John Doe
John Doe


class Rectangle {
    var w = 10
    var h = 20

    lazy var areaLazy: Int = {
        print("Calculating lazy area...")
        return w * h
    }()

    var areaComputed: Int {
        print("Calculating computed area...")
        return w * h
    }
}

let r = Rectangle()
print(r.areaLazy)
print(r.areaLazy)
print(r.areaComputed)
r.w = 20
print(r.areaComputed)
print(r.areaLazy)

Calculating lazy area...
200
200
Calculating computed area...
200
Calculating computed area...
400
200


class Demo {
    init() {
        print("Init Demo")
    }

    lazy var message: String = {
        print("Initializing message...")
        return "Hello"
    }()
}

let d = Demo()
print("Before accessing message")
print(d.message)
print(d.message)


Init Demo
Before accessing message
Initializing message...
Hello
Hello


Lazy Won’t Work with Let Constant

class Example {
    lazy var num = 10
}

let e = Example()
e.num = 20
print(e.num)

20


struct DataHolder {
    lazy var data: Int = {
        print("Loading data...")
        return 5
    }()
}

let obj = DataHolder()
print(obj.data)

Output
❌ This code does NOT compile.
Why?
Because obj is a let struct, and accessing a lazy property mutates the struct.
Lazy structs require the instance to be var.
