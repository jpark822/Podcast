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

class EpisodeCell: UITableViewCell {

    @IBOutlet weak var episodeNumber: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var episodeDetails: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
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
                self.favoriteButton.setTitle("Un-Fave", for: .normal)
            }
            else {
                self.favoriteButton.setTitle("Favorite", for: .normal)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func favoritesButtonPressed(_ sender: Any) {
        if let delegate = self.delegate {
            delegate.episodeCellDidTapFavoriteButton(episodeCell: self)
        }
    }

}
