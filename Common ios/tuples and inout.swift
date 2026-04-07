//
//  tuples and inout.swift
//  
//
//  Created by Apple on 04/11/25.
//

import Foundation

Fantastic — you’re asking about two *very* fundamental Swift concepts that often confuse beginners:
👉 **tuples** and **`inout` parameters**.

Let’s break them down clearly and show how and when you use each, with examples.

---

## 🧩 **1️⃣ Tuple**

### 🔹 Definition

A **tuple** is a lightweight way to **group multiple values into a single compound value**.

You can think of a tuple as a **temporary, unnamed structure** — it groups related values **without creating a custom type** (like a struct or class).

---

### 🔹 Example

```swift
let person = ("Alice", 28)
print(person.0)  // "Alice"
print(person.1)  // 28
```

---

### 🔹 Named Tuples

You can give elements **names** for readability:

```swift
let person = (name: "Alice", age: 28)
print(person.name) // "Alice"
print(person.age)  // 28
```

---

### 🔹 Decomposing Tuples

You can **unpack** tuple values into individual constants or variables:

```swift
let (name, age) = ("Bob", 25)
print(name) // "Bob"
print(age)  // 25
```

If you only need one value:

```swift
let (name, _) = ("Eve", 30)
print(name) // "Eve"
```

---

### 🔹 Returning Multiple Values from a Function

Tuples are super useful when you want to **return more than one value** without defining a struct.

```swift
func getUserInfo() -> (name: String, age: Int) {
    return ("Charlie", 35)
}

let user = getUserInfo()
print(user.name) // "Charlie"
print(user.age)  // 35
```

---

### 🔹 When to Use Tuples

✅ Use tuples when:

* You need to return or pass **a few related values** temporarily.
* You don’t need to store or reuse that data structure long-term.

❌ Don’t use tuples for:

* Complex data that you’ll reuse — that’s what **structs** or **classes** are for.

---

## 🧩 **2️⃣ `inout` Parameters**

### 🔹 Definition

The **`inout`** keyword allows a function to **modify** a variable **passed into it** — instead of just receiving a *copy* of the value.

Normally in Swift, function parameters are **passed by value** (copied), meaning changes inside the function **don’t affect** the original variable.
Using `inout` makes them **pass-by-reference**.

---

### 🔹 Example (Without `inout`)

```swift
func addTen(to number: Int) {
    var number = number
    number += 10
    print("Inside function:", number)
}

var myNumber = 5
addTen(to: myNumber)
print("Outside function:", myNumber)  // Still 5
```

➡️ The value `5` is copied, so `myNumber` remains unchanged.

---

### 🔹 Example (With `inout`)

```swift
func addTen(to number: inout Int) {
    number += 10
}

var myNumber = 5
addTen(to: &myNumber)
print(myNumber)  // 15 ✅
```

Notice:

* You declare the parameter as `inout` in the function.
* You call it with **`&`** before the variable name to indicate you’re passing it *by reference*.

---

### 🔹 When to Use `inout`

✅ Use it when:

* You want a function to **mutate** (change) the passed variable directly.
* For **algorithms or utility functions** that update values in place (like swapping values, accumulating results, etc.).

Example:

```swift
func swapValues(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}

var x = 10
var y = 20
swapValues(&x, &y)
print(x, y) // 20, 10
```

---

### ⚠️ `inout` Rules

* Can only be used with **variables (var)**, not constants (`let`).
* You must prefix with `&` when calling.
* You **can’t use** `inout` parameters with constant literals or temporary expressions (like `addTen(to: &5)` ❌).
* Swift ensures safety by not allowing you to reference the same variable multiple times in one `inout` call (to prevent memory conflicts).

---

## 🧠 **Quick Comparison Summary**

| Concept     | Description                                            | Mutates Value? | Example Use                                                         |
| ----------- | ------------------------------------------------------ | -------------- | ------------------------------------------------------------------- |
| **Tuple**   | Groups multiple values into one compound value         | ❌              | Returning multiple results from a function                          |
| **`inout`** | Passes variable by reference so function can modify it | ✅              | Functions that modify external variables (e.g., swapping, updating) |

