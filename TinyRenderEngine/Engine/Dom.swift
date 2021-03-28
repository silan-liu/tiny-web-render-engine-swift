//
//  Dom.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/26.
//

import Foundation

// 节点
public struct Node {
    // 子节点
    public let children: [Node]
    
    // 节点类型
    public let nodeType: NodeType
}

// 节点类型
public enum NodeType {
    case Element(ElementData)
    case Text(String)
}

public typealias AttrMap = [String:String]

// 标签元素结构
public struct ElementData {
    // 标签名
    public let tagName: String
    
    // 属性
    public let attributes: AttrMap
}

extension Node {
    // 初始化文本节点
    public init(data: String) {
        self.children = []
        self.nodeType = NodeType.Text(data)
    }
    
    // 初始化元素接节点
    public init(tagName: String, attributes: AttrMap, children: [Node]) {
        let elementData = ElementData(tagName: tagName, attributes: attributes)
        self.nodeType = NodeType.Element(elementData)
        self.children = children
    }
}

extension ElementData {
    func getId() -> String {
        return self.attributes["id"] ?? ""
    }
    
    func getClasses() -> [String] {
        if let classes = self.attributes["classes"] {
            
            let classList = classes.split(separator: " ")
            
            return classList.map { (str) -> String in
                String(str)
            }
        }
        
        return []
    }
}
