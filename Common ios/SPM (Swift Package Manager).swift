//
//  SPM (Swift Package Manager).swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

# 🎉 Need help creating a real Swift package?

If you want, I can help you:

* Write a working `Package.swift`
* Add resources or bundle assets
* Configure CI/CD for releases
* Prepare a template GitHub repository

Just tell me what type of package you want to build!


Great — here is a **complete, end-to-end guide** that covers *all* parts of the Swift Package Manager workflow:

✔ What SPM is
✔ How to **create** a Swift package
✔ How to **structure** it properly
✔ How to **add dependencies**
✔ How to **add resources (images, JSON, nibs, fonts)**
✔ How to **test** it
✔ How to **version** it
✔ How to **host & distribute** it (GitHub, private Git, local)
✔ How to **integrate it into an iOS app**
✔ How to **publish releases**
✔ How to **set up CI automation**
✔ Advanced tips & best practices

Everything is included below.

---

# 🚀 1. What SPM Is (Swift Package Manager)

**SPM** is Apple’s official tool for building, managing, and distributing Swift code.
It lets you create reusable libraries that can be imported into iOS, macOS, watchOS, tvOS, and Linux.

---

# 🧱 2. Create a New Swift Package

## Option A — Using Terminal (recommended)

```bash
swift package init --name MyLibrary --type library
```

## Option B — Using Xcode

* File → New → Package
* Enter name
* Choose location

This generates:

```
Package.swift
Sources/
    MyLibrary/
        MyLibrary.swift
Tests/
    MyLibraryTests/
```

---

# ⚙️ 3. Understanding `Package.swift`

This file *defines everything* about your package:

* platforms supported
* libraries provided
* external dependencies
* targets
* resources

