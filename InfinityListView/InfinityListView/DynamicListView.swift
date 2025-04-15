//
//  InfinityListView.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//

import OSLog
import UIKit

func LOG(_ message: String) {
    let logger = Logger(subsystem: "com.example.infinitylistview", category: "InfinityListView")
    logger.debug("\(message)")
}

// MARK: - DynamicListItem

protocol DynamicListItem {
    associatedtype ID: Hashable
    var id: ID { get }
}

// MARK: - DynamicListViewDataSource

protocol DynamicListViewDataSource: AnyObject {
    func listView(listView: DynamicListView, cellBefore theCell: any DynamicListItem) -> (any DynamicListItem)?
    func listView(listView: DynamicListView, cellAfter theCell: any DynamicListItem) -> (any DynamicListItem)?
    func listView(listView: DynamicListView, contentViewOf theCell: any DynamicListItem) -> UIView
    func listView(listView: DynamicListView, heightOf theCell: any DynamicListItem) -> Double
}

// MARK: - DynamicListViewDelegate

protocol DynamicListViewDelegate: AnyObject {
    func cellDidAppear(from listView: DynamicListView, cell: DynamicListView.Cell) -> Void
    func cellDidDisappear(from listView: DynamicListView, cell: DynamicListView.Cell) -> Void
    func cellDidRemoved(from listView: DynamicListView, removedCell: DynamicListView.Cell) -> Void
}

extension DynamicListViewDelegate {
    func cellDidAppear(from listView: DynamicListView, cell: DynamicListView.Cell) {}
    func cellDidDisappear(from listView: DynamicListView, cell: DynamicListView.Cell) {}
    func cellDidRemoved(from listView: DynamicListView, removedCell: DynamicListView.Cell) {}
}

// MARK: - DynamicListView

class DynamicListView: UIView {
    struct Cell {
        let item: any DynamicListItem
        let contentView: UIView
        let contentHeight: Double
    }
    
    enum Position {
        case top
        case bottom
        case middle
        case offset(Double)
    }
    
    private let scrollView = UIScrollView()
    
//    override var safeAreaInsets: UIEdgeInsets { .zero }
    
    private var offset: Double {
        set {
            scrollView.setContentOffset(CGPoint(x: 0, y: newValue), animated: false)
        }
        get {
            scrollView.contentOffset.y
        }
    }
    
    private var inset: Double {
        set {
            scrollView.contentInset = UIEdgeInsets(top: newValue, left: 0, bottom: 0, right: 0)
        }
        get {
            scrollView.contentInset.top
        }
    }

    private var contentHeight: Double {
        set {
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: newValue)
        }
        get {
            scrollView.contentSize.height
        }
    }
    
    private var visibleRange: (top: Double, bottom: Double) {
        (offset, offset + bounds.height)
    }
    
    /// Cells that have been rendered in the list view.
    ///
    /// - Note: You should refresh the list to reload the rendered cells.
    public private(set) var renderedCells: [Cell] = []
    
    /// A set to track previously visible cells using theirs hash values.
    private var previouslyVisibleCells: Set<Int> = []
    
    /// Cells closing the visible area in the range will be preloaded.
    var preloadRange: Double = 100
    
    weak var dataSource: DynamicListViewDataSource?
    weak var delegate: DynamicListViewDelegate?
    
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

extension DynamicListView {
    /// The visible cells in the list view.
    public func queryVisibleCells() -> [Cell] {
        let visibleRect = CGRect(x: 0, y: visibleRange.top, width: bounds.width, height: bounds.height)
        return renderedCells.filter { config in
            visibleRect.intersects(config.contentView.frame)
        }
    }
    
