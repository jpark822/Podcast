//
//  FavoriteKeywordTableViewCell.swift
//  All Ears English
//
//  Created by Jay Park on 4/6/19.
//  Copyright © 2019 All Ears English. All rights reserved.
//

import UIKit

protocol FavoriteKeywordTableViewCellDelegate:class {
    func favoriteKeywordTableViewCellDidDeleteKeyword()
}

class FavoriteKeywordTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var definitionLabel: UILabel!
    
    @IBOutlet weak var keywordInnerView: UIView!
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var definitionView: UIView!
    
    weak var delegate:FavoriteKeywordTableViewCellDelegate?
    
    fileprivate var keywordModel:KeywordModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.keywordInnerView.layer.borderWidth = 1
        self.keywordInnerView.layer.borderColor = UIColor.darkGray.cgColor
        
    }
    
    func configureWithKeyword(_ keyword:KeywordModel) {
        self.nameLabel.text = keyword.name
        self.definitionLabel.text = keyword.definition
        
        self.keywordModel = keyword
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        if let keyword = self.keywordModel {
            KeywordFavoritesManager.sharedInstance.removeKeyword(keyword)
            self.delegate?.favoriteKeywordTableViewCellDidDeleteKeyword()
        }
    }
    
}
