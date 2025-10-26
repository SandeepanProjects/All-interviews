//
//  Core Data Migrations and Versioning.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Perfect ✅ — let’s move into one of the **most important senior-level Core Data topics**:
👉 **Migrations and Model Versioning.**

This topic is where many production apps run into trouble — and where interviewers often check for real-world experience (especially around **lightweight migrations**, **manual migrations**, and **data integrity**).

Let’s break it down clearly and deeply 👇

---

## 🧠 1. What is a Core Data Migration?

A **Core Data migration** happens when your **data model changes** — for example, when you:

* Add or remove an entity, attribute, or relationship,
* Rename an entity or attribute,
* Change attribute types.

Core Data stores metadata about your model version.
When you release a new app version with a modified model, Core Data must **migrate existing persistent stores** to match the new schema — otherwise it fails to load.

---

## ⚙️ 2. What is a Managed Object Model Version?

Each `.xcdatamodeld` file can have **multiple versions** of your data model.

**Example:**

```
MyAppModel.xcdatamodeld
├── Model v1.xcdatamodel
├── Model v2.xcdatamodel (current)
```

When you select “**Set Current Version**” in Xcode, that’s the one Core Data will load at runtime.

---

## 🧩 3. Types of Core Data Migration

### ✅ **Lightweight Migration**

Handled automatically by Core Data when changes are simple and predictable.

**Supported changes:**

* Adding or removing attributes/entities,
* Renaming using mapping hints,
* Adding optional attributes,
* Changing default values.

**Example setup:**

```swift
let container = NSPersistentContainer(name: "MyAppModel")
let description = container.persistentStoreDescriptions.first
description?.shouldMigrateStoreAutomatically = true
description?.shouldInferMappingModelAutomatically = true

container.loadPersistentStores { storeDescription, error in
    if let error = error {
        fatalError("Migration failed: \(error)")
    }
}
```

**Under the hood:**
Core Data infers a **mapping model** by comparing old and new models.

---

### ⚙️ **Manual (Heavyweight) Migration**

Needed when:

* Relationships change significantly (e.g., one-to-many to many-to-many),
* Attribute types change (e.g., Int → String),
* Entities are merged or split.

**Manual migration** uses an explicit `.xcmappingmodel` or `NSMappingModel`.

---

## 🧱 4. Lightweight Migration in Practice

Let’s walk through an example.

### 🔹 Step 1: Change your model

Suppose you add a new field to `User`:

```swift
@NSManaged public var age: Int16
```

### 🔹 Step 2: Create a new model version

1. In Xcode, open your `.xcdatamodeld` file.
2. Choose **Editor → Add Model Version**.
3. Name it (e.g., `ModelV2`).
4. Set it as the **current version**.

### 🔹 Step 3: Enable automatic migration (as shown above).

Now when the app loads, Core Data will automatically detect and migrate the persistent store.

---

## 🧮 5. Manual Migration Example (Custom Mapping)

Let’s say you merged two entities: `FirstName` and `LastName` into `FullName`.
Lightweight migration **can’t infer** that automatically — so you provide a **mapping model**.

### 🔹 Step 1: Create Mapping Model

In Xcode:

* Go to **File → New → Mapping Model**.
* Select source and destination models.
* Edit transformation rules.

Example:
Mapping `Person.firstName` + `Person.lastName` → `User.fullName`.

### 🔹 Step 2: Perform migration in code

```swift
let sourceURL = oldStoreURL
let destinationURL = newStoreURL

let sourceModel = NSManagedObjectModel(contentsOf: sourceModelURL)
let destinationModel = NSManagedObjectModel(contentsOf: destinationModelURL)

let mappingModel = try NSMappingModel.inferredMappingModel(
    forSourceModel: sourceModel!,
    destinationModel: destinationModel!
)

let manager = NSMigrationManager(sourceModel: sourceModel!, destinationModel: destinationModel!)
try manager.migrateStore(
    from: sourceURL,
    sourceType: NSSQLiteStoreType,
    options: nil,
    with: mappingModel,
    toDestinationURL: destinationURL,
    destinationType: NSSQLiteStoreType,
    destinationOptions: nil
)
```

---

## ⚡ 6. Common Migration Issues and Solutions

