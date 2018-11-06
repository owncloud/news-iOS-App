//
//  User.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct User : Codable {
    
    let avatar : Avatar?
    let displayName : String?
    let lastLoginTimestamp : Int?
    let userId : String?
    
    enum CodingKeys: String, CodingKey {
        case avatar = "avatar"
        case displayName = "displayName"
        case lastLoginTimestamp = "lastLoginTimestamp"
        case userId = "userId"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        avatar = try Avatar(from: decoder)
        displayName = try values.decodeIfPresent(String.self, forKey: .displayName)
        lastLoginTimestamp = try values.decodeIfPresent(Int.self, forKey: .lastLoginTimestamp)
        userId = try values.decodeIfPresent(String.self, forKey: .userId)
    }
    
}
