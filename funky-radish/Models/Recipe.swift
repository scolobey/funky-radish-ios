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
    @objc dynamic var _id: String? = ObjectId.generate().stringValue
    @objc dynamic var author: String = ""
    @objc dynamic var title: String? = nil
    @objc dynamic var lastUpdated: Date? = nil
    
    var dir = List<String>()
    var ing = List<String>()
    
    var directions = RealmSwift.List<Direction>()
    var ingredients = RealmSwift.List<Ingredient>()
    
    
    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience init(title: String, ingredients: List<Ingredient>, directions: List<Direction>, ing: List<String>, dir: List<String> ) {
        self.init()
        self.title = title
        self.ingredients = ingredients
        self.directions = directions
        self.ing = ing
        self.dir = dir
    }
}
