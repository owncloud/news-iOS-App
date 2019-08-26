//
//  Readable.swift
//  CloudNews
//
//  Created by Peter Hedlund on 8/24/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation
import SwiftSoup

struct ReadableData {
    public let title: String
    public let description: String?
    public let text: String?
    public let image: String?
    public let video: String?
    public let keywords: [String]?
}

fileprivate struct Pattern {
    static let unlikely = "com(bx|ment|munity)|dis(qus|cuss)|e(xtra|[-]?mail)|foot|"
        + "header|menu|re(mark|ply)|rss|sh(are|outbox)|sponsor|"
        + "a(d|ll|gegate|rchive|ttachment)|(pag(er|ination))|popup|print|"
        + "login|si(debar|gn|ngle)"

    static let positive = "(^(body|content|h?entry|main|page|post|text|blog|story|haupt))"
        + "|arti(cle|kel)|instapaper_body"

    static let negative = "nav($|igation)|user|com(ment|bx)|(^com-)|contact|"
        + "foot|masthead|(me(dia|ta))|outbrain|promo|related|scroll|(sho(utbox|pping))|"
        + "sidebar|sponsor|tags|tool|widget|player|disclaimer|toc|infobox|vcard|post-ratings"

    static let elements = "p|div|td|h1|h2|article|section"
}

class Readable {

    var unlikelyRegExp: NSRegularExpression?
    var positiveRegExp: NSRegularExpression?
    var negativeRegExp: NSRegularExpression?
    var nodesRegExp: NSRegularExpression?

    var highestPriorityElement: Element?
    var document: Document?

    class func parse(_ html: String) -> ReadableData? {
        let parser = Readable()
        return parser.parseHtml(html)
    }

    func parseHtml(_ html: String) -> ReadableData? {
        guard let document = try? SwiftSoup.parse(html) else {
            return nil
        }
        self.document = document

        processDocument()

        return ReadableData(title: self.title() ?? "Untitled",
                            description: description(),
                            text: text(),
                            image: image(),
                            video: video(),
                            keywords: keywords())
    }

    private func processDocument() {
        var highestPriority = 0
        do {
            try unlikelyRegExp = NSRegularExpression(pattern: Pattern.unlikely, options: .caseInsensitive)
            try positiveRegExp = NSRegularExpression(pattern: Pattern.positive, options: .caseInsensitive)
            try negativeRegExp = NSRegularExpression(pattern: Pattern.negative, options: .caseInsensitive)
            try nodesRegExp = NSRegularExpression(pattern: Pattern.elements, options: .caseInsensitive)
        }
        catch { }

        if let body = self.document?.body() {
            let children = body.children().array()
            for child in children {
                var weight = elementWeight(element: child)
                guard let stringValue = try? child.text() else {
                    continue
                }
                weight += stringValue.count / 10

                weight += childElementWeight(element: child)
                if (weight > highestPriority) {
                    highestPriority = weight
                    highestPriorityElement = child
                }

                if weight > 200 {
                    break
                }
            }
        }
    }

