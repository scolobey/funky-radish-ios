//
//  Ingredient.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class Ingredient: Object, Decodable {
    @objc dynamic var realmID = UUID().uuidString
    @objc dynamic var name = ""

    override static func primaryKey() -> String? {
        return "realmID"
    }

    private enum IngredientCodingKeys: String, CodingKey {
        case name
    }

    convenience init(name: String) {
        self.init()
        self.name = name
    }

    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IngredientCodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        self.init(name: name)
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