Example full manifest:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyLibrary",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MyLibrary",
            targets: ["MyLibrary"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    targets: [
        .target(
            name: "MyLibrary",
            dependencies: ["Alamofire"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MyLibraryTests",
            dependencies: ["MyLibrary"]
        )
    ]
)
```

---

# 🧩 4. Add Your Source Code

Put your Swift files in:

```
Sources/MyLibrary/
```

Example:

```swift
public struct Greeting {
    public init() {}
    public func hello() -> String {
        "Hello from MyLibrary!"
    }
}
```

> **Note:** Everything you want to expose must be marked `public`.

---

# 🖼 5. Add Resources (images, JSON, fonts, nibs)

Create:

```
Sources/MyLibrary/Resources/
```

Example manifest:

```swift
resources: [
    .process("Resources")
]
```

Access resources:

```swift
let url = Bundle.module.url(forResource: "config", withExtension: "json")
```

---

# 🧪 6. Add Unit Tests

Tests go under:

```
Tests/MyLibraryTests/
```

Example:

```swift
import XCTest
@testable import MyLibrary

final class MyLibraryTests: XCTestCase {
    func testHello() {
        XCTAssertEqual(Greeting().hello(), "Hello from MyLibrary!")
    }
}
```

Run tests:

```bash
swift test
```

---

# 🔗 7. Add Dependencies to Your Package

Modify the `dependencies` section:

```swift
dependencies: [
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
]
```

Then include it in your target:

```swift
.target(
    name: "MyLibrary",
    dependencies: ["Kingfisher"]
)
```

---

# 🚀 8. Create Versions (Required for distribution)

SPM uses **semantic versioning**:

```
major.minor.patch  → 1.0.0
```

Create a **Git tag**:

```bash
git tag 1.0.0
git push --tags
```

---

# 🌍 9. Distribute the Package

You can distribute via:

---

## **Option A — GitHub (most common)**

1. Push your package to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourname/MyLibrary.git
git push -u origin main
```

2. Add a **version tag**
3. Create a **GitHub Release**

---

## **Option B — Private Git Repository**

SPM works with any Git URL:

* GitLab
* Bitbucket
* Self-hosted Git
* Git over SSH

Example URL for Xcode:

```
git@git.company.com:ios/MyLibrary.git
```

---

## **Option C — Local Package (Internal)**

Drag the package folder into your iOS project
OR
Xcode → Add Package → Add Local…

---

# 📥 10. Using Your Package in an iOS App

In Xcode:

**File → Add Packages**

Enter your repo URL:

```
https://github.com/yourname/MyLibrary.git
```

Select version rule:

* Up to next major
* Exact
* Branch
* Commit

Then import it:

```swift
import MyLibrary
```

---

# 🤖 11. Automate Releases (CI/CD Optional)

### GitHub Actions example:

```yaml
name: Swift Build & Test

on:
  push:
    tags:
      - '*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

---

# 🧠 12. Best Practices

✔ Use semantic versioning strictly
✔ Keep public API small and stable
✔ Keep dependencies minimal
✔ Provide documentation (`.docc`)
✔ Add examples in `Examples/` folder
✔ Use CI to ensure builds stay clean
✔ Tag every release

---

# 🎁 Want a fully generated template?

I can generate a complete ready-to-upload Swift package including:

* Folder structure
* Complete `Package.swift`
* Documentation
* Example project
* Resources folder
* Public APIs
* GitHub Action workflows
* License file
* README.md

Just tell me:

### **What will your package do?**

(e.g., UI components, utilities, networking wrapper, etc.)

And I’ll build the full package for you.




Below is a clear explanation of **SPM (Swift Package Manager)** in iOS, plus **how to create**, **configure**, and **distribute** your own Swift package.

---

# ✅ **What Is SPM in iOS?**

**Swift Package Manager (SPM)** is Apple’s official tool for:

* Managing dependencies (libraries/frameworks)
* Sharing code modules
* Versioning reusable components
* Building Swift projects

It is integrated into **Xcode**, so you can add packages without external tools like CocoaPods or Carthage.

---

# 📦 **How to Create a Swift Package**

### **1. Create a New Swift Package**

In Terminal:

```bash
swift package init --name MyLibrary --type library
```

Or in Xcode:

* **File → New → Package**
* Enter a name
* Choose location

This creates files like:

```
Package.swift          ← manifest
Sources/
    MyLibrary/
        MyLibrary.swift
Tests/
    MyLibraryTests/
```

---

# 🛠️ **2. Edit `Package.swift` (Manifest)**

This file defines the package, its products, dependencies, and targets.

Example:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyLibrary",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "MyLibrary",
            targets: ["MyLibrary"]),
    ],
    dependencies: [
        // Example: add external packages
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0")
    ],
    targets: [
        .target(name: "MyLibrary"),
        .testTarget(name: "MyLibraryTests", dependencies: ["MyLibrary"])
    ]
)
```

---

# 🧪 **3. Add Your Source Code**

Place Swift files inside:

```
Sources/MyLibrary/
```

Example:

```swift
public struct Greeting {
    public static func hello() -> String {
        "Hello from package!"
    }
}
```

Note: **Use `public`** so other apps can access the code.

---

# 🧪 **4. Test Your Package**

Run from Terminal:

```bash
swift test
```

Or in Xcode, simply use the Test navigator.

---

# 🌐 **How to Distribute a Swift Package**

You have **3 main options**:

---

# **Option 1 — Distribute via GitHub (Most Common)**

### **Steps**

1. Create a GitHub repo
2. Push your package to GitHub:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourname/MyLibrary.git
git push -u origin main
```

3. Create a release tag
   In GitHub → **Releases → Create new release**

Tag example:

```
1.0.0
```

SPM requires **semantic version tags**.

---

# **Option 2 — Host Privately (Git, GitLab, Bitbucket)**

SPM supports **any Git repository**, private or public.

Xcode can authenticate using SSH keys, personal access tokens, etc.

---

# **Option 3 — Local Distribution (Internal)**

You can include a package locally by selecting:

**Xcode → Add Package → Add Local…**

---

# 📥 **How Apps Install Your Package**

In Xcode:

1. **File → Add Packages**
2. Enter the Git URL:

```
https://github.com/yourname/MyLibrary.git
```

3. Choose version rule

   * **Up to Next Major** (recommended)
   * **Exact**
   * **Branch**
   * **Commit**

4. Add the library to the target

Done!

---

# 📚 **Extra Tips**

### **Use semantic versioning:**

* `1.0.0` for first stable release
* update minor/patch numbers as needed

### **To distribute resources (images, storyboards, JSON, etc.)**

Add the `resources` parameter in target:

```swift
.target(
    name: "MyLibrary",
    resources: [
        .process("Resources")
    ]
)
```

### **To support multiple platforms:**

```swift
platforms: [
    .iOS(.v13),
    .macOS(.v11),
]
```

---
