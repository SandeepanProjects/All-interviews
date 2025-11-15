//
//  architecting iOS push notifications.swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

Below is a **complete, end-to-end guide** for architecting **iOS push notifications**—from Apple Push Notification service (APNs) all the way to your iOS client—plus code samples written for **Swift / SwiftUI**.

This explains:

1. **Overall architecture**
2. **APNs concepts**
3. **Server-side requirements**
4. **iOS app implementation**
5. **Notification content, categories, actions**
6. **Silent/background pushes**
7. **Rich notifications**
8. **Common pitfalls + best practices**

---

# 🚀 1. High-Level Architecture of Push Notifications on iOS

### Push pipeline

1. **Your app** asks permission → gets a **device token** from APNs.
2. The **device token** is sent to **your server**.
3. Your **server** sends a push request to **APNs** with your app’s device token.
4. **APNs** delivers the notification to the device.
5. iOS displays the notification OR wakes your app silently (depending on type).

```
Your App → APNs → Device
         ↑
      Your Server
```

Key takeaway: The app itself **never sends notifications directly**. Everything must go through your server → APNs → device.

---

# 🧱 2. APNs Fundamentals

### Device token

A unique identifier generated per device+app. Used by your server to target that device.

### Authentication to APNs

Your server uses one of:

* **JWT-based APNs Key (.p8)** → recommended
* Certificate-based → legacy

### Types of notifications

1. **Alert** → visible message
2. **Badge** → update app badge
3. **Sound** → play sound
4. **Silent** (`content-available: 1`) → wakes your app in background
5. **VoIP Push** → for calling apps
6. **Rich Notification** → includes images, buttons, custom UI

---

# 🗄️ 3. Server Architecture (Brief)

Your server should:

* Store device tokens in a database
* Use a queue/job system for sending notifications
* Send JSON payloads to APNs over HTTP/2

### Example APNs JSON payload

```json
{
  "aps": {
    "alert": {
      "title": "Hello!",
      "body": "This is a test push."
    },
    "badge": 1,
    "sound": "default"
  }
}
```

### Example server endpoint to send push (Node.js snippet)

```js
const apn = require("apn");

let provider = new apn.Provider({
    token: {
        key: "AuthKey_XXXXXX.p8",
        keyId: "YOUR_KEY_ID",
        teamId: "YOUR_TEAM_ID"
    },
    production: false
});

let note = new apn.Notification({
    alert: { title: "Hello", body: "World" },
    sound: "default"
});

note.topic = "com.your.bundleid";

provider.send(note, deviceToken)
```

---

# 📱 4. iOS Side — SwiftUI Implementation (Full Guide)

## Step 1 — Request Notification Permission

You typically do this in `App` or your first screen.

### Swift code (works in SwiftUI)

```swift
import SwiftUI
import UserNotifications

@main
struct PushDemoApp: App {
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
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        UNUserNotificationCenter.current().delegate = self

        requestPermission()
        registerForPushNotifications()
        return true
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            print("Permission granted: \(granted)")
        }
    }

    func registerForPushNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
```

---

## Step 2 — Get the Device Token

APNs returns a device token via AppDelegate callbacks:

```swift
extension AppDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token:", tokenString)

        // TODO: Send this string to your server
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register:", error)
    }
}
```

---

## Step 3 — Handling Notifications When the App Is Foregrounded

iOS won’t show banners while your app is open **unless you allow it**.

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    // App is in foreground → decide how to present it
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
```

---

# 🖼️ 5. Rich Notifications (Images, Buttons, Custom UI)

You need:

1. **Notification Service Extension** → modify notification before delivery
2. **Notification Content Extension** (optional) → custom UI

### Example: load remote image

**Notification Service Extension → NotificationService.swift**

```swift
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let bestAttempt = request.content.mutableCopy() as! UNMutableNotificationContent

        // extract image URL
        if let urlString = request.content.userInfo["image-url"] as? String,
           let url = URL(string: urlString) {

            URLSession.shared.downloadTask(with: url) { location, _, _ in
                if let location {
                    let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("image.jpg")
                    try? FileManager.default.moveItem(at: location, to: tmp)

                    let attachment = try? UNNotificationAttachment(identifier: "image", url: tmp)
                    if let attachment { bestAttempt.attachments = [attachment] }
                }
                contentHandler(bestAttempt)
            }.resume()

        } else {
            contentHandler(bestAttempt)
        }
    }
}
```

---

# 🔄 6. Silent / Background Push (content-available = 1)

Used for background syncing or refreshing data.

### APNs payload

```json
{
  "aps": {
    "content-available": 1
  }
}
```

### iOS capabilities required

Enable **Background Modes → Remote notifications**.

### Handle in AppDelegate

```swift
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    // Perform background work here
    completionHandler(.newData)
}
```

⚠️ Silent pushes are **not guaranteed** and may be throttled.

---

# 🔘 7. Notification Categories & Actions (Interactive Notifications)

### Define category with actions

```swift
let accept = UNNotificationAction(
    identifier: "ACCEPT",
    title: "Accept",
    options: [.foreground]
)

