//
//  DoublyLinkedList.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/16.
//

import Foundation

// MARK: - DoublyLinkedList

public class DoublyLinkedList<T> {
    // Nested Node class
    public class Node {
        public var value: T
        public var next: Node?
        public weak var previous: Node? // Use 'weak' to prevent retain cycles
        
        public init(value: T) {
            self.value = value
        }
    }
    
    // MARK: Properties
    
    public private(set) var head: Node? // Reference to the first node
    public private(set) var tail: Node? // Reference to the last node
    
    public var isEmpty: Bool {
        return head == nil
    }
    
    public private(set) var count: Int = 0 // Keep track of the number of nodes
    
    // MARK: Computed Properties (Convenience)
    
    public var first: Node? {
        return head
    }
    
    public var last: Node? {
        return tail
    }
    
    // MARK: Initializers
    
    /// Initializes an empty linked list.
    public init() {} // Designated initializer
    
    /// Initializes a linked list with the elements from a sequence (like an Array).
    /// Elements are appended in the order they appear in the sequence.
    /// - Parameter sequence: A sequence containing elements of type T.
    public convenience init<S: Sequence>(_ sequence: S) where S.Element == T {
        self.init() // Call the designated initializer first
        for element in sequence {
            _ = append(element) // Reuse the append logic
        }
    }
    
    // MARK: Append Operation (Add to end)
    
    @discardableResult
    public func append(_ value: T) -> Node {
        let newNode = Node(value: value)
        append(newNode)
        return newNode
    }
    
    // Internal helper to append a node
    private func append(_ newNode: Node) {
        if let currentTail = tail {
            // List is not empty
            newNode.previous = currentTail
            currentTail.next = newNode
            tail = newNode // Update tail reference
        } else {
            // List is empty
            head = newNode
            tail = newNode
        }
        count += 1
    }
    
    // MARK: Prepend Operation (Add to beginning)
    
    @discardableResult
    public func prepend(_ value: T) -> Node {
        let newNode = Node(value: value)
        prepend(newNode)
        return newNode
    }
    
    // Internal helper to prepend a node
    private func prepend(_ newNode: Node) {
        if let currentHead = head {
            // List is not empty
            newNode.next = currentHead
            currentHead.previous = newNode
            head = newNode // Update head reference
        } else {
            // List is empty
            head = newNode
            tail = newNode
        }
        count += 1
    }
    
    // MARK: Insert Operation (Value-based)
    
    /// Inserts a value at a specific index. O(n) complexity.
    /// - Parameters:
    ///   - value: The value to insert.
    ///   - index: The index at which to insert the value. Must be between 0 and `count` (inclusive).
    /// - Returns: The newly created and inserted Node.
    @discardableResult
    public func insert(_ value: T, at index: Int) -> Node {
        let newNode = Node(value: value)
        insert(newNode, at: index)
        return newNode
    }
    
    // Internal helper to insert a node at an index
    private func insert(_ newNode: Node, at index: Int) {
        // Check valid index (allow inserting at count, which means append)
        precondition(index >= 0 && index <= count, "Index out of bounds")
        
        if index == 0 {
            prepend(newNode)
        } else if index == count {
            append(newNode)
        } else {
            // Find the node *currently* at the target index
            let nextNode = node(at: index)! // We know it exists due to precondition
            let prevNode = nextNode.previous // Guaranteed to exist because index > 0
            
            // Link newNode
            newNode.previous = prevNode
            newNode.next = nextNode
            
            // Update surrounding nodes
            prevNode?.next = newNode // Use optional chaining just in case (though should exist)
            nextNode.previous = newNode
            
            count += 1
        }
    }
    
    // MARK: Internal Node-Based Insertions (for DynamicLinkedMap)
    
    /// Inserts a new node immediately before the specified existing node.
    /// Assumes the existingNode is valid and part of this list. O(1) complexity.
    /// - Parameters:
    ///   - newNode: The node to insert.
    ///   - existingNode: The node to insert before.
    /// - Returns: The node that was inserted (`newNode`).
    @discardableResult
    func insert(_ newNode: Node, before existingNode: Node) -> Node {
        guard existingNode !== head else {
            prepend(newNode) // Handle insertion before head
            return newNode
        }
        // If not head, previous is guaranteed to exist
        let prevNode = existingNode.previous!
        
        newNode.previous = prevNode
        newNode.next = existingNode
        prevNode.next = newNode
        existingNode.previous = newNode
        count += 1
        return newNode
    }
    
    /// Inserts a new node immediately after the specified existing node.
    /// Assumes the existingNode is valid and part of this list. O(1) complexity.
    /// - Parameters:
    ///   - newNode: The node to insert.
    ///   - existingNode: The node to insert after.
    /// - Returns: The node that was inserted (`newNode`).
    @discardableResult
    func insert(_ newNode: Node, after existingNode: Node) -> Node {
        guard existingNode !== tail else {
            append(newNode) // Handle insertion after tail
            return newNode
        }
        // If not tail, next is guaranteed to exist
        let nextNode = existingNode.next!
        
        newNode.previous = existingNode
        newNode.next = nextNode
        nextNode.previous = newNode
        existingNode.next = newNode
        count += 1
        return newNode
    }
    
