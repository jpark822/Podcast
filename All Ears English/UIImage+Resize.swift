//
//  UIImage+Resize.swift
//  All Ears English
//
//  Created by Jay Park on 10/18/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    static func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        
        image.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return newImage
        }
        
        return nil
    }
}
