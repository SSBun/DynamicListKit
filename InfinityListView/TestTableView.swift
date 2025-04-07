//
//  TestTableView.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/6.
//

import UIKit

class TestTableView: UIView {
    private let tableView = UITableView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        tableView.frame = bounds
        tableView.backgroundColor = .white
        addSubview(tableView)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        
        do {
            // a button scroll to bottom
            let button = UIButton(type: .system)
            button.setTitle("Scroll to bottom", for: .normal)
            button.addTarget(self, action: #selector(scrollToBottom), for: .touchUpInside)
            button.frame = CGRect(x: 20, y: 40, width: 200, height: 50)
            addSubview(button)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }
    
    @objc private func scrollToBottom() {
        let indexPath = IndexPath(row: 99, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}


extension TestTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        LOG("cellForRowAt: \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }
}

extension TestTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
