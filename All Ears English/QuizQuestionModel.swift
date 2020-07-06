//
//  QuizQuestionModel.swift
//  All Ears English
//
//  Created by Jay Park on 5/4/20.
//  Copyright © 2020 All Ears English. All rights reserved.
//

import Foundation

struct QuizQuestionModel:Codable {
    let questionText:String
    let answerOptions:[String]
    let answer:String
}
