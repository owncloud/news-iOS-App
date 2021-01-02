//
//  BadgeView.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/1/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import UIKit

@objcMembers
class BadgeView: UIView {

    var value: Int {
        didSet {
            isHidden = (value == 0)
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        value = 0
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let viewBounds = bounds
        if let currentContext = UIGraphicsGetCurrentContext() {
            let numberString = String(format: "%lu", value)
            let numberSize = numberString.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
            
            let arcRadius = ceil((numberSize.height + 2.0) / 2.0)
            let badgeWidthAdjustment = numberSize.width - numberSize.height / 2.0
            var badgeWidth = 2.0 * arcRadius
            
            if badgeWidthAdjustment > 0.0 {
                badgeWidth += badgeWidthAdjustment
            }
            
            let badgePath = CGMutablePath()
            badgePath.move(to: CGPoint(x: arcRadius, y: 0))
            badgePath.addArc(center: CGPoint(x: arcRadius, y: arcRadius), radius: arcRadius, startAngle: 3.0 * (.pi/2), endAngle: .pi/2, clockwise: true)
            badgePath.addLine(to: CGPoint(x: badgeWidth - arcRadius, y: 2.0 * arcRadius))
            badgePath.addArc(center: CGPoint(x: badgeWidth - arcRadius, y: arcRadius), radius: arcRadius, startAngle: .pi/2, endAngle: 3.0 * (.pi/2), clockwise: true)
            badgePath.addLine(to: CGPoint(x: arcRadius, y: 0))
            
            var badgeRect = badgePath.boundingBox
            badgeRect.origin.x = 0
            badgeRect.origin.y = 0
            badgeRect.size.width = ceil(badgeRect.size.width)
            badgeRect.size.height = ceil(badgeRect.size.height)
            
            currentContext.saveGState();
            currentContext.setLineWidth(0.0);
            currentContext.setStrokeColor(UIColor(red: 0.58, green: 0.61, blue: 0.65, alpha: 1.0).cgColor)
            currentContext.setFillColor(UIColor(red: 0.58, green: 0.61, blue: 0.65, alpha: 1.0).cgColor)
            
            let ctm = CGPoint(x: (viewBounds.size.width - badgeRect.size.width) - 10, y: round((viewBounds.size.height - badgeRect.size.height) / 2))
            currentContext.translateBy(x: ctm.x, y: ctm.y)
            currentContext.beginPath()
            currentContext.addPath(badgePath)
            currentContext.closePath()
            currentContext.drawPath(using: .fillStroke)
            currentContext.restoreGState()
            currentContext.saveGState()
            
            let textPt = CGPoint(x: ctm.x + (badgeRect.size.width - numberSize.width) / 2 , y: ctm.y + (badgeRect.size.height - numberSize.height) / 2)
            numberString.draw(at: textPt, withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16), .foregroundColor: UIColor.white])
            
            currentContext.restoreGState()
        }
    }

}
