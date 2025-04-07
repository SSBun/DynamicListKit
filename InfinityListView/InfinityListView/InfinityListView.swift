//
//  InfinityListView.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//


import UIKit
import OSLog

func LOG(_ message: String) {
    let logger = Logger(subsystem: "com.example.infinitylistview", category: "InfinityListView")
    logger.debug("\(message)")
}

protocol InfinityListItem {
    associatedtype ID: Hashable
    var id: ID { get }
}

protocol InfinityListViewDataSource: AnyObject {
    func cellBeforeTheCell(listView: InfinityListView, theCell: any InfinityListItem) -> (any InfinityListItem)?
    func cellAfterTheCell(listView: InfinityListView, theCell: any InfinityListItem) -> (any InfinityListItem)?
    
    func cellContentView(listView: InfinityListView, of theCell: any InfinityListItem) -> UIView
    
    func heightForCell(listView: InfinityListView, theCell: any InfinityListItem) -> Double
}

protocol InfinityListViewDelegate: AnyObject {
    func cellDidAppear(from listView: InfinityListView, cell: InfinityListView.Cell) -> Void
    func cellDidDisappear(from listView: InfinityListView, cell: InfinityListView.Cell) -> Void
    func cellDidRemoved(from listView: InfinityListView, removedCell: InfinityListView.Cell) -> Void
}

extension InfinityListViewDelegate {
    func cellDidAppear(from listView: InfinityListView, cell: InfinityListView.Cell) {}
    func cellDidDisappear(from listView: InfinityListView, cell: InfinityListView.Cell) {}
    func cellDidRemoved(from listView: InfinityListView, removedCell: InfinityListView.Cell) {}
}

class InfinityListView: UIView {
    struct Cell {
        let item: any InfinityListItem
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
    
    override var safeAreaInsets: UIEdgeInsets { .zero }
    
    var offset: Double {
        set {
            LOG("set offset: \(newValue)")
            scrollView.setContentOffset(CGPoint(x: 0, y: newValue), animated: false)
        }
        get {
            scrollView.contentOffset.y
        }
    }
    
    var inset: Double {
        set {
            scrollView.contentInset = UIEdgeInsets(top: newValue, left: 0, bottom: 0, right: 0)
        }
        get {
            scrollView.contentInset.top
        }
    }
    var contentHeight: Double {
        set {
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: newValue)
        }
        get {
            scrollView.contentSize.height
        }
    }
    
    private var visiableRange: (top: Double, bottom: Double) {
        (offset, offset + bounds.height)
    }
    
    private var renderedCells: [Cell] = []
    
    private var buffer: Double =  100
    
    weak var dataSource: InfinityListViewDataSource?
    weak var delegate: InfinityListViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
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
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func fetchVisibleCells() -> [Cell] {
        let visibleRect = CGRect(x: 0, y: visiableRange.top, width: bounds.width, height: bounds.height)
        return renderedCells.filter { config in
            visibleRect.intersects(config.contentView.frame)
        }
    }
    
