//
//  BrowserViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/20/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class BrowserViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!

    var lazyTitle: String?
    var lazyURL: URL?
    
    var pageTitle: String? {
        didSet {
            self.navigationItem.title = pageTitle
        }
    }
    var pageURL: URL? {
        didSet {
            if self.webView != nil {
                self.webView.loadRequest(URLRequest(url: URL.init(string: "about:blank")!))
                self.webView.loadRequest(URLRequest(url: pageURL!))
            } else {
                self.lazyURL = pageURL
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Browser viewDidLoad")
        self.automaticallyAdjustsScrollViewInsets = false
        self.webView.allowsInlineMediaPlayback = true
        self.webView.delegate = self

        if let title = lazyTitle {
            self.pageTitle = title
        }

        if let url = lazyURL {
            self.pageURL = url
        }
    }

    @IBAction func toggleMenu(_ sender: Any) {
        ViewController.doToggleMenu(sender)
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        self.loadingIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.loadingIndicator.stopAnimating()
    }

}