let decline = UNNotificationAction(
    identifier: "DECLINE",
    title: "Decline",
    options: []
)

let category = UNNotificationCategory(
    identifier: "MEETING_INVITE",
    actions: [accept, decline],
    intentIdentifiers: [],
    options: []
)

UNUserNotificationCenter.current().setNotificationCategories([category])
```

### APNs payload must include:

```json
{
  "aps": {
    "category": "MEETING_INVITE",
    "alert": { "title": "Invite", "body": "Join the meeting?" }
  }
}
```

### Handle selected action

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
) {
    switch response.actionIdentifier {
        case "ACCEPT":
            print("User accepted meeting")
        case "DECLINE":
            print("User declined")
        default:
            break
    }
    completionHandler()
}
```

---

# 🧪 8. Testing Push Notifications

### Test w/ Xcode

```
xcrun simctl push <DEVICE_ID> <BUNDLE_ID> payload.apns
```

Example payload:

```json
{
  "aps": {
    "alert": "Hello from simulator!"
  }
}
```

### Tools

* Firebase Cloud Messaging Tester
* Postman (for APNs HTTP/2)
* Custom server script

---

# 🧨 9. Common Pitfalls

| Problem                       | Cause                              | Fix                               |
| ----------------------------- | ---------------------------------- | --------------------------------- |
| Token changes                 | reinstalling app, clearing data    | refresh token every launch        |
| No notification in foreground | iOS default behavior               | use `willPresent`                 |
| Silent push not firing        | throttled, no background mode      | enable Remote Notifications       |
| Rich media not loading        | wrong extension, missing App Group | check service extension logs      |
| Notifications not delivered   | wrong bundle-id/topic              | ensure APNs key matches bundle ID |

---

# 🎉 Summary (Big Picture)

To architect push notifications:

1. **App** asks permission → registers with APNs.
2. **Device token** retrieved → send to server.
3. **Server** creates payload → authenticates → sends to APNs.
4. **APNs** delivers notification to device.
5. **iOS** displays it or wakes your app.

With this setup, you can now build:

* Real-time alerts
* Messaging/chat notifications
* Ecommerce updates
* Background sync
* Rich media pushes
* Interactive actions

---

# Want more?

I can provide:
✅ A full sample Xcode project
✅ A complete server implementation (Node, Python, Go, Kotlin, Swift Server)
✅ A SwiftUI wrapper for push notification events
✅ A notification inbox architecture
✅ A Firebase Cloud Messaging integration guide

Just tell me!

Below is a **production-quality, modular SwiftUI wrapper** for push-notification events **+** a complete **Notification Inbox architecture** (with models, storage, and UI patterns).
This is written to be *copy–paste ready*, and suitable for scalable apps.
                            
---
                            
# 📦 PART 1 — SwiftUI Push Notification Wrapper (Observable + Event Bus)
                            
Goal:
                                
* React to push notifications using **SwiftUI**, not AppDelegate callbacks.
* Receive events for foreground, background, and tapped notifications.
* Provide a shared notification event stream.
                            
---
                            
## ✅ Step 1: Create a NotificationEvent model
                            
```swift
import Foundation
import UserNotifications
                            
enum NotificationEventType {
case receivedForeground
case openedFromBackground
case backgroundSilent
}

struct NotificationEvent: Identifiable {
    let id = UUID()
    let type: NotificationEventType
    let userInfo: [AnyHashable: Any]
    let date: Date = Date()
}
```

---

## ✅ Step 2: Create PushNotificationManager (ObservableObject)

This acts as a **bridge between AppDelegate and SwiftUI**.

```swift
import Foundation
import UserNotifications
import Combine

class PushNotificationManager: NSObject, ObservableObject {
    
    static let shared = PushNotificationManager()
    
    @Published var lastEvent: NotificationEvent?
    @Published var permissionGranted: Bool = false
    @Published var deviceToken: String?
    
    override private init() {}
    
    // MARK: - Public API
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func sendEvent(type: NotificationEventType, userInfo: [AnyHashable:Any]) {
        DispatchQueue.main.async {
            self.lastEvent = NotificationEvent(type: type, userInfo: userInfo)
        }
    }
}
```

---

## ✅ Step 3: AppDelegate → Forward events to the manager

```swift
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        PushNotificationManager.shared.requestPermission()
        return true
    }
    
    // MARK: - Device Token
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        PushNotificationManager.shared.deviceToken = token
    }
    
    // MARK: - Foreground Notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        PushNotificationManager.shared.sendEvent(
            type: .receivedForeground,
            userInfo: notification.request.content.userInfo
        )
        
        completion([.banner, .sound, .badge])
    }
    
    // MARK: - Opened From Background
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completion: @escaping () -> Void
    ) {
        PushNotificationManager.shared.sendEvent(
            type: .openedFromBackground,
            userInfo: response.notification.request.content.userInfo
        )
        completion()
    }
    
    // MARK: - Silent Push
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        PushNotificationManager.shared.sendEvent(
            type: .backgroundSilent,
            userInfo: userInfo
        )
        completionHandler(.newData)
    }
}
```

