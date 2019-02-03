//
//  CDUnread+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDUnread {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUnread> {
        return NSFetchRequest<CDUnread>(entityName: "CDUnread")
    }

    @NSManaged public var itemId: Int32

}
