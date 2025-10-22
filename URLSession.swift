//
//  URLSession.swift
//  
//
//  Created by Apple on 22/10/25.
//

import Foundation

Absolutely — **`URLSession`** is a **core networking API** in iOS, and it's **frequently asked** in interviews for **mid-level to senior iOS roles** (both Objective-C and Swift environments).

Below is a **comprehensive guide** to common and advanced `URLSession` interview questions, categorized with **sample answers**, best practices, and gotchas.

---

## ✅ **Core Interview Questions on `URLSession`**

---

### **1. What is `URLSession`? How does it work?**

`URLSession` is an API used to **perform networking tasks** — like making HTTP requests, downloading/uploading files, and handling background tasks.

* It provides a set of classes for sending/receiving data.
* It's a **replacement for NSURLConnection** (which is deprecated).
* It is **asynchronous by default**, using closures, delegates, or tasks.

---

### **2. What are the different types of tasks in `URLSession`?**

1. **`dataTask`** – For standard HTTP GET/POST requests (fetching JSON, etc.)
2. **`downloadTask`** – For downloading files to disk (can resume later)
3. **`uploadTask`** – For uploading data or files
4. **`streamTask`** – For reading/writing streams of data (used less often)

Example:

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    // Handle response
}
task.resume()
```

---

### **3. How do you create a `URLSession`?**

There are **3 main ways**:

1. **Shared session (simple)**

```swift
let session = URLSession.shared
```

2. **Default session (custom config)**

```swift
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config)
```

3. **Custom session with delegate**

```swift
let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
```

---

### **4. What are `URLSessionConfiguration` types?**

* **default**: Uses disk cache, cookies, etc.
* **ephemeral**: Nothing is saved to disk (great for privacy)
* **background**: Allows downloads/uploads even if app is suspended

Use **background sessions** for large file downloads or uploads.

---

### **5. How does `URLSession` handle completion handlers vs delegates?**

* **Completion handlers** are easier and cleaner for simple requests.
* **Delegates** are more powerful for:

  * Tracking progress
  * Handling redirects/authentication
  * Working with background tasks

### Delegate example:

```swift
func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    // Handle streaming data
}
```

---

### **6. How do you perform a POST request using `URLSession`?**

```swift
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.httpBody = jsonData
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}.resume()
```

---

### **7. How do you handle timeouts in `URLSession`?**

Set it via `URLSessionConfiguration`:

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60
```

---

### **8. What are some common networking error cases you should handle?**

* `URLError.notConnectedToInternet`
* `URLError.timedOut`
* `URLError.cancelled`
* `HTTP status codes`: 400, 401, 500, etc.
* Server returns invalid/malformed data

Interviewers expect you to check:

```swift
if let httpResponse = response as? HTTPURLResponse {
    if (200...299).contains(httpResponse.statusCode) {
        // Success
    } else {
        // Handle HTTP error
    }
}
```

---

### **9. How do you cancel a `URLSessionTask`?**

```swift
let task = URLSession.shared.dataTask(with: url)
task.cancel()
```

Also useful for:

* Avoiding duplicate requests
* Cancelling requests on scroll (e.g., image loading)

---

### **10. How does `URLSession` support background downloads?**

Use:

```swift
let config = URLSessionConfiguration.background(withIdentifier: "com.example.bgDownload")
let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
```

Then implement delegate methods:

```swift
func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
```

Make sure to handle `completionHandler` in AppDelegate:

```swift
func application(_ application: UIApplication,
                 handleEventsForBackgroundURLSession identifier: String,
                 completionHandler: @escaping () -> Void)
```

---

## 🚧 **Advanced & Senior-Level Interview Questions**

---

### **11. How do you monitor download or upload progress using `URLSession`?**

Via delegate methods:

```swift
func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64,
                totalBytesSent: Int64, totalBytesExpectedToSend: Int64)

func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                totalBytesExpectedToWrite: Int64)
```

---

### **12. How do you resume a paused download with `URLSession`?**

Use:

* `cancel(byProducingResumeData:)`
* Store `resumeData`
* Use `downloadTask(withResumeData:)` to restart

---

### **13. How does `URLCache` work with `URLSession`?**

`URLSession` supports caching via `URLCache`:

```swift
let config = URLSessionConfiguration.default
config.urlCache = URLCache(memoryCapacity: ..., diskCapacity: ..., diskPath: "myCache")

let session = URLSession(configuration: config)
```

Caching is only used if:

* Server returns correct headers (`Cache-Control`, `ETag`, etc.)
* Request cache policy allows it

---

### **14. How do you authenticate with `URLSession` (Basic Auth, Token, etc.)?**

**Token:**

```swift
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

**Basic Auth:**

```swift
let loginString = "\(username):\(password)"
let base64Login = loginString.data(using: .utf8)?.base64EncodedString()
request.setValue("Basic \(base64Login!)", forHTTPHeaderField: "Authorization")
```

---

### **15. What is a memory leak or retain cycle with `URLSession` and how to avoid it?**

If you use a closure and reference `self` strongly inside it:

```swift
URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
    self?.doSomething()
}
```

Always use `[weak self]` to **avoid retain cycles**, especially in view controllers.

---

### **16. How do you test `URLSession` in unit tests?**

Use **dependency injection** and **mocking**:

* Inject `URLSessionProtocol` instead of `URLSession`
* Use `URLProtocol` to stub/mock responses

Example using `URLProtocol`:

```swift
class MockURLProtocol: URLProtocol {
    // override methods to return custom data
}
```

---

### **17. What’s the difference between `URLSession.shared` vs custom session?**

| Aspect       | `URLSession.shared`     | Custom `URLSession`        |
| ------------ | ----------------------- | -------------------------- |
| Configurable | ❌ No                    | ✅ Yes                      |
| Delegate     | ❌ No delegate           | ✅ Can set delegate         |
| Best for     | Simple one-off requests | Background, authentication |

---

### **18. How do you handle SSL pinning in `URLSession`?**

Implement this delegate:

```swift
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
```

Use it to compare server certificates against bundled certificates.

---

### **19. How do you throttle or batch requests using `URLSession`?**

Use an `OperationQueue` or custom request queue system to:

* Limit concurrent requests
* Prioritize tasks
* Batch low-priority tasks

---

### **20. Can you upload files with `multipart/form-data` using `URLSession`?**

Yes — you must manually build the `multipart/form-data` body with proper boundaries and headers.

---

## 📌 Tips for Interviews

* Be able to explain **when to use delegates vs closures**
* Know how to use **background sessions**
* Be ready to discuss **error handling** and **resilience**
* Show knowledge of **security (SSL, token auth)**
* Demonstrate **testability and mocking techniques**

---
