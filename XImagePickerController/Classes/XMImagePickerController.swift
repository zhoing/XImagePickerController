//
//  XMImagePickerController.swift
//  channel_sp
//
//  Created by ming on 2017/10/17.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

var  xm_isGlobalHideStatusBar: Bool {
    if isGlobalHideStatusBar == nil {
        if let isHideStatusBar = Bundle.main.object(forInfoDictionaryKey: "UIStatusBarHidden") {
            if isHideStatusBar is Bool {
                isGlobalHideStatusBar = (isHideStatusBar as! Bool)
            } else {
                isGlobalHideStatusBar = false
            }
        } else {
            isGlobalHideStatusBar = false
        }
    }
    return isGlobalHideStatusBar!
}
private var isGlobalHideStatusBar: Bool?


@objc public protocol XMImagePickerControllerDelegate: NSObjectProtocol {
//    @optional
    @objc optional func imagePickerController(_ picker: XMImagePickerController, didFinishPickingPhotos photos: Array<UIImage>?, sourceAssets assets: Array<PHAsset>?, isSelectOriginalPhoto: Bool, infos: Array<[AnyHashable : Any]>?)
    @objc optional func imagePickerController(_ picker: XMImagePickerController, didFinishPickingPhotos photos: Array<UIImage>?, sourceAssets assets: Array<PHAsset>?, isSelectOriginalPhoto: Bool)
    @objc optional func imagePickerControllerDidCancel(_ picker: XMImagePickerController)
    @objc optional func imagePickerController(_ picker: XMImagePickerController, didFinishPickingVideo: UIImage?, sourceAsset assets: PHAsset?)
    @objc optional func imagePickerController(_ picker: XMImagePickerController, didFinishPickingGifImage: UIImage?, sourceAsset assets: PHAsset?)
    @objc optional func isAssetCanSelect(asset: PHAsset?) -> Bool
    @objc optional func isAlbumCanSelect(albumName: String, result: PHFetchResult<PHAsset>?) -> Bool


}



public class XMImagePickerController: UINavigationController {

    weak var pickerDelegate: XMImagePickerControllerDelegate? {
        didSet {
            XMImageManager.manager.pickerDelegate = pickerDelegate
        }
    }

     public var maxImagesCount = 9 {
        didSet {
            if maxImagesCount > 1 {
                showSelectBtn = true
                allowCrop = false
            } else if maxImagesCount < 0 {
                maxImagesCount = 0
            }
        }
    }
    public var minImagesCount = 0
    public var alwaysEnableDoneBtn = false
    public var sortAscendingByModificationDate = true {
        didSet {
            XMImageManager.manager.sortAscendingByModificationDate = sortAscendingByModificationDate
        }
    }

    public var photoWidth: CGFloat = 828.0 {
        didSet {
            XMImageManager.manager.photoWidth = photoWidth
        }
    }
    public var photoPreviewMaxWidth: CGFloat = 600.0 {
        didSet {
            if photoPreviewMaxWidth > 800 {
                photoPreviewMaxWidth = 800
            } else if photoPreviewMaxWidth < 500 {
                photoPreviewMaxWidth = 500
            }
            XMImageManager.manager.photoPreviewMaxWidth = photoPreviewMaxWidth
        }
    }
    public var timeout: TimeInterval = 15
    public var allowPickingOriginalPhoto = true
    public var allowPickingVideo = true {
        didSet {
            UserDefaults.standard.set(allowPickingVideo, forKey: "xm_allowPickingVideo")
            UserDefaults.standard.synchronize()
        }
    }

    public var allowPickingMultipleVideo = false
    public var allowPickingGif = true {
        didSet {
            UserDefaults.standard.set(allowPickingGif, forKey: "xm_allowPickingGif")
            UserDefaults.standard.synchronize()
        }
    }
    public var allowPickingImage = true {
        didSet {
            UserDefaults.standard.set(allowPickingImage, forKey: "xm_allowPickingImage")
            UserDefaults.standard.synchronize()
        }
    }
    public var allowTakePicture = true
    public var allowPreview = true
    public var autoDismiss = true

