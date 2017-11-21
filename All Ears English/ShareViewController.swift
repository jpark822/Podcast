//
//  ShareViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticsManager.sharedInstance.logPageVisit("Page Visit: Share")
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        ExternalShareManager.sharedInstance.presentShareControllerFromViewController(fromController: self, title: "Check out the All Ears English app!", urlString: "https://www.allearsenglish.com/", image: UIImage(named: "Cover"))
    }

    @IBAction func declinePressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
