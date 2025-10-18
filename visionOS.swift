//
//  visionOS.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

## 🧠 What is **visionOS**?

### 🥽 **visionOS** is Apple’s operating system for their spatial computing device: **Apple Vision Pro**.

* It powers apps in **3D space**, allowing them to float around the user and react to their environment.
* Introduced in 2023 alongside **Apple Vision Pro**.
* Developers can build **immersive** and **mixed reality** (AR/VR) experiences using **SwiftUI**, **RealityKit**, and **ARKit**.

---

## 🧊 Key Concepts in visionOS

| Term                | Description                                                         |
| ------------------- | ------------------------------------------------------------------- |
| **Windows**         | Traditional 2D UI like on iPhone/iPad                               |
| **Volumes**         | 3D containers in the user’s space for spatial apps                  |
| **Immersive Space** | Full AR/VR environments that surround the user completely (VR-like) |
| **RealityKit**      | Apple’s 3D rendering engine used to display 3D content              |
| **ARKit**           | Apple’s AR framework for tracking real-world objects and space      |

---

## ⚙️ How to Implement AR/VR with visionOS

You can build 3 types of apps:

1. **Windowed App (2D)** – Traditional SwiftUI app
2. **Volume-based App (3D)** – Interactable 3D UI elements in space
3. **Immersive App (VR)** – Fully immersive environment

---

## 🔨 Getting Started with visionOS AR/VR

### ✅ Requirements:

* macOS Sonoma or later
* **Xcode 15+**
* visionOS SDK
* Apple Vision Pro (or Vision Pro Simulator)

---

### 🧰 Tools & Frameworks Used:

| Tool       | Purpose                               |
| ---------- | ------------------------------------- |
| SwiftUI    | UI Framework for visionOS             |
| RealityKit | Render 3D objects and animations      |
| ARKit      | Track real-world motion & environment |

---

## ✅ Example 1: Simple 3D Object in VisionOS (RealityKit + SwiftUI Volume)

### Step 1: Create a visionOS app in Xcode

1. File → New → Project → **App**
2. Select **visionOS** as the platform
3. Choose a **Volume-based App**

---

### Step 2: Add a 3D Model

You can drag `.usdz` or `.reality` files into the project, or use Reality Composer Pro to create 3D scenes.

---

### Step 3: Display the 3D Model in RealityView

```swift
import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        RealityView { content in
            if let scene = try? await Entity(named: "MyModel", in: realityKitContentBundle) {
                content.add(scene)
            }
        }
    }
}
```

> 🔍 `RealityView` is visionOS’s new view that renders 3D RealityKit scenes in SwiftUI.

---

## ✅ Example 2: Immersive VR-like Experience

1. Create a **Immersive Space** in your app
2. Use `ImmersiveView` to present full-screen AR/VR

```swift
import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Add environment lighting, 3D objects, or effects
            let floor = ModelEntity(mesh: .generatePlane(width: 2, depth: 2), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            content.add(floor)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
```

Present it with:

```swift
@Environment(\.openImmersiveSpace) var openImmersiveSpace

Button("Enter VR Space") {
    Task {
        await openImmersiveSpace(id: "MainImmersive")
    }
}
```

In `@main`:

```swift
@main
struct VisionApp: App {
    var body: some Scene {
        ImmersiveSpace(id: "MainImmersive") {
            ImmersiveView()
        }
    }
}
```

---

## ✅ Example 3: AR Integration (Using ARKit)

You can integrate **ARKit** for:

* Hand/face tracking
* Plane detection
* Scene understanding

Example: Using ARKit hand tracking (Vision Pro supports it!)

```swift
import ARKit

let handTrackingConfig = ARBodyTrackingConfiguration()
// Add to ARSession if needed (advanced use case)
```

---

## 🧠 When to Use Each App Type

| App Type      | Best For                                       |
| ------------- | ---------------------------------------------- |
| **Window**    | 2D interface, productivity apps                |
| **Volume**    | Apps needing 3D presence (media viewers, maps) |
| **Immersive** | Full VR-like environments (games, simulations) |

---

## 🧪 Testing Without a Vision Pro Device

* Use **Vision Pro Simulator** in Xcode
* Supports volumes, immersive spaces, and device gestures
* Use keyboard/mouse/trackpad to simulate hand tracking and focus

---

## 🔗 Useful Resources

