//
//  Capture List.swift
//  
//
//  Created by Apple on 06/12/25.
//

import Foundation

Here is a **clean, complete, and accurate explanation** of what a *capture list* is in Swift—plus **everything that can be captured** and how it works under the hood.

---

# 🔵 **What is a Capture List?**

A **capture list** is a special syntax you add before a Swift closure’s parameters to control:

1. **what values the closure captures**, and
2. **how they are captured** (strongly, weakly, unowned, or copied).

It looks like this:

```swift
{ [capture list] (parameters) -> Return in
    // closure body
}
```

**If no capture list is provided**, Swift automatically captures needed values **strongly**.

---

# 🔵 **Why capture lists exist**

Closures are *reference types* and can outlive the scope they were created in.

Swift automatically captures variables, but sometimes you must:

* avoid retain cycles (`[weak self]`)
* avoid unexpected mutation by copying values (`[x = x]`)
* rename captured values (`[value = compute()]`)
* inject constants explicitly (`[handler = someFunction]`)
* freeze values at capture time

---

# 🔵 **What can be captured?**

You can capture **any expression that produces a value**, not just variables.

Here is the full list:

---

# 1️⃣ **Variables & Properties**

Most common usage:

```swift
{ [x] in print(x) }
```

Equivalent to “capture `x` strongly”.

---

# 2️⃣ **Objects (classes)**

```swift
{ [weak self] in self?.doSomething() }
```

Objects can be captured:

* `strong` (default)
* `weak`
* `unowned`

To avoid retain cycles in closures stored by the same object:

```swift
class A {
    func foo() {
        someAsyncCall { [weak self] in
            self?.bar()
        }
    }
}
```

---

# 3️⃣ **Functions (including methods)**

Yes, you can capture a function:

```swift
func greet() { print("hi") }

let closure = { [g = greet] in g() }
```

Or instance methods:

```swift
let f = self.doThing
let closure = { [f] in f() }
```

This captures the function pointer as a **value**.

---

# 4️⃣ **Other closures**

You can capture an existing closure:

```swift
let handler = { print("done") }

let wrapper = { [h = handler] in h() }
```

Closures are reference types too.

---

# 5️⃣ **Computed expressions**

You can capture **any expression** and assign to a local alias:

```swift
let closure = { [value = expensiveComputation()] in
    print(value)
}
```

This freezes the computed value at creation time.

---

# 6️⃣ **Structs, enums, and other value types**

All value types are copied into the closure:

```swift
struct Point { var x: Int }

var p = Point(x: 3)

let closure = { [p] in print(p.x) }
```

If you modify `p` later, the closure still has the old copy.

---

# 7️⃣ **Tuples, dictionaries, arrays, optionals, etc.**

Any Swift type works:

```swift
let array = [1,2,3]
let closure = { [a = array] in print(a) }
```

---

# 8️⃣ **Renamed captures**

Useful when giving a name to any expression:

```swift
let closure = { [start = Date()] in
    print("Started at \(start)")
}
```

---

# 9️⃣ **Weak or unowned variables**

Capture lists allow memory-safe patterns:

```swift
{ [weak delegate] in delegate?.notify() }
```

Or:

```swift
{ [unowned self] in self.run() }
```

---

# 🔵 **What the capture list really does internally**

When a closure is created, Swift:

1. Allocates a hidden heap object to store captured values.
2. Copies each capture listed into that object (or weak-ref wrapper).
3. Stores pointers to this capture storage inside the closure object.

A closure looks roughly like:

```
struct Closure {
    pointer to function code
    pointer to capture storage
}
```

This is why closures are **reference types**, even though they look like lightweight syntax.

---

# 🔵 **What cannot be captured**

There are two important limitations:

### ❌ You cannot weakly capture value types

Value types (structs, enums, functions) cannot be made weak:

```swift
[weak someInt]      // ❌ not allowed
[weak f = myFunc]   // ❌ also not allowed
```

Only **class instances** support weak references.

### ❌ You can’t capture `self` as a value type

(But you can capture its properties.)

---

# ⭐ **Summary Table**

| What can be captured?       | Allowed? | Notes                            |
| --------------------------- | -------- | -------------------------------- |
| Variables                   | ✅ Yes    | Most common                      |
| Constants                   | ✅ Yes    | Always copied                    |
| Class objects               | ✅ Yes    | Can be weak/unowned              |
| Structs/enums               | ✅ Yes    | Copied                           |
| Functions / methods         | ✅ Yes    | Captured as values               |
| Closures                    | ✅ Yes    | Reference types                  |
| Expressions                 | ✅ Yes    | Fully allowed                    |
| Weak capture of value types | ❌ No     | Only classes                     |
| Computed property getter    | ❌ No     | Must capture expression or value |

---

* how capture lists interact with async/await

Just tell me what level you want!

Here is a **deep, accurate, internal explanation** of how **capture lists interact with `async/await`** in Swift.
This is one of the trickier parts of concurrency + ARC + closures, and the behavior is not always obvious.

---

# 🔵 **1. Every `async` closure is *escaping***

