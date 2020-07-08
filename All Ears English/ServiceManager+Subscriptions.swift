//
//  ServiceManager+Subscriptions.swift
//  All Ears English
//
//  Created by Jay Park on 11/10/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFunctions
import StoreKit

extension ServiceManager {
    func getReceiptData() -> String? {
        if let receiptUrl = Bundle.main.appStoreReceiptURL {
            let receipt = try? Data(contentsOf: receiptUrl)
            
            if let unwrappedReceipt = receipt {
                let receiptdata: NSString = unwrappedReceipt.base64EncodedString(options:NSData.Base64EncodingOptions(rawValue: 0)) as NSString
                return receiptdata as String
            }
        }
        return nil
    }
    
    func checkForValidSubscription(completion: @escaping (Bool, Error?)->Void) {
        self.validSubCompletionBlock = completion
        
        let refreshReq = SKReceiptRefreshRequest()
        refreshReq.delegate = self
        refreshReq.start()
    }
}

extension ServiceManager:SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        guard let receipt = self.getReceiptData() else {
            if let completion = self.validSubCompletionBlock {
                completion(false, nil)
                self.validSubCompletionBlock = nil
            }
            return
        }
        
        let body:[String:Any] = [
                "receipt":receipt
        ]
        #if DEBUG
        let functionName = "validateNodejs10Sandbox"
        #else
        let functionName = "validateNodejs10"
        #endif
        
        print("calling \(functionName)")
        Functions.functions().httpsCallable(functionName).call(body) { (result, error) in
            if let error = error as NSError? {
                if let completion = self.validSubCompletionBlock {
                    completion(false, error)
                    self.validSubCompletionBlock = nil
                }
                return
            }
            
            guard let responseDict = result?.data as? [String:Any],
                let receiptInfoArray = responseDict["latest_receipt_info"] as? [[String:Any]],
                let latestReceiptDict = receiptInfoArray.last,
                let expirationDateMillisecondString = latestReceiptDict["expires_date_ms"] as? String,
                let expirationDateMilliseconds = Double(expirationDateMillisecondString) else {
                if let completion = self.validSubCompletionBlock {
                    completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                    self.validSubCompletionBlock = nil
                }
                return
            }
            
            let expirationDate = Date(timeIntervalSince1970: expirationDateMilliseconds / 1000.0)
            
            let isValid = expirationDate > Date() ? true : false
            
            ApplicationData.isSubscribedToAEE = isValid
            if let completion = self.validSubCompletionBlock {
                completion(isValid, nil)
                self.validSubCompletionBlock = nil
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if let completion = self.validSubCompletionBlock {
            completion(false, error)
            self.validSubCompletionBlock = nil
        }
        print("request failed")
    }
}
