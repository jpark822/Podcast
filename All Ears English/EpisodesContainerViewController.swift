//
//  EpisodesContainerViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 7/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class EpisodesContainerViewController: UIViewController {
    
    @IBOutlet weak var bannerView: BannerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bannerView?.presentingController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bannerView?.addPlaybackObserver()
        self.bannerView?.update()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.bannerView?.removePlaybackObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        let height = self.bannerView?.frame.size.height ?? 0
        let tabHeight = self.tabBarController?.tabBar.frame.height ?? 0
        self.bannerView?.frame.origin.y = self.view.frame.size.height - self.view.frame.origin.y - height - tabHeight
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func toggleMenu(_ sender: Any) {
        ViewController.doToggleMenu(sender)
    }
    
    @IBAction func shareApp(_ sender: Any) {
        ViewController.doShareApp(sender)
    }
    
}
