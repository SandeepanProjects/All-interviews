//
//  value semantics vs reference semantics.swift
//  
//
//  Created by Apple on 06/12/25.
//

import Foundation

Swift decides whether a captured value is stored **by copy** or **by reference** based on the **type of the captured value, the context of the closure, and the capture list**.

This is fundamental to understanding what really happens when closures capture values.

Below is a **detailed, accurate, internal explanation** of exactly how Swift differentiates them, how it stores them, and how to reason about closure memory.

---

# 🔵 1. Swift distinguishes captures by **value semantics** vs **reference semantics**

## **Value types (structs, enums, tuples)**

➡️ **Captured by copy**

Example:

```swift
var x = 10
let closure = { print(x) }
```

Swift stores **a copy of `x` at the moment the closure is created**.

Why?

* Value types have **copy semantics**
* Their lifetime is managed by the closure context
* Mutating the original `x` later does not change the copy

---

## **Reference types (class instances)**

➡️ **Captured by reference**

```swift
class A { var value = 1 }

let a = A()
let closure = { print(a.value) }
```

Swift stores a **strong reference to `a`** in the closure context.

Why?

* Class instances live on the heap
* Capturing the reference ensures the object remains alive
* Mutating `a.value` later is reflected in the closure

---

# 🔵 2. Capture lists allow overriding the default behavior

Capture lists let you explicitly **copy**, or **weaken**, or **rename** captures.

Examples:

### **Force a copy**

```swift
let closure = { [x = x] in print(x) }
```

This puts `x` into the capture list **as a copy**, regardless of how `x` will change later.

### **Weak or unowned references**

```swift
{ [weak self] in self?.doStuff() }
```

Here Swift stores a **weak reference wrapper** instead of copying or strongly referencing.

### **Strong local name**

```swift
{ [object = someExpression()] in object.run() }
```

This freezes the evaluation of `someExpression`.

---

# 🔵 3. Under the hood: closures store captured values in a **capture context object**

Every escaping closure stores captures in a hidden heap object, something like:

```
struct ClosureContext {
    // stored by copy or reference
    capturedValue1
    capturedValue2
    ...
}
```

The closure itself is:

```
struct Closure {
    pointer to function code
    pointer to capture context
}
```

The type of storage for each captured item is based on **type-kind**:

| Type            | How it's stored                                          |
| --------------- | -------------------------------------------------------- |
| Value type      | Embedded copy in context                                 |
| Reference type  | ARC-managed strong reference (unless weak/unowned)       |
| Weak capture    | Weak reference wrapper                                   |
| Unowned capture | Raw unowned pointer                                      |
| Function        | Stored as a value (function pointer + context)           |
| Closure         | Stored by reference (since closures are reference types) |

---

# 🔵 4. **Mutability rules** determine whether Swift copies or boxes values

### **Non-mutating captures**

Captured values are simply copied into the context.

### **Mutating captured variables inside nested scopes**

If a closure *mutates* a value from an outer function, Swift **boxes** the value.

Example:

```swift
var count = 0

let closure = {
    count += 1   // mutation inside closure
}
```

Now Swift promotes `count` into a **reference box**, even though it’s a value type.

Why?

* The closure may outlive the scope
* Both closure and outer scope must see same storage
* Swift allocates a heap “box” whose reference is captured

This is how "variable capture by reference" works for value types.

---

# 🔵 5. Swift differentiates: **captured variable** vs **captured value**

Swift examines *what the closure actually uses*:

### A. Capturing the *value*

```swift
let x = 10
{ print(x) }
```

Captured once → copied.

### B. Capturing the *variable*

```swift
var x = 10
{ print(x) }
```

If `x` is mutated anywhere in the scope, Swift must treat it as a shared “box”:

* Swift boxes `x` into a heap object
* Closures and external code point to the same box

The differentiation logic:

```
If a variable is captured and possibly mutated -> capture by reference (box)
Else -> capture by value
```

---

# 🔵 6. Capture behavior in async contexts

With async closures, Swift inserts extra boundaries, but semantics stay the same:

* Value types → copied into the closure context
* Reference types → stored as references
* Weak/unowned still apply

However:

* Suspension points DO NOT freeze references
* Weak references may become nil
* Strong captures may keep owners alive longer than expected

---

# 🔵 7. Summary Table: How Swift decides “copy vs reference”

| Scenario                                                | How it’s captured       | Why                    |
| ------------------------------------------------------- | ----------------------- | ---------------------- |
| Struct/enum constant                                    | Copy                    | Value semantics        |
| Struct/enum variable not mutated                        | Copy                    | Value semantics        |
| Struct/enum variable mutated from closure or outer code | Boxed reference         | Must stay synchronized |
| Class property                                          | Reference               | Class semantics        |
| Class instance                                          | Strong reference        | Class semantics        |
| Weak capture                                            | Weak reference wrapper  | Avoid retain cycles    |
| Unowned capture                                         | Unowned pointer         | Lifetime guaranteed    |
| Function                                                | Copied function pointer | First-class value      |
| Closure                                                 | Reference (ARC)         | Closures are ref types |
| Explicit capture list assignment                        | Whatever you specify    | Overrides default      |

---

# ⭐ Ultimate mental model

### **Swift captures *values* unless mutation or reference-type semantics require capturing *storage*.**

Or shorter:

> Swift captures constants by copy, variables by reference (if mutated), and objects by pointer.

---

If you want, I can go even deeper into:

* How Swift generates "boxes" for variable capture
* The exact SIL (Swift Intermediate Language) emitted for different capture kinds
* Memory layout of closure contexts
* How capture lists change ARC rules
* How mutation inside nested closures is analyzed

Just tell me!
