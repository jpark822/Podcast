//
//  AudioPlayer.swift
//  All Ears English
//
//  Created by Jay Park on 9/28/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import Crashlytics
import Firebase

internal class AudioPlayer:NSObject {
    
    static var sharedInstance = AudioPlayer()
    
    var queuePlayer:AVQueuePlayer = AVQueuePlayer()
    var currentItem:Feed.Item?
    
    static let playbackStateDidChangeNotification: Notification.Name = Notification.Name(rawValue: "audioPlayerPlaybackStateDidChangeNotification")
    static let didFinishPlayingCurrentTrackNotification: Notification.Name = Notification.Name(rawValue: "didFinishPlayingCurrentTrackNotification")
    
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
    
    override init() {
        super.init()
        
        _ = self.initAudioSessionAndControls()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.queuePlayer.currentItem)
        self.queuePlayer.actionAtItemEnd = .pause
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func playerDidFinishPlaying(notification: NSNotification) {
        if ApplicationData.isAutoPlayEnabled {
            _ = self.seekToNextTrack()
        }
        else {
            self.queuePlayer.seek(to: kCMTimeZero)
            self.pause()
        }
        NotificationCenter.default.post(name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: self)
    }
    
    private func initAudioSessionAndControls() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            self.queuePlayer.automaticallyWaitsToMinimizeStalling = false
            
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            let commandCenter = MPRemoteCommandCenter.shared()
            commandCenter.playCommand.isEnabled = true
            commandCenter.playCommand.addTarget(self, action: #selector(commandCenterPlayPressed))
            
            commandCenter.pauseCommand.isEnabled = true
            commandCenter.pauseCommand.addTarget(self, action: #selector(commandCenterPausePressed))
            
            commandCenter.nextTrackCommand.isEnabled = true
            commandCenter.nextTrackCommand.addTarget(self, action:#selector(commandCenterNextTrackPressed))
            
            commandCenter.previousTrackCommand.isEnabled = true
            commandCenter.previousTrackCommand.addTarget(self, action: #selector(commandCenterPreviousTrackPressed))
            
            commandCenter.changePlaybackPositionCommand.isEnabled = true
            commandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(commandCenterDidChangePlaybackPosition))
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
        
        if self.currentItem?.url == item.url && !self.isPlaying {
            self.play()
            return
        }
        
        self.currentItem = item
        
        self.queuePlayer.removeAllItems()
        if let localURL = Cache.shared.get(item) {
            let newPlayerItem = AVPlayerItem.init(url: localURL)
            self.queuePlayer.insert(newPlayerItem, after: nil)
            print("playing \(localURL)")
        }
        else {
            let newPlayerItem = AVPlayerItem.init(url: itemUrl)
            self.queuePlayer.insert(newPlayerItem, after: nil)
            print("playing \(itemUrl)")
        }
        
        self.queuePlayer.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain
        self.queuePlayer.play()
        
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func play() {
        guard self.currentItem != nil else {
            return
        }
        self.queuePlayer.play()
        
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func pause() {
        guard self.currentItem != nil else {
            return
        }
        self.queuePlayer.pause()
        
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func changePlaybackRate(to rate:Float) {
        self.queuePlayer.rate = rate
        
        //need to update control center with playback rate
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
}

//MARK: Seeking
extension AudioPlayer {
    func seekToNextTrack() -> Feed.Item? {
        guard let currentItem = self.currentItem else {
            return nil
        }
        
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in Feed.shared.items {
            if item.url == currentItem.url && Feed.shared.items.count > (index + 1) {
                let nextEpisodeItem = Feed.shared.items[index + 1]
                self.play(item: nextEpisodeItem)
                
                NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
                
                return nextEpisodeItem
            }
            index += 1
        }
        
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
        
        return nil
    }
    
    //this method doesnt send notification for update state change because it's a helper
    func seekToBeginningOrPreviousTrack() -> Feed.Item? {
        let playerTime = self.queuePlayer.currentTime()
        if CMTimeGetSeconds(playerTime) < 3.0 {
            return self.seekToPreviousTrack()
        }
        else {
            self.seekToBeginningOfTrack()
            return self.currentItem
        }
    }
    
    func seekToBeginningOfTrack() {
        self.queuePlayer.seek(to: kCMTimeZero)
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func seekToPreviousTrack() -> Feed.Item? {
        guard let currentItem = self.currentItem else {
            return nil
        }
        
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in Feed.shared.items {
            if item.url == currentItem.url && (index-1) >= 0 {
                let prevEpisodeItem = Feed.shared.items[index-1]
                self.play(item: prevEpisodeItem)
                
                NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
                
                return prevEpisodeItem
            }
            index += 1
        }
        
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
        
        return nil
    }
    
    func seekForward(seconds:Double) {
        let currentTime = queuePlayer.currentTime()
        let seekToTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + seconds, currentTime.timescale)
        self.queuePlayer.seek(to: seekToTime)
        
        //need up update control center with new elapsed time
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func seekToProgress(_ progress:Float) {
        guard let currentPlayerAVItem = self.queuePlayer.currentItem else {
            return
        }
        
        let duration = CMTimeGetSeconds(currentPlayerAVItem.duration)
        let secondToSeekTo = Double(progress) * duration
        
        self.queuePlayer.seek(to: CMTimeMakeWithSeconds(secondToSeekTo, self.queuePlayer.currentTime().timescale))
        
        //need up update control center with new elapsed time
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func seekToTimeInSeconds(_ seconds: Double) {
        self.queuePlayer.seek(to: CMTimeMakeWithSeconds(seconds, self.queuePlayer.currentTime().timescale))
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
}

//MARK: Now Playing and Command Center remote controls
extension AudioPlayer {
    func commandCenterPlayPressed() {
        self.play()
    }
    
    func commandCenterPausePressed() {
        self.pause()
    }
    
    func commandCenterNextTrackPressed()  {
        if self.seekToNextTrack() != nil {
            self.updatePlayingInfoCenterData()
        }
    }
    
    func commandCenterPreviousTrackPressed() {
        if self.seekToBeginningOrPreviousTrack() != nil {
            self.updatePlayingInfoCenterData()
        }
    }
    
    func commandCenterDidChangePlaybackPosition(event: MPChangePlaybackPositionCommandEvent) {
        self.seekToTimeInSeconds(event.positionTime)
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self)
    }
    
    func updatePlayingInfoCenterData() {
        guard let currentItem = self.currentItem,
            let currentPlayerAVItem = self.queuePlayer.currentItem else {
            return
        }
        
        if let title = currentItem.title,
            let image = UIImage(named: "Cover") {
            
            
            var info: [String: Any]? = [:]
            
            var artwork:MPMediaItemArtwork
            artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {
                size in
                return image
            })
            
            
            if let duration = currentItem.duration {
                let components = duration.components(separatedBy: ":")
                print("Duration \(duration) - Components \(components)")
                if components.count == 2 {
                    let seconds = Int(components[0])! * 60 + Int(components[1])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                } else if components.count == 3 {
                    let seconds = Int(components[0])! * 60 * 60 + Int(components[1])! * 60 + Int(components[2])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                }
                else {
                    print("Duration CANNOT parse")
                }
            }
            else {
                print("Duration NONE")
            }
//            let duration = CMTimeGetSeconds(currentPlayerAVItem.duration)
            
            
            info?[MPMediaItemPropertyTitle] = title
            info?[MPMediaItemPropertyArtwork] = artwork
            info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: CMTimeGetSeconds(currentPlayerAVItem.currentTime()))
            info?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: Double(self.playbackRate))
            
            MediaPlayer.MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
        let minutes = Int64(time)/60
        let seconds = Int64(time) - minutes*60
        let text = String(format: "%d:%02d", arguments: [minutes, seconds])
        return text
    }
}
