//
//  Background Fetch.swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

Below is a practical, up-to-date overview of **how background fetch works in iOS** and **how to design it for efficient resource usage**, with an emphasis on modern APIs and best practices.

---

## 1. Ways to Perform Background Fetch in iOS

### A. Background App Refresh (Legacy but still supported)

This allows the system to periodically wake your app to fetch new content.

**Key points**

* System decides *when* your app runs (based on usage, battery, network).
* No guaranteed timing.
* Deprecated in spirit for many use cases, but still works.

**Setup**

1. Enable **Background Modes → Background fetch** in Xcode.
2. Implement in `AppDelegate`:

```swift
func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler:
    @escaping (UIBackgroundFetchResult) -> Void
) {
    fetchData { result in
        completionHandler(result)
    }
}
```

**Limitations**

* Unpredictable execution.
* Can be suspended if the app abuses resources.

---

### B. Background Tasks Framework (Recommended – iOS 13+)

Use **`BGTaskScheduler`** for more reliable background work.

#### 1. BGAppRefreshTask (Short fetches)

* For quick network updates.
* Runs when system conditions are favorable.

```swift
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.example.app.refresh",
    using: nil
) { task in
    self.handleAppRefresh(task: task as! BGAppRefreshTask)
}
```

```swift
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleNextRefresh()

    let operation = FetchOperation()
    task.expirationHandler = {
        operation.cancel()
    }

    operation.completionBlock = {
        task.setTaskCompleted(success: !operation.isCancelled)
    }

    OperationQueue().addOperation(operation)
}
```

#### 2. BGProcessingTask (Longer tasks)

* Used for heavier work (sync, database cleanup).
* Requires power + network conditions.

```swift
request.requiresNetworkConnectivity = true
request.requiresExternalPower = false
```

---

### C. Push-Based Background Fetch (Best for Efficiency)

Use **silent push notifications** (`content-available: 1`) to trigger background work.

**Advantages**

* Server-controlled timing.
* More predictable.
* Less wasted wake-ups.

```json
{
  "aps": {
    "content-available": 1
  }
}
```

⚠️ Must:

* Be throttled.
* Deliver meaningful updates.
* Avoid excessive failures.

---

## 2. Ensuring Efficient Resource Usage

### A. Do the Minimum Work Necessary

* Fetch only **delta updates**, not full datasets.
* Use **ETags / If-Modified-Since** headers.
* Stop early if no new data is available.

```swift
if response.statusCode == 304 {
    completion(.noData)
}
```

---

### B. Respect Time & Expiration Handlers

Background tasks have strict time limits.

```swift
task.expirationHandler = {
    cancelNetworkRequests()
    saveState()
}
```

* Always clean up quickly.
* Never block the main thread.

---

### C. Use the Right Task Type

| Task Type        | Use Case              |
| ---------------- | --------------------- |
| BGAppRefreshTask | Quick API fetch       |
| BGProcessingTask | Sync, ML, DB cleanup  |
| Silent Push      | Server-driven updates |

Using the wrong type leads to throttling or termination.

---

### D. Batch Work

* Combine network requests.
* Defer non-urgent processing.
* Avoid waking the app repeatedly.

Example:

* Download metadata first
* Process heavy data only if changes exist

---

### E. Monitor System Conditions

Let iOS decide when conditions are optimal.

```swift
request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
```

Avoid forcing execution immediately unless critical.

---

### F. Handle Failures Gracefully

* Report accurate results: `.newData`, `.noData`, `.failed`
* Frequent failures reduce future background execution chances.

---

### G. Measure and Optimize

Use Xcode tools:

* **Energy Log**
* **Background Tasks debugging**
* **OSLog signposts**

Watch for:

* Excessive CPU usage
* Repeated network retries
* Large memory spikes

---

## 3. Common Mistakes to Avoid

❌ Assuming background fetch runs on a fixed schedule
❌ Doing heavy processing in `BGAppRefreshTask`
❌ Ignoring expiration handlers
❌ Returning `.newData` when nothing changed
❌ Using background fetch instead of silent push when possible

---

## 4. Recommended Strategy (Best Practice)

1. **Silent push** to trigger fetch when server has updates
2. **BGAppRefreshTask** as a fallback
3. **BGProcessingTask** for heavy deferred work
4. Fetch minimal data, process incrementally
5. Let the system optimize scheduling

---

If you want, I can:

* Provide a **complete BGTaskScheduler setup example**
* Compare **background fetch vs silent push**
* Show **real-world throttling scenarios**
* Explain **how iOS decides when your task runs**

Just tell me 👍
