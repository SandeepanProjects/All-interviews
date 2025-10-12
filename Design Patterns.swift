//
//  Design Patterns.swift
//  
//
//  Created by Apple on 12/10/25.
//

import Foundation

In iOS development, several **design patterns** are commonly used to build clean, maintainable, and scalable apps. These patterns help solve common problems in software design by providing repeatable, proven solutions.

Here’s a breakdown of the **most used design patterns in iOS**, categorized by type:

---

## 🏗️ 1. **Architectural Patterns**

These define the **overall structure** of your app — how components interact, how data flows, etc.

### ✅ MVC (Model-View-Controller) – Apple’s Default Pattern

* **Model**: Your data and business logic
* **View**: UI components
* **Controller**: Mediator between View and Model

✅ Simple, but in practice, **ViewController often becomes bloated** (“Massive View Controller” problem).

---

### ✅ MVVM (Model-View-ViewModel)

* **Model**: Data layer
* **View**: SwiftUI or UIKit UI layer
* **ViewModel**: Binds the model to the view, handles presentation logic

✅ Great for **SwiftUI**
✅ Encourages **unit testing**, **separation of concerns**
🔁 Often used with **Combine** or **ObservableObject**

---

### ✅ VIPER (View-Interactor-Presenter-Entity-Router)

Used in complex apps or highly modular systems.

* **View** – displays what presenter tells
* **Interactor** – handles business logic
* **Presenter** – prepares data for the view
* **Entity** – data models
* **Router** – navigation logic

✅ Super modular and testable
❌ Can be **overkill** for small projects

---

### ✅ Clean Architecture

Layers like:

* **Presentation**
* **Use Cases**
* **Entities**
* **Data / Repositories**

✅ Highly testable and scalable
✅ Popular in enterprise & long-term apps
❌ Verbose for beginners

---

## 🧰 2. **Creational Patterns**

These deal with **object creation**.

### 🔹 Singleton

Only one instance of a class exists.

```swift
class AuthManager {
    static let shared = AuthManager()
    private init() {}
}
```

✅ Good for shared services (e.g., `UserDefaults`, networking, analytics)
❌ Can lead to tight coupling / testing issues if overused

---

### 🔹 Factory

Creates objects without exposing the creation logic.

```swift
protocol Button {}
class iOSButton: Button {}
class AndroidButton: Button {}

class ButtonFactory {
    static func makeButton(for platform: String) -> Button {
        return platform == "iOS" ? iOSButton() : AndroidButton()
    }
}
```

✅ Decouples object creation from usage

---

## 🔁 3. **Behavioral Patterns**

Focus on **communication between objects**.

### 🔹 Observer (Built-in: Combine / NotificationCenter / KVO)

```swift
NotificationCenter.default.addObserver(...)
```

✅ Used for UI updates, state changes, reactive patterns

---

### 🔹 Delegate

Used to pass information back (UIKit uses this heavily).

```swift
protocol MyDelegate: AnyObject {
    func didFinishTask()
}

class Worker {
    weak var delegate: MyDelegate?
}
```

✅ One-to-one communication
✅ Common in `UITableViewDelegate`, `UICollectionViewDelegate`, etc.

---

### 🔹 Coordinator (Custom but popular in iOS)

Separates navigation from view logic.

✅ Clean navigation structure
✅ Helps unit testing
✅ Very useful in SwiftUI apps (as discussed earlier)

---

### 🔹 Command

Encapsulates a request as an object.

✅ Useful for undo/redo operations or queued tasks

---

## 🧱 4. **Structural Patterns**

These deal with **composition of classes and objects**.

### 🔹 Adapter

Makes two incompatible interfaces work together.

✅ Used when integrating third-party libraries

---

### 🔹 Decorator

Adds functionality to objects without changing their code.

✅ Used with views (e.g., `modifier()` in SwiftUI)

```swift
Text("Hello").foregroundColor(.red)
```

---

### 🔹 Facade

Provides a simplified interface to a complex subsystem.

✅ Good for networking, databases, APIs

```swift
class APIService {
    func login(...) { ... }
    func fetchUser(...) { ... }
}
```

---

## ✅ Summary Table

| Pattern Type      | Common Patterns                          |
| ----------------- | ---------------------------------------- |
| **Architectural** | MVC, MVVM, VIPER, Clean Architecture     |
| **Creational**    | Singleton, Factory                       |
| **Behavioral**    | Observer, Delegate, Coordinator, Command |
| **Structural**    | Adapter, Decorator, Facade               |

---

## 🚀 What Should You Use?

| App Size        | Suggested Patterns                               |
| --------------- | ------------------------------------------------ |
| Small           | MVC / MVVM (SwiftUI)                             |
| Medium          | MVVM + Coordinator                               |
| Large / Complex | MVVM or VIPER + Coordinator / Clean Architecture |

