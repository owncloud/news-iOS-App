//
//  CDRead+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDRead {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRead> {
        return NSFetchRequest<CDRead>(entityName: "CDRead")
    }

    @NSManaged public var itemId: Int32

}
