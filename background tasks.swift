//
//  background tasks.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Handling background tasks in iOS is crucial for performing operations like syncing data, fetching updates, or uploading files when the app is not in the foreground. Apple provides a few mechanisms to support background execution while preserving battery life and user privacy.

Here’s a breakdown of how to handle background tasks in iOS:

---

### ✅ **1. Background Modes (Capabilities)**

Before anything, **enable background modes** in your project:

* Go to **Xcode > Project settings > Signing & Capabilities**
* Add **"Background Modes"**
* Check the appropriate options like:

  * Background fetch
  * Background processing
  * Remote notifications
  * Background audio, etc.

---

### 🔁 **2. Background Fetch (Periodic Tasks)**

Used for apps that need to fetch content regularly.

**Enable:** Background Fetch in capabilities.

**Implementation:**

```swift
func application(_ application: UIApplication,
                 performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Fetch your data here
    fetchData { success in
        if success {
            completionHandler(.newData)
        } else {
            completionHandler(.failed)
        }
    }
}
```

**Configure interval:**

```swift
UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
```

---

### 📦 **3. Background URLSession (Networking)**

Used for uploading/downloading files in the background.

**Key points:**

* Define a `URLSession` with a **background configuration**.
* Delegate handles events when the app relaunches.

**Example:**

```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.bgSession")
let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

let task = session.downloadTask(with: url)
task.resume()
```

**AppDelegate:**

```swift
func application(_ application: UIApplication,
                 handleEventsForBackgroundURLSession identifier: String,
                 completionHandler: @escaping () -> Void) {
    // Store the completion handler to call later
    BackgroundSessionManager.shared.savedCompletionHandler = completionHandler
}
```

---

### 🧠 **4. BGTaskScheduler (iOS 13+)**

Used for **background processing tasks** like syncing or cleaning up resources.

**Setup:**

* Enable **Background Processing** in capabilities.
* Register tasks in `Info.plist` under `Permitted background task scheduler identifiers`.

**Register task:**

```swift
BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.refresh", using: nil) { task in
    self.handleAppRefresh(task: task as! BGAppRefreshTask)
}
```

**Schedule a task:**

```swift
let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.refresh")
request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

do {
    try BGTaskScheduler.shared.submit(request)
} catch {
    print("Could not schedule app refresh: \(error)")
}
```

**Handle task:**

```swift
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // Schedule the next one
    let operation = YourBackgroundOperation()

    task.expirationHandler = {
        operation.cancel()
    }

    operation.completionBlock = {
        task.setTaskCompleted(success: !operation.isCancelled)
    }

    OperationQueue().addOperation(operation)
}
```

---

### 📩 **5. Remote Notifications (Silent Push)**

Used for triggering updates via **silent push notifications**.

**Server sends a push with:**

```json
{
  "aps": {
    "content-available": 1
  }
}
```

**DidReceiveRemoteNotification:**

```swift
func application(_ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    // Perform background work here
}
```

---

### 🔐 Important Considerations:

* iOS prioritizes battery life — tasks may be delayed or throttled.
* You **must complete tasks quickly** or iOS may terminate them.
* For **long tasks**, use `BGProcessingTask` instead of `BGAppRefreshTask`.
* Always test on a real device. Simulators don't behave like real devices in the background.

---

### 📚 Tools for Debugging & Testing:

* Use **Xcode > Debug > Simulate Background Fetch**
* Use **`Console.app`** for logs (filter by your device)
* Use breakpoints or logs to see when your tasks run

---

Would you like a code template or example project using any of the above (e.g., background fetch or URLSession)?

Great! Let’s do a simple **Background Fetch** example project in Swift, which is one of the easiest ways to get started with background tasks in iOS.
                    
                    ---
                    
# Simple Background Fetch Example in Swift
                    
### Step 1: Enable Background Fetch
                    
* Open your Xcode project.
* Go to your **Project > Signing & Capabilities** tab.
* Click **+ Capability** and add **Background Modes**.
* Check **Background fetch**.
                    
                    ---
                    
### Step 2: Set Minimum Background Fetch Interval in `AppDelegate.swift`
                    
Add this inside your `application(_:didFinishLaunchingWithOptions:)`:
                        
