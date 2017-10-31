//
//  XMAssetCell.swift
//  channel_sp
//
//  Created by ming on 2017/10/19.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

class XMAssetCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    var imageProgressUpdate: (() -> Void)?

    var _selectPhotoButton: UIButton?
    var selectPhotoButton: UIButton {
        if _selectPhotoButton == nil {
            _selectPhotoButton = UIButton()
            _selectPhotoButton?.addTarget(self, action: #selector(self.selectPhotoButtonClick(btn:)), for: .touchUpInside)
            contentView.addSubview(_selectPhotoButton!)
        }
        return _selectPhotoButton!
    }

    var model: XMAssetModel? {
        didSet {
            guard let model = self.model else {
                return
            }
            representedAssetIdentifier = model.asset.localIdentifier
            let imgReqID = XMImageManager.manager.getPhoto(asset: model.asset, photoWidth: xm_width, completion: { (photo, info, isDegraded) in
                if self._progressView != nil {
                    self.progressView.isHidden = true
                    self.imageView.alpha = 1.0
                }
                self.imageView.image = photo
                if isDegraded == false {
                    self.imageRequestID = 0
                }
            }, isNetworkAccessAllowed: false)
            if imageRequestID > 0 && imgReqID > 0 && imgReqID != imageRequestID {
                PHImageManager.default().cancelImageRequest(imageRequestID)
            }
            imageRequestID = imgReqID
            selectPhotoButton.isSelected = model.isSelected
            selectImageView.image = UIImage.imageNamedFromMyBundle(name: model.isSelected ? photoSelImageName : photoDefImageName)
            type = model.type
            if !XMImageManager.manager.isPhotoSelectableWithAsset(asset: model.asset) {
                if _selectImageView?.isHidden == false {
                    _selectPhotoButton?.isHidden = true
                    _selectImageView?.isHidden = true
                }
            }
            if model.isSelected {
                fetchBigImage()
            }
            setNeedsLayout()
        }
    }
    var didSelectPhoto: ((Bool) -> Void)?
    var type: XMAssetModelMediaType = .Photo {
        didSet {
            if type == .Photo || type == .LivePhoto || (type == .PhotoGif && allowPickingGif) || allowPickingMultipleVideo {
                _selectImageView?.isHidden = false
                _selectPhotoButton?.isHidden = false
                _bottomView?.isHidden = true
            } else {
                _selectImageView?.isHidden = true
                _selectPhotoButton?.isHidden = true
            }
            if type == .Video {
                bottomView.isHidden = false
                timeLength.text = model?.timeLength
                videoImgView.isHidden = false
                timeLength.xm_left = videoImgView.xm_right
                timeLength.textAlignment = .right
            } else if type == .PhotoGif && !allowPickingGif {
                bottomView.isHidden = false
                timeLength.text = "GIF"
                videoImgView.isHidden = true
                timeLength.xm_left = 5
                timeLength.textAlignment = .left
            }
        }
    }
    var allowPickingGif = false
    var allowPickingMultipleVideo = false
    var representedAssetIdentifier = "" //representedAssetIdentifier = model.asset.localIdentifier
    var imageRequestID:Int32 = 0
    var photoSelImageName = ""
    var photoDefImageName = ""
    var showSelectBtn = true {
        didSet {
            if !selectPhotoButton.isHidden {
                selectPhotoButton.isHidden = !showSelectBtn
            }
            if !selectImageView.isHidden {
                selectImageView.isHidden = !showSelectBtn
            }
        }
    }
    var allowPreview = false

    private var _imageView: UIImageView?
    private var imageView: UIImageView {
        if _imageView == nil {
            _imageView = UIImageView()
            _imageView?.contentMode = .scaleAspectFill
            _imageView?.clipsToBounds = true
            contentView.addSubview(_imageView!)
        }
        return _imageView!
    }

    private var _selectImageView: UIImageView?
    private var selectImageView: UIImageView {
        if _selectImageView == nil {
            _selectImageView = UIImageView()
            contentView.addSubview(_selectImageView!)
        }
        return _selectImageView!
    }

    private var _bottomView: UIView?
    private var bottomView: UIView {
        if _bottomView == nil {
            _bottomView = UIView()
            _bottomView?.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.8)
            contentView.addSubview(_bottomView!)
        }
        return _bottomView!
    }

    private var _timeLength: UILabel?
    private var timeLength: UILabel {
        if _timeLength == nil {
            _timeLength = UILabel()
            _timeLength?.font = UIFont.systemFont(ofSize: 11)
            _timeLength?.textColor = UIColor.white
            _timeLength?.textAlignment = .right
            bottomView.addSubview(_timeLength!)
        }
        return _timeLength!
    }

    private var _videoImgView: UIImageView?
    private var videoImgView: UIImageView {
        if _videoImgView == nil {
            _videoImgView = UIImageView()
            _videoImgView?.image = UIImage.imageNamedFromMyBundle(name: "VideoSendIcon")
            bottomView.addSubview(_videoImgView!)
        }
        return _videoImgView!
    }

    private var _progressView: XMProgressView?
    private var progressView: XMProgressView {
        if _progressView == nil {
            _progressView = XMProgressView()
            let progressWH: CGFloat = 20.0
            let progressXY: CGFloat = (xm_width - progressWH) * 0.5
            _progressView?.frame = CGRect.init(x: progressXY, y: progressXY, width: progressWH, height: progressWH)
            _progressView?.isHidden = true
            contentView.addSubview(_progressView!)
        }
        return _progressView!
    }

    private var bigImageRequestID: Int32 = 0

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fetchBigImage() {
        bigImageRequestID = XMImageManager.manager.getPhoto(asset: model?.asset, completion: { (photo, onfo, isDegraded) in
            if self._progressView != nil {
                self.hideProgressView()
            }
        }, progressHandler: { (progress, error, stop, info) in
            if self.model?.isSelected == true {
                self.progressView.isHidden = false
                self.progressView.progress = max(progress, 0.02)
                self.imageView.alpha = 0.4
                if progress >= 1.0 {
                    if self.imageProgressUpdate != nil {
                        self.imageProgressUpdate!()
                    }
                    self.hideProgressView()
                }
            } else {
                stop.pointee = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }

        }, isNetworkAccessAllowed: true)

    }
    func hideProgressView() {
        progressView.isHidden = true
        imageView.alpha = 1.0

    }

    @objc func selectPhotoButtonClick(btn:UIButton) {
        if didSelectPhoto != nil {
            didSelectPhoto!(btn.isSelected)
        }
        selectImageView.image = UIImage.imageNamedFromMyBundle(name: btn.isSelected ? photoSelImageName : photoDefImageName)
        if btn.isSelected {
            UIView.showOscillatoryAnimation(layer: _selectImageView?.layer, type: .ToBigger)
            fetchBigImage()
        } else {
            if bigImageRequestID > 0 && _progressView != nil {
                PHImageManager.default().cancelImageRequest(bigImageRequestID)
                hideProgressView()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if allowPreview {
            _selectPhotoButton?.frame = CGRect.init(x: Int(xm_width - 44), y: 0, width: 44, height: 44)
        } else {
            _selectPhotoButton?.frame = bounds
        }
        _selectImageView?.frame = CGRect.init(x: Int(xm_width - 27), y: 0, width: 27, height: 27)
        _imageView?.frame = CGRect.init(x: 0, y: 0, width: xm_width, height: xm_height)

        _bottomView?.frame = CGRect.init(x: 0.0, y: xm_height - 17, width: xm_width, height: 17)
        _videoImgView?.frame = CGRect.init(x: 8, y: 0, width: 17, height: 17)
        _timeLength?.frame = CGRect.init(x: videoImgView.xm_right, y: 0.0, width: xm_width - videoImgView.xm_right - 5.0, height: 17.0)

        type = model?.type ?? .Photo
        let tmp = showSelectBtn
        self.showSelectBtn = tmp
    }

}
class XMAlbumCell: UITableViewCell {
    var model: XMAlbumModel? {
        didSet {
            guard let albumMdel = model else { return  }
            let nameString = NSMutableAttributedString.init(string: albumMdel.name, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 16), NSAttributedStringKey.foregroundColor:UIColor.black])
            let countString = NSAttributedString.init(string: String("   (\(albumMdel.count))"), attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor:UIColor.lightGray])
            nameString.append(countString)
            titleLabel.attributedText = nameString

            XMImageManager.manager.getPostImage(model: model, allowPickingGif: UserDefaults.standard.bool(forKey: "xm_allowPickingGif")) {[weak self] (image) in
                self?.posterImageView.image = image
            }

            if albumMdel.selectedCount > 0 {
                selectedCountButton.isHidden = false
                selectedCountButton.setTitle(String(albumMdel.selectedCount), for: .normal)
            } else {
                selectedCountButton.isHidden = true
            }

        }
    }
    var selectedCountButton = UIButton()
    private var titleLabel = UILabel()
    private var posterImageView = UIImageView()


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setupView()
    }
    func setupView() {
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        contentView.addSubview(posterImageView)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)

        selectedCountButton.layer.cornerRadius = 12
        selectedCountButton.clipsToBounds = true
        selectedCountButton.backgroundColor = UIColor.red
        selectedCountButton.setTitleColor(UIColor.white, for: .normal)
        selectedCountButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(selectedCountButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedCountButton.frame = CGRect.init(x: xm_width - 24 - 30, y: 23, width: 24, height: 24)
        let titleHeight = Int(titleLabel.font.lineHeight)
        titleLabel.frame = CGRect.init(x: CGFloat(80), y: (xm_height - CGFloat(titleHeight)) * 0.5, width: xm_width - 80 - 50, height: CGFloat(titleHeight))
        posterImageView.frame = CGRect.init(x: 0, y: 0, width: 70, height: 70)
    }


}


class XMAssetCameraCell: UICollectionViewCell {
    var imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        clipsToBounds = true
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}













