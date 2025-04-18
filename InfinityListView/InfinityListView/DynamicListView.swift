//
//  InfinityListView.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//

import OSLog
import UIKit

func LOG(_ message: String) {
#if DEUBG
    let logger = Logger(subsystem: "com.example.infinitylistview", category: "InfinityListView")
    logger.debug("\(message)")
#endif
}

// MARK: - DynamicListReusable

@objc
public protocol DynamicListReusable {
    typealias Identifier = String
    static var reusableIdentifier: Identifier? { get }
}

public typealias DynamicListCell = DynamicListReusable & UIView

// MARK: - DynamicListViewDataSource

protocol DynamicListViewDataSource: AnyObject {
    func listView(_ listView: DynamicListView, itemBefore theItem: any DynamicIdentifiable) -> (any DynamicIdentifiable)?
    func listView(_ listView: DynamicListView, itemAfter theItem: any DynamicIdentifiable) -> (any DynamicIdentifiable)?
    func listView(_ listView: DynamicListView, cellFor theItem: any DynamicIdentifiable) -> DynamicListCell
    func listView(_ listView: DynamicListView, heightFor theItem: any DynamicIdentifiable) -> Double
}

// MARK: - DynamicListViewDelegate

protocol DynamicListViewDelegate: AnyObject {
    func listView(_ listView: DynamicListView, cellWillAppear appearedCell: DynamicListView.Cell) -> Void
    func listView(_ listView: DynamicListView, cellWillDisappear disappearedCell: DynamicListView.Cell) -> Void
    
    func listViewDidScroll(_ listView: DynamicListView) -> Void
    func listViewWillBeginDragging(_ listView: DynamicListView) -> Void
    func listViewWillEndDragging(_ listView: DynamicListView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) -> Void
    func listViewDidEndDragging(_ listView: DynamicListView, willDecelerate decelerate: Bool) -> Void
    func listViewWillBeginDecelerating(_ listView: DynamicListView) -> Void
    func listViewDidEndDecelerating(_ listView: DynamicListView) -> Void
    func listViewDidEndScrollingAnimation(_ listView: DynamicListView) -> Void
}

// MARK: - DynamicListView

/// A highly dynamic list view optimized for efficiently displaying large or infinite datasets with variable heights.
///
/// `DynamicListView` renders only cells near the visible area and employs cell reuse (`CellReusableCenter`)
/// for performance. Its core strength lies in dynamically adding/removing cells during scrolling
/// (`renderContentIfNeeded`) without needing a full reload. This prevents visual flashes and allows
/// content updates without interrupting ongoing scroll animations, ensuring a smooth user experience.
///
/// Configure using `dataSource` (provides data, cells, heights) and `delegate` (handles scroll/visibility events).
/// Register cell types via `registerReusableView`. Populate initially using `refreshData`. Ideal for feeds
/// or continuous lists where seamless loading and updates are crucial.
class DynamicListView: UIView {
    // MARK: - Public Properties
    
    /// The rendered cells in the list view, containing preload cells.
    public private(set) var renderedCells: [Cell] = []
    
    /// The visible cells in the list view. O(k) average time.
    public private(set) var visibleCells: [Cell] = []
    
    /// Cells closing the visible area in the range(top and bottom) will be preloaded.
    public var preloadRange: Double = 100
    
    public weak var dataSource: DynamicListViewDataSource?
    public weak var delegate: DynamicListViewDelegate?
    
    // MARK: - Private Properties

    private let scrollView = UIScrollView()
    
    // The Y offset of the list view.
    private var offset: Double {
        set { scrollView.setContentOffset(CGPoint(x: 0, y: newValue), animated: false) }
        get { scrollView.contentOffset.y }
    }
    
    // The top inset of the list view.
    private var inset: Double {
        set { scrollView.contentInset = UIEdgeInsets(top: newValue, left: 0, bottom: 0, right: 0) }
        get { scrollView.contentInset.top }
    }

    // The height of the content in the list view.
    private var contentHeight: Double {
        set { scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: newValue) }
        get { scrollView.contentSize.height }
    }
    
    // The visible frame of the list view.
    private var visibleRange: (top: Double, bottom: Double) {
        (offset, offset + bounds.height)
    }

    /// A set to track previously visible cells using theirs hash values.
    private var previouslyVisibleCells: Set<String> = []
    
    private let cellReusableCenter: CellReusableCenter = .init()
  
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(scrollView)
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

