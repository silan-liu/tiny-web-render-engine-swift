//
//  Style.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/28.
//

import Foundation

// 样式 map
typealias StyleMap = [String: Value]

struct StyleNode {
    // 节点
    var node: Node
    
    // 关联的样式
    var styleMap: StyleMap
    
    var children: [StyleNode]
}

// Specifity 同样用于排序
typealias MatchedRule = (Specifity, Rule)

// display
enum Display {
    case Block
    case Inline
    case None
}

extension StyleNode {
    // 查找某个 css 属性
    func getValue(name: String) -> Value? {
        return self.styleMap[name]
    }
    
    // 先查找 name 的值，不存在，则查找 fallbackName 的值，若仍然不存在，则返回 default
    func lookup(name: String, fallbackName: String, defaultValue: Value) -> Value {
        var value = getValue(name: name)
        if (value == nil) {
            value = getValue(name: fallbackName)
            
            if (value == nil) {
                return defaultValue
            }
        }
        
        return value ?? defaultValue
    }
    
    // 根据 display 属性，返回对应的枚举值
    func getDisplay() -> Display {
        let displayValue = getValue(name: "display")
        
        if case let .Keyword(display) = displayValue {
            switch display {
            
            case "block":
                return .Block
                
            case "none":
                return .None
                
            default:
                return .Inline
            }
        }
        
        return .Inline
    }
}

// 样式处理，将 styleSheet 中的样式关联到节点
struct StyleProcessor {
    // 生成样式树
    func genStyleTree(root: Node, styleSheet: StyleSheet) -> StyleNode {
        
        var styleMap: StyleMap
        
        let nodeType = root.nodeType
        
        switch nodeType {
        
        // 文本节点无样式
        case .Text(_):
            styleMap = [:]
        case .Element(let node):
            styleMap = genStyleMap(node: node, styleSheet: styleSheet)
        }
       
        // 子节点递归生成关联样式
        let childrenStyleNodes = root.children.map { (child) -> StyleNode in
            genStyleTree(root: child, styleSheet: styleSheet)
        }
        
        return StyleNode(node: root, styleMap: styleMap, children: childrenStyleNodes)
    }
    
    // 生成样式 map
    func genStyleMap(node: ElementData, styleSheet: StyleSheet) -> StyleMap {
        var styleMap = StyleMap()
        
        // 获取匹配的 rule
        var rules = matchRules(node: node, styleSheet: styleSheet)
        
        // 从低优先级到高优先级排序，这样放入 map 中时高优先级会覆盖低优先级
        rules.sort {
            $0.0 < $1.0
        }
        
        // 遍历匹配 rule 的所有属性声明
        for (_, rule) in rules {
            let declarations = rule.declarations
            for declaration in declarations {
                // 逐个放入 map
                styleMap[declaration.name] = declaration.value
            }
        }
        
        return styleMap
    }
    
    // 遍历整个样式表，找出匹配的规则
    func matchRules(node: ElementData, styleSheet: StyleSheet) -> [MatchedRule] {
        
        let rules = styleSheet.rules.compactMap { (rule) -> MatchedRule? in
            let result = matchRule(node: node, rule: rule)
            return result
        }
        
        return rules
    }
    
    func matchRule(node: ElementData, rule: Rule) -> MatchedRule? {
        // 遍历 rule 的 selectors
        for selector in rule.selectors {
            if case .Simple(let simpleSelector) = selector {
                
                // 如果匹配
                if matchSelector(node: node, simpleSelector: simpleSelector) {
                    return (selector.specificity(), rule)
                }
            }
        }
        
        return nil
    }
    
    // 节点的 id，tag，class 是否与选择器 simpleSelector 匹配，若一个不匹配，则返回 false
    func matchSelector(node: ElementData, simpleSelector: SimpleSelector) -> Bool {
        
        // tag，css 中存在 tag 且不相等
        if simpleSelector.tagName != nil && node.tagName != simpleSelector.tagName {
            return false
        }
        
        // id
        let id = node.getId()
        
        // css 中存在 id 且不相等
        if simpleSelector.id != nil && id != simpleSelector.id {
            return false
        }
        
        // class
        let classes = node.getClasses()
        let selectorClasses = simpleSelector.classes
        
        // 节点元素的 class 中全部包含 selector 中的 class
        for cls in selectorClasses {
            if !classes.contains(cls) {
                return false
            }
        }
        
        return true
    }
}
