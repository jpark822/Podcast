//
//  WebViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/3/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

class WebViewController : UIViewController, UIWebViewDelegate {
    
    var doesReloadOnViewWillAppear = false
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
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
        
        self.webView.delegate = self
        self.loadWebview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.doesReloadOnViewWillAppear {
            self.webView.reload()
        }
    }
    
    private func loadWebview() {
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
}

extension WebViewController {
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.loadingActivityIndicator.isHidden = false
        self.loadingActivityIndicator.startAnimating()
        
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.loadingActivityIndicator.isHidden = true
        self.loadingActivityIndicator.stopAnimating()
    }
}
