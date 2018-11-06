//
//  Feed.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Feed: Codable, FeedProtocol {
    
    var added: Int32
    var faviconLink: String?
    var folderId: Int32
    var id: Int32
    var lastUpdateError: String?
    var link: String?
    var ordering: Int32
    var pinned: Bool
    var title: String?
    var unreadCount: Int32
    var updateErrorCount: Int32
    var url: String?
    
    enum CodingKeys: String, CodingKey {
        case added = "added"
        case faviconLink = "faviconLink"
        case folderId = "folderId"
        case id = "id"
        case lastUpdateError = "lastUpdateError"
        case link = "link"
        case ordering = "ordering"
        case pinned = "pinned"
        case title = "title"
        case unreadCount = "unreadCount"
        case updateErrorCount = "updateErrorCount"
        case url = "url"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        added = try values.decode(Int32.self, forKey: .added)
        faviconLink = try values.decodeIfPresent(String.self, forKey: .faviconLink)
        folderId = try values.decode(Int32.self, forKey: .folderId)
        id = try values.decode(Int32.self, forKey: .id)
        lastUpdateError = try values.decodeIfPresent(String.self, forKey: .lastUpdateError)
        link = try values.decodeIfPresent(String.self, forKey: .link)
        ordering = try values.decode(Int32.self, forKey: .ordering)
        pinned = try values.decode(Bool.self, forKey: .pinned)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        unreadCount = try values.decode(Int32.self, forKey: .unreadCount)
        updateErrorCount = try values.decode(Int32.self, forKey: .updateErrorCount)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }
    
}
