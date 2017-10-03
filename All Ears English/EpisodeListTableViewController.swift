//
//  EpisodeListTableViewController.swift
//  All Ears English
//
//  Created by Jay Park on 10/1/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class EpisodeListTableViewController: UITableViewController {

    var pullToRefreshControl: UIRefreshControl!
    
    fileprivate var episodeItems:[Feed.Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupRefreshControl()
        self.fetchData()
    }
    
    func setupRefreshControl() {
        self.pullToRefreshControl = UIRefreshControl()
        self.pullToRefreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSFontAttributeName:UIFont(name: "Montserrat-Regular", size: 17.0)])
        self.pullToRefreshControl.addTarget(self, action: #selector(fetchData), for: UIControlEvents.valueChanged)
        self.pullToRefreshControl.backgroundColor = UIColor.white
        self.tableView.addSubview(self.pullToRefreshControl)
    }

    func fetchData() {
        Feed.shared.fetchData { (feedItems) in
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
}

//MARK: TableView datasource and delegate
extension EpisodeListTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeCell
        
        cell.item = self.episodeItems[indexPath.row]
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Feed.shared.items.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodeDetailVC = UIStoryboard(name: "Episodes", bundle: nil).instantiateViewController(withIdentifier: "EpisodeDetailsViewControllerId") as! EpisodeDetailsViewController
        //workaround for inherited code
        _ = episodeDetailVC.view
        episodeDetailVC.item = self.episodeItems[indexPath.row]
        self.navigationController?.pushViewController(episodeDetailVC, animated: true)
    }
}
