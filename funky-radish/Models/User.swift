//
//  User.swift
//  funky-radish
//
//  Created by Ryan on 1/6/22.
//  Copyright © 2022 kayso. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class User: Object {
    @objc dynamic var _id: String? = ""
    @objc dynamic var author: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var email: String = ""

    var recipes = RealmSwift.List<Recipe>()
    
    override static func primaryKey() -> String? {
        return "_id"
    }

    convenience init(name: String) {
        self.init()
        self.name = name
        self.email = email
    }
}