    var selectedModels: Array<XMAssetModel> = [] {
        didSet {
            for asset in selectedAssets {
                let model = XMAssetModel.init(asset: asset, type: XMImageManager.manager.getAssetType(asset: asset))
                model.isSelected = true
                selectedModels.append(model)
            }
        }
    }
    public var selectedAssets: Array<PHAsset> = []

    public var minPhotoWidthSelectable: CGFloat = 0 {
        didSet {
            XMImageManager.manager.minPhotoWidthSelectable = minPhotoWidthSelectable
        }
    }
    public var minPhotoHeightSelectable: CGFloat = 0 {
        didSet {
            XMImageManager.manager.minPhotoHeightSelectable = minPhotoHeightSelectable
        }
    }

    public var hideWhenCanNotSelect = false
    public var isStatusBarDefault = false
    public var showSelectBtn = true {
        didSet {
            if !showSelectBtn && maxImagesCount > 1 {
                showSelectBtn = true
            }
        }
    }

    public var allowCrop = false {
        didSet {
            if maxImagesCount > 1 {
                allowCrop = false
            }
            if allowCrop {
                allowPickingOriginalPhoto = false
                allowPickingGif = false
            }
        }
    }
    public var cropRect = CGRect.zero {
        didSet {
            cropRectPortrait = cropRect
            cropRectLandscape = CGRect.init(x: (view.xm_height - cropRect.height) * 0.5, y: cropRect.midX, width: cropRect.width, height: cropRect.width)
        }
    }
    public var cropRectPortrait = CGRect.zero
    public var cropRectLandscape = CGRect.zero
    public var isNeedCircleCrop = true
    public var circleCropRadius: CGFloat = 0.0 {
        didSet {
            cropRect = CGRect.init(x: view.xm_width * 0.5 - circleCropRadius, y: view.xm_height * 0.5 - circleCropRadius, width: circleCropRadius * 2.0, height: circleCropRadius * 2.0)
        }
    }
    public var cropViewSettingBlock: ((UIView?) -> Void)?
    public var navLeftBarButtonSettingBlock: ((UIButton?) -> Void)?

    public var isSelectOriginalPhoto = false

    public var takePictureImageName = "takePicture";
    public var photoSelImageName = "photo_sel_photoPickerVc";
    public var photoDefImageName = "photo_def_photoPickerVc";
    public var photoNumberIconImageName = "photo_number_icon";
    public var photoPreviewOriginDefImageName = "preview_original_def";
    public var photoOriginDefImageName = "photo_original_def";
    public var photoOriginSelImageName = "photo_original_sel";

    public var oKButtonTitleColorNormal = UIColor.init(red: CGFloat(83.0 / 255), green: CGFloat(179.0 / 255), blue: CGFloat(17.0 / 255), alpha: 1.0)
    public var oKButtonTitleColorDisabled = UIColor.init(red: CGFloat(83.0 / 255), green: CGFloat(179.0 / 255), blue: CGFloat(17.0 / 255), alpha: 0.5)
    public var naviBgColor: UIColor? {
        didSet {
            if naviBgColor != nil {
                navigationBar.setBackgroundImage(UIImage.image(naviBgColor!), for: UIBarMetrics.default)
//                navigationBar.barTintColor = naviBgColor!
            }
        }
    }
    public var naviShadowColor: UIColor? {
        didSet {
            if naviShadowColor != nil {
                navigationBar.shadowImage = UIImage.image(naviShadowColor!)
            }
        }
    }
    public var naviTitleColor = UIColor.white {
        didSet {
            configNaviTitleAppearance()
        }
    }

