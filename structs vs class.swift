//
//  structs vs class.swift
//  
//
//  Created by Apple on 26/07/25.
//

import Foundation

In Swift, **structs** and **classes** are both powerful and commonly used to define custom data types. However, they have some important **differences** that impact how and when you should use each one.

---

## 🧱 STRUCT vs CLASS in Swift – Overview

| Feature                                | `struct`                    | `class`                             |
| -------------------------------------- | --------------------------- | ----------------------------------- |
| **Value type**                         | ✅ Yes                       | ❌ No – it's a reference type        |
| **Reference type**                     | ❌ No                        | ✅ Yes                               |
| **Inheritance**                        | ❌ Not supported             | ✅ Supported                         |
| **Deinitializers**                     | ❌ Not supported             | ✅ Supported                         |
| **ARC (Automatic Reference Counting)** | ❌ Not used                  | ✅ Used                              |
| **Mutability**                         | Requires `mutating` keyword | No special keyword needed           |
| **Thread Safety** (by default)         | ✅ Safer (copied per thread) | ❌ Shared reference can cause issues |

---

## 🔍 STRUCT – Example & Use Case

### ➤ Struct is a **value type**:

When you assign a struct to another variable or pass it to a function, a **copy** is made.

### ✅ Example:

```swift
struct Point {
    var x: Int
    var y: Int
}

var p1 = Point(x: 10, y: 20)
var p2 = p1 // p2 is a **copy** of p1

p2.x = 99

print(p1.x) // 10 – p1 remains unchanged
print(p2.x) // 99 – only p2 changed
```

### ✅ When to use `struct`:

Use a `struct` when:

* You want **copy-by-value** behavior (independent copies).
* The data is **relatively simple and immutable**.
* You don’t need inheritance.
* Performance matters – structs are generally **faster** due to stack allocation.

### 🔧 Common examples using `struct`:

* `CGPoint`, `CGSize`, `CGRect`
* Model data in SwiftUI or Swift structs like:

```swift
struct User {
    var name: String
    var age: Int
}
```

---

## 🔍 CLASS – Example & Use Case

### ➤ Class is a **reference type**:

When you assign a class instance to a variable, you are assigning a **reference** to the same object in memory.

### ✅ Example:

```swift
class Person {
    var name: String
    init(name: String) {
        self.name = name
    }
}

var person1 = Person(name: "Alice")
var person2 = person1 // person2 **refers to same object**

person2.name = "Bob"

print(person1.name) // Bob – both refer to the same instance
```

### ✅ When to use `class`:

Use a `class` when:

* You need to use **inheritance** or **polymorphism**.
* You need to manage **shared mutable state**.
* You need **reference semantics** (changing one instance should affect others).
* You need to use **deinitializers** to clean up resources.

### 🔧 Common examples using `class`:

* UI elements: `UIView`, `UIViewController`, `UITableView`
* Networking or data managers:

```swift
class NetworkManager {
    var isConnected: Bool = false

    func connect() {
        isConnected = true
    }
}
```

---

## 🆚 Comparison Through a Real-World Analogy

| Situation             | Use a `struct`                             | Use a `class`                           |
| --------------------- | ------------------------------------------ | --------------------------------------- |
| Blueprint for a house | Copy of the design for different buildings | One shared building everyone uses       |
| A user profile        | Each user gets their own data              | Shared configuration or settings object |
| A coordinate on a map | Doesn’t need to be shared or mutated       | Shared state like app settings          |
| SwiftUI Views         | Always `struct` for performance and safety | UIKit Views are `class`-based           |

---

## ⚖️ Summary: When to Use Structs vs Classes

### ➤ Use `struct` when:

* You want **value semantics** (copying creates independent instances).
* Your data is small and simple.
* You don’t need inheritance.
* You care about **performance and thread-safety**.
* You’re working in SwiftUI (SwiftUI Views are `struct`s).

### ➤ Use `class` when:

* You need **reference semantics** (shared instances).
* You need **inheritance** or **polymorphism**.
* You want to manage **shared mutable state**.
* You need **deinitializers** to release resources (e.g., observers, file handles).

---

Would you like to see an example of how this plays out in SwiftUI vs UIKit, or how copying a struct vs a class can affect app behavior?

Sure! Let's dive deeper into how **structs** and **classes** are used in **SwiftUI** and **UIKit**, and explore **copying behavior** in each. These two frameworks are where you'll commonly see the **value vs reference types** in action, especially in UI development.

---

## 🖥️ **SwiftUI: Structs Everywhere**

### **Why SwiftUI uses Structs:**

SwiftUI is built around **value types**, meaning most of its core components are **structs**. This approach offers a few key advantages:

1. **Immutable & Predictable State**: In SwiftUI, structs are value types, meaning that when you modify a state, you get a copy, not a reference to the original. This makes the UI predictable and easier to manage.
2. **Performance**: Structs are allocated on the stack, which is faster for creating and passing around smaller data, as opposed to classes which are heap-allocated and come with overhead.
3. **Thread Safety**: Value types (structs) are safer in concurrent environments because each copy has its own state, so no one else can modify it unexpectedly.
                                                                                
### **Example in SwiftUI:**
                                                                                    
In SwiftUI, **views are structs**, and when you update the state, SwiftUI re-renders the view by creating a new struct instance. This allows for **declarative UI** — you describe what the UI should look like in different states, and SwiftUI takes care of rendering and updating it.
                                                                                
```swift
import SwiftUI
                                                                                
struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
                .font(.largeTitle)
            
            Button("Increment") {
                count += 1  // Struct is updated, SwiftUI re-renders the view
            }
        }
    }
}
```

### **How the State is Managed:**

