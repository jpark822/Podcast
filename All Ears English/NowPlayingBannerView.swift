//
//  NowPlayingBannerView.swift
//  All Ears English
//
//  Created by Jay Park on 10/4/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import Foundation
import UIKit

class NowPlayingBannerView : UIView {
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var playButton: UIButton!
    
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
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    
    @IBAction func playPressed(_ sender: Any) {
        print("press play")
    }
    
}
