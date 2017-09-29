//
//  AudioPlayer.swift
//  All Ears English
//
//  Created by Jay Park on 9/28/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import MediaPlayer
import Crashlytics
import Firebase

internal class AudioPlayer:NSObject {
    
    static var sharedInstance = AudioPlayer()
    
    var queuePlayer:AVQueuePlayer = AVQueuePlayer()
    var currentItem:Feed.Item?
    
    var isPlaying:Bool {
        get {
            if ((queuePlayer.rate != 0) && (queuePlayer.error == nil)) {
                return true
            }
            return false
        }
    }

    
    private func initAudioSessionAndControls() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget(self, action:#selector(commandCenterNextTrackPressed))
            
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget(self, action: #selector(commandCenterPreviousTrackPressed))
        }
        catch {
            NSLog("error initting audio session")
            return false
        }
        
        return true
    }
    
    func play(item: Feed.Item?) {
        guard let item = item,
            let itemUrlString = item.url,
            let itemUrl = URL.init(string: itemUrlString) else {
            NSLog("no item to play")
            return
        }
        
        guard self.initAudioSessionAndControls() else {
            return
        }
        
        if self.currentItem?.url == item.url && !self.isPlaying {
            self.play()
            return
        }
        
        self.currentItem = item
        if let localURL = Cache.shared.get(item) {
            self.queuePlayer = AVQueuePlayer(url: localURL)
            print("playing \(localURL)")
        }
        else {
            self.queuePlayer = AVQueuePlayer(url: itemUrl)
            print("playing \(itemUrl)")
        }
        
        self.updatePlayingInfoCenterData(item: item)
        self.queuePlayer.play()
        
    }
    
    func commandCenterNextTrackPressed()  {
        print("next")
    }
    
    func commandCenterPreviousTrackPressed() {
        print("back")
    }
    
    func play() {
        
    }
    
    func updatePlayingInfoCenterData(item: Feed.Item?) {
        guard let item = item else {
            return
        }
        
        if let title = item.title,
            let image = UIImage(named: "Cover") {
            
            let infoCenter = MediaPlayer.MPNowPlayingInfoCenter.default()
            
            var artwork:MPMediaItemArtwork
            if #available(iOS 10.0, *) {
                artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {
                    size in
                    return image
                })
            }
            else {
                artwork = MPMediaItemArtwork(image: image)
            }
            
            var info: [String: Any]? = [
                MPMediaItemPropertyTitle: title,
                MPMediaItemPropertyArtwork: artwork
            ]
            if let duration = item.duration {
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
            
            info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(queuePlayer.currentTime())
            info?[MPNowPlayingInfoPropertyPlaybackRate] = 1
            infoCenter.nowPlayingInfo = info
        }
    }
}
