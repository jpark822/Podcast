//
//  ContactUsViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class ContactUsViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentTextView.text = "Need help?\n\n\nContact Lindsay McMahon\nLindsay@allearsenglish.com\n\n\nwww.allearsenglish.com"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticsManager.sharedInstance.logPageVisit("Page Visit: Contact Us")
    }

}
