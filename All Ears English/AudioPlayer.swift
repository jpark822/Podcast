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
import Mixpanel

internal class AudioPlayer:NSObject {
    
    enum FeedType {
        case none
        case episodes
        case favorites
        case bonus
    }
    
    static var sharedInstance = AudioPlayer()
    
    var queuePlayer:AVQueuePlayer = AVQueuePlayer()
    var currentItem:Feed.Item?
    var currentlyPlayingFeedType:AudioPlayer.FeedType = AudioPlayer.FeedType.none
    
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
    
    //keeping a stored playback rate. Pausing the player naturally causes the playbackrate to go to 0
    public fileprivate(set) var playbackRate:Float = 1.0
    
    override init() {
        super.init()
        
        _ = self.initAudioSessionAndControls()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.queuePlayer.currentItem)
        self.queuePlayer.actionAtItemEnd = .pause
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func playerDidFinishPlaying(notification: NSNotification) {
        AnalyticsManager.sharedInstance.logMixpanelEpisodeEvent("Episode Finished", item: self.currentItem)
        
        //bonus content doesnt autoplay
        if ApplicationData.isAutoPlayEnabled && self.currentlyPlayingFeedType != .bonus {
            _ = self.seekToNextTrack()
        }
        else {
            self.queuePlayer.seek(to: CMTime.zero)
            self.pause()
        }
        NotificationCenter.default.post(name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: self)
    }
    
    private func initAudioSessionAndControls() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: .default)
            self.queuePlayer.automaticallyWaitsToMinimizeStalling = true
            
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
    
    func remoteskipbackward() {
        print("skip backward")
    }
    
    func play(episodeItem: Feed.Item?) {
        self.currentlyPlayingFeedType = .episodes
        self.play(item: episodeItem)
    }
    
    func play(favoriteItem:Feed.Item?) {
        self.currentlyPlayingFeedType = .favorites
        self.play(item: favoriteItem)
    }
    
    func play(bonusItem:Feed.Item?) {
        self.currentlyPlayingFeedType = .bonus
        self.play(item:bonusItem)
    }
    
    fileprivate func play(item: Feed.Item?) {
        guard let item = item,
            let itemUrlString = item.url,
            let itemUrl = URL.init(string: itemUrlString) else {
            NSLog("no item to play")
            return
        }
        
        if self.currentItem?.url == item.url {
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
        
        self.queuePlayer.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.timeDomain
        self.queuePlayer.play()
        self.queuePlayer.rate = self.playbackRate
        
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
        
        AnalyticsManager.sharedInstance.logMixpanelEpisodeEvent("Play Episode", item: item)
        switch item.episodeType {
        case .episode:
            AnalyticsManager.sharedInstance.logKochavaEpisodeEvent(.episodeListen, item: item)
            break
        case .bonus:
            AnalyticsManager.sharedInstance.logKochavaEpisodeEvent(.bonusEpisodeListen, item: item)
            break
        }
    }
    
    func play() {
        guard self.currentItem != nil else {
            return
        }
        
        self.queuePlayer.play()
        self.queuePlayer.rate = self.playbackRate
        
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
    
    func clearPlayerItems() {
        self.currentItem = nil
        self.queuePlayer.removeAllItems()
        
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func changePlaybackRate(to rate:Float) {
        self.playbackRate = rate
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
        
        var feedItems:[Feed.Item] = []
        if self.currentlyPlayingFeedType == .episodes {
            feedItems = Feed.shared.items
        }
        else if self.currentlyPlayingFeedType == .favorites {
            feedItems = FavoritesManager.sharedInstance.getAllStoredFavorites()
        }
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in feedItems {
            if item.url == currentItem.url && feedItems.count > (index + 1) {
                let nextEpisodeItem = feedItems[index + 1]
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
        self.queuePlayer.seek(to: CMTime.zero)
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func seekToPreviousTrack() -> Feed.Item? {
        guard let currentItem = self.currentItem else {
            return nil
        }
        
        var feedItems:[Feed.Item] = []
        if self.currentlyPlayingFeedType == .episodes {
            feedItems = Feed.shared.items
        }
        else if self.currentlyPlayingFeedType == .favorites {
            feedItems = FavoritesManager.sharedInstance.getAllStoredFavorites()
        }
        //TODO replace with updated swift index(of)
        var index = 0
        for item:Feed.Item in feedItems {
            if item.url == currentItem.url && (index-1) >= 0 {
                let prevEpisodeItem = feedItems[index-1]
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
        let seekToTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + seconds, preferredTimescale: currentTime.timescale)
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
        
        self.queuePlayer.seek(to: CMTimeMakeWithSeconds(secondToSeekTo, preferredTimescale: self.queuePlayer.currentTime().timescale))
        
        //need up update control center with new elapsed time
        self.updatePlayingInfoCenterData()
        NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
    }
    
    func seekToTimeInSeconds(_ seconds: Double) {
        DispatchQueue.main.async {
            print("seeking to \(seconds)")
            self.queuePlayer.seek(to: CMTimeMakeWithSeconds(seconds, preferredTimescale: self.queuePlayer.currentTime().timescale))
            NotificationCenter.default.post(name: AudioPlayer.playbackStateDidChangeNotification, object: self, userInfo: nil)
            
            let time = DispatchTime.now() + 0.25
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.updatePlayingInfoCenterData()
            })
        }
    }
}

//MARK: Now Playing and Command Center remote controls
extension AudioPlayer {
    @objc func commandCenterPlayPressed() -> MPRemoteCommandHandlerStatus {
        self.play()
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func commandCenterPausePressed() -> MPRemoteCommandHandlerStatus {
        self.pause()
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func commandCenterNextTrackPressed() -> MPRemoteCommandHandlerStatus  {
        if self.seekToNextTrack() != nil {
            self.updatePlayingInfoCenterData()
        }
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func commandCenterPreviousTrackPressed() -> MPRemoteCommandHandlerStatus {
        if self.seekToBeginningOrPreviousTrack() != nil {
            self.updatePlayingInfoCenterData()
        }
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func commandCenterDidChangePlaybackPosition(event: MPChangePlaybackPositionCommandEvent)  -> MPRemoteCommandHandlerStatus {
        self.seekToTimeInSeconds(event.positionTime)
        //seeking will take care of notification and updating playing center info
        return MPRemoteCommandHandlerStatus.success
    }
    
    func updatePlayingInfoCenterData() {
        guard let currentItem = self.currentItem,
            let currentPlayerAVItem = self.queuePlayer.currentItem else {
                
                MediaPlayer.MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                
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
//                print("Duration \(duration) - Components \(components)")
                if components.count == 2 {
                    let seconds = Int(components[0])! * 60 + Int(components[1])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                }
                else if components.count == 3 {
                    let seconds = Int(components[0])! * 60 * 60 + Int(components[1])! * 60 + Int(components[2])!
                    info?[MPMediaItemPropertyPlaybackDuration] = seconds
                }
                else if components.count == 1 {
                    let seconds = components[0]
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
            info?[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: Double(self.queuePlayer.rate))
            
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
        let seconds = Int64(time) - (minutes * 60)
//        let text = "\(minutes):\(seconds)"
        let text = String(format: "%lld:%02lld", arguments: [minutes, seconds])
        return text
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
