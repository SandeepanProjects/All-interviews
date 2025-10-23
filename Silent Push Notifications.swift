//
//  Silent Push Notifications.swift
//  
//
//  Created by Apple on 23/10/25.
//

import Foundation

Sure — let’s go step-by-step and make this clear for **iOS + SwiftUI**.

---

## 🧩 What Are Silent Push Notifications?

A **silent push notification** (also called a **background notification**) is a push notification that **does not alert the user** — no sound, no banner, no vibration — but instead **wakes your app in the background** so it can perform a task.

Typical uses:

* Syncing new data from a server
* Updating app content in the background
* Managing background downloads or uploads
* Refreshing data before the user opens the app

---

## 🔒 Key Characteristics

| Property                  | Value                                                |
| ------------------------- | ---------------------------------------------------- |
| `content-available`       | Must be set to `1` in the APNs payload               |
| `alert`, `sound`, `badge` | Omitted or empty (no visible UI)                     |
| Requires                  | Background Modes → *Remote Notifications* capability |
| Delivery                  | Best effort (Apple may throttle or delay)            |

---

## 📨 Example Payload

```json
{
  "aps": {
    "content-available": 1
  },
  "data": {
    "task": "sync",
    "timestamp": "2025-10-23T12:00:00Z"
  }
}
```

> ⚠️ No `alert`, `sound`, or `badge` — this ensures it’s silent.

---

## ⚙️ Steps to Implement in iOS (SwiftUI or UIKit)

### 1. Enable Background Mode

In **Xcode**:

* Go to your app target → **Signing & Capabilities**
* Add **Background Modes**
* Check **Remote notifications**

This allows the app to wake for silent pushes.

---

### 2. Register for Push Notifications

Even though it’s silent, you still need to register for push notifications:

```swift
import SwiftUI
import UserNotifications

@main
struct SilentPushApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Send deviceToken to your server
    }
}
```

> Silent pushes still require a valid **device token** from APNs.

---

### 3. Handle Silent Push in Background

You handle silent pushes using this method:

```swift
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    guard let aps = userInfo["aps"] as? [String: Any],
          aps["content-available"] as? Int == 1 else {
        completionHandler(.noData)
        return
    }

    // Perform background task
    Task {
        await refreshDataFromServer()
        completionHandler(.newData)
    }
}
```

> ✅ This method will be called **even when your app is not in the foreground**, if the system allows it.

---

### 4. Important Notes

* **Throttling:** Apple may limit frequency if your app abuses silent pushes.
* **No guarantee:** Delivery is *best effort*; if the device is low on power or the app is force-quit, the system may skip it.
* **Testing:** You can test silent notifications using tools like `xcrun simctl push` or Postman with APNs tokens.

---

## 🧠 Example Use Case

Let’s say you have a news app.
When a new article is published:

1. Your server sends a silent push with `content-available: 1`.
2. The app wakes up briefly in the background.
3. It fetches new articles from your API.
4. Next time the user opens the app, content is already updated.

---

Would you like me to show you a **complete working example project structure** (SwiftUI + AppDelegate + mock server push)?
It’ll help you see where each piece fits.

Perfect 👍 — let’s walk through a **complete working example** of implementing **silent push notifications** in a SwiftUI app using `AppDelegate`.
                                                    
We’ll go end-to-end, from Xcode setup → SwiftUI code → payload example → testing.
                                                    
---
                                                    
## 🏗️ Project Setup (Xcode)
                                                    
1. Create a new **iOS App** project using **SwiftUI**.
2. Go to **Signing & Capabilities** → add:
                                                        
* ✅ **Push Notifications**
* ✅ **Background Modes** → check **Remote notifications**
                                                    
This lets your app wake up when a silent notification arrives.
                                                    
---
                                                    
## 🧱 File: `SilentPushApp.swift`
                                                    
This is your main SwiftUI entry point that attaches an `AppDelegate` for background handling.
                                                    
```swift
import SwiftUI
import UserNotifications
                                                    
@main
struct SilentPushApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## ⚙️ File: `AppDelegate.swift`

Handles registration, receiving push tokens, and background fetch when a silent notification arrives.

```swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Ask for permission (optional for silent, but needed if you also use alerts)
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: []) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            } else {
                print("Notification permission: \(granted)")
            }
        }
        
        // Register for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
        return true
    }
    
    // Get device token for APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        // Send this token to your backend server
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for notifications: \(error)")
    }
    
    // Handle silent push notifications
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📩 Received remote notification: \(userInfo)")
        
        guard let aps = userInfo["aps"] as? [String: Any],
              aps["content-available"] as? Int == 1 else {
            completionHandler(.noData)
            return
        }
        
        Task {
            // Simulate background fetch
            await refreshDataFromServer()
            completionHandler(.newData)
        }
    }
    
    // Example: pretend to fetch data from server
    private func refreshDataFromServer() async {
        print("🔄 Refreshing data from server...")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        print("✅ Data refreshed successfully.")
    }
}
```

---

## 🪧 File: `ContentView.swift`

Just a simple SwiftUI view so you can see when updates happen.

```swift
import SwiftUI

struct ContentView: View {
    @State private var statusMessage = "Waiting for silent push..."
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Silent Push Demo")
                .font(.title)
                .padding()
            
            Text(statusMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
        }
        .onAppear {
            print("🟢 App launched and ready for silent pushes.")
        }
    }
}
```

---

## 📨 Silent Push Payload (for APNs)

Send this payload via your backend or a tool like [Postman] or `xcrun simctl push`:

```json
{
    "aps": {
        "content-available": 1
    },
    "data": {
        "action": "refresh",
        "timestamp": "2025-10-23T12:00:00Z"
    }
}
```

---

## 🧪 Testing in Simulator or Device

### 🧰 Using Simulator

You can simulate a silent push in Terminal:

```bash
xcrun simctl push booted com.yourcompany.SilentPushDemo silent.json
```

(where `silent.json` contains the payload above)

### 📱 Using a Device

1. Install the app on a physical device (silent pushes don’t work on Simulator unless manually simulated).
2. Use your APNs token to send a push via:

* **Firebase Cloud Messaging**
* **AWS SNS**
* or **Apple’s APNs** with an HTTP/2 request.

---

## ⚠️ Important Notes

* Silent pushes won’t wake your app if:
                                            
* The user force-quit it (swiped away).
* The device is in Low Power Mode or Doze.
* You send them too frequently (Apple throttles them).
                                        
* For better reliability, pair silent pushes with **Background App Refresh**.
                                        
                                       
