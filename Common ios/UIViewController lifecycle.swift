//
//  UIViewController lifecycle.swift
//  
//
//  Created by Apple on 05/11/25.
//

import Foundation

In iOS development, **view lifecycle** refers to the sequence of events that occur when a **UIViewController**’s view is created, displayed, hidden, and destroyed. Understanding this lifecycle is essential to properly manage resources, update UI elements, and handle data when screens appear and disappear.

Let’s go step-by-step 👇

---

### 🧩 1. The View Controller Lifecycle Overview

Every `UIViewController` has a **view** (of type `UIView`) that it manages. iOS automatically calls specific methods on the view controller during its lifecycle. The main stages are:

| Stage                                        | Method                  | Description                                                                                                                                                 |
| -------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Loading the view**                      | `loadView()`            | Called when the view controller needs its view hierarchy but it doesn’t exist yet. Usually, you don’t override this unless creating views programmatically. |
| **2. After view is loaded**                  | `viewDidLoad()`         | Called **once** after the view is loaded into memory. Initialize data, set up UI, and make one-time configurations here.                                    |
| **3. Before the view appears**               | `viewWillAppear(_:)`    | Called **every time** the view is about to appear on screen. Update data, start animations, and prepare UI.                                                 |
| **4. After the view appears**                | `viewDidAppear(_:)`     | Called right after the view becomes visible. Start tasks that require the view to be visible (e.g., start animations, video playback, network calls).       |
| **5. Before the view disappears**            | `viewWillDisappear(_:)` | Called just before the view goes off-screen. Save changes, hide the keyboard, stop animations or timers.                                                    |
| **6. After the view disappears**             | `viewDidDisappear(_:)`  | Called right after the view disappears. Use it to stop ongoing tasks or remove observers.                                                                   |
| **7. When the view is released from memory** | `deinit`                | Called when the view controller is deallocated. Clean up any retained resources or observers.                                                               |

---

### 🔄 Typical Flow

Here’s the **usual order** of calls when a view controller is presented and then dismissed:

```
loadView()
viewDidLoad()
viewWillAppear()
viewDidAppear()
--- user interacts ---
viewWillDisappear()
viewDidDisappear()
deinit
```

---

### ⚙️ When to Use Each Method

| Method                  | Common Use                                                      |
| ----------------------- | --------------------------------------------------------------- |
| `loadView()`            | Build UI manually (rare; mostly use Storyboards or SwiftUI).    |
| `viewDidLoad()`         | Set up bindings, register table cells, configure initial state. |
| `viewWillAppear(_:)`    | Refresh UI, update layout based on current data.                |
| `viewDidAppear(_:)`     | Start animations, analytics tracking, network calls.            |
| `viewWillDisappear(_:)` | Save draft data, stop timers, pause ongoing tasks.              |
| `viewDidDisappear(_:)`  | Release heavy resources, remove observers.                      |

---

### 🧠 Bonus: Related Concepts

* **`viewWillLayoutSubviews()` / `viewDidLayoutSubviews()`**:
  Called when the view lays out its subviews (e.g., after rotation or resizing). Use these for layout adjustments.

* **Memory Warnings**:
  In older iOS versions, `didReceiveMemoryWarning()` was used to handle low-memory conditions. (Rarely needed today.)

* **Scene Lifecycle** (iOS 13+):
  Separate from view lifecycle — it refers to app-wide events (e.g., app entering background/foreground).

---

### 🪄 Example

```swift
class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad: setup UI once")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear: refresh data")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear: start animations")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear: stop animations")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear: clean up")
    }

    deinit {
        print("deinit: controller released")
    }
}
```

---

