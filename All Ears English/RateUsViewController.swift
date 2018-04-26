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
        AnalyticsManager.sharedInstance.logKochavaPageView(.rating, properties: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func confirmPressed(_ sender: Any) {
        StoreReviewManager.sharedInstance.displayReviewController(fromViewController: self)
        
        ApplicationData.userCompletedRating = true
        AnalyticsManager.sharedInstance.logKochavaCustomEvent(.rateAction, properties: nil)
    }

    @IBAction func declinePressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
