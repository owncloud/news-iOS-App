//
//  Feeds.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Feeds : Codable {
    
    let feeds : [Feed]?
    let newestItemId : Int?
    let starredCount : Int?
    
    enum CodingKeys: String, CodingKey {
        case feeds = "feeds"
        case newestItemId = "newestItemId"
        case starredCount = "starredCount"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        feeds = try values.decodeIfPresent([Feed].self, forKey: .feeds)
        newestItemId = try values.decodeIfPresent(Int.self, forKey: .newestItemId)
        starredCount = try values.decodeIfPresent(Int.self, forKey: .starredCount)
    }
    
}
