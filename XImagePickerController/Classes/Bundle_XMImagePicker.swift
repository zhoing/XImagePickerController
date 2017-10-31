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
    static var xm_imagePickerBundle: Bundle {
        let bundle = Bundle.init(for: XMImagePickerController.classForCoder())
        let url = bundle.url(forResource: "XMImagePickerController", withExtension: "bundle")
        return Bundle.init(url: url!)!

    }
    class func xm_localizedString(key: String)  -> String {
        return Bundle.xm_localizedString(key: key, value: "")

    }
    class func xm_localizedString(key: String, value: String)  -> String {
        var language = Locale.preferredLanguages.first
        if language?.range(of: "zh-Hans") != nil {
            language = "zh-Hans"
        } else {
            language = "en"
        }
        imagePickerBundle = Bundle.init(path: xm_imagePickerBundle.path(forResource: language, ofType: "lproj")!)
        return imagePickerBundle?.localizedString(forKey: key, value: value, table: nil) ?? key

    }
}
