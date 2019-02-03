//
//  SyncHelper.swift
//  CloudNews
//
//  Created by Peter Hedlund on 1/25/19.
//  Copyright © 2019 Peter Hedlund. All rights reserved.
//

import Foundation

struct FolderSync: Equatable {

    var id: Int32
    var name: String

}

struct FeedSync: Equatable {

    var id: Int32
    var title: String
    var folderId: Int32

}
