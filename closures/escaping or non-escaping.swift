//
//  escaping or non-escaping.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

In Swift, closures can be **escaping** or **non-escaping**, and understanding the difference is important for memory management and asynchronous code.

---

## 🧭 Quick Summary

| Type             | When Used                                       | Captured                  | Common Use Case                 |
| ---------------- | ----------------------------------------------- | ------------------------- | ------------------------------- |
| **Non-escaping** | Closure used **immediately** inside a function  | In the current scope      | Synchronous tasks               |
| **Escaping**     | Closure used **later** (after function returns) | Escapes the current scope | Async work, completion handlers |

---

## 📌 **Non-Escaping Closures (Default)**

By default, closures are **non-escaping**. That means they are **executed during the function call** and can't outlive the function body.

```swift
func performNow(action: () -> Void) {
    action() // executed immediately
}
```

You **don’t need to mark** anything here. The closure is guaranteed to be used before the function ends.

---

## 📌 **Escaping Closures (`@escaping`)**

If a closure is **stored or called later**, **after the function returns**, it must be marked with `@escaping`.

```swift
var completionHandlers: [() -> Void] = []

func performLater(action: @escaping () -> Void) {
    completionHandlers.append(action) // used later, must escape
}
```

Here, `action` escapes the function body because it's stored in an array and can be used after the function has returned.

---

## ⚠️ Why Escaping Matters

When a closure **escapes**, it can outlive the object or function that created it. This can cause **retain cycles** if not handled properly, especially when capturing `self`.

```swift
class Example {
    var value = 10

    func runTask() {
        performLater { [weak self] in
            print(self?.value ?? 0)
        }
    }
}
```

Using `[weak self]` helps prevent memory leaks.

---

## 💡 Examples

### 🔸 Non-escaping (default)

```swift
func greet(_ action: () -> Void) {
    action() // run now
}

greet {
    print("Hello now!")
}
```

### 🔸 Escaping

```swift
var savedActions: [() -> Void] = []

func saveAction(_ action: @escaping () -> Void) {
    savedActions.append(action)
}

saveAction {
    print("Hello later!")
}
savedActions.forEach { $0() }
```

---

## ✅ Summary Table

| Feature         | Non-Escaping                | Escaping                                  |
| --------------- | --------------------------- | ----------------------------------------- |
| Executes        | Immediately                 | Later (async or stored)                   |
| Keyword         | None                        | `@escaping`                               |
| Captures `self` | No retain cycle             | Possible retain cycle (use `[weak self]`) |
| Example Use     | Sorting, mapping, filtering | Network requests, animation callbacks     |

---



//
//  EscapingClosure+WeakReference.swift
//  ClosuresInSwift
//
//

import Foundation
import UIKit

class EscapingClosureWithWeakReference: UIViewController {
    override func viewDidLoad() {
        // need to use weak reference to self
        // else it will create a retain cycle
        escapingWithWeakReference { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.view.backgroundColor = UIColor.blue
            }
        }
    }
    
    func escapingWithWeakReference(closure: @escaping () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now()+3) {
            closure()
        }
        print("Function called")
    }
}


//
//  escapingClosure.swift
//  ClosuresInSwift
//
//

import Foundation

var closureArr:[()->()] = []
func functionWithEscapingClosure(closure: @escaping () -> Void) {
    print("function called")
    closureArr.append(closure)
    closure()
    return
}

func functionWithEscapingClosureInAsyncronouscall(closure: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now()+3) {
        closure()
    }
    print("Function called")
    return
}

func functionWithEscapingClosureInAsyncronouscallWithReturn(closure: @escaping () -> Int) {
    DispatchQueue.global().asyncAfter(deadline: .now()+3) {
        let data = closure()
        print(data)
    }
    print("Function called")
    return
}


//
//  nonEscapingClosure.swift
//  ClosuresInSwift
//
//


func functionWithNoEscapingClosure(closure: () -> Void) {
    print("function called")
    closure()
    return
}

func nonescapingClosure(closure:() -> Void) {
    return
    closure()
}
