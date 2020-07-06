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
        
        let purchaseCarouselVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "PurchaseCarouselViewControllerId") as! PurchaseCarouselViewController
        purchaseCarouselVC.delegate = self
        self.viewControllers = [purchaseCarouselVC]
        
//        let selectSubVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "SelectSubscriptionViewControllerId") as! SelectSubscriptionViewController
//        selectSubVC.delegate = self
//        self.viewControllers = [selectSubVC]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

//MARK: SignUpViewControllerDelegate
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
            viewController.isPurchaseEnabled = false
            IAPStore.store.purchaseProduct(product) { (success, error) in
                viewController.isPurchaseEnabled = true
                if success == true {
                    self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController: self)
                }
            }
            break
        }
    }
    
    func SelectSubscriptionViewControllerDelegateDidCancel(viewController: SelectSubscriptionViewController) {
        self.popViewController(animated: true)
    }
}


//MARK: SignUpViewControllerDelegate
extension SubscriptionSignupNavigationController: SignUpViewControllerDelegate {
    func signUpViewControllerDelegateDidFinish(signupViewController: SignUpViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController: self)
    }
    
    func signUpViewControllerDelegateDidCancel(signupViewController: SignUpViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidCancel(viewController: self)
    }
}

//MARK: PurchaseCarouselViewControllerDelegate
extension SubscriptionSignupNavigationController:PurchaseCarouselViewControllerDelegate {
    func purchaseCarouselViewControllerDidCancel(viewController: PurchaseCarouselViewController) {
        self.subscriptionNavigationDelegate?.subscriptionSignupNavigationControllerDidCancel(viewController: self)
    }
    
    func purchaseCarouselViewControllerDidPressContinue(viewController: PurchaseCarouselViewController) {
        let selectSubVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "SelectSubscriptionViewControllerId") as! SelectSubscriptionViewController
        selectSubVC.delegate = self
        self.pushViewController(selectSubVC, animated: true)
    }
}
