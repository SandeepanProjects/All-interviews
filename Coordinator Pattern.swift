//
//  Coordinator Pattern.swift
//  
//
//  Created by Apple on 12/10/25.
//

import Foundation

The **Coordinator Pattern** is a **design pattern** used in iOS development to **manage navigation and flow** between screens (views), aiming to separate **navigation logic** from **UI logic** (e.g. SwiftUI views or UIKit view controllers).

This is especially useful in larger apps to:

* Avoid deeply nested navigation links
* Keep views clean and focused on presentation, not logic
* Centralize and control navigation flow
* Make unit testing and reuse easier

---

## 🧭 Why Use a Coordinator Pattern in SwiftUI?

In SwiftUI, navigation can easily become complex when:

* Using `NavigationStack` with deep links
* Needing to pass data or manage dependencies
* Navigating based on logic (e.g. auth state)

SwiftUI doesn’t have an official Coordinator implementation like UIKit, but we can build one ourselves.

---

## 📦 Key Components of a Coordinator in SwiftUI

1. **Coordinator Protocol or Base Class** – defines the interface and responsibilities
2. **View Models or Coordinators** – contain navigation logic
3. **Navigation State** – stored centrally, usually with `@Published` or `@Observable` state
4. **Views** – observe navigation state and react accordingly

---

## 🧪 Simple Coordinator Pattern in SwiftUI – Example

### 🔧 Step 1: Define Routes (Navigation States)

```swift
enum AppRoute {
    case home
    case detail(id: Int)
}
```

---

### 🧭 Step 2: Create a Coordinator

```swift
import SwiftUI
import Combine

@Observable
class AppCoordinator {
    var path: [AppRoute] = []

    func pushToDetail(id: Int) {
        path.append(.detail(id: id))
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
```

Here, `path` is bound to a `NavigationStack`, and is updated by the coordinator.

> Note: If you're using iOS 17+, you can use `@Observable` instead of `@Published` with `ObservableObject`.

---

### 📱 Step 3: Define Views that React to Navigation

#### Root View

```swift
struct HomeView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        VStack {
            Text("Home")
            Button("Go to Detail") {
                coordinator.pushToDetail(id: 42)
            }
        }
    }
}
```

#### Detail View

```swift
struct DetailView: View {
    let id: Int
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        VStack {
            Text("Detail View \(id)")
            Button("Back") {
                coordinator.pop()
            }
        }
    }
}
```

---

### 🧱 Step 4: Build Navigation Stack

```swift
struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView(coordinator: coordinator)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView(coordinator: coordinator)
                    case .detail(let id):
                        DetailView(id: id, coordinator: coordinator)
                    }
                }
        }
    }
}
```

---

## ✅ Benefits of This Coordinator Setup

* Keeps **views simple** and focused
* **Centralizes navigation logic**
* Allows for **unit testing** of navigation
* Supports **deep linking**, **conditional routing**, and **more complex flows**

---

## 🧠 Advanced Extensions (Optional)

* Child Coordinators for flows like Onboarding, Auth, etc.
* Combine with `@Environment` to inject coordinator into subviews
* Use `enum + associated values` for rich navigation state
* Support sheet/fullScreenCover in coordinator

---

## ❓Want to Go Further?

I can show:

* A multi-step flow (e.g. onboarding with a child coordinator)
* Managing modals and alerts via coordinator
* Combining this with MVVM
* Using it in a real app architecture (TCA, Clean Architecture, etc.)

Let me know how deep you'd like to go!

Great! Let’s **go deeper** into the **Coordinator Pattern in SwiftUI**, with a more advanced, real-world example — like managing a **multi-step flow** (e.g. onboarding or authentication), using **child coordinators** and **modals**, and combining this with **MVVM (Model-View-ViewModel)** principles.
                
                ---
                
# 🧭 Advanced SwiftUI Coordinator Pattern
                
## 🔥 Scenario:
We'll create an app with two flows:
                    
* **Main App Flow** – Home screen → Detail screen
* **Onboarding Flow** – Multiple screens (Welcome → Permissions → Complete)
                
Each flow is controlled by its **own coordinator**, and the **root coordinator** decides which flow to show.
                
---
                
## 🧱 Project Structure
                
                ```
                AppCoordinator
                ├── OnboardingCoordinator
                │   ├── WelcomeView
                │   ├── PermissionsView
                │   └── OnboardingCompleteView
                └── MainAppCoordinator
                ├── HomeView
                └── DetailView
                ```
                
