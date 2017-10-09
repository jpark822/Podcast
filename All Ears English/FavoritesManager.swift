//
//  FavoritesManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/9/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class FavoritesManager: NSObject {
    enum FavoritesManagerKey:String {
        case storedFavorites = "AEEStoredFavoritesKey"
    }
    
    static let sharedInstance = FavoritesManager()
    
    var allStoredFavorites:[Feed.Item] {
        get {
            let allFavoriteDictionaries = self.allFavoritesAsDictionaries
            return FavoritesManager.convertStoredDictionariesToFeedItems(dicts: allFavoriteDictionaries)
        }
        set {
            let convertedFavorites = FavoritesManager.convertFeedItemArrayToDictionaryArray(newValue)
            UserDefaults.standard.set(convertedFavorites, forKey: FavoritesManagerKey.storedFavorites.rawValue)
        }
    }
    
    fileprivate var allFavoritesAsDictionaries:[[String:String]] {
        get {
            guard let allFavorites = UserDefaults.standard.object(forKey: FavoritesManagerKey.storedFavorites.rawValue) as? [[String:String]] else {
                return []
            }
            return allFavorites
        }
    }
    
    static func isItemInFavorites(item:Feed.Item) -> Bool {
        let allFavorites = FavoritesManager.sharedInstance.allStoredFavorites
        for storedFavoriteItem in allFavorites {
            if item.guid == storedFavoriteItem.guid {
                return true
            }
        }
        return false
    }
    
    func addFavorite(_ item:Feed.Item) {
        guard FavoritesManager.isItemInFavorites(item: item) == false else {
            return
        }
        
        var allFavorites = self.allStoredFavorites
        allFavorites.append(item)
        self.allStoredFavorites = allFavorites
    }
    
    func removeFavorite(_ item:Feed.Item) {
        guard FavoritesManager.isItemInFavorites(item: item) == true else {
            return
        }
        
        var newFavorites:[Feed.Item] = []
        for storedItem in self.allStoredFavorites {
            if item.guid != storedItem.guid {
                newFavorites.append(storedItem)
            }
        }
        
        self.allStoredFavorites = newFavorites
    }
}

//MARK: Archiving / Unarchiving helpers
fileprivate extension FavoritesManager {
    enum FeedItemKey:String {
        case number = "number"
        case title = "title"
        case link = "link"
        case comments = "comments"
        case pubDate = "pubDate"
        case creator = "creator"
        case guid = "guid"
        case description = "description"
        case url = "url"
        case subtitle = "subtitle"
        case summary = "summary"
        case author = "author"
        case duration = "duration"
    }
    
    static func convertStoredDictionariesToFeedItems(dicts:[[String:String]]) -> [Feed.Item] {
        var feedItems:[Feed.Item] = []
        for dict in dicts {
            feedItems.append(Feed.Item(dict))
        }
        return feedItems
    }
    
    static func convertFeedItemToDictionary(item:Feed.Item) -> [String:String] {
        var dict = [String:String]()
        if let number = item.number {
            dict[FeedItemKey.number.rawValue] = number
        }
        if let title = item.title {
            dict[FeedItemKey.title.rawValue] = title
        }
        if let link = item.link {
            dict[FeedItemKey.link.rawValue] = link
        }
        if let comments = item.comments {
            dict[FeedItemKey.comments.rawValue] = comments
        }
        if let pubdate = item.pubDate {
            dict[FeedItemKey.pubDate.rawValue] = pubdate
        }
        if let creator = item.creator {
            dict[FeedItemKey.creator.rawValue] = creator
        }
        if let guid = item.guid {
            dict[FeedItemKey.guid.rawValue] = guid
        }
        if let description = item.description {
            dict[FeedItemKey.description.rawValue] = description
        }
        if let url = item.url {
            dict[FeedItemKey.url.rawValue] = url
        }
        if let subtitle = item.subtitle {
            dict[FeedItemKey.subtitle.rawValue] = subtitle
        }
        if let summary = item.summary {
            dict[FeedItemKey.summary.rawValue] = summary
        }
        if let author = item.author {
            dict[FeedItemKey.author.rawValue] = author
        }
        if let duration = item.duration {
            dict[FeedItemKey.duration.rawValue] = duration
        }
        
        return dict
    }
    
    static func convertFeedItemArrayToDictionaryArray(_ items:[Feed.Item]) -> [[String:String]] {
        var feedItemDicts:[[String:String]] = [[:]]
        for item in items {
            let itemDict = FavoritesManager.convertFeedItemToDictionary(item: item)
            feedItemDicts.append(itemDict)
        }
        return feedItemDicts
    }
}
