//
//  initializers.swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

In Swift, **initializers** define *how an instance is created and brought into a valid state*. Understanding **which initializer to use and when** is key to writing safe, expressive, and maintainable code.

Below is a **clear mental model + practical guide** you can use in interviews and real projects.

---

# 1. What Is an Initializer?

An initializer (`init`) must:

* Assign **all stored properties**
* Leave the instance in a **valid state**
* Run **before** the instance is used

```swift
struct User {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
```

---

# 2. Designated Initializers (Primary Initializers)

### What

A **designated initializer** is the *main initializer* responsible for initializing **all stored properties**.

```swift
class User {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
```

### When to use

✅ Always have at least one
✅ When you need full control over initialization
✅ When properties don’t have default values

**Rule**

> Every class must have at least one designated initializer.

---

# 3. Convenience Initializers (Classes Only)

### What

A **convenience initializer** is a *secondary initializer* that:

* Calls another initializer in the same class
* Adds defaults or transforms parameters

```swift
class User {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    convenience init(name: String) {
        self.init(id: 0, name: name)
    }
}
```

### When to use

✅ To provide simpler or shorter init options
✅ To avoid duplicated setup logic
❌ Not for core initialization

**Rule**

> Convenience initializers must call a designated initializer.

---

# 4. Failable Initializers (`init?` / `init!`)

### What

Initializers that can **fail and return `nil`**.

```swift
struct Email {
    let value: String

    init?(value: String) {
        guard value.contains("@") else { return nil }
        self.value = value
    }
}
```

### When to use

✅ When invalid input makes an instance meaningless
✅ Parsing, validation, external data
❌ Don’t overuse for normal control flow

**Use `init!`**

* Only when failure is *logically impossible*
* Rare and dangerous

---

# 5. Memberwise Initializers (Structs)

### What

Swift automatically generates an initializer for structs.

```swift
struct Point {
    let x: Int
    let y: Int
}

let p = Point(x: 1, y: 2)
```

### When to use

✅ Simple value types
❌ If you need validation or invariants

Adding a custom initializer **removes** the automatic one (unless you re-add it).

---

# 6. Default Initializers

### What

If *all properties have default values*, Swift gives you a no-argument initializer.

```swift
struct Settings {
    var darkMode = false
}
```

```swift
let settings = Settings()
```

### When to use

✅ Configuration or state objects
✅ When defaults make sense

---

# 7. Required Initializers (Classes)

### What

Forces subclasses to implement an initializer.

```swift
class Animal {
    required init(name: String) {}
}
```

```swift
class Dog: Animal {
    required init(name: String) {
        super.init(name: name)
    }
}
```

### When to use

✅ Framework or base classes
✅ When subclasses must support a specific initialization path

---

# 8. Convenience vs Designated — Interview Rule

| Question                       | Answer              |
| ------------------------------ | ------------------- |
| Core initialization?           | Designated          |
| Shortcut / default parameters? | Convenience         |
| May fail?                      | Failable            |
| Value type?                    | Memberwise / Custom |
| Framework base class?          | Required            |

---

# 9. Initializer Delegation Rules (Classes)

Swift enforces safety with strict rules:

1. Designated → must call **super**
2. Convenience → must call **self**
3. Convenience → ultimately calls a designated initializer

```
convenience init → designated init → super.init
```

---

# 10. Dependency Injection & Initializers

Initializers are ideal for **dependency injection**.

```swift
final class NearbyViewModel {
    let service: PlacesService

    init(service: PlacesService) {
        self.service = service
    }
}
```

### Why

* Testable
* Explicit dependencies
* No hidden state

---

# 11. Common Mistakes

❌ Doing heavy work in initializers
❌ Using `init!` casually
❌ Duplicating logic across inits
❌ Optional properties just to avoid writing an initializer

---

# 12. Simple Mental Model

> **Designated initializes state**
> **Convenience improves ergonomics**
> **Failable enforces validity**

