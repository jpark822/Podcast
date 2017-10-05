//
//  MainTabBarController.swift
//  All Ears English
//
//  Created by Jay Park on 10/1/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Foundation

class MainTabBarController: UITabBarController {
    
    var nowPlayingBannerView:NowPlayingBannerView!
    static let nowPlayingBannerHeight:CGFloat = 60.0
    
    static let didHideNowPlayingBannerNotification: Notification.Name = Notification.Name(rawValue: "didHideNowPlayingBannerNotification")
    static let didShowNowPlayingBannerNotification: Notification.Name = Notification.Name(rawValue: "didShowNowPlayingBannerNotification")
    
    enum MainTabBarTab:Int {
        case episodes = 0
        case tips = 1
        case contactUs = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let episodeListVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodeListTableViewControllerId") as! EpisodeListTableViewController
        episodeListVC.title = "Episodes"
        let episodeListTabImage = UIImage(named: "ic_playlist_play_white")
        let epispodeNavVC = UINavigationController(rootViewController: episodeListVC)
        episodeListVC.tabBarItem = UITabBarItem(title: "Episodes", image: episodeListTabImage, tag: 0)
        _ = episodeListVC.view
        
        let freeTipsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        freeTipsVC.url = URL(string: "http://allearsenglish.com/tips")
        let freeTipsTabImage = UIImage(named: "ic_public_white")
        freeTipsVC.tabBarItem = UITabBarItem(title: "Free Tips", image: freeTipsTabImage, tag: 0)
        _ = freeTipsVC.view
        
        let contactUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        let contactUsTabImage = UIImage(named: "ic_public_white")
        contactUsVC.tabBarItem = UITabBarItem(title: "Contact Us", image: contactUsTabImage, tag: 0)
        _ = contactUsVC.view
        
        let aboutUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        if let path = Bundle.main.path(forResource: "aboutus", ofType: "html") {
            aboutUsVC.url = URL.init(fileURLWithPath: path)
        }
        let aboutUsTabImage = UIImage(named: "ic_public_white")
        aboutUsVC.tabBarItem = UITabBarItem(title: "About Us", image: aboutUsTabImage, tag: 0)
        _ = aboutUsVC.view
        
        let quickLinksVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        quickLinksVC.url = URL(string: "https://www.allearsenglish.com/resources/")
        let quickLinksVCTabImage = UIImage(named: "ic_public_white")
        quickLinksVC.tabBarItem = UITabBarItem(title: "Free Tips", image: quickLinksVCTabImage, tag: 0)
        _ = quickLinksVC.view
        
        self.viewControllers = [epispodeNavVC, freeTipsVC, aboutUsVC, quickLinksVC, contactUsVC]
        
        self.setupNowPlayingBanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerPlaybackStateDidChange), name: AudioPlayer.playbackStateDidChangeNotification, object: AudioPlayer.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlayingCurrentTrack), name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: AudioPlayer.sharedInstance)
        
        self.updateNowPlayingBannerState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: Now Playing Banner methods
extension MainTabBarController {
    func setupNowPlayingBanner() {
        
        
        let tabBarHeight = self.tabBar.frame.size.height
        
        let yPosition = self.view.frame.size.height - MainTabBarController.nowPlayingBannerHeight - tabBarHeight
        
        self.nowPlayingBannerView = NowPlayingBannerView(frame: CGRect(x: 0, y: yPosition, width: self.view.frame.size.width, height: MainTabBarController.nowPlayingBannerHeight))
        self.view.addSubview(self.nowPlayingBannerView)
        
        let views:[String:UIView] = ["nowPlayingView":self.nowPlayingBannerView]
        var allConstraints = [NSLayoutConstraint]()
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[nowPlayingView]-0-|", options: [], metrics: nil, views: views)
        allConstraints += horizontalConstraints
        
        //        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[nowPlayingView]-0-|", options: [], metrics: nil, views: views)
        //        allConstraints += verticalConstraints
        
        NSLayoutConstraint.activate(allConstraints)
        
        //banner starts hidden
        self.nowPlayingBannerView.isHidden = true
    }
    
    func updateNowPlayingBannerState() {
        self.nowPlayingBannerView.updateControlViews()
        
        if AudioPlayer.sharedInstance.currentItem != nil {
            self.showNowPlayingBannerAndNotify()
        }
        else {
            self.hideNowPlayingBannerAndNotify()
        }
    }
    
    func hideNowPlayingBannerAndNotify() {
        guard self.nowPlayingBannerView.isHidden == false else {
            return
        }
        
        self.nowPlayingBannerView.isHidden = true
        NotificationCenter.default.post(name: MainTabBarController.didHideNowPlayingBannerNotification, object: self, userInfo: nil)
    }
    
    func showNowPlayingBannerAndNotify() {
        guard self.nowPlayingBannerView.isHidden == true else {
            return
        }
        
        self.nowPlayingBannerView.isHidden = false
        NotificationCenter.default.post(name: MainTabBarController.didShowNowPlayingBannerNotification, object: self, userInfo: nil)
    }
}

//MARK: notifications
extension MainTabBarController {
    func audioPlayerDidFinishPlayingCurrentTrack(notification: Notification) {
        DispatchQueue.main.async {
            self.updateNowPlayingBannerState()
        }
    }
    
    func audioPlayerPlaybackStateDidChange(notification:Notification) {
        DispatchQueue.main.async {
            self.updateNowPlayingBannerState()
        }
    }
}
