//
//  Notification Service Extension.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

Implementing a **Notification Service Extension** in a SwiftUI app lets you **download and modify rich push notifications** before they’re displayed — such as adding images, videos, or modifying the content. This is done in a **separate target** using UIKit/UNNotification framework, but it integrates seamlessly with your SwiftUI app.

---

## 🚀 Goal

Enable your SwiftUI app to receive and display **rich push notifications** by using a **Notification Service Extension** to:

* Download media (image, video, audio)
* Attach it to the notification
* Modify notification content before it appears

---

## ✅ Step-by-Step: Implementing Notification Service Extension in SwiftUI

---

### 📦 Step 1: Add the Extension Target

1. In Xcode:
   `File → New → Target → Notification Service Extension`

2. Name it something like:
   `NotificationService`

3. It creates:

   * A new target
   * A class called `NotificationService.swift`
   * A modified `Info.plist`

4. Make sure it's included in the same app group or bundle as your main SwiftUI app.

---

### ✍️ Step 2: Customize the Notification Service Code

Open `NotificationService.swift` and modify it to handle media attachments (e.g., download image):

```swift
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent,
              let mediaURLString = request.content.userInfo["media-url"] as? String,
              let mediaURL = URL(string: mediaURLString) else {
            contentHandler(request.content)
            return
        }

        downloadMedia(from: mediaURL) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Fallback to best effort content
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadMedia(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.downloadTask(with: url) { tempURL, _, _ in
            guard let tempURL = tempURL else {
                completion(nil)
                return
            }

            let fileExtension = url.pathExtension
            let fileName = "media.\(fileExtension)"
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let fileURL = tmpDir.appendingPathComponent(fileName)

            try? FileManager.default.moveItem(at: tempURL, to: fileURL)
            let attachment = try? UNNotificationAttachment(identifier: "media", url: fileURL, options: nil)
            completion(attachment)
        }.resume()
    }
}
```

---

### 📡 Step 3: Send a Rich Push Notification

Your push payload should look like this:

```json
{
  "aps": {
    "alert": {
      "title": "New Photo!",
      "body": "Swipe down to see the image."
    },
    "mutable-content": 1,
    "sound": "default"
  },
  "media-url": "https://yourdomain.com/image.jpg"
}
```

✅ `mutable-content: 1` is **required** to trigger the service extension.

---

### 🧪 Step 4: Test on a Real Device

