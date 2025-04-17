//
//  DynamicLinkedArray.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/16.
//

import Foundation

// MARK: - DynamicIdentifiable

/// A protocol that requires conforming types to have a unique identifier.
public protocol DynamicIdentifiable {
    var identifier: String { get }
}

// MARK: - DynamicLinkedMap

/// A data structure that combines the O(1) average time complexity for key-based lookups,
/// insertions, and deletions of a dictionary with the ordered sequence guarantees
/// of a doubly linked list.
public class DynamicLinkedMap<Item: DynamicIdentifiable> {
    // Typealias for the nested Node type for convenience
    public typealias NodeType = DoublyLinkedList<Item>.Node
    
    // The underlying ordered list of nodes
    private let linkedList: DoublyLinkedList<Item>
    // The map providing fast access from identifier to node
    private var itemMap: [String: NodeType] = [:]
    
    // MARK: Properties
    
    /// Returns the number of items in the map. O(1) time.
    public var count: Int {
        // Ensure consistency check (optional debug check)
        // assert(linkedList.count == itemMap.count, "List count (\(linkedList.count)) and map count (\(itemMap.count)) mismatch")
        return linkedList.count
    }
    
    /// Returns true if the map is empty. O(1) time.
    public var isEmpty: Bool {
        return linkedList.isEmpty
    }
    
    /// Returns the first item in the map's sequence, or nil if empty. O(1) time.
    public var first: Item? {
        return linkedList.first?.value
    }
    
    /// Returns the last item in the map's sequence, or nil if empty. O(1) time.
    public var last: Item? {
        return linkedList.last?.value
    }
    
    // MARK: Initializers
    
    /// Initializes the map with items from a sequence.
    /// Items are added in the order they appear in the sequence.
    /// Duplicate identifiers in the initial sequence will cause a runtime error (precondition failure).
    public init<S: Sequence>(_ sequence: S) where S.Element == Item {
        linkedList = DoublyLinkedList<Item>() // Start with an empty list
        for item in sequence {
            let key = item.identifier
            precondition(itemMap[key] == nil, "Duplicate identifier found during initialization: \(key)")
            let node = linkedList.append(item) // append returns the node
            itemMap[key] = node
        }
    }
    
    /// Initializes an empty map.
    public init() {
        linkedList = DoublyLinkedList<Item>()
        itemMap = [:]
    }
    
    // MARK: - Single Item Query Operations
    
    /// Retrieves the item associated with the given identifier (key). O(1) average time.
    public func item(for key: String) -> Item? {
        return itemMap[key]?.value
    }
    
    /// Retrieves the item immediately preceding the item with the given identifier. O(1) average time.
    public func previousItem(for key: String) -> Item? {
        return itemMap[key]?.previous?.value
    }
    
    /// Retrieves the item immediately succeeding the item with the given identifier. O(1) average time.
    public func nextItem(for key: String) -> Item? {
        return itemMap[key]?.next?.value
    }
    
    /// Checks if an item with the given identifier exists in the map. O(1) average time.
    public func contains(key: String) -> Bool {
        return itemMap[key] != nil
    }
    
    // MARK: - Single Item Modification Operations
    
    /// Appends a new item to the end of the map's sequence.
    /// Does nothing and returns `false` if an item with the same identifier already exists. O(1) time.
    @discardableResult
    public func append(_ newItem: Item) -> Bool {
        let key = newItem.identifier
        guard itemMap[key] == nil else {
            print("Warning: Item with identifier '\(key)' already exists. Append operation ignored.")
            return false
        }
        let newNode = linkedList.append(newItem)
        itemMap[key] = newNode
        return true
    }
    
    /// Prepends a new item to the beginning of the map's sequence.
    /// Does nothing and returns `false` if an item with the same identifier already exists. O(1) time.
    @discardableResult
    public func prepend(_ newItem: Item) -> Bool {
        let key = newItem.identifier
        guard itemMap[key] == nil else {
            print("Warning: Item with identifier '\(key)' already exists. Prepend operation ignored.")
            return false
        }
        let newNode = linkedList.prepend(newItem)
        itemMap[key] = newNode
        return true
    }
    
