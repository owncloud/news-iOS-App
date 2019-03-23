//
//  NotificationNames.swift
//  CloudNews
//
//  Created by Peter Hedlund on 3/23/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation

extension NSNotification.Name {

    public static let syncInitiated = NSNotification.Name("SyncInitiated")
    public static let syncComplete = NSNotification.Name("SyncComplete")
    public static let folderSync = NSNotification.Name("FolderSync")
    public static let feedSync = NSNotification.Name("FeedSync")

}
