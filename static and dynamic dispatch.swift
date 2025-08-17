//
//  static and dynamic dispatch.swift
//  
//
//  Created by Apple on 07/08/25.
//

import Foundation

Sure! Let's break down the **difference between static and dynamic dispatch** in iOS, especially in the context of **Swift** and **Objective-C**.

---

### 🚀 **Overview**

**Dispatch** refers to how a program decides **which method implementation to call** at runtime or compile time.

---

## ✅ **Static Dispatch**

### 🔹 What is it?

* Method calls are **resolved at compile time**.
* The compiler knows exactly which function to call.
* It's **faster** because it avoids runtime lookups.

### 🔹 Example in Swift:

```swift
struct Dog {
    func speak() {
        print("Woof")
    }
}

let dog = Dog()
dog.speak()  // Static dispatch
```

### 🔹 Used in:

* Structs
* Enums
* Final classes
* Non-overridden methods

---

## 🔄 **Dynamic Dispatch**

### 🔹 What is it?

* Method calls are **resolved at runtime**.
* Uses a lookup table (like the Objective-C **runtime's method dispatch table**).
* It's **slower** but allows **polymorphism** and **method overriding**.

### 🔹 Example in Swift:

```swift
class Animal {
    func speak() {
        print("Animal sound")
    }
}

class Dog: Animal {
    override func speak() {
        print("Woof")
    }
}

let animal: Animal = Dog()
animal.speak()  // Dynamic dispatch (runtime decides to call Dog's speak)
```

### 🔹 Used in:

* Classes with overridden methods
* Methods marked with `@objc` (bridging to Objective-C)
* Protocols with class-bound types and dynamic behavior

---

## ⚖️ Comparison Table

| Feature          | Static Dispatch               | Dynamic Dispatch                      |
| ---------------- | ----------------------------- | ------------------------------------- |
| Resolution time  | Compile time                  | Runtime                               |
| Speed            | Faster                        | Slower                                |
| Flexibility      | Less flexible                 | More flexible (supports polymorphism) |
| Used in          | Structs, enums, final methods | Classes, overridden methods, @objc    |
| Runtime overhead | None                          | Yes (due to method lookup)            |

---

### 💡 Extra: Swift Keywords

| Keyword   | Effect                                        |
| --------- | --------------------------------------------- |
| `final`   | Prevents overriding → enables static dispatch |
| `@objc`   | Enables dynamic dispatch via Obj-C runtime    |
| `dynamic` | Forces dynamic dispatch in Swift              |

---

### ✅ Summary

* Use **static dispatch** for performance when you don't need polymorphism (e.g. in value types like structs).
* Use **dynamic dispatch** when you need polymorphism, subclassing, or interoperability with Objective-C.

Let me know if you want a visual or code demo!

Great! Let’s walk through a **visual + code demo** to clearly illustrate the difference between **static** and **dynamic dispatch** in Swift.
                                
---
                                
## 🧪 **Example Scenario**: Animal Sounds
                                
We'll create an `Animal` and a `Dog`, both with a `speak()` method.
                                
---
                                
### 🧱 **1. Static Dispatch Example** (Using `struct` – resolved at compile time)
                                
```swift
struct StaticDog {
    func speak() {
        print("Woof! (Static)")
    }
}

let dog = StaticDog()
dog.speak()
```

✅ This will always print:

```
Woof! (Static)
```

**Why?**

* `struct` doesn’t support inheritance or method overriding.
* The compiler knows exactly which `speak()` to call.
* → **STATIC dispatch**.

---

### 🔄 **2. Dynamic Dispatch Example** (Using `class` and method overriding – resolved at runtime)

```swift
class Animal {
    func speak() {
        print("Generic animal sound")
    }
}

class Dog: Animal {
    override func speak() {
        print("Woof! (Dynamic)")
    }
}

let animal: Animal = Dog()
animal.speak()
```

✅ This will print:

```
Woof! (Dynamic)
```

**Why?**

* Even though the variable is of type `Animal`, the actual object is a `Dog`.
* The method is overridden, so at **runtime**, Swift figures out that it should call `Dog`'s version.
* → **DYNAMIC dispatch**.

---

### 🎯 Want to Force Dynamic Dispatch in Swift?

You can use `@objc dynamic`:

```swift
class Cat: NSObject {
    @objc dynamic func meow() {
        print("Meow! (Forced Dynamic)")
    }
}
```

✅ This ensures the method is always dynamically dispatched using the Objective-C runtime.

---

## 🔍 **Visual Summary**

```
┌────────────┐
│  Static    │     (struct / final class)
│  Dispatch  │────► Compiler decides at build time
└────────────┘

┌────────────┐
│ Dynamic    │     (class / @objc / override)
│ Dispatch   │────► Runtime decides which method to call
└────────────┘
```

---

### 📌 TL;DR

| Feature       | Static              | Dynamic                          |
| ------------- | ------------------- | -------------------------------- |
| Uses          | struct, final class | class inheritance, @objc methods |
| Speed         | Faster              | Slower (but flexible)            |
| Decided when? | Compile time        | Runtime                          |

Let me know if you'd like to explore **protocol dispatch** next (which has both static and dynamic forms in Swift).

Awesome — let’s explore **protocol dispatch** in Swift, which can be a bit tricky because **Swift protocols** support both **static** and **dynamic** dispatch depending on how they're used.
                
---
                
## 🧩 **What is Protocol Dispatch?**
                
When you call a method via a **protocol**, Swift can use:
                    
### ✅ **Static Dispatch**
                
* Happens when the compiler knows the concrete type that conforms to the protocol.
* Fast — no runtime lookup.
                
### 🔄 **Dynamic Dispatch**
                
* Happens when you're using **protocol existential types** (`someProtocol`) or the protocol has `@objc` or `dynamic` methods.
* Supports polymorphism.
* Uses runtime lookup — slower.
                
---
                
## ⚙️ **1. Protocol + Static Dispatch Example**
                
```swift
protocol Greeter {
    func greet()
}

struct Person: Greeter {
    func greet() {
        print("Hello! (Static Dispatch)")
    }
}

let p = Person()
p.greet()  // Static dispatch
```

✅ Swift knows `p` is a `Person`, so it can **statically dispatch** the `greet()` call.

---

## 🔄 **2. Protocol + Dynamic Dispatch Example**

```swift
protocol Greeter {
    func greet()
}

struct Person: Greeter {
    func greet() {
        print("Hello! (Dynamic Dispatch)")
    }
}

let g: Greeter = Person()
g.greet()  // Dynamic dispatch
```

📌 Here, even though the underlying type is `Person`, the variable `g` is typed as `Greeter`.

➡️ **Swift must decide at runtime** which `greet()` to call → **dynamic dispatch**.

---

## 🎭 **3. @objc Protocol = Always Dynamic Dispatch**

```swift
@objc protocol Animal {
    func speak()
}

class Cat: NSObject, Animal {
    func speak() {
        print("Meow! (@objc dynamic dispatch)")
    }
}

let a: Animal = Cat()
a.speak()
```

✅ This is **Objective-C dynamic dispatch** via the Objective-C runtime (required for things like KVO or runtime swizzling).

---

## 🔬 Summary Table: Protocol Dispatch in Swift

| Scenario                                      | Dispatch Type | Notes                                   |
| --------------------------------------------- | ------------- | --------------------------------------- |
| Struct conforming to protocol, used directly  | Static        | Fast — known at compile time            |
| Protocol used as a type (`let x: Protocol`)   | Dynamic       | Uses **witness table** or Obj-C runtime |
| `@objc` protocol                              | Dynamic       | Uses Objective-C runtime dispatch       |
| `protocol extension` method (not in protocol) | Static        | Cannot be overridden                    |

---

### ⚠️ Gotcha: Protocol Extensions

```swift
protocol Speaker {
    func speak()
}

extension Speaker {
    func speak() {
        print("Default speaking")
    }
}

struct Dog: Speaker {}

let d: Speaker = Dog()
d.speak()  // "Default speaking" – but NOT overridden
```

* Even though `Dog` doesn’t implement `speak()`, Swift uses the default extension **statically**.
* You **can’t override** protocol extension methods unless you declare them in the protocol itself.

---

## 🎯 TL;DR

* Protocol methods are **statically dispatched** when the type is known at compile time.
* They become **dynamically dispatched** when using protocols as types (`let x: SomeProtocol`).
* `@objc` protocols are **always dynamic**, using Objective-C runtime.

---
