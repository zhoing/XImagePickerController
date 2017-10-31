//
//  XMProgressView.swift
//  channel_sp
//
//  Created by ming on 2017/10/17.
//  Copyright © 2017年 TiandaoJiran. All rights reserved.
//

import Foundation
import UIKit

class XMProgressView: UIView {
    var progress: Double = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var progressLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.opacity = 1.0
        progressLayer.lineCap = kCALineCapRound
        progressLayer.lineWidth = 5.0

        progressLayer.shadowColor = UIColor.black.cgColor
        progressLayer.shadowOffset = CGSize.init(width: 1.0, height: 1.0)
        progressLayer.shadowOpacity = 0.5
        progressLayer.shadowRadius = 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let center = CGPoint.init(x: rect.width * 0.5, y: rect.height * 0.5)
        let radius = rect.width * 0.5
        let startA: CGFloat = CGFloat(-Double.pi * 0.5)
        let endA: CGFloat = startA + CGFloat(Double.pi * 2 * progress)
        progressLayer.frame = bounds
        let path = UIBezierPath.init(arcCenter: center, radius: radius, startAngle: startA, endAngle: endA, clockwise: true)
        progressLayer.path = path.cgPath
        progressLayer.removeFromSuperlayer()
        self.layer.addSublayer(progressLayer)
    }

}
