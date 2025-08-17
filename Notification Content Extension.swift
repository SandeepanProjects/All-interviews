//
//  Notification Content Extension.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

A **Notification Content Extension** in iOS allows you to fully **customize the appearance of push notifications**, providing rich, **interactive, and dynamic UIs** beyond what standard or rich push notifications offer (like custom layouts, buttons, sliders, etc.).

This is especially useful if you want a **mini app-like experience inside a notification**, and yes — you *can integrate SwiftUI via `UIViewControllerRepresentable`*, even though the extension itself uses UIKit.

---

## 🧠 What Is a Notification Content Extension?

* A **separate target** in your Xcode project.
* Lets you define a **custom view controller** to render the push notification.
* Triggered by a specific **`category`** in your push payload.

---

## 🎯 Example Use Cases

* Custom music controls
* Carousel of images
* Live status or progress display
* Action buttons that do more than default behavior

---

## ✅ Step-by-Step: Implement Notification Content Extension in SwiftUI

---

### 🔧 1. **Add the Extension Target**

In Xcode:

1. Go to **File → New → Target**
2. Choose **Notification Content Extension**
3. Give it a name like `CustomNotificationUI`
4. Check "Include Notification View Controller"

Xcode creates:

* `NotificationViewController.swift`
* `MainInterface.storyboard`
* A new target
* An Info.plist for the extension

---

### 🧾 2. **Understand the Key Files**

`NotificationViewController.swift`:

```swift
import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var titleLabel: UILabel!

    func didReceive(_ notification: UNNotification) {
        titleLabel.text = notification.request.content.title
    }
}
```

---

### 🪄 3. **Customize the UI**

#### Option A: **Using Storyboard (Simpler)**

* Open `MainInterface.storyboard`
* Add UI elements (e.g., ImageView, Buttons)
* Connect them to `NotificationViewController.swift` via `@IBOutlet`

#### Option B: **Using SwiftUI (Advanced)**

While you can’t directly use SwiftUI as the root of the extension, you can embed it using `UIHostingController`:

```swift
import SwiftUI
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentView = CustomNotificationView(title: "Loading...")
        let hostingController = UIHostingController(rootView: contentView)
        
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    func didReceive(_ notification: UNNotification) {
        // You can update SwiftUI view via @State if you store it
    }
}

struct CustomNotificationView: View {
    var title: String
    var body: some View {
        VStack {
            Text("🔔 Notification:")
                .font(.headline)
            Text(title)
                .font(.title)
        }
        .padding()
    }
}
```

---

### 🧷 4. **Configure the Info.plist of the Extension**

Make sure this section exists:

```xml
<key>UNNotificationExtensionCategory</key>
<string>customCategory</string>
<key>UNNotificationExtensionDefaultContentHidden</key>
<true/>
<key>UNNotificationExtensionInitialContentSizeRatio</key>
<real>1.0</real>
```

---

### 🛰️ 5. **Send a Push Notification with the Matching Category**

Example payload:

```json
{
  "aps": {
    "alert": {
      "title": "Special Content",
      "body": "Swipe down to view!"
    },
    "category": "customCategory",
    "mutable-content": 1
  }
}
```

> `category` must match the one defined in your extension's Info.plist.

---

### 🧪 6. **Test It on a Real Device**

* Simulators **won’t show the custom UI**
* Use Firebase, Pusher, or `curl` to send push
* Swipe down on notification to reveal the custom content

---

## 🧠 Summary

| Step        | Description                                                |
| ----------- | ---------------------------------------------------------- |
| Add Target  | Add Notification Content Extension                         |
| UI Setup    | Use storyboard or embed SwiftUI with `UIHostingController` |
| Handle Data | Implement `didReceive(_:)` to update UI                    |
| Payload     | Use `"category": "customCategory"` to trigger              |
| Test        | Only works on real devices                                 |

---

## ⚠️ Limitations

* You **can’t use SwiftUI as the root**, but can embed it.
* Media is cached temporarily — must be HTTPS and under 50 MB.
* Extension execution time is limited (\~30s).

---

Would you like a **complete SwiftUI + UIHostingController notification extension** sample project structure, or help with **custom buttons and actions** inside the extension?

