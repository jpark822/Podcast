//
//  IAPHelper.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//


import StoreKit

/// Notification that is generated when a product is purchased.
public let IAPHelperProductPurchasedSuccessNotification:NSNotification.Name = NSNotification.Name(rawValue: "IAPHelperProductPurchasedSuccessNotification")
public let IAPHelperProductPurchasedFailedNotification:NSNotification.Name = NSNotification.Name(rawValue: "IAPHelperProductPurchasedFailedNotification")

/// Product identifiers are unique strings registered on the app store.
public typealias ProductIdentifier = String

/// Completion handler called when products are fetched.
public typealias RequestProductsCompletionHandler = (_ success: Bool, _ products: [SKProduct]) -> ()
public typealias PurchaseProductsCompletionHandler = (_ success:Bool, _ error:Error?) -> ()


/// A Helper class for In-App-Purchases, it can fetch products, tell you if a product has been purchased,
/// purchase products, and restore purchases.  Uses NSUserDefaults to cache if a product has been purchased.
open class IAPHelper : NSObject  {
    
    // Used to keep track of the possible products and which ones have been purchased.
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
    
    // Used by SKProductsRequestDelegate
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var requestProductsCompletionHandler: RequestProductsCompletionHandler?
    fileprivate var purchaseProductCompletionHandler: PurchaseProductsCompletionHandler?
    
    
    /// MARK: - User facing API
    
    /// Initialize the helper.  Pass in the set of ProductIdentifiers supported by the app.
    public init(productIdentifiers: Set<ProductIdentifier>) {
        self.productIdentifiers = productIdentifiers
        for productIdentifier in productIdentifiers {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            }
            else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    /// Gets the list of SKProducts from the Apple server calls the handler with the list of products.
    func requestProductsWithCompletionHandler(_ handler: @escaping RequestProductsCompletionHandler) {
        requestProductsCompletionHandler = handler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// Initiates purchase of a product.
    func purchaseProduct(_ product: SKProduct, completion: @escaping PurchaseProductsCompletionHandler) {
        print("Buying \(product.productIdentifier)...")
        self.purchaseProductCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    var isSubscribedToAEE:Bool {
        for productIdentifier in self.productIdentifiers {
            if isProductPurchased(productIdentifier) {
                return true
            }
        }
        return false
    }
    
    func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

// This extension is used to get a list of products, their titles, descriptions,
// and prices from the Apple server.

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        requestProductsCompletionHandler?(true, products)
        clearRequest()
        
        // debug printing
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error)")
        clearRequest()
    }
    
    fileprivate func clearRequest() {
        productsRequest = nil
        requestProductsCompletionHandler = nil
    }
}


//MARK: SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        
    }
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction)
                break
            case .failed:
                failedTransaction(transaction)
                break
            case .restored:
                restoreTransaction(transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("transaction restore completed")
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("completeTransaction...")
        provideContentForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
//TODO purchase sub
//        ServiceManager.sharedInstace.addSubcription { (success, error) in
//            self.purchaseProductCompletionHandler?(success, error)
//        }
    }
    
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        if let productIdentifier = transaction.original?.payment.productIdentifier {
            if productIdentifier == IAPStore.monthlyPass {
                print("restoreTransaction... \(productIdentifier)")
                provideContentForProductIdentifier(productIdentifier)
            }
            else if productIdentifier == IAPStore.yearlyPass {
                print("restoreTransaction... \(productIdentifier)")
                provideContentForProductIdentifier(productIdentifier)
            }
            else {
                print("restoreTransaction... skipping \(productIdentifier)")
            }
        } else {
            print("restoreTransaction... skipping")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // Helper: Saves the fact that the product has been purchased/restored and posts a notification.
    fileprivate func provideContentForProductIdentifier(_ productIdentifier: String) {
        if !purchasedProductIdentifiers.contains(productIdentifier) {
            purchasedProductIdentifiers.insert(productIdentifier)
            UserDefaults.standard.set(true, forKey: productIdentifier)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: IAPHelperProductPurchasedSuccessNotification, object: productIdentifier)
        }
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        print("failedTransaction...")
        if let originalTransaction = transaction.original {
            let productIdentifier = originalTransaction.payment.productIdentifier
            NotificationCenter.default.post(name: IAPHelperProductPurchasedFailedNotification, object: productIdentifier)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        self.purchaseProductCompletionHandler?(false, transaction.error)
        
        //if transaction.error.code != SKErrorPaymentCancelled {
        //print("Transaction error: \(transaction.error.localizedDescription)")
        //}
    }
}

