//
//  Liquid Glass.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Ah! You’re asking about **Liquid Glass** in iOS, which is usually referring to a **frosted glass / blur effect** often seen in Apple’s UI design. In SwiftUI, it’s commonly implemented using **`VisualEffectBlur`** or the newer **`Material`** system. Let me break it down properly.

---

## 1. What “Liquid Glass” Really Means

* Apple doesn’t officially call it “Liquid Glass,” but in design terms, it’s a **semi-transparent, frosted effect** that blurs whatever is behind it while keeping a glossy, smooth look.
* In UIKit, it was done using `UIVisualEffectView` with `UIBlurEffect`.
* In SwiftUI, Apple introduced `Material` (iOS 15+) to easily achieve this effect.

---

## 2. SwiftUI Implementation

### Using `Material` (Recommended, iOS 15+)

```swift
import SwiftUI

struct LiquidGlassView: View {
    var body: some View {
        ZStack {
            Image("background") // Any background image
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Text("Hello, Liquid Glass!")
                    .font(.largeTitle)
                    .padding()
            }
            .frame(width: 300, height: 200)
            .background(.ultraThinMaterial) // <-- Liquid Glass effect
            .cornerRadius(25)
            .shadow(radius: 10)
        }
    }
}
```

**Explanation:**

* `.ultraThinMaterial`, `.thinMaterial`, `.regularMaterial` etc., control the blur intensity.
* Works with any shape or container.
* Automatically adapts to **light/dark mode**.

---

### Using `VisualEffectBlur` (iOS 13+)

If you want more control on older versions:

```swift
import SwiftUI
import UIKit

struct VisualEffectBlur<Content: View>: UIViewRepresentable {
    var effect: UIBlurEffect.Style
    let content: () -> Content

    init(_ effect: UIBlurEffect.Style = .systemMaterial, @ViewBuilder content: @escaping () -> Content) {
        self.effect = effect
        self.content = content
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        let hosting = UIHostingController(rootView: content())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.contentView.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.contentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor),
        ])
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
```

Usage:

```swift
VisualEffectBlur(.systemUltraThinMaterial) {
    Text("Liquid Glass!")
        .padding()
}
.frame(width: 300, height: 200)
.cornerRadius(20)
```

---

✅ **Key Points:**

* `Material` is simpler and adapts automatically to light/dark mode.
* Use `.background(.ultraThinMaterial)` on containers for the liquid glass look.
* Combine with `.cornerRadius()` and `.shadow()` for a polished glass effect.

---

If you want, I can also show a **fully animated “Liquid Glass” effect** that **changes dynamically with content behind it**, which looks super fancy in SwiftUI.

Do you want me to do that?

Perfect! Let’s create a **dynamic, animated Liquid Glass effect** in SwiftUI. This version will react to **movement or changes behind it** and feel more “alive,” like real glass.
                                                            
---
                                                            
## 1. Animated Liquid Glass in SwiftUI
                                                            
```swift
import SwiftUI
                                                            
struct AnimatedLiquidGlassView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [.purple, .blue, .pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .blur(radius: animate ? 30 : 60) // subtle animation on background
            
            // Liquid Glass Card
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial) // Liquid Glass effect
                .frame(width: 300, height: 200)
                .overlay(
                    VStack {
                        Text("Dynamic Liquid Glass")
                            .font(.title)
                            .bold()
                        Text("SwiftUI animation")
                            .font(.subheadline)
                    }
                        .foregroundColor(.white)
                        .padding()
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .scaleEffect(animate ? 1.05 : 1.0) // gentle scaling animation
                .rotationEffect(.degrees(animate ? 2 : -2)) // slight rotation
                .animation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: animate
                )
                .onAppear {
                    animate = true
                }
        }
    }
}

struct AnimatedLiquidGlassView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedLiquidGlassView()
    }
}
```

---

### 2. What Makes This “Liquid”

1. **Material**: `.ultraThinMaterial` gives the frosted glass look.
2. **Animation**: Subtle scaling and rotation make it feel fluid.
3. **Dynamic background blur**: The blurred background can change or animate, enhancing the liquid effect.
4. **Shadow & rounded corners**: Adds depth and realism.

---

### 3. Extra Tips for a Realistic Effect
                        
* Combine multiple layers of `.ultraThinMaterial` with **varying opacity**.
* Add a **slight moving gradient behind** the card for extra fluidity.
* Use `mask` with shapes to simulate the glass **stretching or warping**.