Perfect! Let’s walk through building a **complete Notification Content Extension** in SwiftUI using `UIHostingController`, including:

* 🧱 SwiftUI-based custom UI
* 🧩 Notification Extension setup
* 🛰 Push payload with custom `category`
* ✅ Optional: Add **custom buttons** (actions)

---

## 🔧 1. **Project Setup – Add the Extension**

In your existing SwiftUI app project:

1. **File → New → Target → Notification Content Extension**
2. Name it `CustomNotificationUI`
3. Uncheck “Include Notification View Controller” *(if you plan to use SwiftUI directly)*
4. Finish and Xcode will create a new target and Info.plist

---

## 🧠 2. **Create the SwiftUI View**

In your extension target (or shared target if you use shared code), add:

```swift
import SwiftUI

struct CustomNotificationView: View {
    let title: String
    let subtitle: String
    let image: UIImage?

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            }

            Spacer()
        }
        .padding()
    }
}
```

---

## 🧱 3. **Create the `UIViewController` Wrapper**

In `NotificationViewController.swift` (inside your extension target):

```swift
import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    var hostingController: UIHostingController<CustomNotificationView>?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content

        let title = content.title
        let subtitle = content.body
        var image: UIImage? = nil

        if let attachment = content.attachments.first,
           attachment.url.startAccessingSecurityScopedResource() {
            image = UIImage(contentsOfFile: attachment.url.path)
            attachment.url.stopAccessingSecurityScopedResource()
        }

        let view = CustomNotificationView(title: title, subtitle: subtitle, image: image)
        hostingController = UIHostingController(rootView: view)

        if let hostingController = hostingController {
            addChild(hostingController)
            hostingController.view.frame = view.bounds
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
        }
    }
}
```

---

## 🧾 4. **Edit `Info.plist` for the Extension**

Make sure it includes:

```xml
<key>UNNotificationExtensionCategory</key>
<string>customCategory</string>
<key>UNNotificationExtensionDefaultContentHidden</key>
<true/>
<key>UNNotificationExtensionInitialContentSizeRatio</key>
<real>1.0</real>
```

This:

* Links the push `category`
* Hides the default system UI
* Sets your content's size (1.0 = full width)

---

## 🛰️ 5. **Push Notification Payload**

Here’s a working example of what to send:

```json
{
  "aps": {
    "alert": {
      "title": "New Event!",
      "body": "Swipe down to see details"
    },
    "mutable-content": 1,
    "category": "customCategory"
  },
  "media-url": "https://yourserver.com/sample.jpg"
}
```

If you're using a Notification **Service** Extension (for downloading the media), make sure that also adds the attachment.

---

## 🧪 6. **Test on a Real Device**

* You must test **on a real iPhone/iPad**
* Swipe down on the notification to see the custom layout

---

## ➕ Bonus: Add Custom Notification Actions (Buttons)

1. In your main app, register a notification category:

```swift
let likeAction = UNNotificationAction(identifier: "LIKE_ACTION", title: "👍 Like", options: [])
let category = UNNotificationCategory(
    identifier: "customCategory",
    actions: [likeAction],
    intentIdentifiers: [],
    options: [])

UNUserNotificationCenter.current().setNotificationCategories([category])
```

2. Add `"actions"` to your push payload (just add `"category": "customCategory"` – iOS handles the actions).

3. Handle action when the user taps the button:

```swift
UNUserNotificationCenter.current().delegate = self

func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    if response.actionIdentifier == "LIKE_ACTION" {
        print("User liked the notification")
    }
    completionHandler()
}
```

---

## ✅ Summary

| Component    | Description                                 |
| ------------ | ------------------------------------------- |
| SwiftUI View | CustomNotificationView                      |
| Controller   | Wrap SwiftUI in `UIHostingController`       |
| Info.plist   | Define category, hide default UI            |
| Payload      | Must include `"category": "customCategory"` |
| Real Device  | Required for testing                        |

---

Would you like:

* A **complete sample project repo**?
* Help setting up the media download in the Notification Service Extension?
* Support for multiple notification layouts (carousel, timer, etc.)?

Let me know and I’ll get you there!
