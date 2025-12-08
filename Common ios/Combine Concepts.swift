//
//  Combine Concepts.swift
//  
//
//  Created by Apple on 08/12/25.
//

import Foundation

Below are **clear, concise, interview-ready explanations** for each of the important Combine topics you listed. If you want code examples for each, just tell me!

---

# ✅ **1. Difference between Publisher and Subject**

### **Publisher**

* A *source* of values over time.
* Pure / declarative — cannot manually send values (except in custom implementation).
* Examples:
  `URLSession.DataTaskPublisher`, `Just`, `Timer.publish`.

### **Subject**

* A type that is *both a publisher and a subscriber*.
* You can **manually send values** using:

  ```swift
  subject.send(value)
  ```
* Used for bridging imperative code to reactive pipelines.

### 🔑 Key Differences

| Feature            | Publisher                    | Subject                           |
| ------------------ | ---------------------------- | --------------------------------- |
| Emits values       | Automatically based on logic | You manually send values          |
| Control            | Declarative                  | Imperative                        |
| Can receive values | No                           | Yes (because they’re subscribers) |
| State              | None                         | May or may not hold state         |

---

# ✅ **2. When to use PassthroughSubject vs CurrentValueSubject**

### **PassthroughSubject**

* Does *not* store the latest value.
* Sends values only *after* subscription.
* Use when:

  * Events matter only when subscribed (e.g., button taps).
  * No need to remember the last value.

### **CurrentValueSubject**

* Always stores the *latest* value.
* Sends the current value to new subscribers immediately.
* Use when:

  * You need state + reactive updates.
  * Similar to `BehaviorSubject` in RxSwift.
  * Perfect for ViewModel state (e.g., selectedItem, form inputs).

---

# ✅ **3. Importance of AnyCancellable**

* Keeps Combine subscription alive.
* If not stored, pipeline **cancels immediately**.
* Prevents automatic cancellation on deallocation.
* Common pattern:

  ```swift
  var cancellables = Set<AnyCancellable>()
  ```

Also helps:

* Managing memory
* Avoiding retain cycles with `[weak self]`
* Auto-cancelling on deinit

---

# ✅ **4. Explain Backpressure**

**Backpressure** = How subscribers control the rate of values they can handle.

* Combine uses **Subscribers.Demand**:

  * `.none` – don't send any values yet
  * `.max(n)` – send up to *n* values
  * `.unlimited` – send as many as you want

Subscribers request values using:

```swift
func receive(subscription: Subscription) {
    subscription.request(.max(1))
}
```

### Why it matters

* Prevents overloading UI or memory
* Ensures controlled flow of data, especially in streams or heavy pipelines

---

# ✅ **5. Difference: map vs flatMap**

### **map**

* Transforms **values**.
* 1 input → 1 output.
* Does **not** create new publishers.

Example:

```swift
publisher.map { $0 * 2 }
```

### **flatMap**

* Transforms values **into new publishers**.
* Merges resulting publishers into a single stream.
* 1 input → many outputs.

Example:

```swift
userIDPublisher
    .flatMap { fetchUserDetails(id: $0) }
```

### Quick analogy:

* `map`: A → B
* `flatMap`: A → Publisher<B>

---

# ✅ **6. combineLatest vs zip**

### **combineLatest**

* Emits a value *whenever any input publisher emits*,
  **after each has emitted at least once**.

### **zip**

* Emits pairs only when **both publishers emit in lockstep**.

### Example difference:

| A | B  | combineLatest | zip    |
| - | -- | ------------- | ------ |
| 1 |    | —             | —      |
| 1 | 10 | (1,10)        | (1,10) |
| 2 |    | (2,10)        | —      |
| 2 | 11 | (2,11)        | (2,11) |

### Rule:

* Use **combineLatest** for state combinations (e.g., form validation).
* Use **zip** when sequences are paired (e.g., request → response).

---

# ✅ **7. What does switchToLatest solve?**

It solves the **"cancel previous request when a new one begins"** problem.

Example:

* User types in a search bar
* Each new character triggers a new network call
* You want to cancel the old calls and keep only the latest one

### Without switchToLatest → Multiple unnecessary inflights

### With switchToLatest → Only latest publisher continues

Pattern:

```swift
searchTermPublisher
    .map { query in fetchResults(query) }  // returns Publisher
    .switchToLatest()                      // takes only most recent publisher
```

---

# ✅ **8. How to handle errors in Combine**

Common operators:

### **catch**

Recover and return a new publisher:

```swift
publisher
    .catch { _ in Just([]) }
```

### **tryMap / tryFilter**

Throw errors inside map.

### **replaceError**

Return a fallback value and complete:

```swift
publisher.replaceError(with: [])
```

### **retry**

Retry failed pipelines:

```swift
publisher.retry(3)
```

### Handling in sink:

