//
//  adobe.swift
//  
//
//  Created by Apple on 15/12/25.
//

import Foundation

Imagine a button in your app. Once the user taps it, it should ignore any subsequent taps for a certain number of seconds.
                                                                                                
Got it! This is a classic **debounce / throttle** problem: you want the button to **ignore subsequent taps** for a set duration after the first tap. The optimal solution uses a **timestamp or flag with a timer** to block taps temporarily.
                                                                                                
Here’s a clean, Swift-ready approach.
                                                                                                
---
                                                                                                
### Solution 1: Using a Flag and `DispatchQueue`
                                                                                                
```swift
import Foundation
                                                                                                
class ThrottledButton {
    private var isEnabled = true
    private let cooldown: TimeInterval
    
    init(cooldown: TimeInterval) {
        self.cooldown = cooldown
    }
    
    func tap(action: @escaping () -> Void) {
        guard isEnabled else {
            print("Button tap ignored")
            return
        }
        
        isEnabled = false
        action()
        
        // Re-enable button after cooldown
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldown) { [weak self] in
            self?.isEnabled = true
        }
    }
}
```

---

### Example Usage

```swift
let button = ThrottledButton(cooldown: 3) // 3-second cooldown

button.tap {
    print("Button tapped!") // Executes
}

button.tap {
    print("Button tapped again!") // Ignored if within 3 seconds
}
```

✅ **Behavior:**

* First tap runs immediately.
* All taps within the cooldown are ignored.
* After cooldown, taps work again.

---

### Solution 2: SwiftUI Version

If you’re using **SwiftUI**, you can integrate the same logic directly in a `Button`:

```swift
import SwiftUI

struct ContentView: View {
    @State private var isButtonEnabled = true
    let cooldown: TimeInterval = 3
    
    var body: some View {
        Button(action: {
            guard isButtonEnabled else { return }
            isButtonEnabled = false
            
            // Your button action
            print("Button tapped!")
            
            // Re-enable after cooldown
            DispatchQueue.main.asyncAfter(deadline: .now() + cooldown) {
                isButtonEnabled = true
            }
            
        }) {
            Text("Tap me")
                .padding()
                .background(isButtonEnabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(!isButtonEnabled)
    }
}
```

✅ **Features for SwiftUI:**
                        
* Button visually disables during cooldown.
* Prevents repeated taps.
* Easy to configure cooldown duration.
                    
                    ---
                    
This approach is **optimal** because:
                        
* **O(1)** time per tap.
* Uses **minimal state** (just a flag).
* Works reliably for any UI framework.
                    
---
                    
I can also show a **version that tracks exact timestamps** instead of using `DispatchQueue`, which can be more precise if the user taps very fast repeatedly. This is what production apps sometimes use for high-frequency taps.
                    
Do you want me to do that?
                    
Absolutely! With **modern Swift concurrency** (`async`/`await`), you can handle the “ignore subsequent taps” logic in a very clean and thread-safe way without manually using `DispatchQueue`.
                    
Here’s an **optimal solution** using **actors** and `Task.sleep`:
                        
                        ---
                        
### Swift Concurrency Solution
                    
```swift
import Foundation
                    
actor ThrottledButton {
    private var isEnabled = true
    private let cooldown: UInt64 // in nanoseconds
    
    init(cooldownSeconds: Double) {
        self.cooldown = UInt64(cooldownSeconds * 1_000_000_000) // convert seconds to nanoseconds
    }
    
    func tap(action: @escaping () -> Void) async {
        guard isEnabled else {
            print("Button tap ignored")
            return
        }
        
        isEnabled = false
        action()
        
        // Suspend for cooldown
        try? await Task.sleep(nanoseconds: cooldown)
        
        isEnabled = true
    }
}
```

---

### Example Usage

```swift
let button = ThrottledButton(cooldownSeconds: 3)

Task {
    await button.tap {
        print("Button tapped!")
    }
    
    // This will be ignored if tapped within 3 seconds
    await button.tap {
        print("Button tapped again!")
    }
}
```

---

### ✅ Why this is optimal

