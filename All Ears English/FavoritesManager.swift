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
    static let favoritesManagerDidUnfavoriteItemNotification:Notification.Name = Notification.Name(rawValue: "favoritesManagerDidUnfavoriteItemNotification")
    
    func getAllStoredFavorites() -> [Feed.Item] {
        let allFavoriteDictionaries = self.allFavoritesAsDictionaries
        return FavoritesManager.convertStoredDictionariesToFeedItems(dicts: allFavoriteDictionaries)
    }
    
    func setStoredFavorites(favorites:[Feed.Item]) {
        let convertedFavorites = FavoritesManager.convertFeedItemArrayToDictionaryArray(favorites)
        UserDefaults.standard.set(convertedFavorites, forKey: FavoritesManagerKey.storedFavorites.rawValue)
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
        let allFavorites = FavoritesManager.sharedInstance.getAllStoredFavorites()
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
        
        var allFavorites = self.getAllStoredFavorites()
        allFavorites.append(item)
        self.setStoredFavorites(favorites: allFavorites)
        
        AnalyticsManager.sharedInstance.logKochavaEpisodeEvent(.favoriteEpisode, item: item)
    }
    
    func removeFavorite(_ item:Feed.Item) {
        guard FavoritesManager.isItemInFavorites(item: item) == true else {
            return
        }
        
        //safeguard against the current track being the last favorite item
        if AudioPlayer.sharedInstance.currentlyPlayingFeedType == .favorites && AudioPlayer.sharedInstance.currentItem?.guid == item.guid {
            let isCurrentlyPlaying = AudioPlayer.sharedInstance.isPlaying
            
            if AudioPlayer.sharedInstance.seekToNextTrack() == nil {
                AudioPlayer.sharedInstance.clearPlayerItems()
            }
            else {
                if isCurrentlyPlaying == false {
                    AudioPlayer.sharedInstance.pause()
                }
            }
        }
        
        //now build new favorites list
        var newFavorites:[Feed.Item] = []
        for storedItem in self.getAllStoredFavorites() {
            if item.guid != storedItem.guid {
                newFavorites.append(storedItem)
            }
        }
        
        self.setStoredFavorites(favorites: newFavorites)
        
        if let guid = item.guid {
            NotificationCenter.default.post(name: FavoritesManager.favoritesManagerDidUnfavoriteItemNotification, object: nil, userInfo: ["guid":guid])
        }
    }
}

//MARK: Archiving / Unarchiving helpers. TODO: move into Feed.Item
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
        case type = "type"
        case episodeType = "episodeType"
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
        if let type = item.type {
            dict[FeedItemKey.type.rawValue] = type
        }
        dict[FeedItemKey.episodeType.rawValue] = item.episodeType.rawValue
        
        return dict
    }
    
    static func convertFeedItemArrayToDictionaryArray(_ items:[Feed.Item]) -> [[String:String]] {
        var feedItemDicts:[[String:String]] = []
        for item in items {
            let itemDict = FavoritesManager.convertFeedItemToDictionary(item: item)
            feedItemDicts.append(itemDict)
        }
        return feedItemDicts
    }
}
