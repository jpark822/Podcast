//
//  Player.swift
//  All Ears English
//
//  Created by Luis Artola on 6/26/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import Crashlytics
import Firebase

class Player: NSObject {

    static var shared: Player? = Player()

    fileprivate var player: AVPlayer? = nil
    fileprivate var url: String?
    private(set) var item: Feed.Item? = nil
    private(set) var playing = false
    var link: String?
    weak var delegate: PlayerDelegate?


    static let PlayerItemChange: Notification.Name = Notification.Name(rawValue: "PlayerItemChange")
    static let PlayerPlaybackStateChange: Notification.Name = Notification.Name(rawValue: "PlayerPlaybackStateChange")

    func play(from item: Feed.Item?) {
        guard let url = item?.url else {
            print("No url to play")
            return
        }
        self.item = item
        NotificationCenter.default.post(name: Player.PlayerItemChange, object: self)
        if self.url == url {
            if !self.playing {
                self.play()
            }
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            if let localURL = Cache.shared.get(item) {
                self.player = AVPlayer(url: localURL)
                print("playing \(localURL)")
            } else {
                self.player = AVPlayer(url: URL.init(string: url)!)
                print("playing \(url)")
            }
            self.player?.play()
            self.updatePlayingNowInfo()
            self.playing = true
            NotificationCenter.default.post(name: Player.PlayerPlaybackStateChange, object: self)
        } catch {
            print(error)
        }
    }

    func updatePlayingNowInfo() {
        if let title = item?.title,
           let image = UIImage(named: "Cover") {
            let infoCenter = MediaPlayer.MPNowPlayingInfoCenter.default()
            var artwork: MPMediaItemArtwork
            if #available(iOS 10.0, *) {
                artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {
                    size in
                    return image
                })
            } else {
                artwork = MPMediaItemArtwork(image: image)
            }
            var info: [String: Any]? = [
                    MPMediaItemPropertyTitle: title,
                    MPMediaItemPropertyArtwork: artwork
            ]
            if let duration = item?.duration {
                let components = duration.components(separatedBy: ":")
                print("Duration \(duration) - Components \(components)")
                if components.count == 2 {
                    let seconds = Int(components[0])! * 60 + Int(components[1])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                } else if components.count == 3 {
                    let seconds = Int(components[0])! * 60 * 60 + Int(components[1])! * 60 + Int(components[2])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                } else {
                    print("Duration CANNOT parse")
                }
            } else {
                print("Duration NONE")
            }
            if let player = self.player {
                info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player.currentTime())
                info?[MPNowPlayingInfoPropertyPlaybackRate] = 1
            }
            infoCenter.nowPlayingInfo = info
        }
    }

    func play() {
        if let player = self.player,
           !self.playing {
            player.play()
            self.playing = true
            NotificationCenter.default.post(name: Player.PlayerPlaybackStateChange, object: self)
        }
    }

    func pause() {
        if let player = self.player,
           self.playing {
            player.pause()
            self.playing = false
            NotificationCenter.default.post(name: Player.PlayerPlaybackStateChange, object: self)
        }
    }
    
    func togglePlayback() {
        if self.playing {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func open(_ link: String?) {
        print("\(#function) link: \(link ?? "")")
        self.link = link
        if let deepLink = link {
            delegate?.player(self, didOpen: deepLink)
        }
    }

    func shareEpisode(_ item: Feed.Item?, controller presentingController: UIViewController?) {
        let text = item?.title ?? ""
        let url = "https://www.allearsenglish.com/"
        let controller = UIActivityViewController.init(activityItems: [text, url], applicationActivities: nil)
        controller.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .print
        ]
        controller.completionWithItemsHandler = {
            (activityType, completed, returnedItems, activityError) in
            if completed {
                DispatchQueue.main.async {
                    let method = activityType?.rawValue ?? "Default"
                    self.logEventShareEpisode(item, method: method)
                }
            }
        }
        presentingController?.present(controller, animated: true)
    }

    func logEventShareEpisode(_ item: Feed.Item?, method: String) {
        let name = item?.title ?? "Unknown"
        let type = "episode"
        let id = item?.identifier ?? "0"
        let attributes: [String: Any] = [:]
        print("Logging share event: method=\(String(describing: method)) name=\(name) type=\(type) id=\(id) attributes=\(attributes)")
        Answers.logShare(
                withMethod: method,
                contentName: name,
                contentType: type,
                contentId: id,
                customAttributes: attributes
        )
        Analytics.logEvent(
                AnalyticsEventShare,
                parameters: [
                        AnalyticsParameterMedium: method as NSObject,
                        AnalyticsParameterItemName: name as NSObject,
                        AnalyticsParameterItemCategory: type as NSObject,
                        AnalyticsParameterItemID: id as NSObject
                ])
    }

    var progress: Float {
        guard let player = self.player,
                let item = player.currentItem else {
            return 0
        }
        let time = Float(player.currentTime().value)/Float(player.currentTime().timescale)
        let duration = Float(item.duration.value)/Float(item.duration.timescale)
        let progress = time/duration
        return progress
    }

    fileprivate func formatTime(_ time: Float) -> String {
        let minutes = Int(time)/60
        let seconds = Int(time) - minutes*60
        let text = String(format: "%d:%02d", arguments: [minutes, seconds])
        return text
    }

    var formattedTime: (current: String, remaining: String) {
        guard let player = self.player,
              CMTIME_IS_VALID(player.currentTime()),
              let item = player.currentItem,
              CMTIME_IS_VALID(item.duration),
              !CMTIME_IS_INDEFINITE(item.duration) else {
            return (current: "0:00", remaining: "0:00")
        }
        let currentTime = player.currentTime()
        let time = Float(currentTime.value)/Float(currentTime.timescale)
        let currentText = self.formatTime(time)
        let duration = Float(item.duration.value)/Float(item.duration.timescale)
        let remaining = duration - time
        let remainingText = self.formatTime(remaining)
        return (current: currentText, remaining: remainingText)
    }

    func seek(to time: TimeInterval) {
        if let player = self.player,
           self.playing {
            var seconds = time
            if seconds < 0 {
                seconds = 0
            }
            let position = CMTime.init(value: CMTimeValue(seconds*1000000), timescale: 1000000)
            player.seek(to: position, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { (finished) in
                self.updatePlayingNowInfo()
            }
        }
    }
}

protocol PlayerDelegate: NSObjectProtocol {
    func player(_ player: Player, didOpen link: String)
}


