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

class BonusEpisodesTableViewController: UIViewController, EpisodePlayerViewControllerDelegate, EpisodeCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    var pullToRefreshControl: UIRefreshControl!
    
    //master list of episode items
    fileprivate var episodeItems:[Feed.Item] = []
    //filtered items used when the user is searching
    fileprivate var filteredEpisodeItems:[Feed.Item] = []
    
    fileprivate var episodeCellReuseID = "EpisodeListCellReuseId"
    
    //searching
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var isSearchBarEmpty:Bool {
        return self.searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
    fileprivate var isSearching: Bool {
        get {
            return !self.isSearchBarEmpty
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "EpisodeCell", bundle: nil) , forCellReuseIdentifier: self.episodeCellReuseID)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.setupRefreshControl()
        self.setupSearchController()
        
        //we only want this indicator for the initial empty state
        self.loadingIndicator.startAnimating()
        self.fetchData()
        
        self.automaticallyAdjustsScrollViewInsets = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateContentInsetBasedOnNowPlayingBanner()
        
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidShowHandler(notification:)), name: MainTabBarController.didShowNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidHideHandler(notification:)), name: MainTabBarController.didHideNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(episodeItemCachedStateDidChange(notification:)), name: Cache.episodeItemDidChangeCachedStateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: Bonus List")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupRefreshControl() {
        self.pullToRefreshControl = UIRefreshControl()
        self.pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSFontAttributeName:UIFont(name: "PTSans-Regular", size: 17.0)!])
        self.pullToRefreshControl.addTarget(self, action: #selector(fetchData), for: UIControlEvents.valueChanged)
        self.pullToRefreshControl.backgroundColor = UIColor.white
        self.tableView.addSubview(self.pullToRefreshControl)
    }
    
    func fetchData() {
        Feed.shared.fetchBonusFeed { (feedItems) in
            DispatchQueue.main.async {
                self.loadingIndicator.isHidden = true
                
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
    
    func episodeItemCachedStateDidChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let guid = userInfo["guid"] as? String else {
                return
        }
        
        var index = 0
        for item in self.episodeItems {
            if item.guid == guid {
                let indexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: .none)
                break
            }
            index += 1
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
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.episodeCellReuseID, for: indexPath) as! EpisodeCell
        
        cell.item = self.isSearching ? self.filteredEpisodeItems[indexPath.row] : self.episodeItems[indexPath.row]
        cell.configureAsBonusItem()
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isSearching{
            return self.filteredEpisodeItems.count
        }
        return self.episodeItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let episodeImage = UIImage(named: "episode_stub_image") else {
            return EpisodeCell.preferredDetailHeight
        }
        let oldWidth = episodeImage.size.width
        let oldHeight = episodeImage.size.height
        let aspectRatio = oldHeight/oldWidth
        let newHeight = aspectRatio * self.tableView.frame.size.width
        let newHeightWithDescription = newHeight + EpisodeCell.preferredDetailHeight
        return newHeightWithDescription
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodeItem = self.isSearching ? self.filteredEpisodeItems[indexPath.row] : self.episodeItems[indexPath.row]
        
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
        
            AudioPlayer.sharedInstance.pause()
            AudioPlayer.sharedInstance.currentlyPlayingFeedType = .bonus
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

//MARK: - Searching
extension BonusEpisodesTableViewController: UISearchResultsUpdating {
    func setupSearchController() {
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search Episodes"
        self.searchController.searchBar.barTintColor = UIColor.AEEYellow
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.PTSansRegular(size: 14)
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
    }
    
    func filterContentForSearchText(_ searchText:String?) {
        self.filteredEpisodeItems = self.episodeItems.filter({ (item) -> Bool in
            
            guard let lowercaseTrimmedSearchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
                return false
            }
            
            //TODO add more criteria for filtering
            if let lowercasedDisplayTitle = item.displayTitle?.lowercased() {
                if lowercasedDisplayTitle.contains(lowercaseTrimmedSearchText) {
                    return true
                }
            }
            if let episodeNumber = item.number {
                if episodeNumber.contains(lowercaseTrimmedSearchText) {
                    return true
                }
            }
            return false
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.filterContentForSearchText(searchController.searchBar.text)
    }
}

//Keyboard
extension BonusEpisodesTableViewController {
    func keyBoardWillShow(notification: NSNotification) {
        if let keyBoardSize = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardSize.height, right: 0)
            self.tableView.contentInset = contentInsets
        }
    }
    
    func keyBoardWillHide(notification: NSNotification) {
        self.updateContentInsetBasedOnNowPlayingBanner()
    }
}
