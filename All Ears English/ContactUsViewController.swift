//
//  ContactUsViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Foundation

class ContactUsViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let font = UIFont(name: "PTSans-Regular", size: 21)
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        
        let textViewString = NSMutableAttributedString(string: "Need help?\n\n\nContact Lindsay McMahon\nLindsay@allearsenglish.com\n\n\nwww.allearsenglish.com", attributes:[NSFontAttributeName:font, NSParagraphStyleAttributeName:centerStyle])
        let legalHyperlinkString = NSMutableAttributedString(string: "\n\nLegal", attributes: [NSLinkAttributeName:"https://www.allearsenglish.com/legal/", NSFontAttributeName:font, NSParagraphStyleAttributeName:centerStyle])
        
        textViewString.append(legalHyperlinkString)
        
        
        self.contentTextView.attributedText = textViewString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: Contact Us")
    }

}
