//
//  XMGifPhotoPreviewController.swift
//  channel_sp
//
//  Created by ming on 2017/10/20.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

class XMGifPhotoPreviewController: UIViewController {
    var model:XMAssetModel?
    private var toolBar = UIView()
    private var doneButton = UIButton.init(type: .custom)
    private var previewView = XMPhotoPreviewView()
    private var originStatusBarStyle: UIStatusBarStyle?
    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationController is XMImagePickerController {
            navigationItem.title = (navigationController as! XMImagePickerController).previewBtnTitleStr
        }
        view.backgroundColor = UIColor.black
        configPreviewView()
        configBottomToolBar()

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

    func configPreviewView() {
        previewView.model = model
        previewView.singleTapGestureBlock = {[weak self] in
            self?.signleTapAction()
        }
        view.addSubview(previewView)
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

        let byteLabel = UILabel.init(frame: CGRect.init(x: 10, y: 0, width: 100, height: 44))
        byteLabel.textColor = UIColor.white
        byteLabel.font = UIFont.systemFont(ofSize: 13)
        if model != nil {
            XMImageManager.manager.getPhotosBytes(models: [model!]) {[weak byteLabel] (dataLength) in
                byteLabel?.text = dataLength
            }
        }
        toolBar.addSubview(byteLabel)
        view.addSubview(toolBar)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        previewView.scrollView.frame = view.bounds
        doneButton.frame = CGRect.init(x: view.xm_width - 44.0 - 12.0, y: 0.0, width: 44.0, height: 44.0)
        toolBar.frame = CGRect.init(x: 0.0, y: view.xm_height - 44.0, width: view.xm_width, height: 44.0)

    }
    func signleTapAction() {
        toolBar.isHidden = !toolBar.isHidden
        navigationController?.setNavigationBarHidden( toolBar.isHidden, animated: true)
        if !xm_isGlobalHideStatusBar {
            UIApplication.shared.isStatusBarHidden = toolBar.isHidden
        }
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
    func callDelegateMethod() {
        guard let imagePickerVc = (navigationController is XMImagePickerController) ?  navigationController as? XMImagePickerController : nil else {
            return
        }
        let image = previewView.imageView.image
        if imagePickerVc.pickerDelegate?.responds(to: #selector(imagePickerVc.pickerDelegate?.imagePickerController(_:didFinishPickingGifImage:sourceAsset:))) == true {
            imagePickerVc.pickerDelegate?.imagePickerController!(imagePickerVc, didFinishPickingGifImage: image, sourceAsset: model?.asset)
        }
        if imagePickerVc.didFinishPickingGifImageHandle != nil {
            imagePickerVc.didFinishPickingGifImageHandle!(image, model?.asset)
        }

    }

}
