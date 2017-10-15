//
//  FavoritesListTableViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/9/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class FavoritesListTableViewController: UITableViewController, EpisodeCellDelegate, EpisodePlayerViewControllerDelegate {

    var favoriteItems:[Feed.Item] = []
    
    var favoriteEpisodeCellReuseID = "favoriteEpisodeCellReuseID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "EpisodeCell", bundle: nil) , forCellReuseIdentifier: self.favoriteEpisodeCellReuseID)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.favoriteItems = FavoritesManager.sharedInstance.getAllStoredFavorites()
        self.tableView.reloadData()
        
        self.updateContentInsetBasedOnNowPlayingBanner()
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidShowHandler(notification:)), name: MainTabBarController.didShowNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidHideHandler(notification:)), name: MainTabBarController.didHideNowPlayingBannerNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
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

// MARK: - Table view data source
extension FavoritesListTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.favoriteItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.favoriteEpisodeCellReuseID) as! EpisodeCell
        
        cell.item = self.favoriteItems[indexPath.row]
        cell.delegate = self
        cell.indexPath = indexPath
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let playerVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodePlayerViewControllerId") as! EpisodePlayerViewController
        playerVC.episodeItem = self.favoriteItems[indexPath.row]
        playerVC.delegate = self
        self.present(playerVC, animated: true)
    }
}

// MARK: - EpisodeCellDelegate
extension FavoritesListTableViewController {
    func episodeCellDidTapFavoriteButton(episodeCell: EpisodeCell) {
        guard let item = episodeCell.item else {
            return
        }
        FavoritesManager.sharedInstance.removeFavorite(item)
        self.favoriteItems = FavoritesManager.sharedInstance.getAllStoredFavorites()
        self.tableView.reloadData()
    }
}

//MARK: EpisodePlayerViewControllerDelegate
extension FavoritesListTableViewController {
    func episodePlayerViewControllerDidPressDismiss(episodePlayerViewController:EpisodePlayerViewController) {
        self.dismiss(animated: true)
    }
}