//
//  CDFolder+CoreDataClass.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CDFolder)
public class CDFolder: NSManagedObject, FolderProtocol {

    static private let entityName = "CDFolder"
    
    static func all() -> [CDFolder]? {
        let request : NSFetchRequest<CDFolder> = self.fetchRequest()
        //        let sortDescription = NSSortDescriptor(key: sortBy, ascending: ascending)
        //        request.sortDescriptors = [sortDescription]
        
        var folderList = [CDFolder]()
        do {
            let results  = try NewsData.mainThreadContext.fetch(request)
            for record in results {
                folderList.append(record)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return folderList
    }
    
    static func update(folders: [FolderProtocol]) {
        NewsData.mainThreadContext.performAndWait {
            let request: NSFetchRequest<CDFolder> = CDFolder.fetchRequest()
            do {
                for folder in folders {
                    let predicate = NSPredicate(format: "id == %d", folder.id)
                    request.predicate = predicate
                    let records = try NewsData.mainThreadContext.fetch(request)
                    if let existingRecord = records.first {
                        existingRecord.name = folder.name
                    } else {
                        let newRecord = NSEntityDescription.insertNewObject(forEntityName: CDFolder.entityName, into: NewsData.mainThreadContext) as! CDFolder
                        newRecord.id = Int32(folder.id)
                        newRecord.name = folder.name
                    }
                }
                try NewsData.mainThreadContext.save()
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
    }

    static func folder(id: Int32) -> CDFolder? {
        let request: NSFetchRequest<CDFolder> = self.fetchRequest()
        let predicate = NSPredicate(format: "id == %d", id)
        request.predicate = predicate
        request.fetchLimit = 1
        do {
            let results  = try NewsData.mainThreadContext.fetch(request)
            return results.first
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return nil
    }

}
