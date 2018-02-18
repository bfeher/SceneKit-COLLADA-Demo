//
//  ViewController.swift
//  LNZTreeViewDemo
//
//  Created by Giuseppe Lanza on 07/11/2017.
//  Copyright © 2017 Giuseppe Lanza. All rights reserved.
//

import UIKit
import LNZTreeView
import SnapKit
import SceneKit

class DAEViewController: UIViewController {
    
    var treeView = LNZTreeView(frame:.zero)
    var root:SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildTreeView()

        root  = DataManager.shared.gameVC?.modelScene?.rootNode
        treeView.resetTree()
    }
    
    func buildTreeView(){
        treeView.register(CustomUITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(treeView)
        treeView.delegate = self
        treeView.dataSource = self
        treeView.snp.remakeConstraints { (make) in
            make.width.height.equalToSuperview()
        }
    }
    

}