// MARK: - List Refreshing and Scrolling Operations

extension DynamicListView {
    /// Scrolls to the target cell at the specified position in the list view.
    /// - Warning: Not finding the target item will refresh the whole list view.
    public func scroll(
        to targetItem: any DynamicIdentifiable,
        position: Position = .middle,
        animated: Bool = true
    ) {
        var targetRect: CGRect?
        
        defer {
            if let targetRect {
                LOG("targetRect: \(targetRect)")
                switch position {
                case .top:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.minY), animated: animated)
                case .bottom:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.maxY - bounds.height), animated: animated)
                case .middle:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.midY - bounds.height / 2), animated: animated)
                case let .offset(extraOffset):
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.minY + extraOffset), animated: animated)
                }
            }
        }
        
        for renderedCell in renderedCells {
            if renderedCell.item.identifier == targetItem.identifier {
                targetRect = renderedCell.contentView.frame
                return
            }
        }
        
        guard let topCell = renderedCells.first, let bottomCell = renderedCells.last else { return }
        
        var topSearchEnd = false
        var topOffset = topCell.contentView.frame.minY
        var topSearchItem = topCell.item
        
        var bottomSearchEnd = false
        var bottomOffset = bottomCell.contentView.frame.maxY
        var bottomSearchItem = bottomCell.item
        
        while true {
            if !topSearchEnd {
                if let topItem = dataSource?.listView(self, itemBefore: topSearchItem) {
                    let topCellHeight = fetchCellContentHeight(of: topItem)
                    topOffset -= topCellHeight
                    if topItem.identifier == targetItem.identifier {
                        topSearchEnd = true
                        bottomSearchEnd = true
                        
                        targetRect = CGRect(
                            x: 0,
                            y: topOffset,
                            width: bounds.width,
                            height: topCellHeight
                        )
                    } else {
                        topSearchItem = topItem
                    }
                } else {
                    topSearchEnd = true
                }
            }
            
            if !bottomSearchEnd {
                if let bottomItem = dataSource?.listView(self, itemAfter: bottomSearchItem) {
                    let bottomCellHeight = fetchCellContentHeight(of: bottomItem)
                    if bottomItem.identifier == targetItem.identifier {
                        topSearchEnd = true
                        bottomSearchEnd = true
                        
                        targetRect = CGRect(
                            x: 0,
                            y: bottomOffset,
                            width: bounds.width,
                            height: bottomCellHeight
                        )
                    } else {
                        bottomSearchItem = bottomItem
                    }
                    bottomOffset += bottomCellHeight
                } else {
                    bottomSearchEnd = true
                }
            }
            
            if bottomSearchEnd, topSearchEnd {
                break
            }
        }
    }
    
    /// Dynamically refresh the list view without interrupting the scrolling animation.
    /// - Parameters:
    ///   - newItem: The first cell you want to render.
    ///   - replacedItem: A rendered cell will be replaced by the first cell. If the `replacedItem` isn't visible, the whole list will refresh with the `newItem`.
    public func refreshData(
        with newItem: any DynamicIdentifiable,
        replacedItem: any DynamicIdentifiable,
        interruptScrolling: Bool = false
    ) {
        if let replacedCell = renderedCells.first(where: { $0.item.identifier == replacedItem.identifier }) {
            refreshData(with: newItem, position: .offset(replacedCell.contentView.frame.minY - offset))
            return
        }
        refreshData(with: newItem, position: .top, interruptScrolling: interruptScrolling)
    }
    
    /// Recreates all rendered cells.
    /// - Parameters:
    ///   - beginCell: The first cell you want to render.
    ///   - position: The position of the first cell.
    ///   - interruptScrolling: Defaults of `false`; `true` will interrupt the scrolling animation.
    public func refreshData(
        with beginItem: any DynamicIdentifiable,
        position: Position = .middle,
        interruptScrolling: Bool = false
    ) {
        if interruptScrolling {
            offset = self.offset
        }
        
        for renderedCell in renderedCells {
            renderedCell.contentView.removeFromSuperview()
            cellReusableCenter.enqueue(cell: renderedCell.contentView)
        }
        renderedCells.removeAll()
        
        let beginCell = makeCell(from: beginItem)
        
        renderedCells.append(beginCell)
        let cellContentView = beginCell.contentView
        let positionFrame: CGRect
        switch position {
        case .top:
            positionFrame = CGRect(x: 0, y: offset, width: self.bounds.width, height: beginCell.contentHeight)
        case .bottom:
            positionFrame = CGRect(x: 0, y: offset + self.bounds.height - beginCell.contentHeight, width: self.bounds.width, height: beginCell.contentHeight)
        case .middle:
            positionFrame = CGRect(x: 0, y: offset + (self.bounds.height - beginCell.contentHeight) / 2, width: self.bounds.width, height: beginCell.contentHeight)
        case let .offset(extraOffset):
            positionFrame = CGRect(x: 0, y: offset + extraOffset, width: self.bounds.width, height: beginCell.contentHeight)
        }
        cellContentView.frame = positionFrame
        scrollView.addSubview(cellContentView)
        renderContentIfNeeded()
    }
}

