//
//  Item.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Item: Codable, ItemProtocol {
    var author : String?
    var body : String?
    var enclosureLink : String?
    var enclosureMime : String?
    var feedId : Int32
    var fingerprint : String?
    var guid : String?
    var guidHash : String?
    var id : Int32
    var lastModified : Int32
    var pubDate : Int32
    var starred : Bool
    var title : String?
    var unread : Bool
    var url : String?
    
    enum CodingKeys: String, CodingKey {
        case author = "author"
        case body = "body"
        case enclosureLink = "enclosureLink"
        case enclosureMime = "enclosureMime"
        case feedId = "feedId"
        case fingerprint = "fingerprint"
        case guid = "guid"
        case guidHash = "guidHash"
        case id = "id"
        case lastModified = "lastModified"
        case pubDate = "pubDate"
        case starred = "starred"
        case title = "title"
        case unread = "unread"
        case url = "url"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        author = try values.decodeIfPresent(String.self, forKey: .author)
        body = try values.decodeIfPresent(String.self, forKey: .body)
        enclosureLink = try values.decodeIfPresent(String.self, forKey: .enclosureLink)
        enclosureMime = try values.decodeIfPresent(String.self, forKey: .enclosureMime)
        feedId = try values.decode(Int32.self, forKey: .feedId)
        fingerprint = try values.decodeIfPresent(String.self, forKey: .fingerprint)
        guid = try values.decodeIfPresent(String.self, forKey: .guid)
        guidHash = try values.decodeIfPresent(String.self, forKey: .guidHash)
        id = try values.decode(Int32.self, forKey: .id)
        lastModified = try values.decode(Int32.self, forKey: .lastModified)
        pubDate = try values.decode(Int32.self, forKey: .pubDate)
        starred = try values.decode(Bool.self, forKey: .starred)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        unread = try values.decode(Bool.self, forKey: .unread)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }
    
}
