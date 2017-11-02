//
//  File.swift
//  channel_sp
//
//  Created by ming on 2017/10/17.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation

extension Bundle {
    private static var imagePickerBundle: Bundle?
    private static var localizedBundle: Bundle?
    static var xm_imagePickerBundle: Bundle {
        if imagePickerBundle == nil {
            let frameworkBundle = Bundle.init(for: XMImagePickerController.classForCoder())
            let ResourcesBundle = Bundle.init(path: frameworkBundle.path(forResource: "XImagePickerController", ofType: "bundle") ?? "")
            let bundle = Bundle.init(path: ResourcesBundle?.path(forResource: "XImagePickerController", ofType: "bundle") ?? "")
            imagePickerBundle = bundle ?? ResourcesBundle
        }
        return imagePickerBundle ?? Bundle.main
        
    }
    class func xm_localizedString(key: String)  -> String {
        return Bundle.xm_localizedString(key: key, value: "")
        
    }
    class func xm_localizedString(key: String, value: String)  -> String {
        if localizedBundle == nil {
            var language = Locale.preferredLanguages.first
            if language?.range(of: "zh-Hans") != nil {
                language = "zh-Hans"
            } else {
                language = "en"
            }
            localizedBundle = Bundle.init(path: xm_imagePickerBundle.path(forResource: language, ofType: "lproj") ?? "")
        }
        return localizedBundle?.localizedString(forKey: key, value: value, table: nil) ?? key
    }
}
