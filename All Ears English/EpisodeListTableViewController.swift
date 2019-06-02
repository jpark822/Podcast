//
//  EpisodeListTableViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/1/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import AlamofireImage
import Alamofire
import FirebaseAuth

protocol EpisodeListTableViewControllerDelegate:class {
    func episodeListTableViewControllerDidSelect(episode:Feed.Item)
}

class EpisodeListTableViewController: UIViewController, EpisodePlayerViewControllerDelegate, EpisodeCellDelegate, UITableViewDataSource, UITableViewDelegate {
    
    weak var episodeListDelegate:EpisodeListTableViewControllerDelegate?

    var pullToRefreshControl: UIRefreshControl!
    @IBOutlet weak var tableView: UITableView!
    
    //master list of episode items
    fileprivate var episodeItems:[Feed.Item] = []
    //filtered items used when the user is searching
    fileprivate var filteredEpisodeItems:[Feed.Item] = []
    
    fileprivate var episodeCellReuseID = "EpisodeListCellReuseId"
    fileprivate var signupHeaderReuseID = "signupHeaderReuseId"
    fileprivate var isFirstLaunch = true
    
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
        self.tableView.register(UINib(nibName: "SignupLoginCTASectionHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: self.signupHeaderReuseID)
        self.tableView.sectionHeaderHeight = UITableView.automaticDimension;
        self.tableView.estimatedSectionHeaderHeight = 200;
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.setupRefreshControl()
        self.setupSearchController()
        
        self.episodeItems = Feed.shared.fetchLocalEpisodeItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidShowHandler(notification:)), name: MainTabBarController.didShowNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(nowPlayingBannerDidHideHandler(notification:)), name: MainTabBarController.didHideNowPlayingBannerNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(episodeItemCachedStateDidChange(notification:)), name: Cache.episodeItemDidChangeCachedStateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesManagerDidUnfavoriteItem(notification:)), name: FavoritesManager.favoritesManagerDidUnfavoriteItemNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyBoardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.isFirstLaunch == true {
            self.showRefreshControl()
            self.fetchData()
        }
        self.isFirstLaunch = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateContentInsetBasedOnNowPlayingBanner()
        AnalyticsManager.sharedInstance.logMixpanelPageVisit("Page Visit: Episode List")
        
