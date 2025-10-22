//
//  UIKit.swift
//  
//
//  Created by Apple on 22/10/25.
//

import Foundation

Great — you’re asking highly relevant questions that come up often in **iOS technical interviews**, especially for developers working with **Objective-C** and **UIKit**. Here’s a clear and concise explanation of each.

---

### **1. What is the responder chain in UIKit? How does event handling work in iOS?**

The **responder chain** is a hierarchy of objects that can respond to events (like touches, gestures, or actions).

**Event handling flow:**

* A touch begins on the screen.
* UIKit identifies the hit `UIView` (via hit-testing).
* That view becomes the **first responder**.
* If the view can't handle the event, it passes it up the **responder chain**:

  * View → View Controller → Window → App Delegate

You can override methods like:

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
```

UIKit also uses gesture recognizers (`UIGestureRecognizer`) as a higher-level abstraction for handling taps, swipes, etc.

---

### **2. What’s the difference between `UIView` and `CALayer`?**

| Feature        | `UIView`                      | `CALayer`                  |
| -------------- | ----------------------------- | -------------------------- |
| Role           | Manages layout, events        | Handles rendering only     |
| Event Handling | Yes (touches, gestures)       | No event handling          |
| Hierarchy      | UIKit view hierarchy          | Backing layer for views    |
| Animation      | High-level (`UIView.animate`) | Low-level (Core Animation) |
| Coordinates    | UIKit coordinates             | Core Animation coordinates |

Each `UIView` has an associated `CALayer` (via `view.layer`). For custom rendering or performance optimizations, developers work directly with `CALayer`.

---

### **3. What are the lifecycle methods of a `UIViewController`?**

Here’s the typical order of execution:

1. `initWithCoder:` or `initWithNibName:bundle:` — Controller is initialized
2. `loadView` — Creates view manually (override to create views programmatically)
3. `viewDidLoad` — Called after view is loaded
4. `viewWillAppear:` — Just before view appears
5. `viewDidAppear:` — View is now visible
6. `viewWillDisappear:` — Just before it's hidden
7. `viewDidDisappear:` — After it disappears
8. `dealloc` — Cleanup (if not using ARC)

---

### **4. What’s the difference between `frame`, `bounds`, and `center`?**

| Property | Description                                                       |
| -------- | ----------------------------------------------------------------- |
| `frame`  | The view's size and position in **superview's coordinate system** |
| `bounds` | The view's size and position in **its own coordinate system**     |
| `center` | The center point of the view in **superview's coordinate system** |

**Example:**

```objc
CGRect frame = view.frame;
CGRect bounds = view.bounds;
CGPoint center = view.center;
```

If you rotate or scale a view, the `bounds` may change without affecting the `frame` as expected.

---

### **5. How does dynamic typing vs static typing impact Objective-C code safety?**

* **Dynamic typing (`id`, `NSObject*`)**:

  * Type is resolved at **runtime**
  * Allows flexibility but no compile-time checks
  * Risk of **runtime crashes** due to unrecognized selectors

* **Static typing (`MyClass*`)**:

  * Type is checked at **compile time**
  * Safer and more performant
  * Helps with **code completion and errors detection**

**Trade-off:**
Dynamic typing enables powerful runtime features (like `performSelector:`), but **reduces safety**.

---

### **6. What is Key-Value Coding (KVC) and Key-Value Observing (KVO)?**

* **KVC** allows access to object properties using string keys:

```objc
NSString *name = [person valueForKey:@"name"];
[person setValue:@"John" forKey:@"name"];
```

* **KVO** lets you observe changes to property values:

```objc
[object addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    // Handle change
}
```

**Used in:** Reactive programming, bindings, model-view syncing.

---

### **7. What is the `isa` pointer and how does the Objective-C runtime use it?**

* Every Objective-C object has a hidden `isa` pointer that points to its **class object**.
* Enables **dynamic dispatch**: when `[obj doSomething]` is called, the runtime looks up the method in the class via `isa`.
* Supports:

  * Method resolution
  * Inheritance
  * Message forwarding
  * Runtime introspection

**Modern Objective-C** uses “isa-swizzling” for performance, where the `isa` pointer may point to a structure with flags (e.g. tagged pointers).

---

### **8. How does the Objective-C runtime resolve unknown selectors (`forwardingTargetForSelector`, `methodSignatureForSelector`)**

When an object receives a message it doesn’t recognize:

1. **`+resolveInstanceMethod:`** → Add method dynamically.
2. **`-forwardingTargetForSelector:`** → Forward to another object.
3. **`-methodSignatureForSelector:`** → Provide method signature.
4. **`-forwardInvocation:`** → Final chance to handle the call manually.

```objc
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(doSomething)) {
        return self.delegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}
```

Used in:

* Message forwarding
* Proxies
* Method swizzling

---

### **9. How do blocks work in Objective-C? How do they capture variables (strongly/weakly)?**

* Blocks are **closures** — chunks of code that can capture variables.

```objc
int count = 5;
void (^block)(void) = ^{
    NSLog(@"Count: %d", count);
};
```

* By default, variables are **captured by value**.
* To capture mutable state:

```objc
__block int counter = 0;
```

* When capturing `self` (e.g., in async code), use `__weak` to avoid **retain cycles**:

```objc
__weak typeof(self) weakSelf = self;
dispatch_async(queue, ^{
    [weakSelf doSomething];
});
```

---

### **10. Explain how to create a singleton in Objective-C.**

Thread-safe singleton:

```objc
+ (instancetype)sharedInstance {
    static MyClass *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}
