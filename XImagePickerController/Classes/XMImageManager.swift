//
//  XMImageManager.swift
//  channel_sp
//
//  Created by ming on 2017/10/18.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos
import UIKit

func xm_LableSize(_ text: String = "", _ font: UIFont = UIFont.systemFont(ofSize: 15), width: CGFloat = 0.0) -> CGSize {

    if text.isEmpty {
        return CGSize.zero
    } else {
        if width > 0.0 {
            let rect = text.boundingRect(with: CGSize.init(width: Int(width), height: Int.max), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.strokeColor: UIColor.white], context: nil)
            return CGSize(width: rect.width + 1, height: rect.height)
        } else {
            let rect = text.boundingRect(with: CGSize.init(width: Int(UIScreen.main.bounds.width - 30), height: Int.max), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font, NSAttributedStringKey.strokeColor: UIColor.white], context: nil)
            return CGSize(width: rect.width + 1, height: rect.height)
        }
    }
}


class XMImageManager: NSObject{
    public static let manager = XMImageManager()

    weak var pickerDelegate: XMImagePickerControllerDelegate?
    var shouldFixOrientation = false

    var photoPreviewMaxWidth: CGFloat = 600.0
    var photoWidth: CGFloat = 828.0 {
        didSet {
            XMScreenWidth = photoWidth * 0.5
        }
    }
    var columnNumber = 4
    var sortAscendingByModificationDate = true

    var minPhotoWidthSelectable: CGFloat = 0.0
    var minPhotoHeightSelectable: CGFloat = 0.0
    var hideWhenCanNotSelect = true


    var XMScreenWidth: CGFloat = UIScreen.main.bounds.width
    var XMScreenScale: CGFloat {
        if XMScreenWidth > 700 {
            return 1.5
        }
        return 2.0
    }

    var AssetGridThumbnailSize: CGSize {
        let itmeWH = (XMScreenWidth - 2 * 4 - 4) / CGFloat(columnNumber) - 4
        return CGSize.init(width: itmeWH * XMScreenScale, height: itmeWH * XMScreenScale)
    }


