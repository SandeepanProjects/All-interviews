//
//  Code output.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Let's carefully work through this **Swift code step by step**.

---

### **Code**

```swift
var greeting = ["shri": 1, "shrin": 2, "shrini": 5, "shriniv": 4]
let x = greeting.sorted { $0.1 < $1.1 }.map { $0.0 }
```

---

### **Step 1: `greeting.sorted { $0.1 < $1.1 }`**

* `greeting` is a **dictionary**: `[String: Int]`
* `.sorted { $0.1 < $1.1 }` sorts **by value (`Int`) ascending**.

The dictionary entries:

| Key       | Value |
| --------- | ----- |
| "shri"    | 1     |
| "shrin"   | 2     |
| "shrini"  | 5     |
| "shriniv" | 4     |

**Sorting by value ascending:**

1. "shri" → 1
2. "shrin" → 2
3. "shriniv" → 4
4. "shrini" → 5

So the **sorted array of tuples** is:

```swift
[("shri", 1), ("shrin", 2), ("shriniv", 4), ("shrini", 5)]
```

---

### **Step 2: `.map { $0.0 }`**

* `$0.0` is the **key** from each `(key, value)` tuple.
* Mapping over the sorted array:

```swift
["shri", "shrin", "shriniv", "shrini"]
```

---

### ✅ **Step 3: Result**

```swift
x = ["shri", "shrin", "shriniv", "shrini"]
```

---

So the **output of `x`** is:

```
["shri", "shrin", "shriniv", "shrini"]
```

---

If you want, I can also explain **why the dictionary is sorted into an array** instead of staying a dictionary — this often confuses interviewers.

Do you want me to explain that?
