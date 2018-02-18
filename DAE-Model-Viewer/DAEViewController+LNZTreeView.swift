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


extension SCNNode:  TreeNodeProtocol {
    public var identifier: String {
        return debugDescription
    }
    

    public var isExpandable: Bool {
        return childNodes.count > 0
    }

    
}

extension DAEViewController: LNZTreeViewDataSource {
    func numberOfSections(in treeView: LNZTreeView) -> Int {
        return 1
    }
    
    func treeView(_ treeView: LNZTreeView, numberOfRowsInSection section: Int, forParentNode parentNode: TreeNodeProtocol?) -> Int {
        guard let parent = parentNode as? SCNNode else {
            return root!.childNodes.count
        }
        
 
        return parent.childNodes.count
    }
    
    func treeView(_ treeView: LNZTreeView, nodeForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> TreeNodeProtocol {
        guard let parent = parentNode as? SCNNode else {
            return root!.childNodes[indexPath.row]
        }

        return parent.childNodes[indexPath.row]
    }
    
    func treeView(_ treeView: LNZTreeView, cellForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?, isExpanded: Bool) -> UITableViewCell {
        let cell = treeView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var node: SCNNode!
        if let parent = parentNode as? SCNNode {
            node = parent.childNodes[indexPath.row]
        } else {
            node =  root!.childNodes[indexPath.row]
        }
        
        if node.isExpandable {
            if isExpanded {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator_open")
            } else {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator")
            }
        } else {
            cell.imageView?.image = nil
        }
        
        cell.textLabel?.text = node.identifier
        
        return cell
    }
}


extension DAEViewController: LNZTreeViewDelegate {
    func treeView(_ treeView: LNZTreeView, didExpandNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?){
       
        
    }
 
    func treeView(_ treeView: LNZTreeView, didCollapseNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?){
        
    }

    func treeView(_ treeView: LNZTreeView, didSelectNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?){
        print("TODO - toggle visibility parentNode",parentNode ?? "")
        guard let parent = parentNode as? SCNNode else {
            return
        }
        parent.isHidden = !parent.isHidden
    }
}
