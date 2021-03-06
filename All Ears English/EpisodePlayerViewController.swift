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
    
    //keyword related views
    @IBOutlet weak var keywordView: UIView!
    @IBOutlet weak var keywordBackButton: UIButton!
    @IBOutlet weak var keywordTitleLabel: UILabel!
    @IBOutlet weak var keywordDefinitionLabel: UILabel!
    @IBOutlet weak var keywordSaveButton: UIButton!
    @IBOutlet weak var keywordRemoveButton: UIButton!
    
    
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
    
    fileprivate var currentlyViewedKeyword:KeywordModel?
    
    var transcript:TranscriptModel? {
        didSet {
            guard self.isViewLoaded,
            let transcript = transcript else {
                return
            }
            
            self.transcriptTextView.text = transcript.fullTranscript
            self.updatePlaybackProgress()
            print("setting transcript")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transcriptTextView.delegate = self
        
        self.displayLink = CADisplayLink(target: self, selector: #selector(EpisodePlayerViewController.updatePlaybackProgress))
        self.displayLink.add(to: .current, forMode: RunLoop.Mode.default)
        
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
        
        self.setupInitialViewStateForEpisode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
            //changing the item will trigger UI updates
            self.episodeItem = currentLoadedAudioPlayerItem
        }
        else {
            self.setupInitialViewStateForEpisode()
        }
        
        self.updatePlaybackProgress()
        
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerPlaybackStateDidChange), name:AudioPlayer.playbackStateDidChangeNotification , object: AudioPlayer.sharedInstance)
        NotificationCenter.default.addObserver(self, selector: #selector(audioPlayerDidFinishPlayingCurrentTrack), name: AudioPlayer.didFinishPlayingCurrentTrackNotification, object: AudioPlayer.sharedInstance)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updatePlaybackProgress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func audioPlayerPlaybackStateDidChange(notification: Notification) {
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
    
    @objc func audioPlayerDidFinishPlayingCurrentTrack(notification: Notification) {
        DispatchQueue.main.async {
            if let currentLoadedAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
                self.episodeItem = currentLoadedAudioPlayerItem
            }
        }
    }
    
    func setupInitialViewStateForEpisode() {
        self.episodeDescriptionLabel.text = self.episodeItem.title
        self.fetchTranscript()
        self.fetchQuiz()
        self.updatePlaybackProgress()
        self.updateControlViews()
    }
    
    func updateControlViews() {
        
        //play button
        if AudioPlayer.sharedInstance.isPlaying {
            self.playButton?.setImage(UIImage(named: "ic_pause_50"), for: UIControl.State.normal)
        }
        else {
            self.playButton?.setImage(UIImage(named: "ic_play_50"), for: UIControl.State.normal)
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
        self.playbackRateButton.setTitle(playbackRateString, for: UIControl.State.normal)
        
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
    
    @objc func updatePlaybackProgress() {
        DispatchQueue.main.async {
            //Playback progress
            self.progressSlider.isEnabled = AudioPlayer.sharedInstance.queuePlayer.status == AVPlayer.Status.readyToPlay ? true : false

            self.timeElapsedLabel.text = AudioPlayer.sharedInstance.currentPlaybackFormattedTime
            self.timeRemainingLabel.text = "-\(AudioPlayer.sharedInstance.remainingPlaybackFormattedTime)"
            
            if (self.userIsScrubbing == false) {
                self.progressSlider.value = AudioPlayer.sharedInstance.playbackProgress
            }
            
            //Transcript word tracking
            if let transcript = self.transcript {
                let elapsedTime = AudioPlayer.sharedInstance.queuePlayer.currentTime().seconds * 1000
                
                var foundTextRange:NSRange = NSMakeRange(0, 0)

                for transcriptSegment in transcript.segments {
                    let lowerBufferRange:Double = 50
                    let upperBufferRange:Double = 50
                    let lowerTimeRange = transcriptSegment.timeStamp - lowerBufferRange
                    let upperTimeRange = transcriptSegment.timeStamp + upperBufferRange
                    if elapsedTime >= lowerTimeRange && elapsedTime <= upperTimeRange {
                        let endRange = transcriptSegment.endRange > transcript.fullTranscript.count ? transcript.fullTranscript.count : transcriptSegment.endRange
                        let rangeLength = endRange - transcriptSegment.startRange
                        foundTextRange = NSMakeRange(transcriptSegment.startRange, rangeLength)
                        
                        //highlight currently playing text
                        let attributedString = NSMutableAttributedString(string:transcript.fullTranscript)
                        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.PTSansRegular(size: 24), range: NSMakeRange(0, transcript.fullTranscript.count))
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: NSMakeRange(0, transcript.fullTranscript.count))
                        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.AEEYellow, range: foundTextRange)
                        
                        //add keywords
                        self.highlightKeywordsInTranscript(attributedTranscript: attributedString)
                        
                        self.transcriptTextView.attributedText = attributedString
                        
                        
                    }
                }
                
                ///Regular async doesn't work here, but hacking in asyncAfter works
                if foundTextRange != NSMakeRange(0, 0) && elapsedTime > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.transcriptTextView.scrollRangeToVisible(foundTextRange)
                    }
                }
            }
        }
    }
    
    func highlightKeywordsInTranscript(attributedTranscript:NSMutableAttributedString) {
        guard let transcript = self.transcript else {
            return
        }
    
        for keyword in transcript.keywords {
            let keywordName = keyword.name
            let rangesOfOccurence = transcript.fullTranscript.nsRangesForFullWord(of: keywordName)
            for range in rangesOfOccurence {
                let unsanitziedString = "AEE://\(keywordName)"
                let sanitizedString = unsanitziedString.addingPercentEncoding(withAllowedCharacters: [])
                if let url = URL(string:sanitizedString!) {
                    attributedTranscript.addAttributes([NSAttributedString.Key.link:url, NSAttributedString.Key.underlineStyle:NSUnderlineStyle.single.rawValue], range: range)
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
        signupsubVC.state = .signup
        signupsubVC.subscriptionNavigationDelegate = self
        self.present(signupsubVC, animated: true)
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        let loginNavVC = LoginViewController.loginViewControllerWithNavigation(delegate: self)
        self.present(loginNavVC, animated: true)
    }
    
    @IBAction func renewSubscriptionPressed(_ sender: Any) {
        let renewSubVC = SubscriptionSignupNavigationController()
        renewSubVC.state = .renew
        renewSubVC.subscriptionNavigationDelegate = self
        self.present(renewSubVC, animated:true)
    }
    
    //keyword view actions
    @IBAction func keywordBackButtonPressed(_ sender: Any) {
        self.keywordView.isHidden = true
        self.currentlyViewedKeyword = nil
        self.updatePlaybackProgress()
    }
    
    @IBAction func keywordSaveButtonPressed(_ sender: Any) {
        if let currentKeyword = self.currentlyViewedKeyword {
            KeywordFavoritesManager.sharedInstance.saveKeyword(currentKeyword)
            
            self.keywordSaveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(currentKeyword) ? true : false
            self.keywordRemoveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(currentKeyword) ? false : true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    @IBAction func keywordRemoveButtonPressed(_ sender: Any) {
        if let currentKeyword = self.currentlyViewedKeyword {
            KeywordFavoritesManager.sharedInstance.removeKeyword(currentKeyword)
            
            self.keywordSaveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(currentKeyword) ? true : false
            self.keywordRemoveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(currentKeyword) ? false : true
            
        }
    }
    
}

//MARK: transcripts and quizzes
extension EpisodePlayerViewController {
    //Transcipts
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
        if Auth.auth().currentUser?.email == "test@test.com" {
            self.showTranscriptView()
            return
        }
        
        guard let transcript = self.transcript else {
            //No valid transcript for episode
            self.showNonexistentTranscriptCoverImage()
            return
        }
        
        if transcript.isFree == true {
            self.showTranscriptView()
            return
        }
        
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
        
        //we have a transcript that isn't free, a user, and a valid subscription 
        self.showTranscriptView()
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
    
    //Quizes
    func fetchQuiz() {
        ServiceManager.sharedInstace.getQuizWithId("asdf") { (quizModel, error) in
            print("got it")
        }
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

//MARK: UITextViewDelegate
extension EpisodePlayerViewController:UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let parsedKeywordName = URL.absoluteString.removingPercentEncoding?.replacingOccurrences(of: "AEE://", with: "")
        
        guard let transcript = self.transcript else {
            return false
        }
        
        for keyword in transcript.keywords {
            if keyword.name == parsedKeywordName {
                self.currentlyViewedKeyword = keyword
                self.keywordView.isHidden = false
                self.keywordTitleLabel.text = keyword.name
                self.keywordDefinitionLabel.text = keyword.definition
                
                self.keywordSaveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(keyword) ? true : false
                self.keywordRemoveButton.isHidden = KeywordFavoritesManager.sharedInstance.containsKeyword(keyword) ? false : true
                
                Analytics.logEvent("keyword_view", parameters: ["keyword_name":keyword.name, "keyword_definition":keyword.definition])

                break
            }
        }
        
        return false
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
