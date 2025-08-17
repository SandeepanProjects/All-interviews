//
//  File.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

In Swift, an **`@autoclosure`** is a special attribute that lets you automatically convert an expression into a closure — **without having to explicitly write the closure syntax**.

---

### 🔍 **What is `@autoclosure`?**

Normally, if you want to pass a closure (a chunk of code that gets executed later), you write it like this:

```swift
func logIfTrue(_ predicate: () -> Bool) {
    if predicate() {
        print("True!")
    }
}

logIfTrue({ 2 > 1 }) // need to use closure syntax
```

With `@autoclosure`, you can simplify the syntax:

```swift
func logIfTrue(_ predicate: @autoclosure () -> Bool) {
    if predicate() {
        print("True!")
    }
}

logIfTrue(2 > 1) // cleaner syntax, no braces
```

Here, `2 > 1` gets automatically wrapped in a closure.

---

### ✅ **When to Use `@autoclosure`**

Use `@autoclosure` when you want to **delay evaluation** of an expression (lazy evaluation), but keep the **caller’s syntax clean and natural**.

Common use cases:

1. **Assertions:**

```swift
assert(2 > 1, "Math is broken!")
```

Internally, `assert` uses `@autoclosure` so the condition isn’t evaluated unless needed (e.g. in debug mode).

2. **Custom Logical Operations:**

```swift
func myAssert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        print("Assertion failed: \(message)")
    }
}
```

3. **Lazy Evaluation:**

Used to **avoid unnecessary computation** when the result might not be needed.

```swift
func logMessage(_ message: @autoclosure () -> String, if condition: Bool) {
    if condition {
        print(message())
    }
}
```

Here, the `message()` is only computed if `condition` is true — useful if generating the message is expensive.

---

### ⚠️ **Cautions / Best Practices**

* Don’t overuse `@autoclosure` — it can **hide logic** and confuse readers.
* You can **combine with `@escaping`** if the closure needs to be stored or used later:

```swift
func store(_ action: @autoclosure @escaping () -> Void) {
    delayedActions.append(action)
}
```

---

### Summary

| Feature        | Description                                           |
| -------------- | ----------------------------------------------------- |
| **What**       | Automatically turns an expression into a closure      |
| **Why**        | Cleaner syntax for delayed evaluation                 |
| **Used in**    | `assert`, custom control flow, lazy logging           |
| **Avoid when** | It harms readability or leads to unclear control flow |


                                        
func autoClosure(closure: @autoclosure ()->(), msg: String) {
    print(msg)
    closure()
}

func autoClosureWithBoolValue(closure: @autoclosure ()->Bool) {
    print(closure())
}

func autoClosureWithString(closure: @autoclosure ()->String) {
    let res = closure()
    print(res)
}

func autoClosureWithEscaping(closure: @autoclosure @escaping ()->String) {
    let res = closure()
    print(res)
}
