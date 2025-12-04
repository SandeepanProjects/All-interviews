//
//  TestFlight.swift
//  
//
//  Created by Apple on 04/12/25.
//

import Foundation

Here is a **clear, complete, and up-to-date** guide on how to push your iOS app to **TestFlight** — perfect for interviews or real deployment.

---

# 🚀 **How to Upload an iOS App to TestFlight**

There are **4 major steps**:

---

# 1️⃣ **Prepare Your App for Distribution**

### **1. Set the correct Bundle Identifier**

Go to **Xcode → Targets → YourApp → General**
Ensure:
✔️ Unique Bundle ID
✔️ Matches your App Store Connect app

---

### **2. Set the correct version & build number**

Go to **Xcode → Targets → Build Settings** or **General**

You must increment:

* **Version** → e.g., 1.0 → 1.1 (only when submitting a new version)
* **Build Number** → e.g., 1 → 2 → 3 (every upload requires a new build)

---

### **3. Use Release configuration**

Go to:
**Product → Scheme → Edit Scheme → Run → Build Configuration → Release**

---

# 2️⃣ **Archive Your App**

### **Steps**

1. Connect any device OR select **Any iOS Device (arm64)**
2. Go to **Product → Archive**
3. Wait until Xcode finishes archiving
4. The **Organizer** window will open automatically

---

# 3️⃣ **Upload to App Store Connect (TestFlight)**

From the *Organizer*:

1. Select your new archive
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Choose **Upload**
5. Make sure the following are selected:

   * ✔️ **Include symbols**
   * ✔️ **Include bitcode** (if available)
6. Sign with your **App Store** provisioning profile
7. Upload

Xcode will upload your build to App Store Connect.

---

# 4️⃣ **Enable TestFlight in App Store Connect**

### **1. Go to App Store Connect**

[https://appstoreconnect.apple.com/](https://appstoreconnect.apple.com/)

### **2. Select “My Apps” → Your App**

### **3. Go to “TestFlight” tab**

Your uploaded build will appear here (usually after 2–10 minutes).

### **4. Add testers**

There are two types:

#### **Internal testers (immediate access)**

* Up to 100 testers
* Must be part of your App Store Connect team
* No review required

#### **External testers (review required)**

* Up to 10,000 testers
* Apple must review your build (usually 5–48 hours)

Add testers → Send invitation → Install via TestFlight app

---

# 🎉 Your app is now on TestFlight!

---

# ⚠️ Common Issues & Fixes

| Issue                             | Fix                                                                                |
| --------------------------------- | ---------------------------------------------------------------------------------- |
| **Missing Compliance** message    | Upload requires export compliance info (choose “No” if no encryption beyond HTTPS) |
| **ITMS-90035: Invalid Signature** | Use automatic signing & correct distribution certificate                           |
| **Missing icons**                 | Provide all AppIcon sizes in Assets                                                |
| **Build not appearing**           | Wait 10–20 mins or check email for processing errors                               |

---

# 🧩 Bonus: Fastlane Upload (Advanced Devs)

If you want CI automation:

```sh
fastlane pilot upload -u your@email.com -i YourApp.ipa
```

---


