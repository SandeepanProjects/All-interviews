//
//  perform multiple API calls in parallel.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Great scenario — this is a very common requirement in iOS development, and modern Swift concurrency makes it clean and efficient to handle.

---

## 🎯 **Goal:**

* Perform **multiple API calls in parallel**
* Wait for **all responses**
* Then **update the UI** (on the main thread)

---

## ✅ **Preferred Approach (Swift Concurrency with `async let`)**

Assuming you're using Swift 5.5+ (iOS 15+), here's how you'd do it:

### 🧪 Example

```swift
func loadData() async {
    async let user = fetchUserData()
    async let posts = fetchPosts()
    async let settings = fetchUserSettings()

    do {
        let (userResult, postsResult, settingsResult) = try await (user, posts, settings)

        // Switch to main thread to update UI
        await MainActor.run {
            self.updateUI(user: userResult, posts: postsResult, settings: settingsResult)
        }

    } catch {
        print("Failed to load data: \(error)")
        // Handle error on main thread if needed
        await MainActor.run {
            self.showError(error)
        }
    }
}
```

---

### 🧠 Why This Works Well

* `async let` starts the API calls **in parallel**.
* `await` waits for **all of them** to complete.
* `MainActor.run` ensures UI is updated on the **main thread** (which is required).

---

## 🛠️ Alternative: Use `TaskGroup` for Dynamic or Large Number of Requests

```swift
func fetchAllDetails(for ids: [Int]) async throws -> [Detail] {
    try await withThrowingTaskGroup(of: Detail.self) { group in
        var details: [Detail] = []

        for id in ids {
            group.addTask {
                return try await fetchDetail(for: id)
            }
        }

        for try await detail in group {
            details.append(detail)
        }

        return details
    }
}
```

* Useful when the number of API calls is **dynamic**.
* All calls run in parallel and throw if any of them fails.

---

## ⛔ Old School: DispatchGroup (Not Recommended in New Swift)

If you're not using Swift concurrency yet, you could do this:

```swift
let group = DispatchGroup()

var user: User?
var posts: [Post]?

group.enter()
fetchUser { result in
    user = result
    group.leave()
}

group.enter()
fetchPosts { result in
    posts = result
    group.leave()
}

group.notify(queue: .main) {
    updateUI(user: user, posts: posts)
}
```

But this is:

* Harder to read and maintain
* More error-prone
* Lacks built-in error propagation

---

## 🔒 Thread-Safety Note

Always ensure **UI updates happen on the main thread**, whether using:

* `DispatchQueue.main.async { }` (in older code)
* `await MainActor.run { }` (in Swift concurrency)

---

## ✅ Summary

| Tool / Approach | When to Use                          |
| --------------- | ------------------------------------ |
| `async let`     | Few known parallel API calls         |
| `TaskGroup`     | Dynamic or many concurrent tasks     |
| `MainActor.run` | For UI updates in Swift concurrency  |
| `DispatchGroup` | Legacy approach (use only if needed) |

---

Would you like a working SwiftUI example showing this in action?
