//
//  SelectSubscriptionViewController.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

protocol SelectSubscriptionViewControllerDelegate:class {
    func selectSubscriptionViewControllerDidSelectSubscription(product:SKProduct, viewController:SelectSubscriptionViewController)
    func SelectSubscriptionViewControllerDelegateDidCancel(viewController:SelectSubscriptionViewController)
}

class SelectSubscriptionViewController: UIViewController {
    
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var yearlyButton: UIButton!
    
    enum StateType {
        case signup
        case renew
    }
    
    fileprivate var monthlyPassSKProduct:SKProduct!
    fileprivate var yearlyPassSKProduct:SKProduct!
    
    var stateType:StateType = .signup
    
    weak var delegate:SelectSubscriptionViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.monthlyButton.isEnabled = false
        self.yearlyButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        self.fetchData()
    }
    
    func fetchData() {
        IAPStore.store.requestProductsWithCompletionHandler { (success, products) in
            if success {
                for product in products {
                    if product.productIdentifier == IAPStore.monthlyPass {
                        self.monthlyButton.isEnabled = true
                        self.monthlyPassSKProduct = product
                    }
                    if product.productIdentifier == IAPStore.yearlyPass {
                        self.yearlyButton.isEnabled = true
                        self.yearlyPassSKProduct = product
                    }
                }
            }
        }
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        self.delegate?.SelectSubscriptionViewControllerDelegateDidCancel(viewController: self)
    }
    
    @IBAction func monthlyButtonPressed(_ sender: Any) {
        switch self.stateType {
        case .renew:
            break
        case .signup:
            self.delegate?.selectSubscriptionViewControllerDidSelectSubscription(product: self.monthlyPassSKProduct, viewController: self)
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
    
    func startPurchase() {
        //TODO buy the subscription
    }
}
