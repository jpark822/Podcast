//
//  BannerView.swift
//  All Ears English
//
//  Created by Luis Artola on 7/12/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class BannerView: UIView {

    @IBOutlet weak var presentingController: UIViewController?
    @IBOutlet weak var episodeTitle: UILabel?
    @IBOutlet weak var playButton: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
        self.update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupView()
        self.update()
    }
    
    private func setupView() {
        let view = viewFromNibForClass()
        view.frame = bounds
        view.autoresizingMask = [
            UIViewAutoresizing.flexibleWidth,
            UIViewAutoresizing.flexibleHeight
        ]
        addSubview(view)
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(recognizer)
    }
    
    func tap(_ sender: UIGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "EpisodePlaybackViewController")
        self.presentingController?.present(controller, animated: true)
    }
    
    private func viewFromNibForClass() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    func addPlaybackObserver() {
        if let player = Player.shared {
            NotificationCenter.default.addObserver(self, selector: #selector(updateDetails), name: Player.PlayerItemChange, object: player)
            NotificationCenter.default.addObserver(self, selector: #selector(updatePlayButton), name: Player.PlayerPlaybackStateChange, object: player)
        }
    }
    
    func removePlaybackObserver() {
        if let player = Player.shared {
            NotificationCenter.default.removeObserver(self, name: Player.PlayerItemChange, object: player)
            NotificationCenter.default.removeObserver(self, name: Player.PlayerPlaybackStateChange, object: player)
        }
    }
    
    func update() {
        self.updateDetails()
        self.updatePlayButton()
    }
    
    func updateDetails() {
        guard let item = Player.shared?.item else {
            UIView.animate(withDuration: 0.15, animations: {
                self.alpha = 0
            })
            return
        }
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 1
        })
        self.episodeTitle?.text = item.title
    }
    
    func updatePlayButton() {
        if Player.shared?.playing ?? false {
            self.playButton?.setImage(UIImage(named: "ic_pause_white"), for: UIControlState.normal)
        } else {
            self.playButton?.setImage(UIImage(named: "ic_play_arrow_white"), for: UIControlState.normal)
        }
    }
    
    @IBAction func togglePlayback(_ sender: Any) {
        Player.shared?.togglePlayback()
    }
    
}
