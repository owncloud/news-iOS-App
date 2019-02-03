//
//  FeedTreeNode.swift
//  CloudNews
//
//  Created by Peter Hedlund on 1/14/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Cocoa

@objc protocol FeedTreeNode: class {
    
    var isLeaf: Bool { get }
    var childCount: Int { get }
    var children: [FeedTreeNode] { get }
    
    var title: String { get }
    var unreadCount: String? { get }
    var faviconImage: NSImage? { get }

    var sortId: Int { get }
}

class AllFeedNode: NSObject, FeedTreeNode {

    var sortId: Int {
        return 0
    }
    
    var isLeaf: Bool {
            return true
    }
    
    var childCount: Int {

            return 0
    }
    
    var children: [FeedTreeNode] {
            return []
    }
    
    var title: String {
            return "All Articles"
    }
    
    var unreadCount: String? {
            let count = CDItem.unreadCount()
            if count > 0 {
                return "\(count)"
            }
            return nil
    }
    
    var faviconImage: NSImage? {
            return NSImage(named: "All Articles")
    }
    
}

class StarredFeedNode: NSObject, FeedTreeNode {

    var sortId: Int {
        return 1
    }

    
    var isLeaf: Bool {
        get {
            return true
        }
    }
    
    var childCount: Int {
        get {
            return 0
        }
    }
    
    var children: [FeedTreeNode] {
        get {
            return []
        }
    }
    
    var title: String {
        get {
            return "Starred Articles"
        }
    }
    
    var unreadCount: String? {
        get {
            let count = CDItem.starredItems()?.count ?? 0
            if count > 0 {
                return "\(count)"
            }
            return nil
        }
    }
    
    var faviconImage: NSImage? {
        get {
            return NSImage(named: "Starred Articles")
        }
    }
    
}

class FolderFeedNode: NSObject, FeedTreeNode {

    var sortId: Int {
        return Int(self.folder.id) + 100
    }

    
    let folder: CDFolder
    
    init(folder: CDFolder){
        self.folder = folder
    }
    
    var isLeaf: Bool {
        get {
            return false
        }
    }
    
    var childCount: Int {
        get {
            var count = 0
            if let feedIds = CDFeed.idsInFolder(folder: self.folder.id) {
                count = feedIds.count
            }
            return count
        }
    }
    
    var children: [FeedTreeNode] {
        get {
            var result = [FeedTreeNode]()
            if let feeds = CDFeed.inFolder(folder: self.folder.id) {
                for feed in feeds {
                    result.append(FeedNode(feed: feed))
                }
            }
            return result
        }
    }
    
    var title: String {
        get {
            return self.folder.name ?? "Untitled Folder"
        }
    }
    
    var unreadCount: String? {
        get {
            let folderFeeds = CDFeed.inFolder(folder: self.folder.id)
            let unreadCount = folderFeeds?.map { $0.unreadCount }.reduce(0) { $0 + $1 } ?? 0
            if unreadCount > 0 {
                return "\(unreadCount)"
            }
            return nil
        }
    }
    
    var faviconImage: NSImage? {
        get {
            return NSImage(named: "folder")
        }
    }
    
}

class FeedNode: NSObject, FeedTreeNode {

    var sortId: Int {
        return Int(self.feed.id) + 1000
    }

    let feed: CDFeed
    
    init(feed: CDFeed){
        self.feed = feed
    }
    
    var isLeaf: Bool {
        get {
            return true
        }
    }
    
    var childCount: Int {
        get {
            return 0
        }
    }
    
    var children: [FeedTreeNode] {
        get {
            return []
        }
    }
    
    var title: String {
        get {
            return self.feed.title ?? "Untitled Feed"
        }
    }
    
    var unreadCount: String? {
        get {
            let count = self.feed.unreadCount
            if count > 0 {
                return "\(count)"
            }
            return nil
        }
    }
    
    var faviconImage: NSImage? {
        get {
            var result: NSImage?
            if let faviconLink = feed.faviconLink, let url = URL(string: faviconLink) {
                result = NSImage(byReferencing: url)
            } else {
                result = NSImage(named: "All Articles")
            }
            return result
        }
    }
    
}