* Simulators **cannot** display rich push notifications.
* Use:

  * Firebase Cloud Messaging (FCM)
  * APNs via `curl`
  * Push notification testing services (e.g. [Pusher](https://pusher.com/beams), [OneSignal](https://onesignal.com/))

---

### 🧩 Step 5: (Optional) Add a Notification Content Extension

If you want full control over the UI (e.g. SwiftUI-like custom view):

1. Add another target → **Notification Content Extension**
2. Customize its UI using storyboard or Swift.
3. Use a `category` in the payload:

```json
"aps": {
  "alert": { "title": "..." },
  "mutable-content": 1,
  "category": "myCustomCategory"
}
```

Then link that `category` to your content extension in Info.plist.

---

## 📌 Important Notes

| Requirement | Value                                       |
| ----------- | ------------------------------------------- |
| Media URL   | Must be HTTPS and public                    |
| Size Limit  | Max 4 KB payload + 50 MB media              |
| Payload Key | `mutable-content: 1`                        |
| Testing     | Only works on real devices                  |
| Format      | Use `UNNotificationAttachment` to add files |

---

## ✅ Summary

| Step                 | What You Do                                        |
| -------------------- | -------------------------------------------------- |
| Add Extension        | File → New Target → Notification Service Extension |
| Customize Code       | Download and attach media to notification          |
| Update Payload       | Use `mutable-content` and `media-url`              |
| Test                 | Use real device and valid media URL                |
| (Optional) Custom UI | Add Notification Content Extension                 |

---

Would you like a **real working push payload curl example** or a **Firebase config for rich notifications**? I can walk you through it!

Great! Here's a **real working example** of how to send a **rich push notification using `curl` and APNs**, plus a **Firebase Cloud Messaging (FCM)** setup for rich notifications.
                                                      
---

## ✅ PART 1: **APNs + `curl` Example (Direct to Apple Servers)**
                                                      
> This requires an **APNs Auth Key (.p8)** and a **device token** from a real iOS device.
                                                      
---
                                                      
### 🔧 **Prerequisites**
                                                      
* Your app must be:
                                                        
* Push-capable (configured in Xcode)
* Installed on a **real iPhone/iPad**
* You must have:
                                                        
* Your **device token**
* A **.p8 APNs Auth Key**
* Your **team ID**, **key ID**, and **bundle ID**
                                                      
---
                                                      
### 📜 **Example APNs Push Payload (Rich Notification)**
                                                      
```json
{
      "aps": {
          "alert": {
              "title": "Hello from APNs",
              "body": "Swipe down to see the image!"
          },
          "mutable-content": 1,
          "sound": "default"
      },
      "media-url": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Fronalpstock_big.jpg/800px-Fronalpstock_big.jpg"
  }
```
                                                      
---
                                                      
### 🧪 **Sending with `curl`**
                                                      
1. Save your `.p8` APNs key file from Apple Developer Portal.
                                                      
2. Generate a **JWT** (auth token) manually or use a script.
                                                      
3. Send the push:
                                                        
```bash
curl -v \
--http2 \
--header "apns-topic: com.yourcompany.YourApp" \
--header "authorization: bearer <your_jwt_token>" \
--header "apns-push-type: alert" \
--data '{
      "aps": {
          "alert": {
              "title": "Look at this!",
              "body": "This is a rich notification."
          },
          "mutable-content": 1,
          "sound": "default"
      },
      "media-url": "https://yourserver.com/image.jpg"
  }' \
https://api.push.apple.com/3/device/<your_device_token>
```
                                                      
> Replace:
>
> * `com.yourcompany.YourApp` with your app's **bundle ID**
> * `<your_device_token>` with your device token (hex)
> * `<your_jwt_token>` with a valid JWT
                                                      
If you need help generating the JWT, I can provide a script.
                                                      
---
                                                      
## ✅ PART 2: **Firebase (FCM) Rich Push Setup**
                                                      
### 🔧 **Steps to Use FCM for Rich Notifications**
                                                      
1. Add Firebase to your SwiftUI app.
2. Configure Firebase Cloud Messaging.
3. Send a rich push from Firebase Console **or** with `curl`.
                                                      
---
                                                      
### 🧾 Example FCM Rich Payload
                                                      
```json
{
      "to": "<your_fcm_token>",
      "priority": "high",
      "content_available": true,
      "mutable_content": true,
      "notification": {
          "title": "FCM Rich Push",
          "body": "Here’s an image!",
          "sound": "default"
      },
      "data": {
          "media-url": "https://yourserver.com/image.jpg"
      }
  }
```
                                                      
---
                                                      
### 🧪 Send via `curl`:
                                                        
```bash
curl -X POST \
-H "Authorization: key=<your_server_key>" \
-H "Content-Type: application/json" \
-d '{
      "to": "<your_fcm_token>",
      "priority": "high",
      "content_available": true,
      "mutable_content": true,
      "notification": {
          "title": "New Image!",
          "body": "Swipe down to view it",
          "sound": "default"
      },
      "data": {
          "media-url": "https://yourserver.com/image.jpg"
      }
  }' \
https://fcm.googleapis.com/fcm/send
```
                                                      
---
                                                      
### ✅ Result on Device
                                                      
If you’ve set up the **Notification Service Extension** correctly, you’ll see:
                                                        
* A banner with your title and body.
* A **thumbnail of the image** from `media-url`.
* Tapping or expanding shows the full image.
                                                      
---
                                                      
## 🧠 Troubleshooting Tips
                                                      
| Problem                         | Solution                                                              |
| ------------------------------- | --------------------------------------------------------------------- |
| Notification doesn't show media | Make sure `mutable-content: 1` or `mutable_content: true` is included |
| Media doesn’t load              | Media must be publicly available over **HTTPS**, < 50 MB              |
| Doesn’t work in simulator       | Only **real devices** support rich push                               |
| Extension not called            | Double-check target is added and enabled, and `media-url` key exists  |
                                                      
---
                                                      
Would you like:
                                                        
* A JWT generation script for APNs?
* Firebase setup guide in Xcode?
* How to show **custom buttons** or **custom UI** in rich notifications?
                                                      
Let me know — I can walk you through any of these!
