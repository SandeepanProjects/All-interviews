//
//  SwiftUI’s WindowGroup.swift
//  
//
//  Created by Apple on 17/01/26.
//

import Foundation

Perfect! Let’s go **step by step** and really clarify this. Since you’re asking about **AppDelegate, SceneDelegate, and SwiftUI’s WindowGroup**, plus how to approach **iPhone + iPad development**, I’ll explain everything in detail.

---

## **1️⃣ AppDelegate**

`AppDelegate` is the **traditional entry point** of an iOS app (UIKit era). It handles **application-level lifecycle events**.

Key responsibilities:

| Event                                              | Description                                                         |
| -------------------------------------------------- | ------------------------------------------------------------------- |
| `application(_:didFinishLaunchingWithOptions:)`    | App launched → initialize services here (analytics, DB, API setup). |
| `applicationWillTerminate(_:)`                     | App is about to terminate → save data.                              |
| `applicationDidEnterBackground(_:)`                | App went to background → pause tasks, save state.                   |
| `applicationWillEnterForeground(_:)`               | App will come back → refresh data.                                  |
| `application(_:open url:options:)`                 | Handle deep links, URL schemes.                                     |
| Push notifications & remote notifications handlers | Receive device token, notifications.                                |

**Example:**

```swift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("App launched")
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
    }
}
```

✅ **In modern SwiftUI apps, AppDelegate is optional**, but you may still use it for:

* Push notifications
* Background fetch
* Universal links
* Third-party SDK setup

---

## **2️⃣ SceneDelegate**

Introduced in **iOS 13** when Apple added **multi-window support for iPad**.

**Purpose:** Each “scene” represents a **UI instance** (window). For example:

* iPhone → usually one scene
* iPad → multiple scenes, each can show a separate window

SceneDelegate handles **UI lifecycle**:

| Event                             | Description                                           |
| --------------------------------- | ----------------------------------------------------- |
| `scene(_:willConnectTo:options:)` | Scene is being created → set up root view controller. |
| `sceneDidBecomeActive(_:)`        | Scene is visible → resume tasks.                      |
| `sceneWillResignActive(_:)`       | Scene is going to background → pause tasks.           |
| `sceneDidEnterBackground(_:)`     | Scene is backgrounded → save scene-specific state.    |

**Example (UIKit-style SceneDelegate):**

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
}
```

---

### **Difference between AppDelegate and SceneDelegate**

| Aspect           | AppDelegate                                              | SceneDelegate                                      |
| ---------------- | -------------------------------------------------------- | -------------------------------------------------- |
| Scope            | App-wide                                                 | Scene-specific (window-specific)                   |
| Lifecycle        | Launch / Terminate / Background / Foreground             | Active / Inactive / Background for a single window |
| Use              | Initialize SDKs, handle push notifications, global state | Manage each window’s UI, multiple windows on iPad  |
| Multiple Windows | Only one AppDelegate                                     | Each window has its own SceneDelegate              |

---

## **3️⃣ SwiftUI WindowGroup**

With **SwiftUI 2.0+ (iOS 14+)**, Apple **removed the need for SceneDelegate**. You now use `@main` and **WindowGroup** as the root container.

**WindowGroup**:

* Represents **a group of windows** for your app
* On iPhone → usually just one window
* On iPad → can create **multiple windows of the same type**
* Manages **scene lifecycle automatically**

**Example:**

```swift
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

✅ SwiftUI automatically handles:

* Scene lifecycle (active, inactive, background)
* State restoration for multiple windows
* Integration with iPad multi-window features

---

### **When to use multiple WindowGroup**

Use multiple windows **mainly on iPad** or **macCatalyst**:

* Split view editor apps
* Notes / Mail / Music apps where users can open multiple windows at once
* Multi-document apps

**Example:**

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup("Library") {
            LibraryView()
        }
        WindowGroup("Player") {
            PlayerView()
        }
    }
}
```

* Users can open **Library** and **Player** in **separate windows**.
* SwiftUI handles creation of new scenes/windows automatically.

---

## **4️⃣ Developing for iPhone and iPad (Tips)**

### **UI Strategy**

1. **Universal layout**: Use SwiftUI stacks (`VStack`, `HStack`, `ZStack`) + `GeometryReader` for responsive layouts.
2. **Adaptive views**: Use `.horizontalSizeClass` & `.verticalSizeClass` to switch layouts:

   ```swift
   @Environment(\.horizontalSizeClass) var hSizeClass

   if hSizeClass == .compact {
       // iPhone layout
   } else {
       // iPad layout
   }
   ```
3. **Multi-column UI** on iPad: use `NavigationSplitView` or `SplitView` for master-detail patterns.

### **Multi-window Support**

* iPad → allow users to open multiple documents or app views with **WindowGroup**
* iPhone → usually one window, no need for multiple WindowGroups

### **Platform-specific Features**

* iPad: drag & drop, multitasking, multiple windows, context menus
* iPhone: simpler single-window experience

### **Other Considerations**

* **State restoration**: SwiftUI handles it automatically in WindowGroup
* **Background tasks**: configure via AppDelegate or SwiftUI `@Environment(\.scenePhase)`
* **ScenePhase example**:

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: print("Active")
            case .inactive: print("Inactive")
            case .background: print("Background")
            @unknown default: break
            }
        }
    }
}
```

---

### **Summary Table**

| Concept          | iPhone                              | iPad                         | SwiftUI Modern                                     |
| ---------------- | ----------------------------------- | ---------------------------- | -------------------------------------------------- |
| AppDelegate      | Optional, handles global app events | Same                         | Optional, often only for push notifications & SDKs |
| SceneDelegate    | Usually one scene                   | Multi-window support         | Not used in SwiftUI (WindowGroup replaces it)      |
| WindowGroup      | One main window                     | Multiple windows supported   | Root container for all app UI                      |
| Multiple Windows | Rare                                | Common for productivity apps | Use multiple WindowGroups or `.window(id:)`        |

---

💡 **Key takeaway for SwiftUI app development (iPhone + iPad):**

1. Use **`WindowGroup`** as your main app container.
2. Use **@Environment(.scenePhase)** for lifecycle events.
3. Adapt layout with **size classes** and **NavigationSplitView** for iPad.
4. Use **multiple WindowGroups** only if your app benefits from multiple windows (documents, player + library, etc.).
5. Only use **AppDelegate** for tasks that require global app events (push notifications, background fetch).
6. **SceneDelegate is not needed** in new SwiftUI apps.

---

I can also make a **diagram showing AppDelegate → SceneDelegate → WindowGroup → Multiple windows on iPad** so it’s visually clear how these layers interact.

Do you want me to make that diagram?
