//
//  ViewBuilder.swift
//  
//
//  Created by Apple on 02/08/25.
//

import Foundation

**`@ViewBuilder`** is a special result builder used to construct views from multiple child views. It's a powerful feature that enables SwiftUI to support **declarative syntax**, allowing you to write multiple views inside closures like `body`, `VStack`, `if` statements, `switch`, etc.

---

## 🔹 What is `@ViewBuilder`?

`@ViewBuilder` is an attribute that tells the compiler to **combine multiple views into a single `View`**. Without it, SwiftUI would not be able to interpret multiple view expressions in a closure.

### Basic Example:

```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text("Hello")
            Text("World")
        }
    }
}
```

Here, `VStack` uses a `@ViewBuilder` under the hood to allow multiple `Text` views inside its closure.

---

## 🔹 When Do We Use It?

You use `@ViewBuilder` when **you define a custom view or function** that takes multiple views as content.

### 1. **Custom View with Child Views**

```swift
struct CustomContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            Text("Header")
            content()
            Text("Footer")
        }
    }
}
```

Usage:

```swift
CustomContainer {
    Text("Inside the container")
    Image(systemName: "star")
}
```

### 2. **Functions Returning Views Conditionally**

```swift
@ViewBuilder
func conditionalView(show: Bool) -> some View {
    if show {
        Text("Showing")
    } else {
        Text("Hidden")
    }
}
```

Without `@ViewBuilder`, Swift would complain about returning different view types (`Text` vs `Text`, technically same, but the control flow matters).

---

## 🔹 When Not to Use `@ViewBuilder`

* Don't use it if you're returning just one view.
* Don't use it where you need more control over returned types (like in a regular function returning a `View`).

---

## ✅ Summary

| Feature        | `@ViewBuilder` does...                               |
| -------------- | ---------------------------------------------------- |
| Combines views | Allows multiple views inside a closure               |
| Enables DSL    | Makes SwiftUI’s declarative syntax work              |
| Use cases      | Custom containers, conditional views, view factories |
| Not for        | Functions returning a single view with no branching  |


**`@ViewBuilder`**, **`TupleView`**, and **`AnyView`** are all related to how multiple views are structured and rendered, but they serve **very different purposes**.
                    
                    ---
                    
## 🧱 1. `@ViewBuilder` — **Declarative View Builder Syntax**
                    
### What it is:
                        
A **function builder** (technically a result builder) that lets you **write multiple views inside a closure** using Swift’s natural syntax.
                    
### Key role:
                        
Used to **create views declaratively**, typically in SwiftUI layout containers or custom views.
                    
### Example:
                        
```swift
VStack {
    Text("Hello")
    Text("World")
}
```

Under the hood, this becomes something like:

```swift
VStack(content: {
    ViewBuilder.buildBlock(Text("Hello"), Text("World"))
})
```

---

## 🔗 2. `TupleView` — **Combines Multiple Views into One**

### What it is:

A SwiftUI `View` that wraps a **tuple of views** into a single view when `@ViewBuilder` returns multiple views.

### Key role:

`TupleView` is the **actual type** returned by `@ViewBuilder` when there are multiple views (up to 10 views in a tuple).

### Example:

```swift
@ViewBuilder
var myViews: some View {
    Text("A")
    Text("B")
}
```

Behind the scenes:

```swift
TupleView<(Text, Text)>
```

TupleView is mostly **invisible to developers**, but it's how SwiftUI packages multiple child views.

---

## 🧳 3. `AnyView` — **Type Erasure for Views**
                                            
### What it is:
                                                
A type-erased wrapper around any SwiftUI `View`. It hides the **underlying concrete view type**.
                                            
### Key role:
                                                
Used when you **need to return different view types** from a single function or computed property and still conform to `some View`.
                                            
### Example:
                                                
```swift
func makeView(flag: Bool) -> AnyView {
    if flag {
        return AnyView(Text("Yes"))
    } else {
        return AnyView(Image(systemName: "xmark"))
    }
}
```

Without `AnyView`, the compiler would complain because `Text` and `Image` are **different types**, even though they both conform to `View`.

---

## 🧠 Summary Table

