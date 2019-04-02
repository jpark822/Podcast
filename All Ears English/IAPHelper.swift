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
public typealias RestoreProductsCompletionHandler = (_ success:Bool, _ error:Error?) -> ()


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
    fileprivate var restoreProductsCompletionHandler: RestoreProductsCompletionHandler?
    
    
    /// MARK: - API
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
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(self)
        }
    }
    
    //fetch
    func requestProductsWithCompletionHandler(_ handler: @escaping RequestProductsCompletionHandler) {
        if SKPaymentQueue.canMakePayments() {
            requestProductsCompletionHandler = handler
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest?.delegate = self
            productsRequest?.start()
        }
        else {
            self.requestProductsCompletionHandler?(false, [])
        }
    }
    
    //purchase
    func purchaseProduct(_ product: SKProduct, completion: @escaping PurchaseProductsCompletionHandler) {
        print("Buying \(product.productIdentifier)...")
        self.purchaseProductCompletionHandler = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    //restore
    func restoreCompletedTransactions(completion:@escaping RestoreProductsCompletionHandler) {
        if SKPaymentQueue.canMakePayments() {
            self.restoreProductsCompletionHandler = completion
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
        else {
            self.restoreProductsCompletionHandler?(false, NSError(domain: "AEE", code: 998, userInfo: [NSLocalizedDescriptionKey:"inapp purchases not enabled"]))
        }
    }
}

// This extension is used to get a list of products, their titles, descriptions, and prices from ITC
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
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
        print("SK updated downloads")
    }
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("SK removed transactions")
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("completeTransaction...")
        self.storePurchaseAndNotifyForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        ApplicationData.isSubscribedToAEE = true
        self.purchaseProductCompletionHandler?(true, nil)
        //generally you would call a server to upload a receipt here. Instead, we check receipts on login and applaunch
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
    
    //Restoring transactions
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        if let productIdentifier = transaction.original?.payment.productIdentifier {
            if productIdentifier == IAPStore.monthlyPass {
                print("restoreTransaction... \(productIdentifier)")
                self.storePurchaseAndNotifyForProductIdentifier(productIdentifier)
            }
            else if productIdentifier == IAPStore.yearlyPass {
                print("restoreTransaction... \(productIdentifier)")
                self.storePurchaseAndNotifyForProductIdentifier(productIdentifier)
            }
            else {
                print("restoreTransaction... skipping \(productIdentifier)")
            }
        } else {
            print("restoreTransaction... skipping")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("SK transaction restore completed")
        self.restoreProductsCompletionHandler?(true, nil)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("SK transaction restore failed \(error)")
        self.restoreProductsCompletionHandler?(false, error)
    }
    
    
    
    // Helper: Saves the fact that the product has been purchased/restored and posts a notification.
    fileprivate func storePurchaseAndNotifyForProductIdentifier(_ productIdentifier: String) {
        if !purchasedProductIdentifiers.contains(productIdentifier) {
            purchasedProductIdentifiers.insert(productIdentifier)
            UserDefaults.standard.set(true, forKey: productIdentifier)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: IAPHelperProductPurchasedSuccessNotification, object: productIdentifier)
        }
    }
}

