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

class Ingredient: Object {
    @objc dynamic var _id: ObjectId = ObjectId.generate()
    @objc dynamic var name: String? = nil
    @objc dynamic var _partition = ""
    @objc dynamic var realmID: String? = nil
    @objc dynamic var user: ObjectId? = nil

    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(partition: String, name: String) {
        self.init()
        self._partition = partition
        self.name = name
    }

//    private enum IngredientCodingKeys: String, CodingKey {
//        case name
//    }

//    convenience init(name: String) {
//        self.init()
//        self.name = name
//    }

//    convenience required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: IngredientCodingKeys.self)
//        let name = try container.decode(String.self, forKey: .name)
//        self.init(name: name)
//    }
//
//    required init() {
//        super.init()
    
//    }
}
