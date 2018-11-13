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
import Firebase

protocol EpisodePlayerViewControllerDelegate:class {
    func episodePlayerViewControllerDidPressDismiss(episodePlayerViewController:EpisodePlayerViewController)
}

class EpisodePlayerViewController : UIViewController {
    
    var delegate:EpisodePlayerViewControllerDelegate?
    
    //MARK: Dependency section
    var episodeItem:Feed.Item! {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            self.setupInitialViewStateForEpisode()
        }
    }
    var feedType:AudioPlayer.FeedType = .none
    
    //Transcript related views
    @IBOutlet weak var transcriptContainerView: UIView!
    @IBOutlet weak var transcriptTextView: UITextView!
    @IBOutlet weak var transcriptObscureImageView: UIImageView!
    @IBOutlet weak var transcriptSubscribeNowLabel: UILabel!
    @IBOutlet weak var transcriptNonexistentCoverImageView: UIImageView!
    @IBOutlet weak var transcriptSignupView: UIView!
    @IBOutlet weak var transcriptRenewView: UIView!
    
    //Player controls
    @IBOutlet weak var timeElapsedLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var episodeDescriptionLabel: UILabel!
    @IBOutlet weak var playbackRateButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var autoPlaySwitch: UISwitch!
    @IBOutlet weak var autoPlayLabel: UILabel!
    
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate var userIsScrubbing = false
    
    var transcript:TranscriptModel? {
        didSet {
            guard self.isViewLoaded,
            let transcript = transcript else {
                return
            }
            
            self.transcriptTextView.text = transcript.fullTranscript
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch self.feedType {
        case .none:
            break
        case .episodes:
            AudioPlayer.sharedInstance.play(episodeItem: self.episodeItem)
        case .favorites:
            AudioPlayer.sharedInstance.play(favoriteItem: self.episodeItem)
        case .bonus:
            AudioPlayer.sharedInstance.play(bonusItem: self.episodeItem)
        }
        
        displayLink = CADisplayLink(target: self, selector: #selector(EpisodePlayerViewController.updatePlaybackProgress))
        displayLink.add(to: .current, forMode: .defaultRunLoopMode)
        
        self.setupInitialViewStateForEpisode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
            //changing the item will trigger UI updates
            self.episodeItem = currentLoadedAudioPlayerItem
        }
        else {
            self.setupInitialViewStateForEpisode()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerPlaybackStateDidChange), name:AudioPlayer.playbackStateDidChangeNotification , object: AudioPlayer.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlayingCurrentTrack), name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: AudioPlayer.sharedInstance)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func audioPlayerPlaybackStateDidChange(notification: Notification) {
        print("Audio player state change. updating Playback VC views")
        DispatchQueue.main.async {
            if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
                self.episodeItem = currentLoadedAudioPlayerItem
            }
            else {
                //possible error state
                self.setupInitialViewStateForEpisode()
            }
        }
    }
    
    func audioPlayerDidFinishPlayingCurrentTrack(notification: Notification) {
        DispatchQueue.main.async {
            if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
                self.episodeItem = currentLoadedAudioPlayerItem
            }
        }
    }
    
    func setupInitialViewStateForEpisode() {
        self.episodeDescriptionLabel.text = self.episodeItem.title
        self.fetchTranscript()
        self.updatePlaybackProgress()
        self.updateControlViews()
    }
    
    func updateControlViews() {
        
        //play button
        if AudioPlayer.sharedInstance.isPlaying {
            self.playButton?.setImage(UIImage(named: "ic_pause_50"), for: UIControlState.normal)
        }
        else {
            self.playButton?.setImage(UIImage(named: "ic_play_50"), for: UIControlState.normal)
        }
        
        //playback rate
        var playbackRateString = ""
        switch AudioPlayer.sharedInstance.playbackRate {
        case 0:
            playbackRateString = "Paused"
        case 0.5:
            playbackRateString = "0.5x"
        case 1:
            playbackRateString = "1x"
        case 1.5:
            playbackRateString = "1.5x"
        case 2:
            playbackRateString = "2x"
        default:
            playbackRateString = "1x"
        }
        self.playbackRateButton.setTitle(playbackRateString, for: UIControlState.normal)
        
        //Turn off autoplay for bonus content
        if AudioPlayer.sharedInstance.currentlyPlayingFeedType == .bonus {
            self.autoPlaySwitch.isHidden = true
            self.autoPlayLabel.isHidden = true
        }
        
        //Autoplay
        if (ApplicationData.isAutoPlayEnabled) {
            self.autoPlaySwitch.isOn = true
        }
        else {
            self.autoPlaySwitch.isOn = false
        }
    }
    
    func updatePlaybackProgress() {
        //Playback progress
        self.progressSlider.isEnabled = AudioPlayer.sharedInstance.queuePlayer.status == AVPlayerStatus.readyToPlay ? true : false

        self.timeElapsedLabel.text = AudioPlayer.sharedInstance.currentPlaybackFormattedTime
        self.timeRemainingLabel.text = "-\(AudioPlayer.sharedInstance.remainingPlaybackFormattedTime)"
        
        if (self.userIsScrubbing == false) {
            self.progressSlider.value = AudioPlayer.sharedInstance.playbackProgress
        }
        
        //Transcript word tracking
        if let transcript = self.transcript {
            let elapsedTime = AudioPlayer.sharedInstance.queuePlayer.currentTime().seconds * 1000
            for transcriptSegment in transcript.segments {
                let bufferRange:Double = 50
                let lowerTimeRange = transcriptSegment.timeStamp - bufferRange
                let upperTimeRange = transcriptSegment.timeStamp
                if elapsedTime >= lowerTimeRange && elapsedTime <= upperTimeRange {
                    let endRange = transcriptSegment.endRange > transcript.fullTranscript.count ? transcript.fullTranscript.count : transcriptSegment.endRange
                    let rangeLength = endRange - transcriptSegment.startRange
                    let textRange = NSMakeRange(transcriptSegment.startRange, rangeLength)
                    
                    let attributedString = NSMutableAttributedString(string:transcript.fullTranscript)
                    attributedString.addAttribute(NSFontAttributeName, value: UIFont.PTSansRegular(size: 24), range: NSMakeRange(0, transcript.fullTranscript.count))
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: NSMakeRange(0, transcript.fullTranscript.count))
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.AEEYellow, range: textRange)
                    
                    ///Regular async doesn't work here, but hacking in asyncAfter works
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.transcriptTextView.attributedText = attributedString
                        self.transcriptTextView.scrollRangeToVisible(textRange)
                    }
                }
            }
        }
    }
    
    @IBAction func dismissButtonPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.episodePlayerViewControllerDidPressDismiss(episodePlayerViewController: self)
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
    }
    
    @IBAction func autoPlaySwitchPressed(_ sender: Any) {
        ApplicationData.isAutoPlayEnabled = !ApplicationData.isAutoPlayEnabled
        self.updateControlViews()
    }
    
    @IBAction func signupButtonPressed(_ sender: Any) {
        let signupsubVC = SubscriptionSignupNavigationController()
        signupsubVC.subscriptionNavigationDelegate = self
        self.present(signupsubVC, animated: true)
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        let loginNavVC = LoginViewController.loginViewControllerWithNavigation(delegate: self)
        self.present(loginNavVC, animated: true)
    }
    
    @IBAction func renewSubscriptionPressed(_ sender: Any) {
    }
}

