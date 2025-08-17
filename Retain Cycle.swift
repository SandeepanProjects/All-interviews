//
//  Retain Cycle.swift
//  
//
//  Created by Apple on 03/08/25.
//

import Foundation

### 🔁 What Is a Retain Cycle in iOS?

A **retain cycle** (also called a **strong reference cycle**) happens in iOS when two or more objects keep strong references to each other, preventing ARC (Automatic Reference Counting) from deallocating them. As a result, memory is leaked because the objects stay in memory even if they're no longer needed.

---

### 🧱 Where Do Retain Cycles Commonly Occur?

Here are **typical scenarios** where retain cycles often happen:

1. **Delegates**

   * If a delegate is held with a strong reference, it can cause a retain cycle.
   * **Solution:** Declare the delegate as `weak`.

   ```swift
   weak var delegate: SomeDelegate?
   ```

2. **Closures Capturing `self`**

   * Closures capture variables strongly by default, including `self`.
   * Common in:

     * Completion handlers
     * Timer blocks
     * Animation blocks
     * Dispatch closures

   ```swift
   someMethod {
       self.doSomething() // retain cycle if self is retained
   }
   ```

   **Solution:** Use `[weak self]` or `[unowned self]` to avoid capture:

   ```swift
   someMethod { [weak self] in
       self?.doSomething()
   }
   ```

3. **NSTimer or CADisplayLink**

   * These retain their target, causing a cycle if the target retains the timer.
   * **Solution:** Use a proxy or `Timer.scheduledTimer` with weak references.

   ```swift
   Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
       self?.doSomething()
   }
   ```

4. **Parent-Child Relationships**

   * A parent strongly referencing a child and the child also strongly referencing the parent (common in custom views or tree structures).

   **Solution:** One of the references (typically from child to parent) should be `weak`.

5. **Retain Cycle in Custom Containers**

   * For example, if you store objects in an array or dictionary and forget they are strongly retained.

   ```swift
   var objects: [MyObject] = []
   ```

   If `MyObject` references the container, that’s a potential cycle.

---

### ✅ How to Avoid Retain Cycles

Here are **best practices** to prevent retain cycles:

1. **Use `weak` or `unowned` references** where appropriate.

   * `weak` is optional and nils out when the object is deallocated.
   * `unowned` is non-optional but will crash if accessed after deallocation.

2. **Use `[weak self]` or `[unowned self]` inside closures** that are stored or executed later.

3. **Break cycles manually** if necessary, e.g., setting references to `nil` in `deinit`.

4. **Use Instruments' “Leaks” or “Allocations” tool** to detect retain cycles in Xcode.

5. **Avoid long-lived closures capturing objects** (e.g., stored in properties, passed to background threads).

---

### 🔍 Example of a Retain Cycle in a Closure

```swift
class MyViewController: UIViewController {
    var doSomethingClosure: (() -> Void)?

    override func viewDidLoad() {
        doSomethingClosure = {
            self.doSomething() // Retains self
        }
    }

    func doSomething() {
        print("Doing something")
    }
}
```

**Fix:**

```swift
        doSomethingClosure = { [weak self] in
            self?.doSomething()
        }
```

---

Let me know if you’d like a diagram or sample project demonstrating retain cycles and how to resolve them.

Great — let's walk through a **simple example project** that illustrates:
                    
* A **retain cycle**
* How to **identify it**
* And how to **fix it**
                
                ---
                
## 🔄 Example: Retain Cycle with Closure
                
### 💡 Scenario
                
You have a `Downloader` class that performs an async operation. It holds a closure that references a `ViewController`. This can lead to a retain cycle if not handled properly.
                
                ---
                
### ❌ Problematic Code (with retain cycle)
                
                ```swift
class Downloader {
var completion: (() -> Void)?
    
func fetchData() {
        // Simulating async task
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.completion?()
        }
    }
}

class MyViewController: UIViewController {
    let downloader = Downloader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloader.completion = {
            self.updateUI()
        }
        
        downloader.fetchData()
    }
    
    func updateUI() {
        print("UI Updated")
    }
    
    deinit {
        print("MyViewController deinitialized")
    }
}
```

### 🔁 What’s the retain cycle?

* `MyViewController` ➡️ **strongly holds** `Downloader`
* `Downloader` ➡️ **strongly holds** closure
* Closure ➡️ **strongly captures** `self` (the view controller)

So `MyViewController` is **never deallocated**.

---

### ✅ Fixed Version (no retain cycle)

```swift
class MyViewController: UIViewController {
    let downloader = Downloader()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloader.completion = { [weak self] in
            self?.updateUI()
        }
        
        downloader.fetchData()
    }
    
    func updateUI() {
        print("UI Updated")
    }
    
    deinit {
        print("MyViewController deinitialized")
    }
}
```

### 🧠 Why This Works

* `[weak self]` makes `self` a weak reference in the closure.
* This breaks the retain cycle.
* Now `MyViewController` can be deallocated when it’s no longer needed.

---

## 🔧 How to Check for Retain Cycles in Xcode
                        
1. **Run your app**
2. In Xcode, go to **Product > Profile**
3. Choose **Leaks** or **Allocations**
4. Interact with the app (e.g., push and pop view controllers)
5. See if instances are leaked (should be deallocated but aren’t)
                        
                        ---
                        
Would you like this packaged into a **mini Xcode project** or want a diagram explaining this visually?

Here’s a **visual diagram** showing the retain cycle and how it’s broken using `[weak self]`.

                        ---

                        ## ❌ Retain Cycle – Problem

                        ```
                        +-------------------+          +------------------+
                        | MyViewController  |──┐       |    Downloader    |
                        | (owns Downloader) |  └─────▶ | (has completion) |
                        +-------------------+          +------------------+
                                ▲                                 |
                                |                                 ▼
                                |                        +------------------+
                                └──────────────────────▶|    Closure        |
                                                        | (captures self)   |
                                                        +------------------+
                        ```

                        * `MyViewController` **strongly owns** `Downloader`
                        * `Downloader.completion` **strongly references** the closure
                        * Closure **strongly captures `self`**
                        * ➡️ **Cycle formed** — none of the objects can be released

                        ---

                        ## ✅ Fixed – Using `[weak self]`

                        ```
                        +-------------------+          +------------------+
                        | MyViewController  |──┐       |    Downloader    |
                        | (owns Downloader) |  └─────▶ | (has completion) |
                        +-------------------+          +------------------+
                                ▲                                 |
                                |                                 ▼
                                |                        +------------------+
                                └──────────────────────▶|    Closure        |
                                                        | (captures weak    |
                                                        |  reference to self)|
                                                        +------------------+
                        ```

                        * Closure now captures `self` as **weak**
                        * So closure doesn’t **retain** `MyViewController`
                        * ➡️ ARC can clean up objects when no longer used — **no leak**

                        ---
