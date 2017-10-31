//
//  XMAssetModel.swift
//  channel_sp
//
//  Created by ming on 2017/10/18.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import Photos

enum XMAssetModelMediaType: Int {
    case Photo = 0
    case LivePhoto = 1
    case PhotoGif = 2
    case Video = 3
    case Audio = 4
}

class XMAssetModel: NSObject {
    var asset: PHAsset!
    var isSelected = false
    var type:XMAssetModelMediaType = .Photo
    var timeLength = ""

    init(asset: PHAsset, type:XMAssetModelMediaType, timeLength: String? = nil) {
        super.init()
        self.asset = asset
        self.type = type
        self.timeLength = timeLength ?? ""
    }
}
class XMAlbumModel: NSObject {
    var name = ""
    var count = 0
    var result: PHFetchResult<PHAsset>? {
        didSet {
            let allowPickingImage = UserDefaults.standard.bool(forKey: "xm_allowPickingImage")
            let allowPickingVideo = UserDefaults.standard.bool(forKey: "xm_allowPickingVideo")
            let allowPickingGif = UserDefaults.standard.bool(forKey: "xm_allowPickingGif")

            XMImageManager.manager.getAssets(result: result!, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage, allowPickingGif: allowPickingGif) { [weak self](albumModels) in
                if albumModels != nil {
                    self?.models = albumModels!
                }
                if self!.selectedModels.count > 0 {
                    self?.checkSelectedModels()
                }
            }
        }
    }
    var models: Array<XMAssetModel> = []
    var selectedModels: Array<XMAssetModel> = [] {
        didSet {
            if models.count > 0 {
                checkSelectedModels()
            }
        }
    }
    var selectedCount = 0
    var isCameraRoll = false
    func checkSelectedModels() {
        selectedCount = 0
        var selectedAssets: Array<PHAsset> = []
        for model in selectedModels {
            selectedAssets.append(model.asset)
        }
        for model in models {
            if XMImageManager.manager.isContain(assets: selectedAssets, asset: model.asset) {
                selectedCount = selectedCount + 1
            }
        }
    }
}








