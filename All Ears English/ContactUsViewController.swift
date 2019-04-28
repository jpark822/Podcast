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
        
        let textViewString = NSMutableAttributedString(string: "Need help?\n\n\nContact Lindsay McMahon\nLindsay@allearsenglish.com\n\n\nwww.allearsenglish.com", attributes:convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):font, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle):centerStyle]))
        let legalHyperlinkString = NSMutableAttributedString(string: "\n\nLegal", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.link):"https://www.allearsenglish.com/legal/", convertFromNSAttributedStringKey(NSAttributedString.Key.font):font, convertFromNSAttributedStringKey(NSAttributedString.Key.paragraphStyle):centerStyle]))
        
        textViewString.append(legalHyperlinkString)
        
        
        self.contentTextView.attributedText = textViewString
    }
    
    override func viewWillAppear(_ animated: Bool) {
        AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: Contact Us")
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
