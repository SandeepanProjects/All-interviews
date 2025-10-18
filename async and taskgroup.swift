//
//  async and taskgroup.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Swift Concurrency is a powerful set of language features and runtime support introduced in Swift 5.5 (alongside iOS 15, macOS 12, etc.) to simplify asynchronous programming. It helps developers write safe, efficient, and readable code that deals with concurrent operations like network calls, file I/O, or UI updates.

Let’s explore Swift Concurrency in detail:

---

## 🧠 **Why Swift Concurrency?**

Before Swift Concurrency, developers used:

* **Closures/callbacks**: Leads to "callback hell"
* **GCD (Grand Central Dispatch)**: Powerful, but low-level and error-prone
* **OperationQueues**: High-level abstraction, but still complex for simple tasks

These approaches could easily lead to race conditions, deadlocks, and thread explosions.

**Swift Concurrency** solves these issues by introducing structured concurrency, making async code look like regular, linear code.

---

## 🌟 Key Concepts of Swift Concurrency

---

### 1. **`async` and `await`**

These keywords simplify asynchronous programming.

* `async` marks a function as asynchronous (i.e., it may suspend).
* `await` pauses the execution of the function until the async operation completes.

**Example:**

```swift
func fetchUserData() async -> User {
    // Simulate a network call
}

func loadProfile() async {
    let user = await fetchUserData()
    print(user.name)
}
```

---

### 2. **`Task` and Task Hierarchies**

`Task` is a unit of asynchronous work. You can launch concurrent work using `Task {}`.

**Example:**

```swift
Task {
    await loadProfile()
}
```

There are two types:

* **Top-level tasks**: Created with `Task {}` or `Task.detached {}`.
* **Child tasks**: Automatically created inside an async function, part of structured concurrency.

**Detached tasks** are not tied to the parent task or the actor:

```swift
Task.detached {
    await doSomething()
}
```

---

### 3. **Structured Concurrency**

Structured concurrency ensures that child tasks are tied to the lifetime of their parent, and all tasks are completed before the function returns.

This makes code safer and easier to reason about.

**Example using `async let`:**

```swift
func loadData() async {
    async let image = downloadImage()
    async let user = fetchUserData()
    
    // Both tasks run concurrently
    let (img, usr) = await (image, user)
}
```

---

### 4. **Actors**

Actors are reference types that protect their mutable state through isolation, solving the **data race** problem in concurrent code.

```swift
actor BankAccount {
    private var balance = 0
    
    func deposit(_ amount: Int) {
        balance += amount
    }
    
    func getBalance() -> Int {
        return balance
    }
}
```

To call actor methods from outside:

```swift
let account = BankAccount()
await account.deposit(100)
```

Actors guarantee that only one task can access their mutable state at a time.

---

### 5. **MainActor**

Some tasks must run on the **main thread**, especially UI updates.

```swift
@MainActor
class ViewModel {
    func updateUI() {
        // Safe to update UI here
    }
}
```

Or use:

```swift
await MainActor.run {
    // Run on the main thread
}
```

---

### 6. **Concurrency & Error Handling**

You can use `try`, `try await`, and `async throws` together.

```swift
func fetchData() async throws -> Data {
    // ...
}

do {
    let data = try await fetchData()
} catch {
    print("Error: \(error)")
}
```

---

### 7. **Cancellation**

Tasks can be cancelled. Use `Task`’s `isCancelled` or `checkCancellation()`.

```swift
func fetchData() async throws {
    guard !Task.isCancelled else { return }
    // ...
}
```

You can also cancel a task explicitly:

```swift
let task = Task {
    await doSomething()
}

task.cancel()
```

---

### 8. **Task Groups**

For running multiple tasks concurrently and waiting for them all to complete.

```swift
func processFiles(_ files: [String]) async {
    await withTaskGroup(of: Void.self) { group in
        for file in files {
            group.addTask {
                await process(file)
            }
        }
    }
}
```

---

## 📊 Swift Concurrency vs GCD

| Feature        | Swift Concurrency                 | GCD                       |
| -------------- | --------------------------------- | ------------------------- |
| Syntax         | Clean, structured (`async/await`) | Verbose, prone to nesting |
| Safety         | Safer (actors, structured tasks)  | Prone to race conditions  |
| Error Handling | Built-in with `try await`         | Requires manual handling  |
| Cancellation   | First-class support               | Manual and clunky         |

---

## ✅ Best Practices

