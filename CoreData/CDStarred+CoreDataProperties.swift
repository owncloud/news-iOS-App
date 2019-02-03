//
//  CDStarred+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDStarred {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStarred> {
        return NSFetchRequest<CDStarred>(entityName: "CDStarred")
    }

    @NSManaged public var itemId: Int32

}