// MARK: - Cell Reusing Operations

extension DynamicListView {
    public func registerReusableCell<R: DynamicListCell>(_ viewType: R.Type, builder: @escaping () -> R) {
        cellReusableCenter.registerReusableCell(viewType, builder: builder)
    }
    
    public func dequeueReusableCell<R: DynamicListCell>(_ viewType: R.Type) -> R? {
        guard let identifier = viewType.reusableIdentifier else { return nil }
        return cellReusableCenter.dequeue(cell: identifier) as? R
    }
}

// MARK: - Extended Types

extension DynamicListView {
    /// The rendering information of the cell in the list view.
    struct Cell {
        let item: any DynamicIdentifiable
        let contentView: any DynamicListCell
        let contentHeight: Double
    }
    
    /// The position of the cell in the list view.
    enum Position {
        case top
        case bottom
        case middle
        case offset(Double)
    }
}

// MARK: - Internal Rendering Process

extension DynamicListView {
    private func queryVisibleCells() -> [Cell] {
        let visibleRect = CGRect(x: 0, y: visibleRange.top, width: bounds.width, height: bounds.height)
        return renderedCells.filter { config in
            visibleRect.intersects(config.contentView.frame)
        }
    }
    
    private func fetchCellContentHeight(of cellItem: any DynamicIdentifiable) -> Double {
        if let cell = renderedCells.first(where: { $0.item.identifier == cellItem.identifier }) {
            return cell.contentHeight
        } else {
            return dataSource?.listView(self, heightFor: cellItem) ?? 40
        }
    }
    
    private func fetchCellContentView(of cellItem: any DynamicIdentifiable) -> UIView {
        if let cell = renderedCells.first(where: { $0.item.identifier == cellItem.identifier }) {
            return cell.contentView
        } else {
            let contentView = dataSource?.listView(self, cellFor: cellItem)
            return contentView ?? UIView()
        }
    }
    
    private func makeCell(from cellItem: any DynamicIdentifiable) -> Cell {
        let contentView = dataSource?.listView(self, cellFor: cellItem)
        let contentHeight = dataSource?.listView(self, heightFor: cellItem) ?? 0
        return Cell(item: cellItem, contentView: contentView ?? UIView(), contentHeight: contentHeight)
    }
    
