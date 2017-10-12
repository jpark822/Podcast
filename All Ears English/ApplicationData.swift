//
//  ApplicationData.swift
//  All Ears English
//
//  Created by Jay Park on 10/2/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

class ApplicationData: NSObject {
    
    enum ApplicationDataKey:String {
        case autoplay = "AEEAppDataAutoPlayEnabled"
    }
    
    static let sharedInstance = ApplicationData()
    
    override init() {
        super.init()
    }
    
    static func setAppData(value:Any?, key:ApplicationDataKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
    
    static func getAppData(key:ApplicationDataKey) -> Any?{
        return UserDefaults.standard.value(forKey: key.rawValue)
    }
    
    //MARK: Autoplay
    static var isAutoPlayEnabled:Bool {
        get {
            if let isAutoplayEnabled = self.getAppData(key: .autoplay) {
                return isAutoplayEnabled as! Bool
            }
            return true
        }
        set {
            self.setAppData(value: newValue, key: .autoplay)
        }
    }
}
