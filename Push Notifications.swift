//
//  Push Notifications.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

**how push notifications work under the hood** in iOS, from your app to Apple’s servers and back to the device.

---

## 🧠 **Under the Hood: How Push Notifications Work**

At a high level, push notifications involve **three key components**:

1. **Your App (Client)**
2. **Apple Push Notification service (APNs)**
3. **Your Backend Server**

---

## 🔄 Step-by-Step Flow (With Deep Explanation)

---

### 1. **App Registers with APNs**

**Under the hood:**

* Your app calls:

  ```swift
  UIApplication.shared.registerForRemoteNotifications()
  ```

* iOS sends a request to **APNs**.

* APNs responds with a **unique device token** for that app+device+environment (sandbox or production).

* The app receives the token in:

  ```swift
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  ```

👉 **Device token is like the app’s “address” on Apple’s notification system.**

---

### 2. **App Sends the Device Token to Your Server**

**Under the hood:**

* Your app sends the device token to your backend server (often over HTTPS).
* The server stores the token in a database, associated with the current user or device session.

👉 The backend now knows where to reach the device for future notifications.

---

### 3. **Server Sends a Notification Request to APNs**

**Under the hood:**

* When the server wants to send a push notification, it:

  * Builds a **JSON payload** (e.g. title, body, sound, badge).
  * Sends it over **HTTP/2** to Apple’s APNs servers:
    `https://api.push.apple.com/3/device/<device-token>`

* It must:

  * Include a **valid APNs auth token** (JWT using a `.p8` key).
  * Use the correct **topic** (your app’s bundle identifier).

Example HTTP header:

```http
apns-topic: com.example.MyApp
authorization: bearer <JWT>
```

👉 Apple verifies the token, checks payload size, and queues the notification.

---

### 4. **APNs Delivers Notification to the Device**

**Under the hood:**

* APNs routes the notification to the correct **device + app instance** using the device token.
* If the device is online:

  * It delivers instantly.
* If offline:

  * APNs **queues it temporarily** (usually up to 1–4 hours).
* If the app is **in the background or not running**, iOS displays the notification (via banner, sound, etc.).
* If the app is **in the foreground**, your app’s delegate decides how to handle it.

---

### 5. **User Taps or Interacts with the Notification**

* iOS launches or resumes the app.
* Your app can handle the notification and navigate the user appropriately.

---

## 🧰 What’s Stored Where?

| Component  | Stores                                           |
| ---------- | ------------------------------------------------ |
| Device     | Device Token                                     |
| App Server | Token + User Data                                |
| APNs       | Routes to device, stores notification short-term |

---

## 🧱 Security: How It’s Protected

* **Device tokens are anonymous** — no user-identifying info.
* **Authentication uses a JWT (token-based)** system with a private `.p8` key.
* **Connection to APNs is encrypted via TLS** over HTTP/2.

---

## 🚀 Example Timeline

1. User installs app → App registers with APNs.
2. APNs gives device token → App sends token to server.
3. Server sends push via APNs.
4. APNs delivers it to device.
5. User taps → App handles or navigates based on content.

---

## 🎯 Summary Diagram

```text
App ➡️ APNs (register) ➡️ Device Token
App ➡️ Server (send token)
Server ➡️ APNs (send push w/ token & auth)
APNs ➡️ Device (delivers notification)
User taps ➡️ App responds
```

---

Let me know if you want to go deeper into:

* How APNs manages reliability and queuing
* How to build a simple server to send pushes
* Debugging delivery issues

Or I can draw a full diagram for you!


Push notifications allow your app to receive and display messages sent from a **remote server**, even when your app is not running. They're essential for messaging, alerts, updates, and user engagement.

---

## 🔔 **What Are Push Notifications?**

Push notifications are messages sent from **Apple Push Notification Service (APNs)** to your users' devices. Your app can respond by showing alerts, badges, or custom in-app actions.

---

## 🛠️ **How Push Notifications Work (High-Level)**

1. **Your app** registers with APNs for push notifications.
2. **APNs** returns a **device token**.
3. You send the token to your **server**.
4. Your **server** uses that token to send a push message via APNs.
5. APNs delivers the push to the device.

---

## ✅ **Step-by-Step: Using Push Notifications in SwiftUI**

---

### 1. **Enable Push Notifications in Your App**

* In **Xcode**:

  * Go to your **project > Signing & Capabilities**.
  * Click **+ Capability** → Add **Push Notifications** and **Background Modes**.
  * Under Background Modes, enable **Remote notifications**.

---

### 2. **Request Notification Permissions**

In your `App` struct or inside an `ObservableObject`, request permission:

```swift
import SwiftUI
import UserNotifications

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            print("Permission granted: \(granted)")
        }

        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("Device Token: \(token)")
        // Send token to your server
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}
```

---

### 3. **Handle Incoming Notifications (Optional for Foreground)**

If you want to show notifications while the app is open:

```swift
UNUserNotificationCenter.current().delegate = self
```

Then conform to the delegate:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
```

---

### 4. **Send Notifications from Your Server**

* Your server must:

  * Use the **device token**.
  * Authenticate using an **APNs key or certificate**.
  * Send JSON payloads via HTTP/2 to APNs.

Example JSON payload:

```json
{
  "aps": {
    "alert": {
      "title": "Hello",
      "body": "This is a push notification"
    },
    "badge": 1,
    "sound": "default"
  }
}
```

You can use services like **Firebase Cloud Messaging (FCM)** or **OneSignal** if you don’t want to build your own push backend.

---

## 📦 Tip: Using Firebase for Push in SwiftUI

Firebase offers an easier push setup:

* Install Firebase SDK.
* Configure Firebase Cloud Messaging (FCM).
* Firebase handles device tokens and APNs setup.
* Supports rich notifications and analytics.

---

## ✅ Summary

| Step                       | Purpose                               |
| -------------------------- | ------------------------------------- |
| Enable Capabilities        | Allow app to use push features        |
| Request Permission         | Ask user for notification access      |
| Register for Notifications | Get device token for your server      |
| Handle Notifications       | Show in-app notifications when needed |
| Use Server (or Firebase)   | Send push payloads to APNs or via FCM |

---
