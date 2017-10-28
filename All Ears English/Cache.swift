//
//  Cache.swift
//  All Ears English
//
//  Created by Luis Artola on 7/16/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class Cache: NSObject {

    static var shared = Cache()
    static let episodeDidFinishDownloadingNotification:Notification.Name = Notification.Name(rawValue: "episodeDidFinishDownloadingNotification")

    fileprivate var items: [String: URL?] = [:]
    
    var currentlyDownloadingGuids:[String] = []

    override init() {
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

    fileprivate func getLocalURL(_ guid: String) -> URL? {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var localURL = baseURL?.appendingPathComponent("episodes", isDirectory: true)
        localURL = localURL?.appendingPathComponent("\(guid).mp3")
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
        let localURL = self.getLocalURL(guid)
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
              let localURL = self.getLocalURL(guid) else {
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
    
    func delete(item: Feed.Item?, completion: @escaping (Bool) -> Void) {
        guard let item = item,
            let guid = item.guid,
            let localUrl = self.getLocalURL(guid) else { 
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
        NotificationCenter.default.post(name: Cache.episodeDidFinishDownloadingNotification, object: nil, userInfo: ["guid":guid])
    }

}
