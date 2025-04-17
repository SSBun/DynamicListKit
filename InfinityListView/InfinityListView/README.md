# DynamicLinkedMap

**A Swift data structure combining the performance of a Dictionary with the ordered sequence of a Doubly Linked List.**

## Overview

`DynamicLinkedMap` is designed for scenarios where you need both fast key-based access (like a `Dictionary`) and a guaranteed, stable iteration order based on insertion sequence (like an `Array` or Linked List). It achieves this by internally managing a `DoublyLinkedList` to maintain order and a `Dictionary` (`[String: Node]`) to provide O(1) average time complexity for lookups, insertions, and deletions based on an item's unique identifier.

This is particularly useful for managing datasets where elements need to be frequently accessed, added, removed, or reordered based on their keys, while also needing to be displayed or processed sequentially.

## Features

*   **O(1) Average Time Complexity:** For key-based operations:
    *   Retrieving an item (`item(for:)`)
    *   Retrieving the previous/next item (`previousItem(for:)`, `nextItem(for:)`)
    *   Checking for existence (`contains(key:)`)
    *   Adding items (`append`, `prepend`, `insert(before:)`, `insert(after:)`)
    *   Removing items (`remove(forKey:)`)
    *   Updating items (`update(item:)`, `update(item:forKey:)`)
*   **Ordered Sequence:** Maintains the insertion order of elements. Iteration (`for item in map`) occurs in this defined order.
*   **Efficient Sequence Operations:** Provides methods for batch appending, prepending, inserting, updating, and removing items from sequences.
*   **Identifiable Items:** Requires items to conform to the `DynamicIdentifiable` protocol, ensuring each item has a unique `String` identifier.
*   **Type-Safe:** Generic over the `Item` type.

## Usage

### 1. Define Your Item Type

First, define the data structure you want to store. Make sure it conforms to `DynamicIdentifiable`.

```swift
struct User: DynamicIdentifiable, CustomStringConvertible {
    let id: Int
    var name: String
    var email: String

    // Conformance to DynamicIdentifiable
    var identifier: String {
        return "user_\(id)" // Ensure this is unique for each instance
    }

    // For easier printing in examples
    var description: String {
        return "User(id: \(id), name: \"\(name)\", identifier: \"\(identifier)\")"
    }
}
```

### 2. Initialization

You can create an empty map or initialize it with a sequence of items.

```swift
// Create an empty map
let userMap = DynamicLinkedMap<User>()

// Create users
let alice = User(id: 1, name: "Alice", email: "alice@example.com")
let bob = User(id: 2, name: "Bob", email: "bob@example.com")
let charlie = User(id: 3, name: "Charlie", email: "charlie@example.com")

// Initialize with a sequence (duplicates will cause a crash)
let initialUsers = [alice, bob, charlie]
let userMapFromSequence = DynamicLinkedMap(initialUsers)
print(userMapFromSequence.count) // Output: 3
```

### 3. Basic Properties

Access basic information about the map.

```swift
print(userMap.isEmpty) // Output: true
print(userMap.count)   // Output: 0

userMap.append(alice)
print(userMap.isEmpty) // Output: false
print(userMap.count)   // Output: 1
print(userMap.first)   // Output: Optional(User(id: 1, name: "Alice", identifier: "user_1"))
print(userMap.last)    // Output: Optional(User(id: 1, name: "Alice", identifier: "user_1"))
```

### 4. Adding Items

Add single items to the start, end, or relative to existing items. These operations return `false` if an item with the same identifier already exists.

```swift
let userMap = DynamicLinkedMap<User>()
userMap.append(bob)       // [Bob]
userMap.prepend(alice)    // [Alice, Bob]

let charlie = User(id: 3, name: "Charlie", email: "charlie@example.com")
userMap.insert(charlie, after: bob.identifier) // [Alice, Bob, Charlie]

let dave = User(id: 4, name: "Dave", email: "dave@example.com")
userMap.insert(dave, before: bob.identifier) // [Alice, Dave, Bob, Charlie]

print(userMap.allItems.map { $0.name }) // Output: ["Alice", "Dave", "Bob", "Charlie"]

// Try adding Alice again (will fail and print a warning)
let addedAgain = userMap.append(alice)
print(addedAgain) // Output: false
```

