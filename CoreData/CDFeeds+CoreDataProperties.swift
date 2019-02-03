//
//  CDFeeds+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDFeeds {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFeeds> {
        return NSFetchRequest<CDFeeds>(entityName: "CDFeeds")
    }

    @NSManaged public var newestItemId: Int32
    @NSManaged public var starredCount: Int32

}