| Feature        | Purpose                               | Used When...                                                             | Example Output                          |
| -------------- | ------------------------------------- | ------------------------------------------------------------------------ | --------------------------------------- |
| `@ViewBuilder` | Declarative syntax for multiple views | You want to return multiple views from a closure                         | `TupleView<(Text, Text)>`               |
| `TupleView`    | Internal wrapper for view tuples      | SwiftUI packages multiple views (from builder) into a single view        | Automatically created behind the scenes |
| `AnyView`      | Type erasure for `View`               | You want to return different view types conditionally in one return type | `AnyView(Text("Hi"))`                   |
                                            
                                            ---
                                            
### 💡 Tips:
                                                
* Prefer **`@ViewBuilder`** and **type inference** unless you **must** erase types.
* Avoid `AnyView` **unless necessary**, as it introduces **runtime cost** and **loses optimizations**.
* You rarely **write `TupleView`** directly — it's auto-generated.
                                            
`@ViewBuilder` and `Group` are related to combining multiple views, but they operate at **different levels** and have **different purposes**.
                                            
---
                                            
## 🔹 TL;DR – Quick Comparison

| Feature          | `@ViewBuilder`                             | `Group`                                |
| ---------------- | ------------------------------------------ | -------------------------------------- |
| **What it is**   | A compiler-level result builder            | A view container                       |
| **Purpose**      | To *build* views from multiple expressions | To *group* views without adding layout |
| **Used in**      | Functions, closures, view declarations     | Inside a `body` or builder closure     |
| **Adds layout?** | ❌ No — compiler feature                    | ❌ No — invisible in layout             |
| **Return type?** | TupleView or a single View                 | Returns a `Group<View>`                |

---

## 🧱 `@ViewBuilder` – The Builder Syntax

### What it does:

Allows **multiple views** inside closures without explicitly combining them. It’s what powers the `body` of SwiftUI views and container closures like `VStack {}`.

### Example:

```swift
@ViewBuilder
var content: some View {
    Text("One")
    Text("Two")
}
```

This results in something like:

```swift
TupleView<(Text, Text)>
```

### Key idea:

* `@ViewBuilder` is **not a view itself**.
* It’s a **compiler feature** for handling multiple views inside a closure.
                                    
                                    ---
                                    
## 🧳 `Group` – A Lightweight View Wrapper
                                    
### What it does:
                                        
Combines multiple views into **a single view** **without adding layout** like `VStack`, `HStack`, or `ZStack`.
                                    
### Example:
                                        
```swift
var body: some View {
    Group {
        Text("One")
        Text("Two")
    }
}
```

This is used when SwiftUI expects only **one child view**, but you want to include **multiple** — `Group` acts as a transparent container.

### Common use case:

```swift
var body: some View {
    if someCondition {
        Group {
            Text("Line 1")
            Text("Line 2")
        }
    }
}
```

Without `Group`, SwiftUI might not accept multiple views in an `if` block (unless you're using `@ViewBuilder` already).

---

## 🧠 Key Differences

| Feature         | `@ViewBuilder`                            | `Group`                                      |
| --------------- | ----------------------------------------- | -------------------------------------------- |
| **Type**        | Attribute (result builder)                | View                                         |
| **Purpose**     | Build multiple views into a single return | Wrap multiple views into one, layout-neutral |
| **Adds layout** | No                                        | No                                           |
| **Visibility**  | Invisible at runtime                      | Visible in view hierarchy (but layoutless)   |
| **Use Case**    | Building views in functions or closures   | Avoiding multiple returns, grouping views    |

---

## ✅ When to Use Each

* Use **`@ViewBuilder`** when you're writing a custom view or view-returning function that accepts multiple child views.
* Use **`Group`** when you want to include multiple views **in a place SwiftUI expects only one** — like in `if`/`else` or `body`.

---

## 👇 Code Example Comparing Both

```swift
// Using @ViewBuilder
@ViewBuilder
func content() -> some View {
    Text("Hello")
    Text("World")
}

// Using Group
var body: some View {
    Group {
        Text("Hello")
        Text("World")
    }
}
```

Both render the same UI, but serve different roles: `@ViewBuilder` builds views; `Group` **is** a view.

