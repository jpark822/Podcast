//
//  String+AEE.swift
//  All Ears English
//
//  Created by Jay Park on 4/2/19.
//  Copyright © 2019 All Ears English. All rights reserved.
//

import Foundation

//extension String {
//    func indices(of occurrence: String) -> [Int] {
//        var indices = [Int]()
//        var position = startIndex
//        while let range = range(of: occurrence, range: position..<endIndex) {
//            let i = distance(from: startIndex,
//                             to: range.lowerBound)
//            indices.append(i)
//            let offset = occurrence.distance(from: occurrence.startIndex,
//                                             to: occurrence.endIndex) - 1
//            guard let after = index(range.lowerBound,
//                                    offsetBy: offset,
//                                    limitedBy: endIndex) else {
//                                        break
//            }
//            position = index(after: after)
//        }
//        return indices
//    }
//}
//
//extension String {
//    func ranges(of searchString: String) -> [Range<String.Index>] {
//        let _indices = indices(of: searchString)
//        let count = searchString.count
//        return _indices.map({ index(startIndex, offsetBy: $0)..<index(startIndex, offsetBy: $0+count) })
//    }
//}

extension StringProtocol where Index == String.Index {
    func nsRange(of string: Self, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> NSRange? {
        guard let range = self.range(of: string, options: options, range: range ?? startIndex..<endIndex, locale: locale ?? .current) else { return nil }
        return NSRange(range, in: self)
    }
    func nsRanges(of string: Self, options: String.CompareOptions = [], range: Range<Index>? = nil, locale: Locale? = nil) -> [NSRange] {
        var start = range?.lowerBound ?? startIndex
        let end = range?.upperBound ?? endIndex
        var ranges: [NSRange] = []
        while start < end, let range = self.range(of: string, options: options, range: start..<end, locale: locale ?? .current) {
            ranges.append(NSRange(range, in: self))
            start = range.upperBound
        }
        return ranges
    }
}
