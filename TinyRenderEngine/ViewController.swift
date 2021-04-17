//
//  ViewController.swift
//  TinyRenderEngine
//
//  Created by silan on 2021/3/26.
//

import UIKit

public struct PixelData {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        
        let html = readFile(fileName: "test.html")
        
        // html 解析
        var htmlParser = HTMLParser()
        let root = htmlParser.parse(input: html)
        print(root)
        
        let css = readFile(fileName: "test.css")
        
        // css 解析
        var cssParser = CSSParser()
        let styleSheet = cssParser.parse(source: css)
        print(styleSheet)
        
        // 样式关联处理
        let styleProcessor = StyleProcessor()
        let styleNode = styleProcessor.genStyleTree(root: root, styleSheet: styleSheet)
        print(styleNode)
        
        // 布局处理
        // 定义视口大小
        let width: Float = Float(self.view.bounds.size.width)
        let height: Float = Float(self.view.bounds.size.height)
    
        var viewPort = Dimensions()
        
        // 只设置宽度，高度自动计算
        viewPort.content.width = width
        
        var layoutProcessor = LayoutProcessor()

        let layoutTree = layoutProcessor.genLayoutTree(styleNode: styleNode, containingBlock: viewPort)
        print(layoutTree)
        
        let paintingProcessor = PaintingProcessor()
        
        // 设置高度
        viewPort.content.height = height

        // 光栅化，生成像素点
        let canvas = paintingProcessor.paint(layoutRoot: layoutTree, bounds: viewPort.content)
        
        // 根据像素生成图片
        let image = imageFromARGB32Bitmap(pixels: canvas.pixels, width: Int(width), height: Int(height))
        
        let imageView = UIImageView(image: image)
        imageView.backgroundColor = UIColor.red
        imageView.frame = CGRect.init(x: 0, y: 0, width: Int(width), height: Int(height))
        self.view.addSubview(imageView)
    }
    
    func readFile(fileName: String) -> String {
        
        let filePath = Bundle.main.bundlePath + "/" + fileName
       do {
        
        let content = try String(contentsOfFile: filePath)
        return content

        } catch  {
            print("readFile error")
        }
        
        return ""
    }
    
    func test() {
        var pixels = [Color]()

        // a,r,g,b
        let red: Color = (255, 255, 0, 0)
        let green: Color = (255, 0, 255, 0)
        let blue: Color = (255, 0, 0, 255)

        for _ in 1...300 {
            pixels.append(red)
        }
        for _ in 1...300 {
            pixels.append(green)
        }
        for _ in 1...300 {
            pixels.append(blue)
        }

        let image = imageFromARGB32Bitmap(pixels: pixels, width: 30, height: 30)
        
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect.init(x: 100, y: 100, width: 100, height: 100)
        self.view.addSubview(imageView)
        
        print("test done")
    }
    
    func imageFromARGB32Bitmap(pixels: [Color], width: Int, height: Int) -> UIImage? {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = pixels // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                length: data.count * MemoryLayout<PixelData>.size)
            )
            else { return nil }

        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * MemoryLayout<PixelData>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
            )
            else { return nil }

        return UIImage(cgImage: cgim)
    }
}