### 5. Retrieving Items

Access items by their key or relative position.

```swift
// Assuming userMap is [Alice, Dave, Bob, Charlie]

// Get by key
if let retrievedBob = userMap.item(for: "user_2") {
    print("Found: \(retrievedBob.name)") // Output: Found: Bob
}

// Get neighbors
let itemBeforeBob = userMap.previousItem(for: "user_2")
print(itemBeforeBob?.name) // Output: Optional("Dave")

let itemAfterBob = userMap.nextItem(for: "user_2")
print(itemAfterBob?.name) // Output: Optional("Charlie")

// Check existence
print(userMap.contains(key: "user_1")) // Output: true
print(userMap.contains(key: "user_99")) // Output: false
```

### 6. Updating Items

Update an existing item's value.

**Method 1: `update(item:)`**
Updates the item matching the `newItem.identifier`. The identifier *must* already exist.

```swift
var updatedAlice = alice
updatedAlice.name = "Alice Smith"

if let oldAlice = userMap.update(item: updatedAlice) {
    print("Updated Alice. Old name: \(oldAlice.name)") // Output: Updated Alice. Old name: Alice
}
print(userMap.item(for: alice.identifier)?.name) // Output: Optional("Alice Smith")
```

**Method 2: `update(item:forKey:)`**
Updates the item identified by `targetKey` using data from `newItem`. This allows changing the item's value *and potentially its identifier* if `newItem.identifier` differs from `targetKey`. Fails if `targetKey` doesn't exist or if `newItem.identifier` conflicts with another *existing* key.

```swift
// Update Bob's details, keeping the same identifier
var updatedBob = User(id: 2, name: "Robert", email: "robert@example.com") // identifier is still "user_2"
if let oldBob = userMap.update(item: updatedBob, forKey: "user_2") {
     print("Updated Bob. Old name: \(oldBob.name)") // Output: Updated Bob. Old name: Bob
}
print(userMap.item(for: "user_2")?.name) // Output: Optional("Robert")


// Try to update Charlie (user_3) and change his ID/identifier to 33 (user_33)
var updatedCharlie = User(id: 33, name: "Charles", email: "charles@example.com") // New identifier: "user_33"
if let oldCharlie = userMap.update(item: updatedCharlie, forKey: "user_3") {
    print("Updated Charlie and changed key. Old name: \(oldCharlie.name)") // Output: Updated Charlie and changed key. Old name: Charlie
}
print(userMap.contains(key: "user_3"))  // Output: false
print(userMap.item(for: "user_33")?.name) // Output: Optional("Charles")


// Try to update Dave (user_4) to use Alice's identifier (user_1) - this will fail
var conflictingUpdate = User(id: 1, name: "Dave Conflicting", email: "dave@example.com") // identifier "user_1" exists
if userMap.update(item: conflictingUpdate, forKey: "user_4") == nil {
    print("Failed to update Dave with conflicting ID.") // Output: Failed to update Dave with conflicting ID.
}
print(userMap.item(for: "user_4")?.name) // Output: Optional("Dave") - Unchanged
```

### 7. Removing Items

Remove items by key or clear the entire map.

```swift
// Assuming userMap is [Alice(1), Dave(4), Bob(2), Charlie(33)]

// Remove by key
if let removedDave = userMap.remove(forKey: "user_4") {
    print("Removed: \(removedDave.name)") // Output: Removed: Dave
}
print(userMap.count) // Output: 3
print(userMap.allItems.map { $0.name }) // Output: ["Alice Smith", "Robert", "Charles"]

// Remove all
userMap.removeAll()
print(userMap.isEmpty) // Output: true
print(userMap.count) // Output: 0
```

### 8. Working with Sequences

Perform batch operations efficiently.