| Issue                                                                                | Cause                                 | Fix                                                         |
| ------------------------------------------------------------------------------------ | ------------------------------------- | ----------------------------------------------------------- |
| ❌ “The model used to open the store is incompatible with the one used to create it.” | Data model changed without migration. | Enable automatic migration or create a mapping model.       |
| ❌ Migration takes too long                                                           | Large data set                        | Use background migration or versioned migrations over time. |
| ❌ Data corruption after migration                                                    | Incorrect mapping                     | Validate the mapping model or perform manual testing.       |
| ❌ Lightweight migration fails silently                                               | Unsupported change type               | Fall back to manual migration or export data → reimport.    |

---

## 🧠 7. Best Practices for Core Data Migration

### ✅ Always Version Your Models

Never modify the original `.xcdatamodel` directly — always create a **new version**.

---

### ✅ Use Lightweight Migration Where Possible

Keep schema changes **incremental and compatible**.

---

### ✅ Use Mapping Hints for Renames

When renaming an entity or attribute, set the **“Renaming Identifier”** in the Data Model inspector.

Example:

```swift
// Old attribute: firstName
// New attribute: givenName
// Set renaming identifier = firstName
```

This tells Core Data to map the old data automatically.

---

### ✅ Test Migrations Thoroughly

Use unit tests or manual tests with **real persistent stores** from previous app versions.

**Example (Unit Test)**:

```swift
func testMigration() {
    let storeURL = Bundle.main.url(forResource: "OldModelData", withExtension: "sqlite")!
    let container = NSPersistentContainer(name: "MyAppModel")
    container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
    container.loadPersistentStores { _, error in
        XCTAssertNil(error, "Migration failed: \(error!)")
    }
}
```

---

### ✅ Backup Before Migrating in Production

In production apps, always **copy the SQLite file** before performing a migration:

```swift
try FileManager.default.copyItem(at: oldURL, to: backupURL)
```

---

### ✅ Handle Large Stores on a Background Thread

Migrations can block the main thread.
Always perform migrations off the main queue for large databases.

---

## 🧩 8. Summary Table

| Type            | Description                                   | When to Use                          | Example                                        |
| --------------- | --------------------------------------------- | ------------------------------------ | ---------------------------------------------- |
| **Lightweight** | Automatic schema update inferred by Core Data | Simple additions, renames            | `.shouldInferMappingModelAutomatically = true` |
| **Manual**      | Custom migration with mapping model           | Complex relationship or data changes | `NSMigrationManager`                           |
| **Progressive** | Multiple step-by-step migrations              | App with long version history        | Migrate from v1 → v2 → v3 sequentially         |

---

## 🧱 9. Real-World Example Scenario

### **Scenario:**

You’ve shipped version 1 of your app with:

```swift
Entity: User {
   name: String
}
```

In version 2, you added:

```swift
Entity: User {
   name: String
   email: String?
}
```

✅ You can use **lightweight migration** — Core Data will add `email` automatically.
No data loss, no mapping needed.

### **Scenario 2:**

You renamed `User` to `Person`.

✅ Add a “Renaming Identifier” = `User` → lightweight migration still works.

### **Scenario 3:**

You merged `Address` into `User`.

❌ Lightweight migration will fail.
✅ You must create a **mapping model** to merge data fields manually.

---

### 💡 Interview Tip:

If asked about **Core Data Migrations**, mention:

* You always version your models,
* Use lightweight migration when possible,
* Fall back to manual migration for structural changes,
* Test migrations with production data,
* Perform migrations in background for large datasets.

---

Would you like me to continue with the **next advanced Core Data topic** —
👉 **"Core Data + CloudKit Integration"** (using `NSPersistentCloudKitContainer`, sync conflicts, and offline handling)?

That’s the next area interviewers often ask senior iOS developers about after migrations.

Let’s go step-by-step through how **Core Data migrations** work in **Swift / SwiftUI**, and how to implement the three types of migrations you mentioned:
                                            
* **Lightweight migration**
* **Heavyweight (custom) migration**
* **Manual (fully custom) migration**
                                        
---
                                        
## 🧩 Background: Why Migrations Are Needed
                                        
When you change your Core Data model — e.g., rename an attribute, add a new entity, or modify a relationship — your app’s persistent store (`.sqlite` file) may become incompatible with the new model.
                                        
To handle this, Core Data supports different types of **migrations** to update the existing data store to match the new model.
                                        
---
                                        
## ⚙️ 1. Lightweight Migration
                                        
This is the most common and easiest migration type — Core Data can infer the changes automatically (like adding a new attribute, renaming with a rename identifier, or making optional attributes).
                                        
