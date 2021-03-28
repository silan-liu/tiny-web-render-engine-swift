//
//  CSSParser.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/28.
//

import Foundation

// 样式表，最终产物
struct StyleSheet {
    let rules: [Rule]
}

// css 规则结构定义
struct Rule {
    // 选择器
    let selectors: [Selector]
    
    // 声明的属性
    let declarations: [Declaration]
}

enum Selector {
    case Simple(SimpleSelector)
}

struct SimpleSelector {
    // 标签名
    let tagName: String?
    
    // id
    let id: String?
    
    // class
    let classes: [String]
}

struct Declaration {
    let name: String
    let value: Value
}

enum Value {
    case Keyword(String)
    
    // rgba
    case Color(UInt8, UInt8, UInt8, UInt8)
    
    // 长度
    case Length(Float, Unit)
}

enum Unit {
    case Px
}

// 用于选择器排序，优先级从高到低分别是 id, class, tag
typealias Specifity = (Int, Int, Int)

extension Selector {
    public func specificity() -> Specifity {
     
        if case Selector.Simple(let simple) = self {
            // 存在 id
            let a = simple.id == nil ? 0 : 1
            
            // class 个数
            let b = simple.classes.count
            
            // 存在 tag
            let c = simple.tagName == nil ? 0 : 1
            
            return Specifity(a, b, c)
        }
        
        return Specifity(0, 0, 0)
    }
}

struct CSSParser {
    // 文本扫描辅助
    var sourceHelper: SourceHelper = SourceHelper()
    
    
}
