//
//  Purpose and use of EquatableView.swift
//  
//
//  Created by Apple on 29/11/25.
//

import Foundation

`EquatableView` is a **performance optimization tool** in SwiftUI that helps you *control* when a view should update. It allows you to tell SwiftUI:

> “Only re-render this view if its input value actually changed.”

This can significantly reduce redundant recomputations, especially in views whose `body` is expensive, or which often receive unchanged data from parents.

---

# ✅ **What is `EquatableView`?**

`EquatableView` is a wrapper view created implicitly when you use:

```swift
MyView(value)
    .equatable()
```

or explicitly:

```swift
EquatableView(content: MyView(value))
```

It requires that the view’s `body` depends on something that conforms to `Equatable`.

Under the hood, `EquatableView` stores the previous value and then checks:

```swift
if newValue == oldValue {
    // skip recomputing body()
} else {
    // recompute body()
}
```

This is one of the very few times *you* can influence SwiftUI's diffing behavior.

---

# 🔍 **Why does it exist?**

SwiftUI normally compares views using:

* type identity
* structure
* view modifiers
* data driving the view

But it **does not** do deep value checks unless you specifically ask it to.

So consider this example:

```swift
struct Row: View {
    let user: User  // large struct, not Equatable
    var body: some View {
        Text(user.name)
        // heavy view work…
    }
}
```

If the parent re-renders, SwiftUI recreates *all* rows.
Even if `user` hasn’t changed.

To avoid this, you can wrap it:

```swift
Row(user: user)
    .equatable()
```

If `User` conforms to `Equatable`, SwiftUI will skip recomputing the body if nothing changed.

---

# 🎯 **Main Purpose**

### ## **Reduce unnecessary body evaluations**

SwiftUI recomputes `body` whenever:

* any input changes
* parent view recomputes
* environment values change
* animations are active

With `EquatableView`, recomputation is blocked unless data has changed.

### ## **Optimize expensive views**

If you have:

* complex layout calculations
* expensive drawing
* heavy on-appear logic (like geometry)
* expensive subviews

This can improve smoothness.

### ## **Stabilize identity in lists**

In lists (`ForEach`, `List`) views are frequently regenerated.

An `EquatableView` ensures:

* the row's view is reused
* only the mutated ones change
* state remains stable

---

# 🧪 Example: Without EquatableView

```swift
struct ContentView: View {
    @State var value = 0
    var body: some View {
        VStack {
            ExpensiveView(value: value)
            Button("Update unrelated state") { value += 1 }
        }
    }
}

struct ExpensiveView: View {
    let value: Int
    var body: some View {
        print("Recomputed ExpensiveView")
        return Text("Value = \(value)")
    }
}
```

If anything causes `ContentView` to update, **ExpensiveView's body runs** every time.

---

# 🧪 Example: With EquatableView

```swift
ExpensiveView(value: value)
    .equatable()
```

Now `ExpensiveView.body` runs **only when `value` actually changes**.

Huge difference in deeply nested views.

---

# ⚠️ Important Limitations

### 1️⃣ The wrapped view must be `Equatable`

SwiftUI compares values using `==`.

Your view must conform to:

```swift
struct MyView: Equatable, View { ... }
```

or the data passed into `.equatable()` must be Equatable.

### 2️⃣ Don’t overuse it

Overuse can add overhead because SwiftUI must store old/new values and compare them.
Use it only where body recomputation is measurably expensive.

### 3️⃣ Does NOT prevent diffing of subviews

It only prevents re-running `body()`.
If `body` uses dynamic data (e.g. `@State` inside), that part still updates.

---

# 🧠 Under-the-hood

SwiftUI normally relies on structural identity:

```
VStack -> Text -> Button -> etc.
```

But `.equatable()` inserts an explicit comparison node into the diff tree.

Conceptually:

```
EquatableView
   └── YourView
```

During diffing:

```
if oldView.input == newView.input:
    skip diffing children
else:
    recompute and diff children normally
```

This makes `EquatableView` a small “intelligence injection” into SwiftUI’s otherwise structural update algorithm.

---

# 📝 Summary

| What it does                                | Why use it                  |
| ------------------------------------------- | --------------------------- |
| Skips body recomputation if value unchanged | Boost performance           |
| Adds explicit Equatable comparison          | Avoid unnecessary updates   |
| Helps in lists                              | Stabilizes identity & state |
| Good for expensive views                    | Heavy layout or graphics    |

`EquatableView` is a targeted tool for advanced SwiftUI performance tuning.

---

If you want, I can also show:

🔹 A visual diagram of how EquatableView wraps nodes
🔹 A real-world use case (e.g., chat app rows, data-heavy lists)
🔹 When *not* to use `.equatable()`
🔹 How `.transaction` and `.id()` interact with EquatableView

Just say **“show examples”** or **“show diagrams”**, etc.
