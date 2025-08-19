//
//  WebSocket data on a background thread.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Nice! Real-time updates from a WebSocket stream to a list view are a classic scenario where thread safety and UI responsiveness are crucial.

---

## 🎯 Problem Recap

* Data comes in asynchronously from a **background WebSocket stream**.
* UI (list view) needs to update **in real-time**.
* UI updates must happen on the **main thread** to avoid crashes or visual glitches.
* The data source for the list might be shared or mutated concurrently.

---

## ✅ How to Safely Update the UI

### 1. **Receive WebSocket data on a background thread**

WebSocket callbacks typically happen off the main thread.

### 2. **Update your data source safely**

Make sure updates to the underlying model/data array are **thread-safe**.

### 3. **Dispatch UI updates to the main thread**

All UI changes (e.g., `tableView.reloadData()` or SwiftUI state updates) must happen on the **main thread**.

---

## 🧑‍💻 Example in UIKit with `DispatchQueue.main.async`

```swift
func websocketDidReceive(message: Data) {
    // Parse message into model
    let newItem = parseMessage(message)

    // Update data source safely (assuming single-thread access here)
    dataSource.append(newItem)

    // Dispatch UI update on main queue
    DispatchQueue.main.async {
        self.tableView.reloadData()
    }
}
```

---

## 🧑‍💻 Example in SwiftUI using `@MainActor` or `DispatchQueue.main.async`

```swift
@MainActor class ViewModel: ObservableObject {
    @Published var items: [Item] = []

    func handleWebSocketMessage(_ message: Data) {
        let newItem = parseMessage(message)
        items.append(newItem)  // Safe because we're on MainActor
    }
}
```

If your WebSocket callback is off the main thread:

```swift
func websocketDidReceive(message: Data) {
    Task { @MainActor in
        let newItem = parseMessage(message)
        viewModel.items.append(newItem)
    }
}
```

---

## 🔒 Ensuring Thread-Safety of the Data Source

If you have multiple concurrent writers or more complex data mutations:

* Use a **serial dispatch queue** or an **actor** to synchronize mutations.
* For example, wrap your data updates inside a serial queue or inside an actor method.

---

## 📋 Summary

| Step                                   | Description                                |
| -------------------------------------- | ------------------------------------------ |
| **Parse data on background thread**    | Avoid blocking main thread                 |
| **Update data source safely**          | Use serial queue, locks, or actors         |
| **Dispatch UI updates on main thread** | `DispatchQueue.main.async` or `@MainActor` |

---

## Bonus: For High-Frequency Updates

* Consider **batching** updates to avoid excessive UI refreshes.
* Use `tableView.performBatchUpdates` or SwiftUI’s `withAnimation` for smooth changes.
* Debounce or throttle updates if data arrives too rapidly.

---

Would you like a sample SwiftUI live list demo connected to a simulated WebSocket stream?

Awesome! Here’s a simple **SwiftUI example** that simulates receiving data from a WebSocket stream and safely updates a live list in real time using Swift concurrency and `@MainActor`.
                                                                        
---
                                                                        
## 🧑‍💻 SwiftUI Live List with Simulated WebSocket Updates
                                                                        
```swift
import SwiftUI
                                                                        
// Model representing incoming data
struct Message: Identifiable {
    let id = UUID()
    let text: String
}

// ViewModel that receives and publishes updates
@MainActor
class WebSocketViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    // Simulate WebSocket data stream
    func startListening() {
        Task {
            for i in 1...100 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
                
                let newMessage = Message(text: "Message #\(i)")
                
                // Since we're on MainActor, this is safe
                messages.append(newMessage)
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = WebSocketViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.messages) { message in
                Text(message.text)
            }
            .navigationTitle("Live Messages")
            .onAppear {
                viewModel.startListening()
            }
        }
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## How it works:

* The `WebSocketViewModel` is marked with `@MainActor` — all its code runs on the main thread, so updating `@Published messages` is thread-safe.
* `startListening()` simulates incoming messages every 0.5 seconds using `Task.sleep`.
* Each new message is appended to the list, and the UI updates automatically because `messages` is `@Published`.
* The list updates **smoothly and safely** on the main thread.

---

If you want, I can help you modify this to use a real WebSocket (e.g., URLSession WebSocket) or add throttling/batching!
