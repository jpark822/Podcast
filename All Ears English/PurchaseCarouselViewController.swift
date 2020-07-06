//
//  PurchaseCarouselViewController.swift
//  All Ears English
//
//  Created by Jay Park on 5/17/20.
//  Copyright © 2020 All Ears English. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

protocol PurchaseCarouselViewControllerDelegate:class {
    func purchaseCarouselViewControllerDidPressContinue(viewController:PurchaseCarouselViewController)
    func purchaseCarouselViewControllerDidCancel(viewController:PurchaseCarouselViewController)
}

class PurchaseCarouselViewController: UIViewController {
    
    @IBOutlet weak var carouselDescriptionLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate:PurchaseCarouselViewControllerDelegate?
    
    var carouselModels:[PurchaseCarouselModel] = [] {
        didSet {
            guard self.isViewLoaded else {
                return
            }
            
            let currentPage = Int(self.collectionView.contentOffset.x / self.collectionView.frame.width)
            let carouselModel = self.carouselModels[currentPage]
            self.carouselDescriptionLabel.text = carouselModel.descriptionText
            
            self.collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.setupCollectionViewData()
        
        self.styleView()
    }
    
    private func styleView() {
        self.pageControl.pageIndicatorTintColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1)
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        
        self.signupButton.layer.cornerRadius = 10
    }
    
    private func setupCollectionViewData() {
        let backgroundGray = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 0.8)
        
        let promoWelcomeModel = PurchaseCarouselModel(descriptionText: "Subscribe to unlock episode transcripts and keywords", heroImage: UIImage(named: "purchaseCarouselPromo"), backgroundColor: .white)
        let promoTranscriptsModel = PurchaseCarouselModel(descriptionText: "Learn with transcripts", heroImage: UIImage(named: "purchaseCarouselTranscripts"), backgroundColor: backgroundGray)
        let promoKeywordModel = PurchaseCarouselModel(descriptionText: "Tap a word or phrase to learn the meaning", heroImage: UIImage(named: "purchaseCarouselKeyword"), backgroundColor: backgroundGray)
        let promoKeywordDetailModel = PurchaseCarouselModel(descriptionText: "Save vocabulary you want to remember", heroImage: UIImage(named: "purchaseCarouselKeywordDetail"), backgroundColor: backgroundGray)
        let promoBankModel = PurchaseCarouselModel(descriptionText: "Study your vocabulary at any time", heroImage: UIImage(named: "purchaseCarouselBank"), backgroundColor: backgroundGray)
        
        self.carouselModels = [promoWelcomeModel, promoTranscriptsModel, promoKeywordModel, promoKeywordDetailModel, promoBankModel]
        
        self.pageControl.numberOfPages = self.carouselModels.count
    }
    
    @IBAction func closePressed(_ sender: Any) {
        self.delegate?.purchaseCarouselViewControllerDidCancel(viewController: self)
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        self.delegate?.purchaseCarouselViewControllerDidPressContinue(viewController: self)
    }
    
}

//MARK: collection view delegate and data source
extension PurchaseCarouselViewController:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.carouselModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PurchaseCarouselCollectionViewCellId", for: indexPath) as! PurchaseCarouselCollectionViewCell
        let carouselModel = self.carouselModels[indexPath.row]
        cell.configureWith(purchaseCarouselModel: carouselModel)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPage = Int(scrollView.contentOffset.x / scrollView.frame.width)
        
        guard currentPage < self.carouselModels.count else {
            return
        }
        
        self.pageControl.currentPage = currentPage
        let carouselModel = self.carouselModels[currentPage]
        
        let lowerBoundContentOffset = CGFloat(self.pageControl.currentPage) * self.collectionView.frame.size.width
        
        let relativeContentOffset = self.collectionView.contentOffset.x - lowerBoundContentOffset
        let midpointContentOffset = self.collectionView.frame.size.width / 2.0
        
        let distanceFromMidpoint = relativeContentOffset - midpointContentOffset
        let percentDistanceFromMidpoint = abs(distanceFromMidpoint)/midpointContentOffset
        self.carouselDescriptionLabel.alpha = percentDistanceFromMidpoint
        
        self.carouselDescriptionLabel.text = carouselModel.descriptionText
        
        //If we're not on the last page, and we're on the latter half of scrolling between pages
        guard currentPage < self.carouselModels.count - 1,
            distanceFromMidpoint > 0 else {
            return
        }
        
        let nextOnboardingModel = self.carouselModels[currentPage + 1]
        self.pageControl.currentPage = currentPage + 1
        self.carouselDescriptionLabel.text = nextOnboardingModel.descriptionText
    }
    
}