    private func elementWeight(element: Element) -> Int {
        var weight = 0
        do {
            let className = try element.className()
            let range = NSRange(location: 0, length: className.count)
            if let positiveRegExp = positiveRegExp,
                positiveRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight += 35
            }

            if let unlikelyRegExp = unlikelyRegExp,
                unlikelyRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight -= 20
            }

            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: className, options: .reportProgress, range: range).count > 0 {
                weight -= 50
            }

            let id = element.id()
            let idRange = NSMakeRange(0, id.count)
            if let positiveRegExp = positiveRegExp,
                positiveRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight += 40
            }

            if let unlikelyRegExp = unlikelyRegExp,
                unlikelyRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight -= 20
            }

            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: id, options: .reportProgress, range: idRange).count > 0 {
                weight -= 50
            }

            let style = try element.select("style").text()
            if let negativeRegExp = negativeRegExp,
                negativeRegExp.matches(in: style, options: .reportProgress, range: NSMakeRange(0, style.count)).count > 0 {
                weight -= 50
            }
        } catch { }

        return weight
    }

    private func childElementWeight(element: Element) -> Int {
        var weight = 0

        for child in element.children().array() {
            guard let text = try? child.text() else {
                return weight
            }

            let count = text.count
            if count < 20 {
                return weight
            }

            if count > 200 {
                weight += max(50, count / 10)
            }

            let tagName = element.tagName()
            if tagName == "h1" || tagName == "h2" {
                weight += 30
            } else if tagName == "div" || tagName == "p" {
                weight += calcWeightForChild(text: text)

                if let _ = try? element.className().lowercased() == "caption" {
                    weight += 30
                }
            }
        }

        return weight
    }

    private func calcWeightForChild(text: String) -> Int {
        var c = text.countInstances(of: "&quot;")
        c += text.countInstances(of: "&lt;")
        c += text.countInstances(of: "&gt;")
        c += text.countInstances(of: "px")

        var val = 0
        if c > 5 {
            val = -30
        } else {
            val = Int(Double(text.count) / 25.0)
        }

        return val
    }

    private func determineImageSource(element: Element) -> Element? {
        var maxImgWeight = 20.0
        var maxImgNode: Element?

        do {
            var imageNodes = try element.select("img")
            if imageNodes.array().isEmpty,
                let parent = element.parent() {
                imageNodes = try parent.select("img")
            }

            var score = 1.0


            for imageNode in imageNodes {
                guard let url = try? imageNode.select("src").text() else {
                    return nil
                }

                if url.countInstances(of: "ad") > 2 { //most likely an ad
                    return nil
                }

                var weight = Double(imageSizeWeight(element: imageNode) +
                    imageAltWeight(element: imageNode) +
                    imageTitleWeight(element: imageNode))

                if let parent = imageNode.parent(),
                    let _ = try? parent.attr("rel") {
                    weight -= 40.0
                }

                weight = weight * score

                if weight > maxImgWeight {
                    maxImgWeight = weight
                    maxImgNode = imageNode
                    score = score / 2.0
                }
            }
        } catch { }

        return maxImgNode
    }

    private func imageSizeWeight(element: Element) -> Int {
        var weight = 0
        if let widthStr = try? element.attr("width"),
            let width = Int(widthStr) {
            if width >= 50 {
                weight += 20
            }
            else {
                weight -= 20
            }
        }

        if let heightStr = try? element.attr("height"),
            let height = Int(heightStr) {
            if height >= 50 {
                weight += 20
            }
            else {
                weight -= 20
            }
        }
        return weight
    }

    private func imageAltWeight(element: Element) -> Int {
        var weight = 0
        if let altStr = try? element.attr("alt") {
            if (altStr.count > 35) {
                weight = 20
            }
        }
        return weight
    }

    private func imageTitleWeight(element: Element) -> Int {
        var weight = 0
        if let titleStr = try? element.attr("title") {
            if (titleStr.count > 35) {
                weight = 20
            }
        }
        return weight
    }

    private func extractText(element: Element) -> String?
    {
//        guard let strValue = clearNodeContent(node) else {
//            return .none
//        }
//
//        let texts = strValue.replacingOccurrences(of: "\t", with: "").components(separatedBy: CharacterSet.newlines)
//        var importantTexts = [String]()
//        let extractedTitle = title()
//        texts.forEach({ (text: String) in
//            let length = text.count
//
//            if let titleLength = extractedTitle?.count {
//                if length > titleLength {
//                    importantTexts.append(text)
//                }
//
//            } else if length > 100 {
//                importantTexts.append(text)
//            }
//        })
//        return importantTexts.first?.trim()
        return nil
    }

    private func extractFullText(element: Element) -> String?
    {
        guard let elementText = try? element.text() else {
            return  nil
        }

        let texts = elementText.replacingOccurrences(of: "\t", with: "").components(separatedBy: .newlines)
        var importantTexts = [String]()
        texts.forEach({ (text: String) in
            let length = text.count
            if length > 175 {
                importantTexts.append(text)
            }
        })

        var fullText = importantTexts.reduce("", { $0 + "\n" + $1 })
        lowContentChildren(element: element).forEach { lowContent in
            fullText = fullText.replacingOccurrences(of: lowContent, with: "")
        }

        return fullText
    }

    private func lowContentChildren(element: Element) -> [String] {
        var contents = [String]()
        do {
            if element.children().array().isEmpty {
                let content = try element.text()
                let length = content.count
                if length > 3 && length < 175 {
                    contents.append(content)
                }
            }
            element.children().array().forEach { childNode in
                contents.append(contentsOf: lowContentChildren(element: childNode))
            }
        } catch { }
        return contents
    }

    private func extractValueUsing(path: String, attribute: String?) -> String? {

//        guard let nodes = document.xPath(path) else {
//            return .none
//        }
//
//        if nodes.count == 0 {
//            return .none
//        }
//
//        if let node = nodes.first {
//
//            // Valid attribute
//            if let attribute = attribute {
//                if let attrNode = node.attributes[attribute] {
//                    return attrNode
//                }
//            }
//                // Not using attribute
//            else {
//                return node.content
//            }
//        }

        return nil
    }

    private func extractValuesUsing(path: String, attribute: String?) -> [String]? {
        var values: [String]?

//        let nodes = document.xPath(path)
//        values = [String]()
//        nodes?.forEach { node in
//
//            if let attribute = attribute {
//                if let value = node.attributes[attribute] {
//                    values?.append(value)
//                }
//            }
//            else {
//                if let content = node.content {
//                    values?.append(content)
//                }
//            }
//        }

        return values
    }

    private func extractValueUsing(queries: [(String, String?)]) -> String? {
//        for query in queries {
//            if let value = extractValueUsing(document, path: query.0, attribute: query.1) {
//                return value
//            }
//        }

        return nil
    }

    private func extractValuesUsing(queries: [(String, String?)]) -> [String]? {
//        for query in queries {
//            if let values = extractValuesUsing(document, path: query.0, attribute: query.1) {
//                return values
//            }
//        }
//
       return nil
    }

    let titleQueries: [(String, String?)] = [
        ("head > title", nil),
        ("head > meta[@name='title']", "content"),
        ("head > meta[@property='og:title']", "content"),
        ("head > meta[@name='twitter:title']", "content")
    ]


    private func title() -> String? {
        var result: String?
//        if let document = document {
//            guard let title = extractValueUsing(document, queries: titleQueries) else {
//                return .none
//            }
//
//            if title.count == 0 {
//                return .none
//            }
//
//            return title
//        }
//
//        return .none

        return result
    }

    private func description() -> String? {
        var result: String?
//        if let document = document {
//            if let description = extractValueUsing(document, queries: descQueries) {
//                return description
//            }
//        }
//
//        self.extractText(highestPriorityElement)

        return result
    }

    private func text() -> String? {
        guard let highestPriorityElement = highestPriorityElement else {
            return nil
        }

        return extractFullText(element: highestPriorityElement)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func image() -> String? {
        var result: String?
//        if let document = document {
//            if let imageUrl = extractValueUsing(document, queries: imageQueries) {
//                return imageUrl
//            }
//        }
        if let topElement = highestPriorityElement,
            let imageNode = self.determineImageSource(element: topElement) {
            result = try? imageNode.attr("src")
        }

        return result
    }

    private func video() -> String? {
        var result: String?
//        if let document = document {
//            if let imageUrl = extractValueUsing(document, queries: videoQueries) {
//                return imageUrl
//            }
//        }
//
//        return .none
        return result
    }

    private func keywords() -> [String]? {
        var result: [String]?
//        if let document = document {
//            if let values = extractValuesUsing(document, queries: keywordsQueries) {
//                var keywords = [String]()
//                values.forEach { (value: String) in
//                    var separatorsCharacterSet = CharacterSet.whitespacesAndNewlines
//                    separatorsCharacterSet.formUnion(NSCharacterSet.punctuationCharacters)
//                    keywords.append(contentsOf: value.components(separatedBy: separatorsCharacterSet))
//                }
//
//                keywords = keywords.filter({ $0.count > 1 })
//
//                return keywords
//            }
//        }
//
//        return .none

        return result
    }
}

extension String {
    /// stringToFind must be at least 1 character.
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}