1. **Thread-safe**: The `actor` ensures that `isEnabled` is safely accessed even across multiple tasks.
2. **Non-blocking**: `Task.sleep` suspends only the task, not the main thread.
3. **Clean and modern**: No need for `DispatchQueue` hacks.
4. **Flexible**: Works with `async` actions, so you can await network calls or animations inside the button tap.
                                        
---
                                        
If you want, I can also show a **SwiftUI-ready async/await version**, where the button visually disables itself and handles cooldown using `@State` and `Task`. This integrates perfectly with SwiftUI buttons.

Do you want me to do that?

Perfect! Let’s integrate the **async/await throttle logic** directly into a **SwiftUI button** using `@State` and `Task`. This approach is modern, clean, and ensures the button visually disables itself during the cooldown.

---

### SwiftUI Async/Await Throttled Button

```swift
import SwiftUI

struct ContentView: View {
    @State private var isButtonEnabled = true
    let cooldownSeconds: Double = 3
    
    var body: some View {
        Button(action: {
            guard isButtonEnabled else { return }
            isButtonEnabled = false
            
            Task {
                // Your async or sync action
                await performAction()
                
                // Cooldown
                try? await Task.sleep(nanoseconds: UInt64(cooldownSeconds * 1_000_000_000))
                isButtonEnabled = true
            }
            
        }) {
            Text("Tap me")
                .padding()
                .background(isButtonEnabled ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(!isButtonEnabled)
    }
    
    func performAction() async {
        // Simulate async work
        print("Button tapped!")
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec delay
        print("Action completed")
    }
}
```

---

### ✅ Features:

1. **Async-friendly**: You can safely call async functions inside the button action.
2. **Visual feedback**: Button is grayed out during cooldown using `.disabled` and background color.
3. **Non-blocking**: `Task.sleep` suspends only the current task; main UI stays responsive.
4. **Flexible cooldown**: Easily adjustable via `cooldownSeconds`.

---
      
                    
                    
                    

                                                                                                
write optimal solution for
Imagine you have a progress bar or a slider in your app that ranges from 0 to 100.
The API can return values in any range — for example, -10000 to 2000, or 5000 to 7000.
How would you convert these API values to the 0–100 scale?

Absolutely! This is a **classic linear mapping problem**: you want to map a number from **one range** to another range.

---

### Step 1: The formula

If you have a value `x` in a range `[minAPI, maxAPI]` and want to map it to `[0, 100]`, the formula is:
    
    [
        y = \frac{(x - \text{minAPI})}{(\text{maxAPI} - \text{minAPI})} \times 100
    ]

This ensures:
    
    * `x = minAPI` → `y = 0`
* `x = maxAPI` → `y = 100`

You can also clamp the value so it stays between 0 and 100.

---

### Step 2: Swift implementation

```swift
func mapToPercentage(value: Double, apiMin: Double, apiMax: Double) -> Double {
guard apiMax != apiMin else { return 0 } // avoid division by zero

let percentage = (value - apiMin) / (apiMax - apiMin) * 100
return min(max(percentage, 0), 100) // clamp to 0–100
}
```

---

### Step 3: Examples

```swift
let apiValue1 = 5000.0
let apiMin1 = 5000.0
let apiMax1 = 7000.0

let percent1 = mapToPercentage(value: apiValue1, apiMin: apiMin1, apiMax: apiMax1)
print(percent1) // 0

let apiValue2 = 6000.0
let percent2 = mapToPercentage(value: apiValue2, apiMin: apiMin1, apiMax: apiMax1)
print(percent2) // 50

let apiValue3 = 7000.0
let percent3 = mapToPercentage(value: apiValue3, apiMin: apiMin1, apiMax: apiMax1)
print(percent3) // 100
```

---

### ✅ Notes:

* Works for **any API range**, including negative values.
* Handles **edge cases** like `apiMax == apiMin`.
* **Clamping** ensures the slider never goes below 0 or above 100, even if the API value is slightly outside the expected range.

---

If you want, I can also show a **version that works directly with `Int` sliders** and rounds neatly to integers for UI display. This is often what’s used in iOS apps.

Do you want me to do that?
                
Perfect! If your slider uses **integer values from 0 to 100**, it’s best to map the API value to an **integer percentage**. You can just round or floor the calculated value.
                
