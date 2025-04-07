//
//  ViewController.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//

import UIKit

class TestCell: InfinityListItem {
    let contentView: UIView
    let contentHeight: Double = 100
    let id: Int
    
    init(_ index: Int) {
        self.id = index
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.backgroundColor = .gray
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.text = "\(index)"
        contentView = label
        do {
            // renadom background color
            let red = CGFloat.random(in: 0...1)
            let green = CGFloat.random(in: 0...1)
            let blue = CGFloat.random(in: 0...1)
            label.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }
    
    deinit {
        LOG("deinit cell: \(id)")
    }
    
}

class ViewController: UIViewController {
    
    let listView = InfinityListView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listView.frame = view.bounds
        listView.dataSource = self
        view.addSubview(listView)
        
        listView.refreshData(with: TestCell(15), position: .top)
        
//        do {
//            let testView = TestTableView()
//            testView.frame = view.bounds
//            view.addSubview(testView)
//        }
        
        // add a test button to scroll the list view to a specific item
        do {
            let button = UIButton(type: .system)
            button.setTitle("Scroll to 15", for: .normal)
            button.addTarget(self, action: #selector(scrollTo15), for: .touchUpInside)
            button.frame = CGRect(x: 20, y: 40, width: 200, height: 50)
            view.addSubview(button)
        }
    }

    @objc private func scrollTo15() {
        let cell = TestCell(15)
//        listView.scroll(to: cell, position: .bottom)
        listView.refreshData(with: cell, replacedItem: cell)
    }
}

extension ViewController: InfinityListViewDataSource {
    func cellBeforeTheCell(listView: InfinityListView, theCell: any InfinityListItem) -> (any InfinityListItem)? {
        guard let theCell = theCell as? TestCell else {
            return nil
        }
        let newIndex = theCell.id - 1
        if newIndex >= 0 {
            return TestCell(newIndex)
        } else {
            return nil
        }
    }
    
    func cellAfterTheCell(listView: InfinityListView, theCell: any InfinityListItem) -> (any InfinityListItem)? {
        guard let theCell = theCell as? TestCell else {
            return nil
        }
        let newIndex = theCell.id + 1
        if newIndex < 30 {
            return TestCell(newIndex)
        } else {
            return nil
        }
    }
    
    func cellContentView(listView: InfinityListView, of theCell: any InfinityListItem) -> UIView {
        guard let theCell = theCell as? TestCell else {
            return UIView()
        }
        return theCell.contentView
    }
    
    func heightForCell(listView: InfinityListView, theCell: any InfinityListItem) -> Double {
        guard let theCell = theCell as? TestCell else {
            return 0
        }
        return theCell.contentHeight
    }
}
