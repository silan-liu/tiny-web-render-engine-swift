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
    let selectors: [CSSSelector]
    
    // 声明的属性
    let declarations: [Declaration]
}

enum CSSSelector {
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

extension Value: Equatable {
   
    static func == (lhs: Self, rhs: Self) -> Bool {
        if case .Keyword(let l) = lhs, case .Keyword(let r) = rhs {
            return l == r
        }
        
        
        if case .Color(let lr, let lg, let lb, let la) = lhs, case .Color(let rr, let rg, let rb, let ra) = rhs {
            return lr == rr && lg == rg && lb == rb && la == ra
        }
        
        if case .Length(let l, _) = lhs, case .Length(let r, _) = rhs {
            return l == r
        }
        
        return false
    }

}

enum Unit {
    case Px
}

// 用于选择器排序，优先级从高到低分别是 id, class, tag
typealias Specifity = (Int, Int, Int)

extension CSSSelector {
    public func specificity() -> Specifity {
     
        if case CSSSelector.Simple(let simple) = self {
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

extension Value {
    func toPx() -> Float {
        if case .Length(let len, .Px) = self {
            return len
        }
        
        return 0.0
    }
}

struct CSSParser {
    // 文本扫描辅助
    var sourceHelper: SourceHelper = SourceHelper()
    
    // 对外提供的解析方法，返回样式表
    mutating public func parse(source: String) -> StyleSheet {
        self.sourceHelper.updateInput(input: source)
        
        let rules: [Rule] = parseRules()
        
        return StyleSheet(rules: rules)
    }
    
    // 解析 css 规则
    mutating func parseRules() -> [Rule] {
        var rules:[Rule] = []
        
        // 循环解析规则
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
    /**
     div.class, #id {
        padding: 0px;
        margin: 10px;
     }
     */
    mutating func parseRule() -> Rule {
        let selectors = parseSelectors()
        let declaration = parseDeclarations()
        
        return Rule(selectors: selectors, declarations: declaration)
    }
    
    // 解析组合选择器，选择器以","分隔，返回数组
    // tag.class1.class2, #id
    mutating func parseSelectors() -> [CSSSelector] {
        
        var selectors: [CSSSelector] = []
        
        outerLoop: while true {
            let simpleSelector = parseSimpleSelector()
            
            // 包装成枚举
            let selector = CSSSelector.Simple(simpleSelector)
            
            selectors.append(selector)
            
            // 跳过空行
            self.sourceHelper.consumeWhitespace()
            
            // 判断下一个字符
            let c = self.sourceHelper.nextCharacter()
            
            switch c {
            // 到了属性部分，跳出循环
            case "{":
                break outerLoop
                
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
        
        // 对 selector 进行排序，优先级从高到低
        selectors.sort { (s1, s2) -> Bool in
            s1.specificity() > s2.specificity()
        }
        
        return selectors
    }
    
    // 解析选择器
    // tag#id.class1.class2
    mutating func parseSimpleSelector() -> SimpleSelector {
        var selector = SimpleSelector(tagName: nil, id: nil, classes: [])
        
        outerLoop: while !self.sourceHelper.eof() {
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
            case let c where validIdentifierChar(c: c):
                selector.tagName = parseIdentifier()
                break
                
            case _:
                break outerLoop
            }
        }
        
        return selector
    }
    
    // 解析标识符
    mutating func parseIdentifier() -> String {
        // 字母数字-_
        return self.sourceHelper.consumeWhile(test: validIdentifierChar)
    }
    
    // 解析声明的属性列表
    /**
     {
        margin-top: 10px;
        margin-bottom: 10px
     }
     */
    mutating func parseDeclarations() -> [Declaration] {
        var declarations: [Declaration] = []
        
        // 以 { 开头
        assert(self.sourceHelper.consumeCharacter() == "{")
        
        while true {
            self.sourceHelper.consumeWhitespace()
            
            // 如果遇到 }，说明规则声明结束
            if self.sourceHelper.nextCharacter() == "}" {
                _ = self.sourceHelper.consumeCharacter()
                break
            }
            
            // 解析规则
            let declaration = parseDeclaration()
            declarations.append(declaration)
        }
        
        return declarations
    }
    
    // 解析单个属性，margin-top: 10px;
    mutating func parseDeclaration() -> Declaration {
        let name = parseIdentifier()
        
        // 跳过空白字符
        self.sourceHelper.consumeWhitespace()
        
        assert(self.sourceHelper.consumeCharacter() == ":")
        
        // 跳过空白字符
        self.sourceHelper.consumeWhitespace()

        let value = parseValue()
        
        // 跳过空白字符
        self.sourceHelper.consumeWhitespace()
        
        // 最后应该以 ; 结束
        assert(self.sourceHelper.consumeCharacter() == ";")
        
        return Declaration(name: name, value: value)
    }
    
    // 解析属性值，可能包括色值、长度、普通字符串
    mutating func parseValue() -> Value {
        switch self.sourceHelper.nextCharacter() {
        // 色值
        case "#":
            return parseColor()
            
        // 数字长度
        case let c where c.isNumber:
            return parseLength()
            
        case _:
            // 普通值
            let keyword = parseIdentifier()
            return Value.Keyword(keyword)
        }
    }
    
    // 解析色值，只支持十六进制，以 # 开头, #897722
    mutating func parseColor() -> Value {
        assert(self.sourceHelper.consumeCharacter() == "#")
        
        let r = parseHexPair()
        let g = parseHexPair()
        let b = parseHexPair()
        var a: UInt8 = 255
        
        // 如果有 alpha
        if self.sourceHelper.nextCharacter() != ";" {
            a = parseHexPair()
        }
        
        return Value.Color(r, g, b, a)
    }
    
    mutating func parseHexPair() -> UInt8 {
        // 取出 2 位字符
        let s = self.sourceHelper.consumeNCharacter(count: 2)
            
        // 转化为整数
        let value = UInt8(s, radix: 16) ?? 0
        
        return value
    }
    
    // 解析长度
    mutating func parseLength() -> Value {
        let floatValue = parseFloat()
        let unit = parseUnit()
        
        return Value.Length(floatValue, unit)
    }
    
    // 解析浮点数
    mutating func parseFloat() -> Float {
        let s = self.sourceHelper.consumeWhile { (c) -> Bool in
            c.isNumber || c == "."
        }
        
        let floatValue = (s as NSString).floatValue
        return floatValue
    }
    
    // 解析单位
    mutating func parseUnit() -> Unit {
        let unit = parseIdentifier()
        if unit == "px" {
            return Unit.Px
        }
        
        assert(false, "Unexpected unit")
    }
    
    // 有效标识，数字、字母、_-
    func validIdentifierChar(c: Character) -> Bool {
        if c.isNumber || c.isLetter || c == "-" || c == "_" {
            return true
        }
        
        return false
    }
}
