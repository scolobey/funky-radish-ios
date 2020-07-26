//
//  Recipe.swift
//  funky-radish
//
//  Created by Ryn Goodwin on 7/31/18.
//  Copyright © 2018 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class Recipe: Object {
    @objc dynamic var _id: ObjectId? = ObjectId.generate()
    @objc dynamic var author: String = ""
    @objc dynamic var title: String? = nil
    
    var directions = RealmSwift.List<Direction>()
    var ingredients = RealmSwift.List<Ingredient>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience init(title: String, ingredients: List<Ingredient>, directions: List<Direction>) {
        self.init()
        self.title = title
        self.ingredients = ingredients
        self.directions = directions
    }
}
