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

