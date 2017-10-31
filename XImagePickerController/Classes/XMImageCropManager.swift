//
//  XMImageCropManager.swift
//  channel_sp
//
//  Created by ming on 2017/10/18.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import UIKit

class XMImageCropManager: NSObject {
    class func overlayClipping(view: UIView, cropRect: CGRect, containerView: UIView, isNeedCircleCrop: Bool = false) {
        let path = UIBezierPath.init(rect: UIScreen.main.bounds)
        let layer = CAShapeLayer()
        if isNeedCircleCrop {
            path.append(UIBezierPath.init(arcCenter: containerView.center, radius: cropRect.width * 0.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: false))
        } else {
            path.append(UIBezierPath.init(rect: cropRect))
        }
        layer.path = path.cgPath
        layer.fillRule = kCAFillRuleEvenOdd
        layer.fillColor = UIColor.black.cgColor
        layer.opacity = 0.5
        view.layer.addSublayer(layer)
    }

    class func cropImageView(imageView: UIImageView?, toRect: CGRect, zoomScale: CGFloat, containerView: UIView) -> UIImage? {
        guard let iv = imageView else {
            return nil
        }
        var transform = CGAffineTransform.identity
        let imageViewRect = iv.convert(iv.bounds, to: containerView)
        let point = CGPoint.init(x: imageViewRect.midX + imageViewRect.width * 0.5, y: imageViewRect.minY + imageViewRect.height * 0.5)
        let xMargin: CGFloat = containerView.xm_width - toRect.maxX - toRect.midX
        let zeroPoint = CGPoint.init(x: (containerView.xm_width - xMargin) * 0.5, y: containerView.xm_centerY)
        let translation = CGPoint.init(x: point.x - zeroPoint.x, y: point.y - zeroPoint.y)
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        transform = transform.scaledBy(x: zoomScale, y: zoomScale)
        let image = iv.image ?? UIImage()
        let imageRef = self.newTransformedImage(transform: transform, sourceImage: image.cgImage!, sourceSize: image.size, outputWidth: toRect.size.width * UIScreen.main.scale, cropSize: toRect.size, imageViewSize: imageView!.frame.size)
        var cropedImage = UIImage.init(cgImage: imageRef)
        cropedImage = XMImageManager.manager.fixOrientation(image: cropedImage)!
        return cropedImage;
    }
    class func newTransformedImage(transform:CGAffineTransform, sourceImage: CGImage, sourceSize: CGSize, outputWidth: CGFloat, cropSize: CGSize, imageViewSize: CGSize) -> CGImage {
        let source = self.newScaledImage(source: sourceImage, size: sourceSize)
        let aspect = cropSize.height / cropSize.width
        let outputSize = CGSize.init(width: outputWidth, height: outputWidth * aspect)
        var bitmapInfo = CGBitmapInfo.init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        bitmapInfo.insert(.byteOrder32Big)
        let context = CGContext.init(data: nil, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: source.bitsPerComponent, bytesPerRow: source.bytesPerRow, space: source.colorSpace!, bitmapInfo: source.bitmapInfo.rawValue)
        context?.setFillColor(UIColor.clear.cgColor)
        context?.fill(CGRect.init(x: 0, y: 0, width: outputSize.width, height: outputSize.height))

        var uiCoords = CGAffineTransform.identity
        uiCoords = uiCoords.scaledBy(x: outputSize.width / cropSize.width, y:  outputSize.height / cropSize.height)
        uiCoords = uiCoords.translatedBy(x: cropSize.width / 2.0, y: cropSize.height / 2.0)

        context?.concatenate(uiCoords)
        context?.concatenate(transform)
        context?.scaleBy(x: 1.0, y: -1.0)

        context?.draw(source, in: CGRect.init(x: -imageViewSize.width * 0.5, y: -imageViewSize.height * 0.5, width: imageViewSize.width, height: imageViewSize.height))
        let resultRef = context?.makeImage()
        return resultRef!

    }
    class func newScaledImage(source: CGImage, size: CGSize) -> CGImage {
//        let srcSize = size
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        bitmapInfo.insert(.byteOrder32Big)

        let context = CGContext.init(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        context?.interpolationQuality = .none
        context?.translateBy(x: size.width * 0.5, y: size.height * 0.5)
        context?.draw(source, in: CGRect.init(x: -size.width * 0.5, y: -size.height * 0.5, width: size.width, height: size.height))
        return context!.makeImage()!

    }


    /// 获取圆形图片
    class func circularClipImage(phtoto: UIImage?) -> UIImage? {
        guard let image = phtoto else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        let rect =  CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height)

        context.addEllipse(in: rect)
        context.clip()

        image.draw(in: rect)

        let circleImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return circleImage
    }


}

extension UIImage {
    class func xm_animatedGIFWithData(data: Data?) -> UIImage? {
        guard let sourceData = data else {
            return nil
        }
        guard let source = CGImageSourceCreateWithData(sourceData as CFData, nil) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)
        if count <= 1 {
            return UIImage.init(data: sourceData)
        } else {
            var images: Array<UIImage> = []
            var duration: TimeInterval = 0.0;

            for i in 0 ..< count {
                guard let cgimage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                    continue
                }
                var subDuration = xm_frameDurationAtIndex(index: i, source: source)

                if subDuration < 0.011 {
                    subDuration = 0.1
                }
                duration = duration + subDuration
                images.append(UIImage.init(cgImage: cgimage, scale: UIScreen.main.scale, orientation: .up))
            }
            if duration == 0.0 {
                duration = 1.0 / 10.0 * Double(count)
            }
            return UIImage.animatedImage(with: images, duration: duration)
        }
    }

    class func xm_frameDurationAtIndex(index: Int, source: CGImageSource)  -> TimeInterval {
        guard let dict = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? Dictionary<AnyHashable, Any> else {
            return 0.1
        }
        guard let gifProperties = dict[kCGImagePropertyGIFDictionary] as? Dictionary<AnyHashable, Any> else {
            return 0.1
        }
        guard let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval else {
            guard let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval else {
                return 0.1
            }
            return delayTimeProp
        }
        return delayTimeUnclampedProp

    }

}






