//
//  CDFeed+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDFeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFeed> {
        return NSFetchRequest<CDFeed>(entityName: "CDFeed")
    }

    @NSManaged public var added: Int32
    @NSManaged public var articleCount: Int32
    @NSManaged public var faviconLink: String?
    @NSManaged public var folderId: Int32
    @NSManaged public var id: Int32
    @NSManaged public var lastModified: Int32
    @NSManaged public var lastUpdateError: String?
    @NSManaged public var link: String?
    @NSManaged public var ordering: Int32
    @NSManaged public var pinned: Bool
    @NSManaged public var preferWeb: Bool
    @NSManaged public var title: String?
    @NSManaged public var unreadCount: Int32
    @NSManaged public var updateErrorCount: Int32
    @NSManaged public var url: String?
    @NSManaged public var useReader: Bool

}
