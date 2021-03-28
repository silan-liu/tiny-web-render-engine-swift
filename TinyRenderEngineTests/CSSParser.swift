//
//  CSSParser.swift
//  TinyRenderEngineTests
//
//  Created by silan on 2021/3/28.
//

import XCTest
@testable import TinyRenderEngine

class CSSParser: XCTestCase {

    func testSpecifity1() {
        let simple1 = SimpleSelector(tagName: nil, id: nil, classes: ["1"])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: nil, id: "hello", classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() < s2.specificity())
    }
    
    func testSpecifity2() {
        let simple1 = SimpleSelector(tagName: nil, id: nil, classes: ["1"])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: nil, classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() > s2.specificity())
    }
    
    func testSpecifity3() {
        let simple1 = SimpleSelector(tagName: "hello", id: "what", classes: [])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: nil, classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() > s2.specificity())
    }
    
    func testSpecifity4() {
        let simple1 = SimpleSelector(tagName: "hello", id: "what", classes: ["1"])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: "what", classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() > s2.specificity())
    }
    
    func testSpecifity5() {
        let simple1 = SimpleSelector(tagName: "hello", id: "what", classes: [])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: "what", classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() == s2.specificity())
    }
    
    func testSpecifity6() {
        let simple1 = SimpleSelector(tagName: "hello", id: "what", classes: [])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: "what22", classes: [])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() == s2.specificity())
    }
    
    func testSpecifity7() {
        let simple1 = SimpleSelector(tagName: nil, id: "what", classes: [])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: nil, classes: ["1"])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() > s2.specificity())
    }
    
    func testSpecifity8() {
        let simple1 = SimpleSelector(tagName: nil, id: "what", classes: [])
        let s1 = CSSSelector.Simple(simple1)
        
        let simple2 = SimpleSelector(tagName: "hello", id: "22", classes: ["1"])
        let s2 = CSSSelector.Simple(simple2)
        
        assert(s1.specificity() < s2.specificity())
    }
}
