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
    
    var analyticsPageVisitName:String?
    
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
        
        if let name = self.analyticsPageVisitName {
            AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: \(name)")
        }
    }
    
    private func loadWebview() {
        if let url = self.url {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
    }
}

//uiwebviewdelegate
extension WebViewController {
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.loadingActivityIndicator.isHidden = false
        self.loadingActivityIndicator.startAnimating()
        
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.loadingActivityIndicator.isHidden = true
        self.loadingActivityIndicator.stopAnimating()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        //capture "get instant access" event
        if request.url?.host == "staticxx.facebook.com" {
            AnalyticsManager.sharedInstance.logKochavaCustomEvent(.getInstantAccess, properties: nil)
        }
        
        //always load
        return true
    }
}


