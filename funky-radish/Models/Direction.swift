//
//  Direction.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Direction: Object, Decodable {
    @objc dynamic var realmID = UUID().uuidString
    @objc dynamic var text: String = ""

    override static func primaryKey() -> String? {
        return "realmID"
    }

    private enum DirectionCodingKeys: String, CodingKey {
        case text
    }

    convenience init(text: String) {
        self.init()
        self.text = text
    }

    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DirectionCodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        self.init(text: text)
    }

    required init() {
        super.init()
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
}
