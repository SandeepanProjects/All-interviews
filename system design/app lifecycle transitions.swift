//
//  app lifecycle transitions.swift
//  
//
//  Created by Apple on 14/04/26.
//

import Foundation

In iOS, the **app lifecycle** defines how your app moves between different states as users interact with it or as the system manages resources. Understanding these transitions is critical for building stable, performant apps.

Let’s break it down clearly 👇

---

# 📱 App Lifecycle States (Modern iOS)

With UIKit / SwiftUI, apps move through these states:

### 1. **Not Running**

* App is not launched or was terminated
* No code is executing

---

### 2. **Inactive**

* App is in foreground but not receiving events
* Happens during:

  * Incoming calls
  * Control Center pulled down
  * App transitioning states

👉 Short-lived state

---

### 3. **Active**

* App is in foreground and interactive
* User is actively using it

---

### 4. **Background**

* App is executing code but not visible
* Limited execution time unless special modes enabled

---

### 5. **Suspended**

* App is in memory but not executing code
* System may kill it anytime to free memory

---

# 🔄 Lifecycle Transitions (What Actually Happens)

Let’s go through real transitions and what you should do:

---

## 🚀 Launch: Not Running → Active

### Flow:

```
Not Running → Inactive → Active
```

### Key Methods:

* `application(_:didFinishLaunchingWithOptions:)`
* Scene-based:

  * `scene(_:willConnectTo:)`
  * `sceneDidBecomeActive(_)`

### What to do:

* Initialize dependencies (DI container, services)
* Setup UI
* Restore state if needed

---

## ⚠️ Interruption: Active → Inactive

### Causes:

* Phone call
* Notification interruption
* Multitasking gesture

### Method:

* `sceneWillResignActive(_)`

### What to do:

* Pause:

  * Animations
  * Timers
  * Ongoing tasks

---

## ⬇️ Move to Background: Inactive → Background

### Method:

* `sceneDidEnterBackground(_)`

### What to do:

* Save critical data (Core Data, files)
* Release heavy resources
* Stop unnecessary work
* Schedule background tasks if needed

---

## 🔙 Return to Foreground: Background → Inactive → Active

### Methods:

* `sceneWillEnterForeground(_)`
* `sceneDidBecomeActive(_)`

### What to do:

* Refresh UI
* Resume paused tasks
* Re-sync data if needed

---

## ❌ Termination: Background/Suspended → Not Running

### Method:

* `applicationWillTerminate(_)` *(not always called!)*

### Important:

* System may kill app silently

### What to do:

* Never rely on termination callback
* Always save state in background phase

---

# 🧠 Scene-Based Lifecycle (iOS 13+)

With multi-window support:

* Each **scene** has its own lifecycle
* Managed via:

  * `UISceneDelegate`

👉 Apps can have multiple active scenes (iPad multitasking)

---

# ⚡ SwiftUI Lifecycle

In SwiftUI:

```swift
@main
struct MyApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("Active")
            case .inactive:
                print("Inactive")
            case .background:
                print("Background")
            default:
                break
            }
        }
    }
}
```

---

# 🔥 Real-World Interview Insights (Staff Level)

### 1. **Data Loss Prevention**

* Save data in `background`, not `termination`

---

### 2. **Crash Prevention**

* Avoid heavy work during transitions
* Use background queues

---

### 3. **Performance**

* Release memory-heavy objects in background
* Lazy load when returning to active

---

### 4. **Networking Strategy**

* Cancel or pause requests when going inactive
* Resume or retry when active

---

### 5. **Security**

* Blur sensitive screens when moving to background (banking apps)

---

# 🎯 Common Mistakes

* ❌ Doing heavy work in `sceneDidBecomeActive`
* ❌ Not saving state before background
* ❌ Assuming app won’t be killed
* ❌ Ignoring inactive state

---

# 🧩 Simple Mental Model

Think of lifecycle like this:

```
Launch → Use → Interrupt → Background → Return → Kill
```

---

If you want, I can go deeper into:

* Background execution modes (VoIP, location, etc.)
* Handling lifecycle in large-scale apps (like WhatsApp/Instagram)
* Lifecycle-related crash debugging strategies

Just tell me 👍
