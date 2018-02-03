//
//  SplashViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/19/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func letsGoPressed(_ sender: Any) {
        AnalyticsManager.sharedInstance.logKochavaCustomEvent(.letsGoPressed, properties: nil)
        
        let initialVC = UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarControllerId") as! MainTabBarController
        self.present(initialVC, animated: true)
    }

}
