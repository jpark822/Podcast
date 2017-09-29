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

    fileprivate var items: [String: URL?] = [:]

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


    func download(_ item: Feed.Item?, callback: @escaping (Feed.Item) -> Void) {
        guard let item = item,
              let url = item.url,
              let guid = item.guid,
              let localURL = self.getLocalURL(guid) else {
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url:URL(string: url)!)

        let task = session.downloadTask(with: request) { (tempLocalURL, response, error) in
            if let tempLocalURL = tempLocalURL, error == nil {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Downloaded \(url) to \(tempLocalURL) with status \(statusCode)")
                }
                do {
                    try FileManager.default.copyItem(at: tempLocalURL, to: localURL)
                    self.items[guid] = localURL
                    callback(item)
                } catch (let writeError) {
                    print("Error creating \(localURL): \(writeError)")
                }
            } else {
                print("Unexpected error downloading \(url): \(error?.localizedDescription ?? "")")
            }
        }
        task.resume()
    }

}
