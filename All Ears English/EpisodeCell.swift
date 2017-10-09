//
//  EpisodeCell.swift
//  All Ears English
//
//  Created by Luis Artola on 6/22/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class EpisodeCell: UITableViewCell {

    @IBOutlet weak var episodeNumber: UILabel!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var episodeDetails: UILabel!

    var item: Feed.Item? {
        didSet {
            self.episodeNumber.text = item?.number
            self.episodeTitle.text = item?.displayTitle
            self.episodeDetails.text = item?.displayDetails
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
