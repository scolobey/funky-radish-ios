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
    @objc dynamic var author: String = ""
    @objc dynamic var name: String? = nil

    override static func primaryKey() -> String? {
        return "_id"
    }
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