Here’s the **optimal Swift solution**:
                    
---
                    
### Swift Implementation (Integer Slider)
                
```swift
func mapToSlider(value: Double, apiMin: Double, apiMax: Double) -> Int {
    guard apiMax != apiMin else { return 0 } // avoid division by zero
    
    let percentage = (value - apiMin) / (apiMax - apiMin) * 100
    let clamped = min(max(percentage, 0), 100) // clamp between 0–100
    return Int(round(clamped)) // round to nearest integer
}
```

---

### Example Usage

```swift
let apiMin = -10000.0
let apiMax = 2000.0

let apiValue1 = -10000.0
let apiValue2 = -4000.0
let apiValue3 = 2000.0

print(mapToSlider(value: apiValue1, apiMin: apiMin, apiMax: apiMax)) // 0
print(mapToSlider(value: apiValue2, apiMin: apiMin, apiMax: apiMax)) // 50
print(mapToSlider(value: apiValue3, apiMin: apiMin, apiMax: apiMax)) // 100
```

---

### ✅ Notes:

* **`round`** ensures the slider value is accurate for UI purposes.
* **Clamping** prevents the slider from going below 0 or above 100 if the API value is outside the expected range.
* Works for **any API range**, including negative, zero, or large numbers.
                                                        
---
                                                        
If you want, I can also show an **even safer version** that handles **floating-point precision issues** for very large or very small ranges, which sometimes matter in financial or scientific apps.
                                                        
Do you want me to do that?
                                                        
Great! When dealing with **very large or very small API ranges**, floating-point arithmetic can introduce tiny precision errors, which could make your slider sometimes display 101 or -1. To avoid that, we can make the mapping **numerically stable**.
                                                        
---
                                                        
### Optimized Swift Implementation (Precision-Safe)
                                                        
```swift
func mapToSliderSafe(value: Double, apiMin: Double, apiMax: Double) -> Int {
    guard apiMax != apiMin else { return 0 } // avoid division by zero
    
    // Compute ratio in a numerically stable way
    let ratio = (value - apiMin) / (apiMax - apiMin)
    
    // Clamp ratio between 0 and 1
    let clampedRatio = min(max(ratio, 0), 1)
    
    // Convert to 0–100 and round
    return Int((clampedRatio * 100).rounded())
}
```

---

### Example with Large or Small Values

```swift
let apiMin = -1_000_000_000.0
let apiMax = 2_000_000_000.0

let apiValue1 = -1_000_000_000.0
let apiValue2 = 500_000_000.0
let apiValue3 = 2_000_000_000.0

print(mapToSliderSafe(value: apiValue1, apiMin: apiMin, apiMax: apiMax)) // 0
print(mapToSliderSafe(value: apiValue2, apiMin: apiMin, apiMax: apiMax)) // 50
print(mapToSliderSafe(value: apiValue3, apiMin: apiMin, apiMax: apiMax)) // 100
```

---

### ✅ Why this is optimal and safe:

1. **Avoids division by zero** with `guard`.
2. **Uses ratio clamping** before scaling → prevents tiny floating-point overshoots.
3. **Rounds** at the end → safe for integer sliders.
4. Works for **any numeric range**, including negative numbers, very large or very small numbers.
                                        
---
  
Imagine you have several booked time slots in a day. How would you find a free slot for a new meeting?
                                                                                            
Got it! Let’s tackle this carefully. You have **booked time slots** and want to find a **free slot** for a new meeting. Here’s a structured approach:
                                                                                                
---
                                                                                                
### Step 1: Represent the slots
                                                                                            
Assume each slot is a tuple of start and end times, for example in minutes or `Date` objects:
                                                                                                
```swift
typealias TimeSlot = (start: Int, end: Int)
                                                                                            
let bookedSlots: [TimeSlot] = [
(start: 540, end: 600),  // 9:00 AM - 10:00 AM
(start: 630, end: 690),  // 10:30 AM - 11:30 AM
(start: 720, end: 780)   // 12:00 PM - 1:00 PM
]
```
                                                                                            
---
                                                                                            
### Step 2: Sort the slots by start time
                                                                                            
```swift
let sortedSlots = bookedSlots.sorted { $0.start < $1.start }
```

