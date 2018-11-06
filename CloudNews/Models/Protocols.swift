//
//  FeedProtocol.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

protocol FolderProtocol {
    var id: Int32 { get set }
    var name: String? { get set }
}

protocol FeedProtocol {
    var added: Int32 { get set }
    var faviconLink: String? { get set }
    var folderId: Int32 { get set }
    var id: Int32 { get set }
    var lastUpdateError: String? { get set }
    var link: String? { get set }
    var ordering: Int32 { get set }
    var pinned: Bool { get set }
    var title: String? { get set }
    var unreadCount: Int32 { get set }
    var updateErrorCount: Int32 { get set }
    var url: String? { get set }
}

protocol FeedsProtocol {
    var feeds: [FeedProtocol]? { get set }
    var newestItemId: Int32 { get set }
    var starredCount: Int32 { get set }
}

protocol ItemProtocol {
    var author: String? { get set }
    var body: String? { get set }
    var enclosureLink: String? { get set }
    var enclosureMime: String? { get set }
    var feedId: Int32 { get set }
    var fingerprint: String? { get set }
    var guid: String? { get set }
    var guidHash: String? { get set }
    var id: Int32 { get set }
    var lastModified: Int32 { get set }
    var pubDate: Int32 { get set }
    var starred: Bool { get set }
    var title: String? { get set }
    var unread: Bool { get set }
    var url: String? { get set }
}
