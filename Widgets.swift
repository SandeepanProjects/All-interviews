//
//  Widgets.swift
//  
//
//  Created by Apple on 24/10/25.
//

import Foundation

Absolutely! Let’s go through **what widgets are** in iOS, how they work under the hood, and then how to **implement one in SwiftUI** — step by step.

---

## 🧩 What Are Widgets?

**Widgets** in iOS are small views that users can add to their **Home Screen**, **Lock Screen**, or **StandBy mode**.
They let users see key info from your app **at a glance** — without opening the app.

Widgets are built using **SwiftUI** and live inside a **Widget Extension** of your app.

Examples:

* Weather app → Shows temperature and conditions.
* Calendar app → Displays upcoming events.
* Fitness app → Shows steps or activity rings.

---

## ⚙️ Widget Architecture

A widget consists of three main parts:

| Component            | Description                                                          |
| -------------------- | -------------------------------------------------------------------- |
| **TimelineProvider** | Supplies data to the widget and tells the system when to refresh it. |
| **Entry**            | A struct that represents one moment’s data in the timeline.          |
| **View**             | The SwiftUI view that displays the entry’s data.                     |

---

## 🧠 How Widgets Work

1. The **system requests a timeline** from your app’s widget extension.
2. You provide a list of **entries** — each with a date and data.
3. The system **renders** the widget at the appropriate time using your SwiftUI view.
4. The widget **refreshes** automatically or when triggered (for example, via a background push).

---

## 🚀 Implementing a Widget in SwiftUI

Let’s build a simple example:
A widget that shows the **current date and a random quote**.

### Step 1. Add a Widget Extension

In Xcode:

1. **File → New → Target**
2. Choose **Widget Extension**
3. Name it something like `QuoteWidget`
4. Make sure *Include Configuration Intent* is **unchecked** (for simplicity now)
5. Finish → Activate the new scheme

---

### Step 2. Create the Data Model

```swift
import WidgetKit
import SwiftUI

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: String
}
```

---

### Step 3. Create the Timeline Provider

```swift
struct QuoteProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: "Loading...")
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let entry = QuoteEntry(date: Date(), quote: "The best time to start is now.")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        let quotes = [
            "Dream big. Start small. Act now.",
            "Stay hungry, stay foolish.",
            "Do one thing every day that scares you."
        ]
        
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let randomQuote = quotes.randomElement() ?? "Keep going."

        let entry = QuoteEntry(date: currentDate, quote: randomQuote)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}
```

Here’s what’s happening:

* `placeholder` → used for previews or loading state.
* `getSnapshot` → used in widget previews.
* `getTimeline` → generates actual content and sets when the widget should update.

---

### Step 4. Create the Widget View

```swift
struct QuoteWidgetEntryView: View {
    var entry: QuoteProvider.Entry

    var body: some View {
        ZStack {
            Color.indigo
            VStack {
                Text(entry.quote)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
    }
}
```

---

### Step 5. Define the Widget

