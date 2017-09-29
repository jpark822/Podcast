//
//  MainTabBarViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 6/26/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.delegate = self        
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

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            if navigationController.viewControllers.count > 0 {
                if let controller = navigationController.viewControllers[0] as? BrowserViewController {
                    print("Free Tips controller")
                    controller.pageTitle = "Free Tips"
                    controller.pageURL = URL.init(string: "http://allearsenglish.com/bridge")
                }
            }
        }
    }

}
