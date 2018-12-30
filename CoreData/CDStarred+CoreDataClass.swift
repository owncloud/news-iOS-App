//
//  CDStarred+CoreDataClass.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/14/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CDStarred)
public class CDStarred: NSManagedObject {

    static private let entityName = "CDStarred"

    static func update(items: [Int32]) {
        NewsData.mainThreadContext.performAndWait {
            let request: NSFetchRequest<CDStarred> = CDStarred.fetchRequest()
            do {
                for item in items {
                    let predicate = NSPredicate(format: "itemId == %d", item)
                    request.predicate = predicate
                    let records = try NewsData.mainThreadContext.fetch(request)
                    if let existingRecord = records.first {
                        existingRecord.itemId = item
                    } else {
                        let newRecord = NSEntityDescription.insertNewObject(forEntityName: self.entityName, into: NewsData.mainThreadContext) as! CDStarred
                        newRecord.itemId = item
                    }
                }
                try NewsData.mainThreadContext.save()
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
    }

    static func all() -> [Int32]? {
        let request : NSFetchRequest<CDStarred> = self.fetchRequest()

        var itemList = [Int32]()
        do {
            let results  = try NewsData.mainThreadContext.fetch(request)
            for record in results {
                itemList.append(record.itemId)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return itemList
    }

    static func clear() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request )
        batchDeleteRequest.resultType = .resultTypeCount
        do {
            let batchDeleteResult = try NewsData.mainThreadContext.execute(batchDeleteRequest) as! NSBatchDeleteResult
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
//            NewsData.mainThreadContext.reset() // reset managed object context (need it for working)
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }

}
