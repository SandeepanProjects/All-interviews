//
//  Task group and throwingTask group.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Great question! In Swift Concurrency, **`TaskGroup`** and **`ThrowingTaskGroup`** are powerful tools that let you **run a dynamic number of tasks concurrently** and gather their results — in a structured and safe way.

Let’s break down both with simple, clear explanations:

---

## 🧱 1. `TaskGroup`

### 🔹 What is it?

A `TaskGroup` allows you to **run multiple child tasks concurrently**, **wait for all of them to finish**, and **collect their results**, without throwing errors.

* It's **non-throwing**, meaning the tasks **should not throw**.
* If a task throws inside, you must **handle the error yourself**.

### ✅ Use When:

* Tasks **do not throw errors** (or you want to handle them manually)
* You want to **collect all results** of similar type

---

### 📦 Example:

```swift
func loadNames() async {
    let names = ["Alice", "Bob", "Charlie"]

    let results = await withTaskGroup(of: String.self) { group in
        for name in names {
            group.addTask {
                return "Hello, \(name)"
            }
        }

        var greetings: [String] = []

        for await greeting in group {
            greetings.append(greeting)
        }

        return greetings
    }

    print(results) // ["Hello, Alice", "Hello, Bob", "Hello, Charlie"]
}
```

---

## 💥 2. `ThrowingTaskGroup`

### 🔹 What is it?

A `ThrowingTaskGroup` is just like `TaskGroup`, **but allows tasks to throw errors**.

* If **any task throws**, the error is **propagated**, and the remaining tasks are **cancelled** automatically.
* Use `try await withThrowingTaskGroup` to create one.

---

### ✅ Use When:

* You expect **some tasks to throw errors**
* You want to **fail fast** and let the first error propagate
* Remaining tasks should be cancelled if an error happens

---

### ⚠️ Example with Failure:

```swift
func fetchNumber(_ value: Int) async throws -> Int {
    if value == 2 { throw NSError(domain: "", code: 1) }
    return value * 10
}

func loadNumbers() async {
    do {
        let results = try await withThrowingTaskGroup(of: Int.self) { group in
            for i in 1...3 {
                group.addTask {
                    try await fetchNumber(i)
                }
            }

            var numbers: [Int] = []

            for try await number in group {
                numbers.append(number)
            }

            return numbers
        }

        print(results)
    } catch {
        print("One of the tasks failed: \(error)")
    }
}
```

#### ✅ What Happens:

* Task for `i = 2` throws → the group throws
* Remaining tasks are cancelled
* Error is caught in `catch`

---

## 🔍 Comparing the Two

| Feature                | `TaskGroup`                                 | `ThrowingTaskGroup`            |
| ---------------------- | ------------------------------------------- | ------------------------------ |
| Can child tasks throw? | ❌ No (must catch inside)                    | ✅ Yes (use `try await`)        |
| Error propagation      | ❌ Must be manual                            | ✅ Automatic error throwing     |
| Auto-cancellation      | ❌ No                                        | ✅ Yes, if any task throws      |
| Use case               | All tasks succeed or handle errors manually | Fail-fast tasks that may throw |

---

## 🧠 Pro Tip

If you use a `ThrowingTaskGroup` but want to **handle partial results**, you can wrap tasks in `Result<T, Error>` and avoid throwing:

```swift
group.addTask {
    Result { try await someThrowingTask() }
}
```

Then handle results one by one.

---

what happens if one of the api fails in them?
                    
Great follow-up! Here’s what happens if one of the APIs (tasks) fails inside a **`TaskGroup`** vs a **`ThrowingTaskGroup`**:

---

## 1. What if an API fails in **`TaskGroup`** (non-throwing)?

* The tasks **cannot throw** errors directly, so you have to **handle errors manually inside the task**.
* **No automatic error propagation or cancellation.**
* If a task encounters an error, you typically wrap the result in a `Result` enum or optional to communicate failure.

### Behavior:

* Other tasks **continue running** unaffected.
* The group completes when all tasks finish.
* You get **all results**, including success and failure wrapped inside.

### Example:

```swift
await withTaskGroup(of: Result<String, Error>.self) { group in
    group.addTask {
        do {
            let data = try await fetchAPI1()
            return .success(data)
        } catch {
            return .failure(error)
        }
    }
    group.addTask {
        do {
            let data = try await fetchAPI2()
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    for await result in group {
        switch result {
        case .success(let data):
            print("Got data: \(data)")
        case .failure(let error):
            print("API failed: \(error)")
        }
    }
}
```

---

## 2. What if an API fails in **`ThrowingTaskGroup`**?

