//
//  SelectSubscriptionViewController.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit

protocol SelectSubscriptionViewControllerDelegate:class {
    func selectSubscriptionViewControllerDidSelectMonthly(viewController:SelectSubscriptionViewController)
    func selectSubscriptionViewControllerDidSelectYearly(viewController:SelectSubscriptionViewController)
}

class SelectSubscriptionViewController: UIViewController {
    
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var yearlyButton: UIButton!
    
    enum StateType {
        case signup
        case renew
    }
    
    var stateType:StateType = .signup
    
    weak var delegate:SelectSubscriptionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func monthlyButtonPressed(_ sender: Any) {
        switch self.stateType {
        case .renew:
            break
        case .signup:
            break
        }
        
    }
    
    @IBAction func yearlyButtonPressed(_ sender: Any) {
        switch self.stateType {
        case .renew:
            break
        case .signup:
            break
        }
    }
    
    func continueToCreateAccount() {
        let createAccountVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewControllerId") as! SignUpViewController
        self.navigationController?.pushViewController(createAccountVC, animated: true)
    }
    
    func startPurchase() {
        //TODO buy the subscription
    }
}
