//
//  PurchaseCarouselCollectionViewCell.swift
//  All Ears English
//
//  Created by Jay Park on 5/17/20.
//  Copyright © 2020 All Ears English. All rights reserved.
//

import UIKit

class PurchaseCarouselCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var mainImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(purchaseCarouselModel:PurchaseCarouselModel) {
        self.mainImageView.image = purchaseCarouselModel.heroImage
        self.backgroundColor = purchaseCarouselModel.backgroundColor
    }
    
}