    func authorizationStatusAuthorized() -> Bool {
        let status = XMImageManager.authorizationStatus()
        if status  == .notDetermined || status  == .denied {
            requestAuthorization(completion: nil)
        }
        return status == .authorized

    }
    class func authorizationStatus() ->PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus()
    }
    func requestAuthorization(completion: (() -> Void)?) {
        let callCompletion = {
            DispatchQueue.main.async {
                if completion != nil {
                    completion!()
                }
            }
        }
        DispatchQueue.global().async {
            PHPhotoLibrary.requestAuthorization({ (status) in
                callCompletion()
            })
        }
    }

    func getCameraRollAlbum(allowPickingVideo: Bool, allowPickingImage: Bool, completion: ((XMAlbumModel) -> Void)?) {
        let option = PHFetchOptions()
        if !allowPickingVideo {
            option.predicate = NSPredicate.init(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        if !allowPickingImage {
            option.predicate = NSPredicate.init(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !sortAscendingByModificationDate {
            option.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: sortAscendingByModificationDate)]
        }

        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)

        for i in 0 ..< smartAlbums.count {
            if isCameraRollAlbum(metadata: smartAlbums[i]) {
                let fetchResult = PHAsset.fetchAssets(in: smartAlbums[i], options: option)
                let model = getModel(result: fetchResult, name: smartAlbums[i].localizedTitle ?? "", isCameraRoll: true)
                if completion != nil {
                    completion!(model)
                    break
                }
            }
        }
    }
    func getAllAlbums(allowPickingVideo: Bool, allowPickingImage: Bool, allowPickingGif: Bool, completion: ((Array<XMAlbumModel>) -> Void)?) {
        var albumArr: Array<XMAlbumModel> = []
        let option = PHFetchOptions()
        if !allowPickingVideo {
            option.predicate = NSPredicate.init(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        if !allowPickingImage {
            option.predicate = NSPredicate.init(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !sortAscendingByModificationDate {
            option.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: sortAscendingByModificationDate)]
        }
        let albums = [PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil),
                      PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)]
        for album in albums {
            for i in 0 ..< album.count {
                if isCameraRollAlbum(metadata: album[i]) {
                    let fetchResult = PHAsset.fetchAssets(in: album[i], options: option)
                    albumArr.insert(getModel(result: fetchResult, name: album[i].localizedTitle ?? "", isCameraRoll: true), at: 0)

                } else {
                    let fetchResult = PHAsset.fetchAssets(in: album[i], options: option)
                    if album[i].localizedTitle == "Hidden"
                        || album[i].localizedTitle == "已隐藏"
                        || album[i].localizedTitle == "Deleted"
                        || album[i].localizedTitle == "最近删除"{
                        continue
                    }
                    if !allowPickingGif && (album[i].localizedTitle == "动图"
                        || album[i].localizedTitle == "Animated"){
                        continue
                    }
                    let albumModel = getModel(result: fetchResult, name: album[i].localizedTitle ?? "", isCameraRoll: true)

                    if fetchResult.count > 0 && albumModel.models.count > 0 {
                        albumArr.append(albumModel)
                    }
                }
            }
        }
        if completion != nil {
            completion!(albumArr)
        }
    }

    func getAssets(result: PHFetchResult<PHAsset>?, allowPickingVideo: Bool, allowPickingImage: Bool, allowPickingGif: Bool, completion: ((Array<XMAssetModel>?) -> Void)?) {
        guard let fetchResult = result else {
            if completion != nil {
                completion!(nil)
            }
            return
        }
        var modelArr: Array<XMAssetModel> = []
        fetchResult.enumerateObjects { (asset, idx, stop) in
            guard let model = self.assetModel(asset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage, allowPickingGif: allowPickingGif) else {
                return
            }
            modelArr.append(model)
        }
        if completion != nil {
            completion!(modelArr)
        }
    }

    func getAssets(result: PHFetchResult<PHAsset>?,atIndex: Int, allowPickingVideo: Bool, allowPickingImage: Bool, allowPickingGif: Bool, completion: ((XMAssetModel?) -> Void)?) {
        guard let fetchResult = result else {
            if completion != nil {
                completion!(nil)
            }
            return
        }

        do {
            let asset = fetchResult[atIndex]
            guard let model = self.assetModel(asset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage, allowPickingGif: allowPickingGif) else {
                return
            }
            if completion != nil {
                completion!(model)
            }
        }
        if completion != nil {
            completion!(nil)
        }
    }


    func assetModel(asset: PHAsset, allowPickingVideo: Bool, allowPickingImage: Bool, allowPickingGif: Bool) -> XMAssetModel? {
        if self.pickerDelegate?.responds(to: #selector(self.pickerDelegate?.isAssetCanSelect(asset:))) == true {
            if self.pickerDelegate?.isAssetCanSelect!(asset: asset) == false {
                return nil
            }
        }
        let type = getAssetType(asset: asset)
        if (type == .Video && !allowPickingVideo) || (type == .Photo && !allowPickingImage) || (type == .PhotoGif && (!allowPickingImage || !allowPickingGif)) {
            return nil;
        }
        if hideWhenCanNotSelect && !isPhotoSelectableWithAsset(asset: asset) {
            return nil
        }
        let model = XMAssetModel.init(asset: asset, type: type)

        if type == .Video {
            model.timeLength = String(asset.duration)
            model.timeLength = getNewTimeFromDurationSecond(duration: Int(asset.duration))
        }
        return model
    }

    func getAssetType(asset: PHAsset) -> XMAssetModelMediaType {
        if asset.mediaType == .video {
            return .Video
        } else if asset.mediaType == .audio {
            return .Audio
        } else if asset.mediaType == .image {
            if (asset.value(forKey: "filename") as? String)?.hasSuffix("GIF") == true {
                return .PhotoGif
            }
            return .Photo
        }
        return .Photo
    }

    func getNewTimeFromDurationSecond(duration: Int) -> String {
        if duration < 0 {
            return String.init(format: "0:0%zd", duration)
        } else if duration < 60 {
            return String.init(format: "0:%zd", duration)
        }else if duration < 3600 {
            let min = duration / 60
            let sec = duration - min * 60
            return String.init(format: "%02d:%02d", min, sec)
        } else {
            let hour = duration / 3600
            let min = (duration - hour * 3600) / 60
            let sec = duration  - hour * 3600 - min * 60
            return String.init(format: "%d:%02d:%02d", hour, min, sec)
        }
    }




    func savePhoto(photo: UIImage, location: CLLocation? = nil, completion: ((Error?) -> Void)?) {
        if #available(iOS 9.0, *) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: photo)
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    if success && completion != nil {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                            completion!(nil)
                        })
                    } else if error != nil && completion != nil {
                        print("保存照片出错:%@",error!.localizedDescription)
                        completion!(error)
                    }
                }
            })
        } else {
            ALAssetsLibrary().writeImage(toSavedPhotosAlbum: photo.cgImage!, orientation: ALAssetOrientation.init(rawValue: photo.imageOrientation.rawValue)!, completionBlock: { (assetURL, error) in
                if error != nil {
                    print("保存照片出错:%@",error!.localizedDescription)
                    if completion != nil {
                        completion!(error)
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                        if completion != nil {
                            completion!(nil)
                        }
                    })
                }
            })

        }
    }
    
    func getVideo(asset: PHAsset?, progressHandler:((Double, Error?, UnsafeMutablePointer<ObjCBool>,Dictionary<AnyHashable, Any>?) -> Void)? = nil, completion: ((AVPlayerItem?, Dictionary<AnyHashable, Any>?) -> Void)?) {
        guard let phAsset = asset else {
            if completion != nil {
                completion!(nil, nil)
            }
            return
        }

        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = {(progress, error, stop, info) in
            DispatchQueue.main.async {
                if progressHandler != nil {
                    progressHandler!(progress, error, stop, info)
                }
            }
        }
        PHImageManager.default().requestPlayerItem(forVideo: phAsset, options: option) { (playerItem, info) in
            if completion != nil {
                completion!(playerItem, info)
            }
        }
    }

    func getVideoOutputPath(asset: PHAsset?, completion:((String?) -> Void)?) {
        guard let phAsset = asset else {
            if completion != nil {
                completion!(nil)
            }
            return
        }

        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { (avasset, audioMix, info) in
            self.startExportVideo(videoAsset: avasset as? AVURLAsset, completion: completion)
        }
    }
    func startExportVideo(videoAsset: AVURLAsset?, completion:((String?) -> Void)?) {
        guard let asset = videoAsset else {
            if completion != nil {
                completion!(nil)
            }
            return
        }
        let presets = AVAssetExportSession.exportPresets(compatibleWith: asset)

        if presets.contains(AVAssetExportPreset640x480) {
            let session = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPreset640x480)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH:mm:ss-SSS"
            let outputPath = NSHomeDirectory().appendingFormat("/tmp/output-%@.mp4", dateFormatter.string(from: Date()))
            print(outputPath)
            session?.outputURL = URL.init(fileURLWithPath: outputPath)
            session?.shouldOptimizeForNetworkUse = true
            let supportedTypeArray = session?.supportedFileTypes
            if supportedTypeArray?.contains(.mp4) == true {
                session?.outputFileType = .mp4
            } else if supportedTypeArray?.count == 0 {
                print("No supported file types 视频类型暂不支持导出")
            } else {
                session?.outputFileType = supportedTypeArray?[0]
            }
            if FileManager.default.fileExists(atPath: NSHomeDirectory().appending("/tmp")) {
                try? FileManager.default.createDirectory(atPath: NSHomeDirectory().appending("/tmp"), withIntermediateDirectories: true, attributes: nil)
            }
            let videoComposition = fixedComposition(asset: asset)
            if videoComposition.renderSize.width > 0 {
                session?.videoComposition = videoComposition
            }
            session?.exportAsynchronously(completionHandler: {
                guard let status = session?.status else {
                    print("AVAssetExportSessionStatusUnknown")
                    return
                }
                switch status {
                case .unknown:
                    print("AVAssetExportSessionStatusUnknown")
                case .waiting:
                    print("AVAssetExportSessionStatusWaiting")
                case .exporting:
                    print("AVAssetExportSessionStatusExporting")
                case .completed:
                    if completion != nil {
                        completion!(outputPath)
                    }
                    print("AVAssetExportSessionStatusCompleted")
                case .failed:
                    print("AVAssetExportSessionStatusFailed")
                default:
                    print("AVAssetExportSessionStatusUnknown")
                }
            })
        }
    }
    func isContain(assets: Array<PHAsset>, asset: PHAsset) -> Bool {
        return assets.contains(asset)
    }

    func isCameraRollAlbum(metadata: PHAssetCollection) -> Bool {
        return metadata.assetCollectionSubtype == .smartAlbumUserLibrary
    }

    func getAssetIdentifier(asset: PHAsset) -> String {
        return asset.localIdentifier
    }
    func isPhotoSelectableWithAsset(asset: PHAsset) -> Bool {
        let size = CGSize.init(width: asset.pixelWidth, height: asset.pixelHeight)
        if minPhotoWidthSelectable > size.width && minPhotoHeightSelectable > size.height {
            return false
        }
        return true
    }


    func getModel(result: PHFetchResult<PHAsset>, name: String, isCameraRoll: Bool) -> XMAlbumModel {
        let albumModel = XMAlbumModel()
        albumModel.result = result
        albumModel.name = name
        albumModel.isCameraRoll = isCameraRoll
        albumModel.count = result.count
        return albumModel
    }

    func scale(image: UIImage?, toSize: CGSize) -> UIImage? {
        if image != nil {
            if image!.size.width > toSize.width {
                UIGraphicsBeginImageContext(toSize)
                image?.draw(in: CGRect.init(origin: CGPoint.zero, size: toSize))
                let  newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return newImage
            } else {
                return image
            }
        } else {
            return nil
        }
    }

    func fixedComposition(asset: AVAsset) -> AVMutableVideoComposition {
        let videoComposition = AVMutableVideoComposition()
        let degrees = degressFromVideoFile(asset: asset)
        if degrees != 0.0 {
            var translateToCenter = CGAffineTransform.identity
            var mixedTransform = CGAffineTransform.identity

            videoComposition.frameDuration = CMTime.init(value: 1, timescale: 30)
            let tracks = asset.tracks(withMediaType: .video)
            let videoTrack = tracks[0]
            let roateInstruction = AVMutableVideoCompositionInstruction()
            roateInstruction.timeRange = CMTimeRange.init(start: kCMTimeZero, end: asset.duration)

            let roateLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)

            if  degrees == Double.pi * 0.5 {
                translateToCenter = CGAffineTransform.init(translationX: videoTrack.naturalSize.height, y: 0.0)
                mixedTransform = translateToCenter.rotated(by: CGFloat(degrees))
                videoComposition.renderSize = CGSize.init(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
                roateLayerInstruction.setTransform(mixedTransform, at: kCMTimeZero)

            } else if  degrees == Double.pi {
                translateToCenter = CGAffineTransform.init(translationX: videoTrack.naturalSize.width, y: videoTrack.naturalSize.height)
                mixedTransform = translateToCenter.rotated(by: CGFloat(degrees))
                videoComposition.renderSize = CGSize.init(width: videoTrack.naturalSize.width, height: videoTrack.naturalSize.height)
                roateLayerInstruction.setTransform(mixedTransform, at: kCMTimeZero)
            } else if  degrees == Double.pi * 1.5 {
                translateToCenter = CGAffineTransform.init(translationX: 0.0, y: videoTrack.naturalSize.width)
                mixedTransform = translateToCenter.rotated(by: CGFloat(degrees))
                videoComposition.renderSize = CGSize.init(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
                roateLayerInstruction.setTransform(mixedTransform, at: kCMTimeZero)
            }
            roateInstruction.layerInstructions = [roateLayerInstruction]
            videoComposition.instructions = [roateInstruction]
        }
        return videoComposition

    }
    func degressFromVideoFile(asset: AVAsset) -> Double {
        let tracks = asset.tracks(withMediaType: .video)
        if tracks.count > 0 {
            let track = tracks[0]
            let transform = track.preferredTransform
            if transform.a == 0.0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0.0 {
                return Double.pi * 0.5
            } else if transform.a == 0.0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0.0 {
                return Double.pi * 1.5
            }else if transform.a == 1.0 && transform.b == 0.0 && transform.c == 0.0 && transform.d == 1.0 {
                return 0.0
            } else if transform.a == -1.0 && transform.b == 0.0 && transform.c == 0.0 && transform.d == -1.0 {
                return Double.pi
            } else {
                return 0.0
            }
        } else {
            return 0.0
        }
    }

    func fixOrientation(image: UIImage?) -> UIImage? {
        if image == nil {
            return nil
        }
        if !shouldFixOrientation {
            return image
        }
        if image?.imageOrientation == .up {
            return image
        }
        var transform = CGAffineTransform.identity

        switch image!.imageOrientation {
        case .down:
           fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: image!.size.width, y: image!.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))

        case .left:
            fallthrough
        case .leftMirrored:
            transform = transform.translatedBy(x: image!.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi * 0.5))

        case .right:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: 0.0, y: image!.size.height)
            transform = transform.rotated(by: CGFloat(-Double.pi * 0.5))

            
        default:
            transform = CGAffineTransform.identity
        }

        switch image!.imageOrientation {
        case .upMirrored:
            fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: image!.size.width, y: 0.0)
            transform.scaledBy(x: -1.0, y: 1.0)
        case .leftMirrored:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: image!.size.height, y: 0.0)
            transform.scaledBy(x: -1.0, y: 1.0)
        default:
            transform = CGAffineTransform.identity
        }
        guard let cgimage = image?.cgImage else {
            return image
        }
        var bitmapInfo = CGBitmapInfo.init(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        bitmapInfo.insert(.byteOrder32Big)
        let context = CGContext.init(data: nil, width: Int(image!.size.width), height: Int(image!.size.height), bitsPerComponent: cgimage.bitsPerComponent, bytesPerRow: cgimage.bytesPerRow, space: cgimage.colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        context?.concatenate(transform)

        switch image!.imageOrientation {
        case .left:
            fallthrough
        case .leftMirrored:
            fallthrough
        case .rightMirrored:
            fallthrough
        case .right:
            context?.draw(cgimage, in: CGRect.init(x: 0, y: 0, width: image!.size.height, height: image!.size.width))
        default:
            context?.draw(cgimage, in: CGRect.init(x: 0, y: 0, width: image!.size.width, height: image!.size.height))
        }

        guard let retunCGimage = context?.makeImage() else {
            return image
        }
        return UIImage.init(cgImage: retunCGimage)
    }

// MARK: - 获取图片
    func getPhotosBytes(models: Array<XMAssetModel>, completion: ((String) -> Void)?) {

        var dataLength = 0
        for i in 0 ..< models.count {
            let options = PHImageRequestOptions()
            options.resizeMode = .fast

            PHImageManager.default().requestImageData(for: models[i].asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                if models[i].type != .Video && imageData != nil {
                    dataLength = dataLength + imageData!.count
                }
                if i == models.count - 1 {
                    if completion != nil {
                        completion!(self.getBytesFromDataLength(dataLength))
                    }
                }
            })
        }
    }
    func getBytesFromDataLength(_ length: Int) -> String {
        let dataLength = Double(length)

        if dataLength == 0.0 {
            return ""
        }
        if dataLength >= 0.1 * (1024 * 1024) {
            return String.init(format: "%0.1fM", dataLength / 1024.0 / 1024.0)
        } else if (dataLength >= 1024) {
            return String.init(format: "%0.0fK", dataLength / 1024.0)
        } else {
            return String.init(format: "%zdB", dataLength)
        }

    }

    @discardableResult
    func getPhoto(asset: PHAsset?, photoWidth: CGFloat = 0.0, completion: ((UIImage?, Dictionary<AnyHashable, Any>?, Bool?) -> Void)?, progressHandler:((Double, Error?, UnsafeMutablePointer<ObjCBool>,Dictionary<AnyHashable, Any>?) -> Void)? = nil, isNetworkAccessAllowed: Bool = false) -> Int32 {
        guard let phAsset = asset else {
            return 0
        }
        var imageWidth = photoWidth;
        if imageWidth == 0.0 {
            imageWidth = XMScreenWidth;
            if (imageWidth > photoPreviewMaxWidth) {
                imageWidth = photoPreviewMaxWidth;
            }
        }
        var imageSize = CGSize.zero

        if imageWidth < XMScreenWidth && imageWidth < photoPreviewMaxWidth {
            imageSize = AssetGridThumbnailSize
        } else {
            let aspectRatio = CGFloat(phAsset.pixelWidth) / CGFloat(phAsset.pixelHeight)
            var pixelWidth = imageWidth * XMScreenScale * 1.5

            if aspectRatio > 1.8 {
                pixelWidth = pixelWidth * aspectRatio
            }
            if aspectRatio < 0.2 {
                pixelWidth = pixelWidth * 0.5
            }
            imageSize =  CGSize.init(width: pixelWidth, height: pixelWidth / aspectRatio)
        }
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        let imageRequestID = PHImageManager.default().requestImage(for: phAsset, targetSize: imageSize, contentMode: .aspectFill, options: option) { (photo, info) in

            let downloadFinined = (info?[PHImageCancelledKey] == nil || info?[PHImageCancelledKey] as? Bool == false) && (info?[PHImageErrorKey] == nil)
            if downloadFinined && photo != nil {
                if completion != nil {
                    completion!(self.fixOrientation(image: photo), info, info?[PHImageResultIsDegradedKey] as? Bool)
                }
            }
            if info?[PHImageResultIsInCloudKey] != nil && photo == nil && isNetworkAccessAllowed {

                let originalOptions = PHImageRequestOptions()
                originalOptions.progressHandler = { (progress, error, stop, info)  in
                    DispatchQueue.main.async {
                        if progressHandler != nil {
                            progressHandler!(progress, error, stop, info)
                        }
                    }
                }
                originalOptions.isNetworkAccessAllowed = true
                originalOptions.resizeMode = .fast
                PHImageManager.default().requestImageData(for: phAsset, options: originalOptions, resultHandler: { (imageData, dataUTI, orientation, info) in
                    if imageData != nil {
                        var resultImage = UIImage.init(data: imageData!, scale: 0.1)
                        resultImage = self.scale(image: resultImage, toSize: imageSize)
                        resultImage = self.fixOrientation(image: resultImage)
                        if completion != nil {
                            completion!(resultImage, info, false)
                        }
                    }
                })
            }
        }
        return imageRequestID
    }

    func getPostImage(model: XMAlbumModel?, allowPickingGif: Bool, completion: ((UIImage?) -> Void)?) {
        guard let result = model?.result else {
            if completion != nil {
                completion!(nil)
            }
            return
        }
        var asset: PHAsset?

        var index = sortAscendingByModificationDate ? result.count - 1 : 0
        while asset == nil && index >= 0{
            if allowPickingGif || (getAssetType(asset: result[index]) != .PhotoGif) {
                asset = result[index]
            }
            if sortAscendingByModificationDate {
                index = index - 1
            } else {
                index = index + 1
                if index >= result.count {
                    index =  -1
                }
            }
        }
        XMImageManager.manager.getPhoto(asset: asset, photoWidth: 80, completion:{ (image, info, isDegraded) in
            if completion != nil {
                completion!(image)
            }
        })
    }
    func getOriginalPhoto(asset: PHAsset?, completion:((UIImage?, [AnyHashable : Any]?, Bool?) -> Void)?, progressHandler:((Double, Error?, UnsafeMutablePointer<ObjCBool>,Dictionary<AnyHashable, Any>?) -> Void)? = nil) {
        guard let phAsset = asset else {
            if completion != nil {
                completion!(nil, nil, false)
            }
            return
        }
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        option.progressHandler = { (progress, error, stop, info)  in
            DispatchQueue.main.async {
                if progressHandler != nil {
                    progressHandler!(progress, error, stop, info)
                }
            }
        }
        PHImageManager.default().requestImage(for: phAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { (photo, info) in
            let downloadFinined = (info?[PHImageCancelledKey] == nil || info?[PHImageCancelledKey] as? Bool == false ) && info?[PHImageErrorKey] == nil
            if downloadFinined && photo != nil {
                let image = self.fixOrientation(image: photo)

                if completion != nil {
                    completion!(image, info, info?[PHImageResultIsDegradedKey] as? Bool)
                }
            }
        }
    }

    func getOriginalPhotoData(asset: PHAsset?, completion:((Data?, [AnyHashable : Any]?, Bool) -> Void)?) {
        guard let phAsset = asset else {
            if completion != nil {
                completion!(nil, nil, false)
            }
            return
        }

        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        PHImageManager.default().requestImageData(for: phAsset, options: option) { (imageData, dataUTI, orientation, info) in
            let downloadFinined = (info?[PHImageCancelledKey] == nil || info?[PHImageCancelledKey] as? Bool == false) && info?[PHImageErrorKey] == nil
            if downloadFinined && imageData != nil {
                if completion != nil {
                    completion!(imageData!, info, false)
                }
            }
        }
    }


}