* When you click the **"Increment"** button, **`count`** is updated.
* SwiftUI **creates a new copy** of the `ContentView` struct with the updated state.
* The UI is **recomputed** with the new state, which ensures that each view is independent of others.

### **Benefit of Structs in SwiftUI:**

* **No unexpected side effects**: Changes to a struct instance do not affect other views unless you explicitly manage state with bindings.
* **Thread-safety**: SwiftUI automatically handles updates to views safely across threads, without worrying about concurrent changes to mutable shared objects.

---

## 📱 **UIKit: Classes and Reference Semantics**

### **Why UIKit uses Classes:**

UIKit, unlike SwiftUI, relies heavily on **reference types** (classes). The main reason UIKit uses classes is that classes allow for **shared mutable state**, **inheritance**, and **polymorphism**, which are often necessary for building complex, dynamic interfaces in older-style imperative UIs.
                                                                                                                                        
1. **Shared State**: Classes are reference types, so changes to an instance of a class are reflected across all references to that instance. This is useful for things like UI elements that need to be updated dynamically (e.g., buttons, labels, or controllers that share a common state).
2. **Inheritance**: UIKit uses inheritance to create more flexible, reusable components (e.g., `UIViewController`, `UIButton`, etc.).
3. **Performance Considerations**: Classes are **heap-allocated**, which provides more flexibility when managing large objects or more complex UI components.
                                                                                                                                        
### **Example in UIKit:**
                                                                                                                                            
Let’s look at an example using `UIViewController`, which is a **class** in UIKit.
                                                                                                                                        
```swift
import UIKit

class ViewController: UIViewController {
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel()
        label.text = "Count: \(count)"
        label.font = UIFont.systemFont(ofSize: 32)
        label.frame = CGRect(x: 100, y: 100, width: 200, height: 50)
        self.view.addSubview(label)
        
        let button = UIButton(type: .system)
        button.setTitle("Increment", for: .normal)
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 50)
        button.addTarget(self, action: #selector(increment), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    @objc func increment() {
        count += 1
        print("Count: \(count)")
    }
}
```

### **How the State is Managed:**

* In this example, the `count` variable is part of a **class** (`ViewController`).
* When the button is clicked, the `count` is **updated** in the shared instance of the class.
* Since **`ViewController` is a reference type**, any change to the `count` will directly reflect in the object, and we can pass the same instance of the `ViewController` around different parts of the app.

### **Benefit of Classes in UIKit:**

* **Shared mutable state**: The state of `count` is shared across the entire `ViewController` instance. All references to that view controller will see the same state.
* **Dynamic behavior**: Classes allow for **inheritance** and **polymorphism**, enabling UIKit to create reusable and customizable UI elements.
* **Deinitializers**: Classes have deinitializers, so you can clean up resources when the object is no longer needed.
                                                
---
                                                
## ⚡ **Comparing Structs and Classes in SwiftUI vs UIKit**
                                                
### **State Management:**
                                                    
* **SwiftUI (Struct-based)**: Views are declarative. Changes in state trigger **view recreation** and updates to the UI based on a **new copy** of the state. This ensures **thread safety** and avoids side effects.
                                                
* **Example**: Updating a `@State` variable causes SwiftUI to **rebuild** the view from scratch.
* **UIKit (Class-based)**: State changes are **mutated in place** in a class instance. The **same object** is referenced throughout, which allows for more **imperative** and **dynamic updates** to the UI.
                                                
* **Example**: Modifying a `UILabel`'s `text` property directly updates the label since it's a reference to the same object.
                                                
### **UI Updates:**
                                                    
* **SwiftUI**: SwiftUI is optimized for **immutable views** (structs), so when you modify the state (e.g., increment a counter), it creates a **new struct** and recalculates the UI.
                                                
* **UIKit**: UIKit relies on **reference semantics**. When a UI component changes, it updates directly in the **shared instance**, so other parts of the code using that instance can also access the latest state.
                                                
### **Performance:**
                                                    
* **SwiftUI**: Since structs are **stack-allocated** and have value semantics, they are typically faster for smaller, simple data. They avoid the overhead of reference counting and memory management (ARC).
                                                
* **UIKit**: Classes are **heap-allocated**, which adds overhead but provides more flexibility for complex UI elements and dynamic states.
                                                
---
                                                
## 📝 **Summary: Structs in SwiftUI vs Classes in UIKit**
                                                
| Feature/Use Case     | **SwiftUI (Structs)**                                    | **UIKit (Classes)**                                                          |
| -------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **State management** | State is **copied** when modified (value type)           | State is **mutated** directly (reference type)                               |
| **View rendering**   | Views are **recreated** with new state                   | Views are **mutated** in place with shared state                             |
| **Performance**      | Efficient for simple, lightweight data (stack-allocated) | More suitable for complex, dynamic data (heap-allocated)                     |
| **Inheritance**      | **No inheritance**, purely value-based design            | **Inheritance** and polymorphism available                                   |
| **Thread safety**    | Safer because structs don’t share mutable state          | May lead to race conditions if shared mutable state is accessed concurrently |
                                                
---
                                                
### **When to use `struct` (SwiftUI)**:
                                                    
* Use `struct` in **SwiftUI** for **simple, lightweight views** that don’t need inheritance or reference-based sharing.
* Works well when you want **predictable, immutable state** and **clear, declarative UI**.
                                                
### **When to use `class` (UIKit)**:
                                                    
* Use `class` in **UIKit** for **complex, dynamic UIs** where **state needs to be shared and mutated** across multiple parts of the app.
* Ideal for **reference semantics** and **inheritance** (e.g., `UIViewController`, `UIView`, and other UIKit components).
                
---
