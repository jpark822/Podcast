//
//  ServiceManager.swift
//  All Ears English
//
//  Created by Jay Park on 7/2/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import UIKit
import Alamofire
import Firebase
import FirebaseAuth


class ServiceManager: NSObject {
    static let sharedInstace = ServiceManager()
    
    var sessionManager = SessionManager(configuration: .default)
    
    func getTranscriptWithId(_ episodeGuid:String, completion:@escaping (TranscriptModel?, Error?)->Void) {
        
        let url = Auth.auth().currentUser?.email == "test@test.com" ? "https://s3.amazonaws.com/allearsenglish-mobileapp/test-transcripts/\(episodeGuid).json" : "https://s3.amazonaws.com/allearsenglish-mobileapp/transcripts/\(episodeGuid).json"
        
        Alamofire.request(url).validate().responseJSON { (response) in
            switch response.result{
            case .failure(let error):
                completion(nil, error)
                return
            case .success(let value):
                guard let responseDict = value as? [String:Any] else {
                    completion(nil, NSError(domain: "AEE", code: -999, userInfo: [NSLocalizedDescriptionKey:"parsing error"]))
                    return
                }
                let transcriptModel = TranscriptModel(jsonDict: responseDict)
                completion(transcriptModel, nil)
                return
            }
        }
    }
}
