//
//  KeywordFavoritesManager.swift
//  All Ears English
//
//  Created by Jay Park on 4/4/19.
//  Copyright © 2019 All Ears English. All rights reserved.
//

import UIKit

class KeywordFavoritesManager: NSObject {
    enum KeywordFavoritesKey:String {
        case storedKeywords = "AEEStoredKeywordsKey"
    }
    
    static let sharedInstance = KeywordFavoritesManager()
    
    func getStoredKeywords() -> Set<KeywordModel> {
        if let storedKeywordData = UserDefaults.standard.object(forKey: KeywordFavoritesKey.storedKeywords.rawValue) as? Data {
            let decoder = JSONDecoder()
            if let storedKeywords = try? decoder.decode(Set<KeywordModel>.self, from: storedKeywordData) {
                return storedKeywords
            }
        }
        return []
    }
    
    func saveKeyword(_ keyword:KeywordModel) {
        var storedKeywords = self.getStoredKeywords()
        
       storedKeywords.insert(keyword)
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(storedKeywords) {
            UserDefaults.standard.set(encoded, forKey: KeywordFavoritesKey.storedKeywords.rawValue)
        }
        
        print(storedKeywords)
    }

    func removeKeyword(_ keyword:KeywordModel) {
        var storedKeywords = self.getStoredKeywords()
        
        storedKeywords.remove(keyword)
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(storedKeywords) {
            UserDefaults.standard.set(encoded, forKey: KeywordFavoritesKey.storedKeywords.rawValue)
        }
        
        print(storedKeywords)
    }
    
    func containsKeyword(_ keyword:KeywordModel) -> Bool {
        let storedKeywords = self.getStoredKeywords()
        return storedKeywords.contains(keyword) ? true : false
    }
    
}
