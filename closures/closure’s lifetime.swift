//
//  closure’s lifetime.swift
//  
//
//  Created by Apple on 06/12/25.
//

import Foundation

Here is a **deep, accurate, fully internal explanation** of how **closure lifetime** works in Swift.

This is one of the most misunderstood parts of Swift and ARC, especially when it comes to captures, async tasks, escaping closures, and memory leaks.

---

# 🔵 **What is a closure’s lifetime?**

A closure in Swift is a **heap-allocated reference type**.

Its lifetime is governed by **ARC rules**, exactly like any class instance:

* The closure lives **as long as at least one strong reference** points to it.
* When the last strong reference is removed → ARC deallocates the closure → all captured values are released (strongly) or discarded (weak/weak-unowned).

---

# 🔵 Step-by-step: what happens when a closure is created

When you create a closure:

```swift
let closure = { print("hello") }
```

Swift internally allocates:

1. **A heap object** that stores:

   * The captured variables (if any)
   * Metadata for ARC
   * A pointer to the closure’s code

2. The variable `closure` holds a **strong reference** to this heap object.

If no one stores the closure → it's destroyed immediately after use.

---

# 🔵 Closures have 3 common lifetime patterns

## 1️⃣ **Non-escaping closures**

These closures do **not survive beyond the function call**.

Example:

```swift
func doWork(_ action: () -> Void) {
    action()
}
```

* `action` is guaranteed to run *before* `doWork` returns.
* It **cannot escape** the scope.
* It does **not** need to be stored on the heap in most cases — Swift can optimize it.

Meaning: **lifetime = duration of function call**.

---

## 2️⃣ **Escaping closures**

These *can* outlive the function.

Example:

```swift
var stored: (() -> Void)?

func save(_ closure: @escaping () -> Void) {
    stored = closure
}
```

Here:

* `closure` escapes the function
* Swift must allocate a heap storage block for it
* Its lifetime lasts until **nothing else holds a strong reference** to it

This is why escaping closures require explicit capture control (`[weak self]`).

---

## 3️⃣ **Closures captured by asynchronous work**

Closures passed to things like:

* `DispatchQueue.async`
* `Task { ... }`
* `URLSession.shared.dataTask`
* any async API

are **escaping**.

```swift
DispatchQueue.global().async {
    print("I run later")
}
```

The closure remains alive until:

1. the queue executes it
2. it finishes executing
3. the thread returns control → ARC releases the closure
4. no strong refs remain → closure deallocates

This is why capturing self strongly in async can cause retain cycles **if the async work also holds self**.

---

# 🔵 **How captured values affect closure lifetime**

### 1️⃣ Strong captures

If a closure strongly captures an object, the closure **keeps that object alive**.

```swift
class A {
    var handler: (() -> Void)?

    func setup() {
        handler = { self.doStuff() }  // strong capture
    }
}
```

This creates:

```
A → handler closure → strong self capture → A
```

→ retain cycle
→ both objects live forever
→ memory leak
→ unless `self` breaks the cycle manually (rare)

This is why capture lists exist.

---

### 2️⃣ Weak captures

Weak captures do **not** extend lifetime.

```swift
{ [weak self] in self?.doStuff() }
```

* closure does NOT keep self alive
* self may become nil during closure lifetime
* closure becomes harmless when `self` deallocates

---

### 3️⃣ Unowned captures

Unowned captures assume the captured value **outlives the closure**.

```swift
{ [unowned self] in self.doStuff() }
```

Unsafe if self dies first → crash.

Used when lifetime relationships are well-defined (e.g., parent/child).

---

# 🔵 Closure lifetime inside types

If a closure is stored in an object:

```swift
class A {
    var callback: (() -> Void)?
}
```

Then **the closure lifetime is tied to A**, as long as:

* `A.callback != nil`
* `A` has strong owners

If closure captures `A`, that's a cycle.

---

# 🔵 Closure lifetime inside async/await

When calling an async function with a closure:

```swift
await withCheckedContinuation { continuation in
    continuation.resume()
}
```

The closure provided to the continuation stays alive until:

1. it resumes
2. Swift releases the continuation
3. closure deallocates

---

# 🔵 When does a closure actually deallocate?

A closure deallocates exactly when:

```
Its strong ARC count drops to 0.
```

Examples:

### Case A: A simple temporary closure

```swift
func f() {
    let c = { print("hi") }
    c()
}
```

After `f()` returns → `c` goes out of scope → deallocates.

---

### Case B: Stored closure

```swift
var stored: (() -> Void)?
stored = { print("x") }
stored = nil  // closure ARC = 0 → deallocates
```

---

### Case C: Retain cycle (closure never deallocates)

```swift
class A {
    var f: (() -> Void)?
    func start() {
        f = { self.doSomething() }  // retains self
    }
}
```

If no one breaks the cycle → closure never deallocates → `A` never deallocates.

---

# ⭐ **Summary of closure lifetime**

| Concept                     | Explanation                             |
| --------------------------- | --------------------------------------- |
| Closure is a reference type | Lives on heap, ARC-managed              |
| Non-escaping closure        | Lives only during function call         |
| Escaping closure            | Survives and may execute later          |
| Strong capture              | Extends lifetime of captured object     |
| Weak capture                | Does NOT extend lifetime                |
| Unowned capture             | Assumes lifetime extends beyond closure |
| Async closure               | Lives until async work completes        |
| Stored closure              | Lives as long as something holds it     |

---

# Want more?

I can also explain:

* How Swift stores captured variables internally
* How closure memory layout looks
* Why closures are reference types but look like value syntax
* How Swift avoids copying captured values unnecessarily
* ARC optimizations for closures

Just tell me!