---

## ✅ Step 4: Inject into SwiftUI App

```swift
@main
struct PushDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var pushManager = PushNotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pushManager)
        }
    }
}
```

---

## ✅ Step 5: Listen to events in any SwiftUI View

```swift
struct ContentView: View {
    @EnvironmentObject var push: PushNotificationManager
    
    var body: some View {
        VStack {
            Text("Push Demo")
            
            if let event = push.lastEvent {
                Text("New Event: \(event.type)")
                Text("Payload: \(event.userInfo.description)")
            }
        }
        .onReceive(push.$lastEvent.compactMap { $0 }) { event in
            handle(event)
        }
    }
    
    func handle(_ event: NotificationEvent) {
        switch event.type {
        case .receivedForeground:
            print("Foreground notification received")
        case .openedFromBackground:
            print("User tapped notification")
        case .backgroundSilent:
            print("Silent push received")
        }
    }
}
```

👆 **This gives you a complete SwiftUI-ready event bus for all push events.**
                                                            
---
                                                            
# 📁 PART 2 — Notification Inbox Architecture (Local Storage + UI)
                                                            
Goal:
Store incoming pushes in local storage and present an inbox like:
Instagram • Facebook • Twitter • WhatsApp
                                                            
Architecture:
                                                                
* 📦 Model: `InboxNotification`
* 🧠 Manager: `NotificationStore`
* 💾 Storage: JSON / CoreData / UserDefaults (we’ll use JSON-file)
* 🎨 UI: SwiftUI List view
* 🔄 Integrate with PushNotificationManager
                                                            
---
                                                            
# 1. Notification Data Model
                                                            
```swift
import Foundation
                                                            
struct InboxNotification: Identifiable, Codable {
    let id: UUID
    let title: String
    let body: String
    let date: Date
    let payload: [String: String]
    var isRead: Bool
    
    init(title: String, body: String, payload: [String:String]) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.payload = payload
        self.date = Date()
        self.isRead = false
    }
}
```

---

# 2. NotificationStore (Local Storage Layer)

```swift
class NotificationStore: ObservableObject {
    @Published var notifications: [InboxNotification] = []
    
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("notifications.json")
    }()
    
    init() {
        load()
    }
    
    // MARK: - CRUD
    
    func add(_ notification: InboxNotification) {
        notifications.insert(notification, at: 0)
        save()
    }
    
    func markRead(_ id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
        }
        save()
    }
    
    func delete(_ offsets: IndexSet) {
        notifications.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Persistence
    
    func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(notifications) {
            try? data.write(to: fileURL)
        }
    }
    
    func load() {
        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: fileURL),
           let result = try? decoder.decode([InboxNotification].self, from: data) {
            notifications = result
        }
    }
}
```

---

# 3. Notification Inbox UI

```swift
struct NotificationInboxView: View {
    @EnvironmentObject var store: NotificationStore
    
    var body: some View {
        List {
            ForEach(store.notifications) { n in
                HStack {
                    VStack(alignment: .leading) {
                        Text(n.title)
                            .font(.headline)
                        Text(n.body)
                            .font(.subheadline)
                        Text(n.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    if !n.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }
                .onTapGesture {
                    store.markRead(n.id)
                }
            }
            .onDelete(perform: store.delete)
        }
        .navigationTitle("Notifications")
    }
}
```

---

# 4. Integrate Push Handler → Inbox Storage

In `ContentView` or the root:

```swift
struct HomeView: View {
    @EnvironmentObject var push: PushNotificationManager
    @EnvironmentObject var inbox: NotificationStore
    
    var body: some View {
        TabView {
            NotificationInboxView()
                .tabItem {
                    Label("Inbox", systemImage: "bell")
                }
        }
        .onReceive(push.$lastEvent.compactMap { $0 }) { event in
            if let content = extractContent(from: event) {
                inbox.add(content)
            }
        }
    }
    
    func extractContent(from event: NotificationEvent) -> InboxNotification? {
        guard let aps = event.userInfo["aps"] as? [String: Any] else { return nil }
        let alert = aps["alert"] as? [String: String]
        
        return InboxNotification(
            title: alert?["title"] ?? "Notification",
            body: alert?["body"] ?? "",
            payload: event.userInfo.compactMapValues { $0 as? String }
        )
    }
}
```

---

# 🎯 End Result

You now have:

### ✅ A universal SwiftUI push notification wrapper

Handles:

* foreground notifications
* background tap events
* silent pushes
* device token acquisition

### ✅ A complete notification inbox system

* Local persistent storage
* SwiftUI inbox UI
* Auto-insert notifications when pushes arrive
* Tap-to-mark-read
* Swipe-to-delete

This is the same architecture used in many production apps with push-based message centers.

---

# Want more?

I can also deliver:

📌 **Rich notification inbox with images, thumbnails, deep links**
📌 **Core Data–backed inbox**
📌 **Integration with Firebase Cloud Messaging (FCM)**
📌 **Server architecture to send inbox-backed notifications**
📌 **Deep-link routing from notification → SwiftUI screen**

Just tell me what you want!