    /// Inserts a new item immediately before the item with the specified existing identifier.
    /// Does nothing and returns `false` if `newItem.identifier` already exists, or if `beforeKey` is not found. O(1) average time.
    @discardableResult
    public func insert(_ newItem: Item, before beforeKey: String) -> Bool {
        let newKey = newItem.identifier
        guard itemMap[newKey] == nil else {
            print("Warning: Item with identifier '\(newKey)' already exists. Insert operation ignored.")
            return false
        }
        guard let existingNode = itemMap[beforeKey] else {
            print("Warning: Target identifier '\(beforeKey)' not found for insert before. Insert operation ignored.")
            return false
        }
        // Create node manually, then use list's internal insert
        let newNode = DoublyLinkedList<Item>.Node(value: newItem)
        linkedList.insert(newNode, before: existingNode) // Use internal helper
        itemMap[newKey] = newNode // Add to map
        return true
    }
    
    /// Inserts a new item immediately after the item with the specified existing identifier.
    /// Does nothing and returns `false` if `newItem.identifier` already exists, or if `afterKey` is not found. O(1) average time.
    @discardableResult
    public func insert(_ newItem: Item, after afterKey: String) -> Bool {
        let newKey = newItem.identifier
        guard itemMap[newKey] == nil else {
            print("Warning: Item with identifier '\(newKey)' already exists. Insert operation ignored.")
            return false
        }
        guard let existingNode = itemMap[afterKey] else {
            print("Warning: Target identifier '\(afterKey)' not found for insert after. Insert operation ignored.")
            return false
        }
        // Create node manually, then use list's internal insert
        let newNode = DoublyLinkedList<Item>.Node(value: newItem)
        linkedList.insert(newNode, after: existingNode) // Use internal helper
        itemMap[newKey] = newNode // Add to map
        return true
    }
    
    /// Removes the item associated with the given identifier from the map. O(1) average time.
    /// - Parameter key: The identifier of the item to remove.
    /// - Returns: The removed item, or `nil` if the key was not found.
    @discardableResult
    public func remove(forKey key: String) -> Item? {
        // Remove from map first. If it exists, remove the node from the list.
        guard let nodeToRemove = itemMap.removeValue(forKey: key) else {
            // Optionally print warning: print("Warning: Identifier '\(key)' not found for remove. Operation ignored.")
            return nil // Key wasn't in the map
        }
        // Key was found and removed from map, now remove from list
        let removedValue = linkedList.remove(node: nodeToRemove)
        return removedValue
    }
    
    /// Removes all items from the map. O(n) time (dominated by list clearing).
    public func removeAll() {
        linkedList.removeAll() // Clears list pointers & count
        itemMap.removeAll() // Clears the map
    }
    
    // MARK: - Original Update Operation (Item Identifier Based)
    
    /// Updates the value of the item identified by `newItem.identifier`.
    /// The item must already exist in the map with the same identifier. O(1) average time.
    /// - Parameter newItem: The item containing the new value and the identifier to update.
    /// - Returns: The *old* item value if the identifier was found and updated, otherwise `nil`.
    @discardableResult
    public func update(item newItem: Item) -> Item? {
        let key = newItem.identifier
        guard let nodeToUpdate = itemMap[key] else {
            // Optionally print warning: print("Warning: Identifier '\(key)' not found for update. Update operation ignored.")
            return nil // Key not found
        }
        let oldValue = nodeToUpdate.value
        nodeToUpdate.value = newItem // Update value directly in the node
        return oldValue
    }
    
    // MARK: - New Target-Key Based Update Operations
    