---

If you want, I can:

* Explain **two-phase initialization**
* Compare **struct vs class initializers**
* Show **real interview questions**
* Walk through **a tricky initializer bug**

Just tell me 👍

Below is a **complete, end-to-end explanation of Swift initializers**, from fundamentals to advanced edge cases. This is intentionally **deep and structured**, the level expected from a **senior iOS interview** or when designing real frameworks.

---

# 1. What Initializers Really Do (Conceptual Model)

An initializer is **not just a constructor**. It enforces **type safety**.

Swift guarantees:

* No property is accessed before being initialized
* An object is **fully valid** before use
* Subclasses cannot break superclass invariants

**Key invariant**

> After initialization finishes, *every stored property has a valid value*.

---

# 2. Stored vs Computed Properties

### Stored properties

Must be initialized:

```swift
struct User {
    let id: Int      // must be set
    var name: String // must be set
}
```

### Computed properties

Do **not** need initialization:

```swift
var displayName: String {
    name.uppercased()
}
```

---

# 3. Types of Initializers (Complete List)

Swift has **8 initializer categories**:

1. Designated
2. Convenience
3. Failable (`init?`)
4. Implicitly unwrapped failable (`init!`)
5. Memberwise
6. Default
7. Required
8. Throwing initializers

---

# 4. Designated Initializers (Foundation of Everything)

### Definition

A **designated initializer**:

* Initializes **all stored properties**
* Is the *primary path* to create an instance
* Can call a superclass designated initializer

```swift
class Account {
    let id: String
    let balance: Double

    init(id: String, balance: Double) {
        self.id = id
        self.balance = balance
    }
}
```

### Rules

* Classes must have **at least one**
* Structs can rely on memberwise instead
* Subclasses must ensure superclass properties are initialized

### When to use

✅ Core initialization logic
✅ Enforcing invariants
✅ Dependency injection

---

# 5. Two-Phase Initialization (Why Swift Is Safe)

Swift initializes classes in **two phases**.

### Phase 1 — Initialize Stored Properties

* Each class sets its own properties
* No method calls allowed
* No `self` access

### Phase 2 — Customization

* All properties are valid
* Methods can be called
* `self` is available

```swift
class Person {
    let name: String

    init(name: String) {
        self.name = name   // phase 1
        print(name)        // phase 2
    }
}
```

This prevents:
❌ Accessing uninitialized state
❌ Calling overridden methods too early

---

# 6. Convenience Initializers (Ergonomics Layer)

### Definition

A **convenience initializer**:

* Must call another initializer in the same class
* Cannot initialize properties directly

```swift
class User {
    let id: Int
    let name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    convenience init(name: String) {
        self.init(id: 0, name: name)
    }
}
```

### When to use

✅ Default values
✅ Simplified API
✅ Reducing duplication

### Rules (Important)

* Must call `self.init`
* Cannot call `super.init`
* Must eventually call a designated initializer

---

# 7. Failable Initializers (`init?`)

### Definition

An initializer that may return `nil`.

```swift
struct Email {
    let value: String

    init?(value: String) {
        guard value.contains("@") else { return nil }
        self.value = value
    }
}
```

### When to use

✅ Input validation
✅ Parsing JSON / URLs
✅ Domain rules enforcement

### Why not just optional properties?

Because:

* The object **should not exist** in an invalid state
* Forces correctness at creation time

---

# 8. `init!` (Implicitly Unwrapped Failable)

### Definition

Fails at runtime if invalid.

```swift
init!(rawValue: String)
```

### When (Rare)

* When failure is *logically impossible*
* Bridging Objective-C APIs

❌ Avoid in production unless necessary

---

# 9. Throwing Initializers (`init throws`)

### Definition

Fail with **rich error information**.

```swift
enum FileError: Error {
    case notFound
}

struct FileLoader {
    init(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw FileError.notFound
        }
    }
}
```

### When to use

✅ Need error details
✅ Recovery paths exist

