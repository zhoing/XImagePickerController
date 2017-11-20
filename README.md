# XImagePickerController

[![CI Status](http://img.shields.io/travis/ming/XImagePickerController.svg?style=flat)](https://travis-ci.org/ming/XImagePickerController)
[![Version](https://img.shields.io/cocoapods/v/XImagePickerController.svg?style=flat)](http://cocoapods.org/pods/XImagePickerController)
[![License](https://img.shields.io/cocoapods/l/XImagePickerController.svg?style=flat)](http://cocoapods.org/pods/XImagePickerController)
[![Platform](https://img.shields.io/cocoapods/p/XImagePickerController.svg?style=flat)](http://cocoapods.org/pods/XImagePickerController)

 A clone of UIImagePickerController, support picking multiple photos、original photo、GIF、video, also allow preview photo and video, support iOS8+.

## Example
```swift

let imagePickerVc = XMImagePickerController.init(delegate: self, pushPhotoPickerVc: true, maxImagesCount: maxCount, columnNumber: 3)
imagePickerVc.isSelectOriginalPhoto = true
imagePickerVc.naviBgColor = UIColor.white
imagePickerVc.barItemTextColor = mainColor
imagePickerVc.naviTitleColor = c22
imagePickerVc.naviShadowColor = cde
imagePickerVc.isStatusBarDefault = true

imagePickerVc.allowTakePicture = true
imagePickerVc.allowPickingVideo = false
imagePickerVc.allowPickingImage = true
imagePickerVc.allowPickingGif = false

imagePickerVc.allowPickingOriginalPhoto = false
imagePickerVc.sortAscendingByModificationDate = false
imagePickerVc.showSelectBtn = true
imagePickerVc.allowCrop = false
rootVC.present(imagePickerVc, animated: true, completion: nil)
```
## Requirements

## Installation

XImagePickerController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'XImagePickerController'
```

## Author

ming, xiaoming.zhao@mljr.com

## License

XImagePickerController is available under the MIT license. See the LICENSE file for more info.
