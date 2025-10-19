//
//  Accessibility.swift
//  
//
//  Created by Apple on 20/10/25.
//

import Foundation

### What is Accessibility?

**Accessibility** in app development means designing your app so that everyone, including people with disabilities, can use it effectively. This can include people with:

* Visual impairments (blindness, low vision)
* Hearing impairments
* Motor impairments
* Cognitive disabilities

iOS provides built-in support for accessibility features like VoiceOver, Dynamic Type, and more. As a developer, you want to make sure your app content is readable and navigable using these assistive technologies.

---

### Accessibility in SwiftUI

SwiftUI makes accessibility easier because many controls come with default accessibility support. But you often want to customize or add additional information.

Here are some common accessibility features you might want to add:

* **Labels:** Descriptions for UI elements
* **Hints:** Additional instructions
* **Traits:** Describe the element’s behavior (e.g., button, header)
* **Accessibility Values:** For dynamic content
* **Grouping elements:** So VoiceOver reads them as a single unit

---

### SwiftUI Accessibility Samples

#### 1. Basic Accessibility Label

Make a button accessible with a clear label for VoiceOver:

```swift
Button(action: {
    print("Tapped!")
}) {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete item")
```

Here, even though the button uses a trash icon, VoiceOver will say “Delete item.”

---

#### 2. Accessibility Hint

You can add a hint to give more context:

```swift
Button(action: {
    print("Info tapped")
}) {
    Image(systemName: "info.circle")
}
.accessibilityLabel("Information")
.accessibilityHint("Shows detailed information about the product")
```

---

#### 3. Accessibility Value

For something with a dynamic value, like a slider:

```swift
Slider(value: $volume, in: 0...100)
.accessibilityLabel("Volume")
.accessibilityValue("\(Int(volume)) percent")
```

VoiceOver will announce the current volume percent.

---

#### 4. Accessibility Traits

Tell VoiceOver what kind of element it is:

```swift
Text("Settings")
    .font(.headline)
    .accessibilityAddTraits(.isHeader)
```

This marks the text as a header.

---

#### 5. Grouping Elements

Sometimes you want VoiceOver to treat a group as one item:

```swift
HStack {
    Image(systemName: "person.circle")
    VStack(alignment: .leading) {
        Text("John Appleseed")
        Text("Online")
            .font(.subheadline)
            .foregroundColor(.green)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("John Appleseed, Online")
```

VoiceOver will read the whole row as a single combined element.

---

### Bonus: Testing Accessibility

* Enable **VoiceOver** on your device or simulator (Settings > Accessibility > VoiceOver).
* Use the Accessibility Inspector in Xcode.
* Test Dynamic Type by adjusting font size in Settings.

---

If you want, I can help you build a small SwiftUI view with accessibility features! Would you like me to?

Grouping Multiple Views Into One Accessibility Element
Sometimes you have multiple views that visually belong together but should be read as one item by VoiceOver.
HStack {
    Image(systemName: "person.crop.circle")
    VStack(alignment: .leading) {
        Text("Jane Doe")
            .font(.headline)
        Text("Online")
            .foregroundColor(.green)
            .font(.subheadline)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Jane Doe, online")


Making Custom Controls Accessible
If you create a custom control, implement accessibility traits and labels manually.

struct CustomToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Rectangle()
            .fill(isOn ? Color.green : Color.red)
            .frame(width: 100, height: 50)
            .onTapGesture {
                isOn.toggle()
            }
            .accessibilityElement()
            .accessibilityLabel("Custom toggle")
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityAddTraits(.isButton)
    }
}
