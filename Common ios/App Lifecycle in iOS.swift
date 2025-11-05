//
//  App Lifecycle in iOS.swift
//  
//
//  Created by Apple on 05/11/25.
//

import Foundation

Excellent — let’s go through the **App Lifecycle in iOS** step by step.

Just like a view controller has a **view lifecycle**, an iOS **app** itself has an **application lifecycle** that represents the different states your app can be in — from launch to termination.

---

## 🧭 Overview: App Lifecycle States

An iOS app typically moves through **five main states**:

| State           | Description                                                                                                                   |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Not Running** | The app is not launched, or it’s been terminated by the system.                                                               |
| **Inactive**    | The app is running in the foreground but not receiving events (e.g., during an incoming call or when Control Center is open). |
| **Active**      | The app is running in the foreground and receiving user events — the *normal* state while being used.                         |
| **Background**  | The app is in the background and executing code (e.g., finishing a task, playing music, handling a download).                 |
| **Suspended**   | The app is in memory but not executing code. It can be quickly resumed without reloading.                                     |

---

## 🕹️ The Lifecycle Flow

Here’s what typically happens from launch to termination:

```
Not Running
   ↓
Foreground (Inactive)
   ↓
Foreground (Active)
   ↓
Background
   ↓
Suspended (or Terminated)
```

Let’s look at these transitions in detail 👇

---

## ⚙️ Lifecycle Transitions and Methods

### 1. **App Launch**

When the user taps your app icon (or the system launches it for a background task):

**Delegate Method (Scene-based apps – iOS 13+):**

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
```

→ Called when a new scene (window/UI) is created. Initialize your main interface here.

**For older AppDelegate-based apps:**

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
```

→ Called once when the app finishes launching. Set up global configurations, services, analytics, etc.

---

### 2. **App Becomes Active**

When the app moves to the foreground and starts interacting with the user:

```swift
func sceneDidBecomeActive(_ scene: UIScene)
```

→ Start animations, resume tasks, refresh UI, and handle any paused work.

---

### 3. **App Will Resign Active**

When something interrupts the app temporarily (e.g., a phone call, lock screen):

```swift
func sceneWillResignActive(_ scene: UIScene)
```

→ Pause ongoing tasks, animations, or timers. The app is still visible but not receiving events.

---

### 4. **App Enters Background**

When the user presses the Home button or switches apps:

```swift
func sceneDidEnterBackground(_ scene: UIScene)
```

→ Save data, release shared resources, invalidate timers, and prepare for suspension.

Older API (pre-iOS 13):

```swift
func applicationDidEnterBackground(_ application: UIApplication)
```

---

### 5. **App Enters Foreground**

When the user switches back to your app:

```swift
func sceneWillEnterForeground(_ scene: UIScene)
```

→ Undo the changes made when entering the background, refresh UI, check for updates.

Older API:

```swift
func applicationWillEnterForeground(_ application: UIApplication)
```

---

### 6. **App Termination**

When the app is closed or the system terminates it due to low memory:

```swift
func applicationWillTerminate(_ application: UIApplication)
```

⚠️ **Note:** This is **not always called** (e.g., if the system kills your app while suspended).
Always save critical data when entering the background instead of waiting for termination.

---

## 🧩 Scene vs App Delegate (iOS 13+)

Since **iOS 13**, apps use **scenes** to support multiple windows (especially on iPad).
So lifecycle handling is split:

| Task               | Class           | Method Example                                             |
| ------------------ | --------------- | ---------------------------------------------------------- |
| App launch/setup   | `AppDelegate`   | `application(_:didFinishLaunchingWithOptions:)`            |
| Scene/UI lifecycle | `SceneDelegate` | `sceneDidBecomeActive(_:)`, `sceneWillEnterForeground(_:)` |

---

## 🪄 Example Flow in Logs

When you launch, background, and terminate an app, you might see logs like:

```
App launched → didFinishLaunchingWithOptions
Scene will connect
Scene did become active
--- user presses Home ---
Scene will resign active
Scene did enter background
--- user returns to app ---
Scene will enter foreground
Scene did become active
--- user swipes app away ---
Scene did disconnect
App will terminate
```

---

## 🔍 Visual Summary

```
[Not Running]
     ↓
 [Foreground - Inactive]
     ↓
 [Foreground - Active]
     ↓
 [Background]
     ↓
 [Suspended]
```

Transitions:

* Launch → Active
* Home button → Background → Suspended
* Back to app → Foreground → Active
* Termination → Not Running

---

## 🧠 Best Practices

✅ **Save data** when entering the background — don’t wait for termination.
✅ **Pause work** when inactive; **resume** when active.
✅ **Release resources** and cancel tasks before termination.
✅ **Use scene delegates** for modern iOS apps (iOS 13+).
✅ **Use AppDelegate** only for app-wide concerns (notifications, deep links, etc.).

---

Would you like me to add a **diagram comparing the App Lifecycle and the ViewController Lifecycle** side by side? It’s a great way to visualize how they work together.