    /// Updates the item associated with `targetKey` using the data from `newItem`.
    /// If `newItem.identifier` is different from `targetKey`, the key in the internal map will be updated.
    /// Fails if `targetKey` is not found or if `newItem.identifier` conflicts with an *existing* item's key (other than `targetKey`). O(1) average time.
    /// - Parameters:
    ///   - newItem: The item containing the new data and potentially a new identifier.
    ///   - targetKey: The identifier of the item to update.
    /// - Returns: The original `Item` value before the update, or `nil` if the update failed.
    @discardableResult
    public func update(item newItem: Item, forKey targetKey: String) -> Item? {
        // 1. Find the node associated with the target key
        guard let targetNode = itemMap[targetKey] else {
            print("Warning: Target key '\(targetKey)' not found for updateValue.")
            return nil
        }
        
        let oldValue = targetNode.value
        let newKey = newItem.identifier
        let keyChanged = (newKey != targetKey)
        
        // 2. Check for key conflict if the key is changing
        if keyChanged {
            if itemMap[newKey] != nil {
                // Conflict: newKey already exists for a different node
                print("Warning: New identifier '\(newKey)' conflicts with an existing item during updateValue for target '\(targetKey)'. Update failed.")
                return nil
            }
        }
        
        // 3. Update the value in the node
        targetNode.value = newItem
        
        // 4. Update the map if the key changed
        if keyChanged {
            itemMap.removeValue(forKey: targetKey)
            itemMap[newKey] = targetNode
        }
        
        return oldValue
    }
    
    // MARK: - Array/Sequence Convenience Query & Modification
    
    /// Returns an array containing all items in the map, preserving the linked list order. O(n) time.
    public var allItems: [Item] {
        return linkedList.map { $0.value }
    }
    
    /// Retrieves items for the given sequence of keys, maintaining the order of the input keys.
    /// If a key is not found, the corresponding element in the returned array will be `nil`. O(k) average time.
    public func items<S: Sequence>(forKeys keys: S) -> [Item?] where S.Element == String {
        return keys.map { key in
            self.item(for: key) // Use the single item getter
        }
    }
    
    /// Appends items from a sequence to the end of the map's sequence.
    /// Items with identifiers already present in the map are skipped. O(k) time.
    /// - Parameter sequence: The sequence of items to append.
    /// - Returns: An array of identifiers (`String`) for items that were *not* appended because they already existed.
    @discardableResult
    public func append<S: Sequence>(contentsOf sequence: S) -> [String] where S.Element == Item {
        var skippedKeys: [String] = []
        for item in sequence {
            if !append(item) { // Use the single append method
                skippedKeys.append(item.identifier)
            }
        }
        return skippedKeys
    }
    
    /// Prepends items from a sequence to the beginning of the map's sequence, maintaining the sequence's order.
    /// Items with identifiers already present in the map are skipped. O(k) time.
    /// - Parameter sequence: The sequence of items to prepend.
    /// - Returns: An array of identifiers (`String`) for items that were *not* prepended because they already existed.
    @discardableResult
    public func prepend<S: Sequence>(contentsOf sequence: S) -> [String] where S.Element == Item {
        var skippedKeys: [String] = []
        // Iterate in reverse to maintain original order when prepending
        for item in sequence.reversed() {
            if !prepend(item) { // Use the single prepend method
                skippedKeys.append(item.identifier)
            }
        }
        // Return skipped keys in the order they appeared in the original sequence
        return skippedKeys.reversed()
    }
    
    /// Inserts items from a sequence immediately after the item with the specified existing identifier, maintaining the sequence's order.
    /// Skips items from the sequence whose identifiers already exist in the map. Fails if `afterKey` is not found. O(k) time after finding the initial node.
    /// - Parameters:
    ///   - sequence: The sequence of items to insert.
    ///   - afterKey: The identifier of the item to insert after.
    /// - Returns: An array of identifiers (`String`) for items that were *not* inserted. Returns all item identifiers from sequence if `afterKey` not found.
    @discardableResult
    public func insert<S: Sequence>(contentsOf sequence: S, after afterKey: String) -> [String] where S.Element == Item {
        guard let afterNode = itemMap[afterKey] else {
            print("Warning: Target identifier '\(afterKey)' not found for batch insert after. No items inserted.")
            return sequence.map { $0.identifier } // Return all keys from sequence as skipped
        }
        
        var skippedKeys: [String] = []
        var currentNode = afterNode // Start inserting after this node
        
        for item in sequence {
            let newKey = item.identifier
            if itemMap[newKey] != nil {
                // Skip item if its key already exists elsewhere in the map
                print("Warning: Item with identifier '\(newKey)' already exists. Skipping batch insertion.")
                skippedKeys.append(newKey)
                continue
            }
            
            // Create node manually and use list's internal insert
            let newNode = DoublyLinkedList<Item>.Node(value: item)
            linkedList.insert(newNode, after: currentNode) // Insert after the *current* node
            itemMap[newKey] = newNode // Add to map
            currentNode = newNode // Update current node for the next insertion
        }
        return skippedKeys
    }
    
