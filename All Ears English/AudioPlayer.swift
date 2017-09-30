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
    
    var playbackProgress:Float {
        get {
            guard let audioPlayerItem = self.queuePlayer.currentItem else {
                return -1.0
            }
            
            let time = Float(self.queuePlayer.currentTime().value)/Float(self.queuePlayer.currentTime().timescale)
            let duration = Float(audioPlayerItem.duration.value)/Float(audioPlayerItem.duration.timescale)
            let progress = time/duration
            return progress
        }
    }
    
    var playbackRate:Float {
        get {
            return self.queuePlayer.rate
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
        
        self.queuePlayer.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain
        self.updatePlayingInfoCenterData(item: item)
        //send notification for player change
        self.queuePlayer.play()
        
    }
    
    func play() {
        guard self.currentItem != nil else {
            return
        }
        self.queuePlayer.play()
    }
    
    func pause() {
        guard self.currentItem != nil else {
            return
        }
        self.queuePlayer.pause()
    }
    
    
}

//MARK: Seeking
extension AudioPlayer {
    func seekToNextTrack() {
        guard let currentItem = self.currentItem else {
            return
        }
        
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in Feed.shared.items {
            if item.number == currentItem.number && Feed.shared.items.count > (index + 1) {
                self.play(item: Feed.shared.items[index + 1])
            }
            index += 1
        }
    }
    
    func seekToBeginningOrPreviousTrack() {
        let playerTime = self.queuePlayer.currentTime()
        if CMTimeGetSeconds(playerTime) < 3.0 {
            self.seekToPreviousTrack()
        }
        else {
            self.seekToBeginningOfTrack()
        }
    }
    
    func seekToBeginningOfTrack() {
        self.queuePlayer.seek(to: kCMTimeZero)
    }
    
    func seekToPreviousTrack() {
        guard let currentItem = self.currentItem else {
            return
        }
        
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in Feed.shared.items {
            if item.number == currentItem.number && (index-1) >= 0 {
                self.play(item: Feed.shared.items[index-1])
            }
            index += 1
        }
    }
    
    func seekForward(seconds:Double) {
        let currentTime = queuePlayer.currentTime()
        let seekToTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + seconds, currentTime.timescale)
        self.queuePlayer.seek(to: seekToTime)
    }
    
    func seekToProgress(_ progress:Float) {
        guard let currentPlayerAVItem = self.queuePlayer.currentItem else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentPlayerAVItem.duration)
        let secondToSeekTo = Double(progress) * duration
        
        
        self.queuePlayer.seek(to: CMTimeMakeWithSeconds(secondToSeekTo, self.queuePlayer.currentTime().timescale))
    }
}

//MARK: Now Playing and Command Center remote controls
extension AudioPlayer {
    func commandCenterNextTrackPressed()  {
        print("next")
    }
    
    func commandCenterPreviousTrackPressed() {
        print("back")
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

//MARK: Helpers 
extension AudioPlayer {
    var currentPlaybackFormattedTime:String {
        get {
            guard let item = self.queuePlayer.currentItem,
                CMTIME_IS_VALID(self.queuePlayer.currentTime()),
                CMTIME_IS_VALID(item.duration),
                !CMTIME_IS_INDEFINITE(item.duration) else {
                    return "0:00"
            }
            
            let currentTime = self.queuePlayer.currentTime()
            let time = floor(Float(currentTime.value)/Float(currentTime.timescale))
            let currentTimeString = self.formatPlaybackTime(time)
            return currentTimeString
        }
    }
    
    var remainingPlaybackFormattedTime:String {
        get {
            guard let item = self.queuePlayer.currentItem,
                CMTIME_IS_VALID(self.queuePlayer.currentTime()),
                CMTIME_IS_VALID(item.duration),
                !CMTIME_IS_INDEFINITE(item.duration) else {
                    return "0:00"
            }
            let currentTime = self.queuePlayer.currentTime()
            let time = floor(Float(currentTime.value)/Float(currentTime.timescale))
            let duration = floor(Float(item.duration.value)/Float(item.duration.timescale))
            let remaining = duration - time
            let remainingTimeString = self.formatPlaybackTime(remaining)
            
            return remainingTimeString
        }
    }
    
    fileprivate func formatPlaybackTime(_ time: Float) -> String {
        let minutes = Int(time)/60
        let seconds = Int(time) - minutes*60
        let text = String(format: "%d:%02d", arguments: [minutes, seconds])
        return text
    }
    
    func changePlaybackRate(to rate:Float) {
        self.queuePlayer.rate = rate
    }
}