    func scroll(to targetItem: any InfinityListItem, position: Position = .middle) {
        var targetRect: CGRect?
        
        defer {
            if let targetRect {
                LOG("targetRect: \(targetRect)")
                switch position {
                case .top:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.minY), animated: true)
                case .bottom:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.maxY - bounds.height), animated: true)
                case .middle:
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.midY - bounds.height / 2), animated: true)
                case .offset(let extraOffset):
                    scrollView.setContentOffset(CGPoint(x: 0, y: targetRect.minY + extraOffset), animated: true)
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
        
        while(true) {
            if !topSearchEnd {
                if let topItem = dataSource?.cellBeforeTheCell(listView: self, theCell: topSearchItem) {
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
                if let bottomItem = dataSource?.cellAfterTheCell(listView: self, theCell: bottomSearchItem) {
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
            
            if bottomSearchEnd && topSearchEnd {
                break
            }
        }
    }
    
    func refreshData(with newItem: any InfinityListItem, replacedItem: any InfinityListItem) {
        if let replacedCell = renderedCells.first(where: { $0.item.id.hashValue == replacedItem.id.hashValue }) {
            refreshData(with: newItem, position: .offset(replacedCell.contentView.frame.minY - offset))
            return
        }
        refreshData(with: newItem, position: .top)
    }
    
    func refreshData(
        with beginCell: any InfinityListItem,
        position: Position = .middle,
        interruptAnimation: Bool = false
    ) {
        if interruptAnimation {
            offset = self.offset
        }
        
        renderedCells.forEach { $0.contentView.removeFromSuperview()}
        renderedCells.removeAll()
        
        let beginCell = Cell(
            item: beginCell,
            contentView: fetchCellContentView(of: beginCell),
            contentHeight: dataSource?.heightForCell(listView: self, theCell: beginCell) ?? 0
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
        case .offset(let extraOffset):
            positionFrame = CGRect(x: 0, y: offset + extraOffset, width: self.bounds.width, height: beginCell.contentHeight)
        }
        cellContentView.frame = positionFrame
        scrollView.addSubview(cellContentView)
        renderContentIfNeeded()
    }
    
}

extension InfinityListView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        LOG("scrollView offset: \(scrollView.contentOffset.y)")
//        LOG("scrollView content size: \(scrollView.contentSize.height)")
//        LOG("scrollView inset: \(scrollView.contentInset.top)")
        renderContentIfNeeded()
    }
}

extension InfinityListView {
    func fetchCellContentHeight(of cellItem: any InfinityListItem) -> Double {
        if let cell = renderedCells.first(where: { $0.item.id.hashValue == cellItem.id.hashValue }) {
            return cell.contentHeight
        } else {
            return dataSource?.heightForCell(listView: self, theCell: cellItem) ?? 40
        }
    }
    
    func fetchCellContentView(of cellItem: any InfinityListItem) -> UIView {
        if let cell = renderedCells.first(where: { $0.item.id.hashValue == cellItem.id.hashValue }) {
            return cell.contentView
        } else {
            let contentView = dataSource?.cellContentView(listView: self, of: cellItem)
            return contentView ?? UIView()
        }
    }
    
    func makeCell(from cellItem: any InfinityListItem) -> Cell {
        let contentView = dataSource?.cellContentView(listView: self, of: cellItem)
        let contentHeight = dataSource?.heightForCell(listView: self, theCell: cellItem) ?? 0
        return Cell(item: cellItem, contentView: contentView ?? UIView(), contentHeight: contentHeight)
    }
    
    private func renderContentIfNeeded() {
        while true {
            if let topCell = renderedCells.first, topCell.contentView.frame.minY + buffer > offset {
                if let nextCellItem = dataSource?.cellBeforeTheCell(listView: self, theCell: topCell.item) {
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
//                    LOG("no more top cell")
                    inset = -topCell.contentView.frame.minY
                    break
                }
            } else {
                break
            }
        }
        while true {
            if let bottomCell = renderedCells.last, bottomCell.contentView.frame.maxY - buffer < offset + bounds.height {
                if let nextCellItem = dataSource?.cellAfterTheCell(listView: self, theCell: bottomCell.item) {
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
//                    LOG("no more bottom cell")
                    contentHeight = bottomCell.contentView.frame.maxY
                    break
                }
            } else {
                break
            }
        }
        
        // remove disappearedCells
        var removedCells: [Cell] = []
        renderedCells.removeAll { cellConfig in
            let needRemove = cellConfig.contentView.frame.maxY < visiableRange.top - buffer || cellConfig.contentView.frame.minY > visiableRange.bottom + buffer
            if needRemove {
                cellConfig.contentView.removeFromSuperview()
                removedCells.append(cellConfig)
            }
            return needRemove
        }
        removedCells.forEach {
            delegate?.cellDidRemoved(from: self, removedCell: $0)
        }
    }
}
