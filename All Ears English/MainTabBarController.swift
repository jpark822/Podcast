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
        
        self.setupNowPlayingBanner()
        
        self.configureMoreNavigationStyle()
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
        let iconImageSize = CGSize(width: 22, height: 22)
        let episodeListVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodeListTableViewControllerId") as! EpisodeListTableViewController
        episodeListVC.title = "Episodes"
        let episodeListTabImage = UIImage(named: "ic_playlist_play_white")
        let epispodeNavVC = UINavigationController(rootViewController: episodeListVC)
        epispodeNavVC.tabBarItem = UITabBarItem(title: "Episodes", image: episodeListTabImage, tag: 0)
        _ = episodeListVC.view
        
        let bonusesVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "BonusEpisodesTableViewControllerId")
        bonusesVC.title = "Bonuses"
        
        let bonusesTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_bonus")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_bonus")
        let bonusesNavVC = UINavigationController(rootViewController: bonusesVC)
        bonusesNavVC.tabBarItem = UITabBarItem(title: "Bonuses", image: bonusesTabImage, tag: 0)
        _ = bonusesVC.view
        
        let favoritesVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "FavoritesListTableViewControllerId") as! FavoritesListTableViewController
        favoritesVC.title = "Favorites"
        let favoritesTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_favorites")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_favorites")
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
        freeTipsVC.analyticsPageVisitName = "Free Tips"
        _ = freeTipsVC.view
        
        let aboutUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
        aboutUsVC.title = "About Us"
        if let path = Bundle.main.path(forResource: "aboutus", ofType: "html") {
            aboutUsVC.url = URL.init(fileURLWithPath: path)
        }
        let aboutUsTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_about")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_about")
        aboutUsVC.tabBarItem = UITabBarItem(title: "About Us", image: aboutUsTabImage, tag: 0)
        aboutUsVC.analyticsPageVisitName = "About Us"
        _ = aboutUsVC.view
        
//        let quickLinksVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "WebViewControllerId") as! WebViewController
//        quickLinksVC.title = "Quick Links"
//        quickLinksVC.doesReloadOnViewWillAppear = true
//        quickLinksVC.url = URL(string: "https://www.allearsenglish.com/resources/")
//        let quickLinksVCTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_quick_links")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_quick_links")
//        quickLinksVC.tabBarItem = UITabBarItem(title: "Quick Links", image: quickLinksVCTabImage, tag: 0)
//        _ = quickLinksVC.view
        
        let contactUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ContactUsViewControllerId") as! ContactUsViewController
        contactUsVC.title = "Contact Us"
        let contactUsTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_contact_us")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_contact_us")
        let contactUsNavVC = UINavigationController(rootViewController: contactUsVC)
        contactUsNavVC.tabBarItem = UITabBarItem(title: "Contact Us", image: contactUsTabImage, tag: 0)
        _ = contactUsVC.view
        
        let rateUsVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "RateUsViewControllerId") as! RateUsViewController
        rateUsVC.title = "Rate Us"
        let rateUsVCTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_rate_us")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_rate_us")
        let rateUsNavVC = UINavigationController(rootViewController: rateUsVC)
        rateUsNavVC.tabBarItem = UITabBarItem(title: "Rate Us", image: rateUsVCTabImage, tag: 0)
        _ = rateUsVC.view
        
        let shareVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "ShareViewControllerId") as! ShareViewController
        shareVC.title = "Share"
        let shareVCTabImage = UIImage.imageWithImage(image: UIImage(named: "tab_share")!, scaledToSize: iconImageSize) ?? UIImage(named: "tab_share")
        let shareNavVC = UINavigationController(rootViewController: shareVC)
        shareNavVC.tabBarItem = UITabBarItem(title: "Share", image: shareVCTabImage, tag: 0)
        _ = shareVC.view
        
        self.viewControllers = [epispodeNavVC, bonusesNavVC, favoritesNavVC, freeTipsNavVC, aboutUsVC, contactUsNavVC, rateUsNavVC, shareNavVC]
    }
    
    func configureMoreNavigationStyle() {
        if let moreNavTableView = self.moreNavigationController.topViewController?.view as? UITableView {
            if moreNavTableView.subviews.count > 0 {
                for cell in moreNavTableView.visibleCells {
                    cell.textLabel?.font = UIFont(name: "PTSans-Regular", size: 16)
                }
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let tabBarHeight = self.tabBar.frame.size.height
        let yPosition = self.view.frame.size.height - MainTabBarController.nowPlayingBannerHeight - tabBarHeight
        self.nowPlayingBannerView.frame = CGRect(x: 0, y: yPosition, width: self.view.frame.size.width, height: MainTabBarController.nowPlayingBannerHeight)
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
