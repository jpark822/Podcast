//
//  ExternalShareManager.swift
//  All Ears English
//
//  Created by Jay Park on 10/12/17.
//  Copyright © 2017 All Ears English. All rights reserved.
//

import UIKit

class ExternalShareManager: NSObject {
    
    static let sharedInstance = ExternalShareManager()
    
    func presentShareControllerFromViewController(fromController:UIViewController, title:String, urlString:String?, image:UIImage?) {
        
        AnalyticsManager.sharedInstance.logMixpanelShareBegin()
        
        var activityItems:[Any] = [title]
        if let urlString = urlString,
            let url = URL(string: urlString) {
            activityItems.append(url)
        }
        if let image = image {
            activityItems.append(image)
        }
        
        let controller = UIActivityViewController.init(activityItems: activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print
        ]
        controller.completionWithItemsHandler = {
            (activityType, completed, returnedItems, activityError) in
            if completed {
                AnalyticsManager.sharedInstance.logMixpanelShareSuccess()
            }
        }
        
        fromController.present(controller, animated: true)
    }

}
