//
//  HTMLParser.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/26.
//

import Foundation

public struct HTMLParser {
    // 文本扫描辅助
    var sourceHelper: SourceHelper = SourceHelper()
    
    mutating public func parse(input: String) -> Node {
        
        // 设置输入源
        sourceHelper.updateInput(input: input)
        
        // 解析节点
        let nodes = self.parseNodes()
        
        // 如果只有一个元素，则直接返回
        if nodes.count == 1 {
            return nodes[0]
        }
        
        // 用 html 标签包裹一层，再返回
        return Node(tagName: "html", attributes: [:], children: nodes)
    }
    
    // 解析节点
    mutating func parseNode() -> Node {
        switch sourceHelper.nextCharacter() {
        // 解析标签
        case "<":
            return parseElement()
        default:
            // 默认解析文本
            return parseText()
        }
    }
    
    // 解析标签
    // <div id="p1" class="c1"><p>hello</p></div>
    mutating func parseElement() -> Node {
        // 确保以 < 开头
        assert(self.sourceHelper.consumeCharacter() == "<")
        
        // 解析标签
        let tagName = parseTagName()
        
        // 解析属性
        let attributes = parseAttributes()
        
        // 确保标签结束是 >
        assert(self.sourceHelper.consumeCharacter() == ">")

        // 解析嵌套子标签
        let children = parseNodes()
        
        // 确保标签闭合 </
        assert(self.sourceHelper.consumeCharacter() == "<")
        assert(self.sourceHelper.consumeCharacter() == "/")

        // 确保闭合标签名与前面标签一致
        let tailTagName = parseTagName()
        assert(tagName.elementsEqual(tailTagName))
        
        // 确保以 > 结束
        assert(self.sourceHelper.consumeCharacter() == ">")

        // 生成元素节点
        let node = Node(tagName: tagName, attributes: attributes, children: children)
        return node
    }
    
    // 解析文本
    mutating func parseText() -> Node {
        // 获取文本内容，文本在标签中间，<p>hhh</p>
        let text = self.sourceHelper.consumeWhile(test: { (char) -> Bool in
            char != "<"
        })
        
        return Node(data: text)
    }
    
    // 解析标签名
    mutating func parseTagName() -> String {
        // 标签名字，a-z,A-Z,0-9 的组合
        return self.sourceHelper.consumeWhile { (char) -> Bool in
            char.isLetter || char.isNumber
        }
    }
    
    // 解析属性，返回 map
    mutating func parseAttributes() -> AttrMap {
        var map = AttrMap()
        
        while true {
            self.sourceHelper.consumeWhitespace()
            
            // 如果到  opening tag 的末尾，结束
            if self.sourceHelper.nextCharacter() == ">" {
                break
            }
            
            // 解析属性
            let (name, value) = parseAttribute()
            map[name] = value
        }
        return map
    }
    
    // 解析单个属性
    mutating func parseAttribute() -> (String, String) {
        // 属性名
        let name = parseTagName()
        
        // 中间等号
        assert(self.sourceHelper.consumeCharacter() == "=")
        
        // 属性值
        let value = parseAttrValue()
        
        return (name, value)
    }
    
    // 解析属性值，遇到 " 或 ' 结束
    mutating func parseAttrValue() -> String {
        let openQuote = self.sourceHelper.consumeCharacter()
        
        // 以单引号或双引号开头
        assert(openQuote == "\"" || openQuote == "'")
        
        // 取出引号之间的字符
        let value = self.sourceHelper.consumeWhile { (char) -> Bool in
            char != openQuote
        }
        
        // 引号配对
        assert(self.sourceHelper.consumeCharacter() == openQuote)
        
        return value
    }
    
    // 循环解析节点
    mutating func parseNodes() -> [Node] {
        var nodes: [Node] = []
        while true {
            self.sourceHelper.consumeWhitespace()
            
            // "</" 的判断，目的是：当无嵌套标签时，能跳出循环。比如，<html></html>，在解析完<html>后，会重新调用 parseNodes 解析子标签
                 // 这时字符串是  </html>。
            if self.sourceHelper.eof() || self.sourceHelper.startsWith(s: "</") {
                break
            }
            
            let node = self.parseNode()
            nodes.append(node)
        }
        
        return nodes
    }
}
