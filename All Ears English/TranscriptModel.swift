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
    
    let keywords:[KeywordModel] = [KeywordModel(name: "all ears english", definition: "title of this podcast"), KeywordModel(name: "episode", definition: "a single instance of an episode on this podcast a single instance of an episode on this podcast a single instance of an episode on this podcast a single instance of an episode on this podcast")]
    
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

struct KeywordModel:Codable, Equatable, Hashable {
    let name:String
    let definition:String
    
    enum CodingKeys:String, CodingKey {
        case name
        case definition
    }
    
    init(name:String, definition:String) {
        self.name = name
        self.definition = definition
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.definition = try container.decodeIfPresent(String.self, forKey: .definition) ?? ""
    }
}
