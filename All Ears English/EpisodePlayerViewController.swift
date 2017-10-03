//
//  EpisodePlayerViewController.swift
//  All Ears English
//
//  Created by Jay Park on 9/30/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

class EpisodePlayerViewController : UIViewController {
    
    //MARK: Dependency
    var episodeItem:Feed.Item! {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            self.setupInitialViewStateForEpisode()
        }
    }
    
    @IBOutlet weak var episodeImageView: UIImageView!
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var episodeDescriptionLabel: UILabel!
    @IBOutlet weak var playbackRateButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var autoplayButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate var playbackRate = 1.0
    fileprivate var userIsScrubbing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AudioPlayer.sharedInstance.play(item: self.episodeItem)
        
        displayLink = CADisplayLink(target: self, selector: #selector(EpisodePlayerViewController.updatePlaybackProgress))
        displayLink.add(to: .current, forMode: .defaultRunLoopMode)
        
        self.setupInitialViewStateForEpisode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
            self.episodeItem = currentLoadedAudioPlayerItem
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerRemoteCommandDidFinish), name: AudioPlayer.didFinishRemoteControlCommandNotification, object: AudioPlayer.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlayingCurrentTrack), name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: AudioPlayer.sharedInstance)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func audioPlayerDidFinishPlayingCurrentTrack(notification: Notification) {
        DispatchQueue.main.async {
            if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
                self.episodeItem = currentLoadedAudioPlayerItem
            }
        }
    }
    
    func audioPlayerRemoteCommandDidFinish(notification:Notification) {
        DispatchQueue.main.async {
            if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
                self.episodeItem = currentLoadedAudioPlayerItem
            }
        }
    }
    
    func setupInitialViewStateForEpisode() {
        self.episodeDescriptionLabel.text = self.episodeItem.title
        self.updatePlaybackProgress()
        self.updateControlViews()
    }
    
    func updateControlViews() {
        
        //play button
        if AudioPlayer.sharedInstance.isPlaying {
            self.playButton?.setImage(UIImage(named: "ic_pause_48pt"), for: UIControlState.normal)
            self.playButton?.setImage(UIImage(named: "ic_pause_white"), for: UIControlState.highlighted)
        }
        else {
            self.playButton?.setImage(UIImage(named: "ic_play_arrow_48pt"), for: UIControlState.normal)
            self.playButton?.setImage(UIImage(named: "ic_play_arrow_white"), for: UIControlState.highlighted)
        }
        
        //playback rate
        self.playbackRateButton.setTitle("\(AudioPlayer.sharedInstance.playbackRate)x", for: UIControlState.normal)
        
        //Autoplay
        if (ApplicationData.isAutoPlayEnabled) {
            print("autoplay is on")
            self.autoplayButton.setTitle("Auto On", for: .normal)
        }
        else {
            self.autoplayButton.setTitle("Auto Off", for: .normal)
        }
    }
    
    func updatePlaybackProgress() {
        self.progressSlider.isEnabled = AudioPlayer.sharedInstance.queuePlayer.status == AVPlayerStatus.readyToPlay ? true : false

        self.timeElapsedLabel.text = AudioPlayer.sharedInstance.currentPlaybackFormattedTime
        self.timeRemainingLabel.text = "-\(AudioPlayer.sharedInstance.remainingPlaybackFormattedTime)"
        
        if (self.userIsScrubbing == false) {
            self.progressSlider.value = AudioPlayer.sharedInstance.playbackProgress
        }
    }
    
    //MARK: Playback Controls
    @IBAction func playPressed(_ sender: Any) {
        if AudioPlayer.sharedInstance.isPlaying {
            AudioPlayer.sharedInstance.pause()
        }
        else {
            AudioPlayer.sharedInstance.play()
        }
        self.updateControlViews()
    }
    
    @IBAction func previousSeekPressed(_ sender: Any) {
        if let prevEpisodeItem = AudioPlayer.sharedInstance.seekToBeginningOrPreviousTrack() {
            self.episodeItem = prevEpisodeItem
        }
    }
    
    @IBAction func forwardSeekPressed(_ sender: Any) {
        if let nextEpisodeItem = AudioPlayer.sharedInstance.seekToNextTrack() {
            self.episodeItem = nextEpisodeItem
        }
    }
    
    @IBAction func skipBackwardPressed(_ sender: Any) {
        AudioPlayer.sharedInstance.seekForward(seconds: -15.0)
    }
    
    @IBAction func skipForwardPressed(_ sender: Any) {
        AudioPlayer.sharedInstance.seekForward(seconds: 15.0)
    }
    
    @IBAction func progressSliderTouchDown(_ sender: Any) {
        self.userIsScrubbing = true
    }
    
    @IBAction func progressSliderTouchUpInside(_ sender: Any) {
        self.userIsScrubbing = false
        AudioPlayer.sharedInstance.seekToProgress(self.progressSlider.value)
    }
    
    @IBAction func playbackRatePressed(_ sender: Any) {
        let currentRate = AudioPlayer.sharedInstance.playbackRate
        
        var newRate:Float = 1
        switch currentRate {
        case 0.5:
            newRate = 1
        case 1:
            newRate = 1.5
        case 1.5:
            newRate = 2
        case 2:
            newRate = 0.5
        default:
            newRate = 1
        }
        
        AudioPlayer.sharedInstance.changePlaybackRate(to: newRate)
        self.updateControlViews()
    }
    
    @IBAction func autoPlayPressed(_ sender: Any) {
        ApplicationData.isAutoPlayEnabled = !ApplicationData.isAutoPlayEnabled
        self.updateControlViews()
    }
    
    
}