    private func renderContentIfNeeded() {
        while true {
            if let topCell = renderedCells.first, topCell.contentView.frame.minY + preloadRange > offset {
                if let nextCellItem = dataSource?.listView(self, itemBefore: topCell.item) {
                    let nextCell = makeCell(from: nextCellItem)
                    renderedCells.insert(nextCell, at: 0)
                    let cellContentView = nextCell.contentView
                    cellContentView.frame = CGRect(
                        x: 0,
                        y: topCell.contentView.frame.minY - nextCell.contentHeight,
                        width: self.bounds.width,
                        height: nextCell.contentHeight
                    )
                    scrollView.addSubview(cellContentView)
                    if cellContentView.frame.minY < -inset {
                        inset = -cellContentView.frame.minY
                    }
                } else {
                    inset = -topCell.contentView.frame.minY
                    break
                }
            } else {
                break
            }
        }
        while true {
            if let bottomCell = renderedCells.last, bottomCell.contentView.frame.maxY - preloadRange < offset + bounds.height {
                if let nextCellItem = dataSource?.listView(self, itemAfter: bottomCell.item) {
                    let nextCell = makeCell(from: nextCellItem)
                    renderedCells.append(nextCell)
                    let cellContentView = nextCell.contentView
                    cellContentView.frame = CGRect(
                        x: 0,
                        y: bottomCell.contentView.frame.maxY,
                        width: self.bounds.width,
                        height: nextCell.contentHeight
                    )
                    scrollView.addSubview(cellContentView)
                    if cellContentView.frame.maxY > contentHeight {
                        contentHeight = cellContentView.frame.maxY
                    }
                } else {
                    contentHeight = bottomCell.contentView.frame.maxY
                    break
                }
            } else {
                break
            }
        }
        
        // Remove disappeared cells
        var removedCells: [Cell] = []
        renderedCells.removeAll { cellConfig in
            let needRemove = cellConfig.contentView.frame.maxY < visibleRange.top - preloadRange || cellConfig.contentView.frame.minY > visibleRange.bottom + preloadRange
            if needRemove {
                cellConfig.contentView.removeFromSuperview()
                removedCells.append(cellConfig)
            }
            return needRemove
        }
        for item in removedCells {
            cellReusableCenter.enqueue(cell: item.contentView)
        }
        
        // Detect and notify about appeared and disappeared cells
        visibleCells = queryVisibleCells()
        let currentVisibleCellIds = Set(visibleCells.map { $0.item.identifier })
        
        // Find cells that just appeared (in current but not in previous)
        let newlyAppearedCells = visibleCells.filter { !previouslyVisibleCells.contains($0.item.identifier) }
        for cell in newlyAppearedCells {
            delegate?.listView(self, cellWillAppear: cell)
        }
        
        // Find cells that just disappeared (in previous but not in current)
        let newlyDisappearedCellIds = previouslyVisibleCells.subtracting(currentVisibleCellIds)
        let newlyDisappearedCells = renderedCells.filter { newlyDisappearedCellIds.contains($0.item.identifier) }
        for cell in newlyDisappearedCells {
            delegate?.listView(self, cellWillDisappear: cell)
        }
        
        // Update the previously visible cells set
        previouslyVisibleCells = currentVisibleCellIds
    }
}

// MARK: - UIScrollViewDelegate

extension DynamicListView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        renderContentIfNeeded()
        delegate?.listViewDidScroll(self)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
         delegate?.listViewWillBeginDragging(self)
     }
    
     func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
         delegate?.listViewWillEndDragging(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
     }

     func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
         delegate?.listViewDidEndDragging(self, willDecelerate: decelerate)
     }

     func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
         delegate?.listViewWillBeginDecelerating(self)
     }

     func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         delegate?.listViewDidEndDecelerating(self)
     }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
         delegate?.listViewDidEndScrollingAnimation(self)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {}
}

// MARK: - CellReusableCenter

/// A class that manages the reusable cells in the list view.
class CellReusableCenter {
    typealias Identifier = DynamicListCell.Identifier
    private var cacheMap: [Identifier: DynamicListCell] = [:]
    private var reusableCellBuilderMap: [Identifier: () -> DynamicListCell] = [:]
    
    @discardableResult
    func registerReusableCell<R: DynamicListCell>(_ viewType: R.Type, builder: @escaping () -> R) -> Bool {
        guard let identifier = viewType.reusableIdentifier else {
            assertionFailure("\(viewType) must have a reusableIdentifier")
            return false
        }
        if reusableCellBuilderMap[identifier] != nil {
            assertionFailure("\(identifier) already registered")
            return false
        }
        reusableCellBuilderMap[identifier] = builder
        return true
    }
    
    func enqueue(cell: DynamicListCell) {
        guard let identifier = type(of: cell).reusableIdentifier else { return }
        cacheMap[identifier] = cell
    }
    
    func dequeue(cell identifier: Identifier) -> DynamicListCell? {
        if let cell = cacheMap.removeValue(forKey: identifier) {
            return cell
        }
        if let builder = reusableCellBuilderMap[identifier] {
            return builder()
        }
        return nil
    }
}
