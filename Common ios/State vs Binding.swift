//
//  State vs Binding.swift
//  
//
//  Created by Apple on 30/03/26.
//

import Foundation

In **SwiftUI**, `@State` and `@Binding` are tightly related—but they serve **very different roles** in how data flows.

Think of it like this:

👉 `@State` = **owns the data**
👉 `@Binding` = **borrows the data (two-way connection)**

---

# 🔹 @State (Source of Truth)

### ✅ What it is:

A **local, private state** owned by a view.

### Example:

```swift
@State private var isOn = false
```

### 🧠 Key points:

* Stored **inside the view**
* SwiftUI manages its lifecycle
* When it changes → view re-renders
* Should be **private**

### Example usage:

```swift
Toggle("Switch", isOn: $isOn)
```

---

# 🔹 @Binding (Reference to State)

### ✅ What it is:

A **reference to some state owned elsewhere**

### Example:

```swift
@Binding var isOn: Bool
```

### 🧠 Key points:

* Does **NOT own data**
* Gets data from parent
* Enables **two-way data flow**
* Used for **child views**

---

# 🔥 Core Difference (Simple Table)

| Feature | @State | @Binding |
| ---------- | ------------------- | -------------------- |
| Ownership | Owns data | References data |
| Storage | Local to view | No storage |
| Use case | Source of truth | Pass state to child |
| Mutability | Can change directly | Changes parent state |
| Scope | Private | Shared |

---

# 🔄 How They Work Together

### Parent View (owns state)

```swift
struct ParentView: View {
    @State private var isOn = false

    var body: some View {
        ChildView(isOn: $isOn) // pass binding
    }
}
```

### Child View (uses binding)

```swift
struct ChildView: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("Switch", isOn: $isOn)
    }
}
```

---

# 🧠 What’s Actually Happening

* `@State` → stores the value
* `$isOn` → creates a **Binding**
* `@Binding` → receives and updates that value

So when child updates:

```swift
isOn.toggle()
```

👉 Parent state updates automatically
👉 UI stays in sync

---

# 🔴 Common Mistakes

### ❌ 1. Using @State in Child Instead of @Binding

```swift
@State var isOn: Bool // ❌ wrong
```

👉 Creates a **separate copy**, breaks sync

---

### ❌ 2. Passing Value Instead of Binding

```swift
ChildView(isOn: isOn) // ❌
```

✅ Correct:

```swift
ChildView(isOn: $isOn)
```

---

### ❌ 3. Overusing Binding

* Not every value needs two-way flow
* Prefer **one-way data flow** when possible

---

# 🎯 Real-World Analogy

* `@State` = Bank account (owns money 💰)
* `@Binding` = Debit card 💳 (access to same money)

---

# 🚀 Senior-Level Insight

Use `@Binding` only when:

* Child needs to **modify parent state**

Otherwise:

* Pass plain values (`let`)
* Keep data flow predictable

---

# 🧠 Golden Rule

> “State should have a single owner; bindings allow controlled sharing.”

---

If you want, I can next explain:
👉 `@StateObject vs @ObservedObject vs @EnvironmentObject` (VERY important for interviews)

Good question—and a very common confusion.

👉 The `$` in **SwiftUI** has **nothing to do with USD (currency)** 😄
It’s just a **Swift syntax feature to access a “Binding”**.

---

# 🔹 What `$` Actually Means

In SwiftUI:

* `@State var name = "John"` → **actual value**
* `$name` → **Binding to that value**

👉 So `$` = **“give me a reference (binding) to this state”**

---

# 🔥 Why `$` Exists

SwiftUI needs a way to:

* Differentiate between **value** and **reference to value**

So:

```swift
name // String (actual value)
$name // Binding<String> (reference)
```

---

# 🔄 Example

```swift
@State private var isOn = false
```

### Use without `$`:

```swift
Text(isOn ? "ON" : "OFF") // uses VALUE
```

### Use with `$`:

```swift
Toggle("Switch", isOn: $isOn) // uses BINDING
```

---

# 🧠 Why Toggle Needs `$`

`Toggle` needs **two-way communication**:

* Read value → show UI
* Write value → update state

So it requires:

```swift
Binding<Bool>
```

That’s why:

```swift
$isOn
```

---

# 🔍 Under the Hood

When you write:

```swift
@State private var count = 0
```

SwiftUI actually creates:

```swift
private var _count: State<Int>
```

Then:

* `count` → `_count.wrappedValue`
* `$count` → `_count.projectedValue` (Binding)

👉 `$` accesses **projectedValue**

---

# 🔥 Simple Mental Model

| Syntax | Meaning |
| -------- | ------------------- |
| `value` | actual data |
| `$value` | binding (reference) |

---

# 🎯 Real-World Analogy

* `name` → actual text in notebook 📓
* `$name` → pen that can edit that notebook ✍️

---

# 🔴 Common Mistake

```swift
Toggle("Switch", isOn: isOn) // ❌
```

👉 Error because:

* `isOn` = Bool
* Needed = Binding<Bool>

✅ Correct:

```swift
Toggle("Switch", isOn: $isOn)
```

---

# 🚀 Senior-Level Insight

The `$` comes from **property wrappers design in Swift**:

* `wrappedValue` → actual data
* `projectedValue` → accessed using `$`

SwiftUI heavily uses this pattern for:

* `@State`
* `@Binding`
* `@ObservedObject`

---

# 🧠 One-Line Interview Answer

> “`$` gives a Binding to a state by accessing the projected value of a property wrapper.”

---

If you want, I can go deeper into:
👉 How `Binding` is implemented internally
👉 How to create custom bindings (very useful for senior interviews)