    // MARK: Node Access
    
    /// Returns the node at the specified index.
    /// Optimizes traversal by starting from head or tail depending on index proximity. O(n/2) complexity.
    /// - Parameter index: The index of the node to retrieve.
    /// - Returns: The node at the index, or nil if index is out of bounds.
    public func node(at index: Int) -> Node? {
        guard index >= 0, index < count else {
            return nil // Index out of bounds
        }
        
        // Optimization: Decide whether to traverse from head or tail
        if index < count / 2 {
            // Traverse from head
            var currentNode = head
            var currentIndex = 0
            while currentNode != nil, currentIndex < index {
                currentNode = currentNode?.next
                currentIndex += 1
            }
            return currentNode
        } else {
            // Traverse from tail
            var currentNode = tail
            var currentIndex = count - 1
            while currentNode != nil, currentIndex > index {
                currentNode = currentNode?.previous
                currentIndex -= 1
            }
            return currentNode
        }
    }
    
    /// Convenience subscript to get the *value* at a specific index.
    /// Note: This has O(n) complexity due to linked list nature.
    public subscript(index: Int) -> T {
        let foundNode = node(at: index)
        precondition(foundNode != nil, "Index out of bounds")
        return foundNode!.value
    }
    
    // MARK: Removal Operations
    
    /// Removes the given node from the list. O(1) complexity.
    /// Assumes the node is part of this list.
    /// - Parameter node: The node instance to remove.
    /// - Returns: The value of the removed node.
    @discardableResult // Indicate return value might not be used
    public func remove(node: Node) -> T {
        let prev = node.previous
        let next = node.next
        
        // Update surrounding node pointers
        prev?.next = next
        next?.previous = prev
        
        // Update head/tail if necessary
        if node === head { // Use identity operator (===) for reference comparison
            head = next
        }
        if node === tail {
            tail = prev
        }
        
        // Clean up pointers of the removed node (optional but good practice)
        node.previous = nil
        node.next = nil
        
        count -= 1
        // If count becomes 0, ensure head/tail are nil (should be handled by above logic, but explicit check is safe)
        if count == 0 {
            head = nil
            tail = nil
        }
        
        return node.value
    }
    
    /// Removes the node at the specified index. O(n) complexity.
    /// - Parameter index: The index of the node to remove.
    /// - Returns: The value of the removed node.
    @discardableResult
    public func remove(at index: Int) -> T {
        precondition(index >= 0 && index < count, "Index out of bounds")
        let nodeToRemove = node(at: index)! // We know it exists due to precondition
        return remove(node: nodeToRemove)
    }
    
    /// Removes the last node from the list. O(1) complexity.
    /// - Returns: The value of the removed last node, or nil if the list is empty.
    @discardableResult
    public func removeLast() -> T? {
        guard let currentTail = tail else {
            return nil // List is empty
        }
        return remove(node: currentTail)
    }
    
    /// Removes the first node from the list. O(1) complexity.
    /// - Returns: The value of the removed first node, or nil if the list is empty.
    @discardableResult
    public func removeFirst() -> T? {
        guard let currentHead = head else {
            return nil // List is empty
        }
        return remove(node: currentHead)
    }
    
    /// Removes all nodes from the list. O(n) complexity (to break all links).
    public func removeAll() {
        // Break connections to allow ARC to deallocate nodes
        var currentNode = head
        while let node = currentNode {
            currentNode = node.next
            node.previous = nil // Not strictly necessary due to weak ref, but good practice
            node.next = nil
        }
        
        head = nil
        tail = nil
        count = 0
    }
}

// MARK: - CustomStringConvertible

extension DoublyLinkedList: CustomStringConvertible {
    public var description: String {
        guard !isEmpty else {
            return "[]"
        }
        var result = "["
        var currentNode = head
        while let node = currentNode {
            // Avoid printing the value directly if it might be complex
            // Instead, rely on the value's own description if available
            result += String(describing: node.value)
            if node.next != nil {
                result += " <-> "
            }
            currentNode = node.next
        }
        result += "]"
        return result
    }
}

// MARK: - DoublyLinkedList.ListIterator

extension DoublyLinkedList {
    /// An iterator that traverses the linked list from head to tail, yielding each node.
    public struct ListIterator: IteratorProtocol {
        private var currentNode: Node?
        
        fileprivate init(startNode: Node?) {
            self.currentNode = startNode
        }
        
        public mutating func next() -> Node? {
            guard let node = currentNode else {
                return nil // End of sequence
            }
            currentNode = node.next // Move to the next node
            return node // Return the *current* node before advancing
        }
    }
}

// MARK: - Sequence

extension DoublyLinkedList: Sequence {
    /// Returns an iterator over the nodes of the list.
    public func makeIterator() -> ListIterator {
        return ListIterator(startNode: head)
    }
}
