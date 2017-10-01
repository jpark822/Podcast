//
//  EpisodeDetailsViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/22/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import AVFoundation
import Crashlytics
import Firebase

class EpisodeDetailsViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var episodeTitle: UILabel?
    @IBOutlet weak var episodeDescription: UILabel?
    @IBOutlet weak var episodeWebView: UIWebView?
    @IBOutlet weak var episodeWebViewConstraintHeight: NSLayoutConstraint?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var bannerView: BannerView?
    @IBOutlet weak var downloadButton: UIButton?
    @IBOutlet weak var downloadActivity: UIActivityIndicatorView?

    var loaded = false
    var item: Feed.Item? {
        didSet {
            self.updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.episodeWebView?.delegate = self
        self.episodeWebView?.allowsInlineMediaPlayback = true
        self.episodeWebView?.loadRequest(URLRequest.init(url: URL.init(string: "http://allearsenglish.com/bridge")!))

        self.bannerView?.presentingController = self

        self.updateUI()

        self.logEventViewEpisode()
    }

    override func viewDidAppear(_ animated: Bool) {
        let height = self.bannerView?.frame.size.height ?? 0
        self.bannerView?.frame.origin.y = self.view.frame.size.height - self.view.frame.origin.y - height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bannerView?.addPlaybackObserver()
        self.bannerView?.update()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayButton), name: Player.PlayerPlaybackStateChange, object: Player.shared!)
        self.updatePlayButton()
        if let localURL = Cache.shared.get(self.item) {
            self.downloadButton?.isHidden = true
        } else {
            self.downloadButton?.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.bannerView?.removePlaybackObserver()
        NotificationCenter.default.removeObserver(self, name: Player.PlayerPlaybackStateChange, object: Player.shared!)
    }
    
    func updateUI() {
        self.episodeTitle?.text = item?.title
        if let description = item?.description {
            let html = "<span style=\"font-family: 'PT Sans', Verdana, Serif; font-size: 17px;\">\(description)</span>"
            let data = html.data(using: String.Encoding.utf8, allowLossyConversion: true)
            if let data = data {
                let text = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                self.episodeDescription?.attributedText = text
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func play(_ sender: Any) {
        if self.loaded {
            if AudioPlayer.sharedInstance.isPlaying {
                AudioPlayer.sharedInstance.pause()
            }
            else {
                AudioPlayer.sharedInstance.play()
            }
        }
        else if self.item?.url != nil {
            AudioPlayer.sharedInstance.play(item: self.item)
            self.loaded = true
        }
        else {
            print("no url to play")
        }
    }
    //test func
    @IBAction func nextPressed(_ sender: Any) {
        print("next")
    AudioPlayer.sharedInstance.seekToBeginningOrPreviousTrack()
    }
    
    func updatePlayButton() {
        var playing = Player.shared?.playing ?? false
        if playing,
           let playerItemIdentifier = Player.shared?.item?.identifier,
           let itemIdentifier = self.item?.identifier {
            playing = playerItemIdentifier == itemIdentifier
        }
        if playing {
            self.playButton?.setImage(UIImage(named: "ic_pause_white"), for: UIControlState.normal)
        } else {
            self.playButton?.setImage(UIImage(named: "ic_play_arrow_white"), for: UIControlState.normal)
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let height = self.episodeWebView?.scrollView.contentSize.height {
            self.episodeWebView?.bounds.size.height = height
            self.episodeWebViewConstraintHeight?.constant = height
        }
    }

    @IBAction func download(_ sender: Any) {
        guard let item = self.item else { return }
        if let localURL = Cache.shared.get(item) {
            return
        }
        self.downloadButton?.isHidden = true
        self.downloadActivity?.isHidden = false
        self.downloadActivity?.startAnimating()
        Cache.shared.download(item) { (item) in
            self.downloadActivity?.stopAnimating()
        }
    }

    @IBAction func shareEpisode(_ sender: Any) {
        let text = self.item?.title ?? ""
        let url = "https://www.allearsenglish.com/"
        let controller = UIActivityViewController.init(activityItems: [text, url], applicationActivities: nil)
        controller.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .print
        ]
        controller.completionWithItemsHandler = {
            (activityType, completed, returnedItems, activityError) in
            if completed {
                DispatchQueue.main.async {
                    let method = activityType?.rawValue ?? "Default"
                    self.logEventShareEpisode(withMethod: method)
                }
            }
        }
        self.present(controller, animated: true)
    }

    func logEventShareEpisode(withMethod method: String) {
        let name = self.item?.title ?? "Unknown"
        let type = "episode"
        let id = self.item?.identifier ?? "0"
        let attributes: [String: Any] = [:]
        print("Logging share event: method=\(String(describing: method)) name=\(name) type=\(type) id=\(id) attributes=\(attributes)")
        Answers.logShare(
                withMethod: method,
                contentName: name,
                contentType: type,
                contentId: id,
                customAttributes: attributes
        )
        Analytics.logEvent(
                AnalyticsEventShare,
                parameters: [
                        AnalyticsParameterMedium: method as NSObject,
                        AnalyticsParameterItemName: name as NSObject,
                        AnalyticsParameterItemCategory: type as NSObject,
                        AnalyticsParameterItemID: id as NSObject
                ])
    }

    func logEventViewEpisode() {
        let name = self.item?.title ?? "Unknown"
        let type = "episode"
        let id = self.item?.identifier ?? "0"
        let attributes: [String: Any] = [:]
        print("Logging view episode event: name=\(name) type=\(type) id=\(id) attributes=\(attributes)")
        Answers.logContentView(withName: name, contentType: type, contentId: id)
        Analytics.logEvent(
                AnalyticsEventViewItem,
                parameters: [
                        AnalyticsParameterItemName: name as NSObject,
                        AnalyticsParameterItemCategory: type as NSObject,
                        AnalyticsParameterItemID: id as NSObject
                ])
    }
}
