//
//  BonusEpisodesTableViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/14/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class BonusEpisodesTableViewController: UITableViewController, EpisodePlayerViewControllerDelegate, EpisodeCellDelegate {
    
    var pullToRefreshControl: UIRefreshControl!
    
    fileprivate var episodeItems:[Feed.Item] = []
    fileprivate var episodeCellReuseID = "EpisodeListCellReuseId"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "EpisodeCell", bundle: nil) , forCellReuseIdentifier: self.episodeCellReuseID)
        self.setupRefreshControl()
        self.fetchData()
        self.automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateContentInsetBasedOnNowPlayingBanner()
        
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidShowHandler(notification:)), name: MainTabBarController.didShowNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidHideHandler(notification:)), name: MainTabBarController.didHideNowPlayingBannerNotification, object: nil)
        
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupRefreshControl() {
        self.pullToRefreshControl = UIRefreshControl()
        self.pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSFontAttributeName:UIFont(name: "Montserrat-Regular", size: 17.0)!])
        self.pullToRefreshControl.addTarget(self, action: #selector(fetchData), for: UIControlEvents.valueChanged)
        self.pullToRefreshControl.backgroundColor = UIColor.white
        self.tableView.addSubview(self.pullToRefreshControl)
    }
    
    func fetchData() {
        Feed.shared.fetchBonusFeed { (feedItems) in
            DispatchQueue.main.async {
                if let feedItems = feedItems {
                    self.episodeItems = feedItems
                    self.tableView.reloadData()
                }
                else {
                    print("unable to load feed")
                }
                self.pullToRefreshControl.endRefreshing()
            }
        }
    }
    
    func nowPlayingBannerDidShowHandler(notification: Notification) {
        self.updateContentInsetBasedOnNowPlayingBanner()
    }
    
    func nowPlayingBannerDidHideHandler(notification: Notification) {
        self.updateContentInsetBasedOnNowPlayingBanner()
    }
    
    func updateContentInsetBasedOnNowPlayingBanner() {
        if let mainTabBarVC = self.tabBarController as? MainTabBarController {
            if mainTabBarVC.nowPlayingBannerView.isHidden {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
            else {
                self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: MainTabBarController.nowPlayingBannerHeight, right: 0)
            }
        }
    }

}

//MARK: TableView datasource and delegate
extension BonusEpisodesTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.episodeCellReuseID, for: indexPath) as! EpisodeCell
        
        cell.item = self.episodeItems[indexPath.row]
        cell.configureAsBonusItem()
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Feed.shared.bonusItems.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodeItem = self.episodeItems[indexPath.row]
        
        if episodeItem.isVideoContent {
            var finalUrl:URL? = nil
            
            if let localURL = Cache.shared.get(episodeItem) {
                finalUrl = localURL
            }
            else if let urlString = episodeItem.url,
                let remoteUrl = URL(string: urlString) {
                finalUrl = remoteUrl
            }
            guard let videoURL = finalUrl else {
                return
            }
        
            let player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
        else if episodeItem.isVideoContent == false {
            let playerVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodePlayerViewControllerId") as! EpisodePlayerViewController
            playerVC.episodeItem = episodeItem
            playerVC.feedType = .bonus
            playerVC.delegate = self
            self.present(playerVC, animated: true)
        }
    }
}

//MARK: EpisodePlayerViewControllerDelegate
extension BonusEpisodesTableViewController {
    func episodePlayerViewControllerDidPressDismiss(episodePlayerViewController:EpisodePlayerViewController) {
        self.dismiss(animated: true)
    }
}

//MARK: EpisodeCellDelegate
extension BonusEpisodesTableViewController {
    func episodeCellDidTapFavoriteButton(episodeCell: EpisodeCell) {
        guard let item = episodeCell.item else {
            return
        }
        
        if FavoritesManager.isItemInFavorites(item: item) {
            FavoritesManager.sharedInstance.removeFavorite(item)
        }
        else {
            FavoritesManager.sharedInstance.addFavorite(item)
        }
        
        self.tableView.reloadRows(at: [episodeCell.indexPath], with: .none)
    }
    
    func episodeCellRequestDownload(episodeCell: EpisodeCell) {
        guard let cellItem = episodeCell.item else {
            return
        }
        
        Cache.shared.download(cellItem, callback: { (downloadedItem) in
            self.tableView.reloadRows(at: [episodeCell.indexPath], with: .none)
        })
    }
}