    /// Scrolls to the target cell at the specified position in the list view.
    /// - Warning: Not finding the target item will refresh the whole list view.
    func scroll(to targetItem: any DynamicListItem, position: Position = .middle, animated: Bool = true) {
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
            if renderedCell.item.id.hashValue == targetItem.id.hashValue {
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
                if let topItem = dataSource?.listView(listView: self, cellBefore: topSearchItem) {
                    let topCellHeight = fetchCellContentHeight(of: topItem)
                    topOffset -= topCellHeight
                    if topItem.id.hashValue == targetItem.id.hashValue {
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
                if let bottomItem = dataSource?.listView(listView: self, cellAfter: bottomSearchItem) {
                    let bottomCellHeight = fetchCellContentHeight(of: bottomItem)
                    if bottomItem.id.hashValue == targetItem.id.hashValue {
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
    func refreshData(with newItem: any DynamicListItem, replacedItem: any DynamicListItem) {
        if let replacedCell = renderedCells.first(where: { $0.item.id.hashValue == replacedItem.id.hashValue }) {
            refreshData(with: newItem, position: .offset(replacedCell.contentView.frame.minY - offset))
            return
        }
        refreshData(with: newItem, position: .top)
    }
    
    /// Recreates all rendered cells.
    /// - Parameters:
    ///   - beginCell: The first cell you want to render.
    ///   - position: The position of the first cell.
    ///   - interruptAnimation: Defaults of `false`; `true` will interrupt the scrolling animation.
    func refreshData(
        with beginCell: any DynamicListItem,
        position: Position = .middle,
        interruptAnimation: Bool = false
    ) {
        if interruptAnimation {
            offset = self.offset
        }
        
        renderedCells.forEach { $0.contentView.removeFromSuperview() }
        renderedCells.removeAll()
        
        let beginCell = Cell(
            item: beginCell,
            contentView: fetchCellContentView(of: beginCell),
            contentHeight: dataSource?.listView(listView: self, heightOf: beginCell) ?? 0
        )
        
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

// MARK: - UIScrollViewDelegate

extension DynamicListView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        renderContentIfNeeded()
    }
}

extension DynamicListView {
    private func fetchCellContentHeight(of cellItem: any DynamicListItem) -> Double {
        if let cell = renderedCells.first(where: { $0.item.id.hashValue == cellItem.id.hashValue }) {
            return cell.contentHeight
        } else {
            return dataSource?.listView(listView: self, heightOf: cellItem) ?? 40
        }
    }
    
    private func fetchCellContentView(of cellItem: any DynamicListItem) -> UIView {
        if let cell = renderedCells.first(where: { $0.item.id.hashValue == cellItem.id.hashValue }) {
            return cell.contentView
        } else {
            let contentView = dataSource?.listView(listView: self, contentViewOf: cellItem)
            return contentView ?? UIView()
        }
    }
    
    private func makeCell(from cellItem: any DynamicListItem) -> Cell {
        let contentView = dataSource?.listView(listView: self, contentViewOf: cellItem)
        let contentHeight = dataSource?.listView(listView: self, heightOf: cellItem) ?? 0
        return Cell(item: cellItem, contentView: contentView ?? UIView(), contentHeight: contentHeight)
    }
    
    private func renderContentIfNeeded() {
        while true {
            if let topCell = renderedCells.first, topCell.contentView.frame.minY + preloadRange > offset {
                if let nextCellItem = dataSource?.listView(listView: self, cellBefore: topCell.item) {
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
                if let nextCellItem = dataSource?.listView(listView: self, cellAfter: bottomCell.item) {
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
            delegate?.cellDidRemoved(from: self, removedCell: item)
        }
        
        // Detect and notify about appeared and disappeared cells
        let currentVisibleCells = queryVisibleCells()
        let currentVisibleCellIds = Set(currentVisibleCells.map { $0.item.id.hashValue })
        
        // Find cells that just appeared (in current but not in previous)
        let newlyAppearedCells = currentVisibleCells.filter { !previouslyVisibleCells.contains($0.item.id.hashValue) }
        for cell in newlyAppearedCells {
            delegate?.cellDidAppear(from: self, cell: cell)
        }
        
        // Find cells that just disappeared (in previous but not in current)
        let newlyDisappearedCellIds = previouslyVisibleCells.subtracting(currentVisibleCellIds)
        let newlyDisappearedCells = renderedCells.filter { newlyDisappearedCellIds.contains($0.item.id.hashValue) }
        for cell in newlyDisappearedCells {
            delegate?.cellDidDisappear(from: self, cell: cell)
        }
        
        // Update the previously visible cells set
        previouslyVisibleCells = currentVisibleCellIds
    }
}
