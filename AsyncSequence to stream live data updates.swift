//
//  Building a chat system with streaming messages.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Perfect! Let's walk through how to use **`AsyncSequence`** to **stream live data updates** — such as **search suggestions**, **real-time sensor data**, or **chat messages** — in a clean, Swift Concurrency-native way.

---

## 📡 Goal: Live Search Suggestions with `AsyncSequence`

You’ll learn how to:

* Use `AsyncSequence` via `AsyncStream` to emit values over time.
* Debounce input like search text (simulate user typing).
* Handle cancellation and updates efficiently.
* Use `Task` to process and display streaming results in SwiftUI.

---

## 📦 Concept Overview

| Concept           | Swift Feature              |
| ----------------- | -------------------------- |
| Event stream      | `AsyncStream`              |
| Continuous input  | e.g., typing a search term |
| Controlled output | Emit via `yield()`         |
| Process values    | `for await in` loop        |
| Cancel/refresh    | Use `Task.cancel()`        |

---

## 🛠 1. Async Search Stream using `AsyncStream`

Let’s simulate a search service that emits results every time the user types.

```swift
class SearchService {
    func searchSuggestions(for query: String) async -> [String] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        return ["\(query) Result 1", "\(query) Result 2", "\(query) Result 3"]
    }

    func suggestionStream(for textStream: AsyncStream<String>) -> AsyncStream<[String]> {
        AsyncStream { continuation in
            Task {
                for await text in textStream {
                    let results = await searchSuggestions(for: text)
                    continuation.yield(results)
                }
                continuation.finish()
            }
        }
    }
}
```

* `textStream`: Emits search terms.
* `suggestionStream`: Transforms each search term into search results.
* Debounce logic can be layered if needed (we’ll add later).

---

## 🧠 2. ViewModel that Sends User Input as AsyncStream

```swift
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [String] = []

    private let searchService = SearchService()
    private var queryContinuation: AsyncStream<String>.Continuation?
    private var queryStream: AsyncStream<String>?
    private var processingTask: Task<Void, Never>?

    init() {
        let stream = AsyncStream<String> { continuation in
            self.queryContinuation = continuation
        }
        self.queryStream = stream

        processingTask = Task {
            guard let queryStream = queryStream else { return }
            for await suggestions in searchService.suggestionStream(for: queryStream) {
                self.results = suggestions
            }
        }
    }

    func updateQuery(_ newText: String) {
        queryContinuation?.yield(newText)
    }

    deinit {
        queryContinuation?.finish()
        processingTask?.cancel()
    }
}
```

* The `ViewModel` turns `@Published query` updates into an `AsyncStream`.
* It pipes those through the `SearchService` stream.
* It updates `results` as new data arrives.

---

## 🖼 3. SwiftUI View with Real-Time Search Suggestions

```swift
struct LiveSearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.results, id: \.self) { result in
                Text(result)
            }
            .searchable(text: Binding(
                get: { viewModel.query },
                set: {
                    viewModel.query = $0
                    viewModel.updateQuery($0)
                }
            ))
            .navigationTitle("Live Search")
        }
    }
}
```

* Uses `.searchable` (iOS 15+) to bind search input.
* On every change, sends the new query to the async stream.
* `AsyncStream` lets us **respond to input changes over time**, naturally.

---

## ⏱ Bonus: Debounce Search Input

To debounce (avoid firing too many searches too fast), add delay inside the loop:

```swift
func suggestionStream(for textStream: AsyncStream<String>) -> AsyncStream<[String]> {
    AsyncStream { continuation in
        Task {
            var lastQuery: String?
            for await text in textStream {
                // Debounce logic
                if lastQuery == text { continue }
                lastQuery = text

                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

                let results = await searchSuggestions(for: text)
                continuation.yield(results)
            }
            continuation.finish()
        }
    }
}
```

---

## 🧼 Why This is Powerful

* `AsyncStream` fits naturally with Swift Concurrency.
* Easy to cancel — no need for Combine’s `.sink`, `debounce`, etc.
* Fully async/await-compatible.
* Plays well with SwiftUI’s lifecycle.

---

## 🧪 Other Use Cases for `AsyncSequence` / `AsyncStream`

* 🛰 Live data updates from WebSockets.
* ⌨️ Search-as-you-type (as shown).
* 📦 File upload/download progress.
* 📱 Motion sensor updates (e.g., accelerometer).
* 🧭 Location updates via `CLLocationManager`.

---

Would you like a more **complex streaming example**, like:

* Integrating with **WebSockets**?
* Streaming **CoreLocation** updates?
* Building a **chat system** with streaming messages?

Let me know what you're building!
Perfect — let’s build a **real-time chat system using `AsyncSequence` and Swift Concurrency**, step by step.
                                