//MARK: transcripts
extension EpisodePlayerViewController {
    func fetchTranscript() {
        guard let guid = self.episodeItem.guid else {
            return
        }
        ServiceManager.sharedInstace.getTranscriptWithId(guid) { (transcriptModel, error) in
            if let transcriptModel = transcriptModel {
                if transcriptModel.id == self.transcript?.id {
                    // dont reset the transcript if its the same episode
                    return
                }
                self.transcript = transcriptModel
                self.evaluateTranscriptState()
            }
            else if let _ = error {
                self.evaluateTranscriptState()
            }
        }
    }
    
    func evaluateTranscriptState() {
        guard Auth.auth().currentUser != nil else {
            //no user
            self.showTranscriptSignupView()
            return
        }
        
        guard ApplicationData.isSubscribedToAEE == true else {
            //We have a user, but theyre sub isnt valid (no initial purchase or expired sub)
            self.self.showTranscriptRenewView()
            return
        }
        
        guard let transcript = self.transcript else {
            //No valid transcript for episode
            self.showNonexistentTranscriptCoverImage()
            return
        }
        
        if transcript.isFree == true || ApplicationData.isSubscribedToAEE == true {
            self.showTranscriptView()
        }
        else {
            self.showTranscriptSignupView()
        }
        
    }
    
    func showTranscriptView() {
        self.transcriptTextView.isHidden = false
        self.transcriptNonexistentCoverImageView.isHidden = true
        self.transcriptSignupView.isHidden = true
        self.transcriptRenewView.isHidden = true
    }
    
    func showNonexistentTranscriptCoverImage() {
        self.transcriptTextView.isHidden = true
        self.transcriptNonexistentCoverImageView.isHidden = false
        self.transcriptSignupView.isHidden = true
        self.transcriptRenewView.isHidden = true
    }
    
    func showTranscriptSignupView() {
        self.transcriptTextView.isHidden = true
        self.transcriptNonexistentCoverImageView.isHidden = true
        self.transcriptSignupView.isHidden = false
        self.transcriptRenewView.isHidden = true
    }
    
    func showTranscriptRenewView() {
        self.transcriptTextView.isHidden = true
        self.transcriptNonexistentCoverImageView.isHidden = true
        self.transcriptSignupView.isHidden = true
        self.transcriptRenewView.isHidden = false
    }
}

//MARK: Signup and login
extension EpisodePlayerViewController: LoginUpViewControllerDelegate {
    //Login
    func loginViewControllerDelegateDidCancel(loginViewController: LoginViewController) {
        self.evaluateTranscriptState()
        loginViewController.dismiss(animated: true)
    }
    func loginViewControllerDelegateDidFinish(loginViewController: LoginViewController) {
        self.evaluateTranscriptState()
        loginViewController.dismiss(animated: true)
    }
}

extension EpisodePlayerViewController:SubscriptionSignupNavigationControllerDelegate {
    func subscriptionSignupNavigationControllerDidFinishWithPurchase(viewController: SubscriptionSignupNavigationController) {
        self.evaluateTranscriptState()
        viewController.dismiss(animated: true)
    }
    
    func subscriptionSignupNavigationControllerDidCancel(viewController: SubscriptionSignupNavigationController) {
        self.evaluateTranscriptState()
        viewController.dismiss(animated: true)
    }
    
    
}
