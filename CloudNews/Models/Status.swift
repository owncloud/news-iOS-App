//
//  Status.swift
//  CloudNews
//
//  Created by Peter Hedlund on 11/24/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//

import Foundation

struct Warnings: Codable {
    
    let improperlyConfiguredCron: Bool? // if true the webapp will fail to update the feeds correctly
    let incorrectDbCharset: Bool?

    enum CodingKeys: String, CodingKey {
        case improperlyConfiguredCron = "improperlyConfiguredCron"
        case incorrectDbCharset = "incorrectDbCharset"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        improperlyConfiguredCron = try values.decodeIfPresent(Bool.self, forKey: .improperlyConfiguredCron)
        incorrectDbCharset = try values.decodeIfPresent(Bool.self, forKey: .incorrectDbCharset)
    }
}


struct Status : Codable {
    
    let version : String?
    let warnings : Warnings?
    
    enum CodingKeys: String, CodingKey {
        case version = "version"
        case warnings = "warnings"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        warnings = try Warnings(from: decoder)
        version = try values.decodeIfPresent(String.self, forKey: .version)
    }
    
}
