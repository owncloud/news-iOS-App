//
//  SummaryValueTransformer.swift
//  CloudNews
//
//  Created by Peter Hedlund on 12/21/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Cocoa
import SwiftSoup

class SummaryValueTransformer: ValueTransformer {

    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return false
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let summaryValue = value as? NSString else {
            return "No Summary"
        }

        var summary: String = summaryValue as String
        if summary.range(of: "<style>", options: .caseInsensitive) != nil {
            if summary.range(of: "</style>", options: .caseInsensitive) != nil {
                if let start = summary.range(of:"<style>", options: .caseInsensitive)?.lowerBound,
                    let end = summary.range(of: "</style>", options: .caseInsensitive)?.upperBound {
                    let sub = summary[start..<end]
                    summary = summary.replacingOccurrences(of: sub, with: "")
                }
            }
        }
        let result = plainSummary(raw: summary)

        return result
    }

//    private func plainSummary(raw: String) -> String {
//        guard let doc: Document = try? SwiftSoup.parse(raw) else {
//            return raw
//        } // parse html
//        guard let txt = try? doc.text() else {
//            return raw
//        }
//        return txt
//    }

}

class TitleValueTransformer: ValueTransformer {

    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return false
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let titleValue = value as? NSString else {
            return "No Title"
        }

        let result = plainSummary(raw: titleValue as String)
        return result
    }

//    private func plainSummary(raw: String) -> String {
//        guard let doc: Document = try? SwiftSoup.parse(raw) else {
//            return raw
//        } // parse html
//        guard let txt = try? doc.text() else {
//            return raw
//        }
//        return txt
//    }
//
}


extension NSValueTransformerName {
    static let summaryValueTransformerName = NSValueTransformerName(rawValue: "SummaryValueTransformer")
    static let titleValueTransformerName = NSValueTransformerName(rawValue: "TitleValueTransformer")
}

fileprivate func plainSummary(raw: String) -> String {
    guard let doc: Document = try? SwiftSoup.parse(raw) else {
        return raw
    } // parse html
    guard let txt = try? doc.text() else {
        return raw
    }
    return txt
}
