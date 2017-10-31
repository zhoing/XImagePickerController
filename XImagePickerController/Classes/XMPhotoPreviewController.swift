//
//  XMPhotoPreviewController.swift
//  channel_sp
//
//  Created by ming on 2017/10/24.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

class XMPhotoPreviewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    var models: Array<XMAssetModel> = []
    var photos: Array<UIImage>?  {
        didSet {
            if photos != nil {
                photosTemp = photos!
            }
        }
    }
    var currentIndex = 0
    var isSelectOriginalPhoto = false
    var isCropImage = false
    var backButtonClickBlock: ((Bool) -> Void)?
    var doneButtonClickBlock: ((Bool) -> Void)?
    var doneButtonClickBlockCropMode: ((UIImage?, PHAsset?) -> Void)?
    var doneButtonClickBlockWithPreviewType: ((Array<UIImage>?, Array<PHAsset>?, Bool) -> Void)?

    private var layout: UICollectionViewFlowLayout?
    private var assetsTemp: Array<PHAsset> = []
    private var photosTemp: Array<UIImage> = []
    
    private var collectionView:UICollectionView?
    private var naviBar = UIView()
    private var backButton = UIButton.init(type: .custom)
    private var selectButton = UIButton.init(type: .custom)

    private var toolBar = UIView()
    private var doneButton = UIButton.init(type: .custom)
    private var numberImageView = UIImageView()
    private var numberLabel = UILabel()
    lazy private var originalPhotoButton = UIButton.init(type: .custom)
    private var originalPhotoLabel = UILabel()

    private var isHideNaviBar = false
    lazy private var cropBgView = UIView()
    lazy private var cropView = UIView()
    private var progress = 0.0

    private var alertView: UIAlertController?
    private var offsetItemCount: CGFloat = 0.0

    private var originStatusBarStyle: UIStatusBarStyle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        XMImageManager.manager.shouldFixOrientation = true
        if navigationController is XMImagePickerController {
            let imagePick = (navigationController as! XMImagePickerController)
            if models.count == 0 {
                models = imagePick.selectedModels
                assetsTemp = imagePick.selectedAssets
                isSelectOriginalPhoto = imagePick.isSelectOriginalPhoto
            }
        }
        view.backgroundColor = UIColor.black
        configCollectionView()
        configCustomNaviBar()
        configBottomToolBar()
        view.clipsToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeStatusBarOrientationNotification), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        if !xm_isGlobalHideStatusBar {
            UIApplication.shared.isStatusBarHidden = true
        }
        if currentIndex > 0 {
            collectionView?.setContentOffset(CGPoint.init(x: (view.xm_width + 20) * CGFloat(currentIndex), y: 0), animated: true)
        }
        refreshNaviBarAndBottomBarState()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        if !xm_isGlobalHideStatusBar {
            UIApplication.shared.isStatusBarHidden = false
        }
        XMImageManager.manager.shouldFixOrientation = false

    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    func configCustomNaviBar() {

        naviBar.backgroundColor = UIColor.init(red: CGFloat(34.0 / 255.0), green: CGFloat(34.0 / 255.0), blue: CGFloat(34.0 / 255.0), alpha: 0.7)
        view.addSubview(naviBar)

        backButton.setImage(UIImage.imageNamedFromMyBundle(name: "navi_back"), for: .normal)
        backButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -22, bottom: 0, right: 0)
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.addTarget(self, action: #selector(self.backButtonClick), for: .touchUpInside)
        naviBar.addSubview(backButton)

        if let imagePick = navigationController as? XMImagePickerController {
            selectButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick.photoDefImageName), for: .normal)
            selectButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick.photoSelImageName), for: .selected)
        }
        selectButton.addTarget(self, action: #selector(self.select(btn:)), for: .touchUpInside)
        naviBar.addSubview(selectButton)
    }
    func configBottomToolBar() {
        toolBar.backgroundColor = UIColor.init(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 0.7)
        let imagePick = navigationController as? XMImagePickerController
        if imagePick?.allowPickingOriginalPhoto == true {
            originalPhotoButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 0)
            originalPhotoButton.backgroundColor = UIColor.clear
            originalPhotoButton.addTarget(self, action: #selector(self.originalPhotoButtonClick), for: .touchUpInside)
            originalPhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
            originalPhotoButton.setTitle(imagePick?.fullImageBtnTitleStr, for: .normal)
            originalPhotoButton.setTitleColor(UIColor.lightGray, for: .normal)
            originalPhotoButton.setTitleColor(UIColor.white, for: .selected)
            originalPhotoButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick?.photoOriginDefImageName), for: .normal)
            originalPhotoButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick?.photoOriginSelImageName), for: .selected)

            originalPhotoLabel.font = UIFont.boldSystemFont(ofSize: 13)
            originalPhotoLabel.textColor = UIColor.white
            originalPhotoLabel.backgroundColor = UIColor.clear
            if isSelectOriginalPhoto {
                showPhotoBytes()
            }
            toolBar.addSubview(originalPhotoButton)

        }
        if imagePick != nil {
            doneButton.setTitle(imagePick!.doneBtnTitleStr, for: .normal)
            doneButton.setTitleColor(imagePick!.oKButtonTitleColorNormal, for: .normal)
        } else {
            doneButton.setTitle(Bundle.xm_localizedString(key: "Done"), for: .normal)
            doneButton.setTitleColor(UIColor.init(red: 83.0/255.0, green: 179.0/255.0, blue: 17.0/255.0, alpha: 1.0), for: .normal)
        }
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        doneButton.addTarget(self, action: #selector(self.doneButtonClick), for: .touchUpInside)
        toolBar.addSubview(doneButton)

        numberImageView.image = UIImage.imageNamedFromMyBundle(name: imagePick?.photoNumberIconImageName)
        numberImageView.backgroundColor = UIColor.clear
        numberImageView.isHidden = imagePick?.selectedAssets.count == 0
        toolBar.addSubview(numberImageView)


        numberLabel.font = UIFont.systemFont(ofSize: 15)
        numberLabel.textAlignment = .center
        numberLabel.textColor = UIColor.white
        numberLabel.text = String(imagePick?.selectedAssets.count ?? 0)
        numberLabel.isHidden = imagePick?.selectedAssets.count == 0
        numberLabel.backgroundColor = UIColor.clear
        originalPhotoButton.addSubview(originalPhotoLabel)
        toolBar.addSubview(numberLabel)

        view.addSubview(toolBar)
    }
    func configCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width:view.xm_width + 20, height: view.xm_height)

        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.black
        collectionView?.isPagingEnabled = true
        collectionView?.scrollsToTop = false
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.contentOffset = CGPoint.init(x: 0, y: 0)
        collectionView?.contentSize = CGSize.init(width: (view.xm_width + 20) * CGFloat(models.count), height: 0)
        collectionView?.register(XMPhotoPreviewCell.classForCoder(), forCellWithReuseIdentifier: "XMPhotoPreviewCell")
        collectionView?.register(XMVideoPreviewCell.classForCoder(), forCellWithReuseIdentifier: "XMVideoPreviewCell")
        collectionView?.register(XMGifPreviewCell.classForCoder(), forCellWithReuseIdentifier: "XMGifPreviewCell")
        view.addSubview(collectionView!)
    }
    func configCropView() {
         let imagePick = navigationController as? XMImagePickerController
        if imagePick?.allowCrop == true && imagePick?.showSelectBtn == false {
            cropView.removeFromSuperview()
            cropBgView.removeFromSuperview()

            cropBgView.isUserInteractionEnabled = false
            cropBgView.frame = view.bounds
            cropBgView.backgroundColor = UIColor.clear
            view.addSubview(cropBgView)
            XMImageCropManager.overlayClipping(view: cropBgView, cropRect: imagePick?.cropRect ?? CGRect.zero, containerView: view, isNeedCircleCrop: imagePick?.isNeedCircleCrop ?? false)
            cropView.isUserInteractionEnabled = false
            cropView.frame = imagePick?.cropRect ?? CGRect.zero
            cropView.backgroundColor = UIColor.clear
            cropView.layer.borderColor = UIColor.white.cgColor
            cropView.layer.borderWidth = 1.0
            if imagePick?.isNeedCircleCrop == true {
                cropView.layer.cornerRadius = (imagePick?.cropRect.width ?? 0.0) * 0.5
                cropView.clipsToBounds = true
            }
            view.addSubview(cropView)
            if imagePick?.cropViewSettingBlock != nil {
                imagePick?.cropViewSettingBlock!(cropView)
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        naviBar.frame = CGRect.init(x: 0, y: 0, width: view.xm_width, height: 64)
        toolBar.frame = CGRect.init(x: 0, y: view.xm_height - 44, width: view.xm_width, height: 44)

        backButton.frame = CGRect.init(x: 10, y: 10, width: 44, height: 44)
        selectButton.frame = CGRect.init(x: view.xm_width - 54, y: 10, width: 42, height: 42)
        if offsetItemCount > 0 {
            let offsetX: CGFloat = offsetItemCount * (view.xm_width + 20)
            collectionView?.contentOffset = CGPoint.init(x: offsetX, y: 0)
        }
        let imagePick = navigationController as? XMImagePickerController

        if imagePick?.allowCrop == true {
            collectionView?.reloadData()
        }
        if imagePick?.allowPickingOriginalPhoto == true {
            let fullImageWidth = imagePick?.fullImageBtnTitleStr.boundingRect(with: CGSize.init(width: Int.max, height: Int.max), options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)], context: nil).width ?? 0.0
            originalPhotoButton.frame = CGRect.init(x: 0, y: 0, width: fullImageWidth + 56, height: 44)
            originalPhotoLabel.frame = CGRect.init(x: fullImageWidth + 42, y: 0, width: 80, height: 44)
        }
        collectionView?.frame = CGRect.init(x: -10, y: 0, width: view.xm_width + 20, height: view.xm_height)
        doneButton.frame = CGRect.init(x: view.xm_width - 44 - 12, y: 0, width: 44, height: 44)
        numberImageView.frame = CGRect.init(x: view.xm_width - 56 - 28, y: 7, width: 30, height: 30)
        numberLabel.frame = numberImageView.frame

        configCropView()
    }
    @objc func didChangeStatusBarOrientationNotification() {
        offsetItemCount = (collectionView?.contentOffset.x ?? 0.0) / (view.xm_width + 20)
    }

    @objc func select(btn:UIButton) {
        guard let imagePick = navigationController as? XMImagePickerController else { return  }

        let model = models[currentIndex]
        if model.isSelected == false {
            if imagePick.selectedModels.count >= imagePick.maxImagesCount {
                imagePick.showAlertWithTitle(title: String.init(format: Bundle.xm_localizedString(key: "Select a maximum of %zd photos"), imagePick.maxImagesCount))
            } else {
                imagePick.selectedModels.append(model)
                if photos != nil {
                    imagePick.selectedAssets.append(assetsTemp[currentIndex])
                    photos?.append(photosTemp[currentIndex])
                }
                if model.type == .Video && imagePick.allowPickingMultipleVideo == false {
                    imagePick.showAlertWithTitle(title: Bundle.xm_localizedString(key: "Select the video when in multi state, we will handle the video as a photo"))
                }
            }
        } else {
            for model_item in imagePick.selectedModels {
                if XMImageManager.manager.getAssetIdentifier(asset: model.asset) == XMImageManager.manager.getAssetIdentifier(asset: model_item.asset) {
                    let selectedModelsTmp = imagePick.selectedModels
                    for i in 0 ..< selectedModelsTmp.count {
                        if model.isEqual(model_item) {
                            imagePick.selectedModels.remove(at: i)
                            break
                        }
                    }
                    if photos != nil {
                        let selectedAssetsTmp = imagePick.selectedAssets
                        for i in 0 ..< selectedAssetsTmp.count {
                            if selectedAssetsTmp[i].isEqual(assetsTemp[currentIndex]) {
                                imagePick.selectedAssets.remove(at: i)
                                break
                            }
                        }
                        photos?.xm_remover(obj: photosTemp[currentIndex])
                    }
                    break
                }
            }
        }
        model.isSelected = !model.isSelected
        refreshNaviBarAndBottomBarState()
        if model.isSelected {
            UIView.showOscillatoryAnimation(layer: selectButton.imageView?.layer, type: .ToBigger)
        }
        UIView.showOscillatoryAnimation(layer: numberImageView.layer, type: .ToSmaller)

    }

    @objc func backButtonClick() {
        if navigationController?.childViewControllers.count ?? 0 < 2 {
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
            if backButtonClickBlock != nil {
                backButtonClickBlock!(isSelectOriginalPhoto)
            }
        }
    }

    @objc func doneButtonClick() {
        guard let imagePick = navigationController as? XMImagePickerController else { return  }

        if  progress > 0 && progress < 1 && (selectButton.isSelected || imagePick.selectedModels.count == 0) {
            alertView = imagePick.showAlertWithTitle(title: Bundle.xm_localizedString(key: "Synchronizing photos from iCloud"))
        }
        if imagePick.selectedModels.count == 0 && imagePick.minImagesCount <= 0 {
            imagePick.selectedModels.append(models[currentIndex])
        }
        if imagePick.allowCrop {
            let indexpath = IndexPath.init(row: currentIndex, section: 0)
            let cell = collectionView?.cellForItem(at: indexpath) as? XMPhotoPreviewCell
            var cropedImage = XMImageCropManager.cropImageView(imageView: cell?.previewView.imageView, toRect: imagePick.cropRect, zoomScale: cell?.previewView.scrollView.zoomScale ?? 0.0, containerView: view)
            if imagePick.isNeedCircleCrop {
                cropedImage = XMImageCropManager.circularClipImage(phtoto: cropedImage)
            }
            if doneButtonClickBlockCropMode != nil {
                doneButtonClickBlockCropMode!(cropedImage, models[currentIndex].asset)
            }
        } else {
            if doneButtonClickBlock != nil {
                doneButtonClickBlock!(isSelectOriginalPhoto)
            }
        }
        if doneButtonClickBlockWithPreviewType != nil {
            doneButtonClickBlockWithPreviewType!(photos, imagePick.selectedAssets, isSelectOriginalPhoto)
        }
    }

    @objc func originalPhotoButtonClick() {
        originalPhotoButton.isSelected = !originalPhotoButton.isSelected
        isSelectOriginalPhoto = originalPhotoButton.isSelected
        originalPhotoLabel.isHidden = !originalPhotoButton.isSelected
        if isSelectOriginalPhoto {
            showPhotoBytes()
            if selectButton.isSelected == false {
                guard let imagePick = navigationController as? XMImagePickerController else { return  }
                if imagePick.selectedModels.count < imagePick.maxImagesCount && imagePick.showSelectBtn {
                    self.select(btn: selectButton)
                }
            }
        }
    }
    func didTapPreviewCell() {
        isHideNaviBar = !isHideNaviBar
        naviBar.isHidden = isHideNaviBar
        toolBar.isHidden = isHideNaviBar
    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offSetWidth = scrollView.contentOffset.x
        offSetWidth = offSetWidth + (view.xm_width + 20) * 0.5
        let currentIndexTmp = Int(offSetWidth / (view.xm_width + 20))
        if currentIndex < models.count && currentIndexTmp != currentIndex {
            currentIndex = currentIndexTmp
            refreshNaviBarAndBottomBarState()
        }
        NotificationCenter.default.post(name: NSNotification.Name.init("photoPreviewCollectionViewDidScroll"), object: nil)
    }

    // MARK: - UICollectionViewDataSource && Delegate


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imagePick = navigationController as? XMImagePickerController
        let model = models[indexPath.row]
        var cell:XMAssetPreviewCell?

        if imagePick?.allowPickingMultipleVideo == true && model.type == .Video {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "XMVideoPreviewCell", for: indexPath) as? XMVideoPreviewCell
        } else if imagePick?.allowPickingMultipleVideo == true && model.type == .PhotoGif && imagePick?.allowPickingGif == true {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "XMGifPreviewCell", for: indexPath) as? XMGifPreviewCell
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "XMPhotoPreviewCell", for: indexPath) as? XMPhotoPreviewCell
            let photoCell = cell as? XMPhotoPreviewCell
            photoCell?.cropRect = imagePick?.cropRect ?? CGRect.zero
            photoCell?.allowCrop = imagePick?.allowCrop ?? true
            weak var weakPhotoCell = photoCell

            photoCell?.imageProgressUpdateBlock = {[weak self] progress in
                self?.progress = progress
                if progress >= 1 {
                    if self?.isSelectOriginalPhoto == true {
                        self?.showPhotoBytes()
                    }
                    if self?.alertView != nil && collectionView.visibleCells.contains(weakPhotoCell!){
                        self?.alertView?.dismiss(animated: true, completion: nil)
                        self?.alertView = nil
                        self?.doneButtonClick()
                    }
                }
            }
        }
        cell?.model = model
        cell?.singleTapGestureBlock = {[weak self] in
            self?.didTapPreviewCell()
        }
        return cell!
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is XMPhotoPreviewCell {
            (cell as! XMPhotoPreviewCell).recoverSubviews()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is XMPhotoPreviewCell {
            (cell as! XMPhotoPreviewCell).recoverSubviews()
        } else if cell is XMVideoPreviewCell {
            (cell as! XMVideoPreviewCell).pausePlayerAndShowNaviBar()
        }
    }

    func refreshNaviBarAndBottomBarState() {
        guard let imagePick = navigationController as? XMImagePickerController else { return }
        let model = models[currentIndex]
        selectButton.isSelected = model.isSelected
        numberLabel.text = String(imagePick.selectedModels.count)
        numberImageView.isHighlighted = imagePick.selectedModels.count == 0 || isHideNaviBar || isCropImage
        numberLabel.isHighlighted = imagePick.selectedModels.count == 0 || isHideNaviBar || isCropImage

        originalPhotoButton.isSelected = isSelectOriginalPhoto
        originalPhotoButton.isHidden = !originalPhotoButton.isSelected

        if isSelectOriginalPhoto {
            showPhotoBytes()
        }
        if isHideNaviBar == false {
            if model.type == .Video {
                originalPhotoButton.isHidden = true
                originalPhotoLabel.isHidden = true
            } else {
                originalPhotoButton.isHidden = false
                if isSelectOriginalPhoto {
                    originalPhotoLabel.isHidden = false
                }
            }
        }
        doneButton.isHidden = false
        selectButton.isHidden = imagePick.showSelectBtn
        if XMImageManager.manager.isPhotoSelectableWithAsset(asset: model.asset) {
            numberLabel.isHidden = false
            numberImageView.isHidden = false
            selectButton.isHidden = false
            originalPhotoButton.isHidden = false
            originalPhotoLabel.isHidden = false
            doneButton.isHidden = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func showPhotoBytes() {
        if currentIndex <= models.count {
            XMImageManager.manager.getPhotosBytes(models: [models[currentIndex]]) {[weak self] (dataLength) in
                self?.originalPhotoLabel.text = dataLength
            }
        }
    }

}