```swift
@main
struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Motivational Quote")
        .description("Displays a random motivational quote.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

---

### Step 6. Preview

```swift
#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(date: Date(), quote: "Believe in yourself!")
}
```

This lets you preview the widget in Xcode.

---

## 🧩 Adding the Widget to Your Home Screen

1. Build and run the app once (so iOS registers the widget).
2. Long-press the Home Screen → Tap “+”.
3. Search for your app’s widget.
4. Add it!

---

## 🧠 Updating Widget Data

To refresh data programmatically, use:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

For example, you can call this from your main app when data changes — the system will request fresh widget content.

---

## ⚡️ Advanced: Types of Widgets

| Widget Type              | Description                                                                                        |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Static widgets**       | Show fixed data (like the above example).                                                          |
| **Intent-based widgets** | Let users configure widget content via an intent (using `IntentTimelineProvider`).                 |
| **Live Activities**      | Show real-time updates on the Lock Screen / Dynamic Island (e.g., tracking a delivery or a score). |

---

## ✅ Summary

| Step | Action                                      |
| ---- | ------------------------------------------- |
| 1    | Add a **Widget Extension** in Xcode         |
| 2    | Define a **TimelineEntry** and **Provider** |
| 3    | Build a **SwiftUI View** for your widget    |
| 4    | Configure your widget with `@main Widget`   |
| 5    | Test, preview, and add to Home Screen       |

---

Would you like me to extend this example to include **a Live Activity** (for real-time updates on the Lock Screen / Dynamic Island)?

Perfect — let’s level up! 🚀
You’ll now learn how to implement a **Live Activity** in SwiftUI — the more dynamic, real-time version of widgets that show up on the **Lock Screen** and **Dynamic Island** (on iPhones with Face ID).
                
                ---
                
## 🧩 What Are Live Activities?
                
**Live Activities** are an extension of widgets introduced in **iOS 16** that allow your app to show **real-time updates** directly on:
                    
* The **Lock Screen**
* The **Dynamic Island** (for iPhone 14 Pro and newer)
                
They’re great for use cases like:
                    
* Food delivery tracking 🍕
* Ride-sharing updates 🚗
* Workout progress 🏋️
* Sports scores ⚽️
                
Unlike normal widgets, **Live Activities** are temporary and updated by your app or via **push notifications**.
                
---
                
## ⚙️ Core Components
                
1. **ActivityAttributes** – defines what your Live Activity tracks.
2. **ActivityContentState** – defines the *changing* data shown.
3. **Live Activity Widget** – SwiftUI views for the Lock Screen and Dynamic Island.
4. **Starting / Updating / Ending** – handled programmatically from your app.
                
---
                
## 🧠 Example: Pizza Delivery Tracker 🍕
                
We’ll build a simple “Pizza Tracker” Live Activity showing:
                    
* Order stage (e.g., “Preparing”, “Out for delivery”, “Delivered”)
* Estimated delivery time
                
---
                
### Step 1. Add a Live Activity Extension
                
In Xcode:
                    
1. **File → New → Target → Widget Extension**
2. Name it something like `PizzaDeliveryWidget`
3. Check ✅ **Include Live Activity**
4. Finish → Activate the new scheme
                
This creates files like:
                    
* `PizzaDeliveryWidget.swift`
* `PizzaDeliveryWidgetBundle.swift`
                
---
                
### Step 2. Define the Activity Attributes
                
In `PizzaDeliveryWidget.swift`:
                    
```swift
import ActivityKit
import WidgetKit
import SwiftUI
                
struct PizzaDeliveryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var estimatedDeliveryTime: Date
    }
    
    // Fixed data for the activity
    var orderNumber: String
}
```

* `ActivityAttributes` describe *fixed* info (e.g., order number).
* `ContentState` describes *changing* info (e.g., delivery status).

---

### Step 3. Create the Widget View

Now we define how the Live Activity looks.

```swift
struct PizzaDeliveryLiveActivityView: View {
    let context: ActivityViewContext<PizzaDeliveryAttributes>
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Order #\(context.attributes.orderNumber)")
                .font(.headline)
            Text(context.state.status)
                .font(.title2)
                .bold()
            Text("Estimated delivery: \(context.state.estimatedDeliveryTime, style: .time)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .activityBackgroundTint(.yellow)
        .activitySystemActionForegroundColor(.black)
    }
}
```

---

### Step 4. Configure the Live Activity Widget

```swift
@main
struct PizzaDeliveryWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PizzaDeliveryAttributes.self) { context in
            // Lock Screen & StandBy UI
            PizzaDeliveryLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("🍕")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.status)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.estimatedDeliveryTime, style: .time)
                        .font(.subheadline)
                }
            } compactLeading: {
                Text("🍕")
            } compactTrailing: {
                Text(context.state.status.prefix(1))
            } minimal: {
                Text("🍕")
            }
        }
    }
}
```

This defines:

* **Lock screen layout**
* **Dynamic Island layout** (expanded, compact, minimal)

---

### Step 5. Start a Live Activity from Your App

In your main app (not the widget target):

```swift
import ActivityKit

