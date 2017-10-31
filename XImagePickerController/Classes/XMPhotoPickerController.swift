//
//  TZPhotoPickerController.swift
//  channel_sp
//
//  Created by ming on 2017/10/24.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos


let itemMargin: CGFloat = 5
var AssetGridThumbnailSize = CGSize.zero



class XMPhotoPickerController : UIViewController, UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    var columnNumber = 4
    var albumModel: XMAlbumModel?

    private var models: Array<XMAssetModel> = []
    private var collectionView:UICollectionView?
    private var layout: UICollectionViewFlowLayout?
    private var backButton = UIButton.init(type: .custom)
    private var selectButton = UIButton.init(type: .custom)

    private var toolBar = UIView()
    private var previewButton = UIButton.init(type: .custom)
    private var doneButton = UIButton.init(type: .custom)
    private var numberImageView = UIImageView()
    private var numberLabel = UILabel()
    lazy private var originalPhotoButton = UIButton.init(type: .custom)
    private var originalPhotoLabel = UILabel()
    private var divideLine = UIView()

    private var shouldScrollToBottom = false
    private var showTakePhotoBtn = false
    private var offsetItemCount: CGFloat = 0.0
    private var isSelectOriginalPhoto = false
    private var location: CLLocation?
    private var _imagePickerVc: UIImagePickerController?
    private var imagePickerVc: UIImagePickerController {
        if _imagePickerVc == nil {
            _imagePickerVc = UIImagePickerController()
            _imagePickerVc?.delegate = self
            _imagePickerVc?.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
            _imagePickerVc?.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor

            var barItme = UIBarButtonItem()
            guard let imagePick = navigationController as? XMImagePickerController else { return  _imagePickerVc!}

            if #available(iOS 9.0, *) {
                barItme = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIImagePickerController.self])
            } else {
                barItme = UIBarButtonItem.appearance(for: _imagePickerVc!.traitCollection)//UITraitCollection
            }
            barItme.setTitleTextAttributes([NSAttributedStringKey.foregroundColor : imagePick.barItemTextColor, NSAttributedStringKey.font : imagePick.barItemTextFont], for: .normal)
        }
        return _imagePickerVc!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let imagePick = navigationController as? XMImagePickerController
        isSelectOriginalPhoto = imagePick?.isSelectOriginalPhoto ?? false
        shouldScrollToBottom = true
        view.backgroundColor = UIColor.white
        navigationItem.title = albumModel?.name ?? Bundle.xm_localizedString(key: "All Photos")

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: imagePick?.cancelBtnTitleStr, style: .plain, target: imagePick, action: #selector(imagePick?.cancelButtonClick))

        if imagePick?.navLeftBarButtonSettingBlock != nil {
            let btn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 44, height: 44))
            btn.addTarget(self, action: #selector(self.navLeftBarButtonClick), for: .touchUpInside)
            navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: btn)
        }
        showTakePhotoBtn = (albumModel == nil || albumModel?.isCameraRoll == true) && imagePick?.allowTakePicture == true
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangeStatusBarOrientationNotification), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)

    }
    func fetchAssetModels() {
        let imagePick = navigationController as? XMImagePickerController

        imagePick?.showProgressHUD()
        DispatchQueue.global().async {
            if self.albumModel == nil {
                XMImageManager.manager.getCameraRollAlbum(allowPickingVideo: imagePick?.allowPickingVideo ?? true, allowPickingImage: imagePick?.allowPickingImage ?? true, completion: { (model) in
                    self.albumModel = model
                    self.models = model.models
                    self.initSubviews()
                })
            } else {
                if self.albumModel?.models.count == 0 {
                    XMImageManager.manager.getAssets(result: self.albumModel?.result, allowPickingVideo: imagePick?.allowPickingVideo ?? true, allowPickingImage: imagePick?.allowPickingImage ?? true, allowPickingGif: imagePick?.allowPickingGif ?? true, completion: { (assetModels) in
                        if assetModels != nil {
                            self.models = assetModels!
                            self.initSubviews()
                        }
                    })
                } else {
                    self.models = self.albumModel!.models
                    self.initSubviews()
                }
            }
        }
    }

    func initSubviews() {
        DispatchQueue.main.async {
            let imagePick = self.navigationController as? XMImagePickerController
            imagePick?.hideProgressHUD()
            self.checkSelectedModels()
            self.configCollectionView()
            self.collectionView?.isHidden = false
            self.configBottomToolBar()
            self.scrollCollectionViewToBottom()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        (navigationController as? XMImagePickerController)?.isSelectOriginalPhoto = isSelectOriginalPhoto
    }
    override var prefersStatusBarHidden: Bool {
        return false
    }
    func configCollectionView() {
        layout = UICollectionViewFlowLayout()

        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: layout!)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.contentInset = UIEdgeInsets.init(top: itemMargin, left: itemMargin, bottom: itemMargin, right: itemMargin)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.alwaysBounceHorizontal = false

        if showTakePhotoBtn && (navigationController as? XMImagePickerController)?.allowTakePicture == true{
            collectionView?.contentSize = CGSize.init(width: view.xm_width, height: CGFloat(models.count + columnNumber) / CGFloat(columnNumber) * view.xm_width)
        } else {
            collectionView?.contentSize = CGSize.init(width: view.xm_width, height: CGFloat(models.count + columnNumber - 1) / CGFloat(columnNumber) * view.xm_width)
        }
        collectionView?.register(XMAssetCell.classForCoder(), forCellWithReuseIdentifier: "XMAssetCell")
        collectionView?.register(XMAssetCameraCell.classForCoder(), forCellWithReuseIdentifier: "XMAssetCameraCell")
        view.addSubview(collectionView!)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var scale: CGFloat = 2.0
        if UIScreen.main.bounds.width > 600 {
            scale = 1.0
        }
        AssetGridThumbnailSize = CGSize.init(width: layout?.itemSize.width ?? 0.0 * scale, height: layout?.itemSize.height ?? 0.0 * scale)

        if albumModel == nil || albumModel?.models.count == 0 {
            fetchAssetModels()
        } else {
            models = albumModel!.models
            initSubviews()
        }
    }

    func configBottomToolBar() {
        let imagePick = navigationController as? XMImagePickerController
        if imagePick?.showSelectBtn == false {
            return
        }
        toolBar.backgroundColor = UIColor.init(red: 253.0 / 255.0, green: 253.0 / 255.0, blue: 253.0 / 255.0, alpha: 0.7)
        previewButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 0)
        previewButton.addTarget(self, action: #selector(self.previewButtonClick), for: .touchUpInside)
        previewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        previewButton.setTitle(imagePick?.previewBtnTitleStr, for: .normal)
        previewButton.setTitleColor(UIColor.black, for: .normal)
        previewButton.setTitleColor(UIColor.lightGray, for: .disabled)
        previewButton.isEnabled = imagePick?.selectedModels.count ?? 0 > 0
        toolBar.addSubview(previewButton)

        if imagePick?.allowPickingOriginalPhoto == true {
            originalPhotoButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 0)
            originalPhotoButton.addTarget(self, action: #selector(self.originalPhotoButtonClick), for: .touchUpInside)
            originalPhotoButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            originalPhotoButton.setTitle(imagePick?.fullImageBtnTitleStr, for: .normal)
            originalPhotoButton.setTitleColor(UIColor.lightGray, for: .normal)
            originalPhotoButton.setTitleColor(UIColor.black, for: .selected)
            originalPhotoButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick?.photoOriginDefImageName), for: .normal)
            originalPhotoButton.setImage(UIImage.imageNamedFromMyBundle(name: imagePick?.photoOriginSelImageName), for: .selected)
            originalPhotoButton.imageView?.frame = CGRect.init(x: 0, y: 14.5, width: 20, height: 21)
            originalPhotoButton.isSelected = isSelectOriginalPhoto
            originalPhotoButton.isEnabled = imagePick?.selectedModels.count ?? 0 > 0

            originalPhotoLabel.font = UIFont.boldSystemFont(ofSize: 16)
            originalPhotoLabel.textColor = UIColor.black
            if isSelectOriginalPhoto {
                showPhotoBytes()
            }
            toolBar.addSubview(originalPhotoButton)
        }

        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        doneButton.addTarget(self, action: #selector(self.doneButtonClick), for: .touchUpInside)

        if imagePick != nil {
            doneButton.setTitle(imagePick?.doneBtnTitleStr, for: .normal)
            doneButton.setTitleColor(imagePick?.oKButtonTitleColorNormal, for: .normal)
            doneButton.setTitleColor(imagePick?.oKButtonTitleColorDisabled, for: .disabled)

        } else {
            doneButton.setTitle(Bundle.xm_localizedString(key: "Done"), for: .normal)
            doneButton.setTitleColor(UIColor.init(red: 83.0/255.0, green: 179.0/255.0, blue: 17.0/255.0, alpha: 1.0), for: .normal)
            doneButton.setTitleColor(UIColor.init(red: 83.0/255.0, green: 179.0/255.0, blue: 17.0/255.0, alpha: 1.0), for: .disabled)
        }
        doneButton.isEnabled = (imagePick?.selectedModels.count ?? 0) > 0 || (imagePick?.alwaysEnableDoneBtn == true)
        toolBar.addSubview(doneButton)

        numberImageView.image = UIImage.imageNamedFromMyBundle(name: imagePick?.photoNumberIconImageName)
        numberImageView.backgroundColor = UIColor.clear
        numberImageView.isHidden = imagePick?.selectedModels.count == 0
        toolBar.addSubview(numberImageView)


        numberLabel.font = UIFont.systemFont(ofSize: 15)
        numberLabel.textAlignment = .center
        numberLabel.textColor = UIColor.white
        numberLabel.text = String(imagePick?.selectedAssets.count ?? 0)
        numberLabel.isHidden = imagePick?.selectedAssets.count == 0
        numberLabel.backgroundColor = UIColor.clear
        originalPhotoButton.addSubview(originalPhotoLabel)
        toolBar.addSubview(numberLabel)

        let rgb: CGFloat = 222.0 / 255.0
        divideLine.backgroundColor = UIColor.init(red: rgb, green: rgb, blue: rgb, alpha: 1.0)
        toolBar.addSubview(divideLine)
        view.addSubview(toolBar)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let imagePick = navigationController as? XMImagePickerController
        var top: CGFloat = 0.0
        var tableViewHeight: CGFloat = 0.0
        let naviBarHeight: CGFloat = navigationController?.navigationBar.xm_height ?? 44.0
        let isStatusBarHidden = UIApplication.shared.isStatusBarHidden
        if navigationController?.navigationBar.isTranslucent == true {
            top = naviBarHeight
            if !isStatusBarHidden {
                top = top + UIApplication.shared.statusBarFrame.height
            }
            tableViewHeight = imagePick?.showSelectBtn == true ? view.xm_height - top - toolBar.xm_height : view.xm_height - top
        } else {
            tableViewHeight = imagePick?.showSelectBtn == true ? view.xm_height  - toolBar.xm_height : view.xm_height
        }
        let itemWH = (self.view.xm_width - CGFloat(self.columnNumber + 1) * itemMargin) / CGFloat(columnNumber)
        layout?.itemSize = CGSize.init(width: itemWH, height: itemWH)
        layout?.minimumInteritemSpacing = itemMargin;
        layout?.minimumLineSpacing = itemMargin;

        collectionView?.frame =  CGRect.init(x: 0, y: top, width: view.xm_width, height: tableViewHeight)
        collectionView?.setCollectionViewLayout(layout!, animated: true)
        if offsetItemCount > 0 {
            let offsetX: CGFloat = offsetItemCount * (layout?.itemSize.height ?? 0.0 + CGFloat(layout?.minimumLineSpacing ?? 0))
            collectionView?.contentOffset = CGPoint.init(x: offsetX, y: 0)
        }

        var yOffset: CGFloat = 0.0
        if navigationController?.navigationBar.isHidden == false {
            yOffset = view.xm_height - 50
        } else {
            yOffset = view.xm_height - naviBarHeight - 20 - 50
        }
        toolBar.frame = CGRect.init(x: 0, y: yOffset, width: view.xm_width, height: 50)
        var previewWidth = xm_LableSize(imagePick?.previewBtnTitleStr ?? "", UIFont.systemFont(ofSize: 16)).width

        if imagePick?.allowPreview == false {
            previewWidth = 0
        }
        if imagePick?.showSelectBtn == false {
            previewWidth = 0
        }
        previewButton.frame = CGRect.init(x: 10, y: 3, width: previewWidth, height: 44)
        if imagePick?.allowPickingOriginalPhoto == true {
            let fullImageWidth = xm_LableSize(imagePick?.fullImageBtnTitleStr ?? "", UIFont.systemFont(ofSize: 13)).width
            originalPhotoButton.frame = CGRect.init(x: previewButton.frame.maxX, y: 0, width: fullImageWidth + 50, height: 50)
            originalPhotoLabel.frame = CGRect.init(x: fullImageWidth + 46, y: 0, width: 80, height: 50)

        }
        doneButton.frame = CGRect.init(x: view.xm_width - 44 - 12, y: 3, width: 44, height: 44)
        numberImageView.frame = CGRect.init(x: view.xm_width - 56 - 28, y: 10, width: 30, height: 30)
        numberLabel.frame = numberImageView.frame
        divideLine.frame = CGRect.init(x: 0, y: 0, width: view.xm_width, height: 1)
        collectionView?.reloadData()
    }

    @objc func didChangeStatusBarOrientationNotification() {
        offsetItemCount = (collectionView?.contentOffset.x ?? 0.0) / ((layout?.itemSize.height ?? 0.01) + (layout?.minimumLineSpacing ?? 0.01));
    }
    @objc func navLeftBarButtonClick() {
        navigationController?.popViewController(animated: true)
    }
    @objc func previewButtonClick() {
        pushPhotoPrevireViewController(photoPreviewVc: XMPhotoPreviewController())
    }

    @objc func originalPhotoButtonClick() {
        originalPhotoButton.isSelected = !originalPhotoButton.isSelected
        isSelectOriginalPhoto = originalPhotoButton.isSelected
        originalPhotoLabel.isHidden = !originalPhotoButton.isSelected
        if isSelectOriginalPhoto {
            showPhotoBytes()
        }
    }
    @objc func doneButtonClick() {
        guard let imagePick = navigationController as? XMImagePickerController else { return }
        if imagePick.minImagesCount > 0 && imagePick.selectedModels.count < imagePick.minImagesCount {
            imagePick.showAlertWithTitle(title: String.init(format: Bundle.xm_localizedString(key: "Select a minimum of %zd photos"), imagePick.minImagesCount))
            return
        }
        imagePick.showProgressHUD()
        var photos: Array<UIImage> = []
        var assets: Array<PHAsset> = []
        var infoArr: Array<Dictionary<AnyHashable, Any>> = []
        var havenotShowAlert = true
        var alertView: UIAlertController?

        XMImageManager.manager.shouldFixOrientation = true
        for i in 0 ..< imagePick.selectedModels.count {
            let model = imagePick.selectedModels[i]
            XMImageManager.manager.getPhoto(asset: model.asset, completion: { (photo, info, isDegraded) in
                    var image = photo

                    if isDegraded == true {
                        return
                    }
                    if image != nil {
                        image = self.scale(image: image, toSize: CGSize.init(width: imagePick.photoWidth, height: imagePick.photoWidth * image!.size.height / image!.size.width))
                        photos.append(image!)
                    }
                    if info != nil {
                        infoArr.append(info!)
                    }
                    assets.append(model.asset)

                    if havenotShowAlert && photos.count == imagePick.selectedModels.count {
                        imagePick.hideProgressHUD()
                        self.didGet(allPhotos: photos, assets: assets, infos: infoArr)
                    }

            }, progressHandler: { (progress, error, stop, info) in
                if progress < 1 &&  havenotShowAlert && alertView == nil {
                    imagePick.hideProgressHUD()
                    alertView = imagePick.showAlertWithTitle(title: Bundle.xm_localizedString(key: "Synchronizing photos from iCloud"))
                    havenotShowAlert = false
                }
                if progress >= 1 {
                    havenotShowAlert = true
                }
            }, isNetworkAccessAllowed: true)
        }
        if imagePick.selectedModels.count <= 0 {
            self.didGet(allPhotos: photos, assets: assets, infos: infoArr)
        }
    }
    func didGet(allPhotos: Array<UIImage>?, assets: Array<PHAsset>?, infos: Array<Dictionary<AnyHashable, Any>>?) {
        let imagePick = navigationController as? XMImagePickerController
        imagePick?.hideProgressHUD()

        if imagePick?.autoDismiss == true {
            navigationController?.dismiss(animated: true, completion: {
                self.callDelegateMethod(photos: allPhotos, assets: assets, infos: infos);
            })
        } else {
            self.callDelegateMethod(photos: allPhotos, assets: assets, infos: infos);
        }
    }

    func callDelegateMethod(photos: Array<UIImage>?, assets: Array<PHAsset>?, infos: Array<Dictionary<AnyHashable, Any>>?) {
        guard let imagePick = navigationController as? XMImagePickerController else { return }
        if imagePick.pickerDelegate?.responds(to: #selector(imagePick.pickerDelegate?.imagePickerController(_:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:))) == true {
            imagePick.pickerDelegate?.imagePickerController!(imagePick, didFinishPickingPhotos: photos, sourceAssets: assets, isSelectOriginalPhoto: isSelectOriginalPhoto, infos: infos)

        }
        if imagePick.pickerDelegate?.responds(to: #selector(imagePick.pickerDelegate?.imagePickerController(_:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:))) == true {
            imagePick.pickerDelegate?.imagePickerController!(imagePick, didFinishPickingPhotos: photos, sourceAssets: assets, isSelectOriginalPhoto: isSelectOriginalPhoto)
        }
        if imagePick.didFinishPickingPhotosHandle != nil {
            imagePick.didFinishPickingPhotosHandle!(photos, assets, isSelectOriginalPhoto)
        }
        if imagePick.didFinishPickingPhotosWithInfosHandle != nil {
            imagePick.didFinishPickingPhotosWithInfosHandle!(photos, assets, isSelectOriginalPhoto, infos)
        }
    }

    // MARK: - UICollectionViewDataSource && Delegate


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showTakePhotoBtn {
            let imagePick = navigationController as? XMImagePickerController
            if imagePick?.allowPickingImage == true && imagePick?.allowTakePicture == true {
                return models.count + 1
            }
        }
        return models.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imagePick = navigationController as? XMImagePickerController
        if (imagePick?.sortAscendingByModificationDate == true && indexPath.row >= models.count) || (imagePick?.sortAscendingByModificationDate == false && indexPath.row == 0) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "XMAssetCameraCell", for: indexPath) as? XMAssetCameraCell
            cell?.imageView.image = UIImage.imageNamedFromMyBundle(name: imagePick?.takePictureImageName)
            return cell!
        }
        //        let model = models[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "XMAssetCell", for: indexPath) as? XMAssetCell
        var index = indexPath.row

        if showTakePhotoBtn && imagePick?.sortAscendingByModificationDate == false {
            index = index - 1
        }
        let model = models[index]

        cell?.allowPickingMultipleVideo = imagePick?.allowPickingMultipleVideo ?? false
        cell?.photoDefImageName = imagePick?.photoDefImageName ?? ""
        cell?.photoSelImageName = imagePick?.photoSelImageName ?? ""

        cell?.allowPickingGif = imagePick?.allowPickingGif ?? false
        cell?.model = model
        cell?.showSelectBtn = imagePick?.showSelectBtn ?? false
        cell?.allowPreview = imagePick?.allowPreview ?? false
        weak var weakCell = cell
        cell?.imageProgressUpdate = {[weak self] in
            self?.showPhotoBytes()
        }
        cell?.didSelectPhoto = {[weak self] (isSelected) in
            if isSelected {
                weakCell?.selectPhotoButton.isSelected = false
                weakCell?.model?.isSelected = false
                if imagePick != nil {
                    for itmeModel in imagePick!.selectedModels {
                        if XMImageManager.manager.getAssetIdentifier(asset: model.asset) == XMImageManager.manager.getAssetIdentifier(asset: itmeModel.asset) {
                            imagePick?.selectedModels.xm_remover(obj: itmeModel)
                            break
                        }
                    }
                }
                self?.refreshBottomToolBarStatus()
            } else {
                if imagePick != nil {
                    if imagePick!.selectedModels.count < imagePick!.maxImagesCount {
                        weakCell?.selectPhotoButton.isSelected = true
                        model.isSelected = true
                        imagePick?.selectedModels.append(model)
                        self?.refreshBottomToolBarStatus()
                    } else {
                        imagePick?.showAlertWithTitle(title: String.init(format: Bundle.xm_localizedString(key: "Select a maximum of %zd photos"), imagePick!.maxImagesCount))
                    }
                }
            }
            UIView.showOscillatoryAnimation(layer: self?.numberImageView.layer, type: .ToSmaller)
        }
        return cell!
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imagePick = navigationController as? XMImagePickerController
        if (imagePick?.sortAscendingByModificationDate == true && indexPath.row >= models.count) || (imagePick?.sortAscendingByModificationDate == false && indexPath.row == 0) {
            takePhoto();
            return
        }
        var index = indexPath.row
        if imagePick?.sortAscendingByModificationDate == false && showTakePhotoBtn {
            index = index - 1
        }
        let model = models[index]
        if model.type == .Video && imagePick?.allowPickingMultipleVideo == false {
            if imagePick?.selectedModels.count ?? 0 > 0 {
                imagePick?.showAlertWithTitle(title: Bundle.xm_localizedString(key: "Can not choose both video and photo"))
            } else {
                let videoPlayerVc = XMVideoPlayerController()
                videoPlayerVc.model = model
                navigationController?.pushViewController(videoPlayerVc, animated: true)
            }
        } else if model.type == .PhotoGif && imagePick?.allowPickingGif == false && imagePick?.allowPickingMultipleVideo == false {
            if imagePick?.selectedModels.count ?? 0 > 0 {
                imagePick?.showAlertWithTitle(title: Bundle.xm_localizedString(key: "Can not choose both photo and GIF"))
            } else {
                let videoPlayerVc = XMGifPhotoPreviewController()
                videoPlayerVc.model = model
                navigationController?.pushViewController(videoPlayerVc, animated: true)
            }
        } else {
            let photoPreviewVC = XMPhotoPreviewController()
            photoPreviewVC.models = models
            photoPreviewVC.currentIndex = index
            self.pushPhotoPrevireViewController(photoPreviewVc: photoPreviewVC)
        }
    }
    func takePhoto() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if authStatus == .restricted || authStatus == .denied {
            var info = Bundle.main.localizedInfoDictionary
            if info == nil {
                info = Bundle.main.infoDictionary
            }

            var appName = info?["CFBundleDisplayName"] as? String
            if appName == nil {
                appName = info?["CFBundleName"] as? String
            }
            let message = String.init(format: "Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\"", appName ?? "")
            
            let alert =  UIAlertController.init(title:  Bundle.xm_localizedString(key: "Can not use camera"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction.init(title: Bundle.xm_localizedString(key: "Setting"), style: .default, handler: { (alertAction) in
                if UIApplication.shared.canOpenURL(URL.init(string: UIApplicationOpenSettingsURLString)!){
                    UIApplication.shared.openURL(URL.init(string: UIApplicationOpenSettingsURLString)!)
                }
            }))
            present(alert, animated: true, completion: nil)
            return
        } else if authStatus == .denied{
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.pushImagePickerController()
                    }
                }
            })

        } else {
            pushImagePickerController()
        }

    }
    func pushImagePickerController() {
        XMLocationManager.manager.startLocation(success: { (location) in
            self.location = location

        }) { (error) in
            self.location = nil
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerVc = UIImagePickerController()
            pickerVc.sourceType = .camera
            pickerVc.modalPresentationStyle = .overCurrentContext
            pickerVc.delegate = self
            pickerVc.cameraDevice = .rear
            pickerVc.cameraCaptureMode = .photo

            present(pickerVc, animated: true, completion: nil)
        } else {
            print("模拟器中无法打开照相机,请在真机中使用")
        }
    }

    func refreshBottomToolBarStatus() {
        guard let imagePick = navigationController as? XMImagePickerController else { return }
        previewButton.isEnabled = imagePick.selectedModels.count > 0
        doneButton.isEnabled = imagePick.selectedModels.count > 0 || imagePick.alwaysEnableDoneBtn

        numberImageView.isHidden = imagePick.selectedModels.count <= 0
        numberLabel.isHidden = imagePick.selectedModels.count <= 0
        numberLabel.text = String(imagePick.selectedModels.count)

        originalPhotoButton.isEnabled = imagePick.selectedModels.count > 0
        originalPhotoButton.isSelected = isSelectOriginalPhoto && originalPhotoButton.isEnabled
        originalPhotoButton.isHidden = !originalPhotoButton.isSelected
        if isSelectOriginalPhoto {
            showPhotoBytes()
        }
    }

    func pushPhotoPrevireViewController(photoPreviewVc: XMPhotoPreviewController) {
        photoPreviewVc.isSelectOriginalPhoto = isSelectOriginalPhoto
        photoPreviewVc.backButtonClickBlock = {[weak self] (isSelectOriginalPhoto) in
            self?.isSelectOriginalPhoto = isSelectOriginalPhoto
            self?.collectionView?.reloadData()
            self?.refreshBottomToolBarStatus()
        }
        photoPreviewVc.doneButtonClickBlock = {[weak self] (isSelectOriginalPhoto) in
            self?.isSelectOriginalPhoto = isSelectOriginalPhoto
            self?.doneButtonClick()
        }
        photoPreviewVc.doneButtonClickBlockCropMode = {[weak self] (cropedImage, asset) in
            if cropedImage != nil && asset != nil {
                self?.didGet(allPhotos: [cropedImage!], assets: [asset!], infos: nil)
            }
        }
        navigationController?.pushViewController(photoPreviewVc, animated: true)
    }

    func showPhotoBytes() {
        guard let imagePick = navigationController as? XMImagePickerController else { return }
        XMImageManager.manager.getPhotosBytes(models: imagePick.selectedModels) {[weak self] (dataLength) in
            self?.originalPhotoLabel.text = dataLength
        }
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

    func scrollCollectionViewToBottom() {
        let imagePick = navigationController as? XMImagePickerController

        if shouldScrollToBottom && models.count > 0 {
            var item = 0
            if imagePick?.sortAscendingByModificationDate == true {
                item = models.count - 1
                if showTakePhotoBtn {
                    if imagePick?.allowPickingImage == true && imagePick?.allowTakePicture == true {
                        item = item + 1
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: {
                self.collectionView?.scrollToItem(at: IndexPath.init(item: item, section: 0), at: .bottom, animated: false)
                self.shouldScrollToBottom = false
                self.collectionView?.isHidden = false
            })
        } else {
            collectionView?.isHidden = false
        }
    }
    func checkSelectedModels() {
        let imagePick = navigationController as? XMImagePickerController
        for model in models {
            model.isSelected = false
            if imagePick != nil {
                var selectedAsset: Array<PHAsset> = []

                for selectedModel in imagePick!.selectedModels {
                    selectedAsset.append(selectedModel.asset)
                }
                if XMImageManager.manager.isContain(assets: selectedAsset, asset: model.asset) {
                    model.isSelected = true
                }
            }
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let type = info[UIImagePickerControllerMediaType] as? String
        if type == "public.image" {
            let imagePick = navigationController as? XMImagePickerController
            let photo = info[UIImagePickerControllerOriginalImage] as? UIImage
            if photo != nil {
                imagePick?.showProgressHUD()
                XMImageManager.manager.savePhoto(photo: photo!, location: location, completion: {[weak self] (error) in
                    if error == nil {
                        self?.reloadPhotoArray()
                    }
                })
                self.location = nil
            }
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func reloadPhotoArray() {
        let imagePick = navigationController as? XMImagePickerController
        XMImageManager.manager.getCameraRollAlbum(allowPickingVideo: imagePick?.allowPickingVideo ?? true, allowPickingImage: imagePick?.allowPickingImage ?? true) { (model) in
            self.albumModel = model
            XMImageManager.manager.getAssets(result: model.result, allowPickingVideo: imagePick?.allowPickingVideo ?? true, allowPickingImage: imagePick?.allowPickingImage ?? true, allowPickingGif: imagePick?.allowPickingGif ?? true, completion: { (assetModels) in
                imagePick?.hideProgressHUD()

                let assetModel: XMAssetModel?
                if imagePick?.sortAscendingByModificationDate == true {
                    assetModel = assetModels?.last
                    if assetModel != nil {
                        self.models.append(assetModel!)
                    }
                } else {
                    assetModel = assetModels?.first
                    if assetModel != nil {
                        self.models.insert(assetModel!, at: 0)
                    }
                }
                if imagePick?.maxImagesCount == 1 || imagePick?.maxImagesCount == 0 {
                    if imagePick?.allowCrop == true {
                        let photoPreviewVc = XMPhotoPreviewController()
                        if imagePick?.sortAscendingByModificationDate == true {
                            photoPreviewVc.currentIndex = self.models.count - 1
                        } else {
                            photoPreviewVc.currentIndex = 0
                        }
                        photoPreviewVc.models = self.models
                        self.pushPhotoPrevireViewController(photoPreviewVc: photoPreviewVc)
                    } else {
                        if assetModel != nil {
                            imagePick?.selectedModels.append(assetModel!)
                            self.doneButtonClick()
                        }
                    }
                    return
                }
                if (imagePick?.selectedModels.count ?? 0) < (imagePick?.maxImagesCount ?? 0) {
                    assetModel?.isSelected = true
                    if assetModel != nil {
                        imagePick?.selectedModels.append(assetModel!)
                        self.refreshBottomToolBarStatus()
                    }
                }
                self.collectionView?.isHidden = true
                self.collectionView?.reloadData()

                self.shouldScrollToBottom = true
                self.scrollCollectionViewToBottom()
            })
        }
    }
}

class XMCollectionView: UICollectionView {

    override func touchesShouldCancel(in view: UIView) -> Bool {
        if  view is UIControl {
            return true
        }
        return false
    }

}