* [Apple’s visionOS Documentation](https://developer.apple.com/visionos/)
* [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
* [WWDC23: Meet visionOS](https://developer.apple.com/videos/play/wwdc2023/10072/)

---

## ✅ Summary

| Feature             | How to Implement                           |
| ------------------- | ------------------------------------------ |
| 3D UI in space      | Use **Volumes** + `RealityView`            |
| VR-like environment | Use **Immersive Space**                    |
| AR features         | Use **ARKit** (hand, face, plane tracking) |
| 3D Models           | Use `.usdz`, Reality Composer Pro          |
| Offline + VisionOS  | Combine with local file caching, etc.      |

---



Absolutely! Here's a **step-by-step guide** to creating a **starter visionOS project** with:

* A **3D object** in a spatial Volume
* An **immersive space** that fills the user's view (VR-style)
* **RealityView** with a basic 3D scene

---

## 🧱 PROJECT STRUCTURE OVERVIEW

We’ll create:

1. A **Volume-based app** (3D window in real-world space)
2. An **Immersive space** that surrounds the user (like VR)
3. Load a **3D model** into RealityKit using `RealityView`

---

## ✅ Step 1: Create a visionOS App in Xcode

1. Open **Xcode 15 or newer**
2. Go to **File > New > Project**
3. Select **App**
4. Choose **visionOS** platform
5. Name it something like `VisionStarter`
6. Choose **SwiftUI** as the interface
7. Leave "Use Core Data" and "Tests" unchecked

> After creation, Xcode scaffolds a basic Volume-based visionOS app.

---

## ✅ Step 2: Add a 3D Model

We’ll use a `.usdz` file (Apple’s 3D format).

1. Download or create a `.usdz` file (e.g. from [https://developer.apple.com/augmented-reality/tools/](https://developer.apple.com/augmented-reality/tools/))
2. Drag the file into the `RealityKitContent` folder in your project
3. Make sure it’s included in the target `RealityKitContent`

---

## ✅ Step 3: Show the 3D Object in `RealityView`

In `ContentView.swift`, replace the code with:

```swift
import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    var body: some View {
        RealityView { content in
            do {
                // Load model from RealityKitContent bundle
                let model = try await Entity(named: "toy_biplane", in: realityKitContentBundle)
                content.add(model)
            } catch {
                print("Failed to load model: \(error)")
            }
        }
        .frame(width: 1.0, height: 1.0, depth: 1.0) // 1 meter cube
    }
}
```

> This will place the `toy_biplane.usdz` model in the center of your 3D volume.

---

## ✅ Step 4: Add an Immersive Space

In `VisionStarterApp.swift`, update your scene to include an `ImmersiveSpace`.

```swift
@main
struct VisionStarterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveScene") {
            ImmersiveView()
        }
    }
}
```

Create a new SwiftUI file: `ImmersiveView.swift`

```swift
import SwiftUI
import RealityKit

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            let ground = ModelEntity(mesh: .generatePlane(width: 2, depth: 2),
                                     materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            ground.position.y = -1 // below user

            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.1),
                                     materials: [SimpleMaterial(color: .red, isMetallic: true)])
            sphere.position = [0, 0, -1] // in front of user

            content.add(ground)
            content.add(sphere)
        }
    }
}
```

---

## ✅ Step 5: Add a Button to Enter the Immersive Space

In `ContentView.swift`, add a button to trigger immersive mode:

```swift
@Environment(\.openImmersiveSpace) private var openImmersiveSpace

var body: some View {
    VStack {
        RealityView { content in
            // same model loading code as before
        }
        .frame(width: 1.0, height: 1.0, depth: 1.0)

        Button("Enter Immersive Space") {
            Task {
                await openImmersiveSpace(id: "ImmersiveScene")
            }
        }
    }
}
```

> Now you have both a **Volume** and a **VR-style Immersive Scene** working together.

---

## ✅ Optional: Exit Immersive Mode

You can also inject a button into `ImmersiveView.swift` to close the immersive space:

```swift
@Environment(\.dismissImmersiveSpace) private var dismiss

Button("Exit") {
    Task {
        await dismiss()
    }
}
```

---

## 🧪 Testing It

1. Build and run using **Vision Pro Simulator**
2. Use **keyboard + mouse** to simulate hand movement
3. Use `Cmd + Click` and drag to rotate view in immersive mode

---

## 🔗 Resources

* [Apple's visionOS Developer Site](https://developer.apple.com/visionos/)
* [RealityKit Documentation](https://developer.apple.com/documentation/realitykit)
* [USDZ Sample Models](https://developer.apple.com/augmented-reality/quick-look/)

---
