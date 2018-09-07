//
//  APIResponse.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 8/29/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation

struct APIResponse: Decodable {
    var message : String? = ""
    var data : User

    private enum APIResponseCodingKeys: String, CodingKey {
        case message
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: APIResponseCodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        data = try container.decode(User.self, forKey: .data)
    }
}
