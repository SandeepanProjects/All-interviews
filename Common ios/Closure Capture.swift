//
//  Closure Capture.swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

This is a **very common senior iOS interview topic** because it directly tests your understanding of **Swift memory management (ARC)** and **retain cycles**.

Below is a **from-first-principles explanation**, with **clear mental models, diagrams (in words), and real interview framing**.

---

# 1. What Is a Closure Capture?

A **closure captures values from its surrounding scope** so it can use them later.

```swift
func makeClosure() -> () -> Void {
    let x = 10
    return {
        print(x)
    }
}
```

Here:

* `x` is **captured**
* The closure keeps `x` alive even after the function returns

---

# 2. How Closures Capture Memory

### Value types (structs, enums)

* Captured **by value**
* Copied (conceptually)
* No retain cycles

```swift
let count = 5
let closure = { print(count) }
```

---

### Reference types (classes)

* Captured **strongly by default**
* Increases reference count
* Potential for **retain cycles**

```swift
class ViewModel {
    var callback: (() -> Void)?

    func setup() {
        callback = {
            print(self)
        }
    }
}
```

💥 `ViewModel → callback → closure → self`

---

# 3. What Is a Capture List?

A **capture list** lets you control *how* variables are captured.

```swift
{ [weak self] in
    self?.doSomething()
}
```

Syntax:

```swift
{ [capture1, capture2] in
    // closure body
}
```

Capture lists run **at closure creation time**, not execution time.

---

# 4. Strong Capture (Default)

```swift
{
    self.doWork()
}
```

### Behavior

* Closure retains `self`
* Safe if closure is short-lived
* Dangerous if stored

### When it’s OK

* Immediate execution
* Synchronous code
* Local closures

---

# 5. Weak Capture (`[weak self]`)

```swift
{ [weak self] in
    self?.doWork()
}
```

### Behavior

* Does **not** increase retain count
* `self` becomes optional
* `self` may be `nil`

### When to use

✅ Async callbacks
✅ Delegates
✅ Long-lived closures

### Tradeoff

* Code must handle `nil`
* Closure may do nothing if object is gone

---

# 6. Unowned Capture (`[unowned self]`)

```swift
{ [unowned self] in
    doWork()
}
```

### Behavior

* No retain
* Non-optional
* 💥 Crashes if `self` is deallocated

### When to use

✅ Guaranteed lifetime
✅ Parent → child relationships
❌ Async work unless guaranteed

---

# 7. Weak vs Unowned (Interview Table)

| Feature        | weak | unowned           |
| -------------- | ---- | ----------------- |
| Retains object | ❌    | ❌                 |
| Optional       | ✅    | ❌                 |
| Can crash      | ❌    | ✅                 |
| ARC-safe       | Yes  | Unsafe if misused |

**Rule**

> Use `weak` by default. Use `unowned` only when lifetime is guaranteed.

---

# 8. Capture Lists Are Snapshots

```swift
var value = 10

let closure = { [value] in
    print(value)
}

value = 20
closure() // prints 10
```

Capture lists capture **current value**, not future changes.

---

# 9. Capturing Multiple Values

```swift
{ [weak self, count = self.count] in
    guard let self else { return }
    print(count)
}
```

* `count` captured by value
* `self` captured weakly

---

# 10. Retain Cycles (Classic Interview Example)

```swift
class VC {
    var closure: (() -> Void)?

    func setup() {
        closure = {
            self.doWork()
        }
    }
}
```

### Fix

```swift
closure = { [weak self] in
    self?.doWork()
}
```

---

# 11. Async / Await and Closures

Even with `async`:

```swift
Task {
    await self.loadData()
}
```

This captures `self` **strongly**.

Safer:

```swift
Task { [weak self] in
    await self?.loadData()
}
```

---

# 12. UIKit & SwiftUI Gotchas

### UIKit

* Timers
* Animation blocks
* Network callbacks

```swift
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 1
}
```

Safe because animation block is short-lived.

---

### SwiftUI

* `self` is a value type (`View`)
* ViewModels are reference types

```swift
.onAppear {
    viewModel.load()
}
```

Be careful with closures stored inside ViewModels.

---

# 13. When NOT to Use `[weak self]`

❌ Synchronous closures
❌ Closures guaranteed to finish immediately
❌ Performance-critical tight loops

Overusing `weak` causes:

* Silent failures
* Hard-to-debug logic bugs

---

# 14. Memory Diagram (Mental Model)

**Strong Capture**

```
VC ──strong──▶ closure ──strong──▶ VC
```

**Weak Capture**

```
VC ──strong──▶ closure ──weak──▶ VC
```

---

# 15. Interview One-Liner (Very Strong)

> “Closures capture reference types strongly by default, which can create retain cycles when closures are stored. Capture lists let us control ownership—using `weak` to avoid cycles in async work, and `unowned` only when lifetime is guaranteed.”

---

## Want practice?

I can:

* Give you **retain-cycle debugging questions**
* Show **ARC graphs interviewers love**
* Explain **escaping vs non-escaping closures**
* Compare **closures vs delegates memory-wise**

