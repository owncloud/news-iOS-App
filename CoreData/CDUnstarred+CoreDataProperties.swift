//
//  CDUnstarred+CoreDataProperties.swift
//  
//
//  Created by Peter Hedlund on 1/21/19.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CDUnstarred {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUnstarred> {
        return NSFetchRequest<CDUnstarred>(entityName: "CDUnstarred")
    }

    @NSManaged public var itemId: Int32

}
