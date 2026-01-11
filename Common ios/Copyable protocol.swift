//
//  Copyable protocol.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

The **`Copyable` protocol** is a **new language-level concept introduced with Swift’s move toward explicit ownership and noncopyable types** (Swift 5.9+ as part of Swift’s ownership model).

It’s subtle, but important—especially for **performance, safety, and systems-level Swift**.

---

## Big Picture: Why `Copyable` Exists

Historically, **all Swift types were implicitly copyable**:

* Value types (`struct`, `enum`) → copied on assignment (copy-on-write)
* Reference types (`class`) → reference-counted, but still *logically copyable*

This made it impossible to express:

* “This value must not be copied”
* “This resource has unique ownership”

Examples that *should not be copied*:

* File handles
* Locks
* Network sockets
* Unsafe pointers
* GPU resources

Swift introduced **noncopyable types**, and `Copyable` is the protocol that defines the *opposite*.

---

## What Is `Copyable`?

`Copyable` is a **marker protocol** that indicates a type **can be copied**.

```swift
protocol Copyable {}
```

* Most Swift types **conform to `Copyable` by default**
* Types that do **not** conform are **noncopyable**
* Noncopyable types enforce **move-only semantics**

You usually don’t write `Copyable` explicitly—Swift infers it.

---

## Noncopyable Types (`~Copyable`)

You opt *out* of copying using `~Copyable`.

```swift
struct FileHandle: ~Copyable {
    let fd: Int
}
```

Now:

* The value **cannot be copied**
* Assignment *moves* ownership
* Compiler enforces correctness

---

## What Changes with Noncopyable Types?

### ❌ Not Allowed

```swift
let a = fileHandle
let b = a        // ❌ copy not allowed
```

### ✅ Allowed (Move)

```swift
let b = a        // ownership moves
// a is no longer usable
```

The compiler enforces **use-after-move** errors.

---

## Why This Matters

### 1️⃣ Performance

* No hidden copies
* Zero-cost abstractions
* Predictable memory behavior

### 2️⃣ Safety

* Prevents double-close bugs
* Prevents use-after-free
* Safer concurrency primitives

### 3️⃣ Systems & Low-Level Swift

Critical for:

* Swift on embedded systems
* Drivers
* High-performance networking
* Unsafe memory management

---

## Interaction with Functions

### Copyable Parameter

```swift
func process<T: Copyable>(_ value: T) { }
```

### Noncopyable Parameter

```swift
func consume<T: ~Copyable>(_ value: consuming T) { }
```

Ownership modifiers:

* `borrowing`
* `consuming`
* `inout`

These work *with* `Copyable`.

---

## Real-World Example

```swift
struct DatabaseConnection: ~Copyable {
    let handle: OpaquePointer
}
```

Guarantees:

* Only one owner
* Closed exactly once
* No accidental sharing across threads

---

## Important Clarifications

* `Copyable` ≠ `NSCopying`
* `Copyable` is **compile-time**, not runtime
* It’s about **ownership**, not deep copying
* Classes are still reference types, but ownership rules apply

---

## Interview-Ready Summary

> “`Copyable` is part of Swift’s ownership model. It marks types that can be safely copied. By opting out with `~Copyable`, Swift enforces move-only semantics, which improves performance and prevents resource-safety bugs—especially for low-level or systems code.”

---

## Key Takeaway

> **`Copyable` makes copying explicit. Noncopyable types make ownership enforceable.**

If you want:

* Comparison with Rust ownership
* Examples with async/concurrency
* How this affects SwiftUI & ARC
* When *not* to use noncopyable types
