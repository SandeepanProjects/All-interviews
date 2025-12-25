//
//  App crashes.swift
//  
//
//  Created by Apple on 25/12/25.
//

import Foundation

Got it — I’ll **explain each scenario in detail**, step by step, like you’re actually debugging it in real life. I’ll slow it down, explain *why* each step matters, and what signals you’re looking for.

---

# 1️⃣ App crashes **only in production**

### What this usually means

If it works in development but crashes in production, the **code is probably fine**, but:

* The **environment is different**
* The **data is messier**
* The **build behaves differently**

---

## Step 1: Look at crash reports (MOST IMPORTANT)

You **never guess first**.

You open:

* Firebase Crashlytics
* Sentry
* Play Console / App Store crashes

You look for:

* **Stack trace** → exact line where it crashed
* **Crash frequency** → one user or many?
* **Devices / OS versions**
* **App version**

📌 If many users crash at the same line → real bug
📌 If only one device → device-specific issue

---

## Step 2: Compare prod vs dev

Ask: *“What is different?”*

Common differences:

* Production API returns **null or missing fields**
* Feature flags enabled only in prod
* Environment variables missing
* Release build optimizations (minification, obfuscation)

Example:

```text
Dev API: user.name always exists
Prod API: user.name = null → app crashes
```

---

## Step 3: Reproduce using a RELEASE build

Debug builds hide problems.

You:

* Build the app in **release mode**
* Disable debugger
* Use real production-like data

Why?

* Release mode changes:

  * Thread timing
  * Memory behavior
  * Error handling

---

## Step 4: Common real-world crash causes

You specifically check for:

* Null values
* Index out of bounds
* Race conditions
* Missing permissions
* Background task limits

📌 Production users behave differently than testers.

---

## Step 5: Add logging + hotfix

If the crash is rare:

* Add logs **before the crash**
* Release a small patch
* Watch logs → confirm fix

---

### Final mindset

> **Production crashes = data + scale + release behavior**

---

# 2️⃣ Users report **slow app launch**

### What “slow launch” really means

The app takes too long before the user sees *anything*.

There are **three launch types**:

* **Cold start** → app not in memory (worst case)
* **Warm start** → app cached
* **Hot start** → app already running

You focus on **cold start first**.

---

## Step 1: Measure startup time

You don’t rely on “feels slow”.

You measure:

* Time to first frame
* Time to usable UI

Tools:

* Android Startup Profiler
* iOS Instruments

---

## Step 2: Find what runs on launch

You inspect:

* App initialization code
* `onCreate`, `AppDelegate`, root component

Look for:

* API calls
* Database setup
* SDK initialization
* JSON parsing
* Disk access

🚨 Anything blocking the **main thread** is bad.

---

## Step 3: Assets & UI

Check:

* Large images
* Fonts loaded synchronously
* Heavy animations
* Too many plugins starting immediately

---

## Step 4: Fix strategy

You **delay non-critical work**:

* Show UI first
* Load data after
* Lazy-load features
* Move work to background threads

📌 User perception matters more than actual speed.

---

### Golden rule

> **Fast first frame > fast data**

---

# 3️⃣ Memory spike after scrolling

### What this tells you immediately

Scrolling creates objects.
If memory never goes down → **memory leak**.

---

## Step 1: Reproduce with profiler

You:

1. Open memory profiler
2. Scroll a long list
3. Stop scrolling
4. Scroll again

Expected:

```
Memory ↑ while scrolling
Memory ↓ when scrolling stops
```

If memory only goes up → leak.

---

## Step 2: Focus on lists

Most leaks come from:

* RecyclerView / FlatList / UITableView

You check:

* Are views recycled?
* Are images released?
* Are adapters holding references?

---

## Step 3: Common causes

You look for:

* Image bitmaps not cleared
* Event listeners not removed
* Observers still active
* Closures capturing screen/context

Example:

```text
Screen destroyed
→ Listener still active
→ Screen never freed
```

---

## Step 4: Force garbage collection / memory warnings

You simulate:

* Leaving the screen
* Backgrounding app

If memory doesn’t drop → something is retained.

---

## Step 5: Inspect retained objects

Profiler shows:

* Which objects remain
* Who is holding references

You fix:

* Clear listeners
* Null references
* Use weak references

---

### Memory debugging rule

> **If memory grows but never shrinks, something is leaking**

---

# 4️⃣ App freezes randomly

### Freeze ≠ crash

The app:

* Stops responding
* UI doesn’t update
* No crash log

This means:
👉 **Main/UI thread is blocked**

---

## Step 1: Confirm freeze type

* Android → ANR
* iOS → watchdog timeout

---

## Step 2: Profile during a freeze

