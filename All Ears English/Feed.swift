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
                    let newItem = Item(xmlItem)
                    //brute parsing for build 38
//                    if newItem.isAfterNewCutoff {
                        feedItems.append(newItem)
//                    }
                }
                
                //logging bug
                
                //new parsing
//                var fakeFeedItems:[Item] = [Item]()
//                for xmlItem in channel["item"] {
//                    let anotherNewItem = Item(xmlItem)
//                    if anotherNewItem.isAfterNewCutoff {
//                        fakeFeedItems.append(anotherNewItem)
//                    }
//                }
//
//                //old parsing
//                var moreFakeFeedItems:[Item] = [Item]()
//                for xmlItem in channel["item"] {
//                    let moreAnotherNewItem = Item(xmlItem)
//                    if moreAnotherNewItem.isAfterOldCutoff {
//                        moreFakeFeedItems.append(moreAnotherNewItem)
//                    }
//                }
//
//                if (moreFakeFeedItems.count < 500) {
//                    BFLog("Count Discrepancy found. old parsing: %i items. New Parsing: %i. Brute Parsing %i", moreFakeFeedItems.count, fakeFeedItems.count, feedItems.count)
//                }
                //end logging bug
                
                
                self.items = feedItems
                if let completion = completion {
                    completion(feedItems)
                }
            }
            else {
//                BFLog("Feed parsing error")
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
                let newItem = Item(xmlItem)
                items.append(newItem)
            }
            return items
        }
        catch {
            return []
        }
    }



//MARK: Item implementation
    class Item {
        
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
            self.parseTitle()
            self.parseDetails()
            self.parseId()
        }
        
        convenience init(_ xmlItem: XML.Accessor) {
            var attributes: [String: String] = Dictionary()
            let elementNames: [String: String] = [
                "title": "title",
                "link": "link",
                "pubDate": "pubDate",
                "guid": "guid",
                "description": "description",
                "itunes:subtitle": "subtitle",
                "itunes:duration": "duration"
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
    }

}


//class ItemBuilder: NSObject, XMLParserDelegate {
//    
//    fileprivate var feed: Feed
//    fileprivate var parsingItem = false
//    fileprivate var attributes: [String: String] = Dictionary()
//    fileprivate var elementName: String?
//    fileprivate var elementValue: String = ""
//    fileprivate let targetAttributes: [String: String] = [
//        "title": "title",
//        "link": "link",
//        "comments": "comments",
//        "pubDate": "pubDate",
//        "dc:creator": "creator",
//        "category": "category",
//        "guid": "guid",
//        "description": "description",
//        "url": "url",
//        "itunes:subtitle": "subtitle",
//        "itunes:summary": "summary",
//        "itunes:author": "author",
//        "itunes:duration": "duration"
//    ]
//    
//    init(_ feed: Feed) {
//        self.feed = feed
//    }
//    
//    func parserDidStartDocument(_ parser: XMLParser) {
//        //print("FEED: Start document")
//    }
//    
//    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
//        if !self.parsingItem {
//            if name == "item" {
//                //print("FEED: Start \(name) \(qualifiedName ?? name)")
//                self.parsingItem = true
//            }
//        } else if name == "enclosure" {
//            if let url = attributes["url"] {
//                self.attributes["url"] = url
//            }
//            self.elementName = nil
//            self.elementValue = ""
//        } else if self.targetAttributes.keys.contains(name) {
//            self.elementName = name
//            self.elementValue = ""
//        }
//    }
//    
//    func parser(_ parser: XMLParser, foundCharacters text: String) {
//        if self.parsingItem {
//            self.elementValue += text
//        }
//    }
//    
//    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
//        if parsingItem {
//            if name == "item" {
//                //print("FEED: End \(name) \(qualifiedName ?? name)")
//                //print("\nitem")
//                //for (key, value) in self.attributes {
//                //    print("\(key) = \(value)")
//                //}
//                let item = Item(attributes)
//                if item.isAfterCutoff {
//                    self.feed.items.append(item)
//                }
//                self.parsingItem = false
//                self.elementName = nil
//                self.elementValue = ""
//                self.attributes = [:]
//            } else if self.elementName == name, let attributeName = self.targetAttributes[name] {
//                self.attributes[attributeName] = self.elementValue
//                self.elementName = nil
//                self.elementValue = ""
//            }
//        }
//    }
//    
//    func parserDidEndDocument(_ parser: XMLParser) {
//        //print("FEED: End document")
//        self.feed.itemsByGUID.removeAll()
//        for item in self.feed.items {
//            //print("\(item.guid ?? "") - \(item.title ?? "")")
//            if let guid = item.guid {
//                self.feed.itemsByGUID[guid] = item
//            }
//        }
//    }
//    
//}
//
//
//func buildItem(_ xmlItem: XML.Accessor) -> Feed.Item? {
//    var attributes: [String: String] = Dictionary()
//    let elementNames: [String: String] = [
//        "title": "title",
//        "link": "link",
//        "pubDate": "pubDate",
//        "guid": "guid",
//        "description": "description",
//        "itunes:subtitle": "subtitle",
//        "itunes:duration": "duration"
//    ]
//    
//    for (elementName, attributeName) in elementNames {
//        //            print("FEED: Looking up \(elementName)")
//        let element = xmlItem[elementName]
//        if let text = element.text {
//            //                print("FEED: \(attributeName) = \(text)")
//            attributes[attributeName] = text
//        }
//        else {
//            //                print("FEED: \(attributeName) = UNDEFINED!!!")
//        }
//    }
//    let enclosure = xmlItem["enclosure"]
//    if let url = enclosure.attributes["url"] {
//        //            print("FEED: url = \(url)")
//        attributes["url"] = url
//    }
//    if let type = enclosure.attributes["type"] {
//        attributes["type"] = type
//    }
//    else {
//        //            print("FEED: url = UNDEFINED!!!")
//    }
//    let item = Item(attributes)
//    if item.isAfterCutoff {
//        return item
//    }
//    else {
//        return nil
//    }
//}
