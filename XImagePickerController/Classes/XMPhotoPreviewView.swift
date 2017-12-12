//XMPhotoPreviewView//
//  File.swift
//  channel_sp
//
//  Created by ming on 2017/10/29.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

class XMPhotoPreviewView: UIView , UIScrollViewDelegate{
    var imageView = UIImageView()
    var scrollView = UIScrollView()
    var imageContainerView = UIView()
    lazy var progressView = XMProgressView()

    var cropRect = CGRect.zero
    var allowCrop = false {
        didSet {
            scrollView.maximumZoomScale = allowCrop ? 4.0 : 2.5
            if asset != nil && allowCrop {
                let aspectRatio = CGFloat(asset!.pixelWidth / asset!.pixelHeight)
                if aspectRatio > 1.5 {
                    scrollView.maximumZoomScale =  scrollView.maximumZoomScale * aspectRatio / 1.5
                }
            }
        }
    }
    var model: XMAssetModel? {
        didSet {
            if model == nil {
                return
            }
            scrollView.setZoomScale(1.0, animated: false)
            if model?.type == .PhotoGif {
                XMImageManager.manager.getPhoto(asset: model!.asset, completion: { (photo, info, isDegraded) in
                    self.imageView.image = photo
                    self.resizeSubviews()
                    XMImageManager.manager.getOriginalPhotoData(asset: self.model?.asset, completion: { (imageData, info, isDegraded) in

                        self.imageView.image = UIImage.xm_animatedGIFWithData(data: imageData)
                        self.resizeSubviews()

                    })
                })
            }
        }
    }
    var asset: PHAsset? {
        willSet {
            if asset != nil && imageRequestID > 0 {
                PHImageManager.default().cancelImageRequest(imageRequestID)
            }
        }
        didSet {
            if asset == nil {
                return
            }
            XMImageManager.manager.getPhoto(asset: asset, completion: { (photo, info, isDegraded) in
                self.imageView.image = photo
                self.resizeSubviews()
                self.progressView.isHidden = true
                if self.imageProgressUpdateBlock != nil {
                    self.imageProgressUpdateBlock!(1)
                }
                if !isDegraded! {
                    self.imageRequestID = 0
                }

            }, progressHandler: { (progress, error, stop, info) in
                self.progressView.isHidden = false
                self.bringSubview(toFront: self.progressView)
                self.progressView.progress = max(progress, 0.02)
                if progress >= 1.0 {
                    self.progressView.isHidden = true
                    self.imageRequestID = 0
                }
            }, isNetworkAccessAllowed: true)
        }
    }

    var imageRequestID: Int32 = 0
    var singleTapGestureBlock: (() -> Void)?
    var imageProgressUpdateBlock: ((Double) -> Void)?
    var imageUpdateFinish: (() -> Void)?


    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.bouncesZoom = true
        scrollView.maximumZoomScale = 2.5
        scrollView.minimumZoomScale = 0.5
        scrollView.isMultipleTouchEnabled = true
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = true
        var auto = UIViewAutoresizing()
        auto.insert(.flexibleWidth)
        auto.insert(.flexibleHeight)
        scrollView.autoresizingMask = auto
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.alwaysBounceVertical = false
        addSubview(scrollView)

        imageContainerView.clipsToBounds = true
        imageContainerView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageContainerView)

        imageView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageContainerView.addSubview(imageView)


        let singleTap = UITapGestureRecognizer.init(target: self, action: #selector(self.singleTap))
        addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer.init(target: self, action: #selector(self.doubleTap(tap:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(doubleTap)

        progressView.isHidden = true
        addSubview(progressView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func recoverSubviews() {
        scrollView.setZoomScale(1.0, animated: false)
        resizeSubviews()
    }
    func resizeSubviews() {
        imageContainerView.xm_origin = CGPoint.zero
        imageContainerView.xm_width = scrollView.xm_width

        let imageSize = imageView.image?.size ?? CGSize.zero
        if imageSize.height / imageSize.width > xm_height / scrollView.xm_width {
            imageContainerView.xm_height = CGFloat(floor(Double(imageSize.height / (imageSize.width / scrollView.xm_width))))
        } else {
            var h = imageSize.height / imageSize.width * scrollView.xm_width
            if h < 1 || __inline_isnand(Double(h)) != 0 {
                h = xm_height
            }
            h = floor(h)
            imageContainerView.xm_height = h
            imageContainerView.xm_centerY = xm_height * 0.5
        }
        if imageContainerView.xm_height > xm_height && imageContainerView.xm_height - xm_height <= 1.0 {
            imageContainerView.xm_height = xm_height
        }
        scrollView.contentSize = CGSize.init(width: scrollView.xm_width, height: max(imageContainerView.xm_height, xm_height))
        scrollView.scrollRectToVisible(bounds, animated: false)
        scrollView.alwaysBounceVertical = imageContainerView.xm_height <= xm_height ? false : true
        imageView.frame = imageContainerView.bounds
        refreshScrollViewContentSize()
    }
    func refreshScrollViewContentSize() {
        if allowCrop && model?.type != .PhotoGif {
            let contentWidthAdd = scrollView.xm_width - cropRect.maxX
            let contentHeightAdd = (min(imageContainerView.xm_height, xm_height) - cropRect.height) * 0.5

            let newSizeW = scrollView.contentSize.width + contentWidthAdd
            let newSizeH = max(scrollView.contentSize.height, xm_height) + contentHeightAdd

            scrollView.contentSize = CGSize.init(width: newSizeW, height: newSizeH)
            scrollView.alwaysBounceVertical = true

            if contentHeightAdd > 0 || contentWidthAdd > 0 {
                scrollView.contentInset = UIEdgeInsets.init(top: contentHeightAdd, left: cropRect.minX, bottom: 0, right: 0)
            } else {
                scrollView.contentInset = UIEdgeInsets.zero
            }
        }

    }
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = CGRect.init(x: 10.0, y: 0.0, width: xm_width - 20, height: xm_height)
        let progressWH: CGFloat = 40.0
        let progressX = (xm_width - progressWH) * 0.5;
        let progressY = (xm_height - progressWH) * 0.5;
        progressView.frame = CGRect.init(x: progressX, y: progressY, width: progressWH, height: progressWH)
        recoverSubviews()
    }

    @objc func singleTap() {
        if singleTapGestureBlock != nil {
            singleTapGestureBlock!()
        }
    }
    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.contentInset = UIEdgeInsets.zero;
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let touchPoint = tap.location(in: imageView)
            let newZoomScale = scrollView.maximumZoomScale
            let xsize = xm_width / newZoomScale
            let ysize = xm_height / newZoomScale

            scrollView.zoom(to: CGRect.init(x: touchPoint.x - xsize * 0.5, y: touchPoint.y - ysize * 0.5, width: xsize, height: ysize), animated: true)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainerView
    }
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.contentInset = UIEdgeInsets.zero
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        refreshImageContainerViewCenter()
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        refreshScrollViewContentSize()
    }
    func refreshImageContainerViewCenter() {
        let offsetX: CGFloat = (scrollView.xm_width > scrollView.contentSize.width) ? ((scrollView.xm_width - scrollView.contentSize.width) * 0.5) : 0.0;
        let offsetY: CGFloat = (scrollView.xm_height > scrollView.contentSize.height) ? ((scrollView.xm_height - scrollView.contentSize.height) * 0.5) : 0.0;
        self.imageContainerView.center = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
}
