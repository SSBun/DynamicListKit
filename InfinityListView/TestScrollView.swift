//
//  TestScrollView.swift
//  InfinityListView
//
//  Created by caishilin on 2025/4/6.
//

import UIKit

class TestScrollView: UIView {
    let scrollView = UIScrollView()
    
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
//    override var safeAreaInsets: UIEdgeInsets {
//        .zero
//    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        scrollView.backgroundColor = .gray
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 3000)
        scrollView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)
//        scrollView.showsVerticalScrollIndicator = false
//        scrollView.showsHorizontalScrollIndicator = false
//        scrollView.bounces = false
        scrollView.delegate = self
        
        
        do {
            let testView = UIView()
            testView.backgroundColor = .red
            testView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
            scrollView.addSubview(testView)
        }
        
        do {
            let testView = UIView()
            testView.backgroundColor = .orange
            testView.frame = CGRect(x: 0, y: 1800, width: UIScreen.main.bounds.width, height: 200)
            scrollView.addSubview(testView)
        }
        
        do {
            // add a test button to increate the top inset
            let testButton = UIButton()
            testButton.setTitle("Increase Top Inset", for: .normal)
            testButton.setTitleColor(.blue, for: .normal)
            testButton.backgroundColor = .white
            testButton.frame = CGRect(x: 0, y: 200, width: UIScreen.main.bounds.width, height: 50)
            testButton.addTarget(self, action: #selector(increaseTopInset), for: .touchUpInside)
            addSubview(testButton)
        }
    }
    
    @objc private func increaseTopInset() {
//        let newInset = scrollView.contentInset.top - 1000
//        scrollView.contentInset = UIEdgeInsets(top: newInset, left: 0, bottom: 0, right: 0)
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height - 200)
//        print("New top inset: \(newInset)")
    }
}

extension TestScrollView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
//        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height + 1)
//        scrollView.contentInset = UIEdgeInsets(top: scrollView.contentInset.top - 1, left: 0, bottom: 0, right: 0)
        print("ScrollView did scroll to offset: \(offset)")
        print("ScrollView contentHeight: \(scrollView.contentSize.height)")
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
    }
}
