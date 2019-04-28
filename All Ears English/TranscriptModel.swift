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
    
    let keywords:[KeywordModel]
    
    init(jsonDict:[String:Any]) {
        self.id = jsonDict["id"] as? String ?? ""
        self.isFree = jsonDict["isFree"] as? Bool ?? false
        self.fullTranscript = jsonDict["fullText"] as? String ?? ""
        
        if let segmentArray = jsonDict["phrases"] as? [[String:Any]] {
            self.segments = TranscriptSegment.transcriptSegmentsForJsonArray(jsonArray: segmentArray)
        }
        else {
            self.segments = []
        }
        
        if let keywordArray = jsonDict["keywords"] as? [[String:Any]] {
            self.keywords = KeywordModel.keywordModelsForJsonArray(keywordArray)
        }
        else {
            self.keywords = []
        }
        
        
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
    
    init(jsonDict:[String:Any]) {
        self.name = jsonDict["name"] as? String ?? ""
        self.definition = jsonDict["definition"] as? String ?? ""
    }
    
    static func keywordModelsForJsonArray(_ jsonArray:[[String:Any]]) -> [KeywordModel] {
        var keywordModels = [KeywordModel]()
        for jsonDict in jsonArray {
            let keywordModel = KeywordModel(jsonDict: jsonDict)
            keywordModels.append(keywordModel)
        }
        return keywordModels
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.definition = try container.decodeIfPresent(String.self, forKey: .definition) ?? ""
    }
}