### Comparison

| `init?`         | `init throws`   |
| --------------- | --------------- |
| Simple failure  | Rich errors     |
| Optional result | Try/catch       |
| Lightweight     | More expressive |

---

# 10. Memberwise Initializers (Structs)

### Automatic behavior

```swift
struct Point {
    let x: Int
    let y: Int
}
```

Swift generates:

```swift
init(x: Int, y: Int)
```

### Gotcha

Adding **any custom initializer** removes the automatic one.

### Best practice

Re-add explicitly if needed.

---

# 11. Default Initializers

Generated when **all properties have default values**.

```swift
struct Settings {
    var notificationsEnabled = true
}
```

```swift
Settings() // valid
```

Used for:

* Configuration objects
* State containers

---

# 12. Required Initializers

### Definition

Forces subclasses to implement an initializer.

```swift
class Vehicle {
    required init(speed: Int) {}
}
```

```swift
class Car: Vehicle {
    required init(speed: Int) {
        super.init(speed: speed)
    }
}
```

### When to use

✅ Frameworks
✅ Abstract base classes
✅ Serialization / decoding

---

# 13. Initializers & Protocols

Protocols can require initializers.

```swift
protocol Identifiable {
    init(id: String)
}
```

Classes implementing it must mark initializer as `required`.

---

# 14. Initializers in Extensions

### Structs

Extensions **cannot** add designated initializers that access private stored properties.

### Classes

Extensions can add **convenience initializers only**.

```swift
extension User {
    convenience init(guest: Bool) {
        self.init(id: 0, name: "Guest")
    }
}
```

---

# 15. Initializers & Codable

`Codable` synthesizes an initializer.

If you implement `init(from:)`, you must initialize **all properties manually**.

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
}
```

---

# 16. Common Anti-Patterns (Very Important)

❌ Heavy work in initializers
❌ Network calls in `init`
❌ Optional properties to “avoid init”
❌ Calling overridable methods during init
❌ Using `init!` casually

---

# 17. Mental Model (Memorize This)

> **Designated = truth**
> **Convenience = comfort**
> **Failable = validation**
> **Required = contract**

---

# 18. Interview-Ready Summary

If asked:

> “Explain Swift initializers”

Say:

> “Swift initializers guarantee type safety through two-phase initialization. Designated initializers establish valid state, convenience initializers improve ergonomics, and failable or throwing initializers enforce domain rules. Required initializers ensure subclass compliance, and structs benefit from memberwise initialization unless custom logic is needed.”

---

If you want, I can next:

* Walk through **real crash scenarios**
* Show **initializer chains in inheritance**
* Compare **Swift vs Objective-C initialization**
* Explain **why Swift forbids certain init patterns**

Just say the word 💡


Below are **real Swift initializer interview questions**—the kind asked at **Apple, Meta, Amazon, Uber, and senior iOS roles**—with **clear, correct answers and reasoning**.
These aren’t trivia; they test **how well you understand Swift’s safety model**.

---

## 1. What is the difference between designated and convenience initializers?

**Answer**

* **Designated** initializers fully initialize all stored properties and are the *primary* initialization path.
* **Convenience** initializers are secondary and must call another initializer in the same class.

**Key rule**

```
convenience → designated → super
```

**Why it matters**
Prevents duplicated or incomplete initialization.

---

## 2. Why does Swift have two-phase initialization?

**Answer**
Two-phase initialization ensures:

1. All stored properties are initialized before use
2. Subclasses cannot access partially initialized superclasses

**Phase 1**

* Assign stored properties
* No method calls
* No `self` usage

**Phase 2**

* Safe to use `self`
* Safe to call methods

**This prevents crashes common in Objective-C.**

---

## 3. Why can’t you call overridden methods in an initializer?

**Answer**
Because the subclass may not have finished initializing its properties.

Swift blocks this to prevent:

* Accessing uninitialized state
* Undefined behavior

---

## 4. When should you use `init?` instead of optional properties?

**Answer**
Use `init?` when:

* The object is **invalid without proper data**
* You want to prevent invalid instances entirely

Example:

```swift
init?(email: String)
```

Better than:

```swift
var email: String?
```

---

## 5. What happens if a convenience initializer doesn’t call a designated initializer?

**Answer**
The code will **not compile**.

Swift enforces that:

* Convenience initializers must delegate to another initializer
* Ultimately reaching a designated initializer

---

## 6. What happens if a subclass doesn’t implement a required initializer?

**Answer**
Compilation fails.

```swift
class A {
    required init() {}
}

