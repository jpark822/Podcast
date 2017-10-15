//
//  RateUsViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class RateUsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if ApplicationData.userCompletedRating == false {
            StoreReviewManager.sharedInstance.displayReviewController(fromViewController: self)
        }
    }


}