```swift
UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
```
                    
                    ---
                    
### Step 3: Implement `performFetchWithCompletionHandler`
                    
Add this method inside your `AppDelegate.swift`:
                        
```swift
func application(_ application: UIApplication,
                 performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    // Simulate a network fetch or data update
    fetchDataFromServer { newDataAvailable in
        if newDataAvailable {
            print("New data was fetched!")
            completionHandler(.newData)
        } else {
            print("No new data.")
            completionHandler(.noData)
        }
    }
}
```

---

### Step 4: Implement the `fetchDataFromServer` Method

This is a mock function simulating a network call (replace with your real API logic):

```swift
func fetchDataFromServer(completion: @escaping (Bool) -> Void) {
    // Simulate network latency
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        // Let's say we got new data randomly
        let newData = Bool.random()
        completion(newData)
    }
}
```

---

### Full `AppDelegate.swift` Example:

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        fetchDataFromServer { newDataAvailable in
            if newDataAvailable {
                print("New data was fetched!")
                completionHandler(.newData)
            } else {
                print("No new data.")
                completionHandler(.noData)
            }
        }
    }
    
    func fetchDataFromServer(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let newData = Bool.random()
            completion(newData)
        }
    }
}
```

---

### Step 5: Testing Background Fetch

1. Run your app on a real device.
2. In Xcode, go to **Debug > Simulate Background Fetch**.
3. You should see the print statements from the `performFetchWithCompletionHandler` method in the console.

---

If you want, I can also show you how to do **Background URLSession** or the newer **BGTaskScheduler** API. Would you like to go over those next?

Awesome! Let’s go next with **Background URLSession** — a powerful way to handle uploads/downloads that continue even if your app is suspended or terminated.

---

# Background URLSession Example in Swift

---

### Step 1: Enable Background Modes for Background Processing

* In Xcode, open **Signing & Capabilities**
* Add **Background Modes**
* Check **Background fetch** and **Background processing** (optional but recommended)
* Make sure **Background fetch** is checked at minimum for this example.

---

### Step 2: Create a `URLSession` with Background Configuration

Create a custom class to handle background downloads:

```swift
import Foundation

class BackgroundSessionManager: NSObject, URLSessionDownloadDelegate {
    static let shared = BackgroundSessionManager()
    
