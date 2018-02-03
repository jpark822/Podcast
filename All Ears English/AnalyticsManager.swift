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
    enum KochavaCustomEvent:String {
        case letsGoPressed = "let's go action"
        case getInstantAccess = "get instant access action"
        case shareAppAction = "share app action"
        case rateAction = "rate and review action"
    }
    
    enum KochavaEpisodeEvent:String {
        case episodeListen = "episode play"
        case bonusEpisodeListen = "bonus episode play"
        case downloadEpisode = "episode download"
        case downloadBonusEpisode = "bonus episode download"
        case favoriteEpisode = "episode favorited"
    }
    
    enum KochavaPageView:String {
        case rating = "rate page visit"
        case share = "share page visit"
    }
    
    
    static let sharedInstance = AnalyticsManager()
    
    
    //kochava
    func logKochavaEpisodeEvent(_ event:KochavaEpisodeEvent, item:Feed.Item?) {
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
            properties["type"] = "bonus"
        }
        if let guid = item.guid {
            properties["guid"] = guid
        }
        
        KochavaTracker.shared.sendEvent(withNameString: event.rawValue, infoDictionary: properties)
    }
    
    func logKochavaCustomEvent(_ event:KochavaCustomEvent, properties:[AnyHashable:Any]?) {
        KochavaTracker.shared.sendEvent(withNameString: event.rawValue, infoDictionary: properties)
    }
    
    func logKochavaPageView(_ event:KochavaPageView, properties:[AnyHashable:Any]?) {
        if let kochavaEvent = KochavaEvent(eventTypeEnum: .view) {
            kochavaEvent.nameString = event.rawValue
            KochavaTracker.shared.send(kochavaEvent)
        }
    }
    

    //mixpanel
    func logMixpanelEpisodeEvent(_ name:String, item:Feed.Item?) {
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
    
    func logMixpanelPageVisit(_ name:String) {
        Mixpanel.sharedInstance()?.track(name, properties: nil)
    }
    
    func logMixpanelShareBegin() {
        Mixpanel.sharedInstance()?.track("Share Initiated", properties: nil)
    }
    
    func logMixpanelShareSuccess() {
        Mixpanel.sharedInstance()?.track("Share Completed", properties: nil)
    }
}
