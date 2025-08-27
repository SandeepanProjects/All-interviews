//
//  RunLoop.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

A **RunLoop** is a fundamental concept in iOS/macOS programming. It's essentially an **event processing loop** that manages the scheduling and execution of asynchronous events (like user input, timers, network responses, etc.).

Understanding `RunLoop` is especially important when dealing with **threads**, particularly the **main thread** in iOS apps.

---

## ✅ What is a RunLoop?

### 📘 Definition:

A `RunLoop` is an object that:

* **Keeps a thread alive** to respond to events
* **Watches input sources** (e.g., touch events, network sockets)
* **Fires timers**, dispatches events, processes notifications, etc.

Every thread **can** have its own `RunLoop`, but:

* Only the **main thread has one running by default**
* Background threads **do not have a runloop unless you start one manually**

---

## ✅ How Does RunLoop Work?

It works like this:

1. **Waits** for an input source (event, timer, etc.)
2. **Processes** the input if available
3. **Goes idle** until the next input comes in
4. Repeats...

This lets the thread **sleep efficiently** when idle, and **wake up quickly** when something needs attention.

---

## ✅ RunLoop and the **Main Thread**

The **main thread** in an iOS app:

* Always has a **RunLoop** running
* This RunLoop:

  * Handles **UI events**
  * Processes **touch input**
  * Runs **timers**
  * Executes code scheduled on the **main dispatch queue**

This is why:

* UI code **must run on the main thread**
* Blocking the RunLoop (e.g., with a long loop or `sleep`) will **freeze the UI**

---

### 🔁 Visual Example:

```plaintext
Main Thread
┌─────────────────────────────────────────────┐
│ RunLoop                                     │
│ ┌───────────────┐     ┌─────────────┐       │
│ │ Handle Events │ --> │ Dispatch UI │ --> ... (repeats)
│ └───────────────┘     └─────────────┘       │
└─────────────────────────────────────────────┘
```

---

## ✅ Use Cases for RunLoop

* Responding to **user input** (handled automatically)
* Managing **long-lived background threads**

  * E.g., if you spin up a thread and want it to stay alive to monitor network or sockets
* Custom **event scheduling**

---

## ✅ Real-World Example

### Main Thread:

* UIKit starts the RunLoop automatically
* You never need to start it manually
* But you **should never block it** — no heavy tasks here!

### Background Thread (e.g., custom thread):

```swift
let thread = Thread {
    let runLoop = RunLoop.current
    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        print("Background timer fired")
    }
    runLoop.run() // Keep the thread alive
}
thread.start()
```

---

## ✅ Summary

| Concept               | Explanation                                                         |
| --------------------- | ------------------------------------------------------------------- |
| **RunLoop**           | Event-processing loop that keeps threads alive and responsive       |
| **Main Thread**       | Always has a RunLoop — it's responsible for UI events, timers, etc. |
| **Background Thread** | Doesn't have a RunLoop unless you create one manually               |
| **Why it matters**    | UI hangs? Probably because you blocked the main RunLoop             |

---

Would you like a visual animation or Swift Playground example showing RunLoop behavior?