    public var barItemTextColor = UIColor.white {
        didSet {
            configBarButtonItemAppearance()
        }
    }
    public var naviTitleFont = UIFont.systemFont(ofSize: 17){
        didSet {
            configNaviTitleAppearance()
        }
    }
    public var barItemTextFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            configBarButtonItemAppearance()
        }
    }


    public var doneBtnTitleStr = Bundle.xm_localizedString(key: "Done")
    public var cancelBtnTitleStr = Bundle.xm_localizedString(key: "Cancel")
    public var previewBtnTitleStr = Bundle.xm_localizedString(key: "Preview")
    public var fullImageBtnTitleStr = Bundle.xm_localizedString(key: "Full image")
    public var settingBtnTitleStr = Bundle.xm_localizedString(key: "Setting")
    public var processHintStr = Bundle.xm_localizedString(key: "Processing...")


    public var didFinishPickingPhotosHandle: ((Array<UIImage>?, Array<PHAsset>?, Bool) -> Void)?
    public var didFinishPickingPhotosWithInfosHandle: ((Array<UIImage>?, Array<PHAsset>?, Bool, Array<Dictionary<AnyHashable, Any>>?) -> Void)?
    public var didFinishPickingGifImageHandle: ((UIImage?, PHAsset?) -> Void)?
    public var didFinishPickingVideoHandle: ((UIImage?, PHAsset?) -> Void)?
    public var imagePickerControllerDidCancelHandle: (() -> Void)?

    private var settingBtn: UIButton?
    private var tipLabel: UILabel?
    private var timer: Timer?

    private var pushPhotoPickerVc = true

    private var progressHUD: UIButton?
    private var HUDIndicatorView: UIActivityIndicatorView?

    private var originStatusBarStyle: UIStatusBarStyle = .default
    private var columnNumber: Int = 4 {
        didSet {
            if columnNumber < 2 {
                columnNumber = 2
            } else if columnNumber > 6 {
                columnNumber = 6
            }
            guard let albumPickerVc = self.childViewControllers.first as? XMAlbumPickerController else {
                return
            }
            albumPickerVc.columnNumber = columnNumber
            XMImageManager.manager.columnNumber = columnNumber
        }
    }


    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = true
        XMImageManager.manager.shouldFixOrientation = false
        if !xm_isGlobalHideStatusBar {
            UIApplication.shared.isStatusBarHidden = false
        }
    }
    func configDefaultSetting() {

        self.photoWidth = 828.0;
        self.photoPreviewMaxWidth = 600;
        self.allowPreview = true
        configNaviTitleAppearance()
        configBarButtonItemAppearance()
    }
    func configNaviTitleAppearance() {
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : naviTitleColor, NSAttributedStringKey.font : naviTitleFont]
    }
    func configBarButtonItemAppearance() {
        var barItme = UIBarButtonItem()

        if #available(iOS 9.0, *) {
            barItme = UIBarButtonItem.appearance(whenContainedInInstancesOf: [XMImagePickerController.self])
        } else {
            barItme = UIBarButtonItem.appearance(for: self.traitCollection)//UITraitCollection
        }
        barItme.setTitleTextAttributes([NSAttributedStringKey.foregroundColor : barItemTextColor, NSAttributedStringKey.font : barItemTextFont], for: .normal)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        originStatusBarStyle = UIApplication.shared.statusBarStyle
        if isStatusBarDefault {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = originStatusBarStyle
        hideProgressHUD()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public init(delegate:XMImagePickerControllerDelegate, pushPhotoPickerVc: Bool = true, maxImagesCount: Int = 9, columnNumber:Int = 4) {
        let albumPickVc = XMAlbumPickerController()
        albumPickVc.columnNumber = columnNumber
        super.init(rootViewController: albumPickVc)
        self.maxImagesCount = maxImagesCount > 0 ? maxImagesCount : 9
        pickerDelegate = delegate
        self.columnNumber = columnNumber;

        self.sortAscendingByModificationDate = true
        configDefaultSetting()

        let cropViewWH: CGFloat = min(view.xm_width, view.xm_height) * 2.0 / 3.0
        cropRect = CGRect.init(x: (view.xm_width - cropViewWH) * 0.5, y: (view.xm_height - cropViewWH) * 0.5, width: cropViewWH, height: cropViewWH)

        if !XMImageManager.manager.authorizationStatusAuthorized() {
            tipLabel = UILabel.init(frame: CGRect.init(x: 8, y: 120, width: view.xm_width - 16, height: 60))
            tipLabel?.textAlignment = .center
            tipLabel?.numberOfLines = 0
            tipLabel?.textColor = UIColor.black
            tipLabel?.font = UIFont.systemFont(ofSize: 16)

            var info = Bundle.main.localizedInfoDictionary
            if info == nil {
                info = Bundle.main.infoDictionary
            }

            var appName = info?["CFBundleDisplayName"] as? String
            if appName == nil {
                appName = info?["CFBundleName"] as? String
            }

            tipLabel?.text = String.init(format: Bundle.xm_localizedString(key: "Allow %@ to access your album in \"Settings -> Privacy -> Photos\""), appName ?? "")
            view.addSubview(tipLabel!)

            settingBtn = UIButton.init(frame: CGRect.init(x: 0, y: 180, width: view.xm_width, height: 44))
            settingBtn?.setTitle(settingBtnTitleStr, for: .normal)
            settingBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            settingBtn?.setTitleColor(UIColor.black, for: .normal)
            settingBtn?.addTarget(self, action: #selector(self.settingBtnClick), for: .touchUpInside)
            view.addSubview(settingBtn!)

            timer = Timer.init(timeInterval: 0.2, target: self, selector: #selector(self.observeAuthrizationStatusChange), userInfo: nil, repeats: true)
        } else {
            pushPhotoPicker()
        }
    }


    init(selectedAssets: Array<PHAsset>, selectedPhotos: Array<UIImage>, index: Int) {
        let previewVc = XMPhotoPreviewController()

        super.init(rootViewController: previewVc)
        self.selectedAssets = selectedAssets
        configDefaultSetting()

        let cropViewWH: CGFloat = min(view.xm_width, view.xm_height) * 2.0 / 3.0
        cropRect = CGRect.init(x: (view.xm_width - cropViewWH) * 0.5, y: (view.xm_height - cropViewWH) * 0.5, width: cropViewWH, height: cropViewWH)

        previewVc.photos = selectedPhotos
        previewVc.currentIndex = index
        previewVc.doneButtonClickBlockWithPreviewType = {[weak self] (photos, assets, isSelectOriginalPhoto) in
            self?.dismiss(animated: true, completion: {
                if self?.didFinishPickingPhotosHandle  != nil {
                    self?.didFinishPickingPhotosHandle!(photos, assets, isSelectOriginalPhoto)
                }
            })
        }
    }
    init(asset: PHAsset, photo: UIImage,completion:((UIImage?, PHAsset?) -> Void)?) {
        let previewVc = XMPhotoPreviewController()

        super.init(rootViewController: previewVc)

        maxImagesCount = 1
        allowCrop = true
        self.selectedAssets = [asset]
        configDefaultSetting()

        let cropViewWH: CGFloat = min(view.xm_width, view.xm_height) * 2.0 / 3.0
        cropRect = CGRect.init(x: (view.xm_width - cropViewWH) * 0.5, y: (view.xm_height - cropViewWH) * 0.5, width: cropViewWH, height: cropViewWH)

        previewVc.photos = [photo]
        previewVc.isCropImage = true
        previewVc.currentIndex = 0

        previewVc.doneButtonClickBlockCropMode = {[weak self] (photo, asset) in
            self?.dismiss(animated: true, completion: {
                if completion != nil {
                    completion!(photo, asset)
                }
            })
        }
    }


    @objc func observeAuthrizationStatusChange() {
        if XMImageManager.manager.authorizationStatusAuthorized() {
            tipLabel?.removeFromSuperview()
            tipLabel = nil
            settingBtn?.removeFromSuperview()
            settingBtn = nil
            timer?.invalidate()
            timer = nil
            pushPhotoPicker()
        }

    }

    @objc func settingBtnClick() {
//        if UIApplication.shared.canpublicURL(URL.init(string: UIApplicationOpenSettingsURLString)!){
//            UIApplication.shared.publicURL(URL.init(string: UIApplicationOpenSettingsURLString)!)
//        }
    }
    func pushPhotoPicker() {
        if pushPhotoPickerVc {
            let photoPickerVc = XMPhotoPickerController()
            photoPickerVc.columnNumber = columnNumber
            self.pushViewController(photoPickerVc, animated: true)
            self.pushPhotoPickerVc = false
        }
        guard let albumPickerVc = self.childViewControllers.first as? XMAlbumPickerController else {
            return
        }
        albumPickerVc.configTableView()
    }

    @discardableResult
    func showAlertWithTitle(title: String) -> UIAlertController {
        let alert =  UIAlertController.init(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: Bundle.xm_localizedString(key: "OK"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
        return alert
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func showProgressHUD() {
        if progressHUD == nil {
            progressHUD = UIButton.init(type: .custom)
            progressHUD?.backgroundColor = UIColor.clear
            let HUDContainer = UIView.init(frame: CGRect.init(x: (view.xm_width - 120) * 0.5, y: (view.xm_height - 90) * 0.5, width: 120, height: 90))
            HUDContainer.layer.cornerRadius = 9
            HUDContainer.clipsToBounds = true
            HUDContainer.backgroundColor = UIColor.darkGray
            HUDContainer.alpha = 0.7

            HUDIndicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: .white)
            HUDIndicatorView?.frame = CGRect.init(x: 45, y: 15, width: 30, height: 30)
            let HUDLabel = UILabel.init(frame: CGRect.init(x: 0, y: 40, width: 120, height: 50))
            HUDLabel.textAlignment = .center
            HUDLabel.text = processHintStr
            HUDLabel.textColor = UIColor.white
            HUDLabel.font = UIFont.systemFont(ofSize: 15)

            HUDContainer.addSubview(HUDLabel)
            HUDContainer.addSubview(HUDIndicatorView!)
            progressHUD?.addSubview(HUDContainer)
        }
        HUDIndicatorView?.startAnimating()
        UIApplication.shared.keyWindow?.addSubview(progressHUD!)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeout) { [weak self] in
            self?.hideProgressHUD()
        }

    }
    func hideProgressHUD() {
        if progressHUD != nil {
            HUDIndicatorView?.stopAnimating()
            progressHUD?.removeFromSuperview()
        }
    }

    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController.automaticallyAdjustsScrollViewInsets = false
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        super.pushViewController(viewController, animated: animated)
    }
// MARK: - UIContentContainer

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        willInterfaceOrientionChange()
        if size.width > size.height {
            cropRect = cropRectLandscape
        } else {
            cropRect = cropRectPortrait
        }
    }

    func willInterfaceOrientionChange() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.02) {
            if UIApplication.shared.isStatusBarHidden == false {
                if !xm_isGlobalHideStatusBar {
                    UIApplication.shared.isStatusBarHidden = false
                }
            }
        }
    }


    @objc func cancelButtonClick() {
        if autoDismiss {
            dismiss(animated: true, completion: {
                self.callDelegateMethod()
            })
        } else {
            callDelegateMethod()
        }
    }
    func callDelegateMethod() {

        if self.pickerDelegate?.responds(to: #selector(self.pickerDelegate?.imagePickerControllerDidCancel(_:))) == true {
            self.pickerDelegate?.imagePickerControllerDidCancel!(self)
        }
        if self.imagePickerControllerDidCancelHandle != nil {
            self.imagePickerControllerDidCancelHandle!()
        }
    }





}
class XMAlbumPickerController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var albumArr: Array<XMAlbumModel> = []
    var columnNumber = 4
    private var isFirstAppear = true
    private var tableView: UITableView?


    override func viewDidLoad() {
        super.viewDidLoad()
        let imagePick = navigationController as? XMImagePickerController
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: imagePick?.cancelBtnTitleStr, style: .plain, target: imagePick, action: #selector(imagePick?.cancelButtonClick))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let imagePick = navigationController as? XMImagePickerController
        imagePick?.hideProgressHUD()
        if imagePick?.allowTakePicture == true {
            navigationItem.title = Bundle.xm_localizedString(key: "Photos")
        } else if imagePick?.allowPickingVideo == true {
            navigationItem.title = Bundle.xm_localizedString(key: "Videos")
        }
        if isFirstAppear && imagePick?.navLeftBarButtonSettingBlock == nil {
            navigationItem.backBarButtonItem = UIBarButtonItem.init(title: Bundle.xm_localizedString(key: "Back"), style: .plain, target: nil, action: nil)
            isFirstAppear = false
        }
        configTableView()
    }
    func configTableView() {
        DispatchQueue.global().async { [weak self] in
            let imagePick = self?.navigationController as? XMImagePickerController
            XMImageManager.manager.getAllAlbums(allowPickingVideo: imagePick?.allowPickingVideo ?? false, allowPickingImage: imagePick?.allowPickingImage ?? false, allowPickingGif: imagePick?.allowPickingGif ?? false, completion: { (models) in
                self?.albumArr = models
                for albumModel in models {
                    albumModel.selectedModels = imagePick?.selectedModels ?? []
                }
                DispatchQueue.main.async {
                    if self?.tableView == nil {
                        self?.tableView = UITableView.init(frame: CGRect.zero, style: .plain)
                        self?.tableView?.tableFooterView = UIView()
                        self?.tableView?.dataSource = self
                        self?.tableView?.rowHeight = 70.0
                        self?.tableView?.delegate = self
                        self?.tableView?.register(XMAlbumCell.classForCoder(), forCellReuseIdentifier: "XMAlbumCell")
                        self?.view.addSubview(self!.tableView!)
                    } else {
                        self?.tableView?.reloadData()
                    }
                }
            })
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var top: CGFloat = 0.0
        var tableViewHeight: CGFloat = 0.0
        let naviBarHeight: CGFloat = navigationController?.navigationBar.xm_height ?? 44.0
        let isStatusBarHidden = UIApplication.shared.isStatusBarHidden
        if navigationController?.navigationBar.isTranslucent == true {
            top = naviBarHeight
            if !isStatusBarHidden {
                top = top + UIApplication.shared.statusBarFrame.height
            }
            tableViewHeight = view.xm_height - top
        } else {
            tableViewHeight = view.xm_height
        }
        tableView?.frame = CGRect.init(x: 0, y: top, width: view.xm_width, height: tableViewHeight)

    }

// MARK: - UITableViewDataSource, UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumArr.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "XMAlbumCell", for: indexPath) as? XMAlbumCell
        let imagePick = navigationController as? XMImagePickerController
        cell?.selectedCountButton.backgroundColor = imagePick?.oKButtonTitleColorNormal
        if indexPath.row < albumArr.count {
            cell?.model = albumArr[indexPath.row]
        }
        cell?.accessoryType = .disclosureIndicator
        return cell!
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photoPickerVc = XMPhotoPickerController()
        photoPickerVc.albumModel = albumArr[indexPath.row]
        photoPickerVc.columnNumber = columnNumber
        navigationController?.pushViewController(photoPickerVc, animated: true)
        tableView.deselectRow(at: indexPath, animated: false)
    }

}

extension UIImage {

    class func image(_ color: UIColor, _ size: CGSize = CGSize.init(width: 1.0, height: 1.0)) -> UIImage {

        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context?.fill(CGRect.init(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    class func imageNamedFromMyBundle(name: String?) -> UIImage? {
        guard let imageName = name else {
            return nil
        }
        guard let path = Bundle.xm_imagePickerBundle.path(forResource: imageName + "@2x", ofType: "png") else {
            return UIImage.init(named: imageName + "@2x")
        }
        guard let image = UIImage.init(contentsOfFile: path) else {
            return UIImage.init(named: imageName + "@2x")
        }
        return image
    }

}

extension Array where Element : Equatable{
    mutating func xm_remover(obj: Array.Element) {
        if let i = self.index(of: obj) {
            remove(at: i)
        }
    }
}
