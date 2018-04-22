//
//  Feed.swift
//  All Ears English
//
//  Created by Luis Artola on 6/21/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Crashlytics
import Alamofire
import SwiftyXMLParser
import Foundation
//import BugfenderSDK

class Feed: NSObject {

    static let shared = Feed()

    fileprivate let baseURL = URL.init(string: "https://allearsenglish.libsyn.com/App")!
    internal let bonusURL = URL.init(string:"https://appforaee.libsyn.com/rss")!
    fileprivate var parser: XMLParser?
//    fileprivate var itemBuilder: ItemBuilder!

    var items = [Item]()
    var itemsByGUID: [String: Feed.Item] = [:]
    
    var bonusItems = [Item]()

    func fetchData(completion:(([Feed.Item]?)->Void)?) {
        self.items.removeAll()
        Alamofire.request(baseURL).responseData { response in
            let statusCode = response.response?.statusCode ?? 0
            
            if let error = response.error {
//                BFLog("Feed Error:%@ Status code:%i", error.localizedDescription, statusCode)
                
                if let completion = completion {
                    completion(nil)
                }
            }
            else if let data = response.data {
                let xml = XML.parse(data)
                let channel = xml["rss", "channel"]
                
                var feedItems:[Item] = [Item]()
                for xmlItem in channel["item"] {
                    let newItem = Item(xmlItem, episodeType: .episode)
                    //brute parsing for build 38
//                    if newItem.isAfterNewCutoff {
                        feedItems.append(newItem)
//                    }
                }
                
                self.items = feedItems
                if let completion = completion {
                    completion(feedItems)
                }
            }
            else {
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

    func fetchLocalEpisodeItems() -> [Feed.Item] {
        var items:[Feed.Item] = []
        
        let path = Bundle.main.path(forResource: "localEpisodeFeed", ofType: "xml")
        
        do {
            let xmlString = try String(contentsOfFile: path!)
            
            let xml = try XML.parse(xmlString)
            
            let channel = xml["rss", "channel"]
            for xmlItem in channel["item"] {
                let newItem = Item(xmlItem, episodeType: .episode)
                items.append(newItem)
            }
            return items
        }
        catch {
            return []
        }
    }



//MARK: TODO last contractor made a mess of this model. its completely backwards and the inits are anti-pattern
    class Item {
        enum EpisodeType:String {
            case episode = "episode"
            case bonus = "bonus"
        }
        
        var episodeType:EpisodeType = .episode
        
        var number: String?
        var title: String? {
            didSet {
                self.parseTitle()
            }
        }
        var link: String?
        var comments: String?
        var pubDate: String? {
            didSet {
                self.parseDetails()
            }
        }
        var creator: String?
        var category: [String?]?
        var guid: String? {
            didSet {
                self.parseId()
            }
        }
        //type is video or audio. refactor to use an enum
        var type:String?
        var description: String?
        var url: String?
        var subtitle: String?
        var summary: String?
        var author: String?
        var duration: String? {
            didSet {
                self.parseDetails()
            }
        }
        var keywordString:String? {
            didSet {
                self.parseKeywords()
            }
        }
        var keywords = [String]()
        
        // computed for display or internal use
        var isVideoContent: Bool {
            get {
                if let type = self.type {
                    if type.lowercased().range(of:"video") != nil {
                        return true
                    }
                    return false
                }
                return false
            }
        }
        var displayTitle: String?
        var displayDetails: String?
        var published: Date?
        var identifier: String?

        //Deprecated. Still having issues with international users
        var isAfterOldCutoff: Bool {
            var components = DateComponents()
            components.year = 2014
            components.month = 11
            components.day = 19
            components.timeZone = TimeZone(abbreviation: "UTC")
            if let cutoffDate = Calendar.current.date(from: components),
               let date = self.published {
                if date.timeIntervalSince(cutoffDate) >= 0 {
                    return true
                }
                else {
                    if let number = self.number {
                        switch number {
                            case "218", "219", "220":
                                return true
                            default:
                                return false
                        }
                    }
                }
            }
            return false
        }
        
        //Deprecated. Still having issues with international users
        var isAfterNewCutoff: Bool {
            var components = DateComponents()
            components.year = 2014
            components.month = 11
            components.day = 19
            let calendar = Calendar(identifier: .gregorian)
            components.timeZone = TimeZone(abbreviation: "UTC")
            if let cutoffDate = calendar.date(from: components),
                let date = self.published {
                if date > cutoffDate {
                    return true
                }
                else {
                    if let number = self.number {
                        switch number {
                        case "218", "219", "220":
                            return true
                        default:
                            return false
                        }
                    }
                }
            } 
            return false
        }

        init(_ attributes: [String: String]) {
            title = attributes["title"]
            link = attributes["link"]
            comments = attributes["comments"]
            pubDate = attributes["pubDate"]
            creator = attributes["creator"]
            category = [attributes["category"]]
            guid = attributes["guid"]
            description = attributes["description"]
            url = attributes["url"]
            subtitle = attributes["subtitle"]
            summary = attributes["summary"]
            author = attributes["author"]
            duration = attributes["duration"]
            type = attributes["type"]
            keywordString = attributes["keywords"]

            if let episodeTypeRawString = attributes["episodeType"],
                let convertedEpisodeType = Feed.Item.EpisodeType(rawValue: episodeTypeRawString) {
                self.episodeType = convertedEpisodeType
            }
            self.parseTitle()
            self.parseDetails()
            self.parseId()
            self.parseKeywords()
        }
        
        convenience init(_ xmlItem: XML.Accessor, episodeType:EpisodeType) {
            var attributes: [String: String] = Dictionary()
            let elementNames: [String: String] = [
                "title": "title",
                "link": "link",
                "pubDate": "pubDate",
                "guid": "guid",
                "description": "description",
                "itunes:subtitle": "subtitle",
                "itunes:duration": "duration",
                "itunes:keywords": "keywords"
            ]
            
            for (elementName, attributeName) in elementNames {
                //            print("FEED: Looking up \(elementName)")
                let element = xmlItem[elementName]
                if let text = element.text {
                    //                print("FEED: \(attributeName) = \(text)")
                    attributes[attributeName] = text
                }
                else {
                    //                print("FEED: \(attributeName) = UNDEFINED!!!")
                }
            }
            let enclosure = xmlItem["enclosure"]
            if let url = enclosure.attributes["url"] {
                //            print("FEED: url = \(url)")
                attributes["url"] = url
            }
            if let type = enclosure.attributes["type"] {
                attributes["type"] = type
            }
            else {
                //            print("FEED: url = UNDEFINED!!!")
            }
            self.init(attributes)
        }

        func parseTitle() {
            if let text = self.title {
                let pattern = "AEE\\s+(\\w+):\\s*(.*)"
                let regex = try! NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: text, range: NSMakeRange(0, text.utf16.count))
                let results = matches.map { match -> [String] in
                    var groups = [String]()
                    for index in 0..<match.numberOfRanges {
                        let range = match.rangeAt(index)
                        let start = String.UTF16Index(range.location)
                        let end = String.UTF16Index(range.location + range.length)
                        let group = String(text.utf16[start..<end])!
                        groups.append(group)
                    }
                    return groups
                }
                if results.count > 0 {
                    let groups = results[0]
                    self.number = groups[1]
                    self.displayTitle = groups[2]
                } else {
                    self.number = ""
                    self.displayTitle = self.title
                }
            } else {
                self.number = ""
                self.displayTitle = ""
            }
        }

        func parseDetails() {
            let calendar = Calendar(identifier: .gregorian)
            let currentYear = calendar.component(.year, from: Date())
            if let pubDate = self.pubDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
                self.published = formatter.date(from: pubDate)
                formatter.dateFormat = "MMM d"
                if let date = self.published {
                    let publishedYear = calendar.component(.year, from: date)
                    if publishedYear < currentYear {
                        formatter.dateFormat = "MMM d, yyyy"
                    }
                }
                if let date = self.published {
                    let shortPubDate = formatter.string(from: date)
                    self.displayDetails = shortPubDate
                    if let duration = self.duration {
                        self.displayDetails = "\(shortPubDate) • \(duration)"
                    }
                } else {
                    CLSLogv("Unable to parse pubDate: %@", getVaList([pubDate]))
                    if let duration = self.duration {
                        self.displayDetails = "\(duration)"
                    }
                }
            } else {
                if let duration = self.duration {
                    self.displayDetails = "\(duration)"
                }
            }
        }

        func parseId() {
            if let text = self.guid {
                let pattern = ".*\\?p=(.*)"
                let regex = try! NSRegularExpression(pattern: pattern)
                let matches = regex.matches(in: text, range: NSMakeRange(0, text.utf16.count))
                let results = matches.map { match -> [String] in
                    var groups = [String]()
                    for index in 0..<match.numberOfRanges {
                        let range = match.rangeAt(index)
                        let start = String.UTF16Index(range.location)
                        let end = String.UTF16Index(range.location + range.length)
                        let group = String(text.utf16[start..<end])!
                        groups.append(group)
                    }
                    return groups
                }
                if results.count > 0 {
                    let groups = results[0]
                    self.identifier = groups[1]
                } else {
                    self.identifier = self.guid
                }
            } else {
                self.identifier = ""
            }
        }
        
        func parseKeywords() {
            guard let keywordString = self.keywordString else {return}
            self.keywords = keywordString.components(separatedBy: [","])
        }
    }

}