* Use `async let` for parallel tasks with known count.
* Use `TaskGroup` for dynamic, unbounded parallel tasks.
* Use `actors` to isolate shared mutable state.
* Use `@MainActor` for all UI-related work.
* Use structured concurrency over detached tasks when possible.

---

## 🚧 Limitations & Things to Watch

* Swift Concurrency requires iOS 13+/macOS 10.15+, but full support (e.g., actors) requires iOS 15+/macOS 12+.
* Be cautious with `Task.detached {}` – it bypasses structured concurrency.
* Accessing actor properties directly (like `actor.property`) without `await` may cause runtime errors unless the property is marked `nonisolated`.

---

## 🧪 Example Use Case

```swift
struct User: Decodable { let name: String }

func fetchUser() async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.example.com/user")!)
    return try JSONDecoder().decode(User.self, from: data)
}

Task {
    do {
        let user = try await fetchUser()
        print("User: \(user.name)")
    } catch {
        print("Failed to fetch user: \(error)")
    }
}
```

---

## 📚 Further Reading

* Apple’s [Swift Concurrency documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
* WWDC videos: “Explore Structured Concurrency in Swift” (2021), “Protect mutable state with Swift actors” (2021)

---


what will happen if any api fails using async let

Great question — understanding how Swift handles **failures in `async let` bindings** is key to writing robust concurrent code.
                                            
                                            ---
                                            
## ❗ What Happens if an API Fails in `async let`?
                                            
When you use `async let` with multiple async calls in parallel, and **one of them throws an error**, Swift **cancels the other concurrent tasks automatically**, and the **error is propagated** out of the enclosing scope (if marked `throws`).
                                            
This is part of Swift's **structured concurrency model**, which ensures:
                                                
1. **Error propagation** is predictable.
2. **Remaining sibling tasks are cancelled** when any one of them throws.
                                            
                                            ---
                                            
### 📌 Example: One API Throws
                                            
```swift
func fetchUser() async throws -> String {
    throw URLError(.badServerResponse)
}
                                            
func fetchProfileImage() async throws -> String {
    return "image.png"
}
                                            
func loadData() async throws {
    async let user = fetchUser()
    async let image = fetchProfileImage()
    
    let result = try await (user, image) // This will throw if `fetchUser()` fails
}
                                            ```
                                            
### ✅ What Actually Happens:
                                                
* `fetchUser()` throws → structured concurrency **cancels** `fetchProfileImage()`
* `try await (user, image)` throws the error from `fetchUser()`
* `loadData()` must be `throws` to propagate the error
* `fetchProfileImage()` may or may not finish executing — **but it will be cancelled** if possible
                                            
                                            ---
                                            
## 🧠 Cancellation Behavior
                                            
If a sibling `async let` task is still running and **not yet awaited**, Swift cancels it automatically.
                                            
However, cancellation is **cooperative** — the task must **check `Task.isCancelled`** periodically or use APIs that support cancellation (e.g., `URLSession` with `async/await` does this under the hood).
                                            
---
                                            
### 🛑 Don’t Ignore Await
                                            
If you write code like this:
                                                
```swift
async let a = mightThrow()
async let b = anotherTask()
                                            
// Oops! You don't await either
```
                                            
Both tasks are created and will run, but:
                                                
* If not awaited, any errors they throw are lost.
* Not awaiting an `async let` binding **before the function returns** is a compiler error.
                                            
> ✅ Swift enforces structured concurrency — you **must `await` all `async let` bindings** before the scope ends, or you'll get a compile-time error.
                                            
---
                                            
## 🧪 Example: Multiple Errors
                                            
If multiple tasks fail, only **one error is thrown**, usually the **first to be awaited**. The others are cancelled, and their errors are discarded.
                                            
```swift
async let a = api1() // throws
async let b = api2() // throws
                                            
let _ = try await (a, b)
```
                                            
In this case:
                                                
* Only one error is thrown.
* The second task is cancelled, and its error is not surfaced.
                                            
---
                                            
## ✅ Summary
                                            
| Behavior                        | Description                                                       |
| ------------------------------- | ----------------------------------------------------------------- |
| One `async let` fails           | The error is thrown when awaited. Other tasks are **cancelled**.  |
| Multiple fail                   | One error is thrown, others are cancelled.                        |
| Unawaited `async let`           | Compile-time error. All `async let` bindings **must** be awaited. |
| Cancellation after error        | Remaining `async let` tasks are cancelled **automatically**.      |
| Tasks must support cancellation | Use cooperative APIs like `URLSession`.                           |
                                            
---
                                            
Would you like a retry mechanism or error-handling strategy for multiple concurrent APIs?

Great — let’s talk about **error handling and retry strategies** when using `async let` with multiple concurrent API calls in Swift Concurrency.
                                            
This is crucial when you want to:
                                                
* Retry failed API calls
* Proceed even if one fails (optional)
* Gracefully handle partial failures
* Avoid throwing early unless necessary
                                            
---
                                            
## 🧭 Choose Your Strategy
                                            
There are **three common patterns** for handling `async let` API failures:
                                                
---
                                                
### ✅ **1. Catch Each Task Individually**
                                            
Use a `do-catch` block **within each async function** or **wrap each task in a `Result`** to handle errors independently.
                                            
#### 🧪 Example:

```swift
func fetchUser() async throws -> String {
    // simulate API call
    throw URLError(.badServerResponse)
}
                                            
func fetchImage() async throws -> String {
    return "profile.png"
}
                                            
func loadData() async {
    async let userResult: Result<String, Error> = {
        do {
            return .success(try await fetchUser())
        } catch {
            return .failure(error)
        }
    }()
    
    async let imageResult: Result<String, Error> = {
        do {
            return .success(try await fetchImage())
        } catch {
            return .failure(error)
        }
    }()
    
    let user = await userResult
    let image = await imageResult
    
    switch user {
    case .success(let userData): print("User: \(userData)")
    case .failure(let err): print("User fetch failed: \(err)")
    }
    
    switch image {
    case .success(let imageData): print("Image: \(imageData)")
    case .failure(let err): print("Image fetch failed: \(err)")
    }
}
                                            ```
                                            
> ✅ Best when you **want to continue** even if one task fails.
                                            
---
                                            
### 🔁 **2. Retry Failed Tasks (with Limited Attempts)**
                                            
Use a retry wrapper for the failing API.
                                            
#### 🔄 Retry Wrapper:
                                                
```swift
func retry<T>(
maxAttempts: Int = 3,
delay: TimeInterval = 1,
task: @escaping () async throws -> T
) async throws -> T {
var lastError: Error?
                                                
for attempt in 1...maxAttempts {
do {
return try await task()
} catch {
lastError = error
print("Attempt \(attempt) failed: \(error)")
if attempt < maxAttempts {
try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
}
}
}
                                                
throw lastError!
}
```
                                            
#### 🧪 Use with `async let`:
                                                
```swift
func loadData() async {
    async let user = retry { try await fetchUser() }
    async let image = retry { try await fetchImage() }
    
    do {
        let (userData, imageData) = try await (user, image)
        print("User: \(userData), Image: \(imageData)")
    } catch {
        print("One or both tasks failed even after retrying: \(error)")
    }
}
                                            ```
                                            
> ✅ Best when you're okay **retrying before giving up** on a task.
                                            
---
                                            
### ⚖️ **3. Proceed with Partial Results**
                                            
Instead of canceling all tasks when one fails, **use `TaskGroup`** to handle tasks individually with results.
                                            
#### 🧪 TaskGroup Example:
                                                
```swift
func loadAllData() async {
    let apis: [(String, () async throws -> String)] = [
        ("user", fetchUser),
        ("image", fetchImage)
    ]
    
    await withTaskGroup(of: (String, Result<String, Error>).self) { group in
        for (key, api) in apis {
            group.addTask {
                do {
                    let result = try await api()
                    return (key, .success(result))
                } catch {
                    return (key, .failure(error))
                }
            }
        }
        
        for await (key, result) in group {
            switch result {
            case .success(let data): print("\(key.capitalized): \(data)")
            case .failure(let err): print("\(key.capitalized) failed: \(err)")
            }
        }
    }
}
```
                                            
> ✅ Best for **processing multiple dynamic tasks** and handling errors **individually**.
                                            
---
                                            
## 🧠 Summary of When to Use What
                                            
| Strategy                    | Use When…                                                            |
| --------------------------- | -------------------------------------------------------------------- |
| **Catch individually**      | You want to continue even if one API fails                           |
| **Retry wrapper**           | You're okay retrying before giving up                                |
| **Task group with results** | You have multiple tasks and want to process all results individually |
| **Default `async let`**     | You want all-or-nothing (all must succeed, or fail fast)             |
                                            
---