---

Sure! Let’s break down the **Command** and **Adapter** design patterns with clear explanations and **real-world iOS examples** in Swift.

---

## 🧭 1. **Command Pattern**

### 🔶 What it is:

The **Command Pattern** encapsulates a request (or action) as an object, allowing you to:

* Parameterize actions (e.g. queue them, log them, undo them)
* Decouple the sender (e.g. button) from the receiver (business logic)

---

### 🛠️ **Real-life analogy:**

Think of a **remote control** (sender) and a **TV** (receiver). Pressing a button sends a command, but the remote doesn’t need to know *how* the TV turns on.

---

### 📱 **iOS Example: Undo System**

Let's create a simple drawing app that supports **undo/redo** using the Command pattern.

---

### 🔸 Step 1: Define Command Protocol

```swift
protocol Command {
    func execute()
    func undo()
}
```

---

### 🔸 Step 2: Concrete Commands

```swift
class DrawLineCommand: Command {
    private let canvas: Canvas
    private let line: Line

    init(canvas: Canvas, line: Line) {
        self.canvas = canvas
        self.line = line
    }

    func execute() {
        canvas.addLine(line)
    }

    func undo() {
        canvas.removeLine(line)
    }
}
```

---

### 🔸 Step 3: Receiver

```swift
class Canvas {
    private(set) var lines: [Line] = []

    func addLine(_ line: Line) {
        lines.append(line)
        print("Draw line: \(line)")
    }

    func removeLine(_ line: Line) {
        lines.removeAll { $0 == line }
        print("Undo line: \(line)")
    }
}

struct Line: Equatable {
    let from: CGPoint
    let to: CGPoint
}
```

---

### 🔸 Step 4: Command Manager

```swift
class CommandManager {
    private var undoStack: [Command] = []

    func execute(_ command: Command) {
        command.execute()
        undoStack.append(command)
    }

    func undoLast() {
        guard let last = undoStack.popLast() else { return }
        last.undo()
    }
}
```

---

### 🔸 Usage

```swift
let canvas = Canvas()
let manager = CommandManager()

let line1 = Line(from: .zero, to: CGPoint(x: 10, y: 10))
let drawCommand = DrawLineCommand(canvas: canvas, line: line1)

manager.execute(drawCommand)   // Draws the line
manager.undoLast()            // Undoes the line
```

---

## ✅ Use Cases in iOS:

* **Undo/redo functionality**
* **Macro recording** (e.g. drawing apps)
* **Queueing background tasks**
* **UI button actions mapped to commands**

---

---

## 🧩 2. **Adapter Pattern**

### 🔶 What it is:

The **Adapter Pattern** allows incompatible interfaces to work together by creating a **wrapper** that “adapts” one type to another.

---

### 🛠️ **Real-life analogy:**

A **power adapter** lets a UK plug work in an EU socket.

---

### 📱 **iOS Example: Wrapping a Legacy Analytics SDK**

Let’s say you’re using a **third-party analytics SDK** that doesn’t conform to your new app’s standard tracking interface.

---

### 🔸 Step 1: Your app’s tracking protocol

```swift
protocol AnalyticsService {
    func track(event: String, properties: [String: Any])
}
```

---

### 🔸 Step 2: Third-party SDK (can't change this)

```swift
class LegacyAnalyticsSDK {
    func sendEvent(_ name: String, withData data: [String: Any]) {
        print("LegacySDK - Sent: \(name)")
    }
}
```

---

### 🔸 Step 3: Create an Adapter

```swift
class LegacyAnalyticsAdapter: AnalyticsService {
    private let sdk = LegacyAnalyticsSDK()

    func track(event: String, properties: [String : Any]) {
        sdk.sendEvent(event, withData: properties)
    }
}
```

---

### 🔸 Usage

```swift
let analytics: AnalyticsService = LegacyAnalyticsAdapter()
analytics.track(event: "UserSignedIn", properties: ["method": "email"])
```

Now your app can work with **any analytics backend** (even legacy ones) by **adapting them to a common interface**.

---

## ✅ Use Cases in iOS:

* **Wrapping third-party SDKs** (analytics, payment, auth)
* **Bridging between Swift and Objective-C APIs**
* Adapting **old code** to **new protocols** without rewriting everything

---

## 🧠 Summary

| Pattern     | Purpose                             | Common Use Case                          |
| ----------- | ----------------------------------- | ---------------------------------------- |
| **Command** | Encapsulates an action as an object | Undo, action queues, macros              |
| **Adapter** | Converts one interface to another   | Legacy SDKs, bridging incompatible types |

---

