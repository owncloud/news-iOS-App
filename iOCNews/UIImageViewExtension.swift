//
//  UIImageViewExtension.swift
//  iOCNews
//
//  Created by Peter Hedlund on 1/7/21.
//  Copyright © 2021 Peter Hedlund. All rights reserved.
//

import Foundation
import Kingfisher

@objc
extension UIImageView {
    
    func setImage(with url: URL) {
        self.kf.setImage(with: url)
    }
    
}
