//
//  Cache.swift
//  All Ears English
//
//  Created by Luis Artola on 7/16/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class Cache: NSObject {

    static var shared = Cache()
    static let episodeItemDidChangeCachedStateNotification:Notification.Name = Notification.Name(rawValue: "episodeItemDidChangeCachedStateNotification")

    fileprivate var items: [String: URL?] = [:]
    
    var currentlyDownloadingGuids:[String] = []

    override init() {
        
        let imageCache = AutoPurgingImageCache(
            memoryCapacity: 900 * 1024 * 1024,
            preferredMemoryUsageAfterPurge: 600 * 1024 * 1024
        )

        UIImageView.af_sharedImageDownloader = ImageDownloader(
            configuration: ImageDownloader.defaultURLSessionConfiguration(),
            downloadPrioritization: ImageDownloader.DownloadPrioritization.fifo,
            maximumActiveDownloads: 10,
            imageCache:imageCache
        )
        
        do {
            let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let localURL = baseURL?.appendingPathComponent("episodes", isDirectory: true)
            if let url = localURL {
                if !FileManager.default.fileExists(atPath: url.path) {
                    print("Creating directory \(url.path)")
                    try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
                }
            }
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }

    fileprivate func getLocalURL(item:Feed.Item) -> URL? {
        
        guard let guid = item.guid,
            let link = item.link else {
            return nil
        }
        
        let convertedString:NSString = NSString(string: link)
        let pathExtension = item.isVideoContent ? convertedString.pathExtension : "mp3"
        
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var localURL = baseURL?.appendingPathComponent("episodes", isDirectory: true)
        localURL = localURL?.appendingPathComponent("\(guid).\(pathExtension)")
        return localURL
    }
    
    func isCurrentlyDownloadingItem(_ item:Feed.Item?) -> Bool {
        guard let item = item,
        let guid = item.guid else {
            return false
        }
        if self.currentlyDownloadingGuids.contains(guid) {
            return true
        }
        return false
    }

    func get(_ item: Feed.Item?) -> URL? {
        guard let item = item,
              let guid = item.guid else {
            return nil
        }
        if let url = self.items[guid] {
            return url
        }
        let localURL = self.getLocalURL(item:item)
        do {
            let exists = try localURL?.checkResourceIsReachable()
            if exists != nil && exists! {
                self.items[guid] = localURL
                return localURL
            }
        } catch let error as NSError {
            print(error)
        }
        return nil
    }


    func download(_ item: Feed.Item?, callback: @escaping (Feed.Item?) -> Void) {
        guard let item = item,
              let url = item.url,
              let guid = item.guid,
            let localURL = self.getLocalURL(item: item) else {
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url:URL(string: url)!)
        
        self.currentlyDownloadingGuids.append(guid)
        let task = session.downloadTask(with: request) { (tempLocalURL, response, error) in
            
            self.removeGuidFromDownloadingAndNotify(guid: guid)
            
            if let tempLocalURL = tempLocalURL, error == nil {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Downloaded \(url) to \(tempLocalURL) with status \(statusCode)")
                }
                do {
                    try FileManager.default.copyItem(at: tempLocalURL, to: localURL)

                    self.items[guid] = localURL
                    DispatchQueue.main.async {
                        callback(item)
                    }
                }
                catch (let writeError) {
                    DispatchQueue.main.async {
                        callback(nil)
                    }
                    print("Error creating \(localURL): \(writeError)")
                }
            }
            else {
                print("Unexpected error downloading \(url): \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    callback(nil)
                }
            }
        }
        task.resume()
    }
    
    func copyPreloadedEpiosdesToCache() {
        let episodes = Feed.shared.fetchLocalEpisodeItems()
        for episode in episodes {
            if let guid = episode.guid,
                let bundleItemPath = Bundle.main.path(forResource: guid, ofType: "mp3") {
                let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                var localURL = baseURL?.appendingPathComponent("episodes", isDirectory: true)
                localURL = localURL?.appendingPathComponent("\(guid)")
                
                do {
                    let localURL = self.getLocalURL(item: episode)
                    try FileManager.default.copyItem(atPath: bundleItemPath, toPath: localURL!.path)
                }
                catch let error as NSError {
                    print("error copying files")
                    print(error.userInfo)
                }
            }
        }
    }
    
    func delete(item: Feed.Item?, completion: @escaping (Bool) -> Void) {
        guard let item = item,
            let guid = item.guid,
            let localUrl = self.getLocalURL(item: item) else {
                completion(false)
                return
        }
        
        do {
            try FileManager.default.removeItem(at: localUrl)
            completion(true)
        }
        catch (let _) {
            completion(false)
        }
        
        self.items.removeValue(forKey: guid)
    }
    
    func removeGuidFromDownloadingAndNotify(guid:String) {
        if let indexOfGuid = self.currentlyDownloadingGuids.index(of: guid) {
            self.currentlyDownloadingGuids.remove(at: indexOfGuid)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Cache.episodeItemDidChangeCachedStateNotification, object: nil, userInfo: ["guid":guid])
        }
    }

}
