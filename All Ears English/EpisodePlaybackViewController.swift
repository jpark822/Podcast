//
//  EpisodePlaybackViewController.swift
//  All Ears English
//
//  Created by Luis Artola on 7/15/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import MediaPlayer

class EpisodePlaybackViewController: UIViewController {

    @IBOutlet weak var episodeTitle: UILabel?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var volumeView: MPVolumeView?
    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var timeText: UILabel?
    @IBOutlet weak var remainingTimeText: UILabel?
    fileprivate var displayLink: CADisplayLink!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.volumeView?.showsRouteButton = false
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink.add(to: .current, forMode: .defaultRunLoopMode)
        self.updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlayButton), name: Player.PlayerPlaybackStateChange, object: Player.shared!)

    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Player.PlayerPlaybackStateChange, object: Player.shared!)
        displayLink.invalidate()
    }

    override func viewDidAppear(_ animated: Bool) {
        if self.view.frame.size.height < 568 {
            self.volumeView?.isHidden = true
        }
    }

    func updatePlayButton() {
        let playing = Player.shared?.playing ?? false
        if playing {
            self.playButton?.setImage(UIImage(named: "ic_pause_48pt"), for: UIControlState.normal)
        } else {
            self.playButton?.setImage(UIImage(named: "ic_play_arrow_48pt"), for: UIControlState.normal)
        }
    }

    func updateUI() {
        self.episodeTitle?.text = Player.shared?.item?.title
        self.updateProgress()
        self.updatePlayButton()
    }

    func updateProgress() {
        self.progressView?.progress = Player.shared?.progress ?? 0
        if let formattedTime = Player.shared?.formattedTime {
            self.timeText?.text = formattedTime.current
            self.remainingTimeText?.text = formattedTime.remaining
        }
    }

    @IBAction func shareEpisode(_ sender: Any) {
        let item = Player.shared?.item
        Player.shared?.shareEpisode(item, controller: self)
    }

    @IBAction func togglePlayback(_ sender: Any) {
        Player.shared?.togglePlayback()
    }

    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true)
    }

}