```

Key points:

* Uses `dispatch_once` for thread safety
* Ensures only **one instance** is ever created
* Often used for managers (network, config, analytics)

---

### **11. How do you implement infinite scrolling in a `UITableView`?**

Detect when the user scrolls near the bottom, then load more data.

```objc
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat threshold = contentHeight - scrollView.bounds.size.height - 100;
    
    if (offsetY > threshold && !isLoadingMoreData) {
        [self loadMoreData];
    }
}
```

Tips:

* Use a flag (`isLoadingMoreData`) to prevent multiple requests
* Add a loading spinner at the bottom (e.g., `tableFooterView`)
* Update data source and call `reloadData` or `insertRowsAtIndexPaths`

---

Great question — understanding the **AppDelegate** lifecycle and the **SceneDelegate** setup is critical, especially in modern iOS development (iOS 13+). Let's break this down clearly:

---

## 🧩 **AppDelegate Lifecycle (Pre and Post iOS 13)**

### ✅ **Before iOS 13 (iOS 12 and below)**

The `AppDelegate` was responsible for **everything** related to the app's lifecycle — window management, transitions, notifications, background tasks, etc.

Key methods:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidEnterBackground:(UIApplication *)application;
- (void)applicationWillEnterForeground:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;
- (void)applicationWillTerminate:(UIApplication *)application;
```

---

### ✅ **From iOS 13+ — AppDelegate + SceneDelegate (Multi-scene support)**

Starting in **iOS 13**, Apple introduced **multi-window (scene-based)** architecture with `UISceneDelegate`, especially for iPadOS. This changed how lifecycle events are handled.

Now:

* **`AppDelegate` handles app-level events**
* **`SceneDelegate` handles window/UI-level events**

#### 🧱 AppDelegate.swift/.m handles:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)applicationWillTerminate:(UIApplication *)application;
```

#### 🪟 SceneDelegate.swift/.m handles:

```objc
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions;
- (void)sceneDidBecomeActive:(UIScene *)scene;
- (void)sceneWillResignActive:(UIScene *)scene;
- (void)sceneWillEnterForeground:(UIScene *)scene;
- (void)sceneDidEnterBackground:(UIScene *)scene;
```

---

## 🖼 Scene Lifecycle: What is a Scene?

* A **Scene** is a single instance of your app’s **UI** — like a window on macOS.
* iPad users can open **multiple windows** of the same app (like Safari).
* Each scene has its **own lifecycle**, managed by `SceneDelegate`.

---

## 🔁 iOS Lifecycle Flow (Post-iOS 13 with Scene)

```text
App Launch:
    AppDelegate.application(_:didFinishLaunchingWithOptions:) → App initializes
    ↓
    SceneDelegate.scene(_:willConnectTo:options:) → UI setup (create UIWindow, rootViewController)

Foregrounding:
    sceneWillEnterForeground:
    sceneDidBecomeActive:

Backgrounding:
    sceneWillResignActive:
    sceneDidEnterBackground:

Termination:
    AppDelegate.applicationWillTerminate:
```

---

## 🪟 UIWindow Setup (iOS 13+)

Since AppDelegate no longer sets up the window, this happens in `SceneDelegate`:

```objc
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[YourRootVC alloc] init];
    [self.window makeKeyAndVisible];
}
```

---

## 📝 If You're Supporting iOS 12 and Below

You’ll need to:

* Put `UIWindow` setup in **AppDelegate**
* Avoid `SceneDelegate` completely
* Use `@available(iOS 13.0, *)` guards if needed

---

## 🔧 To Enable/Disable SceneDelegate

If you want to **disable scenes** and go back to AppDelegate-only lifecycle (e.g., for simplicity):

### 1. In **Info.plist**:

Remove the `Application Scene Manifest` key.

### 2. In **AppDelegate**:

Set up window like pre-iOS 13:

```objc
self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
self.window.rootViewController = [[YourVC alloc] init];
[self.window makeKeyAndVisible];
```

---

## ✅ Summary Table

| Responsibility        | AppDelegate | SceneDelegate |
| --------------------- | ----------- | ------------- |
| App launch            | ✅           |               |
| Notifications         | ✅           |               |
| Background tasks      | ✅           |               |
| UI setup (`UIWindow`) | ❌ (iOS 13+) | ✅ (iOS 13+)   |
| Scene lifecycle       | ❌           | ✅             |
| Multi-window (iPad)   | ❌           | ✅             |

---

## 🧪 Interview Tip

**Question:** *“How do you support both iOS 12 and iOS 13+ lifecycle in the same app?”*
**Answer:** Use conditional logic and availability checks:

```objc
if (@available(iOS 13.0, *)) {
    // Use SceneDelegate
} else {
    // Setup UIWindow in AppDelegate
}
```

---
