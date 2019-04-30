//
//  UserResponse.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 8/29/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

struct UserResponse: Decodable {
    var message : String
    var token : String?
    var userData : User?

    private enum APIResponseCodingKeys: String, CodingKey {
        case message
        case token
        case userData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: APIResponseCodingKeys.self)
        message = try container.decode(String.self, forKey: .message)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        userData = try container.decodeIfPresent(User.self, forKey: .userData)
    }
}