* If **any task throws**, the **first error encountered is immediately propagated**.
* The **remaining running tasks are automatically cancelled** by the system.
* You **do not get the results of the other tasks** that haven’t completed yet.
* The `withThrowingTaskGroup` call itself throws the error.

### Behavior:

* **Fail-fast**: as soon as one task throws, group throws.
* Other tasks get cancelled.
* You catch or propagate the error outside the task group.

### Example:

```swift
do {
    try await withThrowingTaskGroup(of: String.self) { group in
        group.addTask { try await fetchAPI1() }
        group.addTask { try await fetchAPI2() } // Suppose this throws
        
        for try await data in group {
            print("Got data: \(data)")
        }
    }
} catch {
    print("One of the APIs failed: \(error)")
}
```

---

## **Summary Table**

| Scenario       | TaskGroup                                                                        | ThrowingTaskGroup                                                     |
| -------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| One task fails | No automatic error propagation; you must handle errors manually inside each task | Immediate error propagation; group throws and cancels remaining tasks |
| Other tasks    | Continue to run normally                                                         | Cancelled as soon as error thrown                                     |
| Final result   | You get all results, success & failure wrapped                                   | Either all succeed or group throws error                              |
| Use case       | Handle partial successes/failures                                                | Fail fast on any error                                                |

---

**Bottom line:**

* Use **`TaskGroup`** if you want to **collect all results and errors yourself** without cancelling sibling tasks.
* Use **`ThrowingTaskGroup`** if you want **fail-fast behavior** where one failure cancels all and throws.

---

Want me to show how to implement **retry logic or partial failure handling** with either of these?

Awesome! Let me show you how to implement **retry logic** and **partial failure handling** with both `TaskGroup` and `ThrowingTaskGroup` in Swift concurrency.
                            
---
                            
# 1️⃣ Retry Logic with `ThrowingTaskGroup`
                            
This is useful if you want to **retry failed tasks a few times** but still fail fast if all retries fail.
                            
### Retry Wrapper Function:
                                
```swift
func retry<T>(
maxAttempts: Int = 3,
delaySeconds: UInt64 = 1,
task: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await task()
        } catch {
            lastError = error
            print("Attempt \(attempt) failed with error: \(error)")
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: delaySeconds * 1_000_000_000)
            }
        }
    }
    
    throw lastError!
}
```

### Using Retry in a ThrowingTaskGroup:

```swift
func loadWithRetry() async {
    do {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await retry { try await fetchAPI1() } }
            group.addTask { try await retry { try await fetchAPI2() } }
            
            for try await result in group {
                print("Got result: \(result)")
            }
        }
    } catch {
        print("Failed after retries: \(error)")
    }
}
```

* If any task **fails all retry attempts**, the entire group throws.
* Remaining tasks are cancelled.

---

# 2️⃣ Partial Failure Handling with `TaskGroup` (Non-Throwing)

This approach **never throws from the group**, instead **wraps each task’s result in a `Result`** so you can handle success/failure individually.

### Example:

```swift
func loadPartialResults() async {
    await withTaskGroup(of: Result<String, Error>.self) { group in
        group.addTask {
            Result { try await fetchAPI1() }
        }
        group.addTask {
            Result { try await fetchAPI2() }
        }
        
        for await result in group {
            switch result {
            case .success(let data):
                print("Success: \(data)")
            case .failure(let error):
                print("Failed with error: \(error)")
            }
        }
    }
}
```

* All tasks run concurrently.
* Errors are captured inside the `Result` and handled individually.
* No task cancellation if one fails.
                            * Great for “best effort” parallel fetching.
                            
                            ---
                            
                            # 3️⃣ Bonus: Combine Retry + Partial Handling
                            
                            You can combine these patterns to **retry each task individually and keep partial results**:
                                
                                ```swift
                            func loadRetryPartial() async {
    await withTaskGroup(of: Result<String, Error>.self) { group in
        group.addTask {
            Result { try await retry { try await fetchAPI1() } }
        }
        group.addTask {
            Result { try await retry { try await fetchAPI2() } }
        }
        
        for await result in group {
            switch result {
            case .success(let data):
                print("Success: \(data)")
            case .failure(let error):
                print("Failed even after retries: \(error)")
            }
        }
    }
}
```

---

# 🧠 Summary

| Pattern                              | Use Case                               | Behavior                                   |
| ------------------------------------ | -------------------------------------- | ------------------------------------------ |
| Retry + ThrowingTaskGroup            | Fail-fast but retry individual tasks   | Cancels on first unrecoverable error       |
| Partial Handling + TaskGroup         | Continue regardless of failures        | Capture errors in results, no cancellation |
| Retry + Partial Handling + TaskGroup | Retry each individually, keep partials | Best of both worlds                        |

---

Would you like me to help you build a full example app or Playground to test this out?
