//
//  MainTabBarController.swift
//  All Ears English
//
//  Created by Jay Park on 10/1/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Foundation

class MainTabBarController: UITabBarController, NowPlayingBannerViewDelegate, EpisodePlayerViewControllerDelegate {
    
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
        
        self.setupTabBarViewControllers()
        
        self.customizableViewControllers = []
        self.setupMoreViewControllerNavigationItems()
        
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
    
    func setupTabBarViewControllers() {
        let episodeListVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodeListTableViewControllerId") as! EpisodeListTableViewController
        episodeListVC.title = "Episodes"
        let episodeListTabImage = UIImage(named: "ic_playlist_play_white")
        let epispodeNavVC = UINavigationController(rootViewController: episodeListVC)
        epispodeNavVC.tabBarItem = UITabBarItem(title: "Episodes", image: episodeListTabImage, tag: 0)
        _ = episodeListVC.view
        
        let bonusesVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "BonusEpisodesTableViewControllerId")
        bonusesVC.title = "Bonuses"
        let bonusesTabImage = UIImage(named: "ic_playlist_play_white")
        let bonusesNavVC = UINavigationController(rootViewController: bonusesVC)
        bonusesNavVC.tabBarItem = UITabBarItem(title: "Bonuses", image: bonusesTabImage, tag: 0)
        _ = bonusesVC.view
        
        let favoritesVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "FavoritesListTableViewControllerId") as! FavoritesListTableViewController
        favoritesVC.title = "Favorites"
        let favoritesTabImage = UIImage(named: "ic_playlist_play_white")
        let favoritesNavVC = UINavigationController(rootViewController: favoritesVC)
        favoritesNavVC.tabBarItem = UITabBarItem(title: "Favorites", image: favoritesTabImage, tag: 0)
        _ = favoritesVC.view
        
        let freeTipsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        freeTipsVC.url = URL(string: "http://allearsenglish.com/tips")
        freeTipsVC.title = "Free Tips"
        freeTipsVC.doesReloadOnViewWillAppear = true
        let freeTipsNavVC = UINavigationController(rootViewController: freeTipsVC)
        let freeTipsNavTabImage = UIImage(named: "ic_public_white")
        freeTipsNavVC.tabBarItem = UITabBarItem(title: "Free Tips", image: freeTipsNavTabImage, tag: 0)
        _ = freeTipsVC.view
        
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
        quickLinksVC.tabBarItem = UITabBarItem(title: "Quick Links", image: quickLinksVCTabImage, tag: 0)
        _ = quickLinksVC.view
        
        let contactUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        let contactUsTabImage = UIImage(named: "ic_public_white")
        contactUsVC.tabBarItem = UITabBarItem(title: "Contact Us", image: contactUsTabImage, tag: 0)
        _ = contactUsVC.view
        
        let rateUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "RateUsViewControllerId") as! RateUsViewController
        rateUsVC.title = "Rate Us"
        let rateUsVCTabImage = UIImage(named: "ic_public_white")
        let rateUsNavVC = UINavigationController(rootViewController: rateUsVC)
        rateUsNavVC.tabBarItem = UITabBarItem(title: "Rate Us", image: rateUsVCTabImage, tag: 0)
        _ = rateUsVC.view
        
        let shareVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ShareViewControllerId") as! ShareViewController
        shareVC.title = "Share"
        let shareVCTabImage = UIImage(named: "ic_public_white")
        let shareNavVC = UINavigationController(rootViewController: shareVC)
        shareNavVC.tabBarItem = UITabBarItem(title: "Share", image: rateUsVCTabImage, tag: 0)
        _ = shareVC.view
        
        self.viewControllers = [epispodeNavVC, bonusesNavVC, favoritesNavVC, freeTipsNavVC, aboutUsVC, quickLinksVC, contactUsVC, rateUsNavVC, shareNavVC]
    }
    
    func shareButtonPressed() {
        
    }
    
    func setupMoreViewControllerNavigationItems() {
        let shareButton = UIBarButtonItem(image: UIImage(named: "ic_share") , style: UIBarButtonItemStyle.plain, target: self, action: #selector(shareButtonPressed))
        self.moreNavigationController.navigationItem.rightBarButtonItem = shareButton
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
        self.nowPlayingBannerView.delegate = self
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

//MARK: NowPlayingBannerViewDelegate 
extension MainTabBarController {
    func nowPlayingBannerViewWasTapped(nowPlayingBannerView: NowPlayingBannerView) {
        guard let currentItem = AudioPlayer.sharedInstance.currentItem else {
            return
        }
        
        let playerVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodePlayerViewControllerId") as! EpisodePlayerViewController
        playerVC.episodeItem = currentItem
        playerVC.delegate = self
        self.present(playerVC, animated: true)
    }
}

//MARK: EpisodePlayerViewControllerDelegate
extension MainTabBarController {
    func episodePlayerViewControllerDidPressDismiss(episodePlayerViewController: EpisodePlayerViewController) {
        self.dismiss(animated: true)
    }
}
