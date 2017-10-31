//
//  XMPhotoPreviewCell.swift
//  channel_sp
//
//  Created by ming on 2017/10/19.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

class XMAssetPreviewCell: UICollectionViewCell {
    var model: XMAssetModel?
    var singleTapGestureBlock: (() -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        configSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(self.photoPreviewCollectionViewDidScroll), name: NSNotification.Name.init("photoPreviewCollectionViewDidScroll"), object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configSubviews() {

    }
    @objc func photoPreviewCollectionViewDidScroll() {

    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }



}

class XMPhotoPreviewCell: XMAssetPreviewCell {
    var imageProgressUpdateBlock: ((Double) -> Void)?
    var previewView = XMPhotoPreviewView()
    var allowCrop = false {
        didSet {
            previewView.allowCrop = allowCrop
        }
    }
    var cropRect = CGRect.zero {
        didSet {
            previewView.cropRect = cropRect
        }
    }

    override var model: XMAssetModel? {
        didSet {
            if model == nil {
                return
            }
            previewView.asset = model!.asset
        }
    }

    override func configSubviews() {
        previewView.singleTapGestureBlock = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.singleTapGestureBlock != nil {
                strongSelf.singleTapGestureBlock!()
            }
        }
        previewView.imageProgressUpdateBlock = { [weak self] progress in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.imageProgressUpdateBlock != nil {
                strongSelf.imageProgressUpdateBlock!(progress)
            }
        }
        addSubview(previewView)
    }
    func recoverSubviews() {
        previewView.recoverSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        previewView.frame = bounds
    }
    @objc override func photoPreviewCollectionViewDidScroll() {

    }

}


class XMVideoPreviewCell: XMAssetPreviewCell {
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playButton: UIButton?
    var cover: UIImage?

    override var model: XMAssetModel?{
        didSet {
            if model == nil {
                return
            }
            configMoviePlayer()
        }
    }
    override func configSubviews() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.photoPreviewCollectionViewDidScroll), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

    }

    func configPlayButton() {
        if playButton != nil {
            playButton?.removeFromSuperview()
        }
        playButton = UIButton.init(type: .custom)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlayHL"), for: .highlighted)
        playButton?.addTarget(self, action: #selector(self.playButtonClick), for: .touchUpInside)
        addSubview(playButton!)
    }
    func configMoviePlayer() {
        if player != nil {
            playerLayer?.removeFromSuperlayer()
            playerLayer = nil
            player?.pause()
            player = nil
        }
        XMImageManager.manager.getPhoto(asset: model!.asset, completion: {[weak self] (photo, info, isDegraded) in
            self!.cover = photo
        })
        XMImageManager.manager.getVideo(asset: model!.asset) { (playerItem, info) in

            DispatchQueue.main.async {
                self.player = AVPlayer.init(playerItem: playerItem)
                self.playerLayer = AVPlayerLayer.init(player: self.player)
                self.playerLayer?.backgroundColor = UIColor.black.cgColor
                self.playerLayer?.frame = self.bounds
                self.layer.addSublayer(self.playerLayer!)
                self.configPlayButton()
                NotificationCenter.default.addObserver(self, selector: #selector(self.pausePlayerAndShowNaviBar), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        playButton?.frame = CGRect.init(x: 0, y: 64, width: xm_width, height: xm_height - 64 - 44)
    }

    override func photoPreviewCollectionViewDidScroll() {
        pausePlayerAndShowNaviBar()
    }

    @objc func playButtonClick() {
        let currentTime = player?.currentItem?.currentTime()
        let durationTime = player?.currentItem?.duration
        if player?.rate == 0.0 {
            if currentTime?.value == durationTime?.value {
                player?.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1))
                player?.play()
                playButton?.setImage(nil, for: .normal)
                UIApplication.shared.isStatusBarHidden = true
            }
            if singleTapGestureBlock != nil {
                singleTapGestureBlock!()
            }
        } else {
            pausePlayerAndShowNaviBar()
        }
    }

    @objc func pausePlayerAndShowNaviBar() {
        if player?.rate != 0.0 {
            player?.pause()
            playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
            if singleTapGestureBlock != nil {
                singleTapGestureBlock!()
            }
        }
    }
}


class XMGifPreviewCell: XMAssetPreviewCell {
    var previewView = XMPhotoPreviewView()

    override var model: XMAssetModel? {
        didSet {
            if model == nil {
                return
            }
            previewView.model = model
        }
    }

    override func configSubviews() {
        previewView.singleTapGestureBlock = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.singleTapGestureBlock != nil {
                strongSelf.singleTapGestureBlock!()
            }
        }
        addSubview(previewView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView.frame = bounds
    }

}





