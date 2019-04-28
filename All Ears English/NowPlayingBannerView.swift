//
//  NowPlayingBannerView.swift
//  All Ears English
//
//  Created by Jay Park on 10/4/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

protocol NowPlayingBannerViewDelegate:class {
    func nowPlayingBannerViewWasTapped(nowPlayingBannerView: NowPlayingBannerView)
}

class NowPlayingBannerView : UIView {
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var episodesTitleLabel: UILabel!
    
    var delegate:NowPlayingBannerViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("NowPlayingBannerView", owner: self, options: nil)
        self.addSubview(self.view)
        self.view.frame = self.bounds
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        let views:[String:UIView] = ["view":self.view]
        var allConstraints = [NSLayoutConstraint]()
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views)
        allConstraints += horizontalConstraints
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)
        allConstraints += verticalConstraints
        
        NSLayoutConstraint.activate(allConstraints)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTappedHandler(recognizer:)))
        self.view .addGestureRecognizer(tapGestureRecognizer)
    }
    
    @IBAction func playPressed(_ sender: Any) {
        if AudioPlayer.sharedInstance.isPlaying {
            AudioPlayer.sharedInstance.pause()
        }
        else {
            AudioPlayer.sharedInstance.play()
        }
    }
    
    func updateControlViews() {
        if let currentAudioPlayerItem = AudioPlayer.sharedInstance.currentItem {
            self.episodesTitleLabel.text = currentAudioPlayerItem.title
        }
        
        if AudioPlayer.sharedInstance.isPlaying {
            self.playButton.setImage(UIImage(named: "ic_pause_white"), for: UIControl.State.normal)
        }
        else {
            self.playButton.setImage(UIImage(named: "ic_play_arrow_white"), for: UIControl.State.normal)
        }
    }
    
    @objc func viewTappedHandler(recognizer:UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.nowPlayingBannerViewWasTapped(nowPlayingBannerView: self)
        }
    }
}