---

## 1️⃣ Define Navigation Routes
                
```swift
enum AppRoute: Hashable {
case onboarding(OnboardingRoute)
case main(MainRoute)
}

enum OnboardingRoute: Hashable {
    case welcome
    case permissions
    case completed
}

enum MainRoute: Hashable {
    case home
    case detail(Int)
}
```

---

## 2️⃣ AppCoordinator – Handles App Entry Point

```swift
@Observable
class AppCoordinator {
    var isOnboardingCompleted: Bool = false
    var path: [AppRoute] = []
    
    init() {
        start()
    }
    
    func start() {
        if isOnboardingCompleted {
            path = [.main(.home)]
        } else {
            path = [.onboarding(.welcome)]
        }
    }
    
    func handleOnboardingCompletion() {
        isOnboardingCompleted = true
        path = [.main(.home)]
    }
    
    // For navigating inside main flow
    func pushDetail(id: Int) {
        path.append(.main(.detail(id)))
    }
    
    func pop() {
        _ = path.popLast()
    }
}
```

---

## 3️⃣ Onboarding Views & Logic

### Welcome View

```swift
struct WelcomeView: View {
    @Bindable var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("Welcome!")
            Button("Next") {
                coordinator.path.append(.onboarding(.permissions))
            }
        }
    }
}
```

### Permissions View

```swift
struct PermissionsView: View {
    @Bindable var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("Permissions")
            Button("Next") {
                coordinator.path.append(.onboarding(.completed))
            }
        }
    }
}
```

### Onboarding Complete View

```swift
struct OnboardingCompleteView: View {
    @Bindable var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("You're all set!")
            Button("Go to App") {
                coordinator.handleOnboardingCompletion()
            }
        }
    }
}
```

---

## 4️⃣ Main App Views

### Home View

```swift
struct HomeView: View {
    @Bindable var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("Home")
            Button("Go to Detail") {
                coordinator.pushDetail(id: 99)
            }
        }
    }
}
```

### Detail View

```swift
struct DetailView: View {
    let id: Int
    @Bindable var coordinator: AppCoordinator
    
    var body: some View {
        VStack {
            Text("Detail for ID \(id)")
            Button("Back") {
                coordinator.pop()
            }
        }
    }
}
```

---

## 5️⃣ Main Navigation Stack

### Root View

```swift
struct ContentView: View {
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            resolveView(for: coordinator.path.first ?? .onboarding(.welcome))
                .navigationDestination(for: AppRoute.self) { route in
                    resolveView(for: route)
                }
        }
    }

    @ViewBuilder
    func resolveView(for route: AppRoute) -> some View {
        switch route {
        case .onboarding(let onboardingRoute):
            switch onboardingRoute {
            case .welcome:
                WelcomeView(coordinator: coordinator)
            case .permissions:
                PermissionsView(coordinator: coordinator)
            case .completed:
                OnboardingCompleteView(coordinator: coordinator)
            }
        case .main(let mainRoute):
            switch mainRoute {
            case .home:
                HomeView(coordinator: coordinator)
            case .detail(let id):
                DetailView(id: id, coordinator: coordinator)
            }
        }
    }
}
```

---

## ✅ Benefits of This Approach

* **Modular Navigation**: Each flow has a clean boundary
* **Separation of Concerns**: Views focus on UI; coordinators control flow
* **Testable**: Coordinators can be unit tested in isolation
* **Scalable**: Add more flows (login, settings, etc.) without view nesting hell

---

## 💡 Extensions You Can Add

* Use `@EnvironmentObject` or `Environment(\.coordinator)` for global access
* Handle `.sheet`, `.fullScreenCover`, `.alert` inside coordinators
* Use `ObservableObject` with Combine if targeting iOS 16 or earlier
* Wrap child coordinators inside parent with shared app state
                                                                
---
                                                                
## 📌 Summary
                                                                
| Concept            | What it does                                |
| ------------------ | ------------------------------------------- |
| Coordinator        | Controls navigation state & flow logic      |
| Enum-based Routes  | Clean and type-safe navigation destinations |
| Child Coordinators | Manage nested flows like onboarding/auth    |
| ViewBuilders       | Dynamically render views for enum cases     |
                                                                
---