class B: A {} // ❌ Error
```

---

## 7. Why does adding a custom initializer remove the memberwise initializer?

**Answer**
Because Swift assumes:

* You are taking full control over initialization
* Automatic behavior may violate your invariants

**Fix**
Re-add the memberwise initializer manually if needed.

---

## 8. What’s the difference between `init?` and `init throws`?

**Answer**

| `init?`        | `init throws`   |
| -------------- | --------------- |
| Returns `nil`  | Throws error    |
| Simple failure | Rich error info |
| Lightweight    | More expressive |

Use `throws` when recovery or debugging matters.

---

## 9. Can extensions add designated initializers?

**Answer**

* **Structs**: No (if accessing stored properties)
* **Classes**: No

Extensions can only add:

* Convenience initializers (classes)

---

## 10. Why are initializers not inherited by default?

**Answer**
Because:

* Subclasses may add new invariants
* Automatically inheriting initializers could create invalid state

Swift only inherits initializers when it is **provably safe**.

---

## 11. When does Swift automatically inherit initializers?

**Answer**
When:

1. Subclass defines **no designated initializers**
2. All stored properties have default values

This ensures safety.

---

## 12. What is a failable initializer used for in the standard library?

**Examples**

* `URL(string:)`
* `Int("123")`
* `UIColor(named:)`

Because invalid input should **not produce an instance**.

---

## 13. Why is heavy work discouraged in initializers?

**Answer**
Because:

* Initializers should be fast and predictable
* Failures can’t be retried cleanly
* Side effects make objects harder to test

Better pattern:

```swift
init(...)
func load()
```

---

## 14. Why does Swift require calling `super.init` explicitly?

**Answer**
To guarantee:

* Superclass invariants are satisfied
* Initialization order is deterministic

Swift refuses implicit behavior here for safety.

---

## 15. Can a struct have a failable initializer?

**Answer**
Yes—and it’s common.

```swift
struct Percentage {
    let value: Int

    init?(value: Int) {
        guard (0...100).contains(value) else { return nil }
        self.value = value
    }
}
```

---

## 16. What happens if a failable initializer fails after partially initializing properties?

**Answer**

* The instance is discarded
* No partially initialized object exists
* Memory is safely cleaned up

---

## 17. Why does `self` not exist during phase 1?

**Answer**
Because:

* The object isn’t fully initialized
* Allowing access would break Swift’s safety guarantees

---

## 18. Why must protocol-required initializers be marked `required`?

**Answer**
To ensure:

* All subclasses implement the initializer
* Protocol conformance remains valid across inheritance

---

## 19. Why does Swift prevent stored properties from being accessed before initialization?

**Answer**
To eliminate:

* Undefined behavior
* Runtime crashes
* Memory safety issues

This is a **core language guarantee**.

---

## 20. One-liner interview answer (Strong)

> “Swift initializers enforce type safety through two-phase initialization. Designated initializers establish valid state, convenience initializers improve API ergonomics, and failable or throwing initializers prevent invalid instances. Required initializers ensure subclass correctness.”

---

### Want more?

I can give you:

* 🔥 **Tricky code snippets interviewers love**
* 🧠 **Initializer crash-debug questions**
* 🧪 **Unit test questions involving init**
* ⚔️ **Swift vs Objective-C initialization comparisons**

Just tell me.