Whenever you pass a closure to any async function, Swift treats it as **escaping**, because it may run later:

```swift
Task {
    // async closure → always escaping
}
```

This means:

✓ The closure **is stored on the heap**
✓ ARC rules apply
✓ Captures are preserved in the heap
✓ Strong captures can easily create retain cycles
✓ Capture lists matter a lot

---

# 🔵 **2. Capture lists freeze values at closure creation time**

Example:

```swift
var number = 1

Task { [number] in
    await Task.sleep(1_000_000_000)
    print(number)   // prints the captured copy, not the updated value
}

number = 100
```

Because `[number]` was in a capture list, the closure stored **its own copy** of the value at creation.
Even though `number` changed later, the closure uses the captured (frozen) copy.

This is identical to sync closures.

---

# 🔵 **3. Strong / weak / unowned captures work the same, but async timing changes lifetime**

## Strong capture (`[self]`)

The closure **keeps `self` alive** for the entire async task:

```swift
Task { [self] in
    await doWork()
    print(self) // self guaranteed alive
}
```

This can cause leaks if the `Task` is stored or long-lived.

---

## Weak capture (`[weak self]`)

Weak capture is **extremely important** in async tasks because the task may outlive the object.

```swift
Task { [weak self] in
    guard let self else { return }
    await self.load()
}
```

Here:

* If `self` deallocates before the resume point,
* the closure sees `self == nil`,
* and the closure just stops.

No crash. No leak.

---

## Unowned capture (`[unowned self]`)

This is **dangerous** with async operations:

```swift
Task { [unowned self] in
    await doWork()
    self.finish()   // crash if self is gone
}
```

Because:

* The task might resume later (long after self should be gone)
* `unowned` assumes lifetime extends past the closure
* If wrong → **runtime crash**

Use unowned with async only when lifetimes are strict (e.g., child objects guaranteed to live longer).

---

# 🔵 **4. Suspension points DO NOT freeze captured references**

This is extremely important.

Consider:

```swift
Task { [weak self] in
    await Task.sleep(1_000_000_000)
    self?.foo()   // self may be nil here
}
```

The capture list controls **how the closure captures self**, but:

* `await` suspension does NOT freeze memory
* ARC may release `self` during suspension
* You must re-check `self` after every await if using weak captures

---

# 🔵 **5. Capture lists run at closure *creation*, not at execution**

```swift
func start() {
    let timestamp = Date()

    Task { [timestamp] in
        await Task.sleep(2_000_000_000)
        print(timestamp)   // always the original timestamp
    }
}
```

Even if you mutate `timestamp` (if it were mutable), the captured value is fixed.

---

# 🔵 **6. Actor captures behave differently**

Capturing `self` inside an actor is always allowed, because Swift inserts concurrency checks:

```swift
actor MyActor {
    func start() {
        Task { [weak self] in
            await self?.run()    // hop to actor's executor
        }
    }
}
```

But:

* Strong capture keeps the actor alive
* Weak capture avoids leaks
* Unowned capture is unsafe for async work

---

# 🔵 **7. Capturing Sendable types is always safe**

Async contexts require captured values to be **Sendable** unless you're using `@unchecked Sendable`.

Value types (structs, enums, functions) usually conform automatically.

---

# 🔵 **8. Structured concurrency provides automatic cancellation, but not weak captures**

In this example:

```swift
Task {
    await asyncWork()
}
```

If the task is cancelled, the closure ends early.

But cancellation **does not break retain cycles**.
If the closure captured `self` strongly:

```swift
Task { [self] in await work() }
```

Then cancellation doesn’t help. The cycle remains:

```
self → task closure → strong self capture
```

Use `[weak self]` to avoid task-based leaks.

---

# 🔵 **9. Capture lists help fix the most common async memory leak**

### Common mistake:

```swift
class VM {
    func load() {
        Task {
            await self.fetch()     // strong capture
        }
    }
}
```

If the task lives longer than the VM → **retain cycle**.

### Correct:

```swift
Task { [weak self] in
    guard let self else { return }
    await self.fetch()
}
```

Now there is no leak.

---

# ⭐ **Summary: How capture lists behave with async**

| Behavior                                      | Sync closure          | Async/await closure                         |
| --------------------------------------------- | --------------------- | ------------------------------------------- |
| Capture values at creation                    | ✅ Yes                 | ✅ Yes                                       |
| Strong capture keeps objects alive            | Yes                   | **Longer, until async task ends**           |
| Weak capture may become nil                   | Yes                   | **More likely to become nil during awaits** |
| Unowned capture unsafe if owner deallocates   | Crash                 | **Even riskier with suspension**            |
| Retain cycles possible                        | Yes                   | **Very common**                             |
| Suspension points do not freeze captured refs | N/A                   | **Must re-check weak self**                 |
| Closure lifetime                              | Until last strong ref | **Until task completes + ARC rules**        |

---

# Want me to go even deeper?

I can explain:

* How Swift stores async closure state machines
* How continuations interact with captured values
* Lifetime rules for closures inside actors
* ARC behavior across suspension points
* How tasks hold references internally
* Memory layout of async closure contexts

Just tell me!
