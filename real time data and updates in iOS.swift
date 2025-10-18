//
//  real time data and updates in iOS.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Implementing real-time data and updates in iOS apps typically involves techniques and technologies that allow the app to receive and reflect data changes instantly or near-instantly. Here’s a rundown of common approaches and how you can implement them:

---

### 1. **Using WebSockets**

**What:** WebSockets provide a persistent, full-duplex communication channel between the client (iOS app) and server. It enables the server to push updates instantly.

**How to Implement:**

* Use Apple's native `URLSessionWebSocketTask` (available from iOS 13+) or third-party libraries like [Starscream](https://github.com/daltoniam/Starscream).
* Establish a WebSocket connection with the server.
* Listen for incoming messages and update your UI accordingly.
* Handle connection lifecycle (reconnect, error handling).

**Basic example:**

```swift
import Foundation

class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    
    func connect() {
        let url = URL(string: "wss://yourserver.com/socket")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text: \(text)")
                    // Update your UI or data models here
                case .data(let data):
                    print("Received data: \(data)")
                    // Decode and update
                @unknown default:
                    break
                }
                self?.receiveMessage() // listen for next message
            }
        }
    }
    
    func send(message: String) {
        webSocketTask?.send(.string(message)) { error in
            if let error = error {
                print("Error sending: \(error)")
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
```

---

### 2. **Firebase Realtime Database or Firestore**

**What:** Firebase provides real-time synchronization and offline support out of the box.

**How to Implement:**

* Add Firebase SDK to your project.
* Set up Firebase Realtime Database or Firestore.
* Listen to data changes by observing database references.
* Firebase automatically pushes updates to the client.

**Basic Firestore example:**

```swift
import FirebaseFirestore

let db = Firestore.firestore()

func observeData() {
    db.collection("messages").addSnapshotListener { querySnapshot, error in
        guard let documents = querySnapshot?.documents else {
            print("No documents")
            return
        }
        let messages = documents.compactMap { $0.data()["text"] as? String }
        print("Updated messages: \(messages)")
        // Update UI
    }
}
```

---

### 3. **Push Notifications**

**What:** Use Apple's Push Notification Service (APNs) to notify the app of data updates, then fetch the latest data.

**How to Implement:**

* Set up APNs certificates.
* Configure push notifications in your app.
* Receive silent push notifications (`content-available` flag) to trigger background data fetch.
* Update your app's UI or data upon receiving notification.

---

### 4. **Combine with URLSession Polling**

If your backend doesn't support push or WebSockets, fallback is periodic polling:

* Use `Timer` or `DispatchSourceTimer` to fetch data every few seconds/minutes.
* Compare new data with existing data.
* Update UI if there's a change.

---

### Which to Choose?

| Use Case                                      | Best Option                      |
| --------------------------------------------- | -------------------------------- |
| Full-duplex real-time chat or streaming       | WebSockets                       |
| Simple app with Firebase backend              | Firebase Realtime DB / Firestore |
| Notifications for updates when app not active | Push Notifications               |
| Backend doesn't support push or WebSockets    | Polling                          |

---

If you want, I can help you build a quick demo for any of these! What’s your project about?

Great choice! Firebase Realtime Database and Firestore are super popular for real-time updates in iOS apps because they handle syncing and data change notifications out-of-the-box, with minimal backend work.
                                                                                                                   
Here’s a detailed guide on **how to implement real-time data and updates in iOS using Firebase Firestore** (Firestore is generally preferred nowadays over Realtime Database because of better querying, scalability, and offline support).
                                                                                                                   
---
                                                                                                                   
## Step-by-Step: Real-Time Updates Using Firebase Firestore in iOS
                                                                                                                   
### 1. **Set up Firebase in your iOS Project**
                                                                                                                   
* Go to [Firebase Console](https://console.firebase.google.com/), create a project.
* Add an iOS app to your Firebase project and follow the steps to download `GoogleService-Info.plist`.
* Add `GoogleService-Info.plist` to your Xcode project.
* Using Xcode, install Firebase SDK via Swift Package Manager or CocoaPods:
                                                                                                                                                
**Using Swift Package Manager:**

* File > Add Packages...
* Search for `https://github.com/firebase/firebase-ios-sdk`
* Choose `FirebaseFirestore` (and `FirebaseCore`)

---

### 2. **Initialize Firebase in Your App**
                                                                                                                                              
Edit your `AppDelegate.swift` or your `@main` app struct:
                                                                                                                                                
```swift
import Firebase

@main
struct YourApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---
### 3. **Set Up Firestore**

Import Firestore where you need it:

```swift
import FirebaseFirestore
```

Create a Firestore instance:

```swift
let db = Firestore.firestore()
```

---

### 4. **Listen for Real-Time Updates**

Suppose you have a collection called `"messages"`. You want your app to listen for new messages or updates in real-time.
                                                                                                                                              
```swift
func listenForMessages() {
    db.collection("messages").order(by: "timestamp", descending: false)
        .addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error listening for messages: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            let messages = documents.compactMap { doc -> Message? in
                let data = doc.data()
                guard let text = data["text"] as? String,
                      let timestamp = data["timestamp"] as? Timestamp else { return nil }
                return Message(id: doc.documentID, text: text, timestamp: timestamp.dateValue())
            }
            
            // Update your UI with the latest messages
            print("Updated messages:", messages)
        }
}
```
                                                                                                                                              
Here `addSnapshotListener` listens for any changes to the collection (new docs, updates, deletes) and fires instantly.
                                                                                                                                              
---
                                                                                                                                              
### 5. **Send Data to Firestore**

To add a message to Firestore:

```swift
func sendMessage(text: String) {
    let newMessage = [
        "text": text,
        "timestamp": FieldValue.serverTimestamp()
    ] as [String : Any]
    
    db.collection("messages").addDocument(data: newMessage) { error in
        if let error = error {
            print("Error adding message: \(error.localizedDescription)")
        } else {
            print("Message sent!")
        }
    }
}
```
                                                                                                                                              
---

### 6. **Model Struct Example**

```swift
struct Message: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
}
```

---
                                                                                                                                              
### 7. **Updating UI in SwiftUI**

You can combine this with `@Published` and `ObservableObject` for a reactive UI.
                                                                                                                                              
```swift
class MessagesViewModel: ObservableObject {
    @Published var messages = [Message]()
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func startListening() {
        listener = db.collection("messages").order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                self?.messages = querySnapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    guard let text = data["text"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else { return nil }
                    return Message(id: doc.documentID, text: text, timestamp: timestamp.dateValue())
                } ?? []
            }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    func sendMessage(text: String) {
        let newMessage = [
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        db.collection("messages").addDocument(data: newMessage) { error in
            if let error = error {
                print("Error adding message: \(error)")
            }
        }
    }
}
```
                                                                                                                                              
Then in your SwiftUI view:
                                                                                                                                                
```swift
struct ContentView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        VStack {
            List(viewModel.messages) { message in
                Text(message.text)
            }
            
            Button("Send Hello") {
                viewModel.sendMessage(text: "Hello Firebase!")
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}
```
                                                                                                                                              
---

## Summary

* Use Firestore's `addSnapshotListener` for real-time updates.
* Data updates flow automatically to your app when changes occur in Firestore.
* Use `FieldValue.serverTimestamp()` to keep consistent timestamps.
* Connect with SwiftUI using `ObservableObject` and `@Published` to update your UI reactively.

---

