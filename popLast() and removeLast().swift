//
//  popLast() and removeLast().swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

difference between == and .elementsEqual()

Ah, you’re asking about the difference between **`==`** and **`.elementsEqual()`** in Swift. They may seem similar because both compare sequences or arrays, but they work differently. Let’s go step by step.

---

## 1️⃣ `==` Operator

* **Purpose:** Checks if two **collections (like arrays) are equal**.
* **Requirements:**

  * The collections must be of the **same type**.
  * The elements must conform to **`Equatable`**.
* **Behavior:**

  * Returns `true` if **both collections have the same number of elements**, in the same order, and all corresponding elements are equal.

### Example:

```swift
let a = [1, 2, 3]
let b = [1, 2, 3]
let c = [3, 2, 1]

print(a == b) // true
print(a == c) // false
```

✅ Key point: `==` is **strict equality** for the collection.

---

## 2️⃣ `.elementsEqual(_:)` Method

* **Purpose:** Checks if two **sequences produce the same elements in order**, using a **closure comparator** if needed.
* **Requirements:**

  * Works on **any sequence**, not just arrays.
  * Can use a **custom predicate** for element comparison.
* **Behavior:**

  * Compares **elements pairwise** in order.
  * Returns `false` if sequences are **different lengths**.

### Example:

```swift
let a = [1, 2, 3]
let b = [1, 2, 3]
let c = [3, 2, 1]

print(a.elementsEqual(b)) // true
print(a.elementsEqual(c)) // false

// Using custom closure
let d = ["a", "B", "c"]
let e = ["A", "b", "C"]

let result = d.elementsEqual(e) { $0.lowercased() == $1.lowercased() }
print(result) // true
```

✅ Key point: `.elementsEqual` **can use a custom comparison**, which `==` cannot.

---

## 3️⃣ Major Differences

| Feature                     | `==`                       | `.elementsEqual()`                       |
| --------------------------- | -------------------------- | ---------------------------------------- |
| Works on                    | Equatable collections only | Any sequence                             |
| Returns                     | Bool                       | Bool                                     |
| Requires same type?         | Yes                        | No (as long as sequences are comparable) |
| Uses custom comparison?     | No                         | Yes, via closure                         |
| Safe for different lengths? | No, returns false          | False automatically                      |
| Typical use                 | Standard equality check    | Custom equality or sequence comparison   |

---

### 4️⃣ Quick Rule of Thumb

* Use **`==`** for simple equality checks on arrays, sets, or other `Equatable` collections.
* Use **`.elementsEqual()`** when:

  * You need **custom comparison** logic.
  * Comparing **different sequence types**.

---

I can also make a **diagram showing `==` vs `elementsEqual` step by step**, including the custom closure behavior — it’s very useful for interviews or documentation.

Do you want me to make that diagram?


popLast vs removeLast

Ah! You’re asking about the difference between **`popLast()`** and **`removeLast()`** in Swift. Both are used with collections like `Array`, but they behave differently. Let’s break it down carefully.

---

## 1️⃣ `popLast()`

```swift
var numbers = [1, 2, 3]
let last = numbers.popLast()
```

### Key Points:

1. **Optional Return**

   * Returns the last element as an **optional (`T?`)**.
   * If the array is empty → returns `nil`.

2. **Safe**

   * Does **not crash** if the array is empty.

3. **Mutation**

   * Removes the last element from the array **in place**.

✅ Example:

```swift
var numbers: [Int] = []

let last = numbers.popLast()
print(last)  // nil
print(numbers) // []
```

---

## 2️⃣ `removeLast()`

```swift
var numbers = [1, 2, 3]
let last = numbers.removeLast()
```

### Key Points:

1. **Non-optional Return**

   * Returns the last element directly (`T`), not optional.

2. **Unsafe on Empty Array**

   * If the array is empty → **runtime crash** (`fatal error: can't removeLast from an empty array`).

3. **Mutation**

   * Removes the last element from the array **in place**, like `popLast()`.

✅ Example:

```swift
var numbers: [Int] = []

// let last = numbers.removeLast()  // CRASHES
```

---

## 3️⃣ Summary Table

| Feature             | `popLast()`                     | `removeLast()`                    |
| ------------------- | ------------------------------- | --------------------------------- |
| Return Type         | Optional (`T?`)                 | Non-optional (`T`)                |
| Safe on empty array | ✅ returns `nil`                 | ❌ crashes                         |
| Removes element     | ✅                               | ✅                                 |
| Common use          | Safe removal, optional handling | Guaranteed removal when not empty |

---

### 🔑 Quick Tip

* Use **`popLast()`** when **array might be empty**.
* Use **`removeLast()`** when **you are sure array has elements** and want **direct access**.

---
