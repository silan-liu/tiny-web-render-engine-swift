//
//  SourceHelperTests.swift
//  TinyRenderEngineTests
//
//  Created by silan on 2021/3/26.
//

import XCTest
@testable import TinyRenderEngine

class SourceHelperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test() throws {
        let input = "<html>   </html>"
        
        var sourceHelper = SourceHelper(input: input)
        
        XCTAssert(sourceHelper.nextCharacter() == "<")
        XCTAssert(sourceHelper.consumeCharacter() == "<")
        
        // 消耗 html
        var result = sourceHelper.consumeWhile { (char) -> Bool in
            char.isLetter
        }
        
        XCTAssert(result == "html")
        
        // 消耗 >
        _ = sourceHelper.consumeCharacter()
        
        // 消耗空白字符
        sourceHelper.consumeWhitespace()
        
        // 以 </ 开头
        XCTAssert(sourceHelper.startsWith(s:"</"))
        
        // 未到末尾
        XCTAssert(!sourceHelper.eof())
        
        // 消耗 </
        _ = sourceHelper.consumeCharacter()
        _ = sourceHelper.consumeCharacter()

        // html
        result = sourceHelper.consumeWhile { (char) -> Bool in
            char.isLetter
        }
        
        XCTAssert(result == "html")
        
        // 消耗 >
        _ = sourceHelper.consumeCharacter()
        
        // 到末尾
        XCTAssert(sourceHelper.eof())
    }
}
