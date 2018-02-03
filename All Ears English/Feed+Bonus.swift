//
//  Feed+Bonus.swift
//  All Ears English
//
//  Created by Jay Park on 10/14/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//
import Alamofire
import Foundation
import SwiftyXMLParser
import Crashlytics
//import BugfenderSDK

extension Feed {
    func fetchBonusFeed(completion:(([Feed.Item]?)->Void)?) {
        self.bonusItems.removeAll()
        Alamofire.request(bonusURL).responseData { response in
            let statusCode = response.response?.statusCode ?? 0
            
            if let error = response.error {
//                BFLog("Bonus Error:%@ Status code:%i", error.localizedDescription, statusCode)
                
                if let completion = completion {
                    completion(nil)
                }
            }
            else if let data = response.data {
                let xml = XML.parse(data)
                let channel = xml["rss", "channel"]
                
                var feedItems:[Item] = [Item]()
                for xmlItem in channel["item"] {
                    let newItem = Item(xmlItem, episodeType:.bonus)
                    feedItems.append(newItem)
                }
                
                self.bonusItems = feedItems
                if let completion = completion {
                    completion(feedItems)
                }
            }
            else {
//                BFLog("Bonus parsing error")
                print("FEED: unable to parse RSS feed")
                let userInfo: [String: String] = [
                    NSLocalizedDescriptionKey: "Unable to read RSS feed",
                    NSLocalizedFailureReasonErrorKey: "RSS feed URL returned nothing"
                ]
                let error = NSError(domain: "AEEReadRSSFeedError", code: -1001, userInfo: userInfo)
                Crashlytics.sharedInstance().recordError(error)
                if let completion = completion {
                    completion(nil)
                }
            }
        }
    }
}
