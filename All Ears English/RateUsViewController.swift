//
//  RateUsViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

class RateUsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: Rate Us")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func confirmPressed(_ sender: Any) {
        if #available( iOS 10.3,*){
            SKStoreReviewController.requestReview()
        }
        else if let url = URL(string: "https://itunes.apple.com/us/app/all-ears-english-listening/id1260196995?ls=1&mt=8") {
            UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
            })
        }
        ApplicationData.userCompletedRating = true
    }

    @IBAction func declinePressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
