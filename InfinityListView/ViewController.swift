//
//  ViewController.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/5.
//

import UIKit

class TestCell: DynamicListItem {
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
//        LOG("deinit cell: \(id)")
    }
    
}

class ViewController: UIViewController {
    
    let listView = DynamicListView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listView.frame = view.bounds
        listView.dataSource = self
        listView.delegate = self
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

extension ViewController: DynamicListViewDataSource {
    func listView(listView: DynamicListView, cellBefore theCell: any DynamicListItem) -> (any DynamicListItem)? {
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
    
    func listView(listView: DynamicListView, cellAfter theCell: any DynamicListItem) -> (any DynamicListItem)? {
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
    
    func listView(listView: DynamicListView, contentViewOf theCell: any DynamicListItem) -> UIView {
        guard let theCell = theCell as? TestCell else {
            return UIView()
        }
        return theCell.contentView
    }
    
    func listView(listView: DynamicListView, heightOf theCell: any DynamicListItem) -> Double {
        guard let theCell = theCell as? TestCell else {
            return 0
        }
        return [100, 150, 200].randomElement() ?? 40
    }
}

extension ViewController: DynamicListViewDelegate {
    func cellDidAppear(from listView: DynamicListView, cell: DynamicListView.Cell) {
        LOG("cell \(cell.item.id) did appear")
    }
    
    func cellDidDisappear(from listView: DynamicListView, cell: DynamicListView.Cell) {
        LOG("cell \(cell.item.id) did disappear")
    }
}
