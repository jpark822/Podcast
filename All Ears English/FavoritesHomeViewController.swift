//
//  FavoritesHomeViewController.swift
//  All Ears English
//
//  Created by Jay Park on 4/6/19.
//  Copyright © 2019 All Ears English. All rights reserved.
//

import UIKit

class FavoritesHomeViewController: UIViewController {
    
    enum TabIndex:Int {
        case episodes = 0
        case keywords = 1
    }

    @IBOutlet weak var childViewControllerContentView: UIView!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var currentViewController: UIViewController? {
        return viewControllerForSelectedSegmentIndex(self.segmentedControl.selectedSegmentIndex)
    }
    
    lazy var episodesVC: UIViewController? = {
        let episodeVC = self.storyboard?.instantiateViewController(withIdentifier: "FavoritesListTableViewControllerId")
        return episodeVC
    }()
    lazy var keywordsVC : UIViewController? = {
        let keywordsVC = self.storyboard?.instantiateViewController(withIdentifier: "FavoriteKeywordsViewControllerId")
        
        return keywordsVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayCurrentTab(self.segmentedControl.selectedSegmentIndex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func segmentedControlChangedValue(_ sender: UISegmentedControl) {
        self.removeCurrentViewController()
        self.displayCurrentTab(sender.selectedSegmentIndex)
    }
    
    func viewControllerForSelectedSegmentIndex(_ index: Int) -> UIViewController? {
        switch index {
        case TabIndex.episodes.rawValue :
            return episodesVC
        case TabIndex.keywords.rawValue :
            return keywordsVC
        default:
            return nil
        }
    }
    
    func displayCurrentTab(_ tabIndex: Int){
        if let childVC = viewControllerForSelectedSegmentIndex(tabIndex) {
            
            self.addChild(childVC)
            self.childViewControllerContentView.addSubview(childVC.view)
            
            childVC.view.frame = self.childViewControllerContentView.bounds
            childVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            childVC.didMove(toParent: self)
        }
    }
    
    private func removeCurrentViewController() {
        guard let viewController = self.currentViewController else {
            return
        }
        viewController.willMove(toParent: nil)
        
        viewController.view.removeFromSuperview()
        
        viewController.removeFromParent()
    }
}
