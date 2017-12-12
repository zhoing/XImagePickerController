//
//  UIView_XMImagePicker.swift
//  channel_sp
//
//  Created by ming on 2017/10/17.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import UIKit

let isIPnoneX = UIScreen.main.bounds.height > 736.0

enum TZOscillatoryAnimationType: Int {
    case ToBigger = 0
    case ToSmaller = 1
}
extension UIView {

    var xm_x: CGFloat {
        set {
            frame.origin.x = newValue
        }

        get {
            return frame.origin.x
        }
    }

    var xm_origin: CGPoint {
        set {
            frame.origin = newValue
        }

        get {
            return frame.origin
        }
    }

    var xm_size: CGSize {
        set {
            frame.size = newValue
        }

        get {
            return frame.size
        }
    }


    var xm_y: CGFloat {
        set {
            frame.origin.y = newValue
        }

        get {
            return frame.origin.y
        }
    }

    var xm_width: CGFloat {
        set {
            frame.size.width = newValue
        }

        get {
            return frame.size.width
        }
    }
    var xm_height: CGFloat {
        set {
            frame.size.height = newValue
        }

        get {
            return frame.size.height
        }
    }
    var xm_left:CGFloat {
        set {
            frame.origin.x = newValue
        }

        get {
            return frame.origin.x
        }

    }
    var xm_top:CGFloat {
        set {
            frame.origin.y = newValue
        }

        get {
            return frame.origin.y
        }
    }
    var xm_right:CGFloat {
        set {
            frame.origin.x = newValue - frame.width
        }

        get {
            return frame.origin.x + frame.width
        }

    }
    var xm_bottom:CGFloat {
        set {
            frame.origin.y = newValue - frame.height
        }

        get {
            return frame.origin.y + frame.height
        }    }

    var xm_centerX: CGFloat {
        set {
            center.x = newValue
        }

        get {
            return center.x
        }
    }
    var xm_centerY: CGFloat {
        set {
            center.y = newValue
        }

        get {
            return center.y
        }
    }

    class func showOscillatoryAnimation(layer: CALayer?, type: TZOscillatoryAnimationType) {
        let animationScale1 = type == .ToBigger ? 1.15: 0.5
        let animationScale2 = type == .ToBigger ? 0.92: 1.15
        UIView.animate(withDuration: 0.15, animations: {
            layer?.setValue(animationScale1, forKey: "transform.scale")
        }) { (finished) in
            UIView.animate(withDuration: 0.15, animations: {
                layer?.setValue(animationScale2, forKey: "transform.scale")

            }, completion: { (finished) in
                UIView.animate(withDuration: 0.1, animations: {
                    layer?.setValue(1.0, forKey: "transform.scale")
                })
            })
        }
    }


}















