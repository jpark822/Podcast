//
//  SubscriptionSignupNavigationController.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

protocol SubscriptionSignupNavigationControllerDelegate:class {
    func subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController:SubscriptionSignupNavigationController)
    func subscriptionSignupNavigationControllerDidCancel(viewController:SubscriptionSignupNavigationController)
}

class SubscriptionSignupNavigationController: UINavigationController {
    
    enum StateType {
        case signup
        case renew
    }
    
    weak var subscriptionNavigationDelegate:SubscriptionSignupNavigationControllerDelegate?
    var state:StateType = .signup

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chooseSubVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "SelectSubscriptionViewControllerId") as! SelectSubscriptionViewController
        chooseSubVC.delegate = self
        self.viewControllers = [chooseSubVC]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}


extension SubscriptionSignupNavigationController:SelectSubscriptionViewControllerDelegate {
    func selectSubscriptionViewControllerDidSelectSubscription(product: SKProduct, viewController: SelectSubscriptionViewController) {
        switch self.state {
        case .signup:
            let signupVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewControllerId") as! SignUpViewController
            signupVC.subscriptionSKProduct = product
            signupVC.delegate = self
            self.pushViewController(signupVC, animated: true)
            break
        case .renew:
            //TODO attempt to purchase
            break
        }
    }
    
    func SelectSubscriptionViewControllerDelegateDidCancel(viewController: SelectSubscriptionViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidCancel(viewController: self)
    }
}


extension SubscriptionSignupNavigationController: SignUpViewControllerDelegate {
    func signUpViewControllerDelegateDidFinish(signupViewController: SignUpViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController: self)
    }
    
    func signUpViewControllerDelegateDidCancel(signupViewController: SignUpViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidCancel(viewController: self)
    }
    
    
}
