//
//  Feed+Metadata.swift
//  All Ears English
//
//  Created by Jay Park on 5/5/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation
import Alamofire

extension Feed {
    
    func getFeedMetadataAndPopulateFeed() {
        guard let metadataUrl = URL(string: "https://s3.amazonaws.com/allearsenglish-mobileapp/Episode+Metadata.json") else {
                return
        }
        
        Alamofire.request(metadataUrl).responseJSON { (response) in
            guard let responseJSON = response.result.value as? [String:Any],
                let itemsArray = responseJSON["Items"] as? [[String:Any]] else {
                return
            }
            
            for itemDict in itemsArray {
                if let guid = itemDict["guid"] as? String,
                    let keywordString = itemDict["keywords"] as? String,
                    let categoryString = itemDict["categories"] as? String {
                    
                    var matchingItem:Feed.Item?
                    
                    matchingItem = self.items.filter({ (item) -> Bool in
                        item.guid == guid
                    }).first
                    
                    if matchingItem == nil {
                        matchingItem = self.bonusItems.filter({ (item) -> Bool in
                            item.guid == guid
                        }).first
                    }
                    
                    if let foundItem = matchingItem {
                        foundItem.keywordString = keywordString
                        foundItem.categoriesString = categoryString
                    }
                }
            }
        }
        
    }
}