Just say the word 🧠

Perfect — here are **real retain-cycle debugging interview questions**, exactly the kind used in **senior iOS interviews**, with **step-by-step reasoning**, not just fixes.

I’ll mix **code reading**, **“what’s wrong?”**, and **“how would you debug this?”** styles.

---

## 1. “Why is this ViewController never deallocated?”

```swift
class ProfileViewController: UIViewController {
    var onUpdate: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        onUpdate = {
            self.refreshUI()
        }
    }

    deinit {
        print("ProfileViewController deallocated")
    }
}
```

### What’s happening?

* `ProfileViewController` owns `onUpdate`
* `onUpdate` closure strongly captures `self`
* Retain cycle:

```
VC → closure → VC
```

### Fix

```swift
onUpdate = { [weak self] in
    self?.refreshUI()
}
```

### Interview takeaway

> Any stored closure that references `self` must be suspected.

---

## 2. “This network request completes, but memory keeps growing”

```swift
class DataLoader {
    let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func load() {
        api.fetch { result in
            self.handle(result)
        }
    }
}
```

### Bug

* `APIClient` retains the completion handler
* Closure strongly captures `self`
* Cycle:

```
DataLoader → APIClient → closure → DataLoader
```

### Fix

```swift
api.fetch { [weak self] result in
    self?.handle(result)
}
```

---

## 3. “Why does this Timer cause a leak?”

```swift
class PollingService {
    var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.poll()
        }
    }
}
```

### Bug

* Timer retains its block
* Block retains `self`
* Self retains timer

### Fix

```swift
timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
    self?.poll()
}
```

Also:

```swift
timer?.invalidate()
```

---

## 4. “Why does `deinit` never get called even after dismiss?”

```swift
class ModalVC: UIViewController {
    let viewModel = ModalViewModel()
}

class ModalViewModel {
    var onFinish: (() -> Void)?

    func setup(vc: ModalVC) {
        onFinish = {
            vc.dismiss(animated: true)
        }
    }
}
```

### Bug

* ViewModel retains closure
* Closure retains VC
* VC retains ViewModel

### Fix

```swift
onFinish = { [weak vc] in
    vc?.dismiss(animated: true)
}
```

---

## 5. “Is this animation block leaking?”

```swift
UIView.animate(withDuration: 0.3) {
    self.view.alpha = 1
}
```

### Answer

❌ No leak.

### Why?

* Animation blocks are short-lived
* Not stored
* Released immediately after execution

### Interview trap

Not all strong captures are bad.

---

## 6. “This Combine pipeline leaks — where?”

```swift
class VM {
    var cancellables = Set<AnyCancellable>()

    func bind() {
        publisher
            .sink { value in
                self.process(value)
            }
            .store(in: &cancellables)
    }
}
```

### Bug

* `self` retains `cancellables`
* `cancellables` retains `sink`
* `sink` closure retains `self`

### Fix

```swift
.sink { [weak self] value in
    self?.process(value)
}
```

---

## 7. “Why does this async Task keep my VC alive?”

```swift
Task {
    await self.loadData()
}
```

### Bug

* Task strongly captures `self`
* Task may outlive VC

### Fix

```swift
Task { [weak self] in
    await self?.loadData()
}
```

---

## 8. “Is this `unowned self` safe?”

```swift
class Child {
    let parent: Parent

    init(parent: Parent) {
        self.parent = parent
        parent.onUpdate = { [unowned self] in
            self.refresh()
        }
    }
}
```

### Answer

⚠️ Risky.

If `Child` deallocates before `parent.onUpdate` fires → 💥 crash.

### Safer

```swift
[weak self]
```

---

## 9. “How would you confirm this is a retain cycle?”

### Debug steps (Interview Gold)

1. Add `deinit { print(...) }`
2. Use **Xcode Memory Graph Debugger**
3. Look for circular strong references
4. Pause app → Debug Memory Graph
5. Check retain paths

---

## 10. “Why does capturing `self` weakly sometimes break logic?”

```swift
[weak self] in
self?.save()
```

### Issue

* `self` might be nil
* Closure silently does nothing

### Interview answer

> Use `weak` for safety, but ensure the work is still logically valid if `self` disappears.

---

## 11. “Explain this memory graph”

```
ViewController
 └── strong → ViewModel
       └── strong → closure
             └── strong → ViewController
```

### Diagnosis

Classic retain cycle via ViewModel callback.

---

## 12. “What’s the most common retain-cycle mistake?”

**Answer**

> Storing closures that capture `self` without a capture list.

---

## 13. One-liner Debug Answer (Strong)

> “I look for stored closures capturing `self`, verify deinit is called, and use the Memory Graph to find strong reference loops. Most leaks come from async callbacks, timers, or Combine subscriptions.”

---

## Want harder ones?

I can give you:

* 🔥 Trick questions with **false positives**
* 🧠 ARC graph interpretation drills
* 🧪 Live debugging scenarios
* ⚔️ SwiftUI retain-cycle edge cases

Just say the word.