    /// Inserts items from a sequence immediately before the item with the specified existing identifier, maintaining the sequence's order.
    /// Skips items from the sequence whose identifiers already exist in the map. Fails if `beforeKey` is not found. O(k) time after finding the initial node.
    /// - Parameters:
    ///   - sequence: The sequence of items to insert.
    ///   - beforeKey: The identifier of the item to insert before.
    /// - Returns: An array of identifiers (`String`) for items that were *not* inserted. Returns all item identifiers from sequence if `beforeKey` not found.
    @discardableResult
    public func insert<S: Sequence>(contentsOf sequence: S, before beforeKey: String) -> [String] where S.Element == Item {
        guard let beforeNode = itemMap[beforeKey] else {
            print("Warning: Target identifier '\(beforeKey)' not found for batch insert before. No items inserted.")
            return sequence.map { $0.identifier } // Return all keys as skipped
        }
        
        var skippedKeys: [String] = []
        
        // Iterate normally, always inserting *before* the original target node
        for item in sequence {
            let newKey = item.identifier
            if itemMap[newKey] != nil {
                // Skip item if its key already exists elsewhere in the map
                print("Warning: Item with identifier '\(newKey)' already exists. Skipping batch insertion.")
                skippedKeys.append(newKey)
                continue
            }
            
            // Create node manually and use list's internal insert
            let newNode = DoublyLinkedList<Item>.Node(value: item)
            linkedList.insert(newNode, before: beforeNode) // Always insert before the original target node
            itemMap[newKey] = newNode // Add to map
            // No need to update a 'currentNode' here, insertion point is fixed
        }
        return skippedKeys
    }
    
    /// Updates multiple items in the map based on the identifiers of the items provided in the sequence (using the original `update(item:)` logic).
    /// Items in the sequence whose identifiers are not found in the map are ignored. O(k) average time.
    /// - Parameter items: A sequence of items with updated values.
    /// - Returns: A dictionary `[String: Item]` mapping the identifier to the *old* value for each item that was successfully updated.
    @discardableResult
    public func update<S: Sequence>(items: S) -> [String: Item] where S.Element == Item {
        var oldValues: [String: Item] = [:]
        for item in items {
            if let oldValue = update(item: item) { // Use single item update (key must match item.identifier)
                oldValues[item.identifier] = oldValue
            }
        }
        return oldValues
    }
    
    /// Removes items associated with the identifiers in the given sequence.
    /// Keys not found in the map are ignored. O(k) average time.
    /// - Parameter keys: A sequence of identifiers to remove.
    /// - Returns: A dictionary `[String: Item]` mapping the identifier to the value for each item that was successfully removed.
    @discardableResult
    public func remove<S: Sequence>(forKeys keys: S) -> [String: Item] where S.Element == String {
        var removedItems: [String: Item] = [:]
        for key in keys {
            if let removedValue = remove(forKey: key) { // Use single item remove
                removedItems[key] = removedValue
            }
        }
        return removedItems
    }
}

// MARK: - Sequence

extension DynamicLinkedMap: Sequence {
    /// An iterator that traverses the map's items in the order defined by the linked list.
    public struct MapIterator: IteratorProtocol {
        // Internal iterator over the LinkedList Nodes
        private var listIterator: DoublyLinkedList<Item>.ListIterator
        
        // Initialize with the list's iterator
        fileprivate init(list: DoublyLinkedList<Item>) {
            self.listIterator = list.makeIterator()
        }
        
        /// Advances to the next item and returns it, or `nil` if no next item exists.
        public mutating func next() -> Item? {
            // Get the next Node? from the list iterator
            // Use optional chaining (`?`) to safely get the value from the node
            return listIterator.next()?.value
        }
    }
    
    /// Returns an iterator over the items of the map.
    public func makeIterator() -> MapIterator {
        // Create and return our custom iterator, initialized with the internal list
        return MapIterator(list: linkedList)
    }
}
