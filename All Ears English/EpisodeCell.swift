//
//  EpisodeCell.swift
//  All Ears English
//
//  Created by Luis Artola on 6/22/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

protocol EpisodeCellDelegate:class {
    func episodeCellDidTapFavoriteButton(episodeCell:EpisodeCell)
    func episodeCellRequestDownload(episodeCell:EpisodeCell)
}

//episode cell begins configured for episodes. you must call "configureAsBonusItem" for the bonus screen
class EpisodeCell: UITableViewCell {

    @IBOutlet weak var episodeNumber: UILabel!
    @IBOutlet weak var episodeNumberContainerView: UIView!
    @IBOutlet weak var episodeTitle: UILabel!
    @IBOutlet weak var episodeDetails: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var mediaItemTypeImageView: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var coverImageView: UIImageView!
    
    //dependencies
    var delegate:EpisodeCellDelegate?
    var indexPath:IndexPath!

    static let preferredDetailHeight:CGFloat = 100
    var item: Feed.Item? {
        didSet {
            guard let item = item else {
                return
            }
            self.episodeNumber.text = item.number
            self.episodeTitle.text = item.displayTitle
            self.episodeDetails.text = item.displayDetails
            
            //download/delete button state control
            if Cache.shared.isCurrentlyDownloadingItem(item) {
                self.changeDownloadButtonToActivityIndicator()
            }
            else if Cache.shared.get(item) != nil {
                self.changeDownloadButtonToTrash()
            }
            else {
                self.changeDownloadButtonToCloud()
            }
            
            //favorite button states
            if FavoritesManager.isItemInFavorites(item: item) {
                let filledHeartImage = UIImage(named:"ic_heart_filled")?.withRenderingMode(.alwaysTemplate)
                self.favoriteButton.tintColor = UIColor.red
                self.favoriteButton.setImage(filledHeartImage, for: .normal)
            }
            else {
                let unfilledHeartImage = UIImage(named:"ic_heart_unfilled")?.withRenderingMode(.alwaysTemplate)
                self.favoriteButton.tintColor = UIColor.black
                self.favoriteButton.setImage(unfilledHeartImage, for: .normal)
            }
            
            //setting the main image
            if let episodeNumber = item.number, !episodeNumber.isEmpty,
                let imageUrl = URL(string: "https://s3.amazonaws.com/episode-banner-image/\(episodeNumber).jpg") {
                
                self.coverImageView.af_setImage(withURL: imageUrl, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                    if response.result.value == nil {
                        //there is no dedicated image or it failed
                        self.coverImageView.image = UIImage(named: "episode_stub_image")
                    }
                })
            }
            else {
                //there isnt a number, so show a default image
                self.coverImageView.image = UIImage(named: "episode_stub_image")
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
        self.episodeNumberContainerView.backgroundColor = UIColor.AEEBonusPink
        self.mediaItemTypeImageView.isHidden = false
        self.favoriteButton.isHidden = true
        
        if item.isVideoContent {
            self.mediaItemTypeImageView.image = UIImage(named: "ic_video_item")
        }
        else {
            self.mediaItemTypeImageView.image = UIImage(named: "ic_audio_item")
        }
        
        self.coverImageView.image = UIImage(named: "episode_stub_image")
    }

    @IBAction func downloadPressed(_ sender: Any) {
        guard let item = self.item else {
            return
        }
        
        //item already downloaded which means we're deleting
        if Cache.shared.get(item) != nil {
            Cache.shared.delete(item: item, completion: { (success) in
                if success == true && self.item?.guid == item.guid {
                    self.changeDownloadButtonToCloud()
                }
            })
        }
        //item doesn't exist so download it
        else {
            self.changeDownloadButtonToActivityIndicator()
            
            if let delegate = self.delegate {
                delegate.episodeCellRequestDownload(episodeCell: self)
            }
        }
    }
    
    func changeDownloadButtonToTrash() {
        DispatchQueue.main.async {
            self.downloadActivityIndicator.stopAnimating()
            self.downloadActivityIndicator.isHidden = true
            
            self.downloadButton.setImage(UIImage(named:"ic_trash"), for: .normal)
            self.downloadButton.isHidden = false
        }
    }
    func changeDownloadButtonToCloud() {
        DispatchQueue.main.async {
            self.downloadActivityIndicator.stopAnimating()
            self.downloadActivityIndicator.isHidden = true
            
            self.downloadButton.setImage(UIImage(named:"ic_cloud_download_white"), for: .normal)
            self.downloadButton.isHidden = false
        }
    }
    
    func changeDownloadButtonToActivityIndicator() {
        DispatchQueue.main.async {
            self.downloadActivityIndicator.startAnimating()
            self.downloadActivityIndicator.isHidden = false
            self.downloadButton.isHidden = true
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
        self.mediaItemTypeImageView.isHidden = true
        self.favoriteButton.isHidden = false
        self.episodeNumberContainerView.backgroundColor = UIColor.AEEYellow
        
        self.downloadActivityIndicator.isHidden = true
        
        self.coverImageView.image = nil
        self.coverImageView.backgroundColor = UIColor.clear
    }

}

