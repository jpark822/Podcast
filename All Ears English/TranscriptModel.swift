//
//  TranscriptModel.swift
//  All Ears English
//
//  Created by Jay Park on 7/2/18.
//  Copyright © 2018 All Ears English. All rights reserved.
//

import Foundation

struct TranscriptModel {
    let id:String
    let fullTranscript:String
    let isFree:Bool
    
    let segments:[TranscriptSegment]
    
    let keywords = ["all ears english", "episode"]
    
    init(jsonDict:[String:Any]) {
        self.id = jsonDict["id"] as? String ?? ""
        self.isFree = jsonDict["isFree"] as? Bool ?? false
        self.fullTranscript = jsonDict["fullText"] as? String ?? ""
        
        guard let segmentArray = jsonDict["phrases"] as? [[String:Any]] else {
            self.segments = []
            return
        }
        
        self.segments = TranscriptSegment.transcriptSegmentsForJsonArray(jsonArray: segmentArray)
    }
}

struct TranscriptSegment {
    let timeStamp:Double
    let startRange:Int
    let endRange:Int
    
    init(jsonDict:[String:Any]) {
        self.timeStamp = jsonDict["timestamp"] as? Double ?? -1.0
        guard let rangeDict = jsonDict["range"] as? [String:Int] else {
            self.startRange = -1
            self.endRange = -1
            return
        }
        
        self.startRange = rangeDict["start"] ?? -1
        self.endRange = rangeDict["end"] ?? -1
    }
    
    static func transcriptSegmentsForJsonArray(jsonArray:[[String:Any]]) -> [TranscriptSegment] {
        var parsedSegments = [TranscriptSegment]()
        for jsonDict in jsonArray {
            let segmentModel = TranscriptSegment(jsonDict: jsonDict)
            parsedSegments.append(segmentModel)
        }
        return parsedSegments
    }
}