### ✅ Requirements
                                        
* Changes are **simple** (e.g., add optional attributes, remove attributes, rename with proper identifiers).
* You **don’t** change entity types in complex ways.
* You **don’t** need to manipulate data manually.
                                        
### 🧠 How to Enable Lightweight Migration
                                        
If you use SwiftUI’s `@Environment(\.managedObjectContext)` and a `PersistenceController`, you typically configure Core Data in `PersistenceController.swift`.
                                        
Here’s how to modify it:
                                            
```swift
import CoreData
                                        
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error loading store: \(error)")
            }
        }
    }
}
```

That’s it. Core Data will detect small model version changes and migrate automatically.

---

## 💪 2. Heavyweight (Custom Mapping Model) Migration

If Core Data **cannot infer** the migration — for example, you’re merging entities, splitting entities, or transforming data — you need a **mapping model**.
                                                    
### Steps
                                                    
1. **Create a new model version**
                                                    
* In Xcode, select your `.xcdatamodeld` file.
* Go to **Editor → Add Model Version**.
* Name it something like `MyModelV2`.
* Make your changes in the new version.
                                                    
2. **Create a Mapping Model**
                                                    
* In the file navigator, right-click → **New File → Core Data → Mapping Model**.
* Select:
                                                        
* Source model: `MyModel`
* Destination model: `MyModelV2`
                                                    
Xcode generates a `.xcmappingmodel` file, where you can define custom attribute mappings, transformations, or scripts.

3. **Implement Migration Code**

In your persistence setup, before loading the persistent store:

```swift
func migrateStoreIfNeeded(from sourceURL: URL, to destinationURL: URL) {
    let sourceModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "MyModel", withExtension: "mom")!)!
    let destinationModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "MyModelV2", withExtension: "mom")!)!
    let mappingModel = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: destinationModel)
    
    let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
    
    do {
        try migrationManager.migrateStore(from: sourceURL,
                                          sourceType: NSSQLiteStoreType,
                                          options: nil,
                                          with: mappingModel,
                                          toDestinationURL: destinationURL,
                                          destinationType: NSSQLiteStoreType,
                                          destinationOptions: nil)
    } catch {
        fatalError("Migration failed: \(error)")
    }
}
```

Then, after migration, load the new store with your container.

---

## 🧰 3. Manual Migration (Custom Logic in Code)

This is a **fully custom** migration where you programmatically read data from the old store and write it into a new one using your own logic — without any `.xcmappingmodel`.

This is useful when:

* You need to **transform** data extensively.
* You want **full control** of how data moves between models.
* You’re migrating from a **non–Core Data source** or a different Core Data stack.

### Example

```swift
func performManualMigration(oldURL: URL, newURL: URL) {
    // Load old store
    let oldModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "MyModel", withExtension: "mom")!)!
    let oldPSC = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
    try! oldPSC.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: oldURL)
    
    // Load new model
    let newModel = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "MyModelV2", withExtension: "mom")!)!
    let newPSC = NSPersistentStoreCoordinator(managedObjectModel: newModel)
    try! newPSC.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: newURL)
    
    let oldContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    oldContext.persistentStoreCoordinator = oldPSC
    
    let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    newContext.persistentStoreCoordinator = newPSC
    
    // Custom transformation logic
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
    if let oldUsers = try? oldContext.fetch(fetchRequest) {
        for oldUser in oldUsers {
            let newUser = NSEntityDescription.insertNewObject(forEntityName: "Person", into: newContext)
            newUser.setValue(oldUser.value(forKey: "username"), forKey: "name")
            newUser.setValue(Date(), forKey: "createdDate")
        }
    }
    
    try? newContext.save()
}
```

Here you have complete control over how data from the old model maps to the new one.

---

## 🧾 Summary

| Migration Type  | When to Use                               | How to Implement                                                                 |
| --------------- | ----------------------------------------- | -------------------------------------------------------------------------------- |
| **Lightweight** | Simple changes (add fields, rename, etc.) | Set `shouldMigrateStoreAutomatically` and `shouldInferMappingModelAutomatically` |
| **Heavyweight** | Complex model structure changes           | Use a `.xcmappingmodel` and `NSMigrationManager`                                 |
| **Manual**      | Full control or non–Core Data source      | Custom code to read/write between models                                         |

---

Would you like me to show a **complete working SwiftUI Core Data stack** that supports both lightweight and heavyweight migration (ready to copy-paste)?
