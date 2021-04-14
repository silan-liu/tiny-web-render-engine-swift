//
//  Layout.swift
//  TinyRenderEngine
//
//  Created by liusilan on 2021/4/13.
//

import Foundation

// 布局类型
enum BoxType {
    case AnonymousBlock
    case BlockNode(StyleNode)
    case InlineNode(StyleNode)
}

struct Rect {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
}

// 边距定义
struct EdgeSizes {
    var left: Float = 0.0
    var right: Float = 0.0
    var top: Float = 0.0
    var bottom: Float = 0.0
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

extension Rect {
    // 向外扩展边距
    func expandBy(edge: EdgeSizes) -> Rect {
        return Rect(x: x - edge.left, y: y - edge.top, width: width + edge.left + edge.right, height: height + edge.top + edge.bottom)
    }
}

extension Dimensions {
    func paddingBox() -> Rect {
        return content.expandBy(edge: padding)
    }
    
    func borderBox() -> Rect {
        return paddingBox().expandBy(edge: border)
    }
    
    func marginBox() -> Rect {
        return borderBox().expandBy(edge: margin)
    }
}

// 布局树
struct LayoutBox {
    
    // 布局描述
    var dimensions: Dimensions
    
    // 类型
    var boxType: BoxType
    
    // 子节点布局
    var children: [LayoutBox]
}

extension LayoutBox {
    init(boxType: BoxType) {
        
        self.boxType = boxType
        self.children = []
        self.dimensions = Dimensions()
    }
    
    init(styleNode: StyleNode) {
        
        // 根据设定的 display 属性，返回对应的布局类型
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
    
    // 布局，只有 block 类型才进行布局
    mutating func layout(containingBlock: Dimensions) {
        
        switch self.boxType {
        
        case .BlockNode(_):
            layoutBlock(containingBlock: containingBlock)
            break
            
        default:
            break;
        }
    }
    
    // 计算 block 的布局
   mutating func layoutBlock(containingBlock: Dimensions) {
        // 计算宽度
        calculateBlockWidth(containingBlock: containingBlock)
        
        // 计算位置
        calculateBlockPosition(containingBlock: containingBlock)
        
        // 计算子节点布局
        layoutBlockChildren()
        
        // 根据所有子节点计算高度
        calculateBlockHeight()
    }
    
    // 计算宽度
    func calculateBlockWidth(containingBlock: Dimensions) {
        
    }
    
    // 计算位置
    func calculateBlockPosition(containingBlock: Dimensions) {
        // 计算 x，y，竖直方向间距
        if let styleNode = getStyleNode() {
            var d = self.dimensions
            
            let zero = Value.Length(0.0, .Px)
            
            // margin 竖直方向
            d.margin.top = styleNode.lookup(name: "margin-top", fallbackName: "margin", defaultValue: zero).toPx()
            d.margin.bottom = styleNode.lookup(name: "margin-bottom", fallbackName: "margin", defaultValue: zero).toPx()
            
            // padding 竖直方向
            d.padding.top = styleNode.lookup(name: "padding-top", fallbackName: "padding", defaultValue: zero).toPx()
            d.padding.bottom = styleNode.lookup(name: "padding-bottom", fallbackName: "padding", defaultValue: zero).toPx()
            
            // border 竖直方向
            d.border.top = styleNode.lookup(name: "border-top-width", fallbackName: "border-width", defaultValue: zero).toPx()
            d.border.bottom = styleNode.lookup(name: "border-bottom-width", fallbackName: "border-width", defaultValue: zero).toPx()
            
            // 子节点的 x = 父容器 x + margin + border + padding
            d.content.x = containingBlock.content.x + d.margin.left + d.border.left + d.padding.left
            
            // 子节点 y
            // 现在父容器的高度 = 所有子节点高度之和（包括所有边距），在计算 layoutBlockChildren 子节点布局时会更新父容器高度
            d.content.y = containingBlock.content.y + containingBlock.content.height + d.margin.top + d.border.top + d.padding.top
        }
    }
    
    // 计算子节点布局
    mutating func layoutBlockChildren() {
        for var child in self.children {
            child.layout(containingBlock: self.dimensions)
            
            // 计算整体高度
            self.dimensions.content.height += child.dimensions.marginBox().height
        }
    }
    
    // 如果设置了 height，则取该值
    mutating func calculateBlockHeight() {
        
        if let styleNode = getStyleNode() {
            // 获取设置的 height
            if let heightValue = styleNode.getValue(name: "height") {
                
                if case Value.Length(let height, .Px) = heightValue {
                    self.dimensions.content.height = height
                }
            }
        }
    }

    // 获取 inline 节点的容器。如果 block 包含一个 inline 节点，它会创建一个匿名 block 来包裹该 inline
    mutating func getInlineContainer() -> LayoutBox {
        
        switch self.boxType {
        
        case .AnonymousBlock:
            return self
            
        case .InlineNode(_):
            return self
            
        case .BlockNode(_):
            // 取出最后一个子节点
            let lastChild = self.children.last
            
            // 如果已经是匿名 block，不做处理
            if case .AnonymousBlock = lastChild?.boxType  {
                
            } else {
                // 生成匿名 block
                let anonymousBlock = LayoutBox(boxType: .AnonymousBlock)
                
                // 添加匿名 block
                self.children.append(anonymousBlock)
            }
            
            // 返回最后子节点
            return self.children.last!
        }
    }
}

// 布局处理器
struct LayoutProcessor {
    // 生成布局树
    mutating func genLayoutTree(styleNode: StyleNode, containingBlock: Dimensions) -> LayoutBox {
        var rootBox = buildLayoutBox(styleNode: styleNode)
       
        // 布局
        rootBox.layout(containingBlock: containingBlock)
        
        return rootBox
    }
    
    // 递归确定每个节点的 display 数据
    mutating func buildLayoutBox(styleNode: StyleNode) -> LayoutBox {
        var root = LayoutBox(styleNode: styleNode)
        
        for child in styleNode.children {
            switch child.getDisplay() {
            
            case .Block:
                let childLayoutBox = buildLayoutBox(styleNode: child)
                root.children.append(childLayoutBox)
                break
                
            case .Inline:
                let childLayoutBox = buildLayoutBox(styleNode: child)
                
                // 找到 container
                var container = root.getInlineContainer()
                container.children.append(childLayoutBox)
                break
                
            default:
                break
            }
        }
        
        return root
    }
}
