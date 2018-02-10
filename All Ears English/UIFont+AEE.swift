//
//  UIFont+AEE.swift
//  All Ears English
//
//  Created by Jay Park on 2/6/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    static func PTSansRegular(size:CGFloat) -> UIFont {
        if let font = UIFont(name: "PTSans-Regular", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize:size)
    }
}
