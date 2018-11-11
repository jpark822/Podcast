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
        guard let receipt = self.getReceiptData() else {
            completion(false, nil)
            return
        }
        
        Functions.functions().httpsCallable("validate").call(["receipt": receipt]) { (result, error) in
            if let error = error as NSError? {
                completion(false, error)
                return
            }
            
            guard let responseDict = result?.data as? [String:Any] else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            guard let allReceiptDict = responseDict["receipt"] as? [String:Any] else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            
            guard let inAppArray = allReceiptDict["in_app"] as? [[String:Any]] else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            
            guard let latestReceiptDict = inAppArray.first else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            guard let expirationDateMillisecondString = latestReceiptDict["expires_date_ms"] as? String else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            guard let expirationDateMilliseconds = Double(expirationDateMillisecondString) else {
                completion(false, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"Parsing error"]))
                return
            }
            
            let expirationDate = Date(timeIntervalSince1970: expirationDateMilliseconds / 1000.0)
            
            let dateformatter = DateFormatter()
            dateformatter.timeZone = NSTimeZone.system
            dateformatter.dateStyle = .long
            
            let datestring = dateformatter.string(from: expirationDate)
            
            let isValid = expirationDate > Date() ? true : false
            
            ApplicationData.isSubscribedToAEE = isValid
            completion(isValid, nil)
        }
    }
}
