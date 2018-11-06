//
//  Avatar.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Avatar : Codable {

        let data : String?
        let mime : String?

        enum CodingKeys: String, CodingKey {
                case data = "data"
                case mime = "mime"
        }
    
        init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                data = try values.decodeIfPresent(String.self, forKey: .data)
                mime = try values.decodeIfPresent(String.self, forKey: .mime)
        }

}
