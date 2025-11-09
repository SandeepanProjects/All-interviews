//
//  HSBC.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

How can Class B instantiate Class C but not Class A?

Ah! This is a classic **Swift access control / design question**. Let’s carefully analyze it.

The requirement:

> Class B should be able to instantiate Class C, but **not Class A**.

This is about **controlling visibility** of classes to other parts of your code using **access specifiers**.

---

## **Step 1: Use Access Specifiers**

* If Class A should be **inaccessible** to Class B: make it `fileprivate` or `private` (depending on scope).
* If Class C should be **accessible** to Class B: make it `internal` or `public` (accessible in the module).

---

### **Example 1: Using `fileprivate`**

```swift
// File: Classes.swift

fileprivate class ClassA {
    init() {
        print("Class A created")
    }
}

class ClassB {
    func createC() -> ClassC {
        return ClassC()
    }
    
    // let a = ClassA() // ❌ Error: ClassA is fileprivate
}

class ClassC {
    init() {
        print("Class C created")
    }
}
```

✅ Explanation:

* `ClassA` is **fileprivate**, so it is visible **only within this file**.
* If Class B is in **another file**, it **cannot see ClassA**, but can see ClassC.

---

### **Example 2: Using Modules (Advanced)**

* If Class A should not be instantiated outside **its module**, mark it as `internal`.
* If Class C should be accessible to **Class B in another module**, mark it as `public` or `open`.

```swift
// ModuleA
internal class ClassA { }
public class ClassC { }

// ModuleB
let c = ClassC()   // ✅ Works
let a = ClassA()   // ❌ Error: 'ClassA' is internal to ModuleA
```

---

## **Key Takeaways**

1. **Access control is the main tool**: `private`, `fileprivate`, `internal`, `public`, `open`.
2. To restrict instantiation of a class:

   * Make the class **less accessible** than the class that needs to use it.
   * Example: Class A = `fileprivate`/`internal`, Class C = `public`.
3. Module boundaries can also enforce access control.

---
