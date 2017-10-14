//
//  StoreReviewManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/12/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

class StoreReviewManager: NSObject {
    static let sharedInstance = StoreReviewManager()
    
    func displayReviewController() {
        if #available( iOS 10.3,*){
            SKStoreReviewController.requestReview()
        }
        else {
            if let url = URL(string: "https://itunes.apple.com/us/app/all-ears-english/id1260196995?ls=1&mt=8") {
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    
                })
            }
        }
    }
}
