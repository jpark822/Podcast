//
//  EpisodeCell.swift
//  All Ears English
//
//  Created by Luis Artola on 6/22/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

protocol EpisodeCellDelegate:class {
    func episodeCellDidTapFavoriteButton(episodeCell:EpisodeCell)
}

//episode cell begins configured for episodes. you must call "configure as favorite" when coming from a favorited item
class EpisodeCell: UITableViewCell {

    @IBOutlet weak var episodeNumber: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var episodeDetails: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var favoritesItemTypeImageView: UIImageView!
    
    //dependencies
    var delegate:EpisodeCellDelegate?
    var indexPath:IndexPath!

    var item: Feed.Item? {
        didSet {
            guard let item = item else {
                return
            }
            self.episodeNumber.text = item.number
            self.episodeTitle.text = item.displayTitle
            self.episodeDetails.text = item.displayDetails
            if FavoritesManager.isItemInFavorites(item: item) {
                self.favoriteButton.setImage(UIImage(named:"ic_heart_filled"), for: .normal)
            }
            else {
                self.favoriteButton.setImage(UIImage(named:"ic_heart_unfilled"), for: .normal)
            }
            
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureAsBonusItem() {
        guard let item = item,
        let mediaType = item.type else {
            return
        }
        
        guard mediaType.isEmpty == false else {
            return
        }
        
        self.episodeNumber.isHidden = true
        self.favoritesItemTypeImageView.isHidden = false
        
        if item.isVideoContent {
            self.favoritesItemTypeImageView.image = UIImage(named: "ic_video_item")
            self.favoriteButton.isHidden = true
        }
        else {
            self.favoritesItemTypeImageView.image = UIImage(named: "ic_audio_item")
        }
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func favoritesButtonPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.episodeCellDidTapFavoriteButton(episodeCell: self)
        }
    }
    
    override func prepareForReuse() {
        self.episodeNumber.isHidden = false
        self.favoritesItemTypeImageView.isHidden = true
        self.favoriteButton.isHidden = false
    }

}
