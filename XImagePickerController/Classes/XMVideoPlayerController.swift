//
//  XMPhotoPreviewView.swift
//  channel_sp
//
//  Created by ming on 2017/10/19.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos


class XMVideoPlayerController: UIViewController {
    var model:XMAssetModel?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playButton: UIButton?
    private var cover: UIImage?
    private var progress = UIProgressView()
    private var toolBar = UIView()
    private var doneButton = UIButton.init(type: .custom)
    private var originStatusBarStyle: UIStatusBarStyle?
    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationController is XMImagePickerController {
            navigationItem.title = (navigationController as! XMImagePickerController).previewBtnTitleStr
        }
        view.backgroundColor = UIColor.black
        configMoviePlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(self.pausePlayerAndShowNaviBar), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originStatusBarStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: animated)

    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.setStatusBarStyle(originStatusBarStyle ?? .default, animated: animated)
    }

    func configMoviePlayer() {
        XMImageManager.manager.getPhoto(asset: model!.asset, completion: {[weak self] (photo, info, isDegraded) in
            self!.cover = photo
        })
        XMImageManager.manager.getVideo(asset: model!.asset) { (playerItem, info) in

            DispatchQueue.main.async {
                self.player = AVPlayer.init(playerItem: playerItem)
                self.playerLayer = AVPlayerLayer.init(player: self.player)
                self.playerLayer?.backgroundColor = UIColor.black.cgColor
                self.playerLayer?.frame = self.view.bounds
                self.view.layer.addSublayer(self.playerLayer!)
                self.configBottomToolBar()
                self.addProgressObserver()
                self.configPlayButton()
                NotificationCenter.default.addObserver(self, selector: #selector(self.pausePlayerAndShowNaviBar), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    func addProgressObserver() {
        let playerItem = player?.currentItem
        player?.addPeriodicTimeObserver(forInterval: CMTime.init(value: 1, timescale: 1), queue: DispatchQueue.main, using: {[weak self] (time) in
            let current = time.seconds
            let total = playerItem?.duration.seconds
            if current > 0.0 {
                self?.progress.progress = Float(current / total!)
            }
        })
    }
    func configBottomToolBar() {
        toolBar.backgroundColor = UIColor.init(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.7)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        doneButton.addTarget(self, action: #selector(self.doneButtonClick), for: .touchUpInside)

        if let imagePick = navigationController as? XMImagePickerController {
            doneButton.setTitle(imagePick.doneBtnTitleStr, for: .normal)
            doneButton.setTitleColor(imagePick.oKButtonTitleColorNormal, for: .normal)
        } else {
            doneButton.setTitle(Bundle.xm_localizedString(key: "Done"), for: .normal)
            doneButton.setTitleColor(UIColor.init(red: 83.0/255.0, green: 179.0/255.0, blue: 17.0/255.0, alpha: 1.0), for: .normal)
        }
        toolBar.addSubview(doneButton)

        progress.progress = 0.0
        progress.backgroundColor = UIColor.init(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.7)
        progress.trackTintColor = UIColor.gray
        progress.tintColor = UIColor.white

        toolBar.addSubview(progress)
        view.addSubview(toolBar)
    }

    func configPlayButton() {
        playButton = UIButton.init(type: .custom)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlayHL"), for: .highlighted)
        playButton?.addTarget(self, action: #selector(self.playButtonClick), for: .touchUpInside)
        view.addSubview(playButton!)
    }



    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        playerLayer?.frame = view.bounds
        progress.frame = CGRect.init(x: 12, y: 27, width: view.xm_width - 44.0 - 12.0 - 12.0 - 12.0, height: 2)
        playButton?.frame = CGRect.init(x: 0, y: 64, width: view.xm_width, height: view.xm_height - 64 - (isIPnoneX ? 64 : 50))
        doneButton.frame = CGRect.init(x: view.xm_width - 44.0 - 12.0, y: (isIPnoneX ? 5 : 3), width: 44.0, height: 44.0)
        toolBar.frame = CGRect.init(x: 0.0, y: view.xm_height - (isIPnoneX ? 64 : 50), width: view.xm_width, height: (isIPnoneX ? 64 : 50))

    }

    @objc func doneButtonClick() {
        if navigationController != nil {
            if navigationController is XMImagePickerController {
                if (navigationController as! XMImagePickerController).autoDismiss {
                    navigationController?.dismiss(animated: true, completion: {
                        self.callDelegateMethod()
                    })
                }
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.callDelegateMethod()
            })
        }
    }

    @objc func playButtonClick() {
        let currentTime = player?.currentItem?.currentTime()
        let durationTime = player?.currentItem?.duration
        if player?.rate == 0.0 {
            if currentTime?.value == durationTime?.value {
                player?.currentItem?.seek(to: CMTime.init(value: 0, timescale: 1))
            }
            player?.play()
            toolBar.isHidden = true
            self.navigationController?.setNavigationBarHidden(true, animated: true)
            playButton?.setImage(nil, for: .normal)
            if !xm_isGlobalHideStatusBar {
                UIApplication.shared.isStatusBarHidden = true
            }

        } else {
            pausePlayerAndShowNaviBar()
        }
    }


    func callDelegateMethod() {
        guard let imagePickerVc = (navigationController is XMImagePickerController) ?  navigationController as? XMImagePickerController : nil else {
            return
        }
        if imagePickerVc.pickerDelegate?.responds(to: #selector(imagePickerVc.pickerDelegate?.imagePickerController(_:didFinishPickingVideo:sourceAsset:))) == true {
            imagePickerVc.pickerDelegate?.imagePickerController!(imagePickerVc, didFinishPickingVideo: cover, sourceAsset:  model?.asset)
        }
        if imagePickerVc.didFinishPickingGifImageHandle != nil {
            imagePickerVc.didFinishPickingGifImageHandle!(cover, model?.asset)
        }

    }

    @objc func pausePlayerAndShowNaviBar() {
        player?.pause()
        toolBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)

        playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        if !xm_isGlobalHideStatusBar {
            UIApplication.shared.isStatusBarHidden = false
        }
    }

}