You record:

* CPU usage
* Thread activity

You look at:

* Main thread timeline
* Long tasks

---

## Step 3: Usual freeze causes

You almost always find:

* Large loops
* Synchronous API calls
* Heavy JSON parsing
* Disk reads/writes
* Waiting on locks

🚨 Any of these on the UI thread will freeze the app.

---

## Step 4: Add timing logs

You log:

```text
Start task A
End task A
```

If task A takes 2–3 seconds → found the problem.

---

## Step 5: Fix the freeze

You:

* Move work to background threads
* Split large tasks into chunks
* Show loading indicators

---

### UI rule

> **Main thread = UI only, nothing else**

---

# How this sounds in interviews (important)

Interviewers want:

* Clear thinking
* Tools knowledge
* User-first mindset
* No random guessing

If you say:

> “I check crash reports, reproduce in release mode, compare environments, and use profilers to confirm the root cause”

You sound **very strong**.

---

If you want next:

* 🎯 **One perfect interview answer per question**
* 📱 Platform-specific (Android / iOS / React Native)
* 🧠 Real bugs + real fixes examples

Tell me what you want next.


Great questions. These are **classic real-world app problems**, and interviewers love how you *think* through them. I’ll give you a clear, practical approach for each—platform-agnostic, but I’ll note mobile/web specifics where helpful.

---

## 1️⃣ App crashes **only in production** — how do you debug?

**Mindset:** Production is different → configs, data, scale, permissions.

**Steps:**

1. **Check crash reports first**

   * Use Crashlytics / Sentry / App Store / Play Console
   * Look for:

     * Stack traces
     * OS/device versions
     * Frequency + common path

2. **Compare prod vs dev**

   * API endpoints
   * Feature flags
   * Environment variables
   * Build optimizations (minification, ProGuard, release mode)

3. **Reproduce locally (if possible)**

   * Use a **release build**, not debug
   * Test with real prod data (sanitized)

4. **Look for common culprits**

   * Null values from real users
   * Race conditions
   * Missing permissions
   * Strict OS behavior (background limits, memory pressure)

5. **Add targeted logging**

   * Log *before* the crash point
   * Ship a small hotfix if needed

👉 **Key insight:** If it only crashes in prod, assume **data + scale + release build differences**.

---

## 2️⃣ Users report **slow launch time** — what do you check?

**Goal:** Find what blocks the *first frame*.

**Checklist:**

1. **Measure startup**

   * Cold start vs warm start
   * Time to first render

2. **Look for work on app launch**

   * Heavy API calls
   * Database initialization
   * Large JSON parsing
   * Blocking I/O on main thread

3. **Check assets**

   * Big images
   * Fonts loading synchronously
   * Too many plugins initialized early

4. **Profile**

   * Android: Startup Profiler
   * iOS: Instruments → Time Profiler

5. **Fix**

   * Lazy-load non-critical work
   * Defer network calls
   * Show UI *first*, load data after

👉 **Rule:** Launch fast, load later.

---

## 3️⃣ Memory spike after scrolling — how do you investigate?

**This screams “leak or over-allocation.”**

**Steps:**

1. **Use memory profiler**

   * Scroll → stop → scroll again
   * Memory should go *up then down*

2. **Common causes**

   * Images not being released
   * Views/components not recycled
   * Event listeners not removed
   * Closures capturing context

3. **Check lists specifically**

   * RecyclerView / ListView / FlatList / UITableView
   * Are items reused?
   * Are images cached correctly?

4. **Force GC / memory warnings**

   * Does memory drop? If not → leak

5. **Inspect retained objects**

   * What’s still in memory after leaving the screen?

👉 **Tell-tale sign:** Memory only goes up → something isn’t being freed.

---

## 4️⃣ App freezes randomly — what’s your approach?

**Freeze = main thread blocked.**

**Approach:**

1. **Confirm it’s not a crash**

   * ANR (Android) / watchdog timeout (iOS)

2. **Reproduce with profiling**

   * Record during a freeze
   * Look at main thread activity

3. **Common blockers**

   * Long loops
   * Synchronous network calls
   * Large JSON parsing
   * Disk access on main thread

4. **Add timing logs**

   * Log start/end of suspicious operations
   * Find what takes “too long”

5. **Fix**

   * Move work off main thread
   * Break big tasks into chunks
   * Add loading states

👉 **Simple rule:** UI thread should only handle UI.

---

## How interviewers judge these answers

They’re listening for:

* ✅ **Systematic thinking**
* ✅ **Use of tools**
* ✅ **Understanding of real users**
* ❌ Not guessing randomly
* ❌ Not jumping straight to “rewrite it”

---
