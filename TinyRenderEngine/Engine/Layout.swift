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
    
    // 根据父容器宽度计算节点 x 方向的布局数据，包括 width/margin/border/padding
    func calculateBlockWidth(containingBlock: Dimensions) {
       
        let result = getStyleNode()
        
        guard let styleNode = result else {
            return
        }
        
        // css 中 auto 表示由浏览器自己计算一个值。
        // 当 width 为 auto 时，表示假若在有边距的情况下，尽可能的将自身宽度设置为父容器的宽度。
        // 当 margin 为 auto 时，表示浏览器选择一个合适的边距。
        let auto = Value.Keyword("auto")
        
        var width = styleNode.getValue(name: "width") ?? auto
        
        let zero = Value.Length(0.0, .Px)
        
        // margin
        var marginLeft = styleNode.lookup(name: "margin-left", fallbackName: "margin", defaultValue: zero)
        var marginRight = styleNode.lookup(name: "margin-right", fallbackName: "margin", defaultValue: zero)

        // border
        let borderLeft = styleNode.lookup(name: "border-left-width", fallbackName: "border-width", defaultValue: zero);
        let borderRight = styleNode.lookup(name: "border-right-width", fallbackName: "border-width", defaultValue: zero);
        
        // padding
        let paddingLeft = styleNode.lookup(name: "padding-left", fallbackName: "padding", defaultValue: zero);
        let paddingRight = styleNode.lookup(name: "padding-right", fallbackName: "padding", defaultValue: zero);
        
        // 计算总和，所有边距+宽度
        let totalWidth = marginLeft.toPx() + marginRight.toPx() + borderLeft.toPx() + borderRight.toPx() + paddingLeft.toPx() + paddingRight.toPx() + width.toPx()
        
        // 宽度非 auto
        if (width != auto) {
            // 整体宽度大于父容器宽度，修改 margin-left，margin-right 值
            if totalWidth > containingBlock.content.width {
                if marginLeft == auto {
                    marginLeft = .Length(0.0, .Px)
                }
                
                if marginRight == auto {
                    marginRight = .Length(0.0, .Px)
                }
            }
        }
        
        // 宽度与父容器宽度有差，根据情况调整 margin-left/margin-right/width 的值
        let underflow = containingBlock.content.width - totalWidth
        
        // 是否为 auto
        let autoWidth = (width == auto)
        let autoMarginLeft = (marginLeft == auto)
        let autoMarginRight = (marginRight == auto)
        
        // 宽度非 auto
        if (!autoWidth) {
            
            // marginLeft 为 auto
            if (autoMarginLeft) {
                
                // marginRight 为 auto
                if (autoMarginRight) {
                    
                    // margin-left、margin-right 都为 auto。在 totalWidth 不占空间，平分空间
                    marginLeft = .Length(underflow / 2.0, .Px)
                    marginRight = .Length(underflow / 2.0, .Px)
                    
                } else {
                    // 只有 margin-left 为 auto, 在 totalWidth 不占空间，设置为剩余空间
                    marginLeft = .Length(underflow, .Px)
                }
            } else {
                if (autoMarginRight) {
                    // margin-right 为 auto，在 totalWidth 不占空间，设置为剩余空间
                    marginRight = .Length(underflow, .Px)
                } else {
                    // 修改 margin-right
                    marginRight = .Length(marginRight.toPx() + underflow, .Px)
                }
            }
        } else {
            // 宽度是 auto，此时 width.to_px 的值其实是 0，在 totalWidth 不占空间。
            // 这种情况下，尽可能让 width 贴近父容器宽度
            
            // 若 marginLeft 为 auto，在 totalWidth 不占空间。调整至 0
            if autoMarginLeft {
                marginLeft = .Length(0.0, .Px)
            }
            
            // marginRight 为 auto，在 totalWidth 不占空间。调整至 0
            if autoMarginRight {
                marginRight = .Length(0.0, .Px)
            }
            
            // 小于父容器宽度
            if underflow >= 0.0 {
                // 设置为相差值
                width = .Length(underflow, .Px)
            } else {
                // 超出宽度，减小 margin-right。由于此时 width 不能为负值，设置为 0
                width = .Length(0.0, .Px)
                marginRight = .Length(marginRight.toPx() + underflow, .Px)
            }
        }
        
        // 设置盒子模型数据
        var d = self.dimensions
        d.content.width = width.toPx()
        
        d.padding.left = paddingLeft.toPx()
        d.padding.right = paddingRight.toPx()
        
        d.border.left = borderLeft.toPx()
        d.border.right = borderRight.toPx()
        
        d.margin.left = marginLeft.toPx()
        d.margin.right = marginRight.toPx()
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
            
            // 如果已经是匿名 block，不做处理，稍后返回
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