    var savedCompletionHandler: (() -> Void)?
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.yourapp.bgSession")
        config.isDiscretionary = true // System decides best time
        config.sessionSendsLaunchEvents = true // Relaunch app if needed
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func startDownload(url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    // MARK: URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move the downloaded file from temp location to permanent location
        print("Download finished at \(location)")
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.savedCompletionHandler?()
            self.savedCompletionHandler = nil
        }
    }
}
```

---

### Step 3: Start a Download Task from Your App

In your view controller or wherever appropriate:

```swift
if let url = URL(string: "https://speed.hetzner.de/100MB.bin") {
    BackgroundSessionManager.shared.startDownload(url: url)
}
```

---

### Step 4: Handle Background Events in `AppDelegate`

In your `AppDelegate.swift`:

```swift
func application(_ application: UIApplication,
                 handleEventsForBackgroundURLSession identifier: String,
                 completionHandler: @escaping () -> Void) {
    BackgroundSessionManager.shared.savedCompletionHandler = completionHandler
}
```

This tells the system what to do when your app is relaunched in the background to handle events related to background URL sessions.

---

### Summary:

* Background URLSession lets downloads/uploads continue when your app is in background or killed.
* When download completes, your delegate is called and you can process the file.
* If the app was killed, iOS relaunches it and calls `handleEventsForBackgroundURLSession`.

---

### Want me to walk you through a **full minimal project** with UI or do you want to jump into **BGTaskScheduler** next?

Perfect! BGTaskScheduler is the modern way (iOS 13+) to schedule background tasks like refreshing content or performing longer processing jobs in the background.

---

# BGTaskScheduler Example in Swift

---

### Step 1: Enable Background Processing Capability

* In **Xcode > Signing & Capabilities**, add **Background Modes**
* Check **Background processing**

---

### Step 2: Add Identifiers in `Info.plist`

Add a new key:

```
BGTaskSchedulerPermittedIdentifiers (Array)
```

Add an item (String):

```
com.yourapp.refresh
```

Replace `"com.yourapp.refresh"` with your own unique identifier.

---

### Step 3: Register and Schedule the Background Task

In your `AppDelegate.swift`:

```swift
import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Register the background refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        scheduleAppRefresh()
        
        return true
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BGAppRefreshTaskRequest submitted")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()
        
        // Create an operation queue to do the work
        let queue = OperationQueue()
        
        // Create your background operation (replace with real work)
        let operation = BlockOperation {
            // Simulate work
            print("Background task is running...")
            Thread.sleep(forTimeInterval: 5)
        }
        
        task.expirationHandler = {
            // Cancel the operation if the system terminates the task early
            queue.cancelAllOperations()
            print("Background task expired")
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
            print("Background task completed")
        }
        
        queue.addOperation(operation)
    }
    
    // Handle when the app is terminated by the system
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }
}
```

---

### Step 4: Testing BGTaskScheduler

* **Run your app on a real device.**
* Put your app in background.
* Use **Xcode > Debug > Simulate Background Fetch** to simulate the BGAppRefreshTask.
* Check console logs for prints like `"Background task is running..."`.

---

### Notes:

* BGTaskScheduler **tasks may not run immediately**; iOS optimizes based on system conditions.
* Use `BGProcessingTaskRequest` if you need longer background time (e.g., >30 seconds).
* Always reschedule your background tasks inside the task handler to keep them running.

---

Would you like me to help with an example using **BGProcessingTask** for longer tasks, or how to combine this with real network calls?

Awesome! Let’s extend the BGTaskScheduler example with both:
                                        
1. **BGProcessingTask** — for longer, more flexible background work (e.g., syncing large data or cleanup).
2. Real **network calls** integrated into these background tasks.
                                    
---
                                    
# Step-by-step: BGProcessingTask + Network Call Example
                                    
---
                                    
## Step 1: Update `Info.plist`
                                    
Add your identifiers:
                                        
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
<string>com.yourapp.refresh</string>
<string>com.yourapp.processing</string>
</array>
```
                                    
---
                                    
## Step 2: Register Both Tasks in `AppDelegate.swift`
                                    
```swift
import UIKit
import BackgroundTasks
                                    
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.processing", using: nil) { task in
            self.handleProcessingTask(task: task as! BGProcessingTask)
        }
        
        scheduleAppRefresh()
        scheduleProcessingTask()
        
        return true
    }
    
    // MARK: - Scheduling
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled app refresh task")
        } catch {
            print("Failed to schedule app refresh: \(error)")
        }
    }
    
    func scheduleProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: "com.yourapp.processing")
        request.requiresNetworkConnectivity = true   // Needs network
        request.requiresExternalPower = false        // Can run on battery
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled processing task")
        } catch {
            print("Failed to schedule processing task: \(error)")
        }
    }
    
    // MARK: - Task Handlers
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Schedule next
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = NetworkFetchOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
            print("AppRefresh task expired")
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
            print("AppRefresh task completed")
        }
        
        queue.addOperation(operation)
    }
    
    func handleProcessingTask(task: BGProcessingTask) {
        scheduleProcessingTask() // Schedule next
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = NetworkFetchOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
            print("Processing task expired")
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
            print("Processing task completed")
        }
        
        queue.addOperation(operation)
    }
    
    // MARK: - Background task scheduling when app enters background
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
        scheduleProcessingTask()
    }
}
```

---

## Step 3: Create a `NetworkFetchOperation` (Subclass of `Operation`)

This will do the real network call in the background task.

```swift
import Foundation

class NetworkFetchOperation: Operation {
    
    private var task: URLSessionDataTask?
    
    override func main() {
        if isCancelled { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else {
            print("Invalid URL")
            return
        }
        
        task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            
            if self.isCancelled { return }
            
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let jsonString = String(data: data, encoding: .utf8) {
                print("Fetched data: \(jsonString)")
            }
        }
        
        task?.resume()
        
        // Wait for network call to finish or operation to be cancelled
        semaphore.wait()
    }
    
    override func cancel() {
        super.cancel()
        task?.cancel()
    }
}
```

