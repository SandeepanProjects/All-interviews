//
//  Property wrappers.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Sure! Let’s go **step by step** on **Property Wrappers** in Swift — what they are, why they’re useful, and how to implement them. This is a common **iOS interview topic**, especially for Swift 5+.

---

## **1️⃣ What is a Property Wrapper?**

A **Property Wrapper** is a **struct, class, or enum** that defines **common behavior for getting and setting a property**.
It **wraps the property logic** so you can **reuse it** across multiple properties instead of writing the same logic repeatedly.

Think of it as a **wrapper around your property** that can:

* Validate data
* Transform values
* Provide default values
* Persist values (UserDefaults, database)

---

## **2️⃣ Basic Use Case**

Example: You want a property that **cannot be negative**.

```swift
@propertyWrapper
struct NonNegative {
    private var value: Int = 0

    var wrappedValue: Int {
        get { value }
        set { value = max(0, newValue) } // Ensure non-negative
    }

    init(wrappedValue initialValue: Int) {
        self.value = max(0, initialValue)
    }
}

struct Account {
    @NonNegative var balance: Int
}

var account = Account(balance: 50)
account.balance = -10
print(account.balance) // Output: 0
```

✅ **Explanation:**

* `@propertyWrapper` defines the wrapper.
* `wrappedValue` is the **actual value** you are controlling.
* `@NonNegative` applies the wrapper to the property.

---

## **3️⃣ Property Wrapper Features**

### a) Default Values

You can give the property wrapper a default value.

```swift
@NonNegative var score = 10
```

---

### b) Access to Projected Value

* Use `$` prefix to expose **additional behavior** (projected value).

```swift
@propertyWrapper
struct Logged<T> {
    private var value: T

    var wrappedValue: T {
        get { value }
        set {
            print("Setting value to \(newValue)")
            value = newValue
        }
    }

    var projectedValue: T { value } // access via $property

    init(wrappedValue: T) {
        self.value = wrappedValue
    }
}

struct Player {
    @Logged var score: Int
}

var player = Player(score: 10)
player.score = 20       // prints "Setting value to 20"
print(player.$score)    // prints 20
```

---

### c) Use Cases of Property Wrappers

1. **Validation** — ensure value constraints (e.g., non-negative, max length).
2. **Thread Safety** — wrap property access with locks/queues.
3. **Persistence** — read/write to `UserDefaults`.
4. **Lazy Initialization** — wrap logic that runs only once.
5. **Logging / Analytics** — track value changes automatically.

---

### **4️⃣ Example: Persisting to UserDefaults**

```swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct Settings {
    @UserDefault(key: "isDarkMode", defaultValue: false)
    var isDarkMode: Bool
}

var settings = Settings()
settings.isDarkMode = true
print(settings.isDarkMode) // true
```

---

### **5️⃣ Summary**

| Concept                | Explanation                                       |
| ---------------------- | ------------------------------------------------- |
| `@propertyWrapper`     | Declare a property wrapper type                   |
| `wrappedValue`         | The actual value being wrapped                    |
| `projectedValue` (`$`) | Optional extra behavior or metadata               |
| Benefits               | Code reuse, encapsulation, cleaner property logic |

---

✅ **Interview Tip:**

* Know **how to implement one from scratch**, like `NonNegative` or `UserDefault`.
* Know **projectedValue** and why `$` is useful.
* Think about **reusable patterns**, not just syntax.

---

If you want, I can also show a **real-world example combining `@propertyWrapper` with `Combine`** to auto-publish value changes — something interviewers love for iOS Swift questions.

Do you want me to show that?

Perfect! Let’s see a **real-world iOS example** combining **`@propertyWrapper`** with **Combine** to automatically publish changes. This is something interviewers often ask because it shows **modern Swift skills**.

---
## **Use Case: Auto-Publish Changes**

Suppose you have a **settings model** or **view model** where you want any property change to automatically trigger a **Combine publisher** for UI updates.

---

### **Step 1: Create a Published Property Wrapper**

```swift
import Combine
import Foundation

@propertyWrapper
class PublishedWrapper<Value> {
    private var subject: CurrentValueSubject<Value, Never>
    
    var wrappedValue: Value {
        get { subject.value }
        set { subject.send(newValue) }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(wrappedValue: Value) {
        subject = CurrentValueSubject<Value, Never>(wrappedValue)
    }
}
```

✅ **Explanation:**

* `wrappedValue` → normal property access.
* `projectedValue` (`$`) → exposes a **Combine publisher**.
* `CurrentValueSubject` → stores the value and notifies subscribers on change.

---

### **Step 2: Use in a ViewModel**

```swift
class SettingsViewModel {
    @PublishedWrapper var isDarkMode: Bool = false
    @PublishedWrapper var fontSize: Int = 14
}

let viewModel = SettingsViewModel()
```

---

### **Step 3: Subscribe to Changes**

```swift
let cancellable1 = viewModel.$isDarkMode.sink { newValue in
    print("Dark Mode changed to \(newValue)")
}

let cancellable2 = viewModel.$fontSize.sink { newSize in
    print("Font size changed to \(newSize)")
}

// Trigger changes
viewModel.isDarkMode = true   // prints: Dark Mode changed to true
viewModel.fontSize = 18       // prints: Font size changed to 18
```

---

### **Why This Is Powerful**

1. **Reusability:** Any property can now be wrapped with `@PublishedWrapper`.
2. **Combine Integration:** You automatically get a publisher for **reactive updates**.
3. **Encapsulation:** The ViewModel doesn’t need to manually call `objectWillChange.send()` like with `ObservableObject`.
                                                                        
---
                                                                        
### **Interview Tip**
                                                                        
* Explain **why `wrappedValue` vs `projectedValue`** is important.
* Show how it **reduces boilerplate** compared to writing separate `@Published` properties.
* Bonus: You can extend it for **UserDefaults + Combine**, so changes persist AND auto-update the UI.

