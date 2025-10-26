//
//  Debouncing.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Absolutely! Let’s dive into the **debounce technique** in SwiftUI/iOS. I’ll break it down carefully, explain why it’s useful, and show practical examples.

---

## 1️⃣ What is Debouncing?

**Debouncing** is a technique that **limits how often a function is executed**.

* It ensures that a function is called **only after a certain delay has passed without any new events**.
* Useful for **user input**, **search bars**, or **network requests** where you don’t want to trigger an action on every keystroke.

### Example Use Case:

* User types in a search field.
* Without debounce → every keystroke triggers a network request.
* With debounce → network request triggers **only after the user stops typing for, say, 0.5 seconds**.

---

## 2️⃣ How Debounce Works Conceptually

```
User types:  H  He  Hel  Hell  Hello
Delay:       0.5s after last keystroke

Without debounce: request for H, He, Hel, Hell, Hello → 5 requests
With debounce:    request only for Hello → 1 request
```

---

## 3️⃣ Debounce in SwiftUI using Combine

SwiftUI works seamlessly with **Combine**, which has a built-in `debounce` operator.

```swift
import SwiftUI
import Combine

class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe query changes and debounce
        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates() // optional: skip same queries
            .sink { [weak self] query in
                self?.search(query: query)
            }
            .store(in: &cancellables)
    }

    func search(query: String) {
        // Simulate API request
        results = ["Result for \(query)"]
        print("Searching for: \(query)")
    }
}
```

---

### SwiftUI View

```swift
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack {
            TextField("Search...", text: $viewModel.query)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            List(viewModel.results, id: \.self) { result in
                Text(result)
            }
        }
        .padding()
    }
}
```

✅ Behavior:

* While typing, the `search` function **does not run immediately**.
* It triggers **only after 0.5 seconds of inactivity**.
* Prevents unnecessary network calls.

---

## 4️⃣ Debounce Using Async/Await (Swift Concurrency)

With iOS 15+, you can use `Task` and `async/await` with **delays** to implement debounce manually.

```swift
class AsyncSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [String] = []

    private var searchTask: Task<Void, Never>?

    func onQueryChange(_ newQuery: String) {
        searchTask?.cancel() // cancel previous pending search

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
            await MainActor.run {
                self.search(query: newQuery)
            }
        }
    }

    private func search(query: String) {
        results = ["Result for \(query)"]
        print("Searching for: \(query)")
    }
}
```

**Usage in View:**

```swift
TextField("Search...", text: $viewModel.query)
    .onChange(of: viewModel.query) { newQuery in
        viewModel.onQueryChange(newQuery)
    }
```

✅ Key Points:

* Cancels the previous pending search if the user types again.
* Executes search **only after delay without further input**.

---

## 5️⃣ Key Parameters

| Parameter            | Purpose                                                |
| -------------------- | ------------------------------------------------------ |
| `debounce interval`  | How long to wait after last event                      |
| `scheduler`          | On which thread the debounce runs (main thread for UI) |
| `removeDuplicates()` | Optional — ignores identical consecutive inputs        |

---

## 6️⃣ Practical Tips

1. **Use Combine’s `debounce` for simplicity** if your app already uses Combine.
2. **Use async/await + Task.sleep** if you prefer Swift Concurrency style.
3. **Always cancel previous tasks or subscriptions** to prevent multiple triggers.
4. **Keep interval reasonable** (300–500ms for typing; 1–2s for network-heavy operations).

---

Debouncing is a **must-have technique** for smooth, responsive apps without unnecessary load on APIs or UI.

---

I can make a **diagram showing the timeline of debounce in SwiftUI**, comparing “with debounce” vs “without debounce”, which makes it very clear for teaching or documentation.

Do you want me to do that?