func startPizzaActivity() {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        print("Live Activities not allowed.")
        return
    }
    
    let attributes = PizzaDeliveryAttributes(orderNumber: "12345")
    let initialState = PizzaDeliveryAttributes.ContentState(
        status: "Preparing your pizza 🍳",
        estimatedDeliveryTime: Date().addingTimeInterval(30 * 60)
    )
    
    do {
        let activity = try Activity<PizzaDeliveryAttributes>.request(
            attributes: attributes,
            contentState: initialState,
            pushType: nil // set to .token if you plan to update via push
        )
        print("Started Live Activity: \(activity.id)")
    } catch {
        print("Error starting Live Activity: \(error)")
    }
}
```

---

### Step 6. Update or End the Live Activity

You can update it when the order progresses:

```swift
func updatePizzaActivity(status: String) async {
    for activity in Activity<PizzaDeliveryAttributes>.activities {
        let updatedState = PizzaDeliveryAttributes.ContentState(
            status: status,
            estimatedDeliveryTime: Date().addingTimeInterval(10 * 60)
        )
        await activity.update(using: updatedState)
    }
}

func endPizzaActivity() async {
    for activity in Activity<PizzaDeliveryAttributes>.activities {
        await activity.end(dismissalPolicy: .immediate)
    }
}
```

---

### Step 7. Testing in Xcode

* Run the app on a real device (Live Activities don’t appear in the simulator).
* Call `startPizzaActivity()` from a button in your SwiftUI view.
* Lock the device → you’ll see the Live Activity on the Lock Screen and Dynamic Island.

---

## ⚡️ Optional: Update via Push Notifications

If you want server updates:

* Set `pushType: .token` when starting the activity.
* You’ll get a **push token** to your server.
* Use **APNs** to send updates with the `event` type `liveactivity`.

This allows real-time updates from your backend (like tracking a driver).

---

## ✅ Summary

| Step | Action                                        |
| ---- | --------------------------------------------- |
| 1    | Add a **Widget Extension** with Live Activity |
| 2    | Define your `ActivityAttributes`              |
| 3    | Build your **Live Activity view**             |
| 4    | Configure for Lock Screen & Dynamic Island    |
| 5    | Start, update, and end activities in your app |
| 6    | (Optional) Update via APNs push               |
                        
---
                        
Would you like me to show you **how to trigger and test Live Activity updates via push notifications** (using APNs or a local script)?



Test Live Activity updates via push notifications** (using APNs or a local script)
Excellent — this is the fun part 😎

Let’s go step-by-step on how to **trigger and test Live Activity updates via push notifications** using **APNs (Apple Push Notification Service)**.
This is the method Apple recommends for *real-time server-to-device updates*.

---

## 🧩 Why Push Updates for Live Activities?

Live Activities are meant to show **real-time** info even when your app isn’t running.
You can update them in two ways:

1. **Locally** — when your app is active (via `.update(using:)`).
2. **Remotely (Push)** — when your server sends updates via **APNs**.

We’ll set up the second option — it’s how apps like Uber or DoorDash update their “on the way” status.

---

## ⚙️ Overview of Steps

1. Enable **Push Notifications** and **Live Activities** in Xcode
2. Request the Live Activity **with pushType = .token**
3. Retrieve the **push token** and send it to your server
4. Use the **APNs HTTP/2 API** (or a tool like Postman) to send an update payload
5. See your Live Activity update in real time on the Lock Screen / Dynamic Island

---

## 🧠 Step 1. Enable Capabilities in Xcode

In your app **target (not the widget)**:

* Add capability **Push Notifications** ✅
* Add capability **Background Modes → Remote notifications** ✅

In your **widget extension target**:

* Add capability **Live Activities** ✅

---

## 🧩 Step 2. Request the Live Activity with Push Type

When you start your Live Activity, use `.token` to tell iOS that you’ll be updating via APNs:

```swift
import ActivityKit

