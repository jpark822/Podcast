//
//  MainTabBarController.swift
//  All Ears English
//
//  Created by Jay Park on 10/1/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
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
    }
}
