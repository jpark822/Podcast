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
import Mixpanel

class AnalyticsManager: NSObject {
    static let sharedInstance = AnalyticsManager()
    
    func logEpisodeEvent(_ name:String, item:Feed.Item?) {
        guard let item = item else {
            return
        }
        
        var properties:[AnyHashable : Any] = [:]
        if let number = item.number {
            properties["number"] = number
            properties["type"] = "episode"
        }
        else {
            properties["number"] = ""
            properties["type"] = "Bonus"
        }
        if let guid = item.guid {
            properties["guid"] = guid
        }
        
        Mixpanel.sharedInstance()?.track(name, properties: properties)
    }
    
    func logPageVisit(_ name:String) {
        Mixpanel.sharedInstance()?.track(name, properties: nil)
    }
    
    func logShareBegin() {
        Mixpanel.sharedInstance()?.track("Share Initiated", properties: nil)
    }
    
    func logShareSuccess() {
        Mixpanel.sharedInstance()?.track("Share Completed", properties: nil)
    }
}