Sorting ensures we can check gaps between consecutive meetings.

---

### Step 3: Find gaps

If you know the **working hours** (e.g., 9 AM = 540 minutes, 5 PM = 1020 minutes), you can iterate through sorted slots to find a free gap:

```swift
func findFreeSlot(bookedSlots: [TimeSlot], meetingDuration: Int, workStart: Int, workEnd: Int) -> TimeSlot? {
    let sortedSlots = bookedSlots.sorted { $0.start < $1.start }
    
    var previousEnd = workStart
    
    for slot in sortedSlots {
        if slot.start - previousEnd >= meetingDuration {
            return (previousEnd, previousEnd + meetingDuration)
        }
        previousEnd = max(previousEnd, slot.end)
    }
    
    // Check after last meeting
    if workEnd - previousEnd >= meetingDuration {
        return (previousEnd, previousEnd + meetingDuration)
    }
    
    return nil // no free slot available
}
```

---

### Step 4: Example usage

```swift
let freeSlot = findFreeSlot(bookedSlots: bookedSlots, meetingDuration: 30, workStart: 540, workEnd: 1020)
if let slot = freeSlot {
    print("Free slot found: \(slot.start) to \(slot.end) minutes")
} else {
    print("No free slot available")
}
```

✅ **Key points:**

* Works for **any number of booked slots**.
* Handles **gaps at the start, middle, and end of the day**.
* Efficient: **O(n log n)** because of sorting, **O(n)** to check gaps.
                
                ---
                
I can also show a **version using Swift `Date` and `Calendar`** if you want something that works with real clock times instead of just minutes. It’s a bit more “real-world ready.”
                
Do you want me to do that version too?

Perfect! Let’s make this **real-world ready** using Swift `Date` and `Calendar`. This way, you can handle actual times, not just minutes.
                
---
                
### Step 1: Define a `TimeSlot` type
                
```swift
import Foundation
                
struct TimeSlot {
    let start: Date
    let end: Date
}
```

---

### Step 2: Helper to create a `Date` easily

```swift
func makeDate(hour: Int, minute: Int) -> Date {
    let calendar = Calendar.current
    return calendar.date(
        bySettingHour: hour,
        minute: minute,
        second: 0,
        of: Date()
    )!
}
```

Example:

```swift
let meeting1 = TimeSlot(start: makeDate(hour: 9, minute: 0),
                        end: makeDate(hour: 10, minute: 0))
let meeting2 = TimeSlot(start: makeDate(hour: 10, minute: 30),
                        end: makeDate(hour: 11, minute: 30))
let meeting3 = TimeSlot(start: makeDate(hour: 12, minute: 0),
                        end: makeDate(hour: 13, minute: 0))

let bookedSlots = [meeting1, meeting2, meeting3]
```

---

### Step 3: Find a free slot

```swift
func findFreeSlot(bookedSlots: [TimeSlot], meetingDuration: TimeInterval, workStart: Date, workEnd: Date) -> TimeSlot? {
    let sortedSlots = bookedSlots.sorted { $0.start < $1.start }
    var previousEnd = workStart
    
    for slot in sortedSlots {
        let gap = slot.start.timeIntervalSince(previousEnd)
        if gap >= meetingDuration {
            return TimeSlot(start: previousEnd, end: previousEnd.addingTimeInterval(meetingDuration))
        }
        previousEnd = max(previousEnd, slot.end)
    }
    
    // Check after last meeting
    let gapAfterLast = workEnd.timeIntervalSince(previousEnd)
    if gapAfterLast >= meetingDuration {
        return TimeSlot(start: previousEnd, end: previousEnd.addingTimeInterval(meetingDuration))
    }
    
    return nil // no free slot available
}
```

---

### Step 4: Use it

```swift
let workStart = makeDate(hour: 9, minute: 0)
let workEnd = makeDate(hour: 17, minute: 0)
let meetingDuration: TimeInterval = 30 * 60 // 30 minutes in seconds

if let freeSlot = findFreeSlot(bookedSlots: bookedSlots, meetingDuration: meetingDuration, workStart: workStart, workEnd: workEnd) {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    print("Free slot: \(formatter.string(from: freeSlot.start)) - \(formatter.string(from: freeSlot.end))")
} else {
    print("No free slot available")
}
```

