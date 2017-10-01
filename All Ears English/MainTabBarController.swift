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
        
        let freeTipsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BrowserViewControllerId") as! BrowserViewController
        freeTipsVC.pageURL = URL.init(string: "http://allearsenglish.com/bridge")
        let freeTipsTabImage = UIImage(named: "ic_public_white")
        freeTipsVC.tabBarItem = UITabBarItem(title: "Free Tips", image: freeTipsTabImage, tag: 0)
        _ = freeTipsVC.view
        
        let contactUsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BrowserViewControllerId") as! BrowserViewController
        let contactUsTabImage = UIImage(named: "ic_public_white")
        contactUsVC.tabBarItem = UITabBarItem(title: "Contact Us", image: contactUsTabImage, tag: 0)
        _ = contactUsVC.view
        
        self.viewControllers = [epispodeNavVC, freeTipsVC, contactUsVC]
    }
}
