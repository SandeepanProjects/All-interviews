//
//  View vs Event handling .swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

Below is a **clear, interview-ready explanation of *View vs Event Handling***, framed for **iOS / UI architecture discussions**. This topic often tests whether you understand **separation of concerns**, **MVC/MVVM**, and **testability**, not just UIKit mechanics.

---

## 1. What Is a View?

### Definition

A **View** is responsible for:

* **Rendering UI**
* **Displaying state**
* **Forwarding user interactions**

It should **not own business logic**.

### Examples

* `UIView`, `UILabel`, `UIButton`
* SwiftUI `View`

### What a View *should* do

✅ Layout
✅ Styling
✅ Show data
✅ Expose interaction hooks

```swift
class ProfileView: UIView {
    let button = UIButton()

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc private func tapped() {
        onTap?()
    }
}
```

> The view **forwards the event**, it does not decide what it means.

---

## 2. What Is Event Handling?

### Definition

**Event handling** is:

* Interpreting user actions
* Deciding what should happen
* Triggering navigation, business logic, or state changes

### Where it belongs

* `UIViewController` (MVC)
* `ViewModel` / Coordinator (MVVM)
* Reducer (Redux / TCA)

---

## 3. UIKit: View vs Event Handling (MVC)

### View (`UIView`)

```swift
class LoginView: UIView {
    var onLoginTapped: (() -> Void)?

    @objc func didTapLogin() {
        onLoginTapped?()
    }
}
```

### Controller (`UIViewController`)

```swift
class LoginViewController: UIViewController {
    let loginView = LoginView()

    override func viewDidLoad() {
        super.viewDidLoad()
        loginView.onLoginTapped = { [weak self] in
            self?.handleLogin()
        }
    }

    func handleLogin() {
        // validate, call API, navigate
    }
}
```

### Key separation

| Layer      | Responsibility        |
| ---------- | --------------------- |
| View       | Emits events          |
| Controller | Handles meaning       |
| Model      | Data / business rules |

---

## 4. SwiftUI: View vs Event Handling

### SwiftUI View

```swift
Button("Login") {
    viewModel.loginTapped()
}
```

### ViewModel

```swift
final class LoginViewModel: ObservableObject {
    func loginTapped() {
        // business logic
    }
}
```

SwiftUI views:

* Are **value types**
* Describe UI
* Delegate behavior

---

## 5. Why Separation Matters (Interview Gold)

### ❌ Bad (View handles logic)

```swift
button.addAction {
    if username.isEmpty {
        showError()
    }
}
```

Problems:

* Hard to test
* Reusable view becomes context-dependent
* Business logic tied to UI

---

### ✅ Good (View forwards event)

```swift
onSubmit?()
```

Logic lives elsewhere.

---

## 6. Event Handling Patterns

### 1️⃣ Target-Action

* UIKit standard
* Simple but limited

### 2️⃣ Closures

* Decoupled
* Common in modern UIKit

```swift
view.onTap = { }
```

### 3️⃣ Delegates

* Strong typing
* Good for complex interactions

```swift
protocol LoginViewDelegate: AnyObject {
    func didTapLogin()
}
```

### 4️⃣ Combine / Observables

* Reactive event streams

```swift
button.publisher(for: .touchUpInside)
```

---

## 7. Who Owns Navigation?

**Never the View**

Navigation belongs to:

* ViewController
* Coordinator
* Router

Views should **not**:
❌ Push view controllers
❌ Present modals

---

## 8. Event Handling & Memory

Common bug:

```swift
view.onTap = {
    self.doSomething()
}
```

Fix:

```swift
view.onTap = { [weak self] in
    self?.doSomething()
}
```

Views are often retained by controllers → retain cycle risk.

---

## 9. Interview Trick Question

> “Can a View handle events?”

**Correct answer**

> “A view can detect and forward events, but it shouldn’t interpret or act on them beyond UI feedback.”

---

## 10. View vs Event Handling — One-Sentence Answer

> “Views are responsible for presenting UI and emitting user events, while event handling interprets those events and triggers business logic or navigation in controllers or view models.”

---

## 11. Quick Comparison Table

| Aspect        | View     | Event Handling |
| ------------- | -------- | -------------- |
| Purpose       | Display  | Decide         |
| Logic         | UI only  | Business       |
| Testability   | Snapshot | Unit           |
| Navigation    | ❌        | ✅              |
| State changes | ❌        | ✅              |

---

## 12. When Interviewers Push Further…

They may ask:

* “Where would validation logic live?”
* “How do you handle gestures?”
* “How does this change in SwiftUI?”
* “How do you avoid massive ViewControllers?”

I can walk you through **real follow-up answers** or **architecture diagrams** if you want.