---
                                
## 🎯 Goal: Build a Chat System with Streaming Messages
                                
We’ll simulate a real-time chat where:

* Messages are sent and received.
* Incoming messages are streamed using `AsyncStream`.
* Outgoing messages are handled with async methods.
* SwiftUI updates the UI automatically.

> ✅ We'll keep it local (no backend), but structure it in a way that it can easily plug into real WebSocket or networking code.

---

## 🗂 What We'll Build

| Feature                | Technology                        |
| ---------------------- | --------------------------------- |
| Live incoming messages | `AsyncStream<Message>`            |
| Send messages          | Async `send()` method             |
| UI updates             | SwiftUI + `@Published`            |
| Simulated server       | Background `Task` that emits data |

---

## 🧩 1. Define a `Message` model

```swift
struct Message: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let isIncoming: Bool
    let timestamp: Date
}
```

---

## ⚙️ 2. ChatService with Streaming (`AsyncStream`)

```swift
final class ChatService {
    private var streamContinuation: AsyncStream<Message>.Continuation?
    private var incomingStream: AsyncStream<Message>?
    
    init() {
        let stream = AsyncStream<Message> { continuation in
            self.streamContinuation = continuation
        }
        self.incomingStream = stream
        
        simulateIncomingMessages()
    }
    
    func getMessageStream() -> AsyncStream<Message> {
        guard let stream = incomingStream else {
            fatalError("Stream not initialized")
        }
        return stream
    }
    
    func sendMessage(_ message: String) async {
        let sentMessage = Message(text: message, isIncoming: false, timestamp: .now)
        streamContinuation?.yield(sentMessage)
        
        // Optional: Simulate server echo back
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 sec delay
        let reply = Message(text: "Echo: \(message)", isIncoming: true, timestamp: .now)
        streamContinuation?.yield(reply)
    }
    
    func simulateIncomingMessages() {
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // every 5 sec
                let botMessage = Message(text: "Server says hi! \(Int.random(in: 1...1000))", isIncoming: true, timestamp: .now)
                streamContinuation?.yield(botMessage)
            }
        }
    }
    
    func close() {
        streamContinuation?.finish()
    }
}
```

* `getMessageStream()` returns a streaming sequence.
* `sendMessage()` yields both outgoing and incoming (echoed) messages.
* `simulateIncomingMessages()` adds random messages every 5 seconds.

---

## 🧠 3. ViewModel Handling the Stream

```swift
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    
    private let chatService = ChatService()
    private var streamTask: Task<Void, Never>?
    
    init() {
        startListening()
    }
    
    func startListening() {
        let stream = chatService.getMessageStream()
        
        streamTask = Task {
            for await message in stream {
                messages.append(message)
            }
        }
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        inputText = ""
        
        Task {
            await chatService.sendMessage(text)
        }
    }
    
    deinit {
        streamTask?.cancel()
        chatService.close()
    }
}
```

* Listens to the stream with `for await`.
                                    * Appends messages to the `@Published` list.
                                    * Sends user input using `sendMessage()`.
                                    
                                    ---
                                    
                                    ## 🖼️ 4. SwiftUI Chat Interface
                                    
                                    ```swift
                                    struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            HStack {
                                if message.isIncoming {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            
            HStack {
                TextField("Type a message", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    viewModel.sendMessage()
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
    }
}
```

---

## ✅ What You’ve Built

* Real-time chat using `AsyncStream` as message bus.
* Handles both outgoing and incoming messages.
* Automatically updates UI and scrolls.
* Debounces input naturally using the stream.
* Easily swappable for **WebSockets**, **Firebase**, or **backend push**.
                            
                            ---
                            
                            ## 🔌 Plug into WebSocket in the Future
                            
                            You could easily adapt this:
                                
                                ```swift
                            func websocketMessageStream() -> AsyncStream<Message> {
    AsyncStream { continuation in
        websocket.onMessage = { message in
            continuation.yield(message)
        }
        continuation.onTermination = { _ in websocket.close() }
    }
}
```

---

## 🧼 Summary

| Component     | Role                                   |
| ------------- | -------------------------------------- |
| `AsyncStream` | Streams messages to view model         |
| `Task`        | Keeps stream alive in background       |
| SwiftUI View  | Displays chat and handles input        |
| ViewModel     | Converts stream to UI-friendly updates |

---

## 💬 Want More?

Would you like to:

* Integrate this with a **real WebSocket API** (e.g., `URLSessionWebSocketTask`)?
* Add **typing indicators** using another async stream?
* Support **multiple users or chat rooms**?
* Persist messages to disk?

Let me know where you’d like to take the chat next.