func startPizzaActivity() {
    let attributes = PizzaDeliveryAttributes(orderNumber: "12345")
    let initialState = PizzaDeliveryAttributes.ContentState(
        status: "Preparing your pizza 🍳",
        estimatedDeliveryTime: Date().addingTimeInterval(30 * 60)
    )

    do {
        let activity = try Activity<PizzaDeliveryAttributes>.request(
            attributes: attributes,
            contentState: initialState,
            pushType: .token
        )

        // You’ll get a push token asynchronously
        Task {
            for await data in activity.pushTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                print("🔑 Live Activity push token: \(token)")
                // Send this token to your backend server
            }
        }
    } catch {
        print("Error starting Live Activity: \(error)")
    }
}
```

Once the activity starts, you’ll see a token like:

```
🔑 Live Activity push token: 847fca29...12be
```

This token uniquely identifies the Live Activity session for APNs.

---

## 🧠 Step 3. Prepare Your APNs Environment

You’ll need:

* An **Apple Developer Account**
* An **APNs key** (in your [Apple Developer account → Certificates, Identifiers & Profiles → Keys](https://developer.apple.com/account/resources/authkeys/list))

  * Download the `.p8` key
  * Note the **Key ID**, **Team ID**, and **Bundle ID**

---

## ⚙️ Step 4. Create the Push Payload

The APNs payload for Live Activities looks like this:

```json
{
  "aps": {
    "timestamp": 1697589600,
    "event": "update",
    "content-state": {
      "status": "Out for delivery 🚗",
      "estimatedDeliveryTime": 1697593200
    },
    "alert": {
      "title": "Pizza Update",
      "body": "Your order is on the way!"
    }
  }
}
```

Notes:

* `"event": "update"` means you’re updating the Live Activity.
* `"content-state"` must match your `ContentState` struct exactly.
* `timestamp` is a UNIX epoch (seconds since 1970).

---

## 🧠 Step 5. Send the Push via HTTP/2

Each Live Activity has a **unique push token** you use as part of the URL.

### Example using `curl`

```bash
curl -v \
--header "apns-topic: com.yourcompany.yourapp.push-type.liveactivity" \
--header "authorization: bearer <your_jwt_token>" \
--header "content-type: application/json" \
--data '{
  "aps": {
    "timestamp": 1697589600,
    "event": "update",
    "content-state": {
      "status": "Out for delivery 🚗",
      "estimatedDeliveryTime": 1697593200
    }
  }
}' \
https://api.sandbox.push.apple.com/3/device/<your_live_activity_push_token>
```

> 💡 The `apns-topic` must be your app’s bundle identifier with `.push-type.liveactivity` appended.
> Example: `com.example.PizzaApp.push-type.liveactivity`

If your app is distributed via TestFlight or App Store, use:

```
https://api.push.apple.com/3/device/
```

If running on a debug build:

```
https://api.sandbox.push.apple.com/3/device/
```

---

## 🪄 Step 6. Testing Alternatives (Postman / Tools)

If you don’t want to build the JWT manually, you can use tools:

* [**APNs Postman Collection**](https://github.com/onmyway133/PushNotifications)
* [**PushHero**](https://github.com/onmyway133/PushHero) — GUI macOS app for APNs testing
* Or a script using **Node.js** or **Python**

---

## 🧩 Step 7. Observe the Update

After sending the push, your Live Activity will immediately update:

* The text, emoji, or time on the **Lock Screen**
* The status in the **Dynamic Island**

You’ll also see the update reflected in logs if you add print statements in your widget’s view.

---

## ✅ Summary

| Step | Action                                                           |
| ---- | ---------------------------------------------------------------- |
| 1    | Enable **Push Notifications** + **Live Activities** capabilities |
| 2    | Request Live Activity with `pushType: .token`                    |
| 3    | Send token to your server                                        |
| 4    | Send APNs payload with `event: "update"`                         |
| 5    | Watch the Live Activity update in real time 🎉                   |
