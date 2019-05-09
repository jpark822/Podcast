//
//  FavoriteKeywordsViewController.swift
//  All Ears English
//
//  Created by Jay Park on 4/6/19.
//  Copyright © 2019 All Ears English. All rights reserved.
//

import UIKit

class FavoriteKeywordsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noFavoritesLabel: UILabel!    
    
    let keywordCellReuseId = "keywordCellReuseId"
    
    var keywordModels:[KeywordModel] = [] {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            if keywordModels.count == 0 {
                self.tableView.isHidden = true
                
                self.noFavoritesLabel.text = ApplicationData.isSubscribedToAEE ? "No Favorite keywords found" : "Upgrade to premium to save keywords"
                
                self.noFavoritesLabel.isHidden = false
            }
            else {
                self.tableView.isHidden = false
                self.noFavoritesLabel.isHidden = true
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.fetchKeywordsAndReload()
        
        self.tableView.register(UINib(nibName: "FavoriteKeywordTableViewCell", bundle: nil), forCellReuseIdentifier: self.keywordCellReuseId)
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.delegate = self
        
        self.tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchKeywordsAndReload()
    }
    
    func fetchKeywordsAndReload() {
        self.keywordModels = KeywordFavoritesManager.sharedInstance.getStoredKeywords().sorted(by: { (modelA, modelB) -> Bool in
            return modelA.name < modelB.name
        })
        self.tableView.reloadData()
    }
    

}

extension FavoriteKeywordsViewController:UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return KeywordFavoritesManager.sharedInstance.getStoredKeywords().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.keywordCellReuseId) as! FavoriteKeywordTableViewCell
        cell.configureWithKeyword(self.keywordModels[indexPath.row])
        cell.delegate = self
        
        return cell
    }
}

extension FavoriteKeywordsViewController:FavoriteKeywordTableViewCellDelegate {
    func favoriteKeywordTableViewCellDidDeleteKeyword() {
        self.fetchKeywordsAndReload()
    }
}