---

### ✅ **In One Sentence:**

* **Tuple** → Bundle of multiple values used together (temporary group).
* **`inout`** → Function parameter modifier that allows you to change a variable’s value outside the function.

---

Would you like me to make a **visual diagram** showing how value passing vs `inout` reference passing works in memory (side-by-side)?


Ahh — you’re asking about **`inout` in Swift**, which is a very important (and often confusing) concept.

Let’s break it down simply and clearly 👇

---

# 🧠 What is `inout` in Swift?

`inout` allows a function to **modify the original value passed to it**, instead of working on a copy.

👉 Normally in Swift:

* Parameters are **constants (immutable copies)**
* You **cannot change** them inside a function

👉 With `inout`:

* You pass a **reference to the variable**
* The function can **change the original value**

---

# ⚙️ Basic Example

### ❌ Without `inout` (does NOT modify original)

```swift
func increment(x: Int) {
    var x = x
    x += 1
}

var num = 10
increment(x: num)
print(num) // still 10
```

---

### ✅ With `inout` (modifies original)

```swift
func increment(x: inout Int) {
    x += 1
}

var num = 10
increment(x: &num)
print(num) // 11 ✅
```

👉 Key points:

* Use `inout` in function definition
* Use `&` while passing the variable

---

# 🚀 When to Use `inout`

## ✅ 1. When You Need to Modify External State

If your function’s purpose is to **change a variable directly**

```swift
func doubleValue(_ value: inout Int) {
    value *= 2
}
```

---

## ✅ 2. Performance Optimization (Avoid Copying Large Data)

For large structs (like arrays, dictionaries):

```swift
func updateArray(_ arr: inout [Int]) {
    arr.append(100)
}
```

👉 Avoids unnecessary copying

---

## ✅ 3. Swapping Values (Classic Use Case)

```swift
func swapValues(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}

var x = 5
var y = 10
swapValues(&x, &y)
```

---

## ✅ 4. Mutating Struct Data from Outside

```swift
struct Counter {
    var value: Int
}

func incrementCounter(_ counter: inout Counter) {
    counter.value += 1
}
```

---

# ⚠️ Important Rules

## ❗ 1. Must Use `&` While Passing

```swift
increment(x: &num) // ✅
increment(x: num)  // ❌ error
```

---

## ❗ 2. Cannot Pass Constants (`let`)

```swift
let num = 10
increment(x: &num) // ❌ not allowed
```

---

## ❗ 3. No Multiple Access Conflicts

```swift
var x = 10
increment(x: &x) // OK

// But this is NOT allowed:
func bad(_ x: inout Int) {
    x += x // ❌ overlapping access
}
```

---

# 🧬 How `inout` Works Internally

Swift uses a concept called:
👉 **Copy-In Copy-Out (Value-Result)**

Steps:

1. Copy value into function
2. Modify inside function
3. Copy back to original variable

---

# 🆚 `inout` vs Return Value

## Option 1: Using `inout`

```swift
func addTen(_ x: inout Int) {
    x += 10
}
```

## Option 2: Returning Value (Preferred in many cases)

```swift
func addTen(_ x: Int) -> Int {
    return x + 10
}
```

👉 Swift developers often prefer **return values** unless mutation is necessary.

---

# 💡 Best Practices (Very Important)

Use `inout` when:
✔ You explicitly want mutation
✔ It improves readability
✔ Avoids heavy copying

Avoid `inout` when:
❌ You can return a value instead
❌ It makes code harder to understand
❌ You’re working in functional-style code

---

# 🔥 Interview Insight

If asked:
👉 “When would you use `inout`?”

**Strong answer:**

> Use `inout` when a function needs to modify the caller’s variable directly, especially for performance with large value types or when mutation is part of the function’s responsibility. However, returning values is often preferred for clarity and immutability.

---

If you want, I can next show:
✅ Real-world iOS examples (network layer, caching, reducers)
✅ Advanced concepts like `inout` with closures & memory safety
✅ Interview-level tricky questions on `inout`

