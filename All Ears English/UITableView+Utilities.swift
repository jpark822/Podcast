//
//  UITableView+Utilities.swift
//  All Ears English
//
//  Created by Jay Park on 2/14/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func scrollToTop() {
        DispatchQueue.main.async {
            self.setContentOffset(CGPoint.zero, animated: true)
        }
    }
}

