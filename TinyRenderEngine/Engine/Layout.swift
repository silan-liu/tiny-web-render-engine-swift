//
//  Layout.swift
//  TinyRenderEngine
//
//  Created by liusilan on 2021/4/13.
//

import Foundation

enum BoxType {
    case AnonymousBlock
    case BlockNode(StyleNode)
    case InlineNode(StyleNode)
}

struct Rect {
    var x: Double = 0.0
    var y: Double = 0.0
    var width: Double = 0.0
    var height: Double = 0.0
}

struct EdgeSizes {
    var left: Double = 0.0
    var right: Double = 0.0
    var top: Double = 0.0
    var bottom: Double = 0.0
}

struct Dimensions {
    // 内容区
    var content: Rect = Rect()
    
    // 内边距
    var padding: EdgeSizes = EdgeSizes()
    
    // 外边距
    var margin: EdgeSizes = EdgeSizes()
    
    // 边框
    var border: EdgeSizes = EdgeSizes()
}

// 布局树
struct LayoutBox {
    
    // 布局描述
    var dimensions: Dimensions
    
    // 类型
    var boxType: BoxType
    
    // 子节点布局
    var children: [LayoutBox]
    
    init(boxType: BoxType) {
        
        self.boxType = boxType
        self.children = []
        self.dimensions = Dimensions()
    }
    
    init(styleNode: StyleNode) {
        
        let display = styleNode.getDisplay()
        
        var boxType: BoxType = .AnonymousBlock
        
        switch display {
        
        case .Inline:
            boxType = .InlineNode(styleNode)
            break
            
        case .Block:
            boxType = .BlockNode(styleNode)
            break
            
        case .None:
            assert(false, "Root node has display: none")
        }
        
        self.init(boxType: boxType)
    }
    
    // 获取节点样式
    func getStyleNode() -> StyleNode? {
        switch self.boxType {
        
        case .BlockNode(let node):
            return node
            
        case .InlineNode(let node):
            return node
            
        default:
            assert(false, "AnonymousBlock block box has no style node!")
            return nil
        }
    }
}

extension LayoutBox {
    // 获取 inline 节点的容器。如果 block 包含一个 inline 节点，它会创建一个匿名 block 来包裹该 inline
    mutating func getInlineContainer() -> LayoutBox {
        
        switch self.boxType {
        
        case .AnonymousBlock:
            return self
            
        case .InlineNode(_):
            return self
            
        case .BlockNode(_):
            let lastChild = self.children.last
            
            // 如果已经是匿名 block，不做处理
            if case .AnonymousBlock = lastChild?.boxType  {
                
            } else {
                // 生成匿名 block
                let anonymousBlock = LayoutBox(boxType: .AnonymousBlock)
                self.children.append(anonymousBlock)
            }
            
            // 返回最后子节点
            return self.children.last!
        }
    }
}

struct LayoutProcessor {
    // 生成布局树
    func genLayoutTree(styleNode: StyleNode, containingBlock: Dimensions) -> LayoutBox {
        var rootBox = buildLayoutBox(styleNode: styleNode)
        
        // 布局
        
        return rootBox
    }
    
    // 递归确定每个节点的 display 数据
    func buildLayoutBox(styleNode: StyleNode) -> LayoutBox {
        let root = LayoutBox(styleNode: styleNode)
        
        return root
    }
    
    
}
