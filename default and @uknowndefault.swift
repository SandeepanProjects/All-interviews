//
//  default and @uknowndefault.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Great question 👏 — this is about **Swift’s switch statements** and **the special `@unknown default` case**, which was introduced to make your code **safer and more future-proof**, especially when handling **enums from the system frameworks** (like Apple’s APIs).

Let’s go step by step 👇

---

## 🧩 1️⃣ The Basics of `default` in a `switch`

In Swift, a `switch` statement must be **exhaustive** — meaning every possible case of the value being switched on must be handled.

If it’s not exhaustive, the compiler forces you to add a `default` case.

### Example

```swift
enum Direction {
    case north, south, east, west
}

let direction = Direction.north

switch direction {
case .north:
    print("Going north")
case .south:
    print("Going south")
default:
    print("Some other direction")
}
```

✅ Works fine because the `default` covers any cases not explicitly listed.

---

## 🧠 2️⃣ Problem with `default` and Future Enum Cases

Now imagine Apple defines an enum in a framework you use (e.g. `UIUserInterfaceStyle`):

```swift
enum UIUserInterfaceStyle: Int {
    case unspecified
    case light
    case dark
}
```

If you write:

```swift
switch traitCollection.userInterfaceStyle {
case .light:
    print("Light mode")
case .dark:
    print("Dark mode")
default:
    print("Unspecified or future mode")
}
```

It works *now* — but if Apple adds a **new case** in the future (say `.vibrant`),
your `default` case will silently catch it.

⚠️ This means your app won’t *warn you* that your switch is missing a new case — and you might handle it incorrectly.

---

## 🚨 3️⃣ Enter `@unknown default`

Swift introduced **`@unknown default`** (in Swift 5 / iOS 12+) to help solve that exact problem.

It’s used when switching over **non-exhaustive enums** (especially from system frameworks).

### Example

```swift
switch traitCollection.userInterfaceStyle {
case .light:
    print("Light mode")
case .dark:
    print("Dark mode")
@unknown default:
    print("A new style was added that we didn’t handle yet!")
}
```

---

## ✅ 4️⃣ What `@unknown default` Actually Does

The `@unknown default` is **semantically identical** to `default` at runtime —
but the **compiler treats it differently**:

| Behavior                                 | `default`                              | `@unknown default`                         |
| ---------------------------------------- | -------------------------------------- | ------------------------------------------ |
| Required for exhaustiveness              | ✅ Yes                                  | ✅ Yes                                      |
| Compiler warning for missing known cases | ❌ No                                   | ⚠️ **Yes!**                                |
| Use case                                 | When you don’t care about future cases | When you want to be warned about new cases |
| Common usage                             | App-specific enums                     | System / framework enums                   |

So when Apple adds a new enum case later, **the compiler warns you**:

> ⚠️ "Switch must be exhaustive — new cases added in an API"

That lets you update your code to handle the new case intentionally.

---

## 💡 5️⃣ Example Comparison

### Using `default`

```swift
switch someEnum {
case .a:
    doSomething()
default:
    doFallback()
}
```

➡️ ✅ Compiles cleanly
➡️ ⚠️ No compiler warning if `.b` or `.c` cases are added later

---

### Using `@unknown default`

```swift
switch someEnum {
case .a:
    doSomething()
@unknown default:
    doFallback()
}
```

➡️ ✅ Compiles cleanly
➡️ ⚠️ If new cases are added, compiler warns you to revisit this switch.

---

## 🧰 6️⃣ When to Use Each

| Use Case                                                                  | Use                    |
| ------------------------------------------------------------------------- | ---------------------- |
| You define the enum yourself and you know it won’t change                 | Use `default`          |
| The enum comes from Apple / another library and might add new cases later | Use `@unknown default` |
| You want the compiler to alert you when new enum cases appear             | Use `@unknown default` |

---

## 🧪 7️⃣ Example with a System Enum (UIKit)

```swift
switch UIApplication.shared.applicationState {
case .active:
    print("Active")
case .background:
    print("Background")
case .inactive:
    print("Inactive")
@unknown default:
    print("New state detected — update handling")
}
```

If Apple adds `.suspended` in the future → you’ll get a compiler warning prompting you to handle it.

---

## 🔚 Summary

| Keyword            | Purpose                                           | Compiler Warning on New Enum Case | Recommended For         |
| ------------------ | ------------------------------------------------- | --------------------------------- | ----------------------- |
| `default`          | Catch-all for unhandled cases                     | ❌ No                              | Your own stable enums   |
| `@unknown default` | Catch-all that also warns you if new cases appear | ⚠️ Yes                            | System / evolving enums |

---

Would you like me to show a **real SwiftUI example** where using `@unknown default` avoids a potential runtime logic bug (e.g. when handling `ColorScheme` or `ScenePhase`)?
