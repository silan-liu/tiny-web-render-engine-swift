//
//  Painting.swift
//  TinyRenderEngine
//
//  Created by liusilan on 2021/4/16.
//

import Foundation

// argb
typealias Color = (UInt8, UInt8, UInt8, UInt8)

// 画布
struct Canvas {
    var width: Int
    var height: Int
    
    // 像素点
    var pixels: [Color]
}

// 绘制命令，目前只支持颜色绘制
enum DisplayCommand {
    case SolidColor(Color, Rect)
}

extension Canvas {
    init(width: Int, height: Int) {
        
        self.width = width
        self.height = height
        
        // 默认白色
        let defaultColor: Color = (255, 255, 255, 255)
        
        pixels = Array(repeating: defaultColor, count: width * height)
    }
    
    // 绘制元素，生成像素点
    mutating func paintItem(item: DisplayCommand) {
        switch item {
        case .SolidColor(let color, let rect):
            genPixel(color: color, rect: rect)
            break
        }
    }
    
    // 生成像素点
    mutating func genPixel(color: Color, rect: Rect) {
        // 将 rect 范围内的点填充为 color，不能超过画布大小
        let x0 = Int(rect.x.clamp(min: 0, max: Float(self.width)))
        let y0 = Int(rect.y.clamp(min: 0, max: Float(self.height)))

        let x1 = Int((rect.x + rect.width).clamp(min: 0, max: Float(self.width)))
        let y1 = Int((rect.y + rect.height).clamp(min: 0, max: Float(self.height)))
        
        // 遍历所有点，横向一行行填充
        for y in y0...y1  {
            for x in x0...x1 {
                let index = y * width + x
                pixels[index] = color
            }
        }
    }
}

extension Float {
    // 获取范围内的值
    func clamp(min: Float, max: Float) -> Float {
        var result = self
        if (result < min) {
            result = min
        }
        
        if (result > max) {
            result = max
        }
        
        return result
    }
}

// 绘制处理器
struct PaintingProcessor {
    // 处理绘制命令，转换为像素点
    func paint(layoutRoot: LayoutBox, bounds: Rect) -> Canvas {
        
        // 生成画布
        var canvas = Canvas(width: Int(bounds.width), height: Int(bounds.height))
        
        // 绘制命令列表
        let list = buildDisplayList(layoutRoot: layoutRoot)
        
        // 生成像素点
        for displayCommand in list {
            canvas.paintItem(item: displayCommand)
        }
        
        return canvas
    }
    
    // 生成总体绘制列表
    func buildDisplayList(layoutRoot: LayoutBox) -> [DisplayCommand] {
        var list: [DisplayCommand] = []
        
        renderLayoutBox(list: &list, layoutBox: layoutRoot)
        
        return list
    }
    
    func renderLayoutBox(list: inout [DisplayCommand], layoutBox: LayoutBox) {
        // 绘制背景
        renderBackground(list: &list, layoutBox: layoutBox)
        
        // 绘制边框
        renderBorder(list: &list, layoutBox: layoutBox)

        // 遍历子节点，递归生成命令
        for child in layoutBox.children {
            renderLayoutBox(list: &list, layoutBox: child)
        }
    }
    
    // 绘制背景
    func renderBackground(list: inout [DisplayCommand], layoutBox: LayoutBox) {
        // 获取背景色
        if let color = getColor(layoutBox: layoutBox, name: "background") {
            
            // 背景包括 padding + border + content
            let displayCommand = DisplayCommand.SolidColor(color, layoutBox.dimensions.borderBox())
            
            list.append(displayCommand)
        }
    }
    
    // 绘制边框，分为 4 个区域，上下左右
    func renderBorder(list: inout [DisplayCommand], layoutBox: LayoutBox) {
        if let color = getColor(layoutBox: layoutBox, name: "border-color") {
            let d = layoutBox.dimensions
            let borderBox = d.borderBox()
            
            // 左边框
            let leftRect = Rect(x: borderBox.x, y: borderBox.y, width: d.border.left, height: borderBox.height)
            
            let leftDisplayCommand = DisplayCommand.SolidColor(color, leftRect)
            list.append(leftDisplayCommand)
            
            // 右边框
            let rightRect = Rect(x: borderBox.x + borderBox.width - d.border.right, y: borderBox.y, width: d.border.right, height: borderBox.height)
            
            let rightDisplayCommand = DisplayCommand.SolidColor(color, rightRect)
            list.append(rightDisplayCommand)
            
            // 上边框
            let topRect = Rect(x: borderBox.x, y: borderBox.y, width: borderBox.width, height: d.border.top)
            
            let topDisplayCommand = DisplayCommand.SolidColor(color, topRect)
            list.append(topDisplayCommand)
            
            // 下边框
            let bottomRect = Rect(x: borderBox.x, y: borderBox.y + borderBox.height - d.border.bottom, width: borderBox.width, height: d.border.bottom)
            
            let bottomDisplayCommand = DisplayCommand.SolidColor(color, bottomRect)
            list.append(bottomDisplayCommand)
        }
    }
    
    // 获取属性色值
    func getColor(layoutBox: LayoutBox, name: String) -> Color? {
        let boxType = layoutBox.boxType
        
        switch boxType {
        
        case .BlockNode(let node), .InlineNode(let node):
            
            let value = node.getValue(name: name)
            
            // 值为颜色
            switch value {
            case .Color(let r, let g, let b, let a):
                return Color(a, r, g, b)
            default:
                return nil
            }

        case .AnonymousBlock:
            return nil
        }
    }
}