---

## Explanation:

* `BGAppRefreshTask` is scheduled to run short refresh tasks.
* `BGProcessingTask` is for longer work that can take more time (up to 30 mins, usually).
* Both use the same network operation here, but you can customize.
* The network call fetches JSON from a public API and prints it.
* Expiration handlers cancel the operations if the system kills the background task early.
                                
---
                                
## Step 4: Testing
                                
* Run on a **real device** (BGTasks won’t run on simulator properly).
* Use **Xcode > Debug > Simulate Background Fetch** to simulate the refresh task.
* To simulate the processing task, use:
                                    
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.yourapp.processing"]
```
                                
in the debugger console (private API, so use for testing only).
                                
---
                                
If you want, I can help with:
                                    
* Full sample Xcode project setup
* How to handle task expiration gracefully with saving state
* Scheduling best practices & debugging tips
                                
Would you like to dive into any of these?

Great topics! Handling **task expiration gracefully** and mastering **scheduling & debugging** are key to making your iOS background tasks reliable and efficient. Let’s dive in:
                                    
---
                                    
## 1. Handling Task Expiration Gracefully with Saving State
                                
When iOS decides to terminate your background task early (due to time limits or system constraints), it calls your task’s **expirationHandler**. Your job is to:
                                    
* **Stop work immediately**
* **Save any in-progress state/data**
* **Clean up resources**
                                
### How to do it:
                                    
### Example (based on `Operation` subclass):
                                    
```swift
class NetworkFetchOperation: Operation {
    private var task: URLSessionDataTask?
    private var isTaskCompleted = false
    private var savedData: Data?
    