```swift
let userMap = DynamicLinkedMap<User>()
let users1 = [
    User(id: 10, name: "Eve", email: "eve@example.com"),
    User(id: 11, name: "Frank", email: "frank@example.com")
]
let users2 = [
    User(id: 12, name: "Grace", email: "grace@example.com"),
    User(id: 10, name: "Eve Updated", email: "eve2@example.com") // Duplicate ID
]

// Batch Append
let skippedAppend = userMap.append(contentsOf: users1) // [Eve, Frank]
print("Append skipped: \(skippedAppend)") // Output: Append skipped: []

// Batch Prepend (note: Grace added first, then Eve Updated skipped)
let skippedPrepend = userMap.prepend(contentsOf: users2) // [Grace, Eve, Frank]
print("Prepend skipped: \(skippedPrepend)") // Output: Prepend skipped: ["user_10"]
print(userMap.allItems.map { $0.name }) // Output: ["Grace", "Eve", "Frank"]

// Batch Insert After
let users3 = [ User(id: 13, name: "Heidi", email: "h@e.com")]
let skippedInsert = userMap.insert(contentsOf: users3, after: "user_10") // [Grace, Eve, Heidi, Frank]
print(userMap.allItems.map { $0.name }) // Output: ["Grace", "Eve", "Heidi", "Frank"]

// Get multiple items
let keysToGet: [String] = ["user_11", "user_99", "user_13"]
let fetchedItems = userMap.items(forKeys: keysToGet)
print(fetchedItems.map { $0?.name }) // Output: [Optional("Frank"), nil, Optional("Heidi")]

// Batch Update
let updates = [
    User(id: 11, name: "Franklin", email: "franklin@example.com"), // Will update Frank
    User(id: 99, name: "Nobody", email: "no@body.com") // Will be ignored
]
let oldValues = userMap.update(items: updates)
print("Updated: \(oldValues.mapValues { $0.name })") // Output: Updated: ["user_11": "Frank"]
print(userMap.item(for: "user_11")?.name) // Output: Optional("Franklin")

// Batch Remove
let keysToRemove = ["user_10", "user_13", "user_0"]
let removedItems = userMap.remove(forKeys: keysToRemove)
print("Removed: \(removedItems.mapValues { $0.name })") // Output: Removed: ["user_10": "Eve", "user_13": "Heidi"]
print(userMap.allItems.map { $0.name }) // Output: ["Grace", "Franklin"]
```

### 9. Iteration

`DynamicLinkedMap` conforms to `Sequence`, so you can iterate over it directly, preserving the list order.

```swift
// Assuming userMap is [Grace, Franklin]
for user in userMap {
    print("- \(user.name)")
}
// Output:
// - Grace
// - Franklin

// You can also use other Sequence methods like map, filter, etc.
let userNames = userMap.map { $0.name }
print(userNames) // Output: ["Grace", "Franklin"]
```

## Time Complexity

| Operation                      | Average Time Complexity | Notes                                      |
| :----------------------------- | :---------------------- | :----------------------------------------- |
| `count`, `isEmpty`             | O(1)                    |                                            |
| `first`, `last`                | O(1)                    |                                            |
| `item(for:)`                   | O(1)                    | Dictionary lookup                          |
| `previousItem(for:)`         | O(1)                    | Dictionary lookup + linked list traversal |
| `nextItem(for:)`             | O(1)                    | Dictionary lookup + linked list traversal |
| `contains(key:)`               | O(1)                    | Dictionary lookup                          |
| `append(_:)`                   | O(1)                    | Dictionary check + list append             |
| `prepend(_:)`                  | O(1)                    | Dictionary check + list prepend            |
| `insert(_, before:)`           | O(1)                    | Dictionary checks + list insert            |
| `insert(_, after:)`            | O(1)                    | Dictionary checks + list insert            |
| `remove(forKey:)`              | O(1)                    | Dictionary remove + list remove            |
| `removeAll()`                  | O(n)                    | Clearing list nodes takes linear time      |
| `update(item:)`                | O(1)                    | Dictionary lookup + node update            |
| `update(item:forKey:)`         | O(1)                    | Dictionary lookups/update + node update    |
| `allItems`                     | O(n)                    | Iterating through the linked list          |
| Iteration (`for...in`)         | O(n)                    | Iterating through the linked list          |
| Sequence Ops (k = # items)   | O(k)                    | Each item takes approx. O(1) on average    |

---

