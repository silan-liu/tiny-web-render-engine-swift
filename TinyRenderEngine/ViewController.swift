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
        
        let html = """
                    <div id="main" class="test">
                    </div>
                """
        
        // html 解析
        var htmlParser = HTMLParser()
        let root = htmlParser.parse(input: html)
        print(root)
        
        let css = """
             .test {
                padding: 0px;
                margin: 10px;
                position: absolute;
             }

            p {
                font-size: 10px;
                color: #ff908912;
            }
        """
        
        // css 解析
        var cssParser = CSSParser()
        let styleSheet = cssParser.parse(source: css)
        print(styleSheet)
        
        // 样式关联处理
        let styleProcessor = StyleProcessor()
        let styleNode = styleProcessor.genStyleTree(root: root, styleSheet: styleSheet)
        print(styleNode)
        
        // 布局处理
        var layoutProcessor = LayoutProcessor()
        let containingBlock = Dimensions()

        let layoutTree = layoutProcessor.genLayoutTree(styleNode: styleNode, containingBlock: containingBlock)
        print(layoutTree)
        
        // 绘制
        var viewPort = Rect()
        viewPort.width = 600
        viewPort.height = 800
        
        let paintingProcessor = PaintingProcessor()
        
        // 光栅化，生成像素点
        let canvas = paintingProcessor.paint(layoutRoot: layoutTree, bounds: viewPort)
        
        print(canvas.pixels)
    }
    
    func test() {
        var pixels = [PixelData]()

        let red = PixelData(a: 255, r: 255, g: 0, b: 0)
        let green = PixelData(a: 255, r: 0, g: 255, b: 0)
        let blue = PixelData(a: 255, r: 0, g: 0, b: 255)

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
    
    func imageFromARGB32Bitmap(pixels: [PixelData], width: Int, height: Int) -> UIImage? {
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