    override func main() {
        if isCancelled { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1") else { return }
        
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            defer { semaphore.signal() }
            
            if self.isCancelled { return }
            
            if let data = data {
                self.savedData = data // Save fetched data for later use
                self.isTaskCompleted = true
                print("Data fetched and saved")
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        
        task?.resume()
        semaphore.wait()
    }
    
    override func cancel() {
        super.cancel()
        task?.cancel()
        
        // Save partial state if needed, e.g. persist to disk or UserDefaults
        if let data = savedData {
            saveDataToDisk(data)
        }
    }
    
    private func saveDataToDisk(_ data: Data) {
        // Implement saving to disk or database for restoration on next launch
        print("Saving data to disk")
        // Example:
        // try? data.write(to: someFileURL)
    }
}
```

### In your **background task expiration handler**:

```swift
task.expirationHandler = {
    queue.cancelAllOperations()
    print("Background task expired - cleaning up and saving state")
    // Save any additional state if needed here
}
```

---

## 2. Scheduling Best Practices

* **Always reschedule tasks at the end of your task handler** to ensure the system runs your tasks repeatedly.
* **Set reasonable earliestBeginDate** to avoid excessive CPU/battery use (e.g., 15 mins or more).
* **Use appropriate task type:**

* Use `BGAppRefreshTask` for short, lightweight fetches (<30 seconds).
* Use `BGProcessingTask` for longer or resource-intensive tasks (e.g., large uploads, database cleanup).
* **Specify requirements in `BGProcessingTaskRequest`:**
                                    
* `.requiresNetworkConnectivity = true` if the task needs internet.
* `.requiresExternalPower = true` if the task needs the device plugged in.
* **Avoid scheduling too many tasks at once** — it wastes resources and the system may delay/cancel them.
* **Test on real devices** — simulator behavior differs from actual device background execution.
* **Handle failures gracefully** — if a task fails, you may want to retry with exponential backoff or notify the user.
                                
---
                                
## 3. Debugging Tips for BGTaskScheduler
                                
* **Use Xcode Debug > Simulate Background Fetch** to simulate BGAppRefreshTask.
* To simulate a BGProcessingTask (private API, for testing only), run in LLDB console:
                                    
```lldb
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.yourapp.processing"]
```
                                
* **Check Console Logs:**
                                    
* Use macOS Console app to view device logs.
* Filter by your app’s process or the task identifiers.
* **Add lots of `print` statements or use OSLog** for fine-grained logs.
* **Use breakpoints** in your background task handlers to verify execution.
* **Watch out for expiration:** make sure your `expirationHandler` is called and behaves as expected.
* **Review `BGTaskScheduler` errors:** when submitting a task request, catch and log errors.
                                
---
                                
### Bonus: Tips to avoid common pitfalls
                                
| Pitfall                       | Advice                                              |
| ----------------------------- | --------------------------------------------------- |
| Not rescheduling tasks        | Always schedule new tasks at the end of handlers    |
| Long blocking operations      | Use `OperationQueue` and avoid blocking main thread |
| Forgetting expiration handler | Always implement `expirationHandler`                |
| Overusing background tasks    | Schedule only essential tasks to conserve battery   |
| Using simulator for testing   | Test on real devices                                |
                                
---
                                
Gotcha! You’re asking **how to use iOS background tasks inside Swift’s `Task` (async/await) concurrency model** — basically mixing background execution APIs with Swift concurrency.
                                
---
                                
## Using Background Tasks with Swift Concurrency (`Task`)
                                
Swift’s modern concurrency (`async`/`await`, `Task`) works great with background tasks like BGTaskScheduler, but they’re fundamentally different:
                                    
* **Background tasks (BGTaskScheduler)** run when iOS decides — your app wakes up in background and you run some code.
* **Swift Tasks** represent async work **inside your app's process** — usually active when app is running.
                                
---
                                
### How to combine them?
                                
1. **Start a BGTaskScheduler task** as usual.
2. **Inside the BGTask handler, launch Swift `Task` or `async` functions** to do the work cleanly.
3. Use Swift concurrency features like async network calls, structured concurrency, etc.
4. Manage expiration properly — iOS gives limited time to finish.
                                
---
                                
### Example of BGAppRefreshTask handler using async/await:
                                    
```swift
func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // Schedule next
    
    let task = Task {
        do {
            try await performBackgroundWork()
            task.setTaskCompleted(success: true)
            print("Background task completed successfully")
        } catch {
            task.setTaskCompleted(success: false)
            print("Background task failed with error: \(error)")
        }
    }
    
    // Expiration handler to cancel Swift task if system kills background time
    task.expirationHandler = {
        print("Background task expired — cancelling Swift task")
        task.cancel()
    }
}
```

**But this won’t compile as-is, because you have name conflict:**

To clarify:

* The parameter `task` is a `BGAppRefreshTask`
* You want to create a Swift concurrency `Task` instance.

Better to rename variables to avoid confusion:

```swift
func handleAppRefresh(bgTask: BGAppRefreshTask) {
    scheduleAppRefresh()
    
    let swiftTask = Task {
        do {
            try await performBackgroundWork()
            bgTask.setTaskCompleted(success: true)
            print("Background task completed successfully")
        } catch {
            bgTask.setTaskCompleted(success: false)
            print("Background task failed with error: \(error)")
        }
    }
    
    bgTask.expirationHandler = {
        print("Background task expired — cancelling Swift task")
        swiftTask.cancel()
    }
}
```

---

### Example `performBackgroundWork()` async function:

```swift
func performBackgroundWork() async throws {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    let (data, _) = try await URLSession.shared.data(from: url)
    
    // Process your data here
    print("Fetched data size: \(data.count) bytes")
    
    // Simulate some async work
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
}
```

---

### Key points:

* Use `Task` inside your background handler to run async/await code.
* Call `bgTask.setTaskCompleted(success:)` **only after** your async work finishes.
* Use `bgTask.expirationHandler` to **cancel your Swift `Task`** gracefully.
* Make sure your async work **checks for cancellation** (`Task.isCancelled`) to exit early if needed.
                                            
                                            ---
                                            
### Example full simplified BGTaskScheduler handler using async/await:
                                                
```swift
func handleAppRefresh(bgTask: BGAppRefreshTask) {
    scheduleAppRefresh()
    
    let swiftTask = Task {
        do {
            try await performBackgroundWork()
            bgTask.setTaskCompleted(success: true)
        } catch {
            bgTask.setTaskCompleted(success: false)
        }
    }
    
    bgTask.expirationHandler = {
        swiftTask.cancel()
    }
}
```

---
