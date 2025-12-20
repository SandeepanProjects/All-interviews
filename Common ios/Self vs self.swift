//
//  Self vs self.swift
//  
//
//  Created by Apple on 20/12/25.
//

import Foundation

Here’s a **clear, interview-ready explanation of `Self` vs `self` in Swift**, including **usage, differences, and examples**. This is a common question in Swift interviews.

---

# 🔹 `Self` vs `self` in Swift

| Keyword | What it Refers To                                               | Usage Example                        | Notes                                                                      |
| ------- | --------------------------------------------------------------- | ------------------------------------ | -------------------------------------------------------------------------- |
| `self`  | Refers to the **current instance** of a class, struct, or enum  | `self.name = name`                   | Lowercase `self`, used **inside instance methods or closures**             |
| `Self`  | Refers to the **type itself** (class, struct, or protocol type) | `static func make() -> Self { ... }` | Uppercase `Self`, used in **protocols, generics, and type-level contexts** |

---

## 1️⃣ `self` (instance-level)

* Refers to the **current object instance**
* Required when **parameter names shadow property names**
* Required in **closures** to avoid retain cycles (with `[weak self]`)

### Example 1: Resolving name conflict

```swift
struct Person {
    var name: String

    init(name: String) {
        self.name = name // distinguishes property from parameter
    }
}
```

### Example 2: Closures & retain cycles

```swift
class ViewController {
    var titleText = "Hello"

    func configureButton() {
        button.action = { [weak self] in
            self?.titleText = "Clicked"
        }
    }
}
```

✅ `self` is **mandatory inside closures** when capturing `self`.

---

## 2️⃣ `Self` (type-level)

* Refers to the **current type** rather than an instance
* Often used in **protocols** or **factory methods**
* Uppercase `Self` is **dynamic**, resolves to the conforming type

### Example 1: Protocol with `Self`

```swift
protocol Copyable {
    func copy() -> Self
}

struct Document: Copyable {
    var content: String
    func copy() -> Self {
        return Document(content: content) // returns same type
    }
}
```

✅ `Self` ensures the **returned type matches the conforming type**, even in structs or classes.

### Example 2: Type-level factory

```swift
class Vehicle {
    class func create() -> Self {
        return self.init() // returns the actual subclass type
    }

    required init() {}
}

class Car: Vehicle {}

let car = Car.create() // type is Car, not Vehicle
```

* `Self` allows **polymorphic factory methods**
* Works with `required init()` to ensure correct type

---

## 3️⃣ Summary of Differences

| Feature       | `self`                                          | `Self`                                                       |
| ------------- | ----------------------------------------------- | ------------------------------------------------------------ |
| Refers to     | Instance of the type                            | The type itself                                              |
| Case          | Lowercase                                       | Uppercase                                                    |
| Common use    | Access properties, methods, capture in closures | Protocol requirements, factory methods, generic return types |
| Required when | Name shadowing, closures                        | Type-level return or dynamic type resolution                 |
| Example       | `self.name = name`                              | `func copy() -> Self`                                        |

---

### Interview Tip

> If asked: *“What’s the difference between `Self` and `self`?”*
> ✅ Answer in two sentences:
>
> * "`self` refers to the current instance, used inside methods or closures."
> * "`Self` refers to the current type, used in protocols, generics, or factory methods to return the conforming type."

---

If you want, I can make a **diagram showing `self` vs `Self` in instance vs type contexts**, which is very handy for **FAANG interviews**.

Do you want me to make that diagram?
