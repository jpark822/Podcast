//
//  ServiceManager.swift
//  All Ears English
//
//  Created by Jay Park on 7/2/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import Alamofire


class ServiceManager: NSObject {
    static let sharedInstace = ServiceManager()
    
    var sessionManager = SessionManager(configuration: .default)
    
    func getTranscriptWithId(_ episodeGuid:String, completion:@escaping (TranscriptModel?, Error?)->Void) {
        if let path = Bundle.main.path(forResource: "exampleTranscript", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String:Any]
                let transcriptModel = TranscriptModel(jsonDict: jsonObj)
                completion(transcriptModel, nil)
                
            }
            catch let error {
                print("parse error: \(error.localizedDescription)")
                completion(nil, nil)
            }
        }
        else {
            print("Invalid filename/path.")
            completion(nil, nil)
        }
    }
}
