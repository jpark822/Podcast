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
    
    @IBAction func sharePressed(_ sender: Any) {
        ExternalShareManager.sharedInstance.presentShareControllerFromViewController(fromController: self, title: "Check out the All Ears English app!", urlString: "https://www.allearsenglish.com/", image: UIImage(named: "Cover"))
    }


}
