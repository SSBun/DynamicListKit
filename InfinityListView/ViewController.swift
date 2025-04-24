//
//  ViewController.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//

import UIKit

// MARK: - TestItem

struct TestItem: DynamicIdentifiable {
    let contentHeight: Double = 100
    var identifier: String { "\(id)" }
    let id: Int
    
    init(_ id: Int) {
        self.id = id
    }
}

// MARK: - TestCell

class TestCell: UILabel {
    override class var reusableIdentifier: String? { "TestCell" }
    
    var index: String = "" {
        didSet {
            text = index
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.textColor = .black
        self.textAlignment = .center
        self.backgroundColor = .gray
        self.font = .systemFont(ofSize: 30, weight: .bold)
        
        // random background color
        let red = CGFloat.random(in: 0 ... 1)
        let green = CGFloat.random(in: 0 ... 1)
        let blue = CGFloat.random(in: 0 ... 1)
        self.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LOG("test cell deinit")
    }
}

// MARK: - UIView + DynamicListReusableView

extension UIView: DynamicListReusable {
    public class var reusableIdentifier: Identifier? {
        "UIView"
    }
}

// MARK: - ViewController

// extension TestCell: DynamicListReusableView {
//    
// }

extension Int: DynamicIdentifiable {
    public var identifier: String {
        "\(self)"
    }
}

class ViewController: UIViewController {
    let listView = DynamicListView()
    
    let linkedMap: DynamicLinkedMap = .init((0...30).map(TestItem.init))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listView.frame = view.bounds
        listView.dataSource = self
//        listView.delegate = self
        view.addSubview(listView)
        
        listView.registerReusableCell(TestCell.self, builder: TestCell.init)
        
        listView.reloadList(with: TestItem(15), position: .top)
        
        // add a test button to scroll the list view to a specific item
        do {
            let button = UIButton(type: .system)
            button.setTitle("Scroll to 15", for: .normal)
            button.addTarget(self, action: #selector(scrollTo15), for: .touchUpInside)
            button.frame = CGRect(x: 20, y: 40, width: 200, height: 50)
            view.addSubview(button)
        }
    }

    var localId: Int = 31
    @objc private func scrollTo15() {
        let cell = TestItem(15)
//        listView.scroll(to: cell, position: .bottom, animated: false)
//        UIView.animate(withDuration: 0.5) {
//        linkedMap.append(cell)
//        listView.scroll(to: cell, position: .bottom)
            self.listView.reloadList(with: cell, replacedItem: cell, keepOriginalCells: true)
//        }
//        localId += 1
    }
}

// MARK: - DynamicListViewDataSource

var cellHeight: Double = 100

extension ViewController: DynamicListViewDataSource {
    func dynamicListView(_ listView: DynamicListView, itemBefore theCell: any DynamicIdentifiable) -> (any DynamicIdentifiable)? {
        linkedMap.previousItem(for: theCell.identifier)
    }
    
    func dynamicListView(_ listView: DynamicListView, itemAfter theCell: any DynamicIdentifiable) -> (any DynamicIdentifiable)? {
        linkedMap.nextItem(for: theCell.identifier)
    }
    
    func dynamicListView(_ listView: DynamicListView, cellFor theCell: any DynamicIdentifiable) -> DynamicListCell {
        LOG("fetch cell content: \(theCell.identifier)")
        guard let testCell = listView.dequeueReusableCell(TestCell.self) else {
            return UIView()
        }
        testCell.index = theCell.identifier
        return testCell
    }
    
    func dynamicListView(_ listView: DynamicListView, heightFor theCell: any DynamicIdentifiable) -> Double {
        if theCell.identifier == "15" {
            defer {
                cellHeight += 20
            }
            return cellHeight
        } else {
            return 100
        }
    }
}
