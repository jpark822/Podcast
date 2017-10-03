//
//  WebViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/3/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

class WebViewController : UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    var url: URL? {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            self.loadWebview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadWebview()
    }
    
    private func loadWebview() {
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
}