        if Auth.auth().currentUser != nil {
            self.setupLogoutButton()
        }
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func setupRefreshControl() {
        self.pullToRefreshControl = UIRefreshControl()
        self.pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name: "PTSans-Regular", size: 17.0)!]))
        self.pullToRefreshControl.addTarget(self, action: #selector(fetchData), for: UIControl.Event.valueChanged)
        self.pullToRefreshControl.backgroundColor = UIColor.white
        self.tableView.addSubview(self.pullToRefreshControl)
        self.tableView.refreshControl = self.pullToRefreshControl
    }
    
    func showRefreshControl() {
        self.pullToRefreshControl.beginRefreshing()
        if (self.tableView.contentOffset.y == 0) {
            UIView.animate(withDuration: 0.25, delay: 0, options: [UIView.AnimationOptions.beginFromCurrentState], animations: { 
                self.tableView.contentOffset = CGPoint(x:0, y: -self.tableView.refreshControl!.frame.size.height)
            }, completion: { (finished) in
                
            })
        }
    }

    @objc func fetchData() {
        Feed.shared.fetchData { (feedItems) in
            DispatchQueue.main.async {
                
                if let feedItems = feedItems, feedItems.count > 0 {
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
    
    @objc func episodeItemCachedStateDidChange(notification: Notification) {
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
    
    @objc func favoritesManagerDidUnfavoriteItem(notification:Notification) {
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
    
    @objc func nowPlayingBannerDidShowHandler(notification: Notification) {
        self.updateContentInsetBasedOnNowPlayingBanner()
    }
    
    @objc func nowPlayingBannerDidHideHandler(notification: Notification) {
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
extension EpisodeListTableViewController {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.episodeCellReuseID, for: indexPath) as! EpisodeCell
        
        cell.item = self.isSearching ? self.filteredEpisodeItems[indexPath.row] : self.episodeItems[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodeItem = self.isSearching ? self.filteredEpisodeItems[indexPath.row] : self.episodeItems[indexPath.row]
        
        self.episodeListDelegate?.episodeListTableViewControllerDidSelect(episode: episodeItem)
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && Auth.auth().currentUser == nil {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.signupHeaderReuseID) as! SignupLoginCTASectionHeader
            header.delegate = self
            return header
        }
        return UIView(frame: CGRect.zero)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && Auth.auth().currentUser == nil {
            return UITableView.automaticDimension
        }
        return 0
    }
}

//MARK: EpisodePlayerViewControllerDelegate
extension EpisodeListTableViewController {
    func episodePlayerViewControllerDidPressDismiss(episodePlayerViewController:EpisodePlayerViewController) {
        self.dismiss(animated: true)
    }
}

//MARK: EpisodeCellDelegate
extension EpisodeListTableViewController {
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
extension EpisodeListTableViewController: UISearchResultsUpdating {
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
            for keyword in item.keywords {
                //make keyword searching restrictive to at least 3 characters to reduce noise
                if lowercaseTrimmedSearchText.count < 3 {
                    break
                }
                if keyword.range(of: lowercaseTrimmedSearchText) != nil {
                    return true
                }
            }
            for category in item.categories {
                //make keyword searching restrictive to at least 3 characters to reduce noise
                if lowercaseTrimmedSearchText.count < 3 {
                    break
                }
                if category.range(of: lowercaseTrimmedSearchText) != nil {
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
extension EpisodeListTableViewController {
    @objc func keyBoardWillShow(notification: NSNotification) {
        if let keyBoardSize = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyBoardSize.height, right: 0)
            self.tableView.contentInset = contentInsets
        }
    }
    
    @objc func keyBoardWillHide(notification: NSNotification) {
        self.updateContentInsetBasedOnNowPlayingBanner()
    }
}

extension EpisodeListTableViewController:SignupLoginCTASectionHeaderDelegate {
    func signupLoginCTASectionHeaderDidPressLogin(header: SignupLoginCTASectionHeader) {
        let loginNavVC = LoginViewController.loginViewControllerWithNavigation(delegate: self)
        self.present(loginNavVC, animated: true)
    }
    
    func signupLoginCTASectionHeaderDidPressSignUp(header: SignupLoginCTASectionHeader) {
        let signupsubVC = SubscriptionSignupNavigationController()
        signupsubVC.state = .signup
        signupsubVC.subscriptionNavigationDelegate = self
        self.present(signupsubVC, animated: true)
    }
}

//Login
extension EpisodeListTableViewController: LoginUpViewControllerDelegate {
    func loginViewControllerDelegateDidCancel(loginViewController: LoginViewController) {
        loginViewController.dismiss(animated: true)
    }
    func loginViewControllerDelegateDidFinish(loginViewController: LoginViewController) {
        self.tableView.reloadData()
        self.setupLogoutButton()
        loginViewController.dismiss(animated: true)
    }
    
    func setupLogoutButton() {
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(self.logoutPressed))
        self.navigationItem.leftBarButtonItem = logoutButton
    }
    @objc func logoutPressed() {
        do {
            try Auth.auth().signOut()
            self.tableView.reloadData()
            self.navigationItem.leftBarButtonItem = nil
        }
        catch {
            
        }
    }
}

//Signup
extension EpisodeListTableViewController:SubscriptionSignupNavigationControllerDelegate {
    func subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController: SubscriptionSignupNavigationController) {
        self.tableView.reloadData()
        self.setupLogoutButton()
        viewController.dismiss(animated: true)
    }
    
    func subscriptionSignupNavigationControllerDidCancel(viewController: SubscriptionSignupNavigationController) {
        viewController.dismiss(animated: true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