```swift
sink(receiveCompletion: { completion in
    if case .failure(let error) = completion {
        print(error)
    }
})
```

---

# ✅ **9. How to bind Combine with SwiftUI’s @Published**

`@Published` automatically exposes a publisher:

```swift
@Published var name: String
```

Subscribe in SwiftUI using:

```swift
viewModel.$name
    .sink { value in
        print(value)
    }
    .store(in: &cancellables)
```

### SwiftUI auto-binding (common use-case)

In ViewModel:

```swift
@Published var username = ""
```

In SwiftUI View:

```swift
TextField("Name", text: $viewModel.username)
```

SwiftUI observes `@Published` automatically:

* UI updates when value changes
* User input updates ViewModel
* No manual subscription needed in most cases

---

# If you want, I can give you:

✅ Real interview questions
✅ Mini coding tests
✅ Combine cheat sheet
Just tell me!



Here are the **most important and frequently asked concepts in Combine** during iOS interviews. This covers fundamentals, operators, publishers/subscribers, memory management, and real-world usage.

---

# 🚀 **Important Combine Concepts (iOS Interview Must-Know)**

## 1. **Publisher**

* A type that emits values over time.
* Common system publishers:

  * `Just`, `Empty`, `Fail`
  * `NotificationCenter.Publisher`
  * `URLSession.DataTaskPublisher`
  * `Timer.TimerPublisher`
* Ask: *What is a cold vs hot publisher?*

## 2. **Subscriber**

* Something that receives values from a publisher.
* Combine provides:

  * `sink(receiveValue:)`
  * `assign(to:on:)`
* Custom subscriber using `Subscriber` protocol.

## 3. **Subscription**

* A connection between publisher and subscriber.
* Controls data flow (via backpressure, demand).

---

# ⚙️ **3. Backpressure & Demand**

* Combine manages how many values subscribers want.
* `Subscribers.Demand`

  * `.none`, `.max(n)`, `.unlimited`
* Interview Q: *What happens if demand is not requested?*

---

# 🔗 **4. Operators**

Operators transform or control the flow of data.

### **Transformation**

* `map`, `tryMap`
* `flatMap`
* `scan`

### **Filtering**

* `filter`
* `removeDuplicates`
* `compactMap`

### **Combining**

* `merge`
* `zip`
* `combineLatest`
* `switchToLatest` ← very important for networking

### **Time-related**

* `debounce`
* `throttle`
* `delay`

### **Error Handling**

* `catch`
* `tryCatch`
* `replaceError(with:)`

### **Completion Handling**

* `sink(receiveCompletion:receiveValue:)`
* handling `.finished` vs `.failure`

---

# 🧵 **5. Subjects**

Subjects are both publishers and subscribers.

### **Types**

* `PassthroughSubject`
* `CurrentValueSubject`

### When to use what?

* `PassthroughSubject`: emits only future values
* `CurrentValueSubject`: stores the latest value (like BehaviorSubject in RxSwift)

---

# 🧠 **6. AnyCancellable & Memory Management**

* Subscriptions must be stored, usually in:

  ```swift
  var cancellables = Set<AnyCancellable>()
  ```
* Interview Q: *Why do subscriptions leak memory if not stored?*
  Because they’re retained until cancelled.

---

# 🌐 **7. Combine + Networking**

How Combine deals with network pipelines using `URLSession`:

```swift
URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: Model.self, decoder: JSONDecoder())
    .receive(on: DispatchQueue.main)
    .sink { completion in
        ...
    } receiveValue: { value in
        ...
    }
```

Key concepts:

* `decode`
* `receive(on:)`
* `subscribe(on:)`

---

# ⛓️ **8. Schedulers**

Used to control threading in Combine:

* `DispatchQueue.main`
* `RunLoop.main`
* `OperationQueue`

Common interview Q:

* *Difference between `receive(on:)` and `subscribe(on:)`?*

---

# 📌 **9. Erasing Publishers**

* Using `eraseToAnyPublisher()` to hide underlying type.
* Helps in API abstraction.

---

# 🏗️ **10. Combine in MVVM**

How Combine is used in MVVM for binding:

* ViewModel exposes publishers
* View subscribes and updates UI
* Avoiding retain cycles with `[weak self]`

---

# 🔥 Most Common Combine Interview Questions

* Difference between **Publisher** and **Subject**
* When to use **PassthroughSubject** vs **CurrentValueSubject**
* Importance of **AnyCancellable**
* Explain **backpressure**
* Difference: `map` vs `flatMap`
* `combineLatest` vs `zip`
* What does `switchToLatest` solve?
* How to handle **errors** in Combine?
* How to bind Combine with SwiftUI’s `@Published`?

---

If you want, I can also give:
✅ Example-based explanations
✅ Coding exercises
✅ A Combine crash course
Just tell me what you need!
