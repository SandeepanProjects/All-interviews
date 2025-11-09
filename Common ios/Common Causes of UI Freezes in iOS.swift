//
//  Common Causes of UI Freezes in iOS.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

UI freezes in iOS apps (commonly called “jank” or “stutters”) occur when the **main thread** is blocked, preventing the app from updating the interface smoothly. Let’s go through the **common causes, why they happen, and how to avoid them**.

---

## **1. Performing Heavy Tasks on the Main Thread**

The main thread (UI thread) handles **drawing the interface and responding to user input**.
If you do anything time-consuming here, the UI freezes.

**Examples:**

* Complex calculations (e.g., image processing, sorting huge arrays)
* JSON parsing of large responses
* Synchronous file I/O

**Solution:**
Move heavy tasks to a background queue using **GCD** or **async/await**:

```swift
DispatchQueue.global(qos: .userInitiated).async {
    let result = heavyCalculation()
    DispatchQueue.main.async {
        self.label.text = "\(result)"
    }
}
```

Or with Swift concurrency:

```swift
Task.detached {
    let result = heavyCalculation()
    await MainActor.run {
        self.label.text = "\(result)"
    }
}
```

---

## **2. Synchronous Networking or I/O**

Blocking the main thread with **`Data(contentsOf:)`**, **URLSession synchronous calls**, or reading/writing large files synchronously causes freezes.

**Solution:**
Always use asynchronous APIs:

```swift
// Bad (blocks UI)
let data = try? Data(contentsOf: url)

// Good (async)
URLSession.shared.dataTask(with: url) { data, _, _ in
    DispatchQueue.main.async {
        self.imageView.image = UIImage(data: data!)
    }
}.resume()
```

Or using async/await:

```swift
let (data, _) = try await URLSession.shared.data(from: url)
imageView.image = UIImage(data: data)
```

---

## **3. Overly Complex Views**

Complex SwiftUI or UIKit layouts can freeze UI if they take too long to **compute or render**.

**Examples:**

* Deep nested `VStack`s or `HStack`s
* Hundreds of subviews in `UICollectionView`/`UITableView` without reuse
* Custom drawing in `drawRect` that’s expensive

**Solution:**

* Use `LazyVStack`/`LazyHStack` in SwiftUI
* Reuse cells with `dequeueReusableCell` in UIKit
* Cache precomputed drawing with `CALayer` or `UIGraphicsImageRenderer`

---

## **4. Blocking the Main Thread with Locks**

Using **synchronous locks, semaphores, or dispatch barriers** on the main thread can freeze UI.

**Example:**

```swift
DispatchSemaphore(value: 0).wait() // BAD on main thread
```

**Solution:**
Avoid blocking APIs on the main thread. Use asynchronous patterns instead.

---

## **5. Large Image Loading or Decoding on Main Thread**

Decoding large images or resizing them on the main thread can cause hitches.

**Solution:**

* Use `UIImage(named:)` cautiously (decodes on main thread)
* Decode images on a background thread
* Use `SDWebImage` or `Kingfisher` for async caching and decoding

```swift
DispatchQueue.global(qos: .userInitiated).async {
    let image = UIImage(data: data)
    DispatchQueue.main.async {
        imageView.image = image
    }
}
```

---

## **6. Animations or Layout Calculations that Take Too Long**

Complex animations or repeated layout recalculations can stall the UI.

**Solution:**

* Precompute layout if possible
* Minimize frequent `setNeedsLayout` or `layoutIfNeeded` calls
* Use Core Animation instead of manual `UIView` animations for performance

---

## **7. Memory Pressure / Large Data Sets**

Too much memory usage can trigger **system slowdowns**, causing temporary freezes.

**Solution:**

* Use paging for large data
* Avoid keeping huge arrays in memory at once
* Use lazy loading for images and data

---

### **Summary Table of Common Causes**

| Cause                            | Example                             | Fix / Best Practice             |
| -------------------------------- | ----------------------------------- | ------------------------------- |
| Heavy computation on main thread | Sorting large array                 | Dispatch to background thread   |
| Synchronous network requests     | `Data(contentsOf:)`                 | Use async networking            |
| Complex UI layouts               | Deeply nested stacks, many subviews | Use lazy stacks, cell reuse     |
| Blocking locks                   | Semaphores, mutex on main thread    | Avoid blocking main thread      |
| Large image processing           | Decoding huge images                | Process on background thread    |
| Expensive animations/layout      | Continuous `layoutIfNeeded` calls   | Precompute, optimize animations |
| Memory pressure                  | Loading large datasets into memory  | Use pagination, lazy loading    |

---

💡 **Key Principle:**
**Never block the main thread.** Always move heavy tasks, I/O, decoding, or computations to a **background queue** and update the UI asynchronously.

---

If you want, I can create a **diagram showing how the main thread gets blocked and how background queues prevent freezes**—it makes it super easy to visualize why UI freezes happen in iOS.

Do you want me to do that?
