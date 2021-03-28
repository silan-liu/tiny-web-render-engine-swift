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
    var tagName: String?
    
    // id
    var id: String?
    
    // class
    var classes: [String]
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
    
    // 对外提供的解析方法
    mutating public func parse(source: String) -> StyleSheet {
        self.sourceHelper.updateInput(input: source)
        
        let rules: [Rule] = parseRules()
        return StyleSheet(rules: rules)
    }
    
    // 解析 css 规则
    mutating func parseRules() -> [Rule] {
        var rules:[Rule] = []
        
        while true {
            self.sourceHelper.consumeWhitespace()
            if self.sourceHelper.eof() {
                break
            }
            
            let rule = parseRule()
            rules.append(rule)
        }
        return rules
    }
    
    // 解析单条规则
    mutating func parseRule() -> Rule {
        let selectors = parseSelectors()
        let declaration = parseDeclarations()
        
        return Rule(selectors: selectors, declarations: declaration)
    }
    
    // 解析组合选择器，选择器以","分隔，返回数组
    // tag.class1.class2, #id
    mutating func parseSelectors() -> [Selector] {
        var selectors: [Selector] = []
        while true {
            let simpleSelector = parseSimpleSelector()
            
            // 包装成枚举
            let selector = Selector.Simple(simpleSelector)
            
            selectors.append(selector)
            
            // 跳过空行
            self.sourceHelper.consumeWhitespace()
            let c = self.sourceHelper.nextCharacter()
            
            switch c {
            // 到了属性部分，跳出循环
            case "{":
                break
                
            case ",":
                // 消耗掉当前 , 号
                _ = self.sourceHelper.consumeCharacter()
                
                // 跳过空白字符，继续循环
                self.sourceHelper.consumeWhitespace()
                
                break

            case _:
                print("Unexpected char \(c) in selector list!")
                break
            }
        }
    }
    
    // 解析选择器
    // tag#id.class1.class2
    mutating func parseSimpleSelector() -> SimpleSelector {
        var selector = SimpleSelector(tagName: nil, id: nil, classes: [])
        
        while !self.sourceHelper.eof() {
            switch self.sourceHelper.nextCharacter() {
            // id
            case "#":
                _ = self.sourceHelper.consumeCharacter()
                selector.id = self.parseIdentifier()
                break
                
            // class
            case ".":
                _ = self.sourceHelper.consumeCharacter()
                let cls = parseIdentifier()
                selector.classes.append(cls)
                break
                
            // 通配符，selector 中无需数据，可任意匹配
            case "*":
                _ = self.sourceHelper.consumeCharacter()
                break
                
            // tag
            case let c where valideIdentifierChar(c: c):
                selector.tagName = parseIdentifier()
                break
                
            case _:
                break
            }
        }
        
        return selector
    }
    
    // 解析标识符
    mutating func parseIdentifier() -> String {
        // 字母数字-_
        return self.sourceHelper.consumeWhile(test: valideIdentifierChar)
    }
    
    mutating func parseDeclarations() -> [Declaration] {
        var declarations: [Declaration] = []
        
        return declarations
    }
    
    // 有效标识，数字、字母、_-
    func valideIdentifierChar(c: Character) -> Bool {
        if c.isNumber || c.isLetter || c == "-" || c == "_" {
            return true
        }
        
        return false
    }
}
