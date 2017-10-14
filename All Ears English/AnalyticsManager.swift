//
//  AnalyticsManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/14/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Crashlytics
import Firebase

class AnalyticsManager: NSObject {
    static let sharedInstance = AnalyticsManager()
    
    func logEpisodeShare(method:String, contentName:String, contentType:String, episodeId:String, attributes:[String:Any]?) {
        Answers.logShare(withMethod: method, contentName: contentName, contentType: contentType, contentId: episodeId, customAttributes: attributes)
        
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterMedium: method as NSObject,
            AnalyticsParameterItemName: contentName as NSObject,
            AnalyticsParameterItemCategory: contentType as NSObject,
            AnalyticsParameterItemID: episodeId as NSObject
            ])
    }
    
    func logEpisodeView(episodeName:String, contentType:String, episodeId:String) {
        Answers.logContentView(withName: episodeName, contentType: contentType, contentId: episodeId)
        
        Analytics.logEvent(
            AnalyticsEventViewItem,
            parameters: [
                AnalyticsParameterItemName: episodeName as NSObject,
                AnalyticsParameterItemCategory: contentType as NSObject,
                AnalyticsParameterItemID: episodeId as NSObject
            ])
    }
}