✅ **Advantages of this approach:**

* Works with **real times and dates**.
* Handles **gaps at the start, middle, and end of the day**.
* Extensible for **different durations** or **different working hours**.
                    
---

                
write optimal solution in swift
You’re given a series of numbers — one number is missing. How will you find which one

Got it! Let's tackle this carefully. The problem is:

> You have a series of numbers with **one missing**. Find the missing number efficiently in Swift.

There are several ways to do this, but the **optimal solution** uses the **sum formula** approach, which is **O(n) time and O(1) space**.

---

### Solution in Swift

```swift
func findMissingNumber(in array: [Int]) -> Int {
    let n = array.count + 1 // total numbers including the missing one
    let expectedSum = n * (n + 1) / 2
    let actualSum = array.reduce(0, +)
    return expectedSum - actualSum
}

// Example:
let numbers = [1, 2, 4, 5, 6] // missing 3
let missing = findMissingNumber(in: numbers)
print("Missing number is \(missing)") // Output: 3
```

---

### How it works:

1. The sum of numbers from 1 to `n` is `n*(n+1)/2`.
2. Calculate the sum of the given array.
3. Subtract the array sum from the expected sum → gives the missing number.

---

✅ **Complexity:**

* **Time:** O(n) (just one pass to sum the array)
* **Space:** O(1) (no extra storage needed)

---

If the array **is not guaranteed to start at 1** or contains arbitrary numbers, there’s a similar optimal approach using **XOR**. I can write that version too—it’s even more elegant for arbitrary sequences.

Do you want me to show the XOR version as well?


Difference between .onTask and .onAppear in SwiftUI.

In **SwiftUI**, both `.onAppear` and `.task` (or `.onTask`) modifiers are used to perform actions when a view appears, but they differ in **timing, capabilities, and use cases**. Let’s break it down carefully:

---

### **1. `.onAppear`**

**Definition:**
`.onAppear` is a view modifier that runs a closure when the view **appears on screen**.

**Syntax:**

```swift
Text("Hello")
    .onAppear {
        print("View appeared!")
    }
```

**Characteristics:**

* Runs **synchronously** when the view comes on screen.
* Cannot use `await` directly (so you can’t call async functions without creating a Task).
* Often used for side effects like logging, triggering animations, or starting non-async work.

**Example (without async):**

```swift
.onAppear {
    loadData() // synchronous function
}
```

**Async workaround:**

```swift
.onAppear {
    Task {
        await fetchData() // call async code
    }
}
```

---

### **2. `.task` / `.onTask`**

**Definition:**
`.task` is a modifier designed specifically for running **asynchronous tasks** tied to the lifecycle of a view.

**Syntax:**

```swift
Text("Hello")
    .task {
        await fetchData() // async call directly
    }
```

**Characteristics:**

* Runs **asynchronously** when the view appears.
* Supports `await` directly.
* SwiftUI automatically **cancels the task** if the view disappears (useful for cleanup).
* Ideal for network calls, data fetching, or any long-running async operation.

**Example (async fetch):**

```swift
.task {
    do {
        let data = try await fetchData()
        self.items = data
    } catch {
        print("Error fetching data: \(error)")
    }
}
```

---

### **3. Key Differences**

| Feature                   | `.onAppear`                                 | `.task` / `.onTask`                                    |
| ------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| Runs synchronously        | ✅                                           | ❌ (runs async)                                         |
| Supports `await` directly | ❌ (needs `Task {}` wrapper)                 | ✅                                                      |
| Cancelable automatically  | ❌                                           | ✅ (task cancels if view disappears)                    |
| Typical use case          | Logging, animations, non-async side effects | Async data fetching, network calls, long-running tasks |
| Lifecycle tied to view    | Appears/disappears                          | Appears/disappears with automatic cancellation         |

---

### **Summary / Rule of Thumb**

* Use **`.onAppear`** for simple, synchronous, side-effect work when the view appears.
* Use **`.task`** for **async work** tied to the view’s lifecycle — it’s cleaner and cancellation-aware.

---
