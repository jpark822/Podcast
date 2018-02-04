//
//  StoreReviewManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/12/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

//Not in use
class StoreReviewManager: NSObject {
    static let sharedInstance = StoreReviewManager()
    
    func displayReviewController(fromViewController: UIViewController) {
        
        let alertController = UIAlertController(title: "Do you love All Ears English? Please rate us now!", message: "", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes, I will rate the app", style: UIAlertActionStyle.default, handler: { (alertAction) in
            if #available( iOS 10.3,*){
                SKStoreReviewController.requestReview()
            }
            else if let url = URL(string: "https://itunes.apple.com/us/app/all-ears-english-listening/id1260196995?ls=1&mt=8") {
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                })
            }
            ApplicationData.userCompletedRating = true
        })
        
        let remindMeLaterAction = UIAlertAction(title: "Remind me later", style: UIAlertActionStyle.cancel, handler: { (alertAction) in
        })
        
        let cancelAction = UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.destructive, handler: { (alertAction) in
            
        })
        
        alertController.addAction(confirmAction)
        alertController.addAction(remindMeLaterAction)
        alertController.addAction(cancelAction)
        
        fromViewController.present(alertController, animated: true, completion: {
        })
        
    }
}
