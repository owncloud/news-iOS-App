//
//  Folders.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Folders : Codable {
    
    let folders : [Folder]?
    
    enum CodingKeys: String, CodingKey {
        case folders = "folders"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        folders = try values.decodeIfPresent([Folder].self, forKey: .folders)
    }
    
}
