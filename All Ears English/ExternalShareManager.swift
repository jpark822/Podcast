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
//                  the original code logged event
//                DispatchQueue.main.async {
//                    let method = activityType?.rawValue ?? "Default"
//                    self.logEventShareEpisode(withMethod: method)
//                }
            }
        }
        
        fromController.present(controller, animated: true)
    }

}
