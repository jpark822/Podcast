//
//  StoreReviewManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/12/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import StoreKit

//Not in use
class StoreReviewManager: NSObject {
    
    enum StoreReviewManagerKey:String {
        case lastUserRatingActionDates = "AEEStoreReviewLastUserRatingActionDates"
    }
    
    static let sharedInstance = StoreReviewManager()
    
    func displayReviewController(fromViewController: UIViewController) {
        
        //if theyve attempted more than three times, auto push to appstore
        if StoreReviewManager.userAttemptedRatingOverThreeInstances == true {
            if let url = URL(string: "https://itunes.apple.com/us/app/all-ears-english-listening/id1260196995?ls=1&mt=8") {
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                })
            }
            print("over three times")
            return
        }
        
//        let alertController = UIAlertController(title: "Do you love All Ears English? Please rate us now!", message: "", preferredStyle: .alert)
        
//        let confirmAction = UIAlertAction(title: "Yes, I will rate the app", style: UIAlertActionStyle.default, handler: { (alertAction) in
            if #available( iOS 10.3,*){
                SKStoreReviewController.requestReview()
            }
            else if let url = URL(string: "https://itunes.apple.com/us/app/all-ears-english-listening/id1260196995?ls=1&mt=8") {
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                })
            }
            ApplicationData.userCompletedRating = true
//        })
        
//        let remindMeLaterAction = UIAlertAction(title: "Remind me later", style: UIAlertActionStyle.cancel, handler: { (alertAction) in
//        })
//
//        let cancelAction = UIAlertAction(title: "No Thanks", style: UIAlertActionStyle.destructive, handler: { (alertAction) in
//
//        })
//
//        alertController.addAction(confirmAction)
//        alertController.addAction(remindMeLaterAction)
//        alertController.addAction(cancelAction)
//
//        fromViewController.present(alertController, animated: true, completion: {
//        })
        
        StoreReviewManager.storeRateAttempt()
    }
    
    private static func storeRateAttempt() {
        var storedAttempts = StoreReviewManager.storedAttempts
        storedAttempts.insert(Date(), at: 0)
        while storedAttempts.count > 3 {
            storedAttempts.removeLast(1)
        }
        UserDefaults.standard.set(storedAttempts, forKey: StoreReviewManagerKey.lastUserRatingActionDates.rawValue)
        
        print(storedAttempts)
    }
    
    static var storedAttempts:[Date] {
        return UserDefaults.standard.array(forKey: StoreReviewManagerKey.lastUserRatingActionDates.rawValue) as? [Date] ?? [Date]()
    }
    
    static var userAttemptedRatingOverThreeInstances:Bool {
        
        if self.storedAttempts.count < 3 {
            return false
        }
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        guard let yearComponent = dateComponents.year else {
            return false
        }
        dateComponents.year = yearComponent - 1
        guard let oneYearAgoDate = Calendar.current.date(from: dateComponents) else {
            return false
        }
        
        for date in storedAttempts {
            //if any date in the array is over a year old, then we know we have attempts left
            if date < oneYearAgoDate {
                return false
            }
        }
        
        return true
    }
}
