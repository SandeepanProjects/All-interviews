//
//  Background Threads Don’t Have a RunLoop.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

This is a classic (and subtle) topic in Cocoa / Cocoa Touch threading. Let’s unpack it step by step and connect all three questions.

---

## 1. What a RunLoop actually is

A **RunLoop** is not a thread.

A RunLoop is an **event-processing loop attached to a thread** that:

* waits for input sources (ports, sockets, timers, etc.)
* wakes up when something arrives
* dispatches the work
* goes back to sleep

Key point:

> **RunLoops are opt-in, not automatic (except for the main thread).**

---

## 2. Why the main thread always has a RunLoop

The **main thread** is special because UIKit/AppKit requires it to:

* handle touch/mouse events
* draw the UI
* fire timers
* receive system notifications

So when your app starts, the system:

* creates the main thread
* **automatically creates and runs its RunLoop**
* keeps it alive for the entire app lifecycle

That’s why this works without thinking:

```swift
Timer.scheduledTimer(...)
```

on the main thread.

---

## 3. Why background threads don’t have a RunLoop by default

When you create a background thread (e.g. `Thread`, `NSThread`, pthreads):

```swift
Thread {
    print("Hello from background")
}.start()
```

What happens:

1. Thread starts
2. Your closure runs
3. Closure returns
4. **Thread exits immediately**

There is **no reason** for the system to:

* keep the thread alive
* create a RunLoop
* wait for events

Because most background work is **fire-and-forget**:

* calculations
* file IO
* image processing

Creating and running a RunLoop would waste resources.

So:

> **Background threads do not have a running RunLoop unless you explicitly start one.**

---

## 4. Why timers don’t fire on background threads

Timers are **RunLoop-based**.

When you do:

```swift
Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
    print("Tick")
}
```

This does two things:

1. Creates a timer
2. **Registers it with the current thread’s RunLoop**

On a background thread:

* There is **no running RunLoop**
* So the timer gets registered…
* …but nothing ever wakes up to fire it

Result: **Timer never fires**

### Common mistake

```swift
DispatchQueue.global().async {
    Timer.scheduledTimer(...)
}
```

❌ The timer is created, but the thread exits and no RunLoop is running.

---

## 5. Why some network callbacks never arrive

Certain networking APIs (especially older ones) rely on:

* **RunLoop input sources**
* **Mach ports / sockets**
* **CFNetwork scheduling**

Examples:

* `NSURLConnection`
* some `URLSession` configurations
* custom stream-based networking

If you schedule them on a background thread **without a RunLoop**:

* the socket is created
* data arrives at the OS level
* **no RunLoop is there to deliver the event**
* callback never fires

This leads to the mysterious bug:

> “The request starts, but the delegate methods never get called.”

---

## 6. “Until you force one” — how RunLoops appear on background threads

A background thread **can have a RunLoop**, but you must:

1. Access it
2. Keep it alive
3. Run it

Example:

```swift
Thread {
    let runLoop = RunLoop.current

    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
        print("Tick")
    }

    runLoop.run()
}.start()
```

What’s happening:

* Accessing `RunLoop.current` **creates** a RunLoop for that thread
* `run()` starts the event-processing loop
* The thread stays alive
* Timers and network events now work

⚠️ This thread will now live **forever** unless you stop the RunLoop.

---

## 7. Why GCD “fixes” this without RunLoops

Grand Central Dispatch avoids RunLoops entirely.

When you use:

```swift
DispatchQueue.main.asyncAfter(...)
DispatchQueue.global().async { ... }
```

* GCD uses kernel-managed queues
* No RunLoop required
* No thread lifetime issues
* No manual event pumping

This is why Apple recommends:

> **Use GCD or async/await instead of RunLoop-based threading**

for almost all background work.

---

## 8. Mental model summary

Think of it like this:

| Thread Type               | Has RunLoop?    | Why                      |
| ------------------------- | --------------- | ------------------------ |
| Main thread               | ✅ Always        | UI + event handling      |
| Background thread         | ❌ By default    | Short-lived work         |
| Forced background RunLoop | ✅ If you run it | Timers / ports / streams |

---

## One-sentence takeaway

> **Background threads don’t have RunLoops because they’re meant to finish and die; timers and some networking APIs silently fail because there’s no event loop to deliver their events—until you explicitly create and run one.**

If you want, I can also:

* show how this differs between `Timer`, `DispatchSourceTimer`, and `async/await`
* explain how `URLSession` behaves differently with delegate vs completion handlers
* diagram RunLoop sources vs GCD queues

-------------------------------------------------------------------------------------------------

If a CTA (button) is partially outside its superview, what happens when you tap the outside part?

Short answer: **the tap is ignored** by default.

Now the precise reasoning 👇

---

## The default rule (UIKit / AppKit mental model)

A view **can only receive touch events inside its superview’s bounds**.

So if a CTA (button) visually extends outside its superview:

* The **visible outside portion can be seen**
* But it is **not touchable**
* Touches in that outside area **never reach the button**

---

## Why this happens (hit-testing pipeline)

When you tap the screen, UIKit does this:

1. Start at the **window**
2. Call `hitTest(_:with:)`
3. Walk **down the view hierarchy**
4. At each level:

   * If the touch point is **outside a view’s bounds**
   * UIKit **stops descending into its subviews**

This is the key rule:

> **Subviews are clipped for hit-testing, even if they are not visually clipped.**

So even if:

```swift
superview.clipsToBounds = false
```

* Drawing can overflow
* **Hit-testing cannot**

---

## Concrete example

```
Superview bounds:  ┌──────────────┐
Button bounds:          ┌──────────────┐
                         ↑ outside superview
```

* Tap inside superview bounds → button receives touch
* Tap on button area **outside** superview bounds → ❌ ignored

---

## Important clarifications

### ❌ `clipsToBounds = false` does NOT help

* Affects **rendering only**
* Does **not** affect touch handling

### ❌ Increasing button’s frame doesn’t help

* The superview still rejects touches outside its own bounds

---

## How to make the outside area tappable (intentionally)

You have **three real options**:

### 1. Enlarge the superview’s bounds

Best if layout allows it.

---

### 2. Override hit-testing in the superview

```swift
override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return bounds.contains(point) || button.frame.contains(point)
}
```

This tells UIKit:

> “Yes, I want to accept touches even outside my bounds.”

---

### 3. Move the CTA up the view hierarchy

Put the button in a parent view that fully contains its tappable area.

This is the **cleanest** and most common solution.

---

## SwiftUI note (if relevant)

SwiftUI follows the same principle:

* Hit-testing is clipped to the view’s layout bounds
* Use `.contentShape()` or restructure the layout

---

## One-line takeaway

> **If part of a button lies outside its superview, that part looks tappable but is dead—UIKit never forwards touches outside a view’s bounds unless you override hit-testing or change the hierarchy.**

If you want, I can also explain:

* why Apple designed hit-testing this way
* how this differs in Android
* best practices for “floating” CTAs without breaking accessibility

