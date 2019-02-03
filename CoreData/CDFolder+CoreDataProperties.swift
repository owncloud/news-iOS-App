//
//  CDFolder+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFolder> {
        return NSFetchRequest<CDFolder>(entityName: "CDFolder")
    }

    @NSManaged public var id: Int32
    @NSManaged public var lastModified: Int32
    @NSManaged public var name: String?
    @NSManaged public var unreadCount: Int32

}
