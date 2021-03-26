//
//  SourceHelper.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/26.
//

import Foundation

// 文本扫描辅助工具
public struct SourceHelper {
    // 位置游标
    var pos: String.Index
    
    // 源字符串
    var input: String
}

extension SourceHelper {
    init() {
        input = ""
        pos = input.startIndex
    }
    
    init(input: String) {
        pos = input.startIndex
        self.input = input
    }
    
    mutating func updateInput(input: String) {
        pos = input.startIndex
        self.input = input
    }
    
    // 返回下一个字符，游标不动
    func nextCharacter() -> Character {
        return input[pos]
    }
    
    // 是否以 s 开头
    func startsWith(s: String) -> Bool {
        return input[pos...].starts(with: s)
    }
    
    // 是否到了末尾
    func eof() -> Bool {
        return pos >= input.endIndex
    }
    
    // 消费字符，游标+1
    mutating func consumeCharacter() -> Character {
        let result = input[pos]
        pos = input.index(after: pos)
        return result
    }
    
    // 如果满足 test 条件，则循环消费字符，返回满足条件的字符串
    mutating func consumeWhile(test: (Character) -> Bool) -> String {
        var result = ""
        while !self.eof() && test(nextCharacter()) {
            result.append(consumeCharacter())
        }
        return result
    }
    
    // 跳过空白字符
    mutating func consumeWhitespace() {
        _ = consumeWhile { (char) -> Bool in
            return char.isWhitespace
        }
    }
}
